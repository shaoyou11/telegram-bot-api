# 官方 Telegram Bot API 镜像设计

## 目标

以 Telegram 官方 `tdlib/telegram-bot-api` 源码为唯一上游，由 `shaoyou11` 的 GitHub Actions 构建并发布 GHCR 镜像，替换当前第三方打包镜像。生产 Compose 继续使用 `latest`，同时保留按官方提交 SHA 生成的固定标签，便于审计和回滚。

## 构建与发布

- Dockerfile 通过官方仓库提交 SHA 拉取源码并编译，不提交 Telegram API ID、API Hash、Bot Token 或任何运行数据。
- GitHub Actions 支持手动触发和每日检查；每次构建发布 `latest` 与 `upstream-<官方提交 SHA>` 标签。
- 构建后执行二进制版本检查、帮助命令检查和本地模式启动检查，失败时不发布生产标签。
- OCI 标签记录官方源码仓库和完整提交 SHA，私有 EFB 锁定清单记录同一个提交。

## 运行兼容

- 保持当前容器名、共享网络命名空间、端口、环境变量和 `/var/lib/telegram-bot-api` 持久化目录。
- 入口脚本兼容现有 `TELEGRAM_API_ID`、`TELEGRAM_API_HASH`、`TELEGRAM_LOCAL` 和 HTTP 端口变量。
- `TELEGRAM_LOCAL=1` 继续启用官方本地模式，以保留大文件上传能力。

## 更新与回滚

- `operations/update_service.sh telegram-bot-api` 先创建配置备份并给当前镜像打本机回滚标签，再只拉取和重建 Bot API 容器。
- 更新验证四容器健康、EFB 进程、共享网络、Bot API 单实例和端口；失败自动恢复旧镜像。
- ComWechat、Watchdog 和 EFB 不因 Bot API 更新被主动重建。
- Telegram Bot API 数据目录不删除、不迁移、不调用 `logOut`；保留现有本地 Bot 会话数据。

## 验收标准

- 官方源码提交可追溯，镜像能在 NAS 的 `x86_64` 环境启动。
- `telegram-bot-api --version`、`getMe` 和本地模式健康检查通过。
- 更新后 EFB 能继续访问本地 Bot API，附件路径和共享网络正常。
- 旧镜像、配置备份和固定提交标签均可用于回滚。
