Add-Type -AssemblyName System.Drawing

function Optimize-Image($srcPath, $destPath, $maxWidth) {
    if (-not (Test-Path $srcPath)) {
        Write-Host "File not found: $srcPath"
        return
    }
    $img = [System.Drawing.Image]::FromFile($srcPath)
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
    Write-Host "Optimized: $destPath (Size: $((Get-Item $destPath).Length) bytes)"
}

$publicDir = "C:\Users\ana\.gemini\antigravity\scratch\leire-salgado-makeup\public"

# Optimize public/sobre mi.jpg into public/sobremi.jpg
if (Test-Path "$publicDir\sobre mi.jpg") {
    Optimize-Image "$publicDir\sobre mi.jpg" "$publicDir\sobremi.jpg" 1200
}

# Optimize galeria 5 to 13
5..13 | ForEach-Object {
    $num = $_
    $srcJpg = "$publicDir\galeria$num.JPG"
    if (-not (Test-Path $srcJpg)) { $srcJpg = "$publicDir\galeria$num.jpg" }
    $destJpg = "$publicDir\galeria$num.jpg"
    
    # Create temp copy if src and dest are same path ignoring case
    if (Test-Path $srcJpg) {
        $tempPath = "$publicDir\temp_galeria$num.jpg"
        Optimize-Image $srcJpg $tempPath 1400
        Remove-Item $srcJpg -Force
        Move-Item $tempPath $destJpg -Force
    }
}
