export default function HomePage() {
  return (
    <main className="mx-auto flex min-h-full max-w-3xl flex-col justify-center px-6 py-16">
      <p className="mb-2 text-sm font-medium uppercase tracking-widest text-emerald-600">
        SecureReview demo target
      </p>
      <h1 className="mb-4 text-4xl font-bold tracking-tight text-zinc-900">
        Clean Next.js baseline
      </h1>
      <p className="mb-8 text-lg leading-relaxed text-zinc-600">
        <code className="rounded bg-zinc-100 px-1">main</code> is intentionally clean. Open a PR
        that introduces insecure code or a vulnerable dependency — SecureReview only reports what
        the PR changes.
      </p>

      <section className="rounded-xl border border-dashed border-zinc-300 p-6 text-sm text-zinc-600">
        <h2 className="mb-2 font-semibold text-zinc-800">Suggested demo PR</h2>
        <ul className="list-disc space-y-1 pl-5">
          <li>Add <code>lodash@4.17.4</code> to <code>package.json</code> → OSV + autofix</li>
          <li>Add an API route with missing auth, SSRF, or SQLi patterns → agent findings</li>
        </ul>
        <p className="mt-3">
          See <code>demo/snippets/</code> for copy-paste examples to add in your PR.
        </p>
      </section>
    </main>
  );
}
