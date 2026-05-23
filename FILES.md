# 文件说明

建议先读：

- `README.md`：项目简介、使用方法和注意事项。
- `skills/api-key-leak-checker-leop/SKILL.md`：Codex skill 的触发场景和工作流。
- `scripts/pre_publish_check.ps1`：发布前审查脚本，发现高风险时退出码为 `2`。

辅助文件：

- `references/tooling.md`：GitHub CLI、Gitleaks、TruffleHog 和 token 环境变量说明。
- `references/remediation.md`：疑似泄漏后的撤销、轮换和补救流程。
- `agents/openai.yaml`：Codex skill 的界面元数据。
- `skills/api-key-leak-checker-leop/`：GitHub Agent Skills 发布规范使用的正式 skill 包目录。
- `.github/workflows/pre-publish-check.yml`：GitHub Actions 自动审查流程。
- `.gitignore`：默认阻止 `.env`、私钥和常见敏感文件入库。

平台发布与安装：

- GitHub Agent Skills：已发布 `v1.0.0` release，可用 `gh skill preview` / `gh skill install`。
- skills.sh / `npx skills`：可用 `npx skills add leo-cheung-itlger/api-key-leak-checker-leop -l --full-depth` 识别到 1 个 skill。
- SkillsMD CLI：可用 `uvx skillsmd add leo-cheung-itlger/api-key-leak-checker-leop -l --full-depth` 识别到 1 个 skill。
- Agent Skills CLI / SkillsMP：已用 `npx agent-skills-cli submit-repo leo-cheung-itlger/api-key-leak-checker-leop` 提交索引。
- skills.re：网页导入能识别 `skills/api-key-leak-checker-leop/SKILL.md`，提交后等待平台索引。

发布前顺序：

1. 运行 `scripts/pre_publish_check.ps1`。
2. 只有退出码为 `0` 时再提交和推送。
3. 如果退出码为 `2`，先处理发现项并轮换可能泄漏的密钥。
