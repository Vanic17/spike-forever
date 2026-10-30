$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$assetRoot=Join-Path (Split-Path $PSScriptRoot) 'assets/art/ball68'
New-Item -ItemType Directory -Force $assetRoot | Out-Null
function FontPath([string]$text,[float]$size,[float]$x,[float]$y){
 $path=New-Object Drawing.Drawing2D.GraphicsPath
 $family=New-Object Drawing.FontFamily('Arial')
 $path.AddString($text,$family,[int][Drawing.FontStyle]::Bold,$size,(New-Object Drawing.PointF($x,$y)),[Drawing.StringFormat]::GenericTypographic)
 $points=$path.PathPoints; $types=$path.PathTypes; $svg=New-Object Text.StringBuilder
 for($i=0;$i -lt $points.Length;$i++){
  $point=$points[$i]; $kind=$types[$i] -band 7
  $coord=$point.X.ToString('0.###',[Globalization.CultureInfo]::InvariantCulture)+' '+$point.Y.ToString('0.###',[Globalization.CultureInfo]::InvariantCulture)
  if($kind -eq 0){[void]$svg.Append('M'+$coord+' ')}
  elseif($kind -eq 1){[void]$svg.Append('L'+$coord+' ')}
  elseif($kind -eq 3){
   [void]$svg.Append('C'+$coord+' ')
   for($j=1;$j -le 2;$j++){$i++; $point=$points[$i]; [void]$svg.Append($point.X.ToString('0.###',[Globalization.CultureInfo]::InvariantCulture)+' '+$point.Y.ToString('0.###',[Globalization.CultureInfo]::InvariantCulture)+' ')}
  }
  if(($types[$i] -band 128) -ne 0){[void]$svg.Append('Z ')}
 }
 $family.Dispose(); $path.Dispose(); return '<path fill="white" d="'+$svg.ToString()+'"/>'
}
$body=(FontPath 'MIKASA' 90 16 40)+(FontPath 'V200W' 46 177 145)
$svg='<svg xmlns="http://www.w3.org/2000/svg" width="512" height="256" viewBox="0 0 512 256">'+$body+'</svg>'
[IO.File]::WriteAllText((Join-Path $assetRoot 'mark.svg'),$svg,(New-Object Text.UTF8Encoding($false)))
