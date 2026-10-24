param([Parameter(Mandatory)][string]$Godot, [Parameter(Mandatory)][string]$OutputDirectory)
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$manifest = Get-Content (Join-Path $PSScriptRoot 'game.json') -Raw | ConvertFrom-Json
if ($manifest.id -ne 'broadside' -or $manifest.executable -ne 'Broadside.exe' -or $manifest.version -notmatch '^[A-Za-z0-9.-]+$') { throw 'Invalid package identity/version' }
$output = [IO.Path]::GetFullPath($OutputDirectory)
$payload = Join-Path $output ('payload-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $payload | Out-Null
$exe = Join-Path $payload 'Broadside.exe'
$lines = & $Godot --headless --path $project --export-release 'Windows Desktop' $exe 2>&1
$code = $LASTEXITCODE
$lines | Write-Output
if ($code -ne 0 -or $lines -match 'ERROR:|SCRIPT ERROR:') { throw 'Windows export failed' }
Copy-Item (Join-Path $PSScriptRoot 'game.json') $payload
foreach ($name in @('Broadside.exe','Broadside.pck','game.json')) {
    if ((Get-Item (Join-Path $payload $name)).Length -eq 0) { throw "Empty $name" }
}
$log = Join-Path $payload 'smoke.log'
$harness = Join-Path $project 'tests/boot_test.gd'
$process = Start-Process -FilePath $exe -ArgumentList @('--headless','--script',('"' + $harness + '"'),'--log-file',('"' + $log + '"')) -WindowStyle Hidden -PassThru
if (-not $process.WaitForExit(60000)) { $process.Kill(); throw 'Export smoke test timed out' }
$text = Get-Content $log -Raw
if ($process.ExitCode -ne 0 -or $text -match 'ERROR:|FAIL:' -or $text -notmatch 'PASS: main scene boot') { throw 'Exported executable smoke failed' }
$zip = Join-Path $output "Broadside-windows-x64-$($manifest.version).zip"
Compress-Archive -LiteralPath @($exe,(Join-Path $payload 'Broadside.pck'),(Join-Path $payload 'game.json')) -DestinationPath $zip -Force
$archive = [IO.Compression.ZipFile]::OpenRead($zip)
try {
    $names = @($archive.Entries.FullName | Sort-Object)
    if (($names -join ',') -ne 'Broadside.exe,Broadside.pck,game.json') { throw 'ZIP payload must be three root files' }
} finally { $archive.Dispose() }
Write-Output "PASS: exported runtime boot and exact root ZIP payload: $zip"
