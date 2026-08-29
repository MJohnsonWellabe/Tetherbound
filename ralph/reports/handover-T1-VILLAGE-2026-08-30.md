# Handover — T1-VILLAGE — 2026-08-30

**Branch:** `ralph/T1-VILLAGE`, off `origin/main` at `a97f3e84`.
**HEAD at handover time:** see the final commit on this branch (pushed to
`origin/ralph/T1-VILLAGE` before this file's last update). Working tree
clean at handover.

```
<this file's own commit>  T1-VILLAGE: close the well's hollow underside, finalize handover with judge verdict
113d196a  T1-VILLAGE: handover draft + contact sheet, judge verdict pending
620b9232  T1-VILLAGE: differentiate the inn from Grandpa's house, ground the inn's footprint
a97f3e84  <- main at branch time>
```

Three commits. The first does the inn/apron work (289 files: 3 source
configs, 1 tool, 11 terrain region `.res` files, 256 scatter `.bin` files +
`manifest.json`, 18 PNG frames). The second is the handover draft + contact
sheet, written before the blind judge returned. The third is the well fix
this section describes, added **after** reading the judge's verdict below —
the judge found it, not me.

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
   Full verdict is reproduced verbatim in its own section below (not
   paraphrased, per the visual-judge skill's own rule against grading my
   own work). Summary of the two bar questions: **(A) yes, narrowly, by day
   only** — the building language, meadow palette and warm-window night
   mood are recognisably the keyart's world; what pulls against it is
   settlement dressing (worn ground, a real well shaft, smoke, clutter),
   an empty horizon with no landmark silhouette, and crushed nights — all
   named as scene-fixable, none needing new art. **(B) no** — beside the
   Palworld references this reads as a cozy village-life game, not a
   creature-adventure one, chiefly because **zero creatures appear in any
   of the 18 frames** (a finding entirely outside this lane's own
   ownership — spawns/encounters are `T3-PICKUPS`/content territory, not
   village architecture — but worth relaying loudly, because it is named
   as the single largest "lived-in" gap in the whole verdict).

9. **Acted on one of the judge's bug-class findings within the session**:
   the well (`building_prefabs.json` `well` recipe) is a hollow shell open
   through its north-south axis — the judge's crop caught the plaza paving
   visible straight through underneath the curb, "a market kiosk" rather
   than a well. Verified myself with a fast isolated four-angle probe
   before touching the real village (a scratch tool, not committed — see
   `well-{N,S,E,W,low-under}-before.png` under this report's `shots/` for
   the confirmation renders): the curb's two `Stairs_Exterior_Platform`
   copies (yaw 0/180, the original author's own `_why` calls the module
   "solid on two faces only") are mirror images across the SAME axis, not
   rotations off it, so both leave the north-south faces open — confirmed
   by rendering the east face solid and the north face a tunnel in the
   same probe pass. Fixed by adding two more copies of the same module at
   yaw 90/270 (each 2cm lower than the last, following the original pair's
   own z-fighting-avoidance stagger), which lands their solid faces
   exactly where the open ones were. Re-verified from all four cardinal
   angles plus a low three-quarter angle — solid from every angle, no
   z-fighting, no doubled top-slab artifact. `smoke_village_trade` and
   `smoke_traversal` both still green afterward (the well has no dedicated
   script and no door/interior logic; collision was already an explicit
   box in `colliders`, unaffected by the module change). Before/after
   frames for this fix are also under this report's `shots/` directory,
   named `well-*-before.png` / `well-*-after.png`.

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

**New findings from the blind judge, none touched, roughly ordered by how
squarely they sit inside this lane's own file ownership:**

- **Signpost label text overlaps its own arrow plank and is illegible** —
  "Practice Mead…" collides with its own arrow in
  `01-village-standing-day-after.png`, per the judge's zoomed crop, and
  "Grandpa's House" does the same. `scripts/world/signpost.gd` is shared
  wayfinding infrastructure used at every trailhead in the game, not
  village-specific, so I did not touch it blind — but it is squarely a
  legibility bug and the first words a player reads in the world. Whoever
  owns `signpost.gd` should look at `_add_arm()`'s label placement against
  its own arrow geometry.
- **The well's stone lid showed a dither/halftone pattern** in the judge's
  crop, separate from the hollow-underside bug I fixed (item 9 above). I
  could not reproduce this in my own isolated probe renders (see
  `well-*-after.png`) — it may be a compression artifact in the judge's
  own crop, or something that only shows under the real village's
  lighting/shadow conditions rather than my neutral test stage. Not
  independently confirmed; not touched.
- **Oxblood-adjacent roof colour on two friendly buildings.** The judge
  flagged the farmhouse's crimson roof (visible in `01-village-twins-*.png`
  and the central house in `01-village-approach-day-after.png`) as the
  closest colour in the whole survey to the oxblood the project reserves
  for Team Tether danger, and recommended shifting it toward the
  terracotta family. I did not touch `farmhouse_shell`'s retint — it
  predates this pass entirely and re-tuning it is a colour-palette call
  I'd want to render-verify rather than guess at with budget already spent.
- **Zero creatures appear in any of the 18 frames.** Named by the judge as
  the single largest "lived-in" gap, ahead of any material or lighting
  issue. This is spawn/encounter placement, not architecture — outside
  this lane's ownership (`T3-PICKUPS`/content territory) — but it's worth
  relaying with weight, since it's the top item in the judge's own ranked
  list of what separates these frames from the references.
- **The purple flower clump on Grandpa's own path**
  (`01-village-grandpa-yard-day-after.png`) is, per the judge, the single
  most saturated object in the whole survey, with petals reading larger
  than the trainer's head. I traced this as far as confirming it is NOT
  an authored prop from `band1_lower_meadows/props.json` (checked — no
  flower cluster entry near Grandpa's house coordinates), which means it
  is very likely the world-wide flower scatter layer, `T1-GROUND`'s
  ownership, not mine to retune.
- **The village tournament ground reads as an empty field with a board in
  it**, not a purposeful event space — **independently confirmed by the
  blind judge**, who additionally caught that at night the space vanishes
  entirely (no lighting on the board, no braziers) and that the two NPCs
  standing in it read as "lost, not as participants or officials." The
  bracket board itself (which I
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

1. Act on the remaining judge findings listed under "Still open" above,
   roughly in the order given.
2. Fix the `route-out` shot's framing (see above) and re-run
   `--only=01-village` if a future session has the wall-clock budget —
   ideally bundled with a re-render of the tournament/twins/grandpa-yard
   frames too, so there's a true final "after" sweep that includes the
   well fix in full-village context (my well evidence is from an isolated
   probe stage, not the real village render — verified low-risk via smoke
   tests, but never seen in situ).
3. Consider the roof-dormer differentiation for the inn if the twins fix is
   judged insufficient at distance — needs an iterate-by-render loop. The
   judge's own verdict (below) says the twins fix is real but incomplete:
   roofline silhouette is still identical between the two buildings, and
   an inn wants a distinct silhouette move (L-wing, dormer, porch roof)
   that a ground-floor window swap does not provide.
4. Decide whether the tournament ground gets spectator dressing, after
   someone who owns the combat-arena system confirms the safe clearance —
   I did not want to guess at that boundary. The judge's independent
   confirmation raises the priority of this one.
5. Re-derive `farmhouse_shell`'s own `building_apron` entry against
   `combined_aabb`+0.2m and decide whether it's worth the churn to fix a
   latent inconsistency that isn't currently a visible defect.
6. Route the "zero creatures in the village" finding to whichever lane
   owns band-1 spawns/encounters — it's the single largest gap the judge
   named, and it's entirely outside this lane's file ownership.

---

## The blind judge's full verdict, verbatim

Produced by a Fable sub-agent (model `claude-fable-5`) given the contact
sheet, all 18 individual frames, the keyart board and the five Palworld
reference frames, and the `visual-judge` skill's standing rubric — told
nothing about what changed, what this lane was, or what any developer
hoped to hear. Reproduced in full and unedited, per this project's own
"do not grade your own visual work" rule: the developer's job is to read
this and act on it, not to summarise it into agreement.

> # Visual verdict — T1-VILLAGE survey (18 frames)
>
> ## 1. Silhouette and readability at small size (contact sheet)
>
> **Day frames pass this test; night frames fail it.** At sheet scale the day village reads instantly: staggered red/orange gables against green, the trainer's teal-and-tan separates from the grass, the path draws the eye to the buildings (`01-village-approach-day-after.png` is the best composition in the set — the fence line, path curve, and three-roof stagger read as a village from a glance).
>
> Defects:
>
> - `01-village-tournament-night-after.png` — the trainer is a pure black cutout on near-black grass. At sheet size the frame contains a moon and nothing else. A player glancing at this cannot find themselves.
> - `01-village-twins-night-after.png` and `01-village-twins-night-before.png` — the bottom 40% of the frame is a featureless black wedge. The lit windows carry the frame; everything else is void.
> - `01-village-approach-night-after.png` vs `01-village-twins-night-after.png` — the night frames disagree about how dark night is. The approach frames keep a readable blue-green ambient on the meadow; the twins and tournament frames crush the same ground to black. Two frames of the same night read as different times.
> - `01-village-tournament-day-after.png` — at sheet size this frame is indistinguishable from open wilderness. Nothing in the silhouette says "village event ground" (see point 9).
>
> ## 2. Colour and value structure
>
> The day frames do read as one place — the stone/half-timber/terracotta recipe is consistent, the grass tint is consistent, and the warm lit windows at night are genuinely cozy. Real problems:
>
> - **The meadow is one value.** In `01-village-twins-day-after.png` and `01-village-tournament-day-after.png` the grass is a single saturated mid-green from the camera to the horizon, with no worn ground, no dry patches, no value modulation. The keyart's settlement panel builds its ground out of ochre dirt, olive grass, and flower drifts; the Palworld frames (`palworld-02`, `palworld-05`) alternate dirt, short turf, and flower carpet. These frames have exactly one ground material with grass on top.
> - **Oxblood caution.** The deepest red in the survey is the roof of the left "twin" farmhouse (`01-village-twins-day-after.png`) and the central house in `01-village-approach-day-after.png` — a dark crimson clearly separated from the terracotta of every other roof. If oxblood-red is reserved for Team Tether danger, the closest colour to it in the village currently sits on two friendly civilian roofs. Shift those toward the terracotta family and keep the dark red out of the settlement.
> - `01-village-grandpa-yard-day-after.png` — the purple flower cluster on the path is the most saturated object in the entire survey, more saturated than anything in the keyart palette strip, and it is a decorative doodad, not a point of interest. It outshouts the front door of the player's home.
> - `01-village-twins-day-after.png` — the right building's ground-floor and upper windows glow warm amber **in full daylight**. Lit windows at noon read as an error, and it also spends the one cue ("warm window = night coziness") the night frames rely on.
>
> ## 3. Intentionality
>
> The well square is the only area that reads authored. The rest reads placed-then-abandoned:
>
> - `01-village-twins-day-after.png` — two houses standing in unbroken chest-high hay, grass to the footings, with **no path connecting them, no yard, no fence, no woodpile, no laundry, nothing between them**. This is the frame that most reads "meshes dropped into a field." The keyart settlement panel surrounds every building with worn dirt, fences, clutter, and a shade tree.
> - `01-village-approach-day-after.png` — the fence at left starts and stops enclosing nothing, and the dead twig-saplings are scattered at even intervals across the mid-ground. The barrel/crate cluster by the trainer is good; it is nearly the only prop cluster in 18 frames.
> - No chimney smoke anywhere, no birds, no creatures, no animals — in a creature-training game, across 18 frames of its starting village, **not one creature appears**. Every Palworld reference frame has Pals in it; the keyart day/night panels put a creature at the player's side. This is the single largest "lived-in" gap and it is scene-fixable with installed meshes.
> - `01-village-tournament-day-after.png` — the boulders on the left horizon sit in a rough evenly-spaced line, and the mid-ground brush tufts repeat at similar spacing. Reads scattered, not composed.
>
> ## 4. Lighting
>
> - Day sun direction reads on the buildings (good gable shading in `01-village-standing-day-after.png`), but **the terrain is flat-lit everywhere**: the hills in `01-village-tournament-day-after.png` have no form shadow at all, just a smooth green-yellow felt.
> - `01-village-twins-day-after.png` — neither house casts a readable ground shadow; both sit slightly "pasted" on the grass. The trainer in the same frame has no visible contact shadow.
> - `01-village-standing-night-after.png` — the well and foreground stone are lit by a strong cool light with no visible source, and the stone picks up a wet plastic specular. The moon is behind cloud on the left; the light comes from the right.
> - `01-village-grandpa-yard-night-after.png` — the hard diagonal shadow across the gable is unmotivated (nothing in frame could cast it) and reads as an artefact.
> - Night moon (`01-village-twins-night-after.png`, `01-village-tournament-night-after.png`) is a uniformly blurred white disc with a hard-edged halo — reads as a sticker, not a light source; nothing on the ground is visibly moonlit from its direction.
> - Night clouds (`01-village-standing-night-after.png`) are brighter than the sky and smeared into long diagonal streaks; they read as smoke or motion blur rather than night cloud.
>
> ## 5. Horizon and depth
>
> - `01-village-tournament-day-after.png` — a **visible detail ring**: fine grass and flowers stop abruptly ~30–40 m out, beyond which the terrain is smooth untextured colour. The band cuts across the left of the frame and reads as a draw-distance seam.
> - Same frame — the mountain is a smooth low-poly blob with moss decals, far below the detail level of the foreground; it pops as a different fidelity tier. The keyart uses its mountain as a composed landmark; Palworld (`palworld-04`) puts a readable tower silhouette on the horizon. This survey's horizon contains nothing to walk toward — no mill, no tower, no stronghold silhouette, though the keyart's settlement panels show exactly those.
> - `01-village-approach-day-after.png` — the right-hand distant tree line is a uniform strip of identical-height, identical-tint trees; reads as a hedge texture, not a forest edge.
> - Day frames have almost no aerial perspective; distance is the same saturation as foreground. The keyart hazes its distance blue-green.
>
> ## 6. Artefacts
>
> - **The well is a hollow shell** (`01-village-route-out-day-after.png`, confirmed in crop): it has no shaft, no hole, no rope, no winch. It is a flat slab lid on a three-sided brick skirt, **open underneath — you can see the plaza paving continue under it through the open side**. The bucket sits on the closed lid. The village's central landmark reads as an unfinished market counter under a bus-shelter roof. The keyart settlement panel's well (shingled roof, visible shaft, winch) is the target and this is not it.
> - The well lid in the same crop shows a **dither/halftone screen pattern** on the grey top surface — reads as transparency dithering, i.e. a rendering bug visible at conversational distance.
> - **The inn's ground-floor bay reads as a hole in the building.** In `01-village-standing-day-after.png` and `01-village-route-out-day-after.png` the open-shuttered opening left of the door has near-black backing and a dark recessed band running under the window row; at night (`01-village-route-out-night-after.png`, confirmed in crop) the entire bay is a black cavity with no interior, no counter, no light — while the windows either side glow warm. It reads as missing wall geometry. Note: `01-village-standing-day-before.png` shows the same wall intact (door + window + vine), so whichever state is intended, the open-bay version is the one that reads broken.
> - **Signpost labels are debug UI in the world** (`01-village-standing-day-after.png`, confirmed in crop): flat cream rectangles, default bold sans-serif, floating off the post — and the second label ("Practice Mead…") **renders on top of its own arrow plank and is illegible**. "Grandpa's House" also collides with its arrow. These are the first words a player reads in the world.
> - `01-village-approach-day-after.png` — the large tree at left has hard-edged glossy leaf cards with specular highlights; it reads as plastic confetti next to the hand-painted buildings. Same foliage on the vine cards in `01-village-grandpa-yard-day-after.png`, which float a few centimetres off the wall and are a flat lime that matches nothing else.
> - Plaza slabs (`01-village-route-out-day-after.png`) end in sharp raised edges hovering over grass — the paving does not meet the terrain.
>
> ## 7. Scale agreement (trainer = 1.80 m)
>
> Buildings mostly agree with each other and with the trainer: the inn door (`01-village-route-out-day-after.png`) is ~2.2–2.4 m, Grandpa's door (`01-village-grandpa-yard-day-after.png`) ~2.1 m, sills at sensible heights. Defects:
>
> - `01-village-grandpa-yard-day-after.png` — the purple flowers: individual petals are ~40 cm across, bigger than the trainer's head, lying on the path. They read as giant fallen petals from an off-screen megaflora, not wildflowers, and they clash with the small blue flowers used everywhere else.
> - Chest-high grass **everywhere, including the village interior** (`01-village-twins-day-after.png`, `01-village-tournament-day-after.png`). Villagers do not let hay grow to the front step. This is simultaneously a scale, intentionality, and readability problem — the girl NPC in `01-village-tournament-day-after.png` is grass-deep to the waist.
> - The well's bricks are ~40 cm each — cinderblock scale, contributing to the "new construction kiosk" read.
> - The trainer's proportions are ~3.5 heads tall. That is a style choice, not an error, but be aware the "1.80 m" ruler does not read: next to the buildings the trainer reads as a child of ~1.2 m, which makes every building read larger than intended. Palworld's characters are full anime proportion; anyone comparing side-by-side will register the proportion language as a different genre (see bar question B).
>
> ## 8. The twins — farmhouse vs inn (`01-village-twins-day-after.png`, `01-village-twins-night-after.png`)
>
> **They read as sibling variants of one house, not as a home and a public inn.**
>
> What differentiates them (and it is real, in daylight, side by side): roof colour — dark crimson vs orange terracotta; timber tone — dark chocolate vs honey; massing — the right building is ~30% wider with a taller ground storey; fenestration — the right building has more and larger mullioned windows.
>
> What does **not** differentiate them, and why they still read as twins:
>
> - **Identical roofline.** Same simple gable, same pitch, same ridge orientation, same two-storey box. Silhouette is the strongest identifier at distance, and their silhouettes are the same shape at two scales. An inn wants a different silhouette move — an L-wing, a dormer, a porch roof, a taller gable-end sign bracket — anything.
> - **Same wall recipe** top to bottom: rubble stone base course + half-timber upper + white cobble chimney, the same chimney mesh on both.
> - **Neither has an entrance treatment.** From this angle neither door is visible; there is no hanging inn sign, no lantern, no bench, no porch, no barrel stack, no stable, no smoke. Nothing says "the public one." The only "inn" cue in the whole survey is a signpost plaque elsewhere.
> - **At night the differentiation collapses to window count** (`01-village-twins-night-after.png`) — roof colour and timber tone go black, and they read as two identical dark boxes with lit windows.
> - Aggravating both: they stand in unconnected hay (point 3) with lit windows in daytime (point 2), so neither reads inhabited enough for the distinction to matter.
>
> Fixable without new meshes: hanging sign with icon, lantern by the door, benches/barrels at the inn front, chimney smoke on the inn only, worn path from the square to the inn door, and pushing the farmhouse roof from crimson toward brown-terracotta.
>
> ## 9. The tournament ground (`01-village-tournament-day-after.png`, `01-village-tournament-night-after.png`)
>
> **It reads as an empty field with a sign in it.** Confirmed in the board crop:
>
> - The board is a small parchment poster frame, half-occluded by the trainer's own head at conversational distance, text illegible, standing in chest-high grass with no clearing at its base.
> - There is no arena: no worn or flattened ground, no perimeter (rope, posts, low fence, chalk), no banners, no seating, no torch stands, no scale contrast with the meadow around it. The keyart marks its settlement gathering space with a large banner and a clearing; this frame marks it with nothing.
> - The two NPCs stand idle, waist-deep in grass, facing arbitrary directions. They read as lost, not as participants or officials.
> - At night (`01-village-tournament-night-after.png`) the space vanishes entirely: no lighting on the board, no braziers — a player could not find the tournament ground after dark, in a game whose keyart promises "day and night create different moods."
>
> The minimum for "purposeful event space," using existing props: a cleared/worn ellipse of dirt or short grass, a fence or post-and-rope perimeter, two or four banner posts, the board doubled in size at the entrance to the clearing, and a brazier or two for night.
>
> ---
>
> # Verdict
>
> ## The three things that most separate these frames from the references, ranked
>
> **1. The ground plane is one uniform grass carpet; the references build settlements on varied, worn ground.** Sharpest in `01-village-twins-day-after.png` (houses to their footings in hay, no connecting path) and `01-village-tournament-day-after.png` (event ground indistinguishable from wilderness). The keyart settlement panel and `palworld-02`/`palworld-05` alternate worn dirt, short turf, flower drifts, and paving that meets the terrain — the ground itself tells you where people walk and live. Here only the well square attempts it, and its paving floats.
>
> **2. The world is empty of life.** Zero creatures in 18 frames of a creature-training game's home village; no smoke, no animals, two or three static villagers standing in tall grass (`01-village-tournament-day-after.png`, `01-village-twins-day-after.png`). Every Palworld reference frame is full of Pals doing things; the keyart puts a creature beside the player in both its day and night panels. This, more than any material or lighting gap, is why the frames read as a diorama rather than a place.
>
> **3. Night is a crushed black void, not "mysterious."** `01-village-tournament-night-after.png` (unreadable player, invisible venue) and `01-village-twins-night-after.png` (bottom 40% pure black) versus the keyart night panel, which keeps a readable blue landscape with warm fire accents. The warm windows are the one thing night currently does right; everything below the horizon line needs a floor on its exposure, a moon that actually lights the moon-side of objects, and one or two warm ground-level sources (lantern, brazier, inn door).
>
> ## Bar questions
>
> **A. Do these frames read as belonging to the keyart world? Yes — narrowly, and only by day.** The stone/half-timber/terracotta building language, the wildflower meadow palette, the rolling green horizon, and the warm-window night coziness are all recognizably the same world as the board's settlement panel. What pulls against it: the settlement dressing (worn ground, banners, well with an actual shaft, smoke, clutter, shade trees inside the village), the empty horizon with no landmark silhouette, and the crushed nights. Every one of those gaps is scene-fixable with existing meshes, scatter, and lighting — none requires art that is not in the build.
>
> **B. Beside the Palworld screenshots, would someone say these are trying to be the same kind of game? No.** They would say cozy village-life game — Portia or Fae Farm — not creature-adventure. Three reasons: no creatures anywhere in frame (Palworld's frames are defined by them); the uniform passive meadow versus Palworld's varied, event-marked spaces (arena wear, bases, camps, landmark towers); and the chibi ~3.5-head character proportion versus Palworld's full anime-proportioned adults, which alone re-genres the image at a glance. Split: creatures-in-frame, ground variety, event dressing, and night lighting are scene-fixable now with installed assets. The character proportion language is **not** scene-fixable — it is baked into the rigged cast, and if the owner's bar genuinely requires reading as Palworld's kind of game at a glance, that is the one gap in this survey that needs art the build does not have. If the chibi cast is a settled style choice, then the answer to B can still become "yes" through the fixable three, because Palworld's frames are carried by creatures and lived-in ground far more than by their humans.
>
> ## Bug-class items that should be fixed regardless of any bar
>
> 1. The well has no shaft and is open underneath — hollow shell visible in `01-village-route-out-day-after.png`, plus dither pattern on its lid.
> 2. The inn ground-floor bay reads as missing wall geometry, worst at night (`01-village-route-out-night-after.png`).
> 3. Signpost label "Practice Mead…" renders over its own arrow and is illegible (`01-village-standing-day-after.png`).
> 4. Daylight-lit windows on the right twin (`01-village-twins-day-after.png`).
> 5. Unmotivated hard gable shadow (`01-village-grandpa-yard-night-after.png`) and unmotivated cool foreground light (`01-village-standing-night-after.png`).
> 6. Grass detail ring / draw-distance band cutting across `01-village-tournament-day-after.png`.

### Post-verdict correction — the "inn's ground-floor bay" finding

Bug-class item 2 above names "the inn's ground-floor bay" as a hole in the
building, citing `01-village-standing-day-after.png` and
`01-village-route-out-day-after.png`. **The building filling frame in both
of those shots is the workshop (`village.json`, at `[2, 2]`), not the
inn** — the inn (`[-1.5, -9]`) is not in either frame's field of view at
all; I confirmed this from the eye/look coordinates each shot was taken
from. What the judge is actually describing is almost certainly the
workshop's own open `Wall_Arch` work bay — an intentional feature per its
own recipe comment ("an open Wall_Arch work bay for bible sec12's 'broader
doors'"), not a missing wall. The underlying visual observation may still
be real (a dark, undressed opening reading as unfinished rather than as a
working smithy's open door), but the building identification is wrong, and
I did not act on this one for that reason — it needs someone to look at
the workshop's arch bay specifically, not the inn.

The dark window the judge may be describing on the actual inn (visible in
`01-village-twins-day-after.png` and `01-village-route-out-day-after.png`'s
right-hand building) is the **pre-existing** `-2` front window — present
identically on `farmhouse_shell` before this pass ever touched the recipe
(confirmed: `Prop_Vine2`, at `[1.9, 2.6, 5.12]`, sits directly on my new
`+2` window, and that one reads fine and vine-dressed in every frame; the
darker one is the original, unmodified by me). Worth fixing, but it is not
something this pass introduced, and it affects Grandpa's house identically
if it's real.
