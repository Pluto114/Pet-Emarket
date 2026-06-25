$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$apiDir = Join-Path $root "backend\api-server"

Write-Host "Starting Pet-Emarket API server..."
Write-Host "Backend: http://localhost:8080"
Write-Host "Demo account: admin / Admin@123456"

Set-Location $apiDir
node .\src\server.js
