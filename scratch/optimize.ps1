Add-Type -AssemblyName System.Drawing

function Optimize-Image($srcPath, $destPath, $maxWidth) {
    if (-not (Test-Path $srcPath)) {
        Write-Host "File not found: $srcPath"
        return
    }
    $img = [System.Drawing.Image]::FromFile($srcPath)

    # Auto-rotate based on EXIF Orientation tag 274 (0x0112)
    if ($img.PropertyIdList -contains 274) {
        $prop = $img.GetPropertyItem(274)
        $val = [BitConverter]::ToUInt16($prop.Value, 0)
        if ($val -eq 3) { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone) }
        elseif ($val -eq 6) { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone) }
        elseif ($val -eq 8) { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone) }
        $img.RemovePropertyItem(274)
    }

    $ratio = $maxWidth / $img.Width
    if ($ratio -gt 1) { $ratio = 1 }
    $newWidth = [int]($img.Width * $ratio)
    $newHeight = [int]($img.Height * $ratio)
    
    $bmp = New-Object System.Drawing.Bitmap($newWidth, $newHeight)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.DrawImage($img, 0, 0, $newWidth, $newHeight)
    $img.Dispose()
    $g.Dispose()

    $encoder = [System.Drawing.Imaging.Encoder]::Quality
    $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter($encoder, [long]80)
    $jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
    
    if (Test-Path $destPath) { Remove-Item $destPath -Force }
    $bmp.Save($destPath, $jpegCodec, $encoderParams)
    $bmp.Dispose()

    $finalImg = [System.Drawing.Image]::FromFile($destPath)
    Write-Host "Optimized: $destPath (Width: $($finalImg.Width), Height: $($finalImg.Height), Size: $((Get-Item $destPath).Length) bytes)"
    $finalImg.Dispose()
}

$publicDir = "C:\Users\ana\.gemini\antigravity\scratch\leire-salgado-makeup\public"

# Optimize sobremi.jpg from raw sobre mi.jpg
if (Test-Path "$publicDir\sobre mi.jpg") {
    Optimize-Image "$publicDir\sobre mi.jpg" "$publicDir\sobremi.jpg" 1200
}

# Explicit raw mappings for galeria5 to galeria13
$mappings = [ordered]@{
    "galeria5"  = "$publicDir\galeria4.jpg"
    "galeria6"  = "$publicDir\body paint (2).JPG"
    "galeria7"  = "$publicDir\body paint.JPG"
    "galeria8"  = "$publicDir\caracterizaciones (1).JPG"
    "galeria9"  = "$publicDir\galeria5.jpg"
    "galeria10" = "$publicDir\invitadas.JPG"
    "galeria11" = "$publicDir\invitadas (1).JPG"
    "galeria12" = "$publicDir\bodas (6).jpg"
    "galeria13" = "$publicDir\body paint (4).JPG"
}

foreach ($key in $mappings.Keys) {
    $src = $mappings[$key]
    $dest = "$publicDir\$key.jpg"
    if (Test-Path $src) {
        $temp = "$publicDir\temp_$key.jpg"
        Optimize-Image $src $temp 1400
        if (Test-Path $dest) { Remove-Item $dest -Force }
        Move-Item $temp $dest -Force
    }
}
