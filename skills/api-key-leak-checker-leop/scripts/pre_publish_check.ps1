param(
    [string]$Path = ".",
    [switch]$Strict,
    [switch]$Json
)

$ErrorActionPreference = "Continue"

function Add-Finding {
    param(
        [string]$Severity,
        [string]$Rule,
        [string]$File,
        [int]$Line = 0,
        [string]$Message
    )
    $script:Findings.Add([pscustomobject]@{
        severity = $Severity
        rule = $Rule
        file = $File
        line = $Line
        message = $Message
    }) | Out-Null
}

function Test-CommandExists {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

$target = Resolve-Path -LiteralPath $Path
$Findings = [System.Collections.Generic.List[object]]::new()
$tools = [ordered]@{
    git = Test-CommandExists "git"
    gh = Test-CommandExists "gh"
    gitleaks = Test-CommandExists "gitleaks"
    trufflehog = Test-CommandExists "trufflehog"
}

$gitRepo = $false
$remote = ""
if ($tools.git) {
    Push-Location $target
    try {
        $null = & git rev-parse --is-inside-work-tree 2>$null
        if ($LASTEXITCODE -eq 0) {
            $gitRepo = $true
            $remote = (git remote -v 2>$null | Select-Object -First 1)
        }
    }
    finally {
        Pop-Location
    }
}

$skipDirs = @(".git", "node_modules", ".venv", "venv", "dist", "build", ".next", "target", ".cache")
$files = Get-ChildItem -LiteralPath $target -Force -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object {
        $full = $_.FullName
        -not ($skipDirs | Where-Object { $full -like "*\$_\*" })
    }

foreach ($file in $files) {
    $name = $file.Name
    $relative = $file.FullName.Substring($target.Path.Length).TrimStart("\")
    if ($name -match "^\.env(\..+)?$" -and $name -notmatch "^\.env\.example$") {
        Add-Finding "High" "risky-env-file" $relative 0 "Environment file would be unsafe to publish unless it is intentionally ignored and never committed."
    }
    elseif ($name -match "\.(key|pem|p12|pfx)$") {
        Add-Finding "High" "private-key-file" $relative 0 "Private key or certificate-like file found."
    }
    elseif ($name -match "^(secrets?|credentials?)\." -or $name -match "(secret|credential|token)") {
        Add-Finding "Medium" "risky-secret-filename" $relative 0 "File name suggests sensitive material; inspect before publishing."
    }
}

$patterns = @(
    @{ rule = "openai-api-key"; severity = "Critical"; regex = "sk-[A-Za-z0-9_-]{20,}" },
    @{ rule = "github-token"; severity = "Critical"; regex = "gh[pousr]_[A-Za-z0-9_]{20,}" },
    @{ rule = "github-fine-grained-token"; severity = "Critical"; regex = "github_pat_[A-Za-z0-9_]{20,}" },
    @{ rule = "aws-access-key"; severity = "Critical"; regex = "AKIA[0-9A-Z]{16}" },
    @{ rule = "google-api-key"; severity = "High"; regex = "AIza[0-9A-Za-z_-]{20,}" },
    @{ rule = "generic-secret-assignment"; severity = "High"; regex = "(?i)(api[_-]?key|secret|token|password)\s*[:=]\s*['""]?[^'""\s]{16,}" }
)

foreach ($file in $files) {
    if ($file.Length -gt 1048576) { continue }
    $relative = $file.FullName.Substring($target.Path.Length).TrimStart("\")
    try {
        $lines = @(Get-Content -LiteralPath $file.FullName -ErrorAction Stop)
    }
    catch {
        continue
    }
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = [string]$lines[$i]
        foreach ($pattern in $patterns) {
            if ($line -match $pattern.regex) {
                if ($line -match "(?i)(example|placeholder|your[-_ ]?api[-_ ]?key|dummy|fake)") { continue }
                Add-Finding $pattern.severity $pattern.rule $relative ($i + 1) "Secret-like content found. Value redacted; rotate if this was ever committed or published."
            }
        }
    }
}

if ($tools.gitleaks -and $gitRepo) {
    Push-Location $target
    try {
        gitleaks detect --source . --redact --no-banner *> $null
        if ($LASTEXITCODE -ne 0) {
            Add-Finding "High" "gitleaks" "." 0 "Gitleaks reported possible secrets. Re-run gitleaks locally for redacted detail."
        }
    }
    finally {
        Pop-Location
    }
}

if ($tools.trufflehog -and $gitRepo) {
    Push-Location $target
    try {
        $truffleOutput = trufflehog git file://. --only-verified --no-update 2>$null
        if ($truffleOutput) {
            Add-Finding "Critical" "trufflehog-verified" "." 0 "TruffleHog reported verified secrets. Rotate affected credentials immediately."
        }
    }
    finally {
        Pop-Location
    }
}

$blockingSeverities = @("Critical", "High")
if ($Strict) { $blockingSeverities += "Medium" }
$blocked = [bool]($Findings | Where-Object { $blockingSeverities -contains $_.severity })

$result = [pscustomobject]@{
    target = $target.Path
    gitRepo = $gitRepo
    remote = $remote
    tools = $tools
    strict = [bool]$Strict
    blocked = $blocked
    findings = $Findings
}

if ($Json) {
    $result | ConvertTo-Json -Depth 6
}
else {
    Write-Host "API Key Leak Pre-Publish Check"
    Write-Host "Target: $($result.target)"
    Write-Host "Git repo: $($result.gitRepo)"
    if ($result.remote) { Write-Host "Remote: $($result.remote)" }
    Write-Host "Blocked: $($result.blocked)"
    Write-Host ""
    if ($Findings.Count -eq 0) {
        Write-Host "No blocking secret indicators found."
    }
    else {
        $Findings | Sort-Object severity, file, line | Format-Table severity, rule, file, line, message -AutoSize
    }
}

if ($blocked) { exit 2 }
exit 0
