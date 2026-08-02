# D14. Firebase web config is committed, not injected from CI secrets

Kind: implementation

The web API key is a public project identifier. It names a project and
authorizes nothing; security lives entirely in `firestore.rules` and the
authorized-domains allowlist.

Vite inlines `import.meta.env` at build time regardless, so a key "protected"
as a CI secret still ships as a plaintext literal in the bundle. Treating it as
secret would only break local dev, break `npm run preview`, and break the LAN
host a phone connects to, while protecting nothing.

Resolution is keyed on hostname. Any host not on the production allowlist
resolves to `dev`, which runs local-only with the cloud layer fully dormant and
the Firebase SDK never imported at all.
