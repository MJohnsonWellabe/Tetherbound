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
