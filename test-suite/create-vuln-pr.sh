#!/usr/bin/env bash
# Creates branch "test-suite", pins known-vulnerable npm versions from OSV,
# adds simple code vulnerabilities, pushes to GitHub, and prints a PR link.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BRANCH="test-suite"
BASE_BRANCH="${BASE_BRANCH:-main}"

# package|version|osv-id
VULN_PACKAGES=(
  "lodash|4.17.23|CVE-2026-2950"          # fix available in 4.18.0
  "request|2.88.2|GHSA-p8p7-x288-28g6"   # no known fix; last npm release is affected
)

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

echo "==> Adding vulnerable dependencies from OSV"
node -e "
const fs = require('fs');
const entries = process.argv.slice(1);
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.dependencies = pkg.dependencies || {};
for (const entry of entries) {
  const [name, version] = entry.split('|');
  pkg.dependencies[name] = version;
}
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
" "${VULN_PACKAGES[@]}"

for entry in "${VULN_PACKAGES[@]}"; do
  IFS='|' read -r name version _ <<< "$entry"
  npm install "${name}@${version}" --save-exact
done

echo "==> Adding code vulnerabilities (SQL injection, BOLA)"
cp -R test-suite/vuln-files/src/. src/

COMMIT_BODY="Intentionally pins vulnerable npm packages for SecureReview testing:"
for entry in "${VULN_PACKAGES[@]}"; do
  IFS='|' read -r name version osv_id <<< "$entry"
  COMMIT_BODY="${COMMIT_BODY}
- ${name}@${version} (${osv_id}) https://osv.dev/vulnerability/${osv_id}"
done
COMMIT_BODY="${COMMIT_BODY}

Code vulnerabilities:
- SQL injection (A03): string-built query in src/lib/db/users.ts
- BOLA (A01): user profile route returns any id without ownership check"

git add package.json package-lock.json test-suite/ src/
git commit -m "$(cat <<EOF
test: add dependency and code vulnerabilities for SecureReview demo

${COMMIT_BODY}
EOF
)"

echo "==> Pushing ${BRANCH}"
git push -u origin "$BRANCH"

REPO="$(git remote get-url origin | sed -E 's#.*[:/]([^/]+)/([^/.]+)(\.git)?#\1/\2#')"
COMPARE_URL="https://github.com/${REPO}/compare/${BASE_BRANCH}...${BRANCH}?expand=1"

echo "==> Open a pull request"
echo
echo "Create PR: ${COMPARE_URL}"
