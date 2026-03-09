<#
.SYNOPSIS
Uninstaller for CodeRabbit CLI Windows Port
#>

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

Write-Host ""
Write-Host ""
Write-Host "	    ============================================" -ForegroundColor Red
Write-Host "  	      Uninstalling CodeRabbit CLI Windows Port"   -ForegroundColor Red
Write-Host "	    ============================================" -ForegroundColor Red

# Strict confirmation loop
$confirmation = ""
while ($confirmation -notmatch "^(y|yes|n|no)$") {
    $confirmation = Read-Host "`nAre you sure you want to completely uninstall the CodeRabbit CLI? (y/n)"
}

if ($confirmation -match "^(n|no)$") {
    Write-Host "Uninstallation aborted by user." -ForegroundColor Yellow
    exit
}

Write-Host "`nProceeding with uninstallation..." -ForegroundColor Cyan

$InstallDir = Join-Path $env:LOCALAPPDATA "Programs\CodeRabbit"
$BinDir = Join-Path $InstallDir "bin"

# 1. Remove the directory
if (Test-Path $InstallDir) {
    Write-Host "[*] Removing CodeRabbit CLI files..."
    # We must stop any running instances first to avoid file lock errors
    Stop-Process -Name "coderabbit" -Force -ErrorAction SilentlyContinue
    Stop-Process -Name "cr" -Force -ErrorAction SilentlyContinue
    
    Remove-Item -Path $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "    Files deleted." -ForegroundColor Green
} else {
    Write-Host "[*] CodeRabbit CLI is not installed in the default location." -ForegroundColor Yellow
}

# 2. Clean up PATH
Write-Host "[*] Cleaning up Environment PATH..."
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$pathArray = $userPath -split ';'
$newPathArray = $pathArray | Where-Object { $_ -ne $BinDir }

if ($pathArray.Count -ne $newPathArray.Count) {
    $newPath = $newPathArray -join ';'
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    Write-Host "    PATH variable cleaned." -ForegroundColor Green
} else {
    Write-Host "    PATH variable was already clean." -ForegroundColor Green
}

# 3. Clean up auth tokens
$ConfigDir = Join-Path $env:APPDATA "CodeRabbit"
if (Test-Path $ConfigDir) {
    Write-Host "`n[*] Found stored CodeRabbit authentication tokens."
    $deleteTokens = Read-Host "    Do you want to delete your saved login session? (y/n)"
    if ($deleteTokens -match "^y") {
        Remove-Item -Path $ConfigDir -Recurse -Force
        Write-Host "    Authentication data deleted." -ForegroundColor Green
    } else {
        Write-Host "    Authentication data kept." -ForegroundColor Yellow
    }
}

Write-Host "`nUninstallation complete. Please restart your terminal to clear the 'cr' command from memory." -ForegroundColor Green
