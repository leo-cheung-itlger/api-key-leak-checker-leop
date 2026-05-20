---
name: api-key-leak-checker-leop
description: Check GitHub repositories, local Git projects, AI coding projects, and Vibe Coding apps for possible API key, token, secret, .env, and config leaks. Use when the user asks to scan for leaked keys, exposed credentials, GitHub secret scanning, Gitleaks, TruffleHog, .gitignore hardening, push protection, API key rotation, or remediation after accidentally committing secrets.
---

# API Key Leak Checker LEOP

## Purpose

Use this skill to run a safety-first API key leak check, remediation workflow, and pre-publish gate for open-source releases. Do not build a custom scanner from scratch unless existing tools are unavailable. Prefer existing tools, project scripts, GitHub built-ins, and provider dashboards.

Treat any secret that reached a public repository, public issue, public build log, shared screenshot, or deployed client bundle as compromised. Removing the file is not enough; the key must be revoked or rotated at the provider.

## Fast Workflow

1. Identify the target: local repo path, GitHub URL, owner/repo, username, or organization.
2. Preserve safety: never ask the user to paste secrets, passwords, cookies, tokens, or raw credentials into chat.
3. Inspect repo state before scanning:
   - `git status --short`
   - `git remote -v`
   - `.gitignore`, `.env*`, `config*.json`, `*.key`, `*.pem`, CI files, deployment files
4. Run existing scanners first:
   - Run `scripts/pre_publish_check.ps1 -Path <repo>` as the local gate
   - Prefer `gitleaks detect --source . --redact --no-banner`
   - Use `trufflehog git file://. --only-verified --no-update` when available
   - For GitHub exposure, use `gh` and GitHub web/secret scanning when authenticated
5. Classify findings:
   - `Critical`: likely live secret in public repo, Git history, public build logs, or client-side bundle
   - `High`: likely secret in private repo history or shared artifact
   - `Medium`: secret-like value, placeholder risk, weak `.gitignore`, or missing push protection
   - `Low`: docs/example-only placeholder with clear fake marker
6. Remediate in the right order:
   - Tell the user to revoke or rotate exposed keys in the provider dashboard first.
   - Remove hardcoded secrets from code and config.
   - Move runtime values to environment variables or a secret manager.
   - Add ignore rules and pre-commit/CI scanning.
   - Only discuss Git history rewriting after rotation, and require explicit user approval before destructive or force-push steps.
7. Report clearly:
   - What was checked
   - What was found
   - Whether any key must be rotated
   - What changed locally
   - What the user must still do manually

## Pre-Publish Gate

Before creating a public repository, pushing code, opening a source release, or sharing a project zip, run:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\13678\.codex\skills\api-key-leak-checker-leop\scripts\pre_publish_check.ps1" -Path "<repo-path>"
```

Use `-Strict` when the user wants medium-risk filenames to block publication too:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\13678\.codex\skills\api-key-leak-checker-leop\scripts\pre_publish_check.ps1" -Path "<repo-path>" -Strict
```

Interpret exit codes:

- `0`: no blocking indicators found
- `2`: block publish until findings are reviewed and fixed
- other nonzero: check failed and must be rerun after fixing the error

The script redacts values and reports rule names, files, and line numbers only. Do not publish when it reports `Critical` or `High`.

## GitHub CLI Login

If `gh auth status` says not logged in, use browser login and verify persistence:

```powershell
gh auth login --hostname github.com --git-protocol https --web
gh auth setup-git
gh auth status
Test-Path "$env:APPDATA\GitHub CLI\hosts.yml"
```

If browser login does not persist, guide the user to create a GitHub Personal Access Token in the browser and enter it locally with `gh auth login --with-token`. Do not ask them to paste the token into chat or write it into files.

If the user already has `GITHUB_TOKEN` but `gh` asks for login, map it to `GH_TOKEN` in the user environment and verify with `gh api user --jq '.login'`. Do not print the token value.

## Tool References

Read `references/tooling.md` when choosing commands, installing missing scanners, or diagnosing authentication.

Read `references/remediation.md` when a finding looks real, when a key may have entered history, or when the user asks what to do after leakage.

## Output Template

```markdown
## API Key Leak Check

Checked:
- Local repo:
- Remote:
- Tools:

Findings:
- Critical:
- High:
- Medium:
- Low:

Required user actions:
- Rotate/revoke:
- Provider dashboards:

Local hardening:
- .gitignore:
- Environment variables:
- Pre-commit/CI:

Residual risk:
- Git history:
- Public forks/caches:
```
