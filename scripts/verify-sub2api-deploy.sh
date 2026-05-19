#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  verify-sub2api-deploy.sh \
    [--service SERVICE_OR_CONTAINER] \
    [--expected-image IMAGE_REF] \
    [--expected-revision SHA] \
    [--public-url URL] \
    [--homepage-marker TEXT]

Options:
  --service SERVICE_OR_CONTAINER
      Container name/id or Docker Compose service label to inspect.
      Default: sub2api

  --expected-image IMAGE_REF
      Expected Config.Image value, preferably ghcr.io/owner/name@sha256:...

  --expected-revision SHA
      Expected org.opencontainers.image.revision label on the local image.

  --public-url URL
      Public URL to check with curl -fsSI.

  --homepage-marker TEXT
      Text marker that must appear in the public URL response body.
      Requires --public-url.

Notes:
  - Read-only: no restart, pull, compose up, or container mutation.
  - Does not run docker compose and does not read .env.
EOF
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
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

resolve_container() {
  local service="$1"
  local direct_id
  local -a ids

  if direct_id="$(docker inspect --type container --format '{{.Id}}' "$service" 2>/dev/null)"; then
    printf '%s\n' "$direct_id"
    return
  fi

  mapfile -t ids < <(docker ps -aq --filter "label=com.docker.compose.service=$service")
  case "${#ids[@]}" in
    0)
      die "container not found by name/id or compose service label: $service"
      ;;
    1)
      printf '%s\n' "${ids[0]}"
      ;;
    *)
      printf 'ERROR: multiple containers match compose service label %s:\n' "$service" >&2
      printf '  %s\n' "${ids[@]}" >&2
      die "pass an exact container name or id with --service"
      ;;
  esac
}

SERVICE="sub2api"
EXPECTED_IMAGE=""
EXPECTED_REVISION=""
PUBLIC_URL=""
HOMEPAGE_MARKER=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --service)
      require_value "$1" "${2:-}"
      SERVICE="$2"
      shift 2
      ;;
    --expected-image)
      require_value "$1" "${2:-}"
      EXPECTED_IMAGE="$2"
      shift 2
      ;;
    --expected-revision)
      require_value "$1" "${2:-}"
      EXPECTED_REVISION="$2"
      shift 2
      ;;
    --public-url)
      require_value "$1" "${2:-}"
      PUBLIC_URL="$2"
      shift 2
      ;;
    --homepage-marker)
      require_value "$1" "${2:-}"
      HOMEPAGE_MARKER="$2"
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

[ -n "$SERVICE" ] || die "--service must not be empty"
if [ -n "$HOMEPAGE_MARKER" ] && [ -z "$PUBLIC_URL" ]; then
  die "--homepage-marker requires --public-url"
fi

command -v docker >/dev/null 2>&1 || die "docker is required"
if [ -n "$PUBLIC_URL" ]; then
  command -v curl >/dev/null 2>&1 || die "curl is required when --public-url is set"
fi

container_id="$(resolve_container "$SERVICE")"
info "container id: $container_id"

state_status="$(docker inspect --format '{{.State.Status}}' "$container_id")"
if [ "$state_status" = "running" ]; then
  ok "container state is running"
else
  die "container state is not running: $state_status"
fi

health_status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$container_id")"
case "$health_status" in
  healthy)
    ok "container health is healthy"
    ;;
  none)
    ok "container has no healthcheck"
    ;;
  *)
    die "container health is not healthy: $health_status"
    ;;
esac

config_image="$(docker inspect --format '{{.Config.Image}}' "$container_id")"
info "container Config.Image: $config_image"
if [ -n "$EXPECTED_IMAGE" ]; then
  if [ "$config_image" = "$EXPECTED_IMAGE" ]; then
    ok "Config.Image matches expected image"
  else
    die "Config.Image mismatch. expected=$EXPECTED_IMAGE actual=$config_image"
  fi
fi

if [ -n "$EXPECTED_REVISION" ]; then
  image_id="$(docker inspect --format '{{.Image}}' "$container_id")"
  revision_label="$(
    docker image inspect \
      --format '{{if .Config.Labels}}{{index .Config.Labels "org.opencontainers.image.revision"}}{{end}}' \
      "$image_id" 2>/dev/null || true
  )"

  if [ -z "$revision_label" ]; then
    die "local image is missing org.opencontainers.image.revision label"
  fi

  if [ "$revision_label" = "$EXPECTED_REVISION" ]; then
    ok "local image revision label matches expected revision"
  else
    die "local image revision label mismatch. expected=$EXPECTED_REVISION actual=$revision_label"
  fi
fi

if [ -n "$PUBLIC_URL" ]; then
  curl -fsSI --max-time 15 "$PUBLIC_URL" >/dev/null
  ok "public URL HEAD request succeeded: $PUBLIC_URL"

  if [ -n "$HOMEPAGE_MARKER" ]; then
    if curl -fsSL --max-time 20 "$PUBLIC_URL" | grep -F -- "$HOMEPAGE_MARKER" >/dev/null; then
      ok "homepage marker found"
    else
      die "homepage marker not found in public URL response"
    fi
  fi
fi

ok "deployment verification passed"
