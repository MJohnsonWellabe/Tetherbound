# Second-pass backlog

**Created 2026-09-07** under
`docs/owner/OWNER_DIRECTIVE_2026-09-07_PLAYABLE_FIRST.md`. This run targets the
**playable four-biome build**; everything deferred to reach it lands here.

**The rule: a deferral that is not written here is a defect, not a shortcut.** Append a
row the moment something is deferred — not at the end of the run, not "when there's
time". This file is the entire justification for going fast, and it is the input to the
second pass.

## How to add a row

| Item | Criterion | Why deferred | Evidence that exists |
|---|---|---|---|

- **Item** — what was skipped, specifically enough to pick up cold.
- **Criterion** — which exit criterion it belongs to, by document and number
  (e.g. `Stormwood §32 #14`, `Water §21 (17)`), so the second pass can close it against
  the real bar.
- **Why deferred** — one line. "Needs art that does not exist" and "judge failed once,
  one-round rule applied" are both fine. "Ran out of time" is fine too, if it is true.
- **Evidence that exists** — the render, verdict, probe or report already committed, so
  the second pass does not redo the diagnosis. Path under `ralph/reports/` or `docs/`.

## Known deferrals carried in from before this directive

These were already deferred or open when the directive was written, and belong to the
second pass unless they start blocking the playable path.

| Item | Criterion | Why deferred | Evidence that exists |
|---|---|---|---|
| Every biome fails its blind visual bars; no biome has ever passed both | Stormwood §32 #14, Water §21 (17), Cloudreach and Meadows equivalents | Requires art and lighting work beyond the playable bar | `ralph/reports/JUDGE-OWNER-RUN-20260907/VERDICT.md`, `ralph/reports/STORMWOOD-PROGRESS/crown-visual-judge-0907.md`, `ralph/reports/CLOUDREACH-*/JUDGE-*.md` |
| Six of nine authored stands under 8 fps on the Ally with grass on | Stormwood §32 #15, Water §21 (17) | Owner deferred deep performance work; cheap wins only | `docs/PERF_ALLY_FIRST_MEASUREMENT_2026-09-07.md` |
| Texture import: 497 of 610 measured texture sidecars were Lossless rather than VRAM-compressed | performance / build size | The cheap import-policy migration and measured pack reduction are complete; its before/after visual comparison is deferred because build size is not on the playable path | `ralph/reports/FOUR-BIOME-BUILD/build-size/REPORT.md` (1,133,890,456-byte baseline; 948,965,872-byte result; 16.31% reduction) |
| The cast reads as "three incompatible languages" — raptor, deer, trainer/villager split | art coherence | Needs meshes; the authorised pilot covers one subject only | `ralph/reports/JUDGE-OWNER-RUN-20260907/VERDICT.md`, `ralph/reports/WARRENS-ART-0906/JUDGE-round2.md` |
| Cloudreach stand `05-upper-cloudreach-cliffhold` ground reads flat green | Cloudreach acceptance; owner grass invariant | Nine causes already ruled out; needs a further probe round | `docs/HANDOFF_GRASS_AND_ART_LANES_2026-09-06.md` §3 |
| Cloudreach Phase A visual audit document never written | `docs/owner/CLOUDREACH_VISUAL_AUDIT_AND_SWEEP_GOAL_2026-09-06.md` | Audit-first process, deferred with the rest of the visual work | that goal document |
| Meadows visual sweep: grass, trees, Sakura accent, village, Warrens hero pass, stronghold | `docs/owner/MEADOWS_VISUAL_SWEEP_GOAL_2026-09-06.md` | Deferred visual work | that goal document; the 0906 lane reports |
| Warrens interior geometry reads as "hard 90° extruded prisms" | Meadows visual | Needs an organic tunnel kit — owner budget decision | `ralph/reports/WARRENS-ART-0906/REPORT.md` |
| Tether machine silhouette unreadable; established as a lighting/staging failure | Meadows visual | Three albedo grades exhausted the cheap lever | `ralph/reports/TETHER-MACHINE-0906/JUDGE-machine-round3.md` |
| HUD compass shelved; minimap restored after the corrupt second map open | HUD quality | Two attempts failed, rollback taken per the two-no-yield rule | `docs/CODEX_EXIT_HANDOFF_2026-09-07.md`, PR #80 |
| Stormwood: 57 of ≥160 dialogue nodes, 8 of 12 recipes, 461 placeholder replacement points | Stormwood §32 #7 | Content floor applies this run, not the §13 target | `ralph/reports/STORMWOOD-PROGRESS/census-and-placeholders-0907.md` |
| Water: 0 of 6 side chains, 12 of 28–32 objectives, 0 of 3 settlements accepted | Water §21 (7) | Content floor applies this run | `ralph/reports/WATER-PROGRESS/EXIT-HANDOFF-2026-09-07.md` |
| Multiplayer: four-peer finale, reconnect stress, separated-island proofs | Water §21 (15), Stormwood MP | Solo is this run's bar; MP must not corrupt state, but is not proven to depth | `docs/acceptance/MULTIPLAYER_ACCEPTANCE.md` known-open list |
| Multiplayer owner evidence: outside tester hosting three joiners, owner LAN session | `docs/DEVELOPMENT_ROADMAP.md` Stage 0 exit | Owner-only; no automated evidence can satisfy it | `docs/owner/STAGE_B_HANDOFF_2026-09-06.md` |
| Combat depth ladder: COMBAT-3, 4 and 6 | `docs/specs/COMBAT_DEPTH_PLAN.md` | Blocked on owner decisions (dodge verb, Y slot, type chart) | `docs/prompts/76-CODEX-combat-depth-performance-and-visual-bar.md` §5 |
| Gate F chain S03 onward refused by the harness budget guard at 0.049 s/frame | evidence pipeline | Fits only if the frame rate roughly doubles | `ralph/reports/OWNER-KICKOFF-20260907T023802Z/` |
| Full-checkout Gate F route-row evidence check fails: S04 requires 420 rows against shortest healthy 363; S05 requires 970 against 500 | Gate F recorder completeness / `test_gate_f_harness_predicates::test_the_route_row_thresholds_leave_headroom_below_the_shortest_run` | Owner's 2026-09-08 interruption prioritizes repairing main CI before continuing the campaign. Revisit with actual recorder evidence; no row threshold, 85% predicate or input telemetry was changed. CI's existing sparse checkout lacks these reports and is not proof of this check. | `%TEMP%/wave0-full-units-20260908-stdout.log`; `ralph/reports/FOUR-BIOME-BUILD/MAIN-GREEN-20260908.md` |
| Windows full-suite Gate F lane declaration cannot spawn `bash`; test then parses an absent metadata file | Gate F evidence-lane declaration / `test_gate_f_rig::test_the_runner_declares_its_own_logic_lane_so_a_run_can_start` | Repair the local shell dependency/runner before local Gate F acceptance; main CI runs this on Linux. No skip or softened assertion added, and local full suite is not claimed green. | `%TEMP%/wave0-full-units-20260908-stdout.log` records OS.execute exit -1 and subsequent Nil-to-Dictionary error; `ralph/reports/FOUR-BIOME-BUILD/MAIN-GREEN-20260908.md` |

## Deferred during this run

Append below. Newest last.

| Item | Criterion | Why deferred | Evidence that exists |
|---|---|---|---|
| Map drawing repair's code-blind recording verdict is outstanding, not passed | CLAUDE visual workflow; map interface legibility | Isolated and full-world real-menu frames are available, but the current agent tree rejected two fresh zero-context critics at its thread limit; retain this required review for the next available fresh critic, not an informed substitute | `ralph/reports/FOUR-BIOME-BUILD/MAP-UI-CAPTURE-20260908.md`; 29 map tests/95 assertions pass; full-world controller open/close/reopen exits0 with no native errors, see `MAP-WORLD-REOPEN-20260908.md`. Pixels remain unjudged; corruption is not declared visually closed. |
| BUILD-SIZE Compatibility-render A/B of the compressed creature roster and character select, plus any restoration of visibly damaged textures | performance / build size visual-safety gate | Download size is explicitly second-pass work; the playable-path lanes take write/render priority | `ralph/reports/FOUR-BIOME-BUILD/build-size/REPORT.md`; exact comparison trees were preserved at `C:\Projects\Tetherbound-buildsize-before` and `C:\Projects\Tetherbound-buildsize-after` |
| Full split-realm host-shell/crossing liveness proof beyond the solo path | multiplayer realm-transition reliability | The playable-first directive makes solo the bar and defers broad multiplayer proofs; telemetry isolated an unfinished Cloudreach route-build coroutine instead of a save/state-corruption defect | `ralph/reports/FOUR-BIOME-BUILD/split-realm-freeze/REPORT.md` |
| Livewire's full two-peer remote Stormwood cooldown smoke | Stormwood multiplayer / Spark and Livewire authority | The implementation remains host-resolved and its focused cooldown contract passes, but the local two-peer run reached its 300-second step deadline while both cold Stormwood worlds were still starting; it stopped before the new readiness checks ran. Solo path proof remains blocking; CI owns the next connected verdict. | `ralph/reports/FOUR-BIOME-BUILD/livewire-authority/REPORT.md`; `.artifacts/livewire-smoke-net-stormwood-hosted-trainers.log` |
| ROAD creature presentation polish in all four biomes: separate repeated bodies instead of piles; keep large foreground bodies inside frame; restore individual silhouette/material definition, especially the Band-4 Galecrest wall (`b01_s03`), Windscar Cloudfang crop (`b02_s02`), and Tidal Cradle teal-shellback heap (`b04_s01`) | Prompt 78 Phase 4 scene/creature presentation; four-biome blind visual bars | One code-blind recording round rejected all four biomes. The 12 representative frames each contained at least two forward/framed creatures, but later live Tidewake footing failures reopened continuous functional coverage (see CURRENT_STATE). Only composition and cast-coherence polish are deferred here, not playable-path spawn failures. This scene verdict does not consume Galecrest's two remaining subject-specific mesh rounds. | `ralph/reports/FOUR-BIOME-BUILD/road-visual-creatures/BLIND-JUDGE-final.md`; final frames and manifest under `ralph/reports/FOUR-BIOME-BUILD/road-visual-creatures/captures-final/` |
| Full geological route shoulders, landmark dressing, procedural cover and post-build look dressing in Cloudreach multiplayer shells and live-session crossings | Cloudreach visual acceptance; multiplayer realm-transition presentation | Solo keeps the complete authored Cloudreach presentation. A sliced multiplayer build instead retains authored visible/colliding route ribbons, landing crowns, bridges, regions and encounters. Its settlement, observatory and two differently sloped Waterward crowns now use the full build's exact collision footprints; only geological/dressing passes are omitted. Re-enabling the complete live visual tree measured 83 seconds to reach the gameplay mount and then exceeded the unchanged 15-second heartbeat, so this is recorded visual second-pass work rather than a hidden traversal change. | `ralph/reports/FOUR-BIOME-BUILD/split-realm-freeze/REPORT.md` |
| Water road-creature composition and palette cohesion after the namespaced colourway repair: untangle the teal `b04_s01` group, separate `b04_s02` silhouettes, and refine neon colours into coherent material families while preserving the passing oversized scale | Prompt 78 Phase 4 scene/creature presentation; Water blind visual bar | One permitted code-blind cosmetic round still failed visibility, readability, palette appeal, and the Palworld-quality bar; scale/substance passed. The playable runtime contract remains three creatures at each Water station, so further composition and palette tuning belongs to second pass. | `ralph/reports/FOUR-BIOME-BUILD/road-visual-creatures/REPORT.md`; `ralph/reports/FOUR-BIOME-BUILD/road-visual-creatures/captures-water-colourway-20260907T2141/` |
| Ordinary Water-to-Stormwood return gate and authored Stormwood return arrival | Four-biome navigation completeness after Water entry | The forward fresh-save playable target ends in Water, and Settings travel already reaches every region for testing. Water's `return_to_stormwood` metadata has no mounted RealmGate and Stormwood has no matching Water return anchor, so ordinary backtracking after Water is explicitly deferred instead of being mistaken for a finished connection. | Static route audit against `data/config/water_world.json`, `scripts/world/water_world.gd`, and `data/config/stormwood_world.json`; checkpoint 7 in `ralph/reports/FOUR-BIOME-BUILD/checkpoints.md` |
| Stormwood Crown objective guidance and completion semantics: guidance names the Capacitor guardian but the glass objective does not require its clear fact; one three-glass harvest completes that objective although the arch needs six | Stormwood Act-II progression contract, `data/config/stormwood_chapter.json` objectives `stormwood_crown_glass_gathered` and `stormwood_crown_arch_built` | These do not waive the actual six-glass construction cost or prevent progression. Guidance/prerequisite reconciliation is deferred; the named encounter's presence and fightability, real material payment, and physical chapter completion remain blocking and are not deferred. | Source audit in `ralph/reports/FOUR-BIOME-BUILD/STORMWOOD-CROWN-NEXT.md`; root independently inspected `stormwood_harvest_runtime.gd`'s one-receipt event and `stormwood_harvest_rules.gd`'s region gates. The planned continuous segment requires the guardian and all six glass; it is not yet runtime proof. |
