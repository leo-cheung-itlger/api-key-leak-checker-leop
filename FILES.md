# 文件说明

建议先读：

- `README.md`：项目简介、使用方法和注意事项。
- `SKILL.md`：Codex skill 的触发场景和工作流。
- `scripts/pre_publish_check.ps1`：发布前审查脚本，发现高风险时退出码为 `2`。

辅助文件：

- `references/tooling.md`：GitHub CLI、Gitleaks、TruffleHog 和 token 环境变量说明。
- `references/remediation.md`：疑似泄漏后的撤销、轮换和补救流程。
- `agents/openai.yaml`：Codex skill 的界面元数据。
- `.github/workflows/pre-publish-check.yml`：GitHub Actions 自动审查流程。
- `.gitignore`：默认阻止 `.env`、私钥和常见敏感文件入库。

发布前顺序：

1. 运行 `scripts/pre_publish_check.ps1`。
2. 只有退出码为 `0` 时再提交和推送。
3. 如果退出码为 `2`，先处理发现项并轮换可能泄漏的密钥。

