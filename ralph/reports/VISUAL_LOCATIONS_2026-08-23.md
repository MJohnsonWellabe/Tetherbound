# The locations pass — sites, not routes

The whole-game visual sweep's LOCATIONS lane: the village, the mill sites, the
quarry, the Burrow Warrens, the Tether Relay, the Old Mill Crossing, the Upper
Meadows camps and the Stronghold. Capture tool: `tools/_capture_locations.gd`,
three eyes per site — the approach, standing in it, and one detail — because
the question a site has to answer is not "is this model good" (the structures
survey asks that) and not "does the journey read as one place" (the corridor
survey asks that) but *is this somewhere a player wants to be*.

## Findings that did not need a critic

These came out of authoring the capture — reading what the game actually
references — and each is checkable from `data/config/` in one command. They are
recorded here so a blind round is not spent rediscovering them.

### The stronghold's art exists. It is standing 7,708 metres from the stronghold.

Two different buildings answer to "the stronghold", and the pretty one is not
the one the player walks to.

`scripts/world/landmark.gd` builds `building_prefabs.json`'s `castle`: **132
hand-placed modules** from the Quaternius castle kit — 70 `TallWallBricks` and
38 `WallBricks` of curtain wall, four `PointyTower` corners, three
`LargeSquareTowerBricks` (one of them a 5.2-scale keep with a
`SmallSquareTowerBricks` cap at 21.7 m), three `SimpleTowerBricks`, two
`WatchTowerWRoof`, and a real gate in two `TallWallEntrance` modules. It is
retinted stone-on-stone (`LightRock #a3907a`, `DarkRock #8b7c6b`) and it
carries **nine `Banner` modules retinted `#7a2430`** — oxblood — all nine
clustered on the gate face between 6.4 m and 17.4 m.

It stands at `RISE_CENTRE + OFFSET`, two hardcoded constants totalling
**(229.8, −144.4)**, on a site `OF13` chose specifically so the stronghold
would *not* be visible from the village.

The stronghold the player actually reaches is `scripts/world/stronghold.gd`'s
five-chamber route at **(0, 7560)** — `stronghold.json`'s `outer_works →
courtyard → tether_approach → warden_arena → legendary_chamber`, built entirely
from `BoxMesh` primitives under three flat colours (`stone #6a6157`,
`floor_colour #57503f`, `tether_trim #332228`).

**The two are 7,708 m apart.** `castle` is referenced in exactly one file.

**And so is every piece of stronghold dressing.**
`scripts/world/stronghold_occupation.gd` is referenced by exactly one file --
`landmark.gd` -- so `stronghold_occupation.json`'s **14 braziers, 4 tether
lamps, 5 sky-fill lights and a 21-prop occupation camp** are all attached to
the legacy castle too. Their coordinates are in that castle's own local frame,
which is checkable at a glance: a brazier sits at local `[-1.7, 4.2, -7.0]` and
a tether lamp at `[-3.6, 12.6, -10.95]`, against the castle's own gate-flank
`Banner` at `[-3.6, 10.5, -11.0]` -- the same x, a metre and a half apart in z.

So the fortress a player never sees has stone, crenellation, nine oxblood
banners, fourteen lit braziers, four faction lamps and an enemy camp pitched
outside it. The fortress they walk 7.5 km to fight in has five box rooms,
three flat colours, and a trim system whose only two kinds are `band` and
`pillar` -- no merlons, no banners, verified in `_build_trim()`'s own match
statement.

**Both castles were photographed, and the frames settle which fix this needs.**
The structures survey shoots prefabs on a bare stage, so its verdict could not
distinguish "the model is bad" from "the model is fine and is standing
somewhere else". Two frames from this pass do.

`10-stronghold-approach-day` — the stronghold the player walks 7.5 km to
reach, from 110 m out on its own gate axis: **two flat grey slabs on a green
hill.** No silhouette, no towers, no gate read, no crenellation, no colour. The
larger slab is a featureless pale plane with a hard vertical edge against the
sky. `10-stronghold-gate-day` puts the 1.80 m trainer at the threshold: the
wall is one unbroken near-black rectangle with a plain rectangular hole punched
in it — no arch, no lintel, no doors, no flanking mass, nothing on top. The
approach ramp beside it carries a properly textured cobble material that reads
far better than any wall in the frame, so the build is not short of a stone
texture; the walls are not using one.

`11-castle-landmark-approach-day` — the castle at (229.8, −144.4), from 64 m
out on ITS gate axis: **crenellated curtain walls with visible merlons, two
towers under conical roofs, an arched gate with a door leaf, braziers lit
either side of it, red banners on the wall face, and the occupation camp's
crates at its foot.** Warm cream masonry that reads as stone.

Same build, same renderer, same afternoon. The art is not missing and it is not
bad. It is 7,708 m from the place that needs it.

This is the same shape as D7's finding that "the build owns a better ground
than the one the five bands use", and it re-frames the lane's largest item.
Both of the structures round's stronghold verdicts —

> *"the game's antagonist made of nothing"*
> *"no oxblood banners in the one place that colour belongs"*

— are true, and neither is a missing-art problem. The `OW5D` corridor
relocation carried the quarry, the relay, the mill, the pond and the warrens
onto the 7.5 km spine; `landmark.gd`'s site is a `const`, so it stayed behind
with the old 271-metre world. The banners the critic went looking for are
hanging on a castle nobody can reach, deliberately hidden behind a hill.

### The inn is `farmhouse_shell` plus one line of JSON

`inn` is 75 modules, `farmhouse_shell` is 74, and their module histograms are
identical down to the count: 11 `Wall_UnevenBrick_Straight`, 9
`Window_Wide_Flat1`, 8 and 8 exterior borders, 7 `Wall_Plaster_WoodGrid`, 5
`Wall_Plaster_Window_Wide_Flat`, 4 each of the rest.

The entire visual difference between them is one extra `retint` entry:

    "MI_RoundTiles": {"color": "#8a5a3a"}

Everything else `inn` adds is colliders, a door leaf and an interior room —
real work, none of it visible from outside. The structures critic's *"the inn
IS `farmhouse_shell` with a hue-shifted roof"* is not a figure of speech; it is
the recipe.

### The mill has no mill in it

`mill` is 78 modules and every single one is a wall, roof, window, corner,
border or fence: 11 `Wall_Plaster_WoodGrid`, 11 `Wall_Plaster_Straight`, 10
`Wall_UnevenBrick_Straight`, 8 `Corner_Exterior_Wood`, 8
`Prop_WoodenFence_Single`, and so on down. There is **no wheel, sail, hopper,
race or axle module in the recipe at all.**

`village.json`'s own placement comment states that the wheel hangs at the
prefab's local x −4.0 and that its bottom paddles meet the stream surface. No
module in the recipe is a wheel. The same file already records why: the
Medieval Village MegaKit has no mill machinery, which is why the old
`TowerWindmill` was removed *and not replaced*. A named landmark is being
grounded `"highest"` so that a wheel which does not exist clears a streambed.

### The ranger station is a bigger cottage, not the same mesh

Slightly narrower than the structures critic's *"the ranger station IS
`cottage_b`"*: it is 34 modules against `cottage_b`'s 29, with a
`Roof_RoundTiles_4x6` instead of a `4x4` and seven straight walls instead of
five. They read as twins because they are the same kit, the same single
`MI_WindowGlass` retint, and the same two-window-and-a-door front — not
because they are one mesh. Worth stating precisely, because "it is the same
model" and "it is the same kit used the same way twice" have different fixes.

## Harness defects this pass found in itself, before a critic saw them

Recorded per `ralph/VISUAL_LEDGER.md`, which counts six occasions in this sweep
where a survey photographed something other than its subject.

1. **The warrens approach had no cave in it.** The eye was a world offset of
   (+24,+24) from the entrance mark. The site is yawed 315°, so its mouth faces
   (+x,−z) — the offset walked sideways past the mound rather than standing off
   from it. Caught by a one-site smoke run, not by a critic.
2. **The stronghold approach had the same bug and had not rendered yet.** Its
   route is yawed 90°, so the gate faces west; an eye due south of (0,7560)
   photographs a side wall. Both are now `pull_back`, which takes its direction
   from the two markers the shot already names, so the shot cannot be wrong
   about which way the door faces.
3. **Interior look-targets aimed at the roof.** A shot at the warrens mouth
   looking at the `hall` mark took the target's height from the ordinary
   downward raycast, which returns the *mound's roof*, and aimed the camera up
   the outside of the hill. Eye and look target now carry separate floors.
4. **`burrow_warrens.gd::marker()` returns the node's own position for a key it
   does not know** — a documented fallback that would have photographed the
   wrong room while every line of output looked healthy. Now detected.
5. **`_clear_of_bodies()` named nothing.** It reported `"was occupied by "`
   because `blocker` is empty on the attempt that succeeds. It fired for real
   on the warrens entrance mark — an authored coordinate holding an NPC,
   exactly the trap the corridor survey documented — and said nothing useful
   about it.

## Round 1 blind verdict — Fable, per OWNER_DIRECTIVES_2026-08-22 §5

**A (keyart world): no. B (Palworld kind): no.**

Sheet: `shots/locations/_sheet.png`, 45 frames, eleven sites. The critic read
the rubric, the sheet, 24 frames individually, all five Palworld references and
the keyart board, and was told nothing about what changed or what anyone hoped
to hear.

### The three gaps it ranked

1. **Nothing organises the ground plane.** *"In every reference, the ground
   itself records habitation… In `01-village-twins-day` and
   `10-stronghold-approach-day`, buildings and props sit on untouched uniform
   lawn with no path in, no wear, no enclosure, no ground-material response at
   all. Until a path enters a site and the grass dies where feet go, no site
   will read as a place."* This is the locations-lane form of the standing
   density finding, and it is sharper: the problem is not how much grass there
   is, it is that the ground does not respond to the site standing on it.
2. **Whole sites are still blockout, in frame.** The stronghold gate, the
   waystop's raw grey cliff, the relay plaza's tiling brick slabs. *"No Palworld
   reference contains a single unfinished surface. The bar images are finished
   pictures; a third of this survey is not."*
3. **Night and interior lighting is absence, not mood** — and the specific
   mechanism is new: **the fires emit no light.** `08-ridge-camp-fire-night` is
   *"pure black with an unlit campfire"*; `05-relay-camp-fire-night`'s fire is
   *"a faint smudge behind crates; the scene is lit by nothing."* For a brief
   whose words are "cozy and inviting", *"the single cheapest coziness
   instrument in the toolbox is switched off."*

### What it found blind that this pass had already found in the data

Recorded because independent agreement is the strongest signal available here.

- **The mill has no wheel.** *"The shot named 'wheel' contains no wheel. The
  mill has no water wheel from any surveyed angle. The site's defining prop is
  missing from the site."* Reached from the frames alone, with no access to the
  recipe that proves it — 78 modules, not one of them a wheel.
- **The stronghold gate is an untextured box** — *"a featureless dark cobble
  box with a black hole for a gate, no banners, no Tether identity, standing
  beside greybox"* — against the keyart's stronghold panel, which it calls
  *"the widest single gap in the survey."*

### One finding that reverses a standing assumption

The oxblood rule has been treated as passing. The critic, not told the colour
means anything, flagged it in the opposite direction:

> *"the castle — apparently a friendly landmark — flies near-identical dark-red
> pennants on every tower. If oxblood means danger, the castle is currently
> announcing it."*

Its nine `Banner` modules are retinted `#7a2430`. That is correct **if** the
castle is Team Tether's. It is the enemy stronghold — so the banners are right
and the READ is wrong, because nothing else in the frame says whose castle it
is. Worth having: the colour discipline is holding, and it is doing no work
without a faction silhouette beside it.

### Its answer to the extra question — which site is worth being in

> *"The mill pond (02), on the strength of `02-mill-pond-approach-day` — and it
> is the only one."*

Because it has *"enclosure (the tree line cups the clearing), a focal building
with a reason to exist, a foreground that rewards standing there, water as an
edge, and terrain that slopes you toward the subject. It is composed like a
place."* And it survives *"despite its defects — dead flat cyan water and a
mill with no wheel — which tells you how far structure alone carries a site."*

**That frame is the one this pass re-shot** after the first attempt seated its
eye at −18.4 m against a pond surface of −17.0 and photographed the bottom of
the pond. The single best frame in the survey existed only because the raycast
said so in the log and the coordinate was re-derived from the route the config
already names.

Runner-up: `01-village-standing-day`, *"the one frame with genuine site
grammar — signpost cluster, well plaza, ivy on the wall, two facades forming a
street corner, a villager in the middle distance. This is authored."* That is
independent corroboration of the structures round's `28-village-close`
finding, from a different frame of the same square.

### This survey's own harness defects, found by the critic

Five of forty-five frames do not show their subject, and that is this tool's
fault, not the world's:

1. `07-mill-crossing-yard-day` — camera at a grazing angle to bare terrain.
   *"The detail shot of this site shows no site."*
2. `08-ridge-camp-fire-day` — *"90% sky with the fire, the trainer, and the NPC
   all cut off at the bottom edge — the 'fire' detail shot of this site
   literally does not contain the fire."*
3. `06-relay-apparatus-day` — ~70% empty sky.
4. `05-relay-camp-fire-day` — *"the NPC interpenetrates the trainer — two
   characters standing inside each other."* `_clear_of_bodies()` protects the
   PLAYER's seat; it does not stop an NPC from standing where the player was
   put afterwards.
5. `11-castle-landmark-approach-day` — a foreground tree fills the right of
   frame (noted here; the castle is still legible).

The `detail` rig aims 1.6 m above the target's ground from 5 m back, which
composes a shot about the dirt when the subject is a fire on the ground or an
apparatus on a 10 m deck. Round 2 must fix the rig before it re-judges the
sites, or it will re-photograph its own framing.
