# P2 tournament frame costs

Coordinator task: #525 comment 6012177191. Baseline: origin/main
8e7c11ceb5854f063c5241d62618c382803562c9. Source brief: origin/tb/perf,
ralph/reports/PERF/HANDOFF.md item 6 and Known traps; reference 10cdde31.

## Candidate, acceptance OPEN

- Telegraph glow retains its radius/alpha pulse and fresh dynamic ground/water
  heights. One synchronous rebuild resolves origin and query capabilities once
  and memoizes identical XZ samples. Unchanged draws skip only when neither a
  ground nor water API can change the result. The existing triangle strip has
  almost all distinct points at positive radius: the collapsed-point regression
  is a correctness witness, not evidence of ordinary combat speedup.
- Companion camp scans query authored candidate and explicit opt-in groups,
  retaining suffix configuration, ancestor/UI exclusions and fresh membership.
  Detached fixtures and custom unregistered suffixes retain the original walk.
  The three existing camp source scripts register themselves without changing
  their construction, persistence or resting behavior.
- Vegetation refresh uses Terrain3D's modified/missing-cell update instead of
  destroying and rebuilding all cells. Initial construction remains unchanged;
  transforms, colors, hide/restore tokens and durable harvesting are unchanged.
  Installed addon version is 1.0.2. The [exact upstream native source](https://raw.githubusercontent.com/TokisanGames/Terrain3D/v1.0.2-stable/src/terrain_3d_instancer.cpp)
  marks additions/removals dirty, creates missing cells, skips clean cells,
  and destroys all buffers only for the full rebuild option.

No before/after profiler self-time rows or visual verdict exist yet. The first
independent source review rejected across-draw reuse of dynamic terrain/water;
the candidate now resamples those queries on every rebuild. Independent
`c3_journal_review` final SOURCE PASS covers all nine source/test files against
8e7c11ceb: no stale dynamic-height reuse, camp matching/ancestry preserved,
native dirty/missing-cell contract supports the refresh. Native buffers,
real SceneTree group behavior and measured gain remain OPEN.

## Native component evidence, qualified PASS

Producer fd3e095bc32bef2202a33b79ed89c07cd8d3405d, Godot 4.7 official.
The quiet global lease covered one independent P1 cache copy (2751 files,
957549007 bytes, matching actual asset/addon/project inputs) and the first
two existing-runner stages. No import or writable cache sharing occurred.

- `unit-before`: six original product files at 8e7c11ceb, current new tests.
  Four selected tests / 19 assertions / four expected failed methods / exit 1,
  empty stderr. Camp visits 232 nodes instead of four; Compatibility vegetation
  requests two full rebuilds; dry-ring redraw and collapsed-point sampling fail.
- `unit-after`: current candidate, all three affected existing test files.
  50 tests / 316 assertions / zero failed / exit 0. Nine native ERROR rows from
  detached harvest absolute-path lookups remain; no SCRIPT/Parse error or leak.
- `unit-baseline-harvest`: only the two unchanged harvest methods on original
  product, two tests / six assertions / zero failed / exit 0. Its 5187-byte stderr
  is identical to `unit-after`: SHA256
  `138B0B97D842E2D989E685CF254E86D2531FE52DB5D2F820244AC271746F5AA6`.
  These logged null lookups take explicit fallbacks; assertions continue.
  This attribution ran under WORKFLOW §4's warm-cache read-only unit carve-out
  beside the exact known R1 job recorded in its receipt; no timing claim.

Original receipts/stdout/stderr/exit and per-stage hashes are retained unchanged,
including expected RED and native diagnostics. Recursive `UNIT_SHA256.json`
also covers incidental private boot/engine logs. Independent c3_journal_review verifies all 12 original manifest entries and
the byte-identical inherited diagnostics: qualified component PASS. This is component evidence,
not clean runtime acceptance, live group/native buffer proof or measured gain.

Required existing checks: telegraph_glow, companion_presence and
fight_ring_occluders focused tests; demonstrate the new performance regressions
on original product code; existing smoke_net_shared_boss --tournament host
profiles under -d --profiling in quiet serialized windows. The env-gated peer
profiling patch is temporary and must never be committed. Quote callee self-time
rows, accounting for Godot's call() double counting; no FPS/device claim.

No new harness, fixture, pilot, capture tool, measurement script, network code,
test-budget change, PR or production flag change. Profile acceptance is still OPEN; no
criterion closure. Failed and incomplete future native logs stay preserved.
