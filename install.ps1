[CmdletBinding()]
param(
    [switch] $SkipKeyPrompt,
    [string] $ModuleRoot,
    [string] $ProfilePath,
    [string] $ShimDir,
    [switch] $SkipPathUpdate
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$moduleName = 'ClaudeDeepSeek'
$moduleFileName = "$moduleName.psm1"

if (-not $ModuleRoot) {
    if ($PSVersionTable.PSEdition -eq 'Core') {
        $ModuleRoot = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Modules'
    }
    else {
        $ModuleRoot = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Modules'
    }
}

if (-not $ProfilePath) {
    $ProfilePath = $PROFILE.CurrentUserAllHosts
}

if (-not $ShimDir) {
    $localAppData = [Environment]::GetFolderPath('LocalApplicationData')

    if ([string]::IsNullOrWhiteSpace($localAppData)) {
        $localAppData = Join-Path $HOME 'AppData\Local'
    }

    $ShimDir = Join-Path $localAppData 'ClaudeDeepSeek\bin'
}

$targetModuleDir = Join-Path $ModuleRoot $moduleName
$targetModuleFile = Join-Path $targetModuleDir $moduleFileName

New-Item -ItemType Directory -Force -Path $targetModuleDir | Out-Null
New-Item -ItemType Directory -Force -Path $ShimDir | Out-Null

$moduleContent = @'
Set-StrictMode -Version Latest

$script:ClaudeDeepSeekEnvironment = @{
    ANTHROPIC_BASE_URL             = 'https://api.deepseek.com/anthropic'
    ANTHROPIC_MODEL                = 'deepseek-v4-pro[1m]'
    ANTHROPIC_DEFAULT_OPUS_MODEL   = 'deepseek-v4-pro[1m]'
    ANTHROPIC_DEFAULT_SONNET_MODEL = 'deepseek-v4-pro[1m]'
    ANTHROPIC_DEFAULT_HAIKU_MODEL  = 'deepseek-v4-flash'
    CLAUDE_CODE_SUBAGENT_MODEL     = 'deepseek-v4-flash'
    CLAUDE_CODE_EFFORT_LEVEL       = 'max'
}

function ConvertTo-PlainText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Security.SecureString] $SecureString
    )

    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)

    try {
        [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        if ($bstr -ne [IntPtr]::Zero) {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
    }
}

function Set-ClaudeDeepSeekKey {
    [CmdletBinding()]
    param(
        [string] $ApiKey
    )

    if ([string]::IsNullOrWhiteSpace($ApiKey)) {
        $secureKey = Read-Host -Prompt 'DeepSeek API key' -AsSecureString
        $ApiKey = ConvertTo-PlainText -SecureString $secureKey
    }

    if ([string]::IsNullOrWhiteSpace($ApiKey)) {
        throw 'DeepSeek API key cannot be empty.'
    }

    [Environment]::SetEnvironmentVariable('DEEPSEEK_API_KEY', $ApiKey, 'User')
    $env:DEEPSEEK_API_KEY = $ApiKey

    Write-Host 'DeepSeek API key saved to the user environment variable DEEPSEEK_API_KEY.'
}

function Get-ClaudeDeepSeekKey {
    [CmdletBinding()]
    param()

    if (-not [string]::IsNullOrWhiteSpace($env:DEEPSEEK_API_KEY)) {
        return $env:DEEPSEEK_API_KEY
    }

    $userKey = [Environment]::GetEnvironmentVariable('DEEPSEEK_API_KEY', 'User')

    if (-not [string]::IsNullOrWhiteSpace($userKey)) {
        $env:DEEPSEEK_API_KEY = $userKey
        return $userKey
    }

    return $null
}

function Invoke-ClaudeDeepSeek {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]] $Arguments
    )

    $claudeCommand = Get-Command 'claude' -ErrorAction SilentlyContinue

    if ($null -eq $claudeCommand) {
        throw "Claude Code CLI was not found on PATH.`n`nInstall it first:`n  npm install -g @anthropic-ai/claude-code"
    }

    $apiKey = Get-ClaudeDeepSeekKey

    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        throw "DeepSeek API key was not found.`n`nSet it with:`n  cld-key"
    }

    $managedNames = @('ANTHROPIC_AUTH_TOKEN') + @($script:ClaudeDeepSeekEnvironment.Keys)
    $previousValues = @{}

    foreach ($name in $managedNames) {
        $previousValues[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
    }

    try {
        foreach ($entry in $script:ClaudeDeepSeekEnvironment.GetEnumerator()) {
            [Environment]::SetEnvironmentVariable($entry.Key, $entry.Value, 'Process')
        }

        [Environment]::SetEnvironmentVariable('ANTHROPIC_AUTH_TOKEN', $apiKey, 'Process')

        & $claudeCommand.Source @Arguments
    }
    finally {
        foreach ($name in $managedNames) {
            [Environment]::SetEnvironmentVariable($name, $previousValues[$name], 'Process')
        }
    }
}

Set-Alias -Name 'claude-deepseek' -Value Invoke-ClaudeDeepSeek
Set-Alias -Name 'cld' -Value Invoke-ClaudeDeepSeek
Set-Alias -Name 'cld-key' -Value Set-ClaudeDeepSeekKey

Export-ModuleMember -Function Invoke-ClaudeDeepSeek, Set-ClaudeDeepSeekKey -Alias 'claude-deepseek', 'cld', 'cld-key'
'@

Set-Content -LiteralPath $targetModuleFile -Value $moduleContent -Encoding UTF8

$cldPs1 = @'
Import-Module ClaudeDeepSeek
Invoke-ClaudeDeepSeek @args

if ($null -ne $LASTEXITCODE) {
    exit $LASTEXITCODE
}
'@

$cldKeyPs1 = @'
Import-Module ClaudeDeepSeek
Set-ClaudeDeepSeekKey
'@

$cldCmd = @'
@echo off
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0cld.ps1" %*
exit /b %ERRORLEVEL%
'@

$claudeDeepSeekCmd = @'
@echo off
call "%~dp0cld.cmd" %*
exit /b %ERRORLEVEL%
'@

$cldKeyCmd = @'
@echo off
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0cld-key.ps1"
exit /b %ERRORLEVEL%
'@

Set-Content -LiteralPath (Join-Path $ShimDir 'cld.ps1') -Value $cldPs1 -Encoding UTF8
Set-Content -LiteralPath (Join-Path $ShimDir 'cld-key.ps1') -Value $cldKeyPs1 -Encoding UTF8
Set-Content -LiteralPath (Join-Path $ShimDir 'cld.cmd') -Value $cldCmd -Encoding ASCII
Set-Content -LiteralPath (Join-Path $ShimDir 'claude-deepseek.cmd') -Value $claudeDeepSeekCmd -Encoding ASCII
Set-Content -LiteralPath (Join-Path $ShimDir 'cld-key.cmd') -Value $cldKeyCmd -Encoding ASCII

function Test-PathContainsEntry {
    param(
        [string] $PathValue,
        [string] $Entry
    )

    if ([string]::IsNullOrWhiteSpace($PathValue)) {
        return $false
    }

    $normalizedEntry = $Entry.TrimEnd('\')

    foreach ($part in ($PathValue -split ';')) {
        if ($part.Trim().TrimEnd('\') -ieq $normalizedEntry) {
            return $true
        }
    }

    return $false
}

if (-not $SkipPathUpdate) {
    $userPath = [string] [Environment]::GetEnvironmentVariable('Path', 'User')

    if (-not (Test-PathContainsEntry -PathValue $userPath -Entry $ShimDir)) {
        $newUserPath = if ([string]::IsNullOrWhiteSpace($userPath)) {
            $ShimDir
        }
        else {
            "$userPath;$ShimDir"
        }

        [Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User')
    }

    if (-not (Test-PathContainsEntry -PathValue $env:Path -Entry $ShimDir)) {
        $env:Path = "$env:Path;$ShimDir"
    }
}

$profileDir = Split-Path -Parent $ProfilePath

if (-not (Test-Path -LiteralPath $profileDir)) {
    New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
}

if (-not (Test-Path -LiteralPath $ProfilePath)) {
    New-Item -ItemType File -Force -Path $ProfilePath | Out-Null
}

$importLine = 'Import-Module ClaudeDeepSeek'
$profileContent = [string](Get-Content -LiteralPath $ProfilePath -Raw)

if ($profileContent -notmatch '(?m)^\s*Import-Module\s+ClaudeDeepSeek\s*$') {
    Add-Content -LiteralPath $ProfilePath -Value ''
    Add-Content -LiteralPath $ProfilePath -Value $importLine
}

Import-Module $targetModuleDir -Force

if (-not $SkipKeyPrompt) {
    Set-ClaudeDeepSeekKey
}

Write-Host ''
Write-Host 'ClaudeDeepSeek installed.'
Write-Host ''
Write-Host 'Open a new terminal, then run:'
Write-Host '  cld'
Write-Host ''
Write-Host 'You can update your DeepSeek API key later with:'
Write-Host '  cld-key'
