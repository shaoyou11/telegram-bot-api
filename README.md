# shaoyou11 Telegram Bot API 镜像

本仓库只负责构建镜像，不修改 Telegram Bot API 逻辑。

源码唯一上游是 Telegram 官方的 `tdlib/telegram-bot-api`。GitHub Actions 会解析官方源码的完整提交 SHA，先构建并执行二进制烟雾测试，再发布到 `ghcr.io/shaoyou11/telegram-bot-api`。

发布标签：

- `latest`：官方默认分支最近一次通过测试的构建。
- `upstream-<官方完整提交 SHA>`：可追溯的固定版本标签。

NAS 当前使用 `latest`，更新脚本会在切换前给旧镜像建立本机回滚标签。镜像只支持 NAS 当前使用的 `linux/amd64` 架构。

运行时兼容现有 EFB 配置：

- `TELEGRAM_API_ID`
- `TELEGRAM_API_HASH`
- `TELEGRAM_LOCAL=1`
- `TELEGRAM_HTTP_PORT`

`TELEGRAM_LOCAL=1` 使用 Telegram 官方本地模式。官方说明该模式支持下载不设大小限制、上传最高 2000 MB，以及返回本地文件路径；实际 EFB 转发上限还取决于 EFB 和 Bridge 的处理逻辑。

镜像不包含 API ID、API Hash、Bot Token、Telegram Bot API 数据目录或任何聊天内容。运行数据仍由 Compose 挂载到 NAS 的 `/var/lib/telegram-bot-api`。

上游源码使用 Telegram 官方仓库的 Boost Software License 1.0。使用本镜像前应阅读官方源码和许可证。
