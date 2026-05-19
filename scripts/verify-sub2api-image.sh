#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  verify-sub2api-image.sh \
    --image IMAGE_REF \
    --source-repo OWNER/REPO_OR_LOCAL_PATH \
    --expected-revision SHA \
    [--expected-version VERSION] \
    [--expected-platform PLATFORM ...] \
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
  --expected-version VERSION
      Version expected in org.opencontainers.image.version.
      If omitted, the version label is not required.

  --expected-platform PLATFORM
      Platform that must exist in the image manifest, e.g. linux/amd64.
      Repeatable. unknown/unknown attestation manifests are ignored.

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

extract_label() {
  local json_file="$1"
  local label_name="$2"
  python3 - "$json_file" "$label_name" <<'PY'
import json
import sys

target = sys.argv[2]

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

extract_platforms() {
  local json_file="$1"
  local text_file="$2"
  python3 - "$json_file" "$text_file" <<'PY'
import json
import os
import re
import sys

json_file = sys.argv[1]
text_file = sys.argv[2]
found = []
seen = set()


def add(platform):
    platform = str(platform).strip().lower()
    if not platform:
        return
    if platform == "unknown/unknown":
        return
    parts = platform.split("/")
    if len(parts) < 2:
        return
    if parts[0] == "unknown" and parts[1] == "unknown":
        return
    if platform not in seen:
        seen.add(platform)
        found.append(platform)


def walk(value):
    if isinstance(value, dict):
        os_name = value.get("os")
        architecture = value.get("architecture")
        variant = value.get("variant")
        if isinstance(os_name, str) and isinstance(architecture, str):
            platform = f"{os_name}/{architecture}"
            if isinstance(variant, str) and variant:
                platform = f"{platform}/{variant}"
            add(platform)

        platform_obj = value.get("platform")
        if isinstance(platform_obj, dict):
            walk(platform_obj)

        for child in value.values():
            walk(child)
    elif isinstance(value, list):
        for child in value:
            walk(child)


if os.path.exists(json_file) and os.path.getsize(json_file) > 0:
    try:
        with open(json_file, "r", encoding="utf-8") as fh:
            walk(json.load(fh))
    except json.JSONDecodeError:
        pass

if os.path.exists(text_file):
    with open(text_file, "r", encoding="utf-8", errors="replace") as fh:
        for line in fh:
            match = re.search(
                r"\bPlatform:\s*([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(?:/[A-Za-z0-9_.-]+)?)",
                line,
            )
            if match:
                add(match.group(1))

for platform in found:
    print(platform)
PY
}

IMAGE_REF=""
SOURCE_REPO=""
EXPECTED_REVISION=""
EXPECTED_VERSION=""
UPSTREAM_REPO="Wei-Shaw/sub2api"
UPSTREAM_REF="main"
declare -a EXPECTED_PLATFORMS=()
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
    --expected-version)
      require_value "$1" "${2:-}"
      EXPECTED_VERSION="$2"
      shift 2
      ;;
    --expected-platform)
      require_value "$1" "${2:-}"
      platform="$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
      [ -n "$platform" ] || die "--expected-platform must not be empty"
      EXPECTED_PLATFORMS+=("$platform")
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
  revision_label="$(extract_label "$tmpdir/image.inspect.json" "org.opencontainers.image.revision")"
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

  if [ -n "$EXPECTED_VERSION" ]; then
    version_label="$(extract_label "$tmpdir/image.inspect.json" "org.opencontainers.image.version")"
    if [ -n "$version_label" ]; then
      if [ "$version_label" = "$EXPECTED_VERSION" ]; then
        ok "image version label matches expected version: $version_label"
      else
        printf 'FAIL: image version label mismatch. expected=%s actual=%s\n' "$EXPECTED_VERSION" "$version_label" >&2
        failed=1
      fi
    else
      printf 'FAIL: org.opencontainers.image.version label was not found in imagetools JSON output\n' >&2
      failed=1
    fi
  fi
else
  sed 's/^/FAIL: /' "$tmpdir/image.inspect-json.err" >&2 || true
  printf 'FAIL: could not inspect OCI labels via imagetools JSON\n' >&2
  failed=1
fi

if [ "${#EXPECTED_PLATFORMS[@]}" -gt 0 ]; then
  mapfile -t detected_platforms < <(extract_platforms "$tmpdir/image.inspect.json" "$tmpdir/image.inspect.txt")

  if [ "${#detected_platforms[@]}" -eq 0 ]; then
    printf 'FAIL: no image platforms were found in imagetools inspect output\n' >&2
    failed=1
  else
    info "image platforms detected: ${detected_platforms[*]}"
    for expected_platform in "${EXPECTED_PLATFORMS[@]}"; do
      platform_found=0
      for detected_platform in "${detected_platforms[@]}"; do
        if [ "$detected_platform" = "$expected_platform" ]; then
          platform_found=1
          break
        fi
      done

      if [ "$platform_found" -eq 1 ]; then
        ok "image platform exists: $expected_platform"
      else
        printf 'FAIL: expected image platform was not found: %s\n' "$expected_platform" >&2
        failed=1
      fi
    done
  fi
fi

if [ "$failed" -ne 0 ]; then
  die "verification failed"
fi

ok "self-built image verification passed"
