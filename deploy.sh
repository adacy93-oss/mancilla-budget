#!/bin/bash
# Deploy Mancilla Budget (Descent) to GitHub Pages from any session.
# Usage: GH_TOKEN=xxx ./deploy.sh [repo-name]
set -e
REPO=${1:-mancilla-budget}
API=https://api.github.com
H=(-H "Authorization: Bearer $GH_TOKEN" -H "Accept: application/vnd.github+json")
USER=$(curl -sf "${H[@]}" $API/user | python3 -c 'import sys,json;print(json.load(sys.stdin)["login"])')
echo "GitHub user: $USER"
# 1. repo (create if missing)
if ! curl -sf "${H[@]}" $API/repos/$USER/$REPO >/dev/null; then
  curl -sf "${H[@]}" $API/user/repos -d "{\"name\":\"$REPO\",\"private\":false,\"auto_init\":true,\"description\":\"Mancilla Budget\"}" >/dev/null
  echo "created repo $REPO"; sleep 2
fi
# 2. push the site
cd /home/claude/descent/site
rm -rf .git; git init -q; git checkout -q -b main
git config user.email deploy@descent; git config user.name descent-deploy
cp /home/claude/descent/deploy.sh . 2>/dev/null || true
git add -A; git commit -qm "deploy $(date -u +%Y-%m-%dT%H:%MZ)"
git push -q -f https://x-access-token:$GH_TOKEN@github.com/$USER/$REPO.git main
echo "pushed"
# 3. enable Pages from main / (idempotent)
curl -s "${H[@]}" $API/repos/$USER/$REPO/pages -d '{"source":{"branch":"main","path":"/"}}' >/dev/null || true
curl -s "${H[@]}" -X PUT $API/repos/$USER/$REPO/pages -d '{"source":{"branch":"main","path":"/"}}' >/dev/null || true
URL=$(curl -sf "${H[@]}" $API/repos/$USER/$REPO/pages | python3 -c 'import sys,json;print(json.load(sys.stdin).get("html_url",""))')
echo "LIVE URL: $URL"
echo "local sha256: $(sha256sum index.html | cut -c1-16)  bytes: $(wc -c <index.html)"
