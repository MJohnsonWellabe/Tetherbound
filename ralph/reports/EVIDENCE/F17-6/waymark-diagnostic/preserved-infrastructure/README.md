# Hall capture successor R3 — prepared, not admitted

Capture-only successor for source `5650c507e69ed0a7b6feaf72d1f345e406c98109`, after root's separate reconciliation. No transition helper is included or retried. Original R2, raw-first helper, failure receipt and reconciliation evidence remain unchanged. Root alone owns stage access, admission and engine execution.

`run_hall_window.ps1 -CpuPacketFixture` validates the packet without stage access. Normal invocation rejects while the supplied job/admission remain PREPARED/NOT_ADMITTED. Root must independently review this successor and perform its existing explicit admission procedure, rebinding the admission job digest after any authorized admission changes. No admission is implied by CPU results. The fresh job ID is `hallwindow565-r3`; output is `D:/tetherbound/.artifacts/s/run-hallwindow565-r3`.

The same frozen 565 capture manifest, source bindings, accepted Terrain DLL, two Medium arms, cameras, process limits and resource floors are retained. Each arm still has its own 120-second capture deadline. No source pin changed. The old staging-base metadata remains 287 for verifying the exact declared tree delta; it does not request another transition.

## Source verification

The unbounded Invoke-Git wrapper and broad Git status call are removed. A separate read-only Python checker compares the entire 49,363-path index with the expected 565 tree, validates parent and changed-path metadata, and checks every physically present tracked file even if skip-worktree is set. The 12,911 required materialized paths, 4,205 permitted CRLF paths and 16 deleted paths derive from the pinned independent audit and its hash-bound failed-state materialization record. All 105 content bindings remain checked. Required missing files, unmerged/index differences, modified content and reappearing deleted paths fail.

Raw Git blob identity is checked first. Only the audit's explicit canonical path list permits replacing CRLF with LF, and even then the complete resulting Git blob identity must match the target. This does not strip arbitrary whitespace or accept content changes. Binary bindings, including the DLL, use binary SHA256. Canonical binding hashes retain the frozen UTF-8/BOM/CRLF convention.

The checker streams materialized content once, with at most 64 MiB retained per approved text file; raw assets are streamed in 1 MiB chunks. It verifies file identity/size/mtime around reads and unchanged HEAD/index bytes at completion. Sparse absence is allowed only outside the required set with skip-worktree set. Reparse paths are refused. Arbitrary untracked or ignored engine files are outside tracked-source coverage, as before.

The supervisor bounds the checker at 120 seconds, including terminal pipe drain. The checker has a shared 115-second deadline and each metadata-only Git invocation gets at most 30 seconds or its remaining budget. No per-file Git subprocess or blob batch query is used. The outer supervisor independently bounds blocked filesystem reads. Output readers cap each stream at 1,048,576 characters and fail on overflow. Live owned process trees are killed on failure; exit wait is bounded at 1 second and final pipe cleanup at 250 ms. Inherited-pipe failure after a parent exits is bounded too. Cleanup may extend a failed attempt by those bounded allowances; it never turns the attempt into a pass.

The authoritative initial check runs after the existing exclusive owner lock and requires owner.source=565; initial check failure releases that lock. Each capture repeats the same bounded audit under the retained lock. Successful audit summaries are recorded in the run and per-step receipts. Initial failure still propagates as a terminating supervisor error before capture output creation, so root should retain its invoking terminal output. No capture launch or lease claim follows a failed audit.

## Validation and limitations

- 13 source fixtures: raw CRLF, reviewed canonical CRLF, binary binding, sparse absence, dirty content outside bindings, dirty canonical content, unauthorized normalization, missing required path, deleted path resurrection, dirty skip-worktree file, full-index tamper, binding mismatch, aggregate deadline, mid-audit index/HEAD changes and slow Git subprocess (some cases combine checks).
- Six bounded-process fixtures: success, stalled checker, late zero exit, output overflow, nonzero exit and inherited pipes.
- Existing nine capture drain/deadline fixtures and four arm-reset fixtures pass against the final supervisor.
- Contract verified against the exact offline 565 tree; PowerShell parsing, CpuPacketFixture and NOT_ADMITTED rejection pass. Frozen original hashes remain verified.

See the `cpu-*-results.json` files and `ready-manifest.json` for exact evidence and digests. Fixture repositories sit outside native-supervisor and are not a capture dependency. No native preflight or timing measurement was run by this lane; whether 3.46 GB can be verified within the cap on the current machine remains root's authorized preflight question. A timeout must fail without capture; do not silently extend it. Independent review and native admission are still pending. No criterion is closed.
