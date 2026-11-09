param(
 [Parameter(Mandatory)][string]$Destination,[Parameter(Mandatory)][string]$StateFolder,
 [Parameter(Mandatory)][string]$IndexHash,[Parameter(Mandatory)][string]$ArchiveHash,
 [string]$IndexUrl='',[string]$ArchiveUrl='',
 [string]$LocalIndex='',[string]$LocalArchive=''
)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Net.Http
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root=[IO.Path]::GetFullPath($Destination).TrimEnd('\')
$job=[IO.Path]::GetFullPath($StateFolder).TrimEnd('\')
New-Item -ItemType Directory -Force $job | Out-Null
$statePath=Join-Path $job 'state.json'
$status=@{status='scan';message='Scansione dei file installati';received=0L;total=0L;scanned=0;files=0}
function State([string]$Kind,[string]$Message){
 $status.status=$Kind; $status.message=$Message
 $temporary=Join-Path $job 'state.tmp'
 [IO.File]::WriteAllText($temporary,($status | ConvertTo-Json -Depth 6),[Text.UTF8Encoding]::new($false))
 for($stateAttempt=0;$stateAttempt -lt 5;$stateAttempt++){
  try{
   if(Test-Path -LiteralPath $statePath){[IO.File]::Replace($temporary,$statePath,[NullString]::Value)}else{[IO.File]::Move($temporary,$statePath)}
   break
  }catch [IO.IOException]{if($stateAttempt -ge 4){throw};Start-Sleep -Milliseconds 15}
 }
}
function SafePath([string]$Name){
 if(!$Name -or $Name.Contains('\') -or $Name.Contains(':') -or $Name.StartsWith('/') -or $Name.Split('/') -contains '..' -or $Name.Split('/') -contains '.' -or $Name.Split('/') -contains ''){throw [Security.SecurityException]::new('Unsafe update path')}
 if($Name -match '^(\.git|\.runtime|\.updates|user|userdata|saves|careers|legend72)(/|$)' -or $Name -match '(^|/)(roster-overrides\.json|settings\.cfg|legend-\d+\.json|career-\d+\.json)(\.|$)'){throw [Security.SecurityException]::new('Personal data in update index')}
 $target=[IO.Path]::GetFullPath((Join-Path $root $Name))
 if(!$target.StartsWith($root+'\',[StringComparison]::OrdinalIgnoreCase)){throw [Security.SecurityException]::new('Update escaped installation')}
 if(Test-Path -LiteralPath $target -PathType Container){throw [Security.SecurityException]::new('A required game file is occupied by a directory')}
 $probe=$target
 while($probe.Length -ge $root.Length){
  if((Test-Path -LiteralPath $probe) -and ((Get-Item -LiteralPath $probe).Attributes -band [IO.FileAttributes]::ReparsePoint)){throw [Security.SecurityException]::new('Redirected installation path')}
  $probe=Split-Path $probe
 }
 return $target
}
function Hash([string]$Path){return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()}
$client=[Net.Http.HttpClient]::new(); $client.Timeout=[TimeSpan]::FromSeconds(60)
$client.DefaultRequestHeaders.UserAgent.ParseAdd('Spike-Forever-Selective-Updater')
$bytesReceived=0L
function ReadBounded($Stream,[byte[]]$Buffer){
 $cancel=[Threading.CancellationTokenSource]::new(60000)
 try{return $Stream.ReadAsync($Buffer,0,$Buffer.Length,$cancel.Token).GetAwaiter().GetResult()}finally{$cancel.Dispose()}
}
function Range([long]$Start,[long]$Length){
 if($Length -eq 0){return ,([byte[]]@())}
 if($LocalArchive){
  $stream=[IO.File]::OpenRead($LocalArchive)
  try{
   $stream.Position=$Start; $bytes=[byte[]]::new([int]$Length); $offset=0
   while($offset -lt $Length){$read=$stream.Read($bytes,$offset,[int]($Length-$offset));if($read -le 0){throw 'Truncated local fixture'};$offset+=$read}
   $script:bytesReceived+=$Length; return ,$bytes
  }finally{$stream.Dispose()}
 }
 for($attempt=0;$attempt -lt 3;$attempt++){
  $request=[Net.Http.HttpRequestMessage]::new([Net.Http.HttpMethod]::Get,$ArchiveUrl)
  $request.Headers.Range=[Net.Http.Headers.RangeHeaderValue]::new($Start,($Start+$Length-1))
  $response=$null
  try{
   $response=$client.SendAsync($request,[Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
   $range=$response.Content.Headers.ContentRange
   if([int]$response.StatusCode -ne 206 -or !$range -or $range.From -ne $Start -or $range.To -ne ($Start+$Length-1) -or $range.Length -ne [long]$index.archive.size){throw 'Server does not support the verified byte range'}
   $inputStream=$response.Content.ReadAsStreamAsync().GetAwaiter().GetResult();$memory=[IO.MemoryStream]::new()
   try{
    $buffer=[byte[]]::new(131072);$count=0L;$last=[Diagnostics.Stopwatch]::StartNew()
    while(($read=ReadBounded $inputStream $buffer) -gt 0){
     $count+=$read;if($count -gt $Length){throw 'Oversized byte range'}
     $memory.Write($buffer,0,$read);$script:bytesReceived+=$read
     if($last.ElapsedMilliseconds -gt 150){$status.received=$script:bytesReceived;State 'download' 'Scaricamento dei soli file modificati';$last.Restart()}
    }
    if($count -ne $Length){throw 'Incomplete byte range'}
    return ,$memory.ToArray()
   }finally{$inputStream.Dispose();$memory.Dispose()}
  }catch{
   if($attempt -ge 2){throw}
   Start-Sleep -Milliseconds (500*($attempt+1))
  }finally{if($response){$response.Dispose()};$request.Dispose()}
 }
}
try{
 State 'scan' 'Verifica indice e scansione dei file installati'
 if($IndexHash -notmatch '^[a-fA-F0-9]{64}$' -or $ArchiveHash -notmatch '^[a-fA-F0-9]{64}$'){throw 'Invalid expected checksum'}
 if(!$LocalIndex){
  foreach($url in @($IndexUrl,$ArchiveUrl)){if($url -notmatch '^https://github\.com/Vanic17/spike-forever/releases/download/'){throw 'Unapproved release URL'}}
  $response=$client.GetAsync($IndexUrl,[Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
  try{
   $response.EnsureSuccessStatusCode()|Out-Null
   if($response.Content.Headers.ContentLength -gt 16777216){throw 'Oversized update index'}
   $LocalIndex=Join-Path $job 'index.json'
   $inputStream=$response.Content.ReadAsStreamAsync().GetAwaiter().GetResult();$outputStream=[IO.File]::Create($LocalIndex)
   try{
    $buffer=[byte[]]::new(32768);$count=0L
    while(($read=ReadBounded $inputStream $buffer) -gt 0){$count+=$read;if($count -gt 16777216){throw 'Oversized update index'};$outputStream.Write($buffer,0,$read)}
   }finally{$outputStream.Dispose();$inputStream.Dispose()}
  }finally{$response.Dispose()}
 }
 if(!$LocalArchive -and $ArchiveUrl -notmatch '^https://github\.com/Vanic17/spike-forever/releases/download/'){throw 'Unapproved archive URL'}
 if((Hash $LocalIndex) -ne $IndexHash.ToLowerInvariant()){throw 'Update index checksum mismatch'}
 $index=Get-Content -LiteralPath $LocalIndex -Raw -Encoding UTF8 | ConvertFrom-Json
 if($index.schema -ne 1 -or $index.archive.sha256 -ne $ArchiveHash.ToLowerInvariant() -or $index.archive.name -ne 'SpikeForever-Windows.zip'){throw 'Incompatible update index'}
 if($LocalArchive -and (Hash $LocalArchive) -ne $ArchiveHash.ToLowerInvariant()){throw 'Fixture archive checksum mismatch'}
 $needed=[Collections.Generic.List[object]]::new();$seen=@{};$manifest=@{mode='file-scan';version=$index.version;files=@{}}
 $status.files=@($index.files.PSObject.Properties).Count
 foreach($entry in $index.files.PSObject.Properties){
  $name=$entry.Name; $data=$entry.Value; $target=SafePath $name
  if($seen.ContainsKey($name.ToLowerInvariant())){throw 'Duplicate index path'};$seen[$name.ToLowerInvariant()]=$true
  if($data.sha256 -notmatch '^[a-f0-9]{64}$' -or [long]$data.size -lt 0 -or [long]$data.compressed_size -lt 0 -or [long]$data.compressed_size -gt 536870912 -or [long]$data.offset -lt 0 -or ([long]$data.offset+[long]$data.compressed_size) -gt [long]$index.archive.size -or $data.compression -notin @(0,8)){throw 'Invalid file metadata'}
  $manifest.files[$name]=$data.sha256
  $preserved=$name -in @('controls.cfg','assets/gameplay/league.json') -and (Test-Path -LiteralPath $target)
  if(!$preserved -and (!(Test-Path -LiteralPath $target -PathType Leaf) -or (Hash $target) -ne $data.sha256)){
   $needed.Add(@{name=$name;data=$data});$status.total+=[long]$data.compressed_size
  }
  $status.scanned++
  if($status.scanned%20 -eq 0){State 'scan' 'Scansione dei file installati'}
 }
 foreach($required in @('project.godot','src/main.gd','version.json','Avvia Spike Forever.cmd')){if(!$manifest.files.ContainsKey($required)){throw 'Incomplete target version'}}
 $status.changed_files=$needed.Count
 if($needed.Count -eq 0){State 'current' 'Tutti i file della versione selezionata sono gia verificati';exit 0}
 if(!$LocalArchive -and ($status.total -gt [long]$index.archive.size*.75 -or $needed.Count -gt 300)){State 'fallback' 'Installazione troppo diversa: uso il pacchetto completo';exit 0}
 $stage=Join-Path $job 'payload';New-Item -ItemType Directory -Force $stage | Out-Null
 State 'download' 'Scaricamento dei soli file modificati'
 foreach($file in $needed){
  $bytes=Range ([long]$file.data.offset) ([long]$file.data.compressed_size)
  $path=Join-Path $stage $file.name;New-Item -ItemType Directory -Force (Split-Path $path) | Out-Null
  $memory=[IO.MemoryStream]::new($bytes,$false);$decoder=$memory
  if($file.data.compression -eq 8){$decoder=[IO.Compression.DeflateStream]::new($memory,[IO.Compression.CompressionMode]::Decompress)}
  $output=[IO.File]::Create($path)
  try{
   $buffer=[byte[]]::new(131072);$written=0L
   while(($read=$decoder.Read($buffer,0,$buffer.Length)) -gt 0){$written+=$read;if($written -gt [long]$file.data.size){throw 'Decompressed file exceeds manifest size'};$output.Write($buffer,0,$read)}
   if($written -ne [long]$file.data.size){throw 'Decompressed file size mismatch'}
  }finally{$output.Dispose();if($decoder -ne $memory){$decoder.Dispose()};$memory.Dispose()}
  if((Hash $path) -ne $file.data.sha256){throw ('Downloaded file checksum mismatch: '+$file.name)}
  $status.received=$bytesReceived;State 'download' ('Verificato '+$file.name)
 }
 State 'verify' 'Preparazione installazione verificata'
 $package=Join-Path $job 'selective.zip';$zip=[IO.Compression.ZipFile]::Open($package,[IO.Compression.ZipArchiveMode]::Create)
 try{
  foreach($file in $needed){[IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,(Join-Path $stage $file.name),$file.name,[IO.Compression.CompressionLevel]::Optimal)|Out-Null}
  $writer=[IO.StreamWriter]::new($zip.CreateEntry('release-manifest.json').Open())
  try{$writer.Write(($manifest|ConvertTo-Json -Depth 8))}finally{$writer.Dispose()}
 }finally{$zip.Dispose()}
 $status.package=$package;$status.sha256=Hash $package;$status.received=$bytesReceived
 State 'ready' 'File modificati scaricati e verificati'
}catch [Security.SecurityException]{State 'error' $_.Exception.Message;exit 1
}catch{State 'fallback' $_.Exception.Message;exit 0
}finally{$client.Dispose()}
