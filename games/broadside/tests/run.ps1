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
# Allow editor import workers to settle before shutdown on Windows CI.
# Keep every nonzero exit and engine error fatal; this is not a retry/ignore.
Invoke-GodotCheck @('--editor', '--quit-after', '120', '--max-fps', '60')
Invoke-GodotCheck @('--script', 'res://tests/boot_test.gd')
Invoke-GodotCheck @('--fixed-fps', '60', '--script', 'res://tests/combat_test.gd')
Invoke-GodotCheck @('--fixed-fps', '60', '--script', 'res://tests/ai_test.gd')
Invoke-GodotCheck @('--fixed-fps', '60', '--script', 'res://tests/refinement_test.gd')
Invoke-GodotCheck @('--fixed-fps', '60', '--script', 'res://tests/m12_test.gd')
Invoke-GodotCheck @('--fixed-fps', '60', '--script', 'res://tests/balance_test.gd')
Invoke-GodotCheck @('--fixed-fps', '60', '--script', 'res://tests/viewport_test.gd')
Invoke-GodotCheck @('--fixed-fps', '60', '--script', 'res://tests/campaign_test.gd')
Invoke-GodotCheck @('--fixed-fps', '60', '--script', 'res://tests/shipyard_test.gd')
Invoke-GodotCheck @('--fixed-fps', '60', '--script', 'res://tests/odyssey_test.gd')
& $Python (Join-Path $PSScriptRoot 'manifest_test.py')
if ($LASTEXITCODE -ne 0) { throw 'Manifest validation failed.' }
