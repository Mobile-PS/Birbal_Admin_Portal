#!/usr/bin/env bash
# Build a production Flutter web bundle into build/web.
#
# Usage:
#   ./scripts/build_web.sh
#   BASE_URL=https://birbaladvice.com/api/v1 BASE_HREF=/ ./scripts/build_web.sh
#   BASE_HREF=/admin/ ./scripts/build_web.sh   # if hosted under a subpath
#
# Deploy the contents of build/web to your server document root.
# See deploy/nginx.conf.example (Nginx) or web/.htaccess (Apache).

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

export PATH="${PATH}:/Users/apaar/flutter/bin:${HOME}/flutter/bin"

BASE_URL="${BASE_URL:-https://birbaladvice.com/api/v1}"
BASE_HREF="${BASE_HREF:-/}"

# Ensure base-href always starts and ends with "/".
if [[ "$BASE_HREF" != /* ]]; then
  BASE_HREF="/${BASE_HREF}"
fi
if [[ "$BASE_HREF" != */ ]]; then
  BASE_HREF="${BASE_HREF}/"
fi

echo "Building Birbal Advice Admin web"
echo "  BASE_URL  = ${BASE_URL}"
echo "  BASE_HREF = ${BASE_HREF}"

flutter pub get
flutter build web --release \
  --no-web-resources-cdn \
  --base-href "${BASE_HREF}" \
  --dart-define=BASE_URL="${BASE_URL}"

cp -f deploy/nginx.conf.example build/web/nginx.conf.example

echo
echo "Build ready: ${ROOT_DIR}/build/web"
echo "Upload that folder to your server (Nginx/Apache document root)."
du -sh build/web
