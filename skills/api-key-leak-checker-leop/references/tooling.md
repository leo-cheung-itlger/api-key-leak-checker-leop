# Tooling Reference

Use existing tools before writing custom scanning logic.

## Baseline Checks

```powershell
git status --short
git remote -v
git log --oneline -n 5
Get-ChildItem -Force
```

Check likely risky files without printing secret values unless necessary:

```powershell
Get-ChildItem -Force -Recurse -File -Include ".env*", "*.key", "*.pem", "config*.json" |
  Select-Object FullName, Length, LastWriteTime
```

Avoid dumping full `.env`, key, token, or config contents into chat.

## GitHub CLI

Verify command availability:

```powershell
gh --version
where.exe gh
gh auth status
```

Persistent browser login:

```powershell
gh auth login --hostname github.com --git-protocol https --web
gh auth setup-git
gh auth status
```

If `gh` exists but is not recognized in old terminals, close and reopen the terminal. On this machine, a user-level wrapper may exist at:

```text
C:\Users\13678\AppData\Local\Microsoft\WindowsApps\gh.cmd
```

If `GITHUB_TOKEN` exists but `gh` asks for login, map it to `GH_TOKEN` without printing the token:

Use PowerShell to copy the user-level `GITHUB_TOKEN` value into user-level `GH_TOKEN`, then verify with `gh api user --jq ".login"`. Do not echo either environment variable.

## Gitleaks

Preferred scan:

```powershell
gitleaks detect --source . --redact --no-banner
```

Useful variants:

```powershell
gitleaks detect --source . --redact --no-banner --verbose
gitleaks protect --staged --redact --no-banner
```

If missing, install with an existing package manager when available:

```powershell
winget install Gitleaks.Gitleaks
choco install gitleaks -y
```

On this machine, `gitleaks` may be installed by WinGet with a user-level wrapper at:

```text
C:\Users\13678\AppData\Local\Microsoft\WindowsApps\gitleaks.cmd
```

## TruffleHog

Prefer verified findings when possible:

```powershell
trufflehog git file://. --only-verified --no-update
```

For GitHub targets:

```powershell
trufflehog github --repo https://github.com/OWNER/REPO --only-verified --no-update
```

If missing, install with an existing package manager when available:

```powershell
winget install TruffleSecurity.TruffleHog
```

## GitHub Built-ins

Use GitHub Secret Scanning and Push Protection when the account/repo supports them. If the user lacks permissions, report that as a required owner/admin action.

Official references:

- GitHub Secret Scanning: https://docs.github.com/en/code-security/secret-scanning
- GitHub CLI auth: https://cli.github.com/manual/gh_auth_login
- Gitleaks: https://github.com/gitleaks/gitleaks
- TruffleHog: https://github.com/trufflesecurity/trufflehog
