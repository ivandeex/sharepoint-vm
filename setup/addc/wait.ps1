Write-Host "Waiting for completion..."
$Time = [System.Diagnostics.Stopwatch]::StartNew()
while ($Time.Elapsed.TotalMinutes -lt 15) {
    if (Test-Path C:\setup\done) {
        Write-Host "All Done!"
        exit 0
    }
    Start-Sleep -Seconds 5
}
Write-Host "Please wait more."
exit 1
