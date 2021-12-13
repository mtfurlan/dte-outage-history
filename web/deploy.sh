#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

npm run build
cd dist
git init
git add -A
git commit -m "deply"
git push -f git@github.com:mtfurlan/dte-outage-history.git main:gh-pages
cd ..
