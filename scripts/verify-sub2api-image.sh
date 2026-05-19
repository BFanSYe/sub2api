#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  verify-sub2api-image.sh \
    --image IMAGE_REF \
    --source-repo OWNER/REPO_OR_LOCAL_PATH \
    --expected-revision SHA \
    [--upstream-repo OWNER/REPO] \
    [--upstream-ref REF] \
    [--required-fix SHA ...]

Required:
  --image IMAGE_REF
      Remote image reference to inspect, preferably ghcr.io/owner/name@sha256:...

  --source-repo OWNER/REPO_OR_LOCAL_PATH
      GitHub owner/repo or a local git repository path containing --expected-revision.

  --expected-revision SHA
      Source commit expected in org.opencontainers.image.revision.

Optional:
  --upstream-repo OWNER/REPO
      Upstream GitHub repository used for missing-commit counts.
      Default: Wei-Shaw/sub2api

  --upstream-ref REF
      Upstream branch, tag, or commit used for missing-commit counts.
      Default: main

  --required-fix SHA
      Commit that must be an ancestor of --expected-revision. Repeatable.

Notes:
  - Read-only against Docker and local source repositories.
  - Uses docker buildx imagetools inspect; it never docker pulls.
  - Uses a temporary git repository for remote fetches and comparisons.
EOF
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

warn() {
  printf 'WARN: %s\n' "$*" >&2
}

ok() {
  printf 'OK: %s\n' "$*"
}

info() {
  printf 'INFO: %s\n' "$*"
}

require_value() {
  local option="$1"
  local value="${2:-}"
  if [ -z "$value" ] || [[ "$value" == --* ]]; then
    die "$option requires a value"
  fi
}

is_owner_repo() {
  [[ "$1" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]
}

github_repo_url() {
  local repo="$1"
  is_owner_repo "$repo" || die "expected OWNER/REPO, got: $repo"
  printf 'https://github.com/%s.git\n' "$repo"
}

source_repo_url_or_path() {
  local repo="$1"
  if [ -e "$repo" ]; then
    git -C "$repo" rev-parse --git-dir >/dev/null 2>&1 || die "local path is not a git repository: $repo"
    printf '%s\n' "$repo"
    return
  fi

  github_repo_url "$repo"
}

extract_revision_label() {
  local json_file="$1"
  python3 - "$json_file" <<'PY'
import json
import sys

target = "org.opencontainers.image.revision"

with open(sys.argv[1], "r", encoding="utf-8") as fh:
    data = json.load(fh)

found = []

def walk(value):
    if isinstance(value, dict):
        direct = value.get(target)
        if isinstance(direct, (str, int)):
            found.append(str(direct))

        for key in ("Labels", "labels", "Annotations", "annotations"):
            labels = value.get(key)
            if isinstance(labels, dict):
                label_value = labels.get(target)
                if isinstance(label_value, (str, int)):
                    found.append(str(label_value))

        for child in value.values():
            walk(child)
    elif isinstance(value, list):
        for child in value:
            walk(child)

walk(data)
print(found[0] if found else "")
PY
}

IMAGE_REF=""
SOURCE_REPO=""
EXPECTED_REVISION=""
UPSTREAM_REPO="Wei-Shaw/sub2api"
UPSTREAM_REF="main"
declare -a REQUIRED_FIXES=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --image)
      require_value "$1" "${2:-}"
      IMAGE_REF="$2"
      shift 2
      ;;
    --source-repo)
      require_value "$1" "${2:-}"
      SOURCE_REPO="$2"
      shift 2
      ;;
    --expected-revision)
      require_value "$1" "${2:-}"
      EXPECTED_REVISION="$2"
      shift 2
      ;;
    --upstream-repo)
      require_value "$1" "${2:-}"
      UPSTREAM_REPO="$2"
      shift 2
      ;;
    --upstream-ref)
      require_value "$1" "${2:-}"
      UPSTREAM_REF="$2"
      shift 2
      ;;
    --required-fix)
      require_value "$1" "${2:-}"
      REQUIRED_FIXES+=("$2")
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

[ -n "$IMAGE_REF" ] || die "--image is required"
[ -n "$SOURCE_REPO" ] || die "--source-repo is required"
[ -n "$EXPECTED_REVISION" ] || die "--expected-revision is required"
[ -n "$UPSTREAM_REF" ] || die "--upstream-ref must not be empty"

command -v docker >/dev/null 2>&1 || die "docker is required"
command -v git >/dev/null 2>&1 || die "git is required"
command -v python3 >/dev/null 2>&1 || die "python3 is required for JSON label inspection"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

gitdir="$tmpdir/git"
git init -q "$gitdir"

source_location="$(source_repo_url_or_path "$SOURCE_REPO")"
upstream_url="$(github_repo_url "$UPSTREAM_REPO")"

git -C "$gitdir" remote add source "$source_location"
git -C "$gitdir" remote add upstream "$upstream_url"

info "Fetching source revision from $SOURCE_REPO"
if ! git -C "$gitdir" fetch --quiet --no-tags source "$EXPECTED_REVISION"; then
  die "source revision not found in $SOURCE_REPO: $EXPECTED_REVISION"
fi
source_commit="$(git -C "$gitdir" rev-parse --verify 'FETCH_HEAD^{commit}')"
ok "source commit exists: $source_commit"

failed=0

if [ "${#REQUIRED_FIXES[@]}" -eq 0 ]; then
  info "No required fixes declared"
else
  for fix in "${REQUIRED_FIXES[@]}"; do
    if ! git -C "$gitdir" cat-file -e "$fix^{commit}" 2>/dev/null; then
      git -C "$gitdir" fetch --quiet --no-tags source "$fix" 2>/dev/null || true
    fi

    if ! fix_commit="$(git -C "$gitdir" rev-parse --verify "$fix^{commit}" 2>/dev/null)"; then
      printf 'FAIL: required fix is not present in source repository: %s\n' "$fix" >&2
      failed=1
      continue
    fi

    if git -C "$gitdir" merge-base --is-ancestor "$fix_commit" "$source_commit"; then
      ok "required fix is an ancestor: $fix_commit"
    else
      printf 'FAIL: required fix is not an ancestor of source commit: %s\n' "$fix_commit" >&2
      failed=1
    fi
  done
fi

info "Fetching upstream ref $UPSTREAM_REPO@$UPSTREAM_REF"
if ! git -C "$gitdir" fetch --quiet --no-tags upstream "$UPSTREAM_REF"; then
  die "upstream ref not found: $UPSTREAM_REPO@$UPSTREAM_REF"
fi
upstream_commit="$(git -C "$gitdir" rev-parse --verify 'FETCH_HEAD^{commit}')"
missing_total="$(git -C "$gitdir" rev-list --count "${source_commit}..${upstream_commit}")"
missing_nonmerge="$(git -C "$gitdir" rev-list --count --no-merges "${source_commit}..${upstream_commit}")"
info "upstream commit: $upstream_commit"
info "missing upstream commits: total=$missing_total nonmerge=$missing_nonmerge"

info "Inspecting remote image: $IMAGE_REF"
if docker buildx imagetools inspect "$IMAGE_REF" >"$tmpdir/image.inspect.txt"; then
  ok "remote image inspect succeeded"
else
  cat "$tmpdir/image.inspect.txt" >&2 || true
  die "remote image inspect failed: $IMAGE_REF"
fi

if docker buildx imagetools inspect "$IMAGE_REF" --format '{{json .}}' >"$tmpdir/image.inspect.json" 2>"$tmpdir/image.inspect-json.err"; then
  revision_label="$(extract_revision_label "$tmpdir/image.inspect.json")"
  if [ -n "$revision_label" ]; then
    if [ "$revision_label" = "$source_commit" ]; then
      ok "image revision label matches expected revision: $revision_label"
    else
      printf 'FAIL: image revision label mismatch. expected=%s actual=%s\n' "$source_commit" "$revision_label" >&2
      failed=1
    fi
  else
    printf 'FAIL: org.opencontainers.image.revision label was not found in imagetools JSON output\n' >&2
    failed=1
  fi
else
  sed 's/^/FAIL: /' "$tmpdir/image.inspect-json.err" >&2 || true
  printf 'FAIL: could not inspect OCI labels via imagetools JSON\n' >&2
  failed=1
fi

if [ "$failed" -ne 0 ]; then
  die "verification failed"
fi

ok "self-built image verification passed"
