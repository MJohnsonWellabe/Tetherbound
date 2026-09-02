# START D2 — Quarry / Burrow Warrens

**Branch:** `ralph/gate-d-band2-quarry-warrens`
**Band directory:** `data/config/bands/band2_stone_and_root/` — yours whole
**Also yours:** `data/config/old_quarry.json`, `data/config/burrow_warrens.json`
**Reserved `order` range:** 2000–2999
**Owning prompt:** `docs/ralph-prompts/63-BAND2-finished-quarry-warrens.md`
**Spine:** z 1360 → 3180, ~1820 m. Old Quarry, Burrow Warrens, ridge trails,
deeper oak forest, abandoned ranger camp.

Read `ralph/lanes/COMMON.md` first, then `ralph/GATE_D_LANE_CONTRACT.md`, then
your prompt, then `ralph/DONE.md`'s BAND2 entries.

The player enters by crossing South Bridge and leaves with a handoff toward the
river. The region's question: **what do I gain by exploring dangerous places
instead of just following the road?** Prompt 63's definition of done: *the
player leaves Band 2 thinking — going off the easy path made my team and
preparation better, and now I know something larger is happening.*

## Already done on this branch — do not redo it

Branch head `ceb51cd`, full suite verified green just before push: **1301 tests,
715102 assertions, 0 failed.**

- **Density**: 6 clusters / 9 creatures → **56 clusters / 195 creatures** across
  1820 m, inside the owner's 45–60 / 170–260 target. **Density is done.**
  Non-uniform by zone — ~80 m spacing on worked quarry stone, ~30 m around the
  Warrens mouth, ~35–45 m elsewhere, about a third of clusters off-road.
- **Species variety**: five (burrowback, mudsnout, trailpup, meadowhart,
  duskhush), recorded as a deliberate decision in a `spawns.json` comment after
  the coordinator questioned it.
- **Special encounter**: a level-13 Terrapup in the Warrens' optional vault
  chamber beside the heartstone — a species that spawns wild nowhere else in the
  game.
- **Team Tether evidence**: new `quarry_supply_cache` prop cluster at the
  `ranger_camp_spur` loop, delivering on that loop's own long-standing `_why`
  text in `terrain_playground.json`.
- **Camp/rest siting**: clearing, wood/fiber node, and a map landmark pin (the
  previously-unused `camp` icon) at `ranger_camp`.
- **Third picket** `band2_outrider_kest` (order 2002) with matching dialogue in
  `data/dialogue/bands/band2_stone_and_root.json`, added after the coordinator
  questioned two pickets over 1820 m against prompt 59's *"no major region is
  simply wild traversal followed by one boss."*
- **Rootstone comprehension verified, not asserted**, via a new tool
  `tools/_probe_band2_cadence.py`: every rootstone recipe is craftable off the
  first quarry visit alone. Same tool measures cadence — longest gap **75 m**,
  one beat every ~22 m.
- `tests/test_band_vegetation.gd`'s exact-count assertion loosened to `>=`.
  Correct, and the coordinator accepted it; D1 and D4 hit the identical false
  failure independently and the coordinator collapses the overlap at
  integration. **Leave it.**

## Settled decisions — do not reopen without new evidence

**The band's required fight is the Warrens guardian, not a trainer battle.**
`trainers.json`'s own `_comment_why_this_band_had_none` explains that neither
`docs/MEADOWS_PROGRESSION_SPEC.md` §3 nor `docs/MEADOWS_MACRO_LAYOUT.md` names a
Band 2 trainer and that the macro-layout doc calls this band's human occupation
abandoned. The third picket was added to satisfy prompt 59's ladder without
overturning that reasoning. Extend it if you must; do not reverse it.

## What is left

1. **A real blind visual pass.** The only round so far was self-rendered and
   self-judged with `tools/capture_band2_63.gd` (it did fix the toppled-crate
   silhouette), and that is explicitly not a blind pass — `ralph/conventions.md`
   forbids grading your own frames, and on this run two lanes did it and both
   were contradicted by an independent critic in the parts that mattered.
   Produce clean captures of the new `quarry_supply_cache` cluster and the
   `ranger_camp` camp siting, then **ask the coordinator to dispatch the
   independent critic**. Do not judge them yourself.
2. **Warrens dungeon quality against prompt 63.** Verify on the current branch,
   reproduce-first, before changing anything: readable chamber navigation, a
   guardian that is memorable rather than "standard fight plus HP", the optional
   harder branch and its rare reward, and visible evidence Team Tether has been
   moving material through. `data/config/burrow_warrens.json` and
   `tests/smoke_warrens.gd` already exist.
3. **The Mudsnout → Tuskroot lead.** `chapter_curve.json` records the gate
   (level 15 + bond 55 + heartstone) as decided in this region even though it
   fires later. Confirm that lead is legible to a player here. Do not change the
   evolution rules.
4. **A driven run** — `tests/smoke_warrens.gd` plus `tests/smoke_traversal.gd`,
   or extend your own probe. You have cadence numbers from the analytical probe;
   what is still missing is the played evidence: dungeon duration and
   readability, and whether the region's objective is legible while playing it.

## Known remainders recorded by the previous round

- The new vegetation clearing at `ranger_camp` **will not take effect in the
  live scatter until the coordinator re-bakes** — the inherited fingerprint
  defect in `COMMON.md` §4. Not yours to fix.
- `Rope_1` in the supply-cache cluster is illegible at normal camera distance
  under software rendering — the same pre-existing limitation the shipped
  `ranger_camp` cluster's own rope has. Not chased further.
- **No `density_scale` request.** The owner's directive was about authored
  creature count, not scatter foliage, and nothing in the driven run pointed at
  vegetation as bare. Revisit only if the blind pass says otherwise — and
  report it, do not edit the shared file.

## Trap that cost another lane real work

**Do not author a wild Tuskroot.** It is Mudsnout's evolved form behind the
Heartstone bond gate and `test_no_evolved_form_spawns_wild` will refuse it. D4
built a special encounter around one and had to rebuild it.
