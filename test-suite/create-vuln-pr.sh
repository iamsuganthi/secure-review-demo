#!/usr/bin/env bash
# Creates branch "test-suite", pins a known-vulnerable lodash version from OSV,
# pushes to GitHub, and opens a PR against main.
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
git fetch origin
git checkout "$BASE_BRANCH"
git pull --ff-only origin "$BASE_BRANCH"

if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
  git branch -D "$BRANCH"
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
git push -u origin "$BRANCH" --force-with-lease

echo "==> Opening pull request"
PR_URL="$(gh pr create \
  --base "$BASE_BRANCH" \
  --head "$BRANCH" \
  --title "test: introduce ${VULN_PACKAGE}@${VULN_VERSION} (${OSV_ID})" \
  --body "$(cat <<EOF
## Summary
- Adds \`${VULN_PACKAGE}@${VULN_VERSION}\`, a version flagged by OSV as vulnerable to **${OSV_ID}**
- Includes \`test-suite/create-vuln-pr.sh\` to reproduce this PR on demand

## OSV reference
- https://osv.dev/vulnerability/${OSV_ID}
- Affected range: \`<= 4.17.23\`
- Patched in: \`4.18.0\`

## Test plan
- [ ] SecureReview / dependency scan flags lodash
- [ ] Autofix suggests upgrade to \`>= 4.18.0\`
EOF
)")"

echo
echo "PR created: ${PR_URL}"
