<#
.SYNOPSIS
Unofficial Native Windows Installer & Updater for CodeRabbit CLI

.DESCRIPTION
Downloads the official Linux binary, decompiles the JavaScript bundle, 
and cross-compiles it into a native Windows executable (coderabbit.exe).
#>

$ErrorActionPreference = 'Stop'

function Show-Banner {
    Write-Host "==========================================================================" -ForegroundColor Blue
    $banner = @"
 	 	   __         __               __      
		  /   _  _| _|__)_ |_ |_ .|_  /  |  |  
		  \__(_)(_|(-| \(_||_)|_)||_  \__|__|                                      
			
			   CodeRabbit CLI
                      Unofficial Windows Port                         
                    Maintained by Sukarth Acharya                     
            https://github.com/sukarth/coderabbit-windows             
"@
    Write-Host $banner -ForegroundColor DarkCyan
    Write-Host "==========================================================================" -ForegroundColor Blue
}

Show-Banner

$InstallDir = Join-Path $env:LOCALAPPDATA "Programs\CodeRabbit"
$BinDir = Join-Path $InstallDir "bin"
$ExePath = Join-Path $BinDir "coderabbit.exe"

# --- 1. Version Checking ---
Write-Host "`n[*] Checking latest version..."
$LatestVersionUrl = "https://cli.coderabbit.ai/releases/latest/VERSION"
$LatestVersion = (Invoke-RestMethod -Uri $LatestVersionUrl).Trim()

if (Test-Path $ExePath) {
    $CurrentVersion = (& $ExePath --version 2>&1).Trim()
    
    if ($CurrentVersion -eq $LatestVersion) {
        Write-Host "You already have the latest version installed: " -NoNewline
        Write-Host "v$CurrentVersion" -ForegroundColor Green
        Write-Host "`nInstallation skipped. Your CLI is up to date!"
        exit
    } else {
        Write-Host "Update available! " -NoNewline
        Write-Host "v$CurrentVersion" -ForegroundColor Yellow -NoNewline
        Write-Host " -> " -NoNewline
        Write-Host "v$LatestVersion" -ForegroundColor Green
    }
} else {
    Write-Host "Installing version: " -NoNewline
    Write-Host "v$LatestVersion" -ForegroundColor Green
}

# --- 2. Environment Setup ---
if (-not (Get-Command bun -ErrorAction SilentlyContinue)) {
    Write-Host "`n[!] Bun is not installed. Installing Bun for Windows..." -ForegroundColor Yellow
    Invoke-Expression "& { $(Invoke-RestMethod -Uri 'https://bun.sh/install.ps1') }"
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

$TempDir = Join-Path $InstallDir "temp_build_$LatestVersion"
New-Item -ItemType Directory -Force -Path $TempDir | Out-Null
New-Item -ItemType Directory -Force -Path $BinDir | Out-Null

# --- 3. Fast Download with Progress Bar ---
Write-Host "`n[*] Downloading official CodeRabbit CLI (Linux Payload)..."
$ZipUrl = "https://cli.coderabbit.ai/releases/latest/coderabbit-linux-x64.zip"
$ZipPath = Join-Path $TempDir "coderabbit-linux-x64.zip"

Import-Module BitsTransfer
Start-BitsTransfer -Source $ZipUrl -Destination $ZipPath -DisplayName "Downloading CodeRabbit payload..."

Expand-Archive -Path $ZipPath -DestinationPath $TempDir -Force
$LinuxBinary = Join-Path $TempDir "coderabbit"

# --- 4. Decompile the Bun executable ---
Write-Host "`n[*] Unpacking CodeRabbit bundle natively..."
Set-Location $TempDir
bun install @shepherdjerred/bun-decompile --silent
bunx @shepherdjerred/bun-decompile $LinuxBinary

$DecompiledDir = Join-Path $TempDir "decompiled\bundled"
if (-not (Test-Path $DecompiledDir)) {
    Write-Error "Failed to decompile the CodeRabbit binary."
}

# --- 5. Resolve dependencies and compile ---
Write-Host "[*] Compiling native Windows executable..."
Set-Location $DecompiledDir
bun install --silent
bun build index.js --compile --target=bun-windows-x64 --outfile=$ExePath

if (-not (Test-Path $ExePath)) {
    Write-Error "Failed to compile the Windows executable."
}

Copy-Item -Path $ExePath -Destination (Join-Path $BinDir "cr.exe") -Force

# --- 6. Add to PATH ---
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (($userPath -split ';') -notcontains $BinDir) {
    $newPath = if ([string]::IsNullOrWhiteSpace($userPath)) { $BinDir } else { "$userPath;$BinDir" }
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    $env:Path = "$env:Path;$BinDir"
}

# --- 7. Cleanup ---
Set-Location $env:USERPROFILE
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  Success! CodeRabbit v$LatestVersion Installed " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "`nPlease restart your terminal, then run:"
Write-Host "  cr auth login" -ForegroundColor Cyan
