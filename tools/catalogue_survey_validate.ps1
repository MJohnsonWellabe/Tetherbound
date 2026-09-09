param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("meadows", "cloudreach", "stormwood", "water")]
    [string]$Biome,
    [string[]]$Subset = @(),
    [switch]$Json
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$cataloguePath = Join-Path $repoRoot "data/config/debug_teleport_spots.json"
$catalogue = Get-Content -Raw -LiteralPath $cataloguePath | ConvertFrom-Json
$biomeRow = $catalogue.biomes | Where-Object { $_.id -eq $Biome } | Select-Object -First 1
if ($null -eq $biomeRow) {
    throw "unknown biome '$Biome'"
}

function ConvertTo-CatalogueSlug([string]$Value) {
    $slug = $Value.ToLowerInvariant().Replace("'", "") -replace '[^a-z0-9]+', '_'
    $slug = $slug.Trim('_')
    if ([string]::IsNullOrWhiteSpace($slug)) { return "unnamed" }
    return $slug
}

$rows = [System.Collections.Generic.List[object]]::new()
$destinationIndex = 0
foreach ($band in $biomeRow.bands) {
    $spotIndex = 0
    foreach ($spot in $band.spots) {
        $destinationIndex++
        $spotIndex++
        $identity = "$Biome`__$($band.id)`__$($destinationIndex.ToString('00'))`__$(ConvertTo-CatalogueSlug $spot.display_name)"
        $searchable = "$identity $($band.display_name) $($spot.display_name)"
        $include = $Subset.Count -eq 0
        foreach ($part in $Subset) {
            if ($searchable.IndexOf($part, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) { $include = $true }
        }
        if (-not $include) { continue }
        $position = @($spot.position)
        if ($position.Count -ne 2 -or $position[0] -isnot [ValueType] -or $position[1] -isnot [ValueType]) {
            throw "$identity position must be a numeric Array[x,z]"
        }
        foreach ($timeName in @("day", "night")) {
            $rows.Add([pscustomobject][ordered]@{
                frame_id = "$identity`__$timeName"
                biome_id = $Biome
                biome_display_name = $biomeRow.display_name
                band_id = $band.id
                band_display_name = $band.display_name
                destination_index = $destinationIndex
                spot_index_in_band = $spotIndex
                destination_display_name = $spot.display_name
                position_xz = @([double]$position[0], [double]$position[1])
                time = $timeName
            })
        }
    }
}
$duplicates = $rows | Group-Object frame_id | Where-Object Count -gt 1
if ($duplicates) { throw "duplicate frame IDs: $($duplicates.Name -join ', ')" }
if ($rows.Count -eq 0) { throw "selection yielded no frames" }
$destinationCount = @($rows.destination_index | Sort-Object -Unique).Count
if ($Json) {
    [ordered]@{ biome = $biomeRow; destinations = $destinationCount; frames = $rows } | ConvertTo-Json -Depth 8
} else {
    "$Biome`: $destinationCount destinations, $($rows.Count) day/night frames"
    $rows.frame_id
}
