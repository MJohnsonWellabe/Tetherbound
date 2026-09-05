# N11-TERRAIN-BAKE — re-bake the stale terrain manifest — lane report

Branch: `ralph/N11-TERRAIN-BAKE-0905`, from `origin/main` at `f8a47ee4` (PR #51 merge).
Session: `session_01PBLLN9soLdr9PmagJEFCv1` (Fable), created 2026-09-05 13:37 UTC.
**Commit:** this report and the code below land as one commit; its hash is in the branch
head (`git log --oneline -1 origin/ralph/N11-TERRAIN-BAKE-0905`) because a file cannot name
the commit that saves it. The base every number here was measured on is `f8a47ee4`.

## The brief was not in the repository

The launch prompt said to read `ralph/briefs/0905-followup/COMMON.md` and
`ralph/briefs/0905-followup/N11-TERRAIN-BAKE.md`. Neither exists on `origin/main`
(`f8a47ee4`), on any of the 20 `ralph/*` branches, on `claude/codex-merge-meadows-finish-dq12jj`,
`codex/cloudreach-cliffs`, or on any of the 52 PR heads (`git ls-remote` over every ref,
re-checked with `git fetch` after the clone). The only briefs directory on `main` is
`ralph/briefs/0904/`, and it holds only `LANES.md`. The session was created with no
repository attached at all; `MJohnsonWellabe/Tetherbound` was attached from the session
title (*"Lane N11-TERRAIN-BAKE (Fable): re-bake the stale terrain manifest"*) and cloned.
The parent session (`session_012LVyP4m2khjJ9Pczw8Gai3`) could not be reached by peer message
(no other session live on this host).

So this lane worked from the title and from the repository's own record of the incident,
under the 0904 wave's conventions: branch `ralph/<LANE>-<date>`, report under
`ralph/reports/<LANE>-<date>/`, the `docs/AGENT_WORKFLOW.md` §4 contract, no PR. Every
judgement call is recorded below so the orchestrator can overrule it against the real brief.

## What "stale terrain manifest" turned out to mean

The record on `main` (`docs/CURRENT_STATE.md` §1, `ralph/briefs/0904/LANES.md`,
`docs/HANDOFF_2026-09-03.md` §2, commits `0702ad4c`, `3c73aab5`, `f2dd20e4`, `2724b5af`):

| Commit | What happened to `data/terrain/playground` |
|---|---|
| `0702ad4c` (2026-09-03 02:29Z) | last real full bake committed: 63/64 regions byte-identical, one differs by 15 bytes of serialization; manifest written, fingerprint 2765491071 |
| `3c73aab5` (PR #29, 2026-09-03 21:35Z) | `terrain_playground.json` edited (the *Pond Circuit* trailhead `at` moved from (−357.76, 401.12) to (−228, 331)); **only `manifest.json` changed**, fingerprint → 1823724492, **no region file changed** |
| `f2dd20e4` (Codex, Windows) | only the `config_fingerprint` line changed, → 4395215917; both freshness guards went red on `main` |
| `2724b5af` (PR #42) | fingerprint restored to 1823724492 by hand; guards green again |

Two open questions came out of that, and both are now answered by measurement rather than
by reading:

**1. Are the committed region files stale against the config the manifest vouches for?**
The last region bake (`0702ad4c`) predates the trailhead move; `3c73aab5`'s "re-bake"
touched no region, and the 2026-09-03 handoff says the terrain re-bake it started never
finished. **No.** A full 64-region bake on `f8a47ee4` decodes pixel-for-pixel identical to
the committed data in every region (§ Evidence). The trailhead `at` is read by
`signpost.gd`, `severed_spokes.gd` and `playground_world.gd` at run time and never by
`playground_heightfield.gd` or `build_playground_terrain.gd`, so that edit could not move a
pixel — the manifest re-stamp in `3c73aab5` was the correct output of a bake whose region
files came back identical. The manifest is honest.

**2. Why did `f2dd20e4` write a "wrong" fingerprint from a tree with no bake input
changed?** Because the fingerprint hashes the file's raw text and the Codex session ran on a
Windows checkout (`D:\Tetherbound-source`, per `docs/CURRENT_STATE.md`'s exit note) where
`core.autocrlf` hands `FileAccess.get_as_text()` CRLF endings. Reproduced exactly, both
guards:

| Manifest | Value `f2dd20e4` wrote | LF hash of the same inputs | CRLF hash of the same inputs |
|---|---|---|---|
| `data/terrain/playground` | 4395215917 | 1823724492 | **4395215917** |
| `data/scatter/playground` | 404295163156206 | 7496100143687718 | **404295163156206** |

(The scatter value was recomputed from `f2dd20e4`'s own seven input files — both head
configs and the five band `vegetation.json`s — with the exact mixing loop from
`scatter_bake.gd`, LF and CRLF.) So `f2dd20e4` did not clobber anything: it committed a
correct bake's manifest from a platform whose fingerprint disagrees with Linux CI's. Any
future Windows bake — the owner's machine is the one with the GPU — would do the same, and
the repository has no `.gitattributes` pinning these files to LF. That is the actual defect,
and it is what this lane fixed.

## What changed

| File | Change |
|---|---|
| `scripts/world/terrain_bake.gd` | `config_fingerprint()` hashes `normalised_text()` — the file text with every `\r\n` folded to `\n`. New `static func normalised_text()`, the one place the line-ending rule lives. An LF file hashes exactly as before: the committed manifest's 1823724492 is unchanged and the guard passes on the untouched bake. |
| `scripts/world/scatter_bake.gd` | the per-file hash in `config_fingerprint()` goes through `TERRAIN_BAKE.normalised_text()` (new `preload` of `terrain_bake.gd`). LF value unchanged: 7496100143687718, guard passes on the untouched scatter bake. |
| `tests/test_terrain_bake_freshness.gd` | new `test_fingerprint_ignores_crlf_line_endings`: rewrites the real config with CRLF, takes the fingerprint, restores the original bytes (asserted), asserts the number did not move. Same write-the-real-file pattern as the file's existing perturbation test, for the same reason. |
| `tests/test_scatter_fingerprint_covers_bands.gd` | new `test_the_fingerprint_ignores_crlf_line_endings`, same shape, on `data/config/vegetation.json`. |
| `tools/_probe_n11_terrain_dir_diff.gd` (+ `.uid`) | new: decodes every `terrain3d*.res` in two data directories and compares `height_range`, `height_map`, `control_map`, `color_map` pixel by pixel — `_probe_ow5b_region_content_diff.gd`'s comparison, whole-bake, one Godot launch. Exit 0 only when every region present on either side is identical; prints one line per region. |
| `docs/CURRENT_STATE.md` | one §1 bullet recording the verdict and the cause, next to the "repaired, not re-baked" bullet it answers. |
| `ralph/reports/N11-TERRAIN-BAKE-0905/REPORT.md` | this report |

**Deliberately not changed: `data/terrain/playground/*.res` and its `manifest.json`.**
The re-bake's 64 region files are all byte-different from the committed ones and all
decode identical; Terrain3D's serialization is not byte-reproducible run to run
(`tools/verify_incremental_bake_identity.sh` documents the ZSTD frame divergence, and this
run shows it again: `terrain3d-01-01.res` 377,481 → 377,440 bytes, zero pixels changed).
Committing them would be 24 MB of churn carrying no information. The bake's own
`manifest.json` is byte-identical to the committed one (`cmp` clean), so there is nothing to
install. Treating this as evidence-backed "already fresh" is what `CLAUDE.md` asks for.

Not done, and worth a separate decision: a `.gitattributes` line (`*.json text eol=lf`)
would stop CRLF reaching a Windows checkout in the first place. It changes checkout
behaviour for the owner's working copy across the whole repo, which is bigger than this
lane's remit; the code fix above makes the guard correct either way.

## Evidence (exact commands, from the repo root, `PATH=$HOME/godot-bin:$PATH`, Godot 4.7-stable installed fresh in-container, two clean import passes: rc 0, 0 `SCRIPT ERROR`/`Parse Error`/`Failed to load`)

| Step | Command | Result |
|---|---|---|
| baseline, untouched tree | `godot --headless --path . --script tests/run_tests.gd -- --only=test_terrain_bake_freshness.gd` | 3 tests / 8 assertions / 0 failed — the guard already passed on `f8a47ee4` |
| **full bake** | `godot --headless --path . --script scripts/world/build_playground_terrain.gd -- --data-dir=res://data/terrain/_n11_rebake` | rc 0; `64 of 64 regions (4x16 full-world grid) at 2.00m spacing`; `height range -26.2m .. 51.2m (relief 77.3m)`; `1.0% of the surface is steeper than 30 degrees`; manifest `{"config_fingerprint": 1823724492, "regions": 64}`; **31 min wall** (13:52:32 → 14:23:31 UTC, 4 cores, the first ~10 min shared with test runs). Engine noise: the expected `Cannot open directory` on the empty scratch dir ×2 and one `_grab_camera` line, nothing else |
| **decoded comparison** | `godot --headless --path . --script tools/_probe_n11_terrain_dir_diff.gd -- res://data/terrain/playground res://data/terrain/_n11_rebake` | rc 0; `summary: 64 identical, 0 differing, 0 missing/unloadable of 64` |
| raw bytes, for the record | `cmp` per region, both directories | 0 of 64 byte-identical; `manifest.json` byte-identical |
| probe can fail | same probe against a copy of the re-bake with `terrain3d_00_00.res` replaced by `_00_01`'s file and `terrain3d_01_14.res` deleted | rc 1; `terrain3d_00_00.res: DIFFERS -- height_range (-10.18, 26.07) vs (-11.81, 10.58), height_map 65536 px, control_map 20756 px, color_map 64669 px`; `terrain3d_01_14.res: MISSING on one side`; `62 identical, 1 differing, 1 missing` |
| guard, with the fix | `... --only=test_terrain_bake_freshness.gd` | 4 tests / 15 assertions / 0 failed |
| scatter guard file, with the fix | `... --only=test_scatter_fingerprint_covers_bands.gd` | 4 tests / 22 assertions / 0 failed |
| scatter CI job's assertion, with the fix | `... --only=test_scatter_perf_budget.gd::test_playground_bake_is_committed_and_fresh` | 1 / 1 / 0 failed |
| **new tests seen red** | the `\r\n` fold in `normalised_text()` replaced by `return text`, both files re-run, fold restored (`git diff` confirms only the intended change remains) | terrain: `1 failed — expected 1823724492, got 4395215917`; scatter: `1 failed — expected 7496100143687718, got 3499021386830483`. Red for exactly the incident's numbers |
| terrain-adjacent unit files | `test_map_baker.gd`, `test_minimap_terrain_region.gd`, `test_scatter_perf_budget.gd`, `test_terrain_adaptation.gd` | 7/13, 5/8, 3/6, 6/9 — all 0 failed |
| runtime | `godot --headless --path . --script tests/smoke_playground.gd` | `smoke: OK`, rc 0, 2 min; the only `ERROR` lines are the known-benign `Parameter "material" is null` ×2 (`docs/AGENT_WORKFLOW.md` known-benign set, unchanged count) |

The CRLF fingerprints were first computed by a throwaway script (`text.replace("\n",
"\r\n")` through the same `hash() + path.hash()` mix) before the fix existed, then confirmed
by the new tests going red with the same numbers. Scratch directories
(`data/terrain/_n11_rebake`, `_n11_failcheck`) were deleted; `git status` shows only the
files in the table above plus the `.uid` sidecars the import generates for Cloudreach files
already on `main`, which are not committed.

## Ownership and landing notes

- `scripts/world/scatter_bake.gd` is touched for a 4-line change inside `config_fingerprint()`
  only. If a 0905 lane owns that file, the change is separable: drop it and the scatter guard
  keeps its old platform-dependent behaviour, with the terrain guard fixed alone.
- No bake input (`terrain_playground.json`, `vegetation.json`, band files) was edited, so
  neither committed manifest moves and both `verify-*-bake-freshness` jobs should pass on the
  first attempt on this branch; a retry rescue would be a finding.
- Decision numbers: none taken. Nothing here is a design decision.
- CI on this branch was not observed from the container (`gh` is not installed and
  `api.github.com` is not reachable through the proxy); the landing lane should read the run.
