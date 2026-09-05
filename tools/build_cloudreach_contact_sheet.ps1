param(
    [string]$Shots = 'ralph/reports/CLOUDREACH-ENV-CORRECTION-0904/round3/shots',
    [string]$Output = 'ralph/reports/CLOUDREACH-ENV-CORRECTION-0904/round3/contact-sheet.png'
)

# Evidence composition only: preserve complete real production frames, with
# readable source-location labels. No retouching or generated replacement pixels.
Add-Type -AssemblyName System.Drawing
$frameFiles = @(Get-ChildItem -LiteralPath $Shots -Filter '*.png' -File | Where-Object { -not $_.Name.StartsWith('_') } | Sort-Object Name)
if ($frameFiles.Count -eq 0) { throw 'No captured production frames found.' }
$columns = 3
$tileWidth = 620
$tileHeight = 388
$padding = 14
$labelHeight = 34
$rows = [int][Math]::Ceiling($frameFiles.Count / [double]$columns)
$sheet = [Drawing.Bitmap]::new($columns * ($tileWidth + $padding) + $padding, $rows * ($tileHeight + $labelHeight + $padding) + $padding)
$graphics = [Drawing.Graphics]::FromImage($sheet)
$font = [Drawing.Font]::new('Segoe UI', 14, [Drawing.FontStyle]::Regular, [Drawing.GraphicsUnit]::Pixel)
$brush = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(238, 240, 225))
try {
    $graphics.Clear([Drawing.Color]::FromArgb(18, 21, 23))
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    for ($index = 0; $index -lt $frameFiles.Count; $index++) {
        $x = $padding + ($index % $columns) * ($tileWidth + $padding)
        $y = $padding + [int][Math]::Floor($index / [double]$columns) * ($tileHeight + $labelHeight + $padding)
        $frame = [Drawing.Image]::FromFile($frameFiles[$index].FullName)
        try {
            $scale = [Math]::Min($tileWidth / [double]$frame.Width, $tileHeight / [double]$frame.Height)
            $width = [int][Math]::Round($frame.Width * $scale)
            $height = [int][Math]::Round($frame.Height * $scale)
            $graphics.DrawImage($frame, [Drawing.Rectangle]::new($x, $y, $width, $height))
            $label = ('F{0} · {1}' -f ($index + 1), $frameFiles[$index].BaseName)
            $graphics.DrawString($label, $font, $brush, [single]$x, [single]($y + $tileHeight + 6))
        } finally { $frame.Dispose() }
    }
    $sheet.Save([IO.Path]::GetFullPath($Output), [Drawing.Imaging.ImageFormat]::Png)
    Write-Output ('{0} unretouched production frames with labels -> {1}' -f $frameFiles.Count, $Output)
} finally {
    $brush.Dispose()
    $font.Dispose()
    $graphics.Dispose()
    $sheet.Dispose()
}
