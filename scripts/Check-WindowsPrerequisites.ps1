# Game Dock: read-only Windows prerequisite audit. Does not install software.
$ErrorActionPreference = "Continue"
$missing = New-Object System.Collections.Generic.List[string]

function Check-Tool {
    param([string]$Name, [string]$Command, [bool]$Required)
    $found = Get-Command $Command -ErrorAction SilentlyContinue
    if ($null -eq $found) {
        if ($Required) { $script:missing.Add($Name) }
        Write-Host ("[MISSING] " + $Name) -ForegroundColor Yellow
        return
    }
    $version = ""
    try { $version = (& $Command --version 2>$null | Select-Object -First 1) } catch {}
    Write-Host ("[OK]      " + $Name + "  " + $version) -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================"
Write-Host " GAME DOCK - WINDOWS SETUP AUDIT"
Write-Host "========================================"
Write-Host ""

Check-Tool "Git" "git" $true
Check-Tool "Node.js" "node" $true
Check-Tool "npm" "npm" $true
Check-Tool "Rust compiler" "rustc" $true
Check-Tool "Cargo" "cargo" $true
Check-Tool "VS Code (optional)" "code" $false

$rustup = Get-Command rustup -ErrorAction SilentlyContinue
if ($null -ne $rustup) {
    try {
        $target = (& rustup show active-toolchain 2>$null)
        if ($target -match "pc-windows-msvc") {
            Write-Host ("[OK]      Rust MSVC target  " + $target) -ForegroundColor Green
        } else {
            $missing.Add("Rust MSVC toolchain")
            Write-Host ("[MISSING] Rust MSVC toolchain (active: " + $target + ")") -ForegroundColor Yellow
        }
    } catch { Write-Host "[CHECK]   Check Rust with: rustup show active-toolchain" }
}

$prog86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
$vswhere = Join-Path $prog86 "Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vswhere) {
    $msvc = & $vswhere -products "*" -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2>$null
    if ($msvc) {
        Write-Host ("[OK]      Visual Studio C++ Build Tools  " + ($msvc | Select-Object -First 1)) -ForegroundColor Green
    } else {
        $missing.Add("Visual Studio C++ Desktop development tools")
        Write-Host "[MISSING] Visual Studio C++ Desktop development tools" -ForegroundColor Yellow
    }
} else {
    $missing.Add("Visual Studio C++ Build Tools (verify manually)")
    Write-Host "[CHECK]   Visual Studio Build Tools not found through vswhere" -ForegroundColor Yellow
}

$webViewPatterns = @(
    "$prog86\Microsoft\EdgeWebView\Application\*\msedgewebview2.exe",
    "$env:ProgramFiles\Microsoft\EdgeWebView\Application\*\msedgewebview2.exe",
    "$env:LOCALAPPDATA\Microsoft\EdgeWebView\Application\*\msedgewebview2.exe"
)
$webView = $false
foreach ($pattern in $webViewPatterns) {
    if (Get-Item -Path $pattern -ErrorAction SilentlyContinue) { $webView = $true; break }
}
if ($webView) {
    Write-Host "[OK]      Microsoft Edge WebView2 runtime" -ForegroundColor Green
} else {
    Write-Host "[CHECK]   WebView2 not found in common paths; typically already available on Windows 11" -ForegroundColor Yellow
}

Write-Host ""
if ($missing.Count -eq 0) {
    Write-Host "Required command-line tools are present. Native build is not yet verified." -ForegroundColor Green
} else {
    Write-Host ("Needs attention: " + ($missing -join ", ")) -ForegroundColor Yellow
}
Write-Host ""
Write-Host "Install instructions: docs\WINDOWS_SETUP.md"
Write-Host "Rust: https://rustup.rs/"
Write-Host "Node: https://nodejs.org/en/download"
Write-Host "MSVC: https://visualstudio.microsoft.com/visual-cpp-build-tools/"
Write-Host "Tauri: https://v2.tauri.app/start/prerequisites/"
Write-Host ""
