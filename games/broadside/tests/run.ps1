param([string]$Godot = 'godot', [string]$Python = 'python')
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
function Invoke-GodotCheck([string[]]$ExtraArgs) {
    $lines = & $Godot --headless --path $project @ExtraArgs 2>&1
    $code = $LASTEXITCODE
    $lines | ForEach-Object { Write-Output $_ }
    if ($code -ne 0 -or ($lines -match 'SCRIPT ERROR:|ERROR:|FAIL:')) {
        throw "Godot validation failed (exit $code)."
    }
}
Invoke-GodotCheck @('--editor', '--quit')
Invoke-GodotCheck @('--quit-after', '30')
Invoke-GodotCheck @('--fixed-fps', '60', '--script', 'res://tests/combat_test.gd')
Invoke-GodotCheck @('--fixed-fps', '60', '--script', 'res://tests/ai_test.gd')
& $Python (Join-Path $PSScriptRoot 'manifest_test.py')
if ($LASTEXITCODE -ne 0) { throw 'Manifest validation failed.' }
