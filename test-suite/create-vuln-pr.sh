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
PR_BODY="$(cat <<EOF
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
)"
PR_TITLE="test: introduce ${VULN_PACKAGE}@${VULN_VERSION} (${OSV_ID})"
COMPARE_URL="https://github.com/$(git remote get-url origin | sed -E 's#.*[:/]([^/]+)/([^/.]+)(\.git)?#\1/\2#')/compare/${BASE_BRANCH}...${BRANCH}?expand=1"

create_pr() {
  local token="$1"
  curl -fsS -X POST \
    -H "Authorization: Bearer ${token}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/iamsuganthi/secure-review-demo/pulls" \
    -d "$(node -e "
      console.log(JSON.stringify({
        title: process.argv[1],
        head: process.argv[2],
        base: process.argv[3],
        body: process.argv[4],
      }));
    " "$PR_TITLE" "$BRANCH" "$BASE_BRANCH" "$PR_BODY")" \
    | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{const j=JSON.parse(d); if(j.html_url) console.log(j.html_url); else process.exit(1);});"
}

PR_URL=""
for token in "${GH_TOKEN:-}" "${GITHUB_TOKEN:-}" "${GITHUB_MCP_PAT:-}"; do
  if [[ -n "$token" ]] && PR_URL="$(create_pr "$token" 2>/dev/null || true)"; then
    break
  fi
done

if [[ -z "$PR_URL" ]] && command -v gh >/dev/null 2>&1; then
  PR_URL="$(GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-${GITHUB_MCP_PAT:-}}}" gh pr create \
    --base "$BASE_BRANCH" \
    --head "$BRANCH" \
    --title "$PR_TITLE" \
    --body "$PR_BODY" 2>/dev/null || true)"
fi

echo
if [[ -n "$PR_URL" ]]; then
  echo "PR created: ${PR_URL}"
else
  echo "Could not create PR automatically (GitHub token needs pull_requests:write)."
  echo "Finish manually: ${COMPARE_URL}"
  exit 1
fi
