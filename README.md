# API Key Leak Checker LEOP

一个给小白和 AI 编程用户用的发布前安全审查小工具。

它的目标很简单：在你把项目开源、推到 GitHub、发压缩包、交给别人之前，先帮你挡一遍常见的 API Key / Token / `.env` / 配置文件泄漏风险。

## 为什么做这个

我是在看了 B 站视频《GitHub上正在发生大规模API Key泄漏事件，小白需警惕！》后做的这个工具。视频里提醒了一个很现实的问题：AI 让写代码变容易了，但很多新手并不知道密钥不能直接写进代码，更不能推到公开仓库。

一旦 key 进了公开 GitHub，就应该当作已经泄漏。只删除文件不够，必须去服务商后台撤销或轮换。

## 能做什么

- 检查 `.env`、私钥、证书、可疑配置文件是否准备被发布。
- 检查常见密钥形状，例如 OpenAI Key、GitHub Token、AWS Access Key、Google API Key。
- 优先调用成熟工具 `gitleaks`，如果本机安装了 `trufflehog` 也会辅助检查。
- 发现 `Critical` 或 `High` 风险时，用退出码 `2` 阻断发布。
- 输出文件名、行号和规则名，不打印密钥值。
- 提供 Codex skill，让智能体以后能按同一套流程做“上传前审查”。

## 快速使用

在 PowerShell 里运行：

```powershell
powershell -ExecutionPolicy Bypass -File ".\scripts\pre_publish_check.ps1" -Path "你的仓库路径"
```

严格模式会把中风险文件名也作为阻断项：

```powershell
powershell -ExecutionPolicy Bypass -File ".\scripts\pre_publish_check.ps1" -Path "你的仓库路径" -Strict
```

退出码：

- `0`：没有发现阻断级风险
- `2`：发现疑似泄漏风险，先不要上传
- 其他非 0：检查过程出错，修好后重跑

## 推荐搭配

- GitHub Secret Scanning
- GitHub Push Protection
- Gitleaks
- TruffleHog
- `.gitignore`
- GitHub Actions / pre-commit hook

## Codex Skill

这个仓库本身也是一个 Codex skill：

```text
api-key-leak-checker-leop
```

触发场景包括：

- “帮我检查这个仓库有没有 API Key 泄漏”
- “开源前先审查一下”
- “这个项目能不能推 GitHub”
- “帮我补 `.gitignore`，别把密钥传上去”
- “我好像把 key 提交了，怎么办”

## 注意

这个工具不能保证发现所有秘密，也不能替你撤销已经泄漏的 key。只要密钥曾经公开出现过，请立刻去对应服务商后台撤销或轮换。

我是新手，也是在边学边做。欢迎提 issue、给建议，也欢迎 star 鼓励一下。

