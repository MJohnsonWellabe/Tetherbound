param(
    [Parameter(Mandatory = $true)]
    [string]$NativeCheckout,

    [string]$PacketPath = (Join-Path $PSScriptRoot 'capture-packet.json'),

    [string]$OutputPath = (Join-Path $PSScriptRoot 'capture-packet.rebound.json')
)

$ErrorActionPreference = 'Stop'
$ExpectedCommit = '5bb435c2ded96ecbec6a4a762e231ef7d7fabac0'
$SnapshotPath = Join-Path (Split-Path -Parent $PacketPath) 'capture-packet.pre-rebind.json'

function Invoke-Git([string[]]$GitArgs) {
    $Result = & git -C $NativeCheckout @GitArgs
    if ($LASTEXITCODE -ne 0) { throw "git $($GitArgs -join ' ') failed with exit code $LASTEXITCODE" }
    return $Result
}

function Get-Sha256Bytes([byte[]]$Bytes) {
    $Hasher = [System.Security.Cryptography.SHA256]::Create()
    try { return ([System.BitConverter]::ToString($Hasher.ComputeHash($Bytes))).Replace('-', '') }
    finally { $Hasher.Dispose() }
}

function Get-Sha256File([string]$Path) {
    return (Get-Sha256Bytes ([System.IO.File]::ReadAllBytes($Path)))
}

function Get-ByteSequenceMatches([byte[]]$Haystack, [byte[]]$Needle) {
    $Matches = [System.Collections.Generic.List[int]]::new()
    for ($i = 0; $i -le $Haystack.Length - $Needle.Length; $i++) {
        $Same = $true
        for ($j = 0; $j -lt $Needle.Length; $j++) {
            if ($Haystack[$i + $j] -ne $Needle[$j]) { $Same = $false; break }
        }
        if ($Same) { $Matches.Add($i) }
    }
    return $Matches.ToArray()
}

function Get-OnPropsBytes([byte[]]$OffBytes) {
    $Property = [System.Text.Encoding]::ASCII.GetBytes('"p2_005_groundcover_candidate_enabled"')
    $PropertyMatches = @(Get-ByteSequenceMatches $OffBytes $Property)
    if ($PropertyMatches.Count -ne 1) { throw 'P2-005 flag key must occur exactly once in props.json' }
    $i = $PropertyMatches[0] + $Property.Length
    while ($i -lt $OffBytes.Length -and ($OffBytes[$i] -eq 9 -or $OffBytes[$i] -eq 10 -or $OffBytes[$i] -eq 13 -or $OffBytes[$i] -eq 32)) { $i++ }
    if ($i -ge $OffBytes.Length -or $OffBytes[$i] -ne 58) { throw 'P2-005 flag key is not followed by a JSON colon' }
    $i++
    while ($i -lt $OffBytes.Length -and ($OffBytes[$i] -eq 9 -or $OffBytes[$i] -eq 10 -or $OffBytes[$i] -eq 13 -or $OffBytes[$i] -eq 32)) { $i++ }
    $FalseBytes = [System.Text.Encoding]::ASCII.GetBytes('false')
    if ($i + $FalseBytes.Length -gt $OffBytes.Length) { throw 'P2-005 OFF flag value is incomplete' }
    for ($j = 0; $j -lt $FalseBytes.Length; $j++) {
        if ($OffBytes[$i + $j] -ne $FalseBytes[$j]) { throw 'P2-005 flag must be false in the clean baseline props.json' }
    }
    $End = $i + $FalseBytes.Length
    if ($End -lt $OffBytes.Length -and $OffBytes[$End] -ne 9 -and $OffBytes[$End] -ne 10 -and $OffBytes[$End] -ne 13 -and $OffBytes[$End] -ne 32 -and $OffBytes[$End] -ne 44 -and $OffBytes[$End] -ne 125) {
        throw 'P2-005 OFF boolean is not a complete JSON token'
    }
    $TrueBytes = [System.Text.Encoding]::ASCII.GetBytes('true')
    $OnBytes = [byte[]]::new($OffBytes.Length - 1)
    [Array]::Copy($OffBytes, 0, $OnBytes, 0, $i)
    [Array]::Copy($TrueBytes, 0, $OnBytes, $i, $TrueBytes.Length)
    [Array]::Copy($OffBytes, $End, $OnBytes, $i + $TrueBytes.Length, $OffBytes.Length - $End)
    return ,$OnBytes
}

function Set-JsonPathSha([string]$Text, [string]$RelativePath, [string]$Sha256) {
    $PathToken = '"path"\s*:\s*"' + [regex]::Escape($RelativePath) + '"'
    $Pattern = '(?m)^(?<prefix>[^\r\n]*' + $PathToken + '[^\r\n]*?"sha256"\s*:\s*")[A-Fa-f0-9]{64}(?<suffix>"[^\r\n]*\r?)$'
    $Matches = [regex]::Matches($Text, $Pattern)
    if ($Matches.Count -ne 1) { throw "Expected one packet SHA entry for $RelativePath; found $($Matches.Count)" }
    $Match = $Matches[0]
    $Replacement = $Match.Groups['prefix'].Value + $Sha256 + $Match.Groups['suffix'].Value
    return $Text.Substring(0, $Match.Index) + $Replacement + $Text.Substring($Match.Index + $Match.Length)
}

if (-not (Test-Path -LiteralPath $NativeCheckout -PathType Container)) { throw "Native checkout not found: $NativeCheckout" }
$CheckoutRoot = (Invoke-Git @('rev-parse', '--show-toplevel') | Select-Object -First 1).Trim()
$ExpectedRoot = [System.IO.Path]::GetFullPath($NativeCheckout).TrimEnd('\')
if (-not [string]::Equals([System.IO.Path]::GetFullPath($CheckoutRoot).TrimEnd('\'), $ExpectedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Git root mismatch: expected $ExpectedRoot, found $CheckoutRoot"
}
$Head = (Invoke-Git @('rev-parse', 'HEAD') | Select-Object -First 1).Trim()
if ($Head -ne $ExpectedCommit) { throw "Native HEAD must be $ExpectedCommit; found $Head" }
$Status = @(Invoke-Git @('status', '--porcelain'))
if ($Status.Count -ne 0) { throw "Native checkout must be clean; found status entries: $($Status -join '; ')" }

$PacketFullPath = [System.IO.Path]::GetFullPath($PacketPath)
$OutputFullPath = [System.IO.Path]::GetFullPath($OutputPath)
if ($PacketFullPath -eq $OutputFullPath) { throw 'OutputPath must not overwrite the input packet' }
$NativePrefix = $ExpectedRoot + [System.IO.Path]::DirectorySeparatorChar
foreach ($WritePath in @($PacketFullPath, $OutputFullPath, [System.IO.Path]::GetFullPath($SnapshotPath))) {
    if ($WritePath.StartsWith($NativePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Packet, snapshot, and output files must stay outside the native checkout: $WritePath"
    }
}
if (-not (Test-Path -LiteralPath $PacketFullPath -PathType Leaf)) { throw "Packet not found: $PacketFullPath" }
if (Test-Path -LiteralPath $OutputFullPath) { throw "Output already exists; refusing to overwrite: $OutputFullPath" }

$OriginalBytes = [System.IO.File]::ReadAllBytes($PacketFullPath)
if (Test-Path -LiteralPath $SnapshotPath) {
    $SnapshotBytes = [System.IO.File]::ReadAllBytes($SnapshotPath)
    if ([Convert]::ToBase64String($SnapshotBytes) -ne [Convert]::ToBase64String($OriginalBytes)) { throw "Existing pre-rebind snapshot differs from input: $SnapshotPath" }
} else {
    [System.IO.File]::Copy($PacketFullPath, $SnapshotPath, $false)
}

$HasBom = $OriginalBytes.Length -ge 3 -and $OriginalBytes[0] -eq 239 -and $OriginalBytes[1] -eq 187 -and $OriginalBytes[2] -eq 191
$TextOffset = if ($HasBom) { 3 } else { 0 }
$Utf8 = [System.Text.UTF8Encoding]::new($false, $true)
$PacketText = $Utf8.GetString($OriginalBytes, $TextOffset, $OriginalBytes.Length - $TextOffset)
$Packet = $PacketText | ConvertFrom-Json
if ($Packet.source_commit -ne $ExpectedCommit) { throw 'Packet source_commit does not match the exact required checkout commit' }

$PinnedBlobs = @{}
foreach ($Entry in $Packet.source_blobs) {
    if ($PinnedBlobs.ContainsKey($Entry.path) -and $PinnedBlobs[$Entry.path] -ne $Entry.blob) { throw "Conflicting canonical blob pins for $($Entry.path)" }
    $PinnedBlobs[$Entry.path] = $Entry.blob
}
foreach ($Entry in $Packet.assets) {
    if ($PinnedBlobs.ContainsKey($Entry.path) -and $PinnedBlobs[$Entry.path] -ne $Entry.blob) { throw "Conflicting canonical blob pins for $($Entry.path)" }
    $PinnedBlobs[$Entry.path] = $Entry.blob
}
if ($PinnedBlobs.ContainsKey('project.godot') -and $PinnedBlobs['project.godot'] -ne $Packet.project_godot_blob) { throw 'Conflicting project.godot blob pins' }
$PinnedBlobs['project.godot'] = $Packet.project_godot_blob
foreach ($Entry in $Packet.source_files) {
    if (-not $PinnedBlobs.ContainsKey($Entry.path)) { throw "No canonical Git blob pin exists for source file $($Entry.path)" }
}

foreach ($Path in $PinnedBlobs.Keys) {
    if ([System.IO.Path]::IsPathRooted($Path) -or $Path.Split('/') -contains '..' -or $Path.Contains('\')) { throw "Unsafe packet path: $Path" }
    $HeadBlob = (Invoke-Git @('rev-parse', "HEAD:$Path") | Select-Object -First 1).Trim()
    if ($HeadBlob -ne $PinnedBlobs[$Path]) { throw "HEAD:$Path blob mismatch: expected $($PinnedBlobs[$Path]), found $HeadBlob" }
    $WorkBlob = (Invoke-Git @('hash-object', "--path=$Path", '--', $Path) | Select-Object -First 1).Trim()
    if ($WorkBlob -ne $PinnedBlobs[$Path]) { throw "Working-tree canonical blob mismatch for $Path: expected $($PinnedBlobs[$Path]), found $WorkBlob" }
}

$PacketTextUpdated = $PacketText
$WorkingShaByPath = @{}
foreach ($Entry in $Packet.source_files) {
    $AbsPath = Join-Path $CheckoutRoot ($Entry.path.Replace('/', [System.IO.Path]::DirectorySeparatorChar))
    $WorkingShaByPath[$Entry.path] = Get-Sha256File $AbsPath
    $PacketTextUpdated = Set-JsonPathSha $PacketTextUpdated $Entry.path $WorkingShaByPath[$Entry.path]
}
foreach ($Entry in $Packet.assets) {
    $AbsPath = Join-Path $CheckoutRoot ($Entry.path.Replace('/', [System.IO.Path]::DirectorySeparatorChar))
    $WorkingShaByPath[$Entry.path] = Get-Sha256File $AbsPath
    $PacketTextUpdated = Set-JsonPathSha $PacketTextUpdated $Entry.path $WorkingShaByPath[$Entry.path]
}

$PropsPath = Join-Path $CheckoutRoot 'data/config/props.json'
$PropsBytes = [System.IO.File]::ReadAllBytes($PropsPath)
$PropsJson = $Utf8.GetString($PropsBytes) | ConvertFrom-Json
if ([bool]$PropsJson.p2_005_groundcover_candidate_enabled) { throw 'Clean baseline props.json must have the P2-005 flag OFF' }
$OffSha = Get-Sha256Bytes $PropsBytes
$OnSha = Get-Sha256Bytes (Get-OnPropsBytes $PropsBytes)
$PropsLine = '"props_sha256_by_arm"\s*:\s*\{(?<body>[^}]*)\}'
if ($PacketTextUpdated -notmatch $PropsLine) { throw 'props_sha256_by_arm object not found' }
$PacketTextUpdated = [regex]::Replace($PacketTextUpdated, $PropsLine, {
    param($m)
    $Body = $m.Groups['body'].Value
    $Body = [regex]::Replace($Body, '("off"\s*:\s*")[A-Fa-f0-9]{64}("\s*,)', ('$1' + $OffSha + '$2'), 1)
    $Body = [regex]::Replace($Body, '("on"\s*:\s*")[A-Fa-f0-9]{64}("\s*)', ('$1' + $OnSha + '$2'), 1)
    return '"props_sha256_by_arm": {' + $Body + '}'
}, 1)
$PacketTextUpdated = [regex]::Replace($PacketTextUpdated, '("candidate_flag_off_sha256"\s*:\s*")[A-Fa-f0-9]{64}(")', ('$1' + $OffSha + '$2'), 1)

$UpdatedBytes = $Utf8.GetBytes($PacketTextUpdated)
if ($HasBom) {
    $WithBom = [byte[]]::new($UpdatedBytes.Length + 3)
    $WithBom[0] = 239; $WithBom[1] = 187; $WithBom[2] = 191
    [Array]::Copy($UpdatedBytes, 0, $WithBom, 3, $UpdatedBytes.Length)
    $UpdatedBytes = $WithBom
}
[System.IO.File]::WriteAllBytes($OutputFullPath, $UpdatedBytes)
"Rebound packet written: $OutputFullPath"
"Original packet snapshot preserved: $SnapshotPath"
"Verified exact HEAD and canonical blobs for $($PinnedBlobs.Count) runtime files."
"Raw props SHA OFF=$OffSha ON=$OnSha (ON changes only the false token to true)."
