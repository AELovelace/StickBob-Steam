param(
    [string]$Path,
    [int]$Tail = 80
)

if ([string]::IsNullOrWhiteSpace($Path)) {
    Write-Host "Usage: .\Start-MpLogTail.ps1 <path-to-mp_multiplayer_debug.log>" -ForegroundColor Yellow
    exit 1
}

Write-Host "Waiting for log file: $Path" -ForegroundColor Cyan
while (-not (Test-Path -LiteralPath $Path)) {
    Start-Sleep -Seconds 1
}

Write-Host "Tailing multiplayer debug log..." -ForegroundColor Green
Get-Content -LiteralPath $Path -Tail $Tail -Wait
