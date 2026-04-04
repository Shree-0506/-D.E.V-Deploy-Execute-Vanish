#!/usr/bin/env bash
set -euo pipefail

ZIP_PATH="${1:-/opt/cashurance-deploy.zip}"
EXTRACT_ROOT="/opt/v1"
APP_NAME="cashurance-backend"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Please run as root: sudo bash deploy_from_scratch.sh [zip-path]"
  exit 1
fi

if [[ ! -f "${ZIP_PATH}" ]]; then
  echo "Zip file not found: ${ZIP_PATH}"
  echo "Upload your deployment zip first, e.g. to /opt/cashurance-deploy.zip"
  exit 1
fi

echo "[1/7] Installing system packages..."
export DEBIAN_FRONTEND=noninteractive
apt update -y
apt install -y unzip curl ca-certificates gnupg lsb-release python3 python3-pip python3-venv build-essential ufw

echo "[2/7] Installing Node.js 20 if needed..."
if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt install -y nodejs
else
  NODE_MAJOR="$(node -v | sed -E 's/^v([0-9]+).*/\1/')"
  if [[ "${NODE_MAJOR}" -lt 20 ]]; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt install -y nodejs
  fi
fi

echo "[3/7] Extracting project zip..."
mkdir -p "${EXTRACT_ROOT}"
unzip -o "${ZIP_PATH}" -d "${EXTRACT_ROOT}" >/dev/null

BACKEND_DIR="$(find "${EXTRACT_ROOT}" -maxdepth 4 -type d -name cashurance-backend | head -n1 || true)"
if [[ -z "${BACKEND_DIR}" ]]; then
  # Support backend-only zips that extract directly to /opt/v1 without enclosing folder.
  if [[ -f "${EXTRACT_ROOT}/package.json" && -d "${EXTRACT_ROOT}/node" && -d "${EXTRACT_ROOT}/python" ]]; then
    BACKEND_DIR="${EXTRACT_ROOT}"
  elif [[ -f "${EXTRACT_ROOT}/cashurance-backend/package.json" && -d "${EXTRACT_ROOT}/cashurance-backend/node" && -d "${EXTRACT_ROOT}/cashurance-backend/python" ]]; then
    BACKEND_DIR="${EXTRACT_ROOT}/cashurance-backend"
  else
    echo "Could not locate cashurance-backend after extraction."
    echo "Tip: zip should contain either cashurance-backend/ folder or package.json + node/ + python/ at root."
    exit 1
  fi
fi

echo "[4/7] Installing backend dependencies..."
cd "${BACKEND_DIR}"
npm install

echo "[5/7] Installing PM2 and starting backend stack..."
npm install -g pm2
pm2 delete "${APP_NAME}" >/dev/null 2>&1 || true
pm2 start npm --name "${APP_NAME}" -- start
pm2 save
pm2 startup systemd -u root --hp /root >/dev/null 2>&1 || true

echo "[6/7] Opening firewall ports (22, 3000, 8001)..."
ufw allow 22/tcp >/dev/null 2>&1 || true
ufw allow 3000/tcp >/dev/null 2>&1 || true
ufw allow 8001/tcp >/dev/null 2>&1 || true
ufw --force enable >/dev/null 2>&1 || true

echo "[7/7] Verifying API health..."
for i in {1..20}; do
  if curl -fsS "http://127.0.0.1:3000/health" >/dev/null; then
    echo "Deployment complete. Node and Python backends are running via PM2."
    pm2 status
    exit 0
  fi
  sleep 2
done

echo "Services started but health check did not pass in time."
echo "Check logs: pm2 logs ${APP_NAME}"
exit 1
