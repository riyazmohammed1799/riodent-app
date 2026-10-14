Add-Type -AssemblyName System.Drawing

$baseDir = "C:\Users\riyaz\riodent_claude"
$iconSrcPath = Join-Path $baseDir "assets\images\riodent_icon.png"
$logoSrcPath = Join-Path $baseDir "assets\images\riodent_logo.png"
$outDir = Join-Path $baseDir "assets\playstore"

if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

# 1. Generate 512x512 App Icon
Write-Host "Generating 512x512 Play Store App Icon..."
$srcIcon = [System.Drawing.Image]::FromFile($iconSrcPath)
$icon512 = New-Object System.Drawing.Bitmap 512, 512
$gIcon = [System.Drawing.Graphics]::FromImage($icon512)
$gIcon.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$gIcon.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$gIcon.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$gIcon.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

$gIcon.DrawImage($srcIcon, 0, 0, 512, 512)
$icon512Out = Join-Path $outDir "app_icon_512x512.png"
$icon512.Save($icon512Out, [System.Drawing.Imaging.ImageFormat]::Png)

$gIcon.Dispose()
$icon512.Dispose()
$srcIcon.Dispose()
Write-Host "Saved: $icon512Out"

# Helper to generate Feature Graphic
function Generate-FeatureBanner([int]$width, [int]$height, [string]$filename) {
    Write-Host "Generating Feature Graphic banner ($($width)x$($height))..."
    $banner = New-Object System.Drawing.Bitmap $width, $height
    $g = [System.Drawing.Graphics]::FromImage($banner)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    # Background gradient: deep surgical navy to surgical cyan-navy
    $cTopLeft = [System.Drawing.Color]::FromArgb(255, 10, 38, 71)
    $cBottomRight = [System.Drawing.Color]::FromArgb(255, 15, 76, 129)
    $rect = New-Object System.Drawing.Rectangle 0, 0, $width, $height
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, $cTopLeft, $cBottomRight, 25.0
    $g.FillRectangle($brush, $rect)
    $brush.Dispose()

    # Subtle decorative radial glow on right side
    $glowPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $glowPath.AddEllipse(550, -50, 500, 500)
    $pbr = New-Object System.Drawing.Drawing2D.PathGradientBrush $glowPath
    $pbr.CenterColor = [System.Drawing.Color]::FromArgb(40, 0, 168, 150)
    $pbr.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 10, 38, 71))
    $g.FillPath($pbr, $glowPath)
    $pbr.Dispose()
    $glowPath.Dispose()

    # Draw Emblem Icon on Left
    $srcLogo = [System.Drawing.Image]::FromFile($iconSrcPath)
    $iconSize = 340
    $iconX = 60
    $iconY = ($height - $iconSize) / 2
    $g.DrawImage($srcLogo, $iconX, $iconY, $iconSize, $iconSize)
    $srcLogo.Dispose()

    # Text Block on Right
    $textStartX = 440
    
    # Title: RioDent
    $fontTitle = [System.Drawing.Font]::new("Segoe UI", [float]46, [System.Drawing.FontStyle]::Bold)
    $brushTitle = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
    $g.DrawString("RioDent", $fontTitle, $brushTitle, $textStartX, 80)
    $fontTitle.Dispose()
    $brushTitle.Dispose()

    # Tagline: Dental Equipment Technicians
    $fontTagline = [System.Drawing.Font]::new("Segoe UI", [float]21, [System.Drawing.FontStyle]::Bold)
    $brushTagline = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 0, 206, 175))
    $g.DrawString("Dental Equipment Technicians", $fontTagline, $brushTagline, $textStartX, 165)
    $fontTagline.Dispose()
    $brushTagline.Dispose()

    # Subtitle: On-Demand Diagnostics & Repair for Dental Clinics
    $fontSub = [System.Drawing.Font]::new("Segoe UI", [float]13, [System.Drawing.FontStyle]::Regular)
    $brushSub = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 218, 232, 245))
    $g.DrawString("On-Demand Diagnostics, Calibration & Rapid Clinic Service", $fontSub, $brushSub, $textStartX, 215)
    $fontSub.Dispose()
    $brushSub.Dispose()

    # Badges
    $fontBadge = [System.Drawing.Font]::new("Segoe UI", [float]11, [System.Drawing.FontStyle]::Bold)

    $badgeBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 240, 248, 255))
    $badgeBgBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(60, 255, 255, 255))
    $badgePen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(100, 255, 255, 255)), 1

    $badges = @(
        "Verified Technicians",
        "Live Dispatch Tracking",
        "Transparent Pricing"
    )

    $badgeX = $textStartX
    $badgeY = 270
    foreach ($badge in $badges) {
        $size = $g.MeasureString($badge, $fontBadge)
        $bWidth = $size.Width + 24
        $bHeight = 36
        
        $bRect = New-Object System.Drawing.Rectangle $badgeX, $badgeY, $bWidth, $bHeight
        $g.FillRectangle($badgeBgBrush, $bRect)
        $g.DrawRectangle($badgePen, $bRect)
        $g.DrawString($badge, $fontBadge, $badgeBrush, ($badgeX + 12), ($badgeY + 8))

        $badgeX += $bWidth + 14
        if ($badgeX -gt ($width - 150)) {
            $badgeX = $textStartX
            $badgeY += 46
        }
    }


    $fontBadge.Dispose()
    $badgeBrush.Dispose()
    $badgeBgBrush.Dispose()
    $badgePen.Dispose()

    # Save 24-bit PNG (Google Play compliant)
    $outPath = Join-Path $outDir $filename
    $banner.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $banner.Dispose()
    Write-Host "Saved: $outPath"
}

# Standard Google Play requirement is 1024 x 500
Generate-FeatureBanner 1024 500 "feature_graphic_1024x500.png"
# Also generate 1025 x 500 as specifically requested by user
Generate-FeatureBanner 1025 500 "feature_graphic_1025x500.png"

Write-Host "All Play Store graphics generated successfully!"
