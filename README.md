# shaoyou11 Telegram Bot API 镜像

本仓库只负责构建镜像，不修改 Telegram Bot API 逻辑。

## 构建来源

源码唯一上游是 Telegram 官方的 `tdlib/telegram-bot-api`。GitHub Actions 会：

1. 解析官方源码的完整提交 SHA。
2. 编译镜像并执行版本、帮助参数等二进制烟雾测试。
3. 测试通过后发布到 `ghcr.io/shaoyou11/telegram-bot-api`。

## 发布标签

| 标签 | 用途 |
| --- | --- |
| `latest` | 官方默认分支最近一次通过测试的构建。 |
| `upstream-<官方完整提交 SHA>` | 可追溯的固定版本，用于回滚或复现。 |

NAS 当前使用 `latest`。更新脚本会在切换前给旧镜像建立本机回滚标签。
镜像只支持 NAS 当前使用的 `linux/amd64` 架构。

## 运行时配置

镜像兼容现有 EFB 配置：

| 变量 | 作用 |
| --- | --- |
| `TELEGRAM_API_ID` | Telegram API ID。 |
| `TELEGRAM_API_HASH` | Telegram API Hash。 |
| `TELEGRAM_LOCAL=1` | 启用 Telegram 官方本地模式。 |
| `TELEGRAM_HTTP_PORT` | 本地 Bot API 服务端口。 |

`TELEGRAM_LOCAL=1` 使用 Telegram 官方本地模式。官方说明该模式支持下载不设大小限制、上传最高 2000 MB，
以及返回本地文件路径。实际 EFB 转发上限仍取决于 EFB、ComWechat Bridge、存储空间和网络稳定性。

## 数据持久化

镜像不包含以下内容：

- API ID、API Hash 和 Bot Token。
- Telegram Bot API 数据目录。
- Telegram 聊天内容或运行日志。

运行数据由 Compose 挂载到 NAS 的：

```text
/var/lib/telegram-bot-api
```

删除 NAS 上的本地目录不会直接删除 Telegram 云端聊天记录，但会影响本地 Bot API 的文件缓存和运行状态。

## 许可证

上游源码使用 Telegram 官方仓库的 Boost Software License 1.0。使用本镜像前应阅读官方源码和许可证。
