<#
.SYNOPSIS
Sets the GitHub Actions secrets needed by .github/workflows/ios_app_store.yml.

.DESCRIPTION
This script validates the local iOS/App Store Connect secret inputs, checks for
existing GitHub secrets, and writes the required encrypted repository secrets
using the GitHub CLI.

It never prints secret values. Existing secrets are not overwritten unless
-Force is provided.

.EXAMPLE
.\scripts\setup_ios_github_secrets.ps1 `
  -IssuerId "00000000-0000-0000-0000-000000000000" `
  -Repo "owner/repository"

.EXAMPLE
.\scripts\setup_ios_github_secrets.ps1 -IssuerId "00000000-0000-0000-0000-000000000000" -Force

.EXAMPLE
.\scripts\setup_ios_github_secrets.ps1 -IssuerId "00000000-0000-0000-0000-000000000000" -InstallGitHubCli

.EXAMPLE
.\scripts\setup_ios_github_secrets.ps1 -IssuerId "00000000-0000-0000-0000-000000000000" -InstallGitHubCli -LoginGitHub
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$IssuerId,

    [Parameter(Mandatory = $false)]
    [ValidatePattern('^[^/\s]+/[^/\s]+$')]
    [string]$Repo,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$KeyFile = "AuthKey_C45N5T7668.p8",

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$CertificatePrivateKeyFile = "ios_distribution_private_key.pem",

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$ClientEnvFile = "client_app\client_app\.env",

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$DriverEnvFile = "driver_app\driver_app\.env",

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [switch]$InstallGitHubCli,

    [Parameter(Mandatory = $false)]
    [switch]$LoginGitHub
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host "[ios-secrets] $Message"
}

function Fail {
    param([Parameter(Mandatory = $true)][string]$Message)
    throw "[ios-secrets] $Message"
}

function Resolve-RepoRoot {
    $root = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($root)) {
        Fail "Run this script from inside the Git repository."
    }
    return (Resolve-Path -LiteralPath $root.Trim()).Path
}

function Resolve-RequiredFile {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $candidate = if ([System.IO.Path]::IsPathRooted($Path)) {
        $Path
    } else {
        Join-Path $RepoRoot $Path
    }

    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
        Fail "$Label not found: $candidate"
    }

    $item = Get-Item -LiteralPath $candidate
    if ($item.Length -le 0) {
        Fail "$Label is empty: $candidate"
    }

    return $item.FullName
}

function Require-Command {
    param([Parameter(Mandatory = $true)][string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        Fail "Missing command '$Name'. Install it first, then rerun this script."
    }
}

function Install-GitHubCli {
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        return
    }

    if (-not $InstallGitHubCli) {
        Fail "Missing command 'gh'. Install GitHub CLI or rerun with -InstallGitHubCli."
    }

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Step "Installing GitHub CLI with winget"
        winget install --id GitHub.cli --source winget --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
            Fail "GitHub CLI installation failed."
        }

        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("Path", "User")

        if (Get-Command gh -ErrorAction SilentlyContinue) {
            return
        }
    }

    Write-Step "Installing portable GitHub CLI under .tools"
    $toolsDir = Join-Path $repoRoot ".tools"
    $ghDir = Join-Path $toolsDir "gh"
    $zipPath = Join-Path $toolsDir "gh_windows_amd64.zip"
    New-Item -ItemType Directory -Force -Path $toolsDir | Out-Null
    if (Test-Path -LiteralPath $ghDir) {
        Remove-Item -LiteralPath $ghDir -Recurse -Force
    }

    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        $latestHeaders = curl.exe -sSIL "https://github.com/cli/cli/releases/latest"
        $location = $latestHeaders |
            Where-Object { $_ -match '^location:\s*https://github\.com/cli/cli/releases/tag/(v[0-9.]+)' } |
            Select-Object -Last 1
        if ([string]::IsNullOrWhiteSpace($location) -or $location -notmatch '(v[0-9.]+)') {
            Fail "Could not resolve latest GitHub CLI release tag."
        }

        $tag = $Matches[1]
        $version = $tag.TrimStart("v")
        $assetUrl = "https://github.com/cli/cli/releases/download/$tag/gh_${version}_windows_amd64.zip"
        curl.exe -L --fail --retry 3 --output $zipPath $assetUrl
        if ($LASTEXITCODE -ne 0) {
            Fail "Portable GitHub CLI download failed."
        }
    } else {
        Fail "GitHub CLI is missing and curl.exe is not available. Install GitHub CLI from https://cli.github.com/"
    }

    Expand-Archive -LiteralPath $zipPath -DestinationPath $ghDir -Force
    Remove-Item -LiteralPath $zipPath -Force -ErrorAction SilentlyContinue

    $ghExe = Get-ChildItem -LiteralPath $ghDir -Recurse -Filter gh.exe |
        Select-Object -First 1
    if ($null -eq $ghExe) {
        Fail "Portable GitHub CLI download did not contain gh.exe."
    }

    $env:Path = $ghExe.DirectoryName + ";" + $env:Path
    Write-Step "Using portable GitHub CLI at $($ghExe.FullName)"

    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        Fail "GitHub CLI is still not available after portable install."
    }
}

function Ensure-GitHubAuth {
    gh auth status 1>$null 2>$null
    if ($LASTEXITCODE -eq 0) {
        return
    }

    if (-not $LoginGitHub) {
        Fail "GitHub CLI is not authenticated. Run 'gh auth login' first, or rerun this script with -LoginGitHub."
    }

    Write-Step "Starting GitHub login"
    gh auth login --web --hostname github.com --git-protocol https --scopes repo
    if ($LASTEXITCODE -ne 0) {
        Fail "GitHub login failed."
    }

    gh auth status 1>$null 2>$null
    if ($LASTEXITCODE -ne 0) {
        Fail "GitHub CLI is still not authenticated."
    }
}

function Get-RepoFromGitHubCli {
    $repoValue = gh repo view --json nameWithOwner --jq .nameWithOwner 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($repoValue)) {
        return $null
    }
    return $repoValue.Trim()
}

function Get-KeyIdFromFileName {
    param([Parameter(Mandatory = $true)][string]$Path)
    $name = [System.IO.Path]::GetFileName($Path)
    if ($name -notmatch '^AuthKey_([A-Z0-9]+)\.p8$') {
        Fail "API key file must look like AuthKey_KEYID.p8. Got: $name"
    }
    return $Matches[1]
}

function Test-TextFileContains {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if (-not (Select-String -LiteralPath $Path -Pattern $Pattern -Quiet)) {
        Fail "$Label does not look valid: $Path"
    }
}

function Get-Base64FileContent {
    param([Parameter(Mandatory = $true)][string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    return [Convert]::ToBase64String($bytes)
}

function New-TempSecretFile {
    param([Parameter(Mandatory = $true)][string]$Content)
    $path = [System.IO.Path]::GetTempFileName()
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($path, $Content, $utf8NoBom)
    return $path
}

function Set-GitHubSecret {
    param(
        [Parameter(Mandatory = $true)][string]$RepoName,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Value,
        [Parameter(Mandatory = $true)][string[]]$ExistingSecrets,
        [Parameter(Mandatory = $true)][bool]$Overwrite,
        [Parameter(Mandatory = $true)][bool]$OnlyDryRun
    )

    $alreadyExists = $ExistingSecrets -contains $Name
    if ($alreadyExists -and -not $Overwrite) {
        Fail "Secret '$Name' already exists in $RepoName. Rerun with -Force to overwrite it."
    }

    if ($OnlyDryRun) {
        $action = if ($alreadyExists) { "would overwrite" } else { "would create" }
        Write-Step "$action secret $Name"
        return
    }

    $tempFile = New-TempSecretFile -Content $Value
    try {
        gh secret set $Name --repo $RepoName --body-file $tempFile | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Fail "Failed to set GitHub secret '$Name'."
        }
    } finally {
        Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
    }

    $actionDone = if ($alreadyExists) { "Updated" } else { "Created" }
    Write-Step "$actionDone secret $Name"
}

Require-Command "git"
$repoRoot = Resolve-RepoRoot
Set-Location -LiteralPath $repoRoot
Install-GitHubCli

Write-Step "Checking GitHub CLI authentication"
Ensure-GitHubAuth

if ([string]::IsNullOrWhiteSpace($Repo)) {
    $Repo = Get-RepoFromGitHubCli
    if ([string]::IsNullOrWhiteSpace($Repo)) {
        Fail "Could not detect GitHub repository. Pass -Repo owner/repository."
    }
}

Write-Step "Using GitHub repository $Repo"

$workflowPath = Resolve-RequiredFile -RepoRoot $repoRoot -Path ".github\workflows\ios_app_store.yml" -Label "iOS GitHub Actions workflow"
$keyPath = Resolve-RequiredFile -RepoRoot $repoRoot -Path $KeyFile -Label "App Store Connect API .p8 key"
$certKeyPath = Resolve-RequiredFile -RepoRoot $repoRoot -Path $CertificatePrivateKeyFile -Label "Apple distribution certificate private key"
$clientEnvPath = Resolve-RequiredFile -RepoRoot $repoRoot -Path $ClientEnvFile -Label "Client .env"
$driverEnvPath = Resolve-RequiredFile -RepoRoot $repoRoot -Path $DriverEnvFile -Label "Driver .env"

$keyId = Get-KeyIdFromFileName -Path $keyPath
Test-TextFileContains -Path $keyPath -Pattern 'BEGIN PRIVATE KEY' -Label "App Store Connect API key"
Test-TextFileContains -Path $certKeyPath -Pattern 'BEGIN (RSA )?PRIVATE KEY' -Label "Certificate private key"
Test-TextFileContains -Path $workflowPath -Pattern 'APP_STORE_CONNECT_ISSUER_ID' -Label "iOS workflow"

if ($IssuerId.Trim().Length -lt 10) {
    Fail "Issuer ID is too short. Copy the full Issuer ID from App Store Connect API page."
}

Write-Step "Checking existing GitHub Actions secrets"
$existingSecretsOutput = gh secret list --repo $Repo 2>$null
if ($LASTEXITCODE -ne 0) {
    Fail "Could not list secrets for $Repo. Check your GitHub permissions."
}

$existingSecrets = @()
if (-not [string]::IsNullOrWhiteSpace($existingSecretsOutput)) {
    $existingSecrets = $existingSecretsOutput |
        ForEach-Object { ($_ -split '\s+')[0] } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
}

$secrets = [ordered]@{
    APP_STORE_CONNECT_ISSUER_ID = $IssuerId.Trim()
    APP_STORE_CONNECT_KEY_IDENTIFIER = $keyId
    APP_STORE_CONNECT_PRIVATE_KEY = [System.IO.File]::ReadAllText($keyPath)
    CERTIFICATE_PRIVATE_KEY = [System.IO.File]::ReadAllText($certKeyPath)
    CLIENT_DOTENV_BASE64 = Get-Base64FileContent -Path $clientEnvPath
    DRIVER_DOTENV_BASE64 = Get-Base64FileContent -Path $driverEnvPath
}

$duplicates = @($secrets.Keys | Where-Object { $existingSecrets -contains $_ })
if ($duplicates.Count -gt 0 -and -not $Force) {
    $list = $duplicates -join ", "
    Fail "These secrets already exist: $list. Rerun with -Force to overwrite them."
}

foreach ($entry in $secrets.GetEnumerator()) {
    Set-GitHubSecret `
        -RepoName $Repo `
        -Name $entry.Key `
        -Value $entry.Value `
        -ExistingSecrets $existingSecrets `
        -Overwrite ([bool]$Force) `
        -OnlyDryRun ([bool]$DryRun)
}

if ($DryRun) {
    Write-Step "Dry run complete. No GitHub secrets were changed."
} else {
    Write-Step "Done. GitHub Actions secrets are ready for the iOS App Store workflow."
}
