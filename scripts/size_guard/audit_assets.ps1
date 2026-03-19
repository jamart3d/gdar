# Audit script for GDAR assets
$assetDir = "assets"
$maxSizeKB = 500
$allAssets = Get-ChildItem -Path $assetDir -Recurse -File

Write-Host "--- GDAR Asset Audit Baseline ---"
Write-Host "Scanning recursively from: $assetDir"
Write-Host "Target threshold: $maxSizeKB KB"
Write-Host ""

$overLimitCount = 0
$totalSize = 0

foreach ($file in $allAssets) {
    $sizeKB = [math]::Round($file.Length / 1KB, 2)
    $totalSize += $file.Length

    # Flag large files
    if ($sizeKB -gt $maxSizeKB) {
        $overLimitCount++
        $ext = $file.Extension.ToLower()
        $msg = " [!] LARGE FILE ($sizeKB KB): $($file.FullName)"

        # Suggest WebP conversion for PNG/JPG
        if ($ext -eq ".png" -or $ext -eq ".jpg" -or $ext -eq ".jpeg") {
            $msg += " (Suggest: Convert to WebP)"
        }

        Write-Host $msg -ForegroundColor Yellow
    }
}

Write-Host "`n--- Summary ---"
Write-Host "Total Files Scanned: $($allAssets.Count)"
Write-Host "Total Asset Size: $([math]::Round($totalSize / 1MB, 2)) MB"
Write-Host "Files over $maxSizeKB KB: $overLimitCount"
Write-Host ""

if ($overLimitCount -gt 0) {
    Write-Host "Action required: Review large files to ensure they are strictly TV-necessary." -ForegroundColor Cyan
} else {
    Write-Host "Check successful: Assets are lean." -ForegroundColor Green
}
