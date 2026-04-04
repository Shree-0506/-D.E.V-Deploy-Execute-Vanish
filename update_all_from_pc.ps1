param(
    [string]$ServerIp = "139.59.12.72",
    [string]$ServerUser = "root",
    [string]$BackendZipName = "cashurance-backend-fixed.zip",
    [string]$ApiBaseUrl = "",
    [switch]$SkipFirebaseDeploy
)

$ErrorActionPreference = "Stop"

$workspaceRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendPath = Join-Path $workspaceRoot "cashurance-backend"
$flutterPath = Join-Path $workspaceRoot "cashurance"
$tempPath = Join-Path $workspaceRoot "_deploy_tmp"
$backendZipPath = Join-Path $workspaceRoot $BackendZipName

Write-Host "[1/6] Preparing backend zip..."
if (Test-Path $backendZipPath) { Remove-Item $backendZipPath -Force }
if (Test-Path $tempPath) { Remove-Item $tempPath -Recurse -Force }
New-Item -ItemType Directory -Path (Join-Path $tempPath "cashurance-backend") -Force | Out-Null
Copy-Item (Join-Path $backendPath "*") (Join-Path $tempPath "cashurance-backend") -Recurse -Force

$removeDirs = @(
  (Join-Path $tempPath "cashurance-backend/node_modules"),
  (Join-Path $tempPath "cashurance-backend/node/node_modules"),
  (Join-Path $tempPath "cashurance-backend/node/uploads"),
  (Join-Path $tempPath "cashurance-backend/node/database.sqlite"),
  (Join-Path $tempPath "cashurance-backend/python/.venv"),
  (Join-Path $tempPath "cashurance-backend/python/venv"),
  (Join-Path $tempPath "cashurance-backend/python/__pycache__"),
  (Join-Path $tempPath "cashurance-backend/python/app/__pycache__")
)
$removeDirs | ForEach-Object { if (Test-Path $_) { Remove-Item $_ -Recurse -Force } }

Compress-Archive -Path (Join-Path $tempPath "cashurance-backend") -DestinationPath $backendZipPath -CompressionLevel Optimal
Remove-Item $tempPath -Recurse -Force

Write-Host "[2/6] Uploading backend zip to server..."
$remoteHost = "$($ServerUser)@$($ServerIp)"
$remoteScpTarget = "${remoteHost}:/opt/"
& scp $backendZipPath $remoteScpTarget
if ($LASTEXITCODE -ne 0) {
    throw "SCP upload failed with exit code $LASTEXITCODE"
}

Write-Host "[3/6] Deploying backend remotely..."
$remoteLines = @(
    'set -euo pipefail',
    'echo "[remote] Cleaning previous backend..."',
    'rm -rf /opt/cashurance-backend',
    'echo "[remote] Extracting backend zip..."',
    'set +e',
    "unzip -o /opt/$BackendZipName -d /opt",
    'unzip_code=$?',
    'set -e',
    'if [ "$unzip_code" -gt 1 ]; then exit $unzip_code; fi',
    'echo "[remote] Installing Node dependencies..."',
    'cd /opt/cashurance-backend',
    'npm install',
    'echo "[remote] Preparing Python virtualenv..."',
    'python3 -m venv python/.venv',
    'python/.venv/bin/pip install -r python/requirements.txt',
    'echo "[remote] Starting PM2 process..."',
    'npm install -g pm2',
    'pm2 delete cashurance-backend >/dev/null 2>&1 || true',
    'PYTHON_BIN=/opt/cashurance-backend/python/.venv/bin/python pm2 start npm --name cashurance-backend -- start',
    'pm2 save',
    'echo "[remote] Waiting for backend health..."',
    'for i in $(seq 1 30); do curl -fsS http://127.0.0.1:3000/health && exit 0; sleep 2; done',
    'echo "[remote] Health check failed. PM2 logs:"',
    'pm2 logs cashurance-backend --lines 120 --nostream',
    'exit 1'
)
$remoteScript = (($remoteLines -join "`n") + "`n")

$remoteScript | & ssh $remoteHost "bash -s"
if ($LASTEXITCODE -ne 0) {
    throw "Remote backend deploy failed with exit code $LASTEXITCODE"
}

Write-Host "[4/6] Building Flutter web..."
Push-Location $flutterPath
if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
    flutter build web --release
} else {
    flutter build web --release --dart-define="API_BASE_URL=$ApiBaseUrl"
}
Pop-Location

if (-not $SkipFirebaseDeploy) {
    Write-Host "[5/6] Deploying Flutter web to Firebase..."
    Push-Location $flutterPath
    firebase deploy
    Pop-Location
} else {
    Write-Host "[5/6] Skipping Firebase deploy as requested."
}

Write-Host "[6/6] Done. Backend + frontend update completed." -ForegroundColor Green