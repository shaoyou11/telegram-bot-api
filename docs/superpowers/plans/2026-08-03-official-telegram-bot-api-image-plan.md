# 官方 Telegram Bot API 镜像 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 从 Telegram 官方 `tdlib/telegram-bot-api` 源码构建 `shaoyou11` 自有 GHCR 镜像，并安全替换 NAS 上的本地 Bot API 容器。

**Architecture:** GitHub Actions 解析官方源码提交 SHA，构建多阶段 Docker 镜像，发布 `latest` 和 `upstream-<sha>` 标签。NAS Compose 使用 `ghcr.io/shaoyou11/telegram-bot-api:latest`，更新脚本只重建 Bot API，并保留旧镜像与数据目录回滚。

**Tech Stack:** C++17/CMake、Ubuntu 24.04、Docker Buildx、GitHub Actions、Docker Compose、Python unittest、飞牛 NAS。

## Global Constraints

- 官方源码仓库固定为 `tdlib/telegram-bot-api`。
- 运行时必须兼容 `TELEGRAM_API_ID`、`TELEGRAM_API_HASH`、`TELEGRAM_LOCAL` 和 HTTP 端口变量。
- 不把任何 API 凭据、Bot Token、聊天数据或运行数据写入镜像或 Git。
- 保留 `/var/lib/telegram-bot-api` 持久化挂载，不调用 `logOut`，不迁移 Bot 会话。
- 生产配置使用 `latest`，固定提交标签用于审计和回滚。
- NAS 更新只重建 `efb2026-telegram-bot-api-1`，不主动重建 ComWechat、Watchdog 或 EFB。

### Task 1: 入口参数契约

**Files:**
- Create: `tests/test_entrypoint.py`
- Create: `docker-entrypoint.sh`

**Interfaces:**
- Consumes: `TELEGRAM_API_ID`, `TELEGRAM_API_HASH`, `TELEGRAM_LOCAL`, `TELEGRAM_HTTP_PORT`。
- Produces: 传给官方二进制的参数序列，缺少必填 API 参数时以非零状态退出。

- [ ] Write the failing test for API arguments, local mode, HTTP port, and missing credentials.
- [ ] Run `python3 -m unittest -v tests/test_entrypoint.py` and confirm failure because the entrypoint is absent.
- [ ] Implement a POSIX entrypoint that uses `set --`, appends `--local` only when enabled, appends `--http-port` only when configured, and executes `telegram-bot-api` without printing secrets.
- [ ] Run the focused unittest and confirm all cases pass.

### Task 2: Official source Docker build

**Files:**
- Create: `Dockerfile`
- Create: `.dockerignore`

**Interfaces:**
- Consumes: `TELEGRAM_BOT_API_REF` build argument containing a full official commit SHA.
- Produces: `/usr/local/bin/telegram-bot-api` plus the entrypoint in a runtime-only image.

- [ ] Build from `https://github.com/tdlib/telegram-bot-api.git` with recursive submodules and the supplied full SHA.
- [ ] Install only the documented build dependencies in the builder and the runtime libraries in the final image.
- [ ] Set the working directory to `/var/lib/telegram-bot-api` and preserve the current container port 8081.
- [ ] Validate locally with `docker build`, `telegram-bot-api --version`, and `telegram-bot-api --help` when Docker is available.

### Task 3: Reproducible GitHub publishing

**Files:**
- Create: `.github/workflows/publish.yml`
- Modify: `README.md`

**Interfaces:**
- Consumes: official default branch HEAD, optional manual `upstream_ref` input.
- Produces: GHCR tags `latest` and `upstream-<full official SHA>`, OCI source/revision labels, build and smoke-test result.

- [ ] Resolve the official branch HEAD to a full SHA before building.
- [ ] Build and smoke-test the image before pushing; publish only after the test succeeds.
- [ ] Run on manual dispatch and a daily schedule; do not include secrets in build args.
- [ ] Document official source provenance, tags, local mode, 2GB local upload ceiling, and rollback usage.

### Task 4: EFB private configuration integration

**Files:**
- Modify: `efb-config-private/docker-compose.example.yaml`
- Modify: `efb-config-private/operations/update_service.sh`
- Modify: `efb-config-private/operations/upstream-lock.json`
- Modify: `efb-config-private/README.md`

**Interfaces:**
- Consumes: the new GHCR image and official source SHA.
- Produces: a private deployment template and update path using the owned image.

- [ ] Replace only the Telegram Bot API image reference with the `shaoyou11` GHCR image.
- [ ] Change the update script rollback image name while retaining the current old-image tag flow.
- [ ] Add the official upstream repository and current full SHA to the audit lock.
- [ ] Document that the owned image is a rebuild, not a modified Telegram server.
- [ ] Run JSON parsing, Compose config validation, and the existing operations tests.

### Task 5: Publish and deploy with rollback

**Files:**
- NAS `/vol4/1000/docker/efb/docker-compose.yaml`
- NAS `/vol4/1000/docker/efb/operations/update_service.sh`

- [ ] Commit and push the new image repository and private configuration using Chinese commit logs.
- [ ] Wait for the GitHub build, test, and push workflow to pass.
- [ ] Create a timestamped NAS config backup and run the service update script for `telegram-bot-api` only.
- [ ] If verification fails, let the script restore the old image and report the blocker.
- [ ] Verify Bot API version, `getMe`, local port, EFB health, shared network, attachment mode, restart counts, and unchanged ComWechat/Watchdog/EFB containers.
