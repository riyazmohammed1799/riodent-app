Add-Type -AssemblyName System.Drawing

$srcLogo = 'C:\Users\riyaz\.gemini\antigravity-ide\brain\d40f2edf-eb22-4cc1-bc9c-7661e3215b6e\riodent_logo_icon_1791968355362.jpg'
$srcIcon = 'C:\Users\riyaz\.gemini\antigravity-ide\brain\d40f2edf-eb22-4cc1-bc9c-7661e3215b6e\riodent_app_icon_1791968378108.jpg'

Copy-Item $srcLogo -Destination 'c:\Users\riyaz\riodent_claude\assets\images\riodent_logo.jpg' -Force
Copy-Item $srcIcon -Destination 'c:\Users\riyaz\riodent_claude\assets\images\riodent_icon.jpg' -Force

# Convert to PNG for app assets
$imgLogo = [System.Drawing.Image]::FromFile($srcLogo)
$imgLogo.Save('c:\Users\riyaz\riodent_claude\assets\images\riodent_logo.png', [System.Drawing.Imaging.ImageFormat]::Png)
$imgLogo.Dispose()

$imgIcon = [System.Drawing.Image]::FromFile($srcIcon)
$imgIcon.Save('c:\Users\riyaz\riodent_claude\assets\images\riodent_icon.png', [System.Drawing.Imaging.ImageFormat]::Png)

# Generate mipmap icons
$sizes = @{
    'mipmap-mdpi' = 48
    'mipmap-hdpi' = 72
    'mipmap-xhdpi' = 96
    'mipmap-xxhdpi' = 144
    'mipmap-xxxhdpi' = 192
}

foreach ($folder in $sizes.Keys) {
    $size = $sizes[$folder]
    $destPath = Join-Path 'c:\Users\riyaz\riodent_claude\android\app\src\main\res' $folder
    if (!(Test-Path $destPath)) { New-Item -ItemType Directory -Path $destPath -Force | Out-Null }
    $outFile = Join-Path $destPath 'ic_launcher.png'
    
    $bmp = [System.Drawing.Bitmap]::new($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.DrawImage($imgIcon, 0, 0, $size, $size)
    $g.Dispose()
    
    $bmp.Save($outFile, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Output "Generated $outFile"
}
$imgIcon.Dispose()
Write-Output 'All launcher icons and assets updated successfully!'
