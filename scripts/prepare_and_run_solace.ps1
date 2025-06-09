# PowerShell script to launch the Solace Docker environment
Write-Host "🔧 Executing docker-compose from: $PWD" -ForegroundColor Cyan

# Validate .env
if (-Not (Test-Path ".env")) {
    Write-Host "❌ Missing '.env' file in $PWD. Please create one before running this script." -ForegroundColor Red
    exit 1
} else {
    Write-Host "✅ Found '.env' in $PWD." -ForegroundColor Green
}

# Validate docker-compose.yml
if (-Not (Test-Path "docker-compose.yml")) {
    Write-Host "❌ Missing 'docker-compose.yml' in $PWD. Cannot proceed." -ForegroundColor Red
    exit 1
} else {
    Write-Host "✅ Found 'docker-compose.yml' in $PWD." -ForegroundColor Green
}

# Optional: Show which profiles are available
Write-Host "`n📋 Available profiles:" -ForegroundColor Yellow
docker compose config --profiles

# Launch with all profiles
Write-Host "`n🚀 Attempting to launch Docker services using all profiles..." -ForegroundColor Cyan
$composeCommand = "docker compose --profile core --profile ai --profile optional up -d --build"
Invoke-Expression $composeCommand

# Check if services started
if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Docker services launched successfully." -ForegroundColor Green
} else {
    Write-Host "`n❌ ERROR: Docker Compose command failed with exit code $LASTEXITCODE." -ForegroundColor Red
    Write-Host "Please check for syntax errors or image build issues." -ForegroundColor Yellow
    exit $LASTEXITCODE
}
