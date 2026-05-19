# Custom Patches

This file documents the fork-owned changes that should be intentionally preserved when syncing `BFanSYe/sub2api` with upstream `Wei-Shaw/sub2api`.

It is not a release changelog. Use it as a merge/review checklist: if upstream touches any of the listed areas, verify the custom behavior again before building or deploying a self-built image.

## Patch Policy

- Keep custom patches small, obvious, and recoverable.
- Prefer upstream behavior unless there is a clear BFanSYe/customer requirement.
- Document the file scope, runtime behavior, verification steps, and upstream-conflict notes for each maintained patch.
- Do not add production secrets, customer-specific domains, API keys, tokens, passwords, database URLs, or `.env` contents to source code, docs, Docker layers, workflow logs, or image labels.
- When a custom patch becomes obsolete because upstream implements the same behavior, remove the fork patch and update this file in the same change.

## Patch Index

- [FusionGate-ready public homepage](#fusiongate-ready-public-homepage)
- [Self-built GHCR image pipeline](#self-built-ghcr-image-pipeline)
- [Customer production cutover documentation](#customer-production-cutover-documentation)

## FusionGate-ready Public Homepage

Status: maintained.

Scope: frontend default public homepage only.

Primary files:

- `frontend/src/views/HomeView.vue`
- `frontend/src/composables/useScrollReveal.ts`
- `frontend/src/i18n/locales/en.ts`
- `frontend/src/i18n/locales/zh.ts`

Runtime behavior:

- Replaces the upstream default public homepage with an editorial, alternating-section landing page.
- Uses the deployment's public `site_name` setting for the visible brand/title, so deployments can show markers such as `FusionGate` without hard-coding customer-specific text into the image.
- Keeps the upstream custom-home-content behavior: if admin-provided `home_content` exists, it takes over the full public homepage.
- Keeps docs/login/dashboard navigation behavior based on public settings and authentication state.
- Uses `[data-reveal]` markers plus `useScrollReveal()` for scroll fade/slide-in effects.
- Uses a conservative IntersectionObserver setting (`threshold: 0.08`, `rootMargin: '0px 0px 5% 0px'`) so below-fold cards reveal as the user scrolls into them, not far before they are visible.
- Intended backend/database impact: none. This patch should not add fork-specific API behavior, data models, or migrations.

Verification:

1. Build or open the frontend on a deployment with the default homepage enabled.
2. Confirm the configured public site name appears in the header/hero; for BFanSYe production this is commonly checked with the `FusionGate` marker.
3. Confirm language switching still renders the customized homepage text.
4. Scroll through the page and confirm `[data-reveal]` sections visibly fade/slide in.
5. Confirm browser console has no new frontend errors.
6. Confirm login/dashboard/docs links still route correctly for logged-out and logged-in states.
7. Confirm an admin-provided `home_content` override still replaces the default homepage.

Upstream conflict notes:

- Recheck this patch whenever upstream changes `HomeView.vue`, public settings loading, route/login behavior, locale files, CSP/nonces, or frontend build tooling.
- If reveal animation looks missing after a merge, inspect `useScrollReveal.ts` before changing CSS. Over-eager positive bottom `rootMargin` can reveal below-fold cards before the user sees them.
- Keep customer-specific branding out of the image. The homepage should remain runtime-brandable through settings rather than hard-coded domains or names.

## Self-built GHCR Image Pipeline

Status: maintained.

Scope: CI, Docker build metadata, read-only verification scripts, and operational docs.

Primary files:

- `.github/workflows/build-sub2api-image.yml`
- `Dockerfile`
- `scripts/verify-sub2api-image.sh`
- `scripts/verify-sub2api-deploy.sh`
- `docs/BFANSYE_FORK.md`
- `docs/SELF_BUILT_IMAGE_RUNBOOK.md`

Runtime behavior:

- Publishes BFanSYe-owned GHCR images from a clean GitHub Actions checkout.
- Supports multi-platform image builds, currently intended for customer-facing `linux/amd64` and `linux/arm64` coverage unless explicitly narrowed.
- Adds OCI labels such as source repository, source revision, version, and creation time.
- Produces a `build-manifest.yaml` artifact containing source/upstream commits, missing-upstream counts, version, platforms, image, tags, digest, required fixes, and build run URL.
- Verifies must-have upstream hotfixes by commit ancestry before building when `required_fixes` is supplied.
- Keeps production tags human-friendly while treating the immutable digest as the only production deploy reference.
- Keeps verification scripts read-only: no pull, rebuild, restart, compose up, prune, tag, or push.

Verification for workflow/script-only changes:

```bash
bash -n scripts/verify-sub2api-image.sh scripts/verify-sub2api-deploy.sh
shellcheck scripts/verify-sub2api-image.sh scripts/verify-sub2api-deploy.sh
python3 - <<'PY'
from pathlib import Path
import yaml
yaml.safe_load(Path('.github/workflows/build-sub2api-image.yml').read_text())
print('workflow yaml parse ok')
PY
git diff --check
```

For a built image, also run `scripts/verify-sub2api-image.sh` against the exact digest and expected revision/platforms.

Upstream conflict notes:

- Preserve OCI revision labeling. Image verification must fail closed if the revision label is absent or mismatched.
- Preserve digest-first production guidance. Do not let `latest`, `main`, or short commit tags become production references.
- Preserve source/upstream repo validation before using user-provided workflow inputs in labels, URLs, or fetch commands.
- Keep expensive build stages on the build platform where possible and cross-compile Go for the target platform. This avoids slow QEMU-heavy multi-arch builds.
- Do not put production configuration or secrets into build args, Docker layers, workflow summaries, image labels, or docs.

## Customer Production Cutover Documentation

Status: maintained.

Scope: docs only.

Primary files:

- `docs/CUSTOMER_PRODUCTION_CUTOVER.md`
- `docs/SELF_BUILT_IMAGE_RUNBOOK.md`
- `docs/BFANSYE_FORK.md`

Purpose:

- Make it clear that BFanSYe self-built images are non-official artifacts with separate provenance and rollback responsibilities.
- Require customer approval for the custom homepage/branding before replacing an official image.
- Require architecture/platform, source revision, version label, digest, and rollback checks before production cutover.
- Encourage staging/canary smoke tests and app-only restarts.

Verification:

- Check all referenced docs and scripts still exist.
- Confirm examples use digest-pinned references, not mutable tags.
- Confirm no concrete customer secrets, domains, passwords, API keys, or environment-specific values are committed.
- Confirm the customer cutover checklist still covers health, login, model listing, streaming, dashboard/admin, and payment/OAuth paths when applicable.

Upstream conflict notes:

- If upstream changes deployment docs or Docker Compose recommendations, compare them with `SELF_BUILT_IMAGE_RUNBOOK.md` and `CUSTOMER_PRODUCTION_CUTOVER.md`.
- Keep customer-specific release records outside the generic repo docs; this file should describe the process, not record a single stale deployment digest.
