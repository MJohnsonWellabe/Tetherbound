# D13. `base: './'` rather than `/<repo-name>/`

Kind: implementation

`ARCHITECTURE.md` calls for the repo name so Pages can serve a project subpath.
Relative URLs do that without hard-coding the name, and they also survive
`vite preview`, a custom domain, and the LAN URL a phone hits during
`npm run dev --host`.
