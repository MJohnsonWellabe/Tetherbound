# CURRENT_STATE history — moved 2026-09-07

Moved verbatim from `docs/CURRENT_STATE.md` when that file was slimmed to the live
status. History only; nothing here routes current work. See `docs/CURRENT_STATE.md`.

## 1. Git truth

- `origin/main` is `2cd711eb` as of 2026-09-05 08:25 UTC (it was `cf535cce` when this
  section was first written). All five remaining remote branches
  (`claude/backlog-coordinator-setup-3y0jr4`, `claude/coordination-subagents-3fhz1x`,
  `ralph/CONSOLIDATE-0902-EVENING`, `ralph/GATE-F-S03-CATCH-LOOP`,
  `ralph/OWNER-0901-CREATURE-GRASS-VISIBILITY-V2`) are 0 commits ahead of `main`:
  **nothing meaningful is stranded off `main`.** They can be deleted from GitHub.
- No stashes, no worktrees, no uncommitted work at session start.
- The last two CI runs on `main` that executed code jobs were green (fdc34025, 50 min;
  d0906654, 37 min). Five of the day's earlier `main` runs concluded *failure* and were
  papered over by later docs-only pushes; see §4.
- 25 pull requests to date. PRs #20–#25 (2026-09-02) landed the visual-parity program
  and the last lanes. Before that the loop landed branches via fast-forward without PRs.

**The 2026-09-04/05 lane wave, landed by W24-LANDING** (`ralph/reports/W24-LANDING-0904/REPORT.md`
is the evidence; `archive/ralph/briefs/0904/LANES.md` is the per-lane ledger):

| PR | Merge commit | Lanes landed |
|---|---|---|
| #42 | `c5a16dfb` | W00-ICONS, plus the bake-manifest repair below |
| #45 | `fdf70ab4` | W19-CONTRACTS, W13-PROGRESSION-FEED, W04-PORTRAITS, W12-COMPANION, W18-DENSITY-B4-B5, W17-DENSITY-B2-B3, W09-VFX, W23-DIFFICULTY — one consolidated branch, one verification pass |
| #46 | `504c7b55` | this section's record of the wave (no code) |
| #48 | `2cd711eb` | W01-ROUTE-STRIP, W22-BRIDGE-SIGNPOST |
| #49 | `8e9ece36` | landing ledger through cycle 7, plus two repairs to this file (no code) |
| #50 | `590741fe` | W01's and W09's closed reports, cycle-8 ledger (no code) |
| #51 | *open* | **W20-SMALL-FIXES** |

PR #43 was opened and closed as superseded by #45. Verification on the merged tree before
#45: two imports with no `SCRIPT ERROR`/`Parse Error`; 658 tests / 3,399,284 assertions,
0 failed across every merged lane's owned tests; the progression and HUD set re-run at
158 / 2,521 after W13's round-2 UI fix; `smoke_playground` OK with all 101 band pickups
placed; `smoke_gate_b_continuous` OK. #45 merged on CI run 33949277496, green on every job.

- **The bake manifests were repaired, not re-baked.** `f2dd20e4` rewrote only the
  `config_fingerprint` line of `data/terrain/playground/manifest.json` and
  `data/scatter/playground/manifest.json` while changing no bake input, so both freshness
  guards read the committed bakes as stale and `main` went red on four jobs. #42 restores
  the two fingerprints from `90efc0d5`, which is what a re-bake against the unchanged config
  writes; both guards pass. W05-TREELINE and W18 reached the same diagnosis independently.
- **The terrain bake is verified fresh by a real bake, and the manifest clobber has a
  named cause (N11-TERRAIN-BAKE-0905, `ralph/reports/N11-TERRAIN-BAKE-0905/REPORT.md`).**
  A full 64-region `build_playground_terrain.gd` run on `f8a47ee4` decodes pixel-identical
  to the committed `data/terrain/playground` in every region (height_range, height_map,
  control_map, color_map; `tools/_probe_n11_terrain_dir_diff.gd`) and writes a byte-identical
  `manifest.json`, so the region files were left alone — PR #29's trailhead move feeds
  `signpost.gd`, not the heightfield. `f2dd20e4`'s "stale" fingerprints (4395215917 terrain,
  404295163156206 scatter) are exactly the CRLF hashes of the unchanged inputs: a Windows
  checkout under `core.autocrlf` stamps a value Linux CI rejects. Both
  `config_fingerprint()`s now fold `\r\n` to `\n` before hashing (LF values unchanged, no
  manifest moves) and each guard's test file proves the property.
- **`smoke_gate_e_finale` is flaky on `main`, not broken.** It failed four times (two `main`
  runs, a landing branch, and a locally built tree byte-identical to `origin/main`) and then
  passed on run 33949277496 for the same commit that failed on that commit's push run. The
  likely mechanism: `04d844d0` gave the Warden an automatic `victory_conversation`, and
  `sequence_director.gd` holds locomotion while a dialogue panel is open, so the smoke's
  check races the panel. `tests/smoke_gate_e_finale.gd` is W06-FINALE's file.
- **Nine decision records, uniquely numbered** after eight lanes each opened a D74:
  D74/D75 W19, D76 W13, D77 W23, D78 W18, D80 W09, D81 W04, D83 W12, D84 W17. D79 is
  reserved for W10 and D82 for W02. W22 later took D86 (PR #48); D85 is unused
  because W05 did not land, so the next free number is D87.
- **W05-TREELINE is still off `main` after two rounds, and the reason is now narrower than
  it first looked.** Its round-2 fix decouples collider growth from mesh growth and
  **passes on the lane's own base** (`ef16544f`); on **current `main`** the player instead
  penetrates the trunk at (42.33, −66.54), trips
  `player_controller.gd::_recover_if_entombed` and is teleported 116.1 m away. Both baselines
  are measured in the landing container: current `main` alone passes `smoke_aggression` (twice
  now, first attempt each time), `main` + W05 fails. Whether the cause is W05 alone or W05
  against everything that landed today is **not established**, because the lane's base is five
  hours stale. The lane is asked to rebase onto current `main` and re-run its own probe
  (`tools/_probe_walk_block_0905.gd`) and the smoke there, not to accept a verdict it cannot
  reproduce. Its decision record renumbers D74 → **D85** on the landing side.
- **Round 1, for the record: PR #47 was opened for W05-TREELINE and closed unmerged.** The walk to the wild creature stops at **53.7 m**, deterministically —
  `main` alone passes and `main` + W05 fails in the same container back to back, and both CI
  runs on the landing head agree. This is *not* the flake that smoke's own header documents:
  that one sits at 44.1 / 38.0 / 45.1 m and was traced to the `Terrain3D` node. The likely
  mechanism is the lane's own change — `trees.scale_max` goes 1.45 → 2.0 with heroes at
  2.2–2.7, and colliders scale with the mesh, so a wider trunk now sits on a line the walk
  used to clear; both bakes report an unchanged 825,979 kept / 3,883 drained, so placements
  did not move. A physics query at the frozen position will name the blocking body. The lane
  owns the fix; `ralph/LAND-0904-4` holds the prepared landing. On the same tree the
  benign-engine-error set was checked against `main` and is identical, so W05 is exonerated
  on that point.
- **Two standing owner instructions, 2026-09-05 ~09:00 UTC.** *"You need to be consolidating
  lanes so we don't have five separate CIs trying to happen at once in GitHub"* — every
  landing from here is one branch, one CI run, one PR, ledger included on the landing branch;
  two open landing PRs is a defect. And *"if there are merge conflicts with cloudreach,
  whatever it is doing should win"* — Cloudreach takes the conflicting side unconditionally.
  The second supersedes this lane's earlier flag that `04d844d0`, `3f9e1a14` and `47ca2e12`
  build Cloudreach Cliffs on `main` against CLAUDE.md's Biome 2 bar; that was raised for the
  owner and is not the landing lane's to act on.
- **W20-SMALL-FIXES verified on the merged tree** (PR #51): its six named test files all
  0-failed, two of them exercising *more* than the lane claimed because the merged tree
  carries other lanes' data (`test_chapter_curve` 22/520 against its 20/465,
  `test_band_content` 6/1,339 against its 6/1,147); `smoke_relay_station`, `smoke_playground`
  and `smoke_aggression` all exit 0. Its `docs/acceptance/MEADOWS_EXIT_CRITERION.md` edit
  corrects B2's three-passes-stale 1.08:1 to a measured 1.618:1 and marks B4 **half** closed
  (contact shadows done, embedded-on-slope still open) rather than closing it.
- **Still off `main` from that wave:** W05 (see below) and W10 (its
  report is a seven-line skeleton with an unfilled placeholder and no test results);
  W02, W03, W06, W07, W08, W11, W14, W15, W16 and W21 have pushed no report of their own —
  W07 has judge sheets but no `REPORT.md`. The wave resumed at 08:39 after a five-hour
  silence and lanes are still pushing.
  W17 and W23 were independently re-verified by the landing lane before landing; W05's
  re-bake and its `vegetation.json` edit will need the bake-freshness pair re-run on
  whatever tree eventually lands it.
- **A capture-tooling defect two lanes have now paid for.** Independent code-blind judges,
  on W05 and on W22, flagged `place5-bridge-approach` (and W05's judge also `place2-the-rise`)
  as shot from a camera at roughly 1.05 m with no player figure in frame, rather than the
  game's ~2.8 m third-person rig — half the frame is out-of-focus dirt, and neither round
  could use it as evidence. That is one fix in `tools/_capture_band1_places.gd`'s viewpoint
  list, and it belongs to whoever owns that file. The same judges note the studio turntable
  rows have no figure either, so board 18's 2–2.5 m signpost and 1–1.2 m rail heights cannot
  be checked; putting the 1.80 m trainer in those shots makes both checkable in one pass.
