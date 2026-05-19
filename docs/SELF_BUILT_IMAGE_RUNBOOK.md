# Self-built GHCR Image Runbook

## 目标

使用自建 GHCR 镜像承接 Wei-Shaw/sub2api upstream main 的热修复, 同时保留 BFanSYe/sub2api 的自定义首页与功能.

生产环境必须使用 digest 固定镜像, 禁止使用 `latest` 或仅使用可变 tag 部署.

## 分支与来源策略

- 以 `BFanSYe/sub2api` 作为生产构建来源.
- 以 `Wei-Shaw/sub2api@main` 作为 upstream 热修复来源.
- 将 upstream main 的必要修复合入 BFanSYe 分支后再构建镜像.
- 对生产构建优先使用精确 commit SHA 作为 `source_ref`.
- 仅在人工确认的情况下使用分支名触发构建.
- 不在镜像内写入生产域名, API key, token, 数据库地址, 管理员密码或 `.env` 内容.
- 将生产配置留给 Compose, secret manager, 环境变量或部署平台注入.

## Upstream Sync 流程

1. 拉取 upstream main 最新提交.
2. 阅读 upstream 变更, 标记必须吸收的 hotfix commit.
3. 将必要 commit 合入或同步到 BFanSYe 构建分支.
4. 保留 BFanSYe 自定义首页, 支付, 管理端或其他 fork 特性.
5. 执行本地测试或 CI 测试.
6. 触发 `.github/workflows/build-sub2api-image.yml`.
7. 在 `required_fixes` 中填写必须包含的 upstream hotfix SHA, 一行一个.
8. 检查 workflow summary 与 `build-manifest.yaml`.
9. 只使用 `image@sha256:...` 更新生产 Compose.

## 风险分级

### R0: 文档与脚本变更

- 只影响 runbook, verify script, Makefile help target 或 CI 元数据.
- 不改变应用运行时行为.
- 验证要求: `bash -n`, YAML 语法检查, 只读脚本 dry run 或 help 输出.

### R1: 镜像重建但 source commit 不变

- 只改变构建环境, OCI label, manifest, tag 或缓存.
- 验证要求: 检查 digest, revision label, manifest, production Compose digest pin.

### R2: 吸收 upstream hotfix

- source commit 改变, 但目标是修复 upstream 已确认问题.
- 验证要求: `required_fixes` 全部为 source commit 祖先, upstream missing count 已记录, 应用测试通过.

### R3: Fork 功能与 upstream 冲突

- 涉及首页, 管理端, 支付, 鉴权, 配置模型或 API 行为冲突.
- 验证要求: 除 required fixes 外, 必须人工确认 BFanSYe 自定义功能仍存在, public homepage marker 可通过部署验证脚本检查.

### R4: 生产配置或 secret 触达风险

- 任何可能把生产 secret, 域名, token 或 `.env` 写入镜像的变更.
- 处理要求: 停止构建, 移除硬编码, 重新审查 Dockerfile, workflow, build args 与日志.

## Required Fixes 清单

- 将必须吸收的 upstream hotfix commit SHA 写入 workflow 的 `required_fixes`.
- 每行只写一个 SHA.
- 不写分支名, tag, PR 编号或自然语言说明.
- 如果是 merge/rebase upstream, 写 upstream 原始 SHA; 如果是 cherry-pick, 原始 upstream SHA 不再是祖先, 需要写 fork 中实际落地的 cherry-pick SHA, 并在发布记录中注明来源 upstream SHA.
- workflow 必须在构建前验证每个 SHA 都是 source commit 的祖先.
- 本地或生产前验证使用:

```bash
./scripts/verify-sub2api-image.sh \
  --image ghcr.io/OWNER/sub2api@sha256:DIGEST \
  --source-repo BFanSYe/sub2api \
  --expected-revision SOURCE_COMMIT \
  --required-fix UPSTREAM_HOTFIX_SHA
```

## CI 构建步骤

1. 打开 `Build Sub2API image` workflow.
2. 设置 `source_repo` 为 `BFanSYe/sub2api`.
3. 设置 `source_ref` 为待发布 commit SHA.
4. 设置 `upstream_repo` 为 `Wei-Shaw/sub2api`.
5. 设置 `upstream_ref` 为 `main`.
6. 在 `required_fixes` 中填写必须包含的 upstream hotfix SHA.
7. 设置 `image_name` 为生产使用的 GHCR image name.
8. 保持 `tag_latest=false`, 除非明确需要维护非生产 alias.
9. 触发 workflow.
10. 检查 summary 中的 source commit, upstream commit, missing upstream counts, digest.
11. 下载并归档 `build-manifest.yaml`.

## 镜像验证步骤

1. 使用 digest 引用验证远端镜像:

```bash
./scripts/verify-sub2api-image.sh \
  --image ghcr.io/OWNER/sub2api@sha256:DIGEST \
  --source-repo BFanSYe/sub2api \
  --expected-revision SOURCE_COMMIT \
  --expected-version 0.1.127 \
  --expected-platform linux/amd64 \
  --expected-platform linux/arm64 \
  --upstream-repo Wei-Shaw/sub2api \
  --upstream-ref main \
  --required-fix UPSTREAM_HOTFIX_SHA
```

2. 确认输出包含:
   - image inspect 成功.
   - `org.opencontainers.image.revision` 等于 source commit.
   - `org.opencontainers.image.version` 等于预期版本（如 `0.1.127`）.
   - 目标平台（如 `linux/amd64`, `linux/arm64`）存在于 manifest.
   - source commit 存在.
   - required fixes 全部为 source commit 的祖先.
   - missing upstream total 与 non-merge counts 已打印.

## 生产部署步骤

客户生产从 official image 切换到自建镜像前, 先阅读 `docs/CUSTOMER_PRODUCTION_CUTOVER.md`.

1. 只把 Compose image 改成 digest pinned reference:

```yaml
image: ghcr.io/OWNER/sub2api@sha256:DIGEST
```

2. 禁止使用以下形式部署生产:

```yaml
image: ghcr.io/OWNER/sub2api:latest
image: ghcr.io/OWNER/sub2api:main
image: ghcr.io/OWNER/sub2api:SHORT_SHA
```

3. 不把生产 secret, 生产域名或 `.env` 文件复制进镜像.
4. 部署后执行只读验证:

```bash
./scripts/verify-sub2api-deploy.sh \
  --service sub2api \
  --expected-image ghcr.io/OWNER/sub2api@sha256:DIGEST \
  --expected-revision SOURCE_COMMIT \
  --public-url https://PUBLIC_HOST/ \
  --homepage-marker "MARKER_TEXT"
```

5. 确认容器状态为 running.
6. 如配置了 healthcheck, 确认状态为 healthy.
7. 确认 `Config.Image` 与 digest pinned reference 完全一致.
8. 确认本地镜像 revision label 等于 source commit.
9. 确认 public URL HEAD 请求成功.
10. 如提供 homepage marker, 确认页面正文包含 marker.

## 回滚步骤

1. 从上一版发布记录或 Compose 历史中取回旧 digest.
2. 将 Compose image 改回旧 digest pinned reference.
3. 执行正常部署命令.
4. 执行 `verify-sub2api-deploy.sh`.
5. 记录回滚 digest, source commit, 时间与原因.
6. 不使用 `latest` 作为临时回滚目标.

## 禁止项

- 禁止生产 Compose 使用 `latest`.
- 禁止把生产 secret, token, password, private key, `.env` 内容写入镜像层.
- 禁止在验证脚本中执行 docker pull, docker compose up, restart, rm, tag, push 或 prune.
- 禁止在镜像构建日志中打印 secret.
- 禁止用未验证的 tag 替代 digest.
- 禁止跳过 required fixes 祖先检查后发布.

## 发布记录字段

每次生产发布至少记录:

- `source_repo`
- `source_ref_input`
- `source_commit`
- `upstream_repo`
- `upstream_ref`
- `upstream_commit`
- `missing_upstream_total`
- `missing_upstream_nonmerge`
- `image`
- `digest`
- `required_fixes`
- `build_run_url`
- 生产 Compose 中实际使用的 `image@sha256:...`
