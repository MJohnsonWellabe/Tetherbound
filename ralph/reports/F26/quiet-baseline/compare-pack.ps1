param([switch]$MeasurementOnly)
$ErrorActionPreference='Stop'
function Read-Directory($stream){
  $r=[IO.BinaryReader]::new($stream,[Text.Encoding]::UTF8,$true)
  if($r.ReadUInt32() -ne 0x43504447){throw 'Not a PCK'}
  $version=$r.ReadUInt32();$major=$r.ReadUInt32();$minor=$r.ReadUInt32();$patch=$r.ReadUInt32();$flags=$r.ReadUInt32();$base=$r.ReadUInt64()
  if($flags -band 1){throw 'Encrypted directory unsupported'}
  if($version -eq 3 -or $version -eq 4){
    $offset=$r.ReadUInt64();$remaining=[long]$offset-40
    if($stream.CanSeek){$stream.Position=$offset}else{
      $buffer=[byte[]]::new(1048576)
      while($remaining -gt 0){$n=$stream.Read($buffer,0,[int][Math]::Min($remaining,$buffer.Length));if($n -le 0){throw 'Truncated PCK'};$remaining-=$n}
    }
  }elseif($version -eq 2){$null=$r.ReadBytes(64)}else{throw "Unsupported PCK $version"}
  $count=$r.ReadUInt32();$result=@{}
  for($i=0;$i -lt $count;$i++){
    $length=$r.ReadUInt32();$path=[Text.Encoding]::UTF8.GetString($r.ReadBytes($length)).Trim([char]0)
    $ofs=$r.ReadUInt64();$size=$r.ReadUInt64();$md5=[Convert]::ToHexString($r.ReadBytes(16)).ToLowerInvariant();$fileFlags=$r.ReadUInt32()
    $result[$path]=@{size=$size;md5=$md5;flags=$fileFlags}
  }
  $r.Dispose();return $result
}
$taskRoot='C:/CodexTemp/quiet-baseline-20261009'
$indexPath=Join-Path $PSScriptRoot 'measurement-pack-directory.json'
if($MeasurementOnly){
  $stream=[IO.File]::OpenRead((Join-Path $taskRoot 'measurement-release/Tetherbound.pck'))
  try{$measurement=Read-Directory $stream}finally{$stream.Dispose()}
  $measurement|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $indexPath -Encoding utf8
  Write-Output "Measurement PCK index: $($measurement.Count) files";return
}
$zipPath=Join-Path $taskRoot 'shipping-check.zip'
$tailPath='D:/tetherbound/.artifacts/quiet-baseline-20261009/shipping-check-tail.zip.part'
$zipInput=$null
if((Get-Item -LiteralPath $zipPath).Length -eq 791025189){$zipInput=[IO.File]::OpenRead($zipPath)}else{
  $zipInput=[IO.MemoryStream]::new(791025189)
  foreach($part in @($zipPath,$tailPath)){
    $stream=[IO.File]::OpenRead($part);try{$stream.CopyTo($zipInput)}finally{$stream.Dispose()}
  }
  if($zipInput.Length -ne 791025189){throw 'Incomplete split ZIP'}
}
$zipInput.Position=0
$sha=[Security.Cryptography.SHA256]::Create()
try{$zipHash=[Convert]::ToHexString($sha.ComputeHash($zipInput)).ToLowerInvariant()}finally{$sha.Dispose()}
if($zipHash -ne 'fd6472a40cba56dfe82fd1294207eccfee64ab19d63a8bc84c8e9fd43622112e'){throw 'Published ZIP hash mismatch'}
$zipInput.Position=0
$zip=[IO.Compression.ZipArchive]::new($zipInput,[IO.Compression.ZipArchiveMode]::Read,$true)
try{
  $entry=@($zip.Entries|Where-Object{$_.Name -eq 'Tetherbound.pck'})
  if($entry.Count -ne 1){throw 'Expected one shipping PCK'}
  $stream=$entry[0].Open();try{$shipping=Read-Directory $stream}finally{$stream.Dispose()}
}finally{$zip.Dispose();$zipInput.Dispose()}
$measurement=Get-Content -LiteralPath $indexPath -Raw|ConvertFrom-Json -AsHashtable
$changes=@()
foreach($path in @(@($shipping.Keys)+@($measurement.Keys)|Sort-Object -Unique)){
  if(-not $shipping.ContainsKey($path) -or -not $measurement.ContainsKey($path) -or $shipping[$path].md5 -ne $measurement[$path].md5 -or $shipping[$path].size -ne $measurement[$path].size){$changes+=@{path=$path;shipping=$shipping[$path];measurement=$measurement[$path]}}
}
$result=@{comparison_shipping_source='7dd4a777fbc11ce62c6747248b96d53e4a27a099';measurement_source='7c7d25873cec69c1720b1964af9fd4b94151bee5';shipping_zip_sha256=$zipHash;shipping_count=$shipping.Count;measurement_count=$measurement.Count;differences=$changes;stormwood_scatter_matching=@($changes|Where-Object{$_.path -match 'data/scatter/stormwood/|scripts/world/(stormwood_scatter|vegetation|scatter_bake)'}).Count -eq 0;reference='https://github.com/godotengine/godot/blob/4.7/core/io/file_access_pack.cpp'}
$result|ConvertTo-Json -Depth 15|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'pack-comparison.json') -Encoding utf8
Write-Output "PCK comparison: $($changes.Count) changed resources; Stormwood scatter matching=$($result.stormwood_scatter_matching)"
$changes|Select-Object -ExpandProperty path
