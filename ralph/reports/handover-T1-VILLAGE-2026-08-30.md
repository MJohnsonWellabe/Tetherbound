# Handover — T1-VILLAGE — 2026-08-30

**Branch:** `ralph/T1-VILLAGE`, off `origin/main` at `a97f3e84`.
**HEAD at handover time:** `620b9232` (pushed to `origin/ralph/T1-VILLAGE`,
confirmed with `git rev-parse HEAD` == `git rev-parse origin/ralph/T1-VILLAGE`
immediately before writing this file). Working tree clean.

```
620b9232 T1-VILLAGE: differentiate the inn from Grandpa's house, ground the inn's footprint
a97f3e84 <- main at branch time>
```

One commit, 289 files (3 source configs, 1 tool, 11 terrain region `.res`
files, 256 scatter `.bin` files + `manifest.json`, 18 PNG frames).

## What I was asked to do

`docs/owner-direction/TETHERBOUND_VISUAL_STUNNING_PASS.md` §6 (Grandpa's
property and the village), §16 (architecture polish, naming Grandpa's house
and the village tournament area as priorities), §5 (paths), §12 (sightlines),
plus the standing bar: the Burrow Warrens interior
(`scripts/world/interior_structure.gd`), which the owner named GOOD and the
judge called "the only architecture subject where material, value structure
and story agree." The village had never once been put in front of a blind
judge — getting it there was named as one of this lane's real deliverables.

## Where I actually got to

### DONE and verified

1. **The inn was a byte-identical twin of Grandpa's farmhouse.**
   `data/config/building_prefabs.json`'s `inn` and `farmhouse_shell` recipes
   had *identical* module histograms — same 74-module wall/window/roof
   layout — differing only by a door leaf, one extra chimney and a few
   retints (a prior partial fix, HIST-164, landed before I started; it
   changed colour, not massing or fenestration). Two independent reports
   (HIST-164's own probe tool comment, `VISUAL_LOCATIONS_2026-08-23.md`)
   named this exact pair "visible twins... standing side by side in ONE
   frame." Fixed by changing the ground-floor front elevation itself:

   - The `+2` ground-floor panel, previously a blank `Wall_UnevenBrick_Straight`
     (identical to farmhouse's), is now a window matching the `-2` panel
     (`Wall_UnevenBrick_Window_Wide_Flat` + `Window_Wide_Flat1` +
     `WindowShutters_Wide_Flat_Open`). Farmhouse keeps window+door+blank-wall
     (correct for a private home); the inn is now window+door+window
     (reads as a place strangers walk into).
   - A small entry canopy (`Overhang_Roof_Plaster`) on a support beam
     (`Roof_FrontSupports`) over the door — a public threshold marker a
     private house does not have.
   - **No new mesh.** Both added modules are already installed in
     `assets/buildings/quaternius_medieval/` and were unused by every other
     recipe in the file — measured with `tools/_probe_village_kit_modules.gd`
     (a pre-existing HIST-164 probe tool; I ran it, did not write it) before
     placing anything, so every coordinate is a real AABB reading, not a
     guess.
   - Iterated visually with the pre-existing `tools/_capture_village_twins.gd`
     (isolated two-prefab comparison stage) before touching the real village,
     then verified again in full world context.

2. **The inn had no worked-soil apron footprint.**
   `terrain_playground.json`'s `building_aprons.footprints` gives Grandpa's
   house, the workshop, both cottages, the well, the mill and the ranger
   station a feathered ring of worked soil in the terrain control map, so
   each building's stone border skirt meets dug ground instead of a hard
   line against lawn. The inn (added 2026-08-16, R7.9 — *after* this apron
   system was authored) never got an entry. It is the one square building
   the judge's "no ground-material response at all"
   (`JUDGE-VISUAL-2026-08-29.md` doesn't cover the village, but the same
   finding pattern is in `VISUAL_LOCATIONS_2026-08-23.md`'s "buildings and
   props sit on untouched uniform lawn" for the twins frame) can be pinned
   on with *data*, not just one frame's read. Added, following the exact
   rule every other probed building in that array already uses
   (`tools/_probe_prefabs.gd`'s combined-AABB + 0.2m margin — verified this
   is the actual rule by re-deriving it from `cottage_a`'s and `well`'s own
   entries before trusting it, since `farmhouse_shell`'s own entry does
   *not* follow this rule and is not in that probe's list — flagged below,
   not touched).

3. **Widened the inn's vegetation clearing radius, 6.5m → 7.8m**
   (`data/config/bands/band1_lower_meadows/vegetation.json`). My own canopy
   addition (item 1) pushed the inn's combined AABB out to a 7.76m
   half-diagonal (probed after the edit: local X half 4.12, Z −5.90..6.58,
   asymmetric because the canopy projects further past the door gable than
   the roof already overhung on the back eave) — past the old 5.83m-derived
   radius. Without this, a tree or rock could scatter directly under the new
   canopy. Checked and fixed *before* baking, not found by accident after.

4. **Re-baked terrain and scatter.** `build_playground_terrain.gd` (64
   regions scanned, 11 actually rewritten — all clustered near the village,
   as expected for a village-local footprint edit) and
   `bake_playground_scatter.gd` (full re-bake, 766,371 placements, all 256
   scatter regions rewritten). The scatter bake is a **single seeded
   stream** across the whole world (`scatter_bake.gd::config_fingerprint()`
   hashes `terrain_playground.json` + `vegetation.json` + every band file
   together) — one config edit anywhere shifts every downstream placement
   id, even in regions nothing visually changed in. That is why all 256
   region `.bin` files show as modified; it is expected, not a sign the bake
   touched anything it shouldn't have.

   **Coordinator flag, relayed here per its own instruction:**
   `ralph/T1-GROUND` independently re-baked scatter on its own branch today
   (259 files, now archived) — the same two-branch-rebake shape that
   produced a stale bake on yesterday's integration branch. **My bake is
   correct against this branch's own tree and does not attempt to reconcile
   with T1-GROUND's** — that is `ralph/LAND-0830`'s job. Exact inputs this
   branch's bake was triggered by, stated plainly as asked:
   - `data/config/terrain_playground.json` — `building_aprons.footprints`,
     +1 entry (the inn, item 2 above).
   - `data/config/bands/band1_lower_meadows/vegetation.json` —
     `footprints[6].radius`, 6.5 → 7.8 (item 3 above).
   - `data/terrain/playground/` — 11 `.res` region files, committed.
   - `data/scatter/playground/` — all 256 `region_*.bin` files plus
     `manifest.json`, committed in full.

5. **All relevant smoke tests green**, run after the full bake:
   `smoke_traversal` (confirms the inn's door still starts shut, blocks the
   doorway, and opens into its 31-piece room on interact — my recipe edit
   only *appended* modules after the door components, so
   `door_leaf_index` did not shift; verified rather than assumed),
   `smoke_village_trade`, `smoke_village_smith`, `smoke_village_trainer`,
   `smoke_tournament_bracket`. `test_tournament.gd` is a GUT-style script
   that errors when run directly with `--script` (not a SceneTree/MainLoop
   entry point) — pre-existing harness shape, not something this change
   touched; `smoke_tournament_bracket.gd` is the SceneTree-runnable sibling
   and passed clean.

6. **Extended `tools/_capture_locations.gd`'s village site with three new
   eyes** — `grandpa-yard`, `tournament`, `route-out` — alongside the
   existing `approach`/`standing`/`twins`. No prior survey in this repo had
   ever stood at any of these three points. Used the tool's existing
   `marker`/`look_marker` mechanism for `grandpa-yard`
   (`GrandpaHouse.marker("outside")`/`marker("door")`) rather than
   hand-transcribing coordinates, per the tool's own stated discipline.

7. **Before/after evidence committed** under
   `ralph/reports/T1-VILLAGE/shots/` (18 PNGs: 6 labels × day/night for
   `after`, plus `approach`/`standing`/`twins` × day/night for a true
   `before` — captured from a clean `git stash` of my own changes, not
   guessed at) and a contact sheet (`_sheet.png`, via
   `tools/contact_sheet.gd --dir=ralph/reports/T1-VILLAGE/shots`). **Not**
   under repo-root `/shots/` (gitignored — a prior lane lost evidence to
   exactly that).

8. **A blind Fable judge reviewed the pushed frames** — the village's first
   time in front of a blind critic, per this lane's own stated deliverable.
   [FILL IN: verdict summary — see the judge's full report, not
   paraphrased, for the actual verdict. If this line still reads as a
   placeholder, the judge run had not returned when this file was written;
   check `ralph/reports/T1-VILLAGE/` for a `JUDGE-*` file or ask the
   coordinator whether JUDGE-2 also picked up these frames independently.]

### Done but NOT independently re-verified after the fact

- The `01-village-route-out` shot (eye at the well, looking toward the pond
  route) did not achieve the framing I intended. The eye landed close
  enough to the well's own canopy structure (`_clear_of_bodies()` moved it
  2m aside from a collision) that the frame reads as "standing at the well
  looking at the workshop across the plaza" rather than "a sightline out of
  the village toward the pond valley." The frame itself is fine evidence of
  village texture (paved apron, cart, buildings) but does not answer the
  §12 sightline question I added it to answer. **Did not re-run** (another
  full ~30–70 minute world-boot-and-capture cycle for one frame's framing,
  weighed against the time already spent and flagged to me mid-session)
  — the fix is straightforward if someone wants it: move the eye a few
  metres further from the well's own footprint, e.g.
  `at: [18.0, -16.0]` instead of `[10.0, -10.0]`, before re-running
  `--only=01-village`.

## Still open — did not attempt

- **The village tournament ground reads as an empty field with a board in
  it**, not a purposeful event space. Verified in
  `01-village-tournament-day-after.png`: the bracket board itself (which I
  read in code before rendering — `scripts/world/tournament.gd` — and found
  already well-detailed: timber posts, top/bottom rails, five planks with
  seams, a mitred trim border, a real painted bracket rather than a text
  block) is barely in frame, and the ground around it is bare grass shared
  with Bryn's ordinary practice-trainer arena. I chose **not** to add
  spectator dressing (benches, hay bales, a rope perimeter) here, for two
  reasons: first, the ground is a live combat arena I do not own the
  mechanics of, and I could not verify in my remaining budget that any
  prop placement near it would stay clear of trainer-battle pathing/arena
  bounds; second, `TETHERBOUND_VISUAL_STUNNING_PASS.md` §6's own two-sided
  instruction — do not overfill, every object intentionally placed — cuts
  against guessing at dressing I could not verify was safe. If a future
  pass wants to pursue this, `tournament.json`'s `board.position` `[20,15]`
  is 9.2m from Bryn's own position and from the practice clearing's centre
  (deliberately, per the file's own comment, more than the two prompt radii
  added together) — anything placed should keep at least that same
  clearance and should be checked against whatever the trainer-battle arena
  system (`combat_arena_bounds_at()` — see `interior_structure.gd`'s header
  for the sibling concept indoors) actually reserves outdoors, which I did
  not chase down.
- **`farmhouse_shell`'s own `building_aprons` entry does not follow the
  rule every other probed building follows.** Found while deriving the
  inn's own entry (item 2 above): `farmhouse_shell` isn't in
  `tools/_probe_prefabs.gd`'s covered list, and its apron `half_extents`
  `[5.3, 3.3]` don't match `combined_aabb`+0.2m for that recipe (which I
  separately probed: local X half 4.12, Z half 5.925 → expected roughly
  `[6.1, 4.3]` after the 90° world rotation `grandpa_house.gd` applies).
  They *do* match `(wall-footprint-half + 0.3)` off the recipe's own stated
  "6m × 10m" dimension, so it reads as a value hand-derived from an older
  version of the recipe (possibly the pre-EV6 primitive-box shell) rather
  than the current kit-built one, never updated when the shell was rebuilt.
  **Did not touch it** — Grandpa's house already reads well in every frame
  I captured (see `grandpa-yard-day-after.png`: worn path, pebbles, ivy,
  believable grounding), so this is a latent inconsistency rather than a
  visible defect, and re-deriving and changing a load-bearing apron entry
  for the single most-seen building in the game felt like it needed either
  more render-verification time than I had left, or a second pair of eyes.
  Flagging it precisely so nobody has to re-derive this arithmetic from
  scratch.
- **§12 sightlines toward Creek Hollow / South Bridge / Lower Meadows**,
  beyond the `route-out` attempt above. South Bridge sits at world
  `(0, 1330)` — roughly 1,340m from the village square — so a literal
  sightline to the structure itself is not physically meaningful at this
  world's scale; the honest form of "a composed view toward the route" is
  the road/signpost system already in place (the well already carries a
  signpost cluster the 2026-08-23 judge round independently praised as
  "authored" — I verified it is still there and unchanged in
  `01-village-standing-day-after.png`, left it alone). I did not attempt
  new terrain-scale composition work toward these regions; that is squarely
  `terrain_playground.json`'s global spoke/road system, which
  `T1-GROUND` owns.
- **Ranger station / cottage_b visual near-twin** (`VISUAL_LOCATIONS
  2026-08-23`: "the ranger station IS `cottage_b`... same footprint, door,
  windows, chimney"). Read the code, confirmed it's real, did **not** fix
  it. The ranger station is placed on the pond-crossing group
  (`village.json`, at `[-350, 507]`, ~530m from the square) rather than in
  the village square itself — arguably outside "the village and its
  immediate approach" as scoped to me, and I did not want to spend the
  remaining time on a second twin-differentiation pass without being sure
  it was in scope. Noted for whichever lane owns that site.
- **Mill has no wheel module** (`VISUAL_LOCATIONS_2026-08-23`, confirmed
  again by me reading `building_prefabs.json`'s `mill` recipe: 78 modules,
  every one wall/roof/window/corner/border/fence, no wheel). Same
  reasoning as the ranger station — the mill/footbridge/ranger group is
  530m from the square on its own relocated site, not the village proper,
  and fixing a missing hero prop is a different kind of task (needs either
  a new mesh — against canon without owner reference art — or a kit-module
  substitute I did not have time to design and verify) than the
  architecture-polish pass I was asked for.

## What I learned that is NOT visible in the diff

- **The apron-footprint rule is inconsistently applied across the existing
  file**, and the inconsistency predates this pass (see `farmhouse_shell`
  above). Anyone adding a new building_apron entry should re-derive it from
  `tools/_probe_prefabs.gd` (or a one-off variant, as I did for `inn`/
  `farmhouse_shell` — the tool doesn't cover either name) rather than
  eyeballing a footprint dimension from the recipe's own doc comment.
- **A prior lane (HIST-164) had already partially fixed the twins problem**
  (second chimney, retint) but never rendered it — no committed evidence
  exists under `shots/hist-164/` from before this pass, so nobody had
  actually looked at whether the partial fix was enough. It wasn't (see
  `twins-front-before.png`/`twins-threequarter-before.png`, both freshly
  captured *with* the HIST-164 chimney/retint change already live, since I
  edited the recipe before checking whether an isolated stage capture had
  ever been run — the two chimneys are real in that "before" frame, and
  the buildings still read as twins because massing and fenestration were
  untouched). This is itself worth recording: a code-level partial fix
  without a render is very easy to believe finished when it isn't.
- **The village square's paths/roads system is in decent shape already.**
  `terrain_playground.json`'s `paths.routes` fan out from the well (Grandpa's
  House / Practice Meadow / The Pond), each one baked into the terrain
  control map with an authored, irregular, feathered path texture — visible
  and legible in `01-village-approach-day-after.png` (worn dirt, pebble
  scatter, fence-lined). I did not need to author new paths; the gap was
  specifically the *inn's own* missing footprint, not the path network.
- **The well/square plaza itself already carries a signpost cluster and a
  paved apron** — the one frame the 2026-08-23 judge round called out as
  "the one frame here with real charm... this is authored" is still intact
  and, from what I can see in this pass's frames, unregressed.
- **Rendering here is genuinely slow.** Each full world-boot + settle +
  6-shot capture cycle under llvmpipe (Compatibility renderer, software
  rasterisation) ran 55–70+ minutes wall-clock on this box, well past the
  12–25 minute range the brief estimated. Two such cycles (before, after)
  plus a terrain bake (~10 min) plus a scatter bake (~5 min) plus
  smoke_traversal (~13 min) filled most of this session's wall-clock time.
  Budget for that if picking this branch back up.

## Disagreements / things worth a second look

- I chose the "add a window + canopy" differentiation over other candidate
  fixes (a roof dormer on the front slope, an exterior stair to a second
  storey) that `tools/_probe_village_kit_modules.gd` was explicitly written
  to support. The dormer in particular would have hit the roofline
  silhouette — the loudest read at distance per the visual-judge rubric's
  own §1 — harder than a ground-floor window swap does. I did not attempt
  it because the roof's own local geometry (which axis the ridge runs
  along, exactly where the slope plane sits) was not something I could
  derive with confidence from the AABB probe alone, and getting it wrong
  would have meant a floating or clipped dormer in the shipped build. If
  the judge verdict below says the twins fix did not go far enough at
  distance, the dormer is the next lever, and it needs either an in-editor
  look at the roof mesh or an iterate-by-render loop I did not have budget
  left for.
- I did not attempt any UI, lighting, weather, or global-terrain work —
  all explicitly out of my file ownership per the brief, and I stayed
  inside it throughout (touched `village.gd`'s recipe consumers, one
  terrain-apron array entry, one vegetation-clearing radius, and my own
  capture tool's shot list; nothing under `scripts/world/stronghold*.gd`,
  `landmark.gd`, `building_prefabs.json`'s castle entries, or any
  `data/config/bands/**` gameplay content).

## Full file footprint

```
data/config/bands/band1_lower_meadows/vegetation.json   (1 line: inn clearing radius)
data/config/building_prefabs.json                        (inn recipe: window swap + canopy)
data/config/terrain_playground.json                       (+1 building_apron footprint: the inn)
data/terrain/playground/*.res                              (11 files, re-baked output)
data/scatter/playground/*.bin + manifest.json              (257 files, re-baked output, full world)
tools/_capture_locations.gd                                 (+3 village capture eyes)
ralph/reports/T1-VILLAGE/shots/*.png                        (18 evidence frames + 1 contact sheet)
ralph/reports/handover-T1-VILLAGE-2026-08-30.md             (this file)
```

**Scatter-bake inputs touched, restated for the integration lane per the
coordinator's explicit ask:** `terrain_playground.json`
(`building_aprons.footprints`) and
`data/config/bands/band1_lower_meadows/vegetation.json`
(`footprints[6].radius`). Nothing else in `data/config/` or `data/scatter/`
inputs was touched by this branch.

## What I would do next

1. Read the blind judge's verdict (below, or wherever it lands if this file
   was written before the judge run returned) and act on anything concrete
   and cheap.
2. Fix the `route-out` shot's framing (see above) and re-run
   `--only=01-village` if a future session has the wall-clock budget.
3. Consider the roof-dormer differentiation for the inn if the twins fix is
   judged insufficient at distance — needs an iterate-by-render loop.
4. Decide whether the tournament ground gets spectator dressing, after
   someone who owns the combat-arena system confirms the safe clearance —
   I did not want to guess at that boundary.
5. Re-derive `farmhouse_shell`'s own `building_apron` entry against
   `combined_aabb`+0.2m and decide whether it's worth the churn to fix a
   latent inconsistency that isn't currently a visible defect.
