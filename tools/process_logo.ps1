Add-Type -AssemblyName System.Drawing

$srcPath = "C:\Users\riyaz\.gemini\antigravity-ide\brain\d40f2edf-eb22-4cc1-bc9c-7661e3215b6e\.user_uploaded\media_1792324111325.png"
$baseDir = "C:\Users\riyaz\riodent_claude"
$assetsImg = Join-Path $baseDir "assets\images"
$playstoreDir = Join-Path $baseDir "assets\playstore"
$webIconsDir = Join-Path $baseDir "web\icons"
$webDir = Join-Path $baseDir "web"

if (-not (Test-Path $srcPath)) {
    Write-Error "Source image not found: $srcPath"
    exit 1
}

# 1. Copy original full logo
$logoPng = Join-Path $assetsImg "riodent_logo.png"
Copy-Item -Path $srcPath -Destination $logoPng -Force
Write-Host "Updated full logo: $logoPng"

# Load source image
$srcImg = [System.Drawing.Image]::FromFile($srcPath)
Write-Host "Source dimensions: $($srcImg.Width) x $($srcImg.Height)"

# 2. Generate Square App Icon (512x512)
# We want the dental chair/tooth emblem with comfortable padding, or centered logo on white background
$icon512 = New-Object System.Drawing.Bitmap 512, 512
$g512 = [System.Drawing.Graphics]::FromImage($icon512)
$g512.Clear([System.Drawing.Color]::White)
$g512.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g512.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g512.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g512.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

# Fit the logo into 512x512 with 32px padding
# Source is 1024x682 (aspect ratio ~ 1.5 : 1)
$destW = 460
$destH = [int](460 * ($srcImg.Height / $srcImg.Width))
$destX = [int]((512 - $destW) / 2)
$destY = [int]((512 - $destH) / 2)

$g512.DrawImage($srcImg, $destX, $destY, $destW, $destH)

# Save to assets/images/riodent_icon.png and playstore
$appIconPng = Join-Path $assetsImg "riodent_icon.png"
$icon512.Save($appIconPng, [System.Drawing.Imaging.ImageFormat]::Png)
Write-Host "Saved app icon: $appIconPng"

$playstoreIcon = Join-Path $playstoreDir "app_icon_512x512.png"
$icon512.Save($playstoreIcon, [System.Drawing.Imaging.ImageFormat]::Png)
Write-Host "Saved playstore icon: $playstoreIcon"

# 3. Generate Web Favicon and Icons
function Save-ResizedIcon($sourceBmp, $size, $outPath) {
    $res = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($res)
    $g.Clear([System.Drawing.Color]::White)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($sourceBmp, 0, 0, $size, $size)
    $res.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $res.Dispose()
    Write-Host "Saved: $outPath ($($size)x$($size))"
}

Save-ResizedIcon $icon512 64 (Join-Path $webDir "favicon.png")
Save-ResizedIcon $icon512 192 (Join-Path $webIconsDir "Icon-192.png")
Save-ResizedIcon $icon512 512 (Join-Path $webIconsDir "Icon-512.png")
Save-ResizedIcon $icon512 192 (Join-Path $webIconsDir "Icon-maskable-192.png")
Save-ResizedIcon $icon512 512 (Join-Path $webIconsDir "Icon-maskable-512.png")

# 4. Generate Android Launcher Icons
$androidRes = Join-Path $baseDir "android\app\src\main\res"
if (Test-Path $androidRes) {
    Save-ResizedIcon $icon512 48 (Join-Path $androidRes "mipmap-mdpi\ic_launcher.png")
    Save-ResizedIcon $icon512 72 (Join-Path $androidRes "mipmap-hdpi\ic_launcher.png")
    Save-ResizedIcon $icon512 96 (Join-Path $androidRes "mipmap-xhdpi\ic_launcher.png")
    Save-ResizedIcon $icon512 144 (Join-Path $androidRes "mipmap-xxhdpi\ic_launcher.png")
    Save-ResizedIcon $icon512 192 (Join-Path $androidRes "mipmap-xxxhdpi\ic_launcher.png")
}

$g512.Dispose()
$icon512.Dispose()
$srcImg.Dispose()

Write-Host "All logo and icon assets successfully generated!"
