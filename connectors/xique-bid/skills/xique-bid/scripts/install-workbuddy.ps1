[CmdletBinding()]
param(
    [string]$WorkBuddyHome = '',
    [string]$PackageVersion = '',
    [switch]$SkipLogin
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

if ([string]::IsNullOrWhiteSpace($WorkBuddyHome)) {
    if (-not [string]::IsNullOrWhiteSpace($env:WORKBUDDY_HOME)) {
        $WorkBuddyHome = $env:WORKBUDDY_HOME
    } else {
        $WorkBuddyHome = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.workbuddy'
    }
}
if ([string]::IsNullOrWhiteSpace($PackageVersion)) {
    if (-not [string]::IsNullOrWhiteSpace($env:XIQUE_WORKBUDDY_MCP_VERSION)) {
        $PackageVersion = $env:XIQUE_WORKBUDDY_MCP_VERSION
    } else {
        $PackageVersion = '0.9.3'
    }
}
if ($PackageVersion -notmatch '^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$') {
    throw "Invalid MCP npm package version: $PackageVersion"
}

$minimumVersion = [Version]'20.19.0'
$candidates = @()
$versionsRoot = Join-Path $WorkBuddyHome 'binaries\node\versions'
if (Test-Path -LiteralPath $versionsRoot -PathType Container) {
    foreach ($directory in Get-ChildItem -LiteralPath $versionsRoot -Directory -ErrorAction SilentlyContinue) {
        $nodePath = Join-Path $directory.FullName 'node.exe'
        $npxPath = Join-Path $directory.FullName 'npx.cmd'
        if (-not (Test-Path -LiteralPath $nodePath -PathType Leaf) -or
            -not (Test-Path -LiteralPath $npxPath -PathType Leaf)) {
            continue
        }
        try {
            $actualVersion = [Version]((& $nodePath --version 2>$null).TrimStart('v'))
            if ($actualVersion -ge $minimumVersion) {
                $candidates += [PSCustomObject]@{
                    Version = $actualVersion
                    Node = $nodePath
                    Npx = $npxPath
                    Source = 'WorkBuddy bundled Node'
                }
            }
        } catch {
            continue
        }
    }
}

$selected = $candidates | Sort-Object Version -Descending | Select-Object -First 1
if ($null -eq $selected) {
    $nodeCommand = Get-Command node.exe -ErrorAction SilentlyContinue
    if ($null -eq $nodeCommand) {
        $nodeCommand = Get-Command node -ErrorAction SilentlyContinue
    }
    $npxCommand = Get-Command npx.cmd -ErrorAction SilentlyContinue
    if ($null -eq $npxCommand) {
        $npxCommand = Get-Command npx -ErrorAction SilentlyContinue
    }
    if ($null -ne $nodeCommand -and $null -ne $npxCommand) {
        $actualVersion = [Version]((& $nodeCommand.Source --version 2>$null).TrimStart('v'))
        if ($actualVersion -ge $minimumVersion) {
            $selected = [PSCustomObject]@{
                Version = $actualVersion
                Node = $nodeCommand.Source
                Npx = $npxCommand.Source
                Source = 'System Node'
            }
        }
    }
}

if ($null -eq $selected) {
    throw 'Node.js 20.19.0 or newer was not found. Upgrade WorkBuddy and run the installer again.'
}

$configureScript = Join-Path $PSScriptRoot 'configure-workbuddy.mjs'
if (-not (Test-Path -LiteralPath $configureScript -PathType Leaf)) {
    throw "Installer file is missing: $configureScript"
}
$packageSpec = "@xqyz/workbuddy-plugin-xique@$PackageVersion"
$rawResult = & $selected.Node $configureScript `
    '--workbuddy-home' $WorkBuddyHome `
    '--command' $selected.Npx `
    '--package' $packageSpec
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to update the WorkBuddy MCP configuration.'
}
$result = (($rawResult -join "`n") | ConvertFrom-Json)

if ($result.changed) {
    Write-Output "Xique Bid MCP configuration saved (not active yet): $($result.configFile)"
    if (-not [string]::IsNullOrWhiteSpace([string]$result.backupFile)) {
        Write-Output "Existing configuration backup: $($result.backupFile)"
    }
} else {
    Write-Output "Xique Bid MCP configuration is already current, but activation must still be verified: $($result.configFile)"
}
Write-Output "Runtime: $($selected.Source) $($selected.Version)"
Write-Output "MCP package: $packageSpec (npx downloads it on first start)"

if (-not $SkipLogin) {
    $loginConfigFile = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.xq-opencli\config.json'
    $loggedIn = $false
    if (Test-Path -LiteralPath $loginConfigFile -PathType Leaf) {
        try {
            $loginConfig = Get-Content -Raw -Encoding UTF8 -LiteralPath $loginConfigFile | ConvertFrom-Json
            $loggedIn = -not [string]::IsNullOrWhiteSpace([string]$loginConfig.token)
        } catch {
            $loggedIn = $false
        }
    }
    if ($loggedIn) {
        Write-Output 'Existing Xique login detected; browser authorization was not repeated.'
    } else {
        Write-Output 'Opening Xique browser authorization. Complete login in the browser and return here.'
        & $selected.Npx '-y' '@xqyz/xq-cli@0.2.1' 'login' '--browser' '--timeout-sec' '600'
        if ($LASTEXITCODE -ne 0) {
            throw 'Xique browser login did not complete. The MCP registration was saved; run the installer again to retry login.'
        }
        Write-Output 'Xique login completed.'
    }
}

Write-Output 'WorkBuddy trust is still required: open 专家·技能·连接器 > 连接器 > MCP 服务管理, find xique-bid, and click 信任 if prompted.'
Write-Output 'Then fully exit and reopen WorkBuddy.'
Write-Output 'Installation is complete only after xique_runtime_status succeeds after restart.'
