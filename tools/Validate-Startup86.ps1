$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
Set-Location $root
$env:APPDATA=Join-Path $root '.runtime/graphics86-validation-appdata'
$env:LOCALAPPDATA=Join-Path $root '.runtime/graphics86-validation-local'
$engine=Join-Path $root 'tools/godot/Godot_v4.5.1-stable_win64_console.exe'
$results=@()
$cases=@(
 @{Name='import';Args=@('--headless','--path','.','--editor','--import');Marker='DONE'},
 @{Name='resources';Args=@('--headless','--path','.','--script','tools/Test-Imports85.gd');Marker='IMPORT85 PASS'},
 @{Name='editor-vulkan-1';Args=@('--path','.','--editor','--rendering-method','forward_plus','--rendering-driver','vulkan','--position','19000,19000','--resolution','1280x720','--quit-after','180');Marker='Vulkan'},
 @{Name='editor-vulkan-2';Args=@('--path','.','--editor','--rendering-method','forward_plus','--rendering-driver','vulkan','--position','19000,19000','--resolution','1280x720','--quit-after','180');Marker='Vulkan'}
)
foreach($case85 in $cases){
 $out85='.runtime/graphics86-final-'+$case85.Name+'.stdout.log'
 $err85='.runtime/graphics86-final-'+$case85.Name+'.stderr.log'
 $p=Start-Process $engine -ArgumentList $case85.Args -WindowStyle Hidden -PassThru -RedirectStandardOutput $out85 -RedirectStandardError $err85
 $handle85=$p.Handle
 if(!$p.WaitForExit(90000)){Stop-Process -Id $p.Id;throw ('Startup timeout '+$case85.Name)}
 $stdout85=Get-Content -Raw $out85
 $stderr85=Get-Content -Raw $err85
 # Root CA access fails inside this sandbox even for an empty project.
 $allowed85=$stderr85 -replace '(?m)^ERROR: Failed to read the root certificate store\.\r?\n\s+at: get_system_ca_certificates[^\r\n]*\r?\n?',''
 $ok85=$p.ExitCode -eq 0 -and $stdout85.Contains($case85.Marker) -and $allowed85 -notmatch 'ERROR:|SCRIPT ERROR|SHADER ERROR|Parse Error|CrashHandlerException|Program crashed|signal 11'
 $results+=@{name=$case85.Name;pass=$ok85;exit_code=$p.ExitCode;root_certificate_sandbox_warning=$stderr85.Contains('Failed to read the root certificate store')}
 if(!$ok85){throw ('Startup failed '+$case85.Name+' exit='+$p.ExitCode+' marker='+$stdout85.Contains($case85.Marker)+' errors='+$allowed85+'; inspect '+$err85)}
 Write-Output ('PASS '+$case85.Name)
}
$report85=@{pass=$true;engine='4.5.1';gpu='RTX 5080';driver='621.01';isolated_profiles=$true;crash_reproduced=$false;cause_of_reported_crash='not established';cases=$results}
[IO.File]::WriteAllText((Join-Path $root 'docs/graphics86-editor-tests.json'),($report85 | ConvertTo-Json -Depth 8))



