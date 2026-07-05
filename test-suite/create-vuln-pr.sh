#!/usr/bin/env bash
# Creates branch "test-suite", pins a known-vulnerable lodash version from OSV,
# pushes to GitHub, and prints a link to open a PR against main.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BRANCH="test-suite"
BASE_BRANCH="${BASE_BRANCH:-main}"
# OSV: https://osv.dev/vulnerability/CVE-2026-2950 — lodash <= 4.17.23
VULN_PACKAGE="lodash"
VULN_VERSION="4.17.23"
OSV_ID="CVE-2026-2950"

echo "==> Syncing ${BASE_BRANCH} from origin"
git fetch origin --prune
git checkout "$BASE_BRANCH"
git pull --ff-only origin "$BASE_BRANCH"

echo "==> Deleting existing ${BRANCH} branch (local and remote)"
if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
  git branch -D "$BRANCH"
fi
if git ls-remote --exit-code --heads origin "$BRANCH" >/dev/null 2>&1; then
  git push origin --delete "$BRANCH"
fi

git checkout -b "$BRANCH"

echo "==> Adding ${VULN_PACKAGE}@${VULN_VERSION} (${OSV_ID})"
node -e "
const fs = require('fs');
const pkgPath = 'package.json';
const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
pkg.dependencies = pkg.dependencies || {};
pkg.dependencies['${VULN_PACKAGE}'] = '${VULN_VERSION}';
fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + '\n');
"

npm install "${VULN_PACKAGE}@${VULN_VERSION}" --save-exact

git add package.json package-lock.json test-suite/
git commit -m "$(cat <<EOF
test: add ${VULN_PACKAGE}@${VULN_VERSION} for SecureReview demo

Intentionally pins a version affected by ${OSV_ID} (prototype pollution in
_.unset / _.omit). See https://osv.dev/vulnerability/${OSV_ID}
EOF
)"

echo "==> Pushing ${BRANCH}"
git push -u origin "$BRANCH"

REPO="$(git remote get-url origin | sed -E 's#.*[:/]([^/]+)/([^/.]+)(\.git)?#\1/\2#')"
COMPARE_URL="https://github.com/${REPO}/compare/${BASE_BRANCH}...${BRANCH}?expand=1"

echo "==> Open a pull request"
echo
echo "Create PR: ${COMPARE_URL}"
