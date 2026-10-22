$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$destination=Join-Path $root 'tools/godot/Godot_v4.5.1-stable_win64.exe'
$expected='a829242096d640007de9fa93ea923d0f666d13d6a3b472a0231c820be6dc7627'
if((Test-Path -LiteralPath $destination) -and (Get-FileHash -LiteralPath $destination).Hash -eq $expected){Write-Output 'Godot runtime ready';exit 0}
$staging=Join-Path $root ('.engine-download-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $staging | Out-Null
$archive=Join-Path $staging 'godot.zip'
Invoke-WebRequest 'https://github.com/godotengine/godot/releases/download/4.5.1-stable/Godot_v4.5.1-stable_win64.exe.zip' -OutFile $archive
Expand-Archive -LiteralPath $archive -DestinationPath $staging
$engine=Join-Path $staging 'Godot_v4.5.1-stable_win64.exe'
if((Get-FileHash -LiteralPath $engine).Hash -ne $expected){throw 'Godot runtime checksum mismatch'}
New-Item -ItemType Directory -Force (Split-Path $destination) | Out-Null
Copy-Item -LiteralPath $engine -Destination $destination -Force
$console=Join-Path $staging 'Godot_v4.5.1-stable_win64_console.exe'
if(Test-Path -LiteralPath $console){Copy-Item -LiteralPath $console -Destination (Split-Path $destination) -Force}
Write-Output 'Godot 4.5.1 runtime installed; launch Spike Forever.exe'
