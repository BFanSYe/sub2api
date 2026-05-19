# BFanSYe Sub2API Fork

This repository is BFanSYe's maintained fork of [`Wei-Shaw/sub2api`](https://github.com/Wei-Shaw/sub2api).

The fork exists to track upstream Sub2API fixes while carrying a small set of BFanSYe-specific patches and a reproducible self-built GHCR image pipeline.

## Relationship To Upstream

- Upstream source of truth: [`Wei-Shaw/sub2api`](https://github.com/Wei-Shaw/sub2api).
- Fork source for self-built production images: [`BFanSYe/sub2api`](https://github.com/BFanSYe/sub2api).
- The upstream README and product documentation are intentionally preserved as much as possible to reduce future merge conflicts.
- Fork-specific operating rules live in this file and the linked runbooks below.

This fork should not claim to be an official upstream release. Treat every self-built image as a BFanSYe-maintained artifact with its own provenance, verification output, and rollback record.

## What This Fork Carries

### Custom homepage patch

The public homepage is customized with a FusionGate-ready, editorial landing page while keeping Sub2API's runtime public-setting overrides.

Key properties:

- The visible brand/title follows the deployment's `site_name` public setting, so deployments can show markers such as `FusionGate` without hard-coding customer-specific text into the image.
- The admin-provided `home_content` override still takes precedence over the default homepage.
- Scroll reveal uses `[data-reveal]` elements and `useScrollReveal()` for progressive fade/slide-in behavior.
- The intended scope is frontend-only: no fork-specific backend API or database migration changes are expected from this patch.

See [`CUSTOM_PATCHES.md`](CUSTOM_PATCHES.md) for file ownership, verification, and upstream-conflict notes.

### Self-built GHCR image pipeline

The fork can publish GHCR images from a clean GitHub Actions checkout.

Key properties:

- Production images must be referenced by immutable digest, for example:

  ```yaml
  image: ghcr.io/bfansye/sub2api@sha256:<digest>
  ```

- Short commit tags are aliases only; do not use them as the production source of truth.
- The workflow records OCI labels, including source repository, source revision, version, and creation time.
- The workflow uploads a `build-manifest.yaml` artifact with source/upstream commits, missing-upstream counts, platforms, tags, digest, required fixes, and build run URL.
- Customer-facing images should remain multi-platform unless an explicit release decision says otherwise.

See [`SELF_BUILT_IMAGE_RUNBOOK.md`](SELF_BUILT_IMAGE_RUNBOOK.md) for the build and verification workflow.

### Read-only verification scripts

The fork includes scripts for image and deployment verification:

- [`../scripts/verify-sub2api-image.sh`](../scripts/verify-sub2api-image.sh): verifies a remote image digest, OCI revision/version labels, required-fix ancestry, upstream gap, and expected platforms without pulling or rebuilding the image.
- [`../scripts/verify-sub2api-deploy.sh`](../scripts/verify-sub2api-deploy.sh): verifies a running deployment's exact image reference, local image revision label, health state, public URL, and optional homepage marker without restarting or mutating services.

## Maintenance Rules

1. Keep fork-specific deltas small and documented.
2. Prefer merging or rebasing upstream fixes into the fork before building a production image.
3. For production builds, prefer an exact full commit SHA as `source_ref`.
4. Use `required_fixes` for must-have upstream hotfixes and require them to be ancestors of the selected source commit.
5. Before publishing an image, check the build manifest and verify:
   - `source_commit` is the intended fork commit.
   - `org.opencontainers.image.revision` matches `source_commit`.
   - `missing_upstream_total` and `missing_upstream_nonmerge` are understood and recorded.
   - required platforms are present.
6. Do not build production images from a dirty local checkout.
7. Do not put production domains, API keys, tokens, passwords, database URLs, `.env` files, or customer-specific values into the image.
8. Do not deploy production with `latest`, `main`, or a short SHA tag alone.

## Routine Upstream Sync Checklist

Use this shape when absorbing upstream fixes:

1. Fetch both remotes:

   ```bash
   git fetch origin main
   git fetch upstream main
   ```

2. Merge or rebase upstream changes into the fork branch.
3. Preserve the custom homepage and image-pipeline patches listed in [`CUSTOM_PATCHES.md`](CUSTOM_PATCHES.md).
4. Verify upstream coverage:

   ```bash
   git merge-base --is-ancestor upstream/main HEAD
   git rev-list --left-right --count upstream/main...HEAD
   ```

   For a fully synced fork, the left-side count should be `0`; the right-side count is the fork-only patch count.

5. Run the relevant tests/builds for the touched areas.
6. Trigger `.github/workflows/build-sub2api-image.yml` with explicit inputs.
7. Verify the resulting digest using `scripts/verify-sub2api-image.sh`.
8. For production cutover, follow [`CUSTOMER_PRODUCTION_CUTOVER.md`](CUSTOMER_PRODUCTION_CUTOVER.md) and deploy by digest only.

## Customer Production Boundary

Before replacing an official image in a customer environment, explicitly confirm:

- The customer accepts the custom homepage/branding behavior.
- The deployment architecture is supported by the image manifest.
- The image digest, source commit, upstream baseline, version label, platform list, and rollback digest are recorded.
- Staging or canary smoke tests have passed.
- The cutover is app-only and does not recreate Postgres/Redis or change secrets/networking.

See [`CUSTOMER_PRODUCTION_CUTOVER.md`](CUSTOMER_PRODUCTION_CUTOVER.md) for the customer-facing checklist.

## Documentation Map

- [`CUSTOM_PATCHES.md`](CUSTOM_PATCHES.md): fork-owned deltas, file scope, verification, and conflict notes.
- [`SELF_BUILT_IMAGE_RUNBOOK.md`](SELF_BUILT_IMAGE_RUNBOOK.md): GHCR image build, manifest, verification, deployment, and rollback rules.
- [`CUSTOMER_PRODUCTION_CUTOVER.md`](CUSTOMER_PRODUCTION_CUTOVER.md): customer production risk review and cutover checklist.
- [`.github/workflows/build-sub2api-image.yml`](../.github/workflows/build-sub2api-image.yml): manual GHCR image build workflow.
- [`scripts/verify-sub2api-image.sh`](../scripts/verify-sub2api-image.sh): read-only remote image verification.
- [`scripts/verify-sub2api-deploy.sh`](../scripts/verify-sub2api-deploy.sh): read-only running deployment verification.
