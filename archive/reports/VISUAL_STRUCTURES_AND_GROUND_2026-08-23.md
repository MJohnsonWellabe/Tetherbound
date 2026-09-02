# D5 structures and D7 ground/sky — blind pass, round 1

Two independent Fable critics, blind, per `ralph/OWNER_DIRECTIVES_2026-08-22.md` §5.

| domain | A (keyart world) | B (Palworld kind) |
|---|---|---|
| D5 structures | **no** (narrowly, mostly fixably) | **no** |
| D7 ground / sky / water | **no** | **no** |

## The one that is a rule violation, not a taste call

> *"23-roof.png: the player-buildable roof is dark, glazed, oxblood red — far
> darker and glossier than any village roof, and sitting in exactly the colour
> band the project reserves for Team Tether danger."*

The visual-judge rubric's criterion 2 explicitly checks that the oxblood stays
reserved for danger. **The player's own house wears the enemy's colour.** Found
blind, by a critic that was never told the colour meant anything.

## D5: three named landmarks are the same two meshes

- **The mill is not a mill** — no sails, wheel, hopper or race; a three-storey
  townhouse with a landmark's name.
- **The ranger station IS `cottage_b`** — same footprint, door, windows, chimney.
- **The inn IS `farmhouse_shell`** with a hue-shifted roof, *"and they stand
  side by side as visible twins in `28-village.png`"*.

Against a brief that asks for "silhouettes and landmarks visible from
distance", *"the world cannot be navigated by looking at it."*

**The player's buildables are the worst-looking things in the game.** The wall
piece — *"the atom of player building, so every wall placed will carry this
defect"* — has a slanted top beam over a black gap and a diagonal base cut that
lifts one corner. The camp is faceted low-poly from a different art style. The
creature bed is a human single bed with a headboard, white pillow and blue
blanket: *"if the player's five companions get this, it reads as a naming
error."* Compared directly with `palworld-05-base-building.jpg`, whose base
pieces sit in the same language as its world.

**The castle is untextured blockout** with no stone material, no crenellation,
a person-sized gate slot and no banners — *"the game's antagonist made of
nothing"*, and the one place oxblood belongs does not have it.

Also: ice-blue foundation slabs under seven buildings; oaks at 6-7 m with
near-black canopies, blue and maroon leaf cards, and salmon-pink trunks.

**What works:** the village pack is *"one architectural language"* and
`28-village-close.png` is *"the one frame here with real charm, and evidence
these assets CAN compose into a place."*

## D7: the ground is the game's weakest surface, and a better one already exists

> *"The build owns a better ground than the one the five bands use."*

A proper grass-blade material renders well at close range in the river frames
and appears nowhere in the five walk bands. That reframes the standing #1 gap
from "add density" to "use the material already in the build".

- **No clouds anywhere.** The `cloudy` preset contains none, and no day frame
  in all 24 shows a single cloud form — every sky is a flat gradient, against
  keyart panels stacked with cumulus.
- **Weather changes particles, not light.** Sun shadows stay identically sharp
  and long under clear, cloudy, fog and rain. *"Overcast with crisp directional
  shadows is a contradiction the eye catches instantly."* Fog is the one preset
  doing its job.
- **Night is an absence, not a mood** — and the character is exempt from it,
  rendering near day-lit against black, casting two divergent shadows with no
  visible source.
- **Three water bodies, three unrelated colours**: pool cyan, dark navy, pale
  grey-blue.
- **Black-backfaced grass tufts** — half of every clump renders as a black
  spike. A real material bug (two-sided/backface), not a lighting subtlety.
- Golden hour *"reads as mud, not gold"*.

## Defects in THIS SWEEP's own harnesses, found by the critics

Recorded because a survey that does not photograph its subject wastes a round,
and this sweep has now done it three times in three different tools.

1. **The ground capture repeats the corridor's floating-player bug** — band-4
   viewpoints again sit on `captain_field` and `captain_ridge`, so the trainer
   renders in mid-air in all three band-4 ground frames.
   `_probe_corridor_survey.gd` already fixed this; the fix was not ported.
2. **Four water frames do not show water.** `water-02-river-grazing` contains
   none at all. `ground-03-band3` is named "river-lock" and photographs a relay
   signpost with no river in frame.
3. **A third of the structures close-ups are framed inside the eaves** and show
   nothing judgeable.

## Cross-survey corroboration worth noting

The floating badge sphere on the Team Tether ranks has now been reported by
**three independent critics in three different surveys** — the character cast
(*"a debug gizmo, not insignia"*), and the ground survey, which saw *"a
detached orange sphere floating beside the Warden's face"* without being asked
about characters at all.

---

# The stronghold: RULED — a siting bug, not a material bug

Three critics called the stronghold *"untextured blockout"*, *"the game's
antagonist made of nothing"*, and *"needs art not in the build… no amount of
scatter or lighting will hide a five-hundred-metre grey plane."* That last
conclusion is **wrong**, and the evidence is in the configs rather than in any
frame.

VIS-SITES found a second castle and shot both, specifically to separate two
fixes hiding behind one verdict. This ruling closes that question without
needing the frames.

**`scripts/world/playground_world.gd` builds a node named
`StrongholdSilhouette` on every boot**, from `landmark.gd`, at
`RISE_CENTRE (140, -90) + OFFSET (89.8, -54.4)` = **(229.8, -144.4)**. It is a
132-module assembled castle — four corner towers, a two-module gate, nine
oxblood banners, a retinted stone kit.

`landmark.gd`'s own comment gives its job: *"271 m out and therefore beyond
`world_perimeter.gd`'s 235 m ring — it is a silhouette, drawn to be seen and
not reached"*, sited on the bearing from the Sigil Gate's OLD position at
(130, -176).

**Then OW5D moved the map and left it behind.** The Sigil Gate went to
(0, 7400); `stronghold.json`'s site went to (0, 7560). `landmark.gd` line 25
states the silhouette's coordinates are *"unchanged from OF9/OF13"*. So the
castle now stands beside the village at z = -144, framed as a distant view
from a gate that is 7.5 km away and no longer exists there — while the
destination the player actually walks to is a different system that renders as
blockout.

**The game already owns a good castle. The player never sees it.**

## What this changes

The fix is not authoring a fortress kit. It is one or both of:

1. **Re-site the silhouette** onto the new stronghold bearing so it reads as
   the destination seen from distance — the job it was built for, on the map
   that now exists.
2. **Bring the castle prefab's assembly and retint to the destination itself**,
   so the thing the player reaches is made of the kit that already works.

Both are cheap against "needs art that is not in the build", which is what the
structures round's verdict implied and what would have been budgeted for.

## Method note

This was ruled from `playground_world.gd`, `landmark.gd`, `stronghold.json` and
`map_landmarks.json` — no render. A blind critic looking at frames could not
have reached it: the frames show a blockout stronghold and are correct that it
looks like one. Photographing the second castle told VIS-SITES it existed;
reading the constants told us why it is in the wrong place. **The critic
diagnoses the symptom; only the code names the cause.**
