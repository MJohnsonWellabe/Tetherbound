# P2 tournament frame costs

Coordinator task: #525 comment 6012177191. Baseline: origin/main
8e7c11ceb5854f063c5241d62618c382803562c9. Source brief: origin/tb/perf,
ralph/reports/PERF/HANDOFF.md item 6 and Known traps; reference 10cdde31.

## Current disposition: acceptance OPEN

Independent final review supports bounded boot-refresh and camp-function cost
reductions. Glow gain is unproved and both tournament profiles fail. No P2 DONE
or functional/visual/feel acceptance is claimed; coordinator disposition is pending.

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

Warm profiler self-time observations and their limits appear below; no visual
verdict exists. The first
independent source review rejected across-draw reuse of dynamic terrain/water;
the candidate now resamples those queries on every rebuild. Independent
`c3_journal_review` final SOURCE PASS covers all nine source/test files against
8e7c11ceb: no stale dynamic-height reuse, camp matching/ancestry preserved,
native dirty/missing-cell contract supports the refresh. Native buffers,
real SceneTree group-result equivalence and complete criterion acceptance remain OPEN.

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

## First host profile: FAIL before tournament

Existing --tournament with original six product files and host -d --profiling
completed exit 2: host did not say hello within the unchanged 180 s deadline.
Guest hello was recorded; the host's pre-teardown exited=false summary is retained,
and all actual owned processes exited before source/helper restoration and lease release.
Native check-only passed. The partial startup dump includes minimap bake self
95.647941 seconds; nested call() totals are not additive. No target ground-vertex,
camp-scan or vegetation-refresh self row was reached. This is no tournament profile
or before performance acceptance. Raw receipt/compiler/output/net/private logs and
the actual generated production map cache are preserved under profile-before.

The helper's CRLF-only insertion guard first yielded before engine/evidence; its
LF-preserving correction produced the actual launched profile. The temporary patch
was restored byte-exact and is retained only as evidence. The cold candidate counterpart was not run. Reuse of the completed shipping
minimap cache equally in fresh
original/candidate private homes has independent SOURCE PASS: unchanged cache
key/schema/terrain input, real PNG decoding and honest miss fallback. Actual cache
hit observation must come from native rows, not a receipt assertion. No budget change
or fresh target timing has been accepted.

## Warm production-map host profiles: terminal, functional FAIL

Both existing profiles ran serially and alone at producer
108eb16ac8fe82f0585b78a1f6cef86592e0aa48. The original uses six original
product files at 8e7c11ceb; the candidate uses the unchanged P2 product.
Host 0 has -d --profiling; guest arguments, assertions and budgets are unchanged.
Both fresh independent pairs were seeded with the exact completed original
production map PNG and key, validated before copying. Native bake_cached rows
are 0.017589 / 0.018200 seconds SELF, one call, with no bake child row in either
dump. This supports the shipping cached branch; no synthetic cache or hit log.

Example raw native callee SELF rows (seconds; caller totals are not additive):

| Target | Original SELF / calls | Candidate SELF / calls | Scope |
| --- | --- | --- | --- |
| vegetation::_refresh_render_instances | 27.147906 / 37 | 3.202467 / 37 | Same boot-time clear_area call count; not an arena window or buffer-content equivalence. |
| companion_presence::_scan_camp_sources | 0.389037 / 1 | 0.000160 / 1 | Later raw rows also retained; helper work and membership need review. |
| telegraph_glow::_ground_vertex | 0.165152 / 400 | 0.166780 / 400 | First matching-count samples overlap; no clear glow gain claimed. |

These are examples from full retained frame dumps, not a repeatable benchmark,
matched full-tournament workload, FPS/feel claim or all-frame aggregate. Other
glow rows vary: original 0.184951 / 400 and candidate 0.165080 / 400 also occur.
No cherry-picked later row is substituted for the inconclusive first comparison;
hoisted context/helper work must be considered in the independent verdict.

Original profile-before-warm exits 1: both peers opened/joined/deployed Mira's
shared quarter encounter and reduced its opponent HP, but round completion
reached the original deadline with no verdict. Candidate profile-after-warm
exits 1: Mira completes, but guest join/hit/reward checks and its accepted durable
reward receipts fail; Tam then reaches the original deadline with no verdict.
All failures, character/world saves and pre-teardown observations are retained.
No authority-cause claim, functional PASS or P2 criterion closure follows.

Own peers exited, helper bytes match HEAD exactly, candidate tracked sources
are clean, and only matching owned leases were released. The actual quiet pair
is serviced; root released R2's P2 CPU reservation in #525 comment 6014265515.
Per-stage SHA256.json preserves every original raw file (23 before, 24 after).
Independent final review of native costs and remaining acceptance follows below.
No repeated unit, cold baseline or profiler run is requested.
## Independent final scope verdict

c3_journal_review verifies all 47 original manifest entries, retained map bytes,
restored harness/product sources and actual all-own-engines-gone census. Evidence
integrity PASS; source PASS; functional acceptance HOLD. The summary's
host exited=false is a pre-teardown snapshot, retained without rewriting.

- Vegetation: bounded COST PASS for 37 world-construction/clear_area calls,
  reported SELF 27.147906 -> 3.202467 seconds (about 88.2% lower). Combat arena
  hide/restore cost and native buffer/visual equivalence remain OPEN.
- Camp: bounded COST PASS across all samples, original 15 one-call rows
  0.387228-0.425123 seconds/call; candidate 11 rows/13 calls
  0.000146-0.000169 seconds/call, plus 4-6 microseconds/call group helper.
  Live group-result equivalence is not established by timing alone.
- Glow: GAIN HOLD after reviewing all 11 original and 48 candidate rows.
  Equal-400-call ranges overlap (0.163091-0.184951 vs 0.161910-0.185572 seconds).
  First inclusive draw work also lacks a benefit (0.166575 -> 0.167889 seconds).
  Different encounters/exposure prevent a matched sustained-combat claim.

These findings prove no authority cause or P2 regression. FPS, feel,
repeatability, native equivalence and successful tournament acceptance remain
OPEN. Coordinator disposition or a reviewed round/reward dependency is needed
before repeating the affected existing combat proof. No protected source,
assertion, fixture, profiling API or budget workaround is authorized by this
review. P2 is not DONE; the three completed profiler stages remain immutable.