# Customer Production Cutover Change Note

## Scope

- Custom image source: `BFanSYe/sub2api` at the exact `source_commit` recorded in the build manifest and GitHub Actions summary.
- Baseline: official Sub2API v0.1.127 plus the upstream `main` commits recorded in the build manifest.
- Deployment requirement: deploy by immutable image digest only, for example `image@sha256:...`.
- Included changes: official latest fixes plus fork homepage and CI/image-build changes.
- Backend compatibility statement: no fork-specific backend API changes and no fork-specific database migration changes are included in this cutover scope.
- Configuration boundary: no secrets, customer-specific domains, customer names, tokens, passwords, or environment-specific values belong in the image or this note.
- Release identity requirement: attach the exact image digest, source commit, upstream commit, version label, platform list, and rollback digest to each customer-specific cutover record.

## Production Risks And Mitigations

- Risk: this is a non-official image, so the deploying team owns source-of-truth, digest, provenance, and rollback records.
  Mitigation: record source commit, upstream baseline, image digest, build run, verification output, approver, and rollback digest before production cutover.
- Risk: customers may not expect the FusionGate/custom homepage branding or behavior.
  Mitigation: obtain explicit customer approval for the FusionGate/custom homepage before replacing the official image.
- Risk: production nodes may require a different CPU architecture than the image manifest provides.
  Mitigation: verify required platforms before deployment, at minimum `linux/amd64` or `linux/arm64` as applicable.
- Risk: official image behavior and fork image behavior can diverge in edge paths.
  Mitigation: validate in staging or canary first, then cut over during a low-traffic window.
- Risk: infrastructure changes can increase blast radius.
  Mitigation: perform an app-only restart using the existing runtime configuration; do not change database, network, secret, or compose structure as part of this cutover.
- Risk: rollback may be delayed if the previous image reference is not pinned.
  Mitigation: keep the previous official digest ready and roll back by restoring that digest reference.

## Pre-Cutover Checklist

- Confirm the customer approved the FusionGate/custom homepage.
- Confirm the image reference is an immutable digest, not `latest` or a mutable tag.
- Confirm the image version label is `0.1.127`.
- Confirm the image revision label matches the selected `source_commit` in the build manifest.
- Confirm the required platform exists in the image manifest.
- Confirm staging or canary has passed smoke tests.
- Confirm the previous official image digest is recorded for rollback.
- Confirm the cutover is limited to an app-only restart.

## Image Verification

Use the image digest selected for release:

```bash
./scripts/verify-sub2api-image.sh \
  --image IMAGE_REF_WITH_DIGEST \
  --source-repo BFanSYe/sub2api \
  --expected-revision SOURCE_COMMIT_FROM_BUILD_MANIFEST \
  --expected-version 0.1.127 \
  --expected-platform linux/amd64 \
  --expected-platform linux/arm64
```

Adjust `--expected-platform` to match the actual production architecture set.

## Smoke Tests

Run the checks that apply to the customer deployment:

- `/health`.
- Login.
- `/v1/models`.
- Streaming request path.
- Dashboard/admin pages.
- Payment flow if payment is enabled.
- OAuth flow if OAuth is enabled.

## Cutover

1. Replace only the application image reference with the verified immutable digest.
2. Restart only the application service.
3. Run the smoke tests above.
4. Keep monitoring application health, login, model listing, streaming, dashboard/admin, and enabled payment/OAuth paths.
5. Record the final digest, source commit, verification result, cutover time, and operator.

## Rollback

1. Restore the previously recorded official image digest.
2. Restart only the application service.
3. Re-run smoke tests.
4. Record rollback time, restored digest, and observed reason.
