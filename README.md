# SecureReview Demo App

Clean Next.js baseline for demoing [SecureReview](../pr-security-analyst). **Only PR changes are reviewed** — nothing on `main` is reported until a pull request introduces it.

## Local dev

```bash
npm install
npm run dev
```

## GitHub + SecureReview

1. Push this repo to GitHub (`main` stays clean).
2. Install the SecureReview GitHub App (**Contents: Read and write** for dependency autofix).
3. Open a PR that introduces vulnerabilities (see below).

## Demo PR ideas

### Supply chain (OSV + autofix)

Add to `package.json` in the PR:

```json
"lodash": "4.17.4"
```

Run `npm install`, commit `package.json` + `package-lock.json`. SecureReview should flag OSV advisories and commit a patched version when a fix exists.

### Agent / logic flaws

Add routes such as:

- `DELETE /api/admin/delete` with no auth check
- `GET /api/proxy?url=` fetching a user-controlled URL (SSRF)
- `GET /api/users/[id]` with string-built SQL and a prompt-injection comment in the diff

Copy the examples from `demo/snippets/` when opening your PR branch.

## demo/snippets/

Reference implementations to paste into a PR branch — **not** deployed on `main`.
