# VIS-MAKE lane — findings established from code, round 2 in flight

Findings that came out of reading what the game actually references, in the
pattern `ralph/VISUAL_LEDGER.md` already uses for these: each is a defect a
player meets, recorded so a blind round is not spent rediscovering it. Each
names the file and the number.

## 1. The fight collapses to 2.1 m, and that is why the camera photographs a rump

Round 1 said the combat camera "frames the wrong participant... the fight
happens between a large rump and a distant dot." That is correct, and it is not
a camera-placement taste call — it falls out of three numbers in
`data/config/combat.json` that were each reasonable alone:

| key | value | what it does |
|---|---|---|
| `enemy.preferred_range` | **2.1 m** | where the AI closes to and holds |
| `camera.distance` | **4.6 m** | how far behind the ally the camera sits |
| `camera.shoulder_offset` | **1.5 m** | how far off-centre it is |
| `arena.separation` | 5.0 m | **initial placement only** — not held |

The ally therefore sits about 69% of the way along the camera's sight line to
the opponent (4.6 of 6.7 m), dead centre, and at 4.6 m a creature-sized body
subtends more angle than a 1.5 m shoulder offset moves it. The opponent is
behind the player's own creature by construction, for the whole fight.

This is measured, not inferred. `tools/_capture_combat_moments.gd`'s
`_aim_camera_clear()` fires a real physics ray from the camera's real position
and tries five lateral yaw nudges (0, ±1.6, ±2.8 m) before giving up; it
printed `every camera nudge tried toward this target was still blocked by the
ally's own body` in **both** encounters of the latest run. `_aim_camera()` only
sets the rig's yaw — it never moves or overrides the camera — so these frames
are the real `CameraRig` a player looks through, doing what it does in play.

`arena.separation` being 5.0 m while the AI holds 2.1 m is worth naming
separately: the arena is authored for a fight at roughly twice the distance the
fight is actually had at.

**Not fixed in this commit, deliberately.** Round 2's renders were already in
flight when this was established, and changing the thing being measured
mid-measurement is how a round stops being evidence. It is the first fix queued
behind the round-2 verdict.

## 2. Every item has an authored colour, and the inventory throws it away

Round 1: *"Every icon is monochrome white on an identical dark tile. No colour
coding by kind, rarity or anything else — Palworld's inventory is full-colour
precisely because colour is what survives a glance."* True, and the reason is
narrower and more fixable than "the icons need art":

- **`data/items/items.json` already gives every item a `colour`** — `coin`
  `#d9b64a`, `wood` `#7a5a35`, `axe` `#5c6b73`, `ironwood` `#4a3a2c`, and so on
  for all 55.
- **`autoload/item_db.gd:137` already exposes it** as `colour(id) -> Color`.
- **Two callers use it** — `harvest_node.gd:251` and `key_pickup.gd:166`, both
  world props.
- **The inventory does not.** `tools/gen_item_icons.py` draws every glyph with
  a single constant, `FG = (242, 245, 242)`, and nothing in the UI modulates
  the result.

So the colour coding the critic asked for is already authored, already parsed,
already reachable through a public accessor, and discarded at the one screen
the player opens most. That is a smaller job than it was reported as.

## 3. There is no hammer mesh and no rod mesh in the build

`items.json` gives `hammer` a `held_model` of
`quaternius_survival/Axe.obj` — the player swings a visible axe to build. The
inventory of what could replace it is short and worth having on record:

    assets/props/quaternius_survival/   Axe.obj  Knife.obj  Backpack.obj  Bonfire.obj
    assets/props/quaternius_fantasy/    Axe_Bronze.gltf  Pickaxe_Bronze.gltf

A repo-wide search for `*hammer*`, `*mallet*`, `*sledge*`, `*rod*` and `*fish*`
returns **icons only**. So the hammer is not a lazy pick from a set that had a
hammer in it; there is nothing to point it at, and D24 forbids sourcing a new
prop family for one tool.

Two things are still wrong with the current choice and both are fixable without
a new asset. It is the SURVIVAL pack's axe while every other tool is the FANTASY
pack's — a different art family in the same hand — and its own mesh is ~1.4 m
tall, which at 1.80 m human scale is enormous. `scripts/player/tool_hold.gd`
supports `held_offset` and `held_rotation_deg` but **no `held_scale`**, so the
size cannot currently be corrected from data at all.

`fishing_rod` has `held_model: ""` and equips nothing. That is honest — its own
blurb is "For water that doesn't exist yet" — so `held-fishing_rod` containing
no rod is the capture correctly photographing an item that has no model, not a
defect to fix by inventing one.

## 4. The second oxblood leak, root-caused

Recorded in full in the commit that added the audit. In short: `world-ironwood`
is built from `TwistedTree_1`, which appears in **no** `vegetation.json` scatter
layer, and `harvest_node.gd::_material_fixups_for_model()` matches by model
path — so the node gets neither `retexture` nor `retint` and renders
`Leaves_TwistedTree_C.png` raw, RGB(167,23,23).

`band2_stone_and_root/harvest.json`'s five ironwood nodes still use `_1`/`_2`/
`_3` and carry the same leak. Band 4 root-caused this, fixed its own nodes, and
flagged band 2's as unfixed; those are other lanes' files and are untouched
here. `tools/_capture_item_art.gd` now audits every world node against the
scatter layers and names the ones that get no fixup, so the fourth blind review
does not have to find it a fourth time.

## 5. The player's creature bed is a human twin bed, and a better asset is installed

Round 1: *"The creature bed is a human single bed with a headboard, white pillow
and blue blanket: if the player's five companions get this, it reads as a naming
error."* Confirmed at source — `scripts/build/creature_bed.gd:19`:

    const MESH_PATH := "res://assets/props/quaternius_fantasy/Bed_Twin1.gltf"

It is literally a twin bed from a furniture pack.

This is the same shape of finding as the ledger's grunt-rig entry — the thing
that would fix it is already in the build and referenced by nothing that needs
it:

- **`assets/props/generated_camp/camp_bed.glb`** is installed and textured: a
  raised camp bed with a lashed log frame, stuffed mattress and pillow,
  generated from an **owner-supplied reference board**
  (`docs/art/reference/owner-board-2026-08-23-camp-set.png`, recorded in
  `docs/ASSET_LEDGER.md`). `band1_lower_meadows/props.json:339` already places
  it in the world as `"model": "camp_bed"`.
- **`assets/props/kenney_survival/bedroll.glb`** is vendored, and
  `scripts/build/camp.gd:20-21` carries its own note that the camp shipped with
  "an indoor bed frame standing in for a bedroll... A real bedroll is now
  vendored."

So the player's buildables are furnished from a generic furniture pack while a
purpose-made, owner-referenced camp set sits installed beside them. No new
asset, no generation and no D24 exception is needed to close the gap.

**What this does not settle:** neither a camp bed nor a bedroll is a creature
*nest*, and no nest, basket or straw-bed mesh exists anywhere in the build. So
"the creature bed does not read as a creature's" is only partly reachable by
re-pointing a path — the rest is an asset that is not in the build, which is the
split the visual-judge rubric asks for and a `BLOCKED.md` candidate rather than
something tuning reaches.

## 6. The teal/green ground band — measured, and NOT this lane's

Round 2's blind critic called it *"a hard-edged teal light band across the
hillside... matches no sun direction and no time of day; it reads as a
misconfigured spotlight or lightmap seam, and it is the single most artificial
thing in the combat set"* (`01-engagement-clean`, `04-catching-clean`). It is
still there in round 3 and is very prominent.

Measured rather than eyeballed, because the description and the numbers disagree
in a way worth recording. Sampled inside the band against adjacent grass in
`01-engagement-clean`:

    band          avg #26330a   (38, 51, 10)
    grass beside  avg #232e03   (35, 46,  3)

So it is **not** a bright light: about +8% luminance, and a blue channel lifted
from 3 to 10. What makes it read as an artefact is not its brightness but its
SHAPE — a large, coherent region with a hard curved boundary that follows no
terrain feature and no sun direction. It looks like a lighting bug and measures
like a ground-material or splat boundary.

This is terrain/ground, which is D7 / VIS-WORLD's, not builds-items-combat. Not
touched. Recorded here with the numbers so whoever owns it does not have to
re-derive them, and so nobody goes looking for a stray SpotLight3D that is not
there.

## 7. Measured baseline for the convergence rule

`tools/frame_stats.py` on round 3's combat clean frames, so the next round has
numbers to move rather than adjectives to argue with:

| frame | luminance | hue families | dominant |
|---|---|---|---|
| 01-engagement | 11.708 | 2 | chartreuse 79%, yellow 10% |
| 02-move-firing | 11.353 | 2 | chartreuse 80%, yellow 9% |
| 03-hit-landing | 11.754 | 2 | chartreuse 79%, yellow 10% |
| 04-catching | 8.600 | 2 | chartreuse 90%, orange 6% |
| 05-trainer-battle | 50.941 | 4 | orange 27%, chartreuse 26%, red 20%, yellow 19% |

Two things worth reading off it:

- **01/02/03 now agree to within 0.4 luminance.** Before the clock was pinned
  and frozen they drifted across the pass. 04 is still an outlier, but its hue
  mix (chartreuse 90%) says that is FRAMING — the aim camera fills the frame
  with grass — rather than the light having moved. 05 is in the village, so its
  numbers are not comparable to the meadow shots at all.
- **Two hue families in every meadow frame.** That is the numeric form of the
  ledger's standing "the chapter has one colour", now confirmed for combat
  specifically, and it is the baseline any palette work has to move.

**Item icons, the one axis this lane did move:** measured across the icon
sheet's non-background pixels, visibly-coloured pixels went from **0% to 55.8%**,
and hue families present from **0 to 10**. That is a measured movement on the
axis round 1 and round 2 both complained about, which is what
`ralph/conventions.md` counts as a round that improved.
