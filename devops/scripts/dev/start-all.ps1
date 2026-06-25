$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$apiDir = Join-Path $root "backend\pet-emarket-server"

Write-Host "Starting Pet-Emarket Java backend..."
Write-Host "Backend: http://localhost:8080"
Write-Host "Demo account: admin / Admin@123456"

Set-Location $apiDir
mvn spring-boot:run
