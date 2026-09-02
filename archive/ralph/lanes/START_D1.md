# START D1 — Lower Meadows

**Branch:** `ralph/gate-d-band1-lower-meadows`
**Band directory:** `data/config/bands/band1_lower_meadows/` — yours whole
**Reserved `order` range:** 1000–1999 (the tournament block at 1000–1003 stays put)
**Owning prompt:** `docs/ralph-prompts/62-BAND1-finished-lower-meadows.md`
**Spine:** z −512 → 1360, ~1872 m. Village, lower grasslands, farm paths, oak
grove, starter stream, pond, and the old South Bridge at z≈1330.

Read `ralph/lanes/COMMON.md` first — setup, test traps, inherited defects, file
ownership, hard rules, ship protocol. Then `ralph/GATE_D_LANE_CONTRACT.md`, then
your prompt. Then `ralph/DONE.md`'s BAND1-D1 entries, which are your own prior
rounds.

The player arrives here having just won the village tournament and leaves by
crossing South Bridge. Prompt 62's definition of done: *the player crosses South
Bridge feeling that the world has opened up and that their five are already more
personal and capable than they were at the tournament.*

## Already done on this branch — do not redo it

- Wild density **8 clusters / 16 creatures → 56 / 200**, inside the owner's
  45–60 clusters / 170–260 creatures target. **Density is done. Do not raise it further.**
- Authored gatherables 14 → 19. Prop clusters 4 → 5 (`trail_camp`).
- Dead travel, measured with `tools/_probe_band1_cadence.py` (new, yours — it
  projects every authored point of interest onto the real spine polyline):
  - pond → village: **673 m → 56 m**
  - tournament → South Bridge: **1568 m → 84 m**
  - whole band worst gap: 1600 m → 84 m
- `scripts/world/props.gd` extended, backward compatibly, with an optional `dir`
  key plus `.glb`/`.obj`-as-Mesh fallbacks, so `props.json` can reach
  `quaternius_survival`, `quaternius_furniture`, `environment/nature` and
  `environment/stylized_nature` — not just `quaternius_fantasy`.
- `scripts/world/campfire_glow.gd` (new) — flickering `OmniLight3D`, flame
  billboards, embers, smoke column, reusing `torch_prop.gd`'s no-texture-asset
  technique because `Bonfire*.mtl` ships no emissive material.
- `trail_camp` rebuilt from 3 props in a line to 14 in a ring around a real
  `Bonfire`.
- `tests/test_band_vegetation.gd`'s exact-count assertion loosened to `>=`. This
  is correct and the coordinator accepted it: the sibling test
  `test_merged_arrays_are_identical_to_the_pre_split_file` still pins every
  baseline entry by `order`/index, so what was removed was a genuine false
  positive. Three lanes made the same change; the coordinator collapses the
  overlap at integration. **Leave it.**
- Full suite green at last check: 1301 tests, 0 failed.

## Settled decisions — do not reopen without new evidence

**Village trainer siting stays as it is.** Seven of eight trainers sit within
30 m of z=0 and the eighth is the South Bridge grunt at z=1314. Moving them was
investigated and declined: their `trainers.json` positions ride the same
villager bodies `village_npcs.json` places (Mira behind a shop counter, Oskar
and Tam with vendor dialogue ladders, the tournament marshal's bracket
referencing all three in the square), so moving position without rebuilding
shop and dialogue placement would desync the two. Full reasoning is in
`ralph/DONE.md`. The coordinator accepted this.

## Your immediate task: the trail camp failed its second blind judgement

An independent critic — which did not produce the frames, was told nothing about
what changed, and did not know an earlier round had failed — judged
`shots/trail_camp/01-camp-close.png` and `02-camp-from-spine.png` and answered
**no** to both bar questions. Its verdict:

> **Single highest-impact remaining defect: the campfire — oversized inert logs,
> no flame, no glow, no smoke.** It fails both questions at once: up close it
> kills the "someone stopped here" read, and from the trail its missing smoke
> column is why the camp doesn't resolve at all.

### Investigate before you change art — this may not be a scene bug

You added `campfire_glow.gd` with flame billboards, an omni light and a smoke
column. The critic reports seeing *"only a few floating ember sparks"* — no
flame, no glow, **no warm light on the barrel or haystack a metre away**, no
smoke. Ember particles rendering while flame billboards and a light do not is a
strong hint that the **capture path** is dropping them — software GL / headless
renderer handling of emissive or billboards, or the glow node never being
instantiated in the captured scene at all — rather than the effect being
missing from the game.

**Establish which it is first.** If the camp looks right in-engine and only the
capture is lying, that is a capture-tool fix and a completely different job from
rebuilding a campfire. Say plainly which one you found.

Two capture-tool bugs of exactly this class were already found and fixed by the
D3 lane in its own tools: a day/weather clock racing the multi-viewpoint pass,
and parking the camera rig's player underground tripping the water-hazard
warning overlay. D3 noted the same conventions exist in other capture tools and
it did not fix them there. Worth reading before you assume your scene is wrong.

### Reachable by scene work

1. **Fog density/tint and sun warmth.** Both frames sit under a heavy blue wash;
   the sky says day, the scene says dusk. The critic called this *"the largest
   single-lever visual gap to both references, and it is a WorldEnvironment
   setting, not art."*
2. **Smoke column above the fire** — the single distance-legibility fix for
   frame 02.
3. **Fire assembly.** The crossed logs read at ~0.6–0.8 m diameter and 3–4 m
   long, thicker than the stool is tall — a fallen-trunk prop pressed into
   firewood duty, and it reads exactly like that. Swap for small-scale logs or
   scale down; add flame/emissive plus a warm omni; scorch or dirt decal under
   it if the project has any.
4. **The pale white-stone scatter** forms two amorphous blobs hugging the camp's
   left flank — too bright, no arrangement, reads as litter or snow patches.
   Arrange into a deliberate fire ring; bury or delete the rest.
5. **Orientation and interpenetration.** The stool faces the barrel, not the
   fire. The haystack is parked touching the fire pile. A long log skewers
   straight **through** the wattle panel — geometry interpenetration that reads
   as a bug. Give the wattle panel posts or something to lean on.
6. **The trail is in neither frame.** Frame 01 shows no path at all; frame 02,
   the supposed approach-from-the-trail view, is a 60%-of-frame empty grass
   slope with no trail surface. "Beside the trail" is this location's entire
   premise. Route the actual trail through both compositions and put worn ground
   under the camp itself.
7. **Greybox and empty foreground.** The long flat mid-grey box at bottom-centre
   of frame 01 has no visible texture and reads as unshaded greybox; the grey
   slab rocks around the fire have uniform faceting and identical tint. Vary or
   bury them, and break up frame 02's foreground with existing bush and
   grass-tuft props.

### Needs art that is not in the build

- **A bedroll, tent or lean-to.** This is the prop that converts "objects" into
  "someone stopped." `Bed*` are indoor furniture.
- Possibly **a real campfire prop** (stone ring, charred small logs, flame) —
  unless the current pile is a mis-scaled placement of one that does exist.
- Ground-wear decals (dirt patch, scorch) if the project has none.

Record these in `ralph/BLOCKED.md` as needing owner-supplied reference art.
**Generate nothing.**

### How far to take this

The critic's own guidance, which the coordinator endorses:

> Do the tuning list once; source or make the bedroll and campfire in parallel;
> do not run another tuning round after that expecting it to close the gap those
> two props own.

So: **one thorough tuning round, then stop and report.** Do not grind rounds
three and four. The critic's read on which failure mode this is: not the
tuning-forever trap — most of what is wrong is ordinary scene work with clear
expected outcomes — but the ceiling is visible, and without a sleep prop and a
real campfire, further rounds converge on a well-lit prop dump.

### Out of your scope

The critic flagged spiky agave/banana-frond plants near the camp as reading
tropical against a temperate meadow. Those are almost certainly `Plant_1`,
`Plant_1_Big`, `Plant_7`, `Plant_7_Big` in the shared `vegetation.json` `bushes`
layer — chapter-wide, in a file no lane may edit, and the coordinator is
investigating it. **Do not touch it.**

## Also owed

- `python3 tools/_probe_chapter_map.py` after any change.
- Full suite green before each push.
- `ralph/DONE.md` currently says round 2 is unjudged. Update it with the verdict
  above — the record should not claim less certainty than we now have.
- **Do not grade your own frames.** When re-rendered, tell the coordinator and
  it will dispatch an independent critic.
