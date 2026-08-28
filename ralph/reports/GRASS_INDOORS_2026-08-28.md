# GRASS-INDOORS — the field learns what is standing on the ground

**Branch** `ralph/GRASS-REROLL`. **Answers** `ralph/OWNER_PLAYTEST_2026-08-28.md`
§7, a regression the owner is hitting in the build they are playing.

> *"grass grows through indoor buildings now"*

The word that dates it is **now**: the grass field was switched on 2026-08-27
and this came with it.

---

## 1. Reproduced first, and it is worse than the words suggest

`ralph/reports/shots/grass-indoors/grandpa-house-before.png` is the opening
room of the game — the house the player wakes up in. It is a meadow. Grass,
bushes and flowers stand up through the floorboards and the rug at full
height, and Grandpa is standing in it up to his knees.

## 2. The mechanism

The field's only exclusion was terrain **texture** names:

    for entry: Variant in cfg.get("forbidden_ground", ["rock", "path"]):
    _material.set_shader_parameter("forbidden_base_mask", mask)

That keeps grass off painted rock and painted path. A texture name cannot know
that a farmhouse is standing on the grass it names, so the ground under
Grandpa's floor is grass-painted and the field grew grass out of it.

**The scatter solved this years of commits ago and the field never read the
answer.** `scatter_rules.gd::_inside_a_footprint` gates every baked placement
on a footprint list, and that list's own entries describe this exact defect in
their own words — *"Grandpa's house, 9x7m inside plus walls — grass was
standing on the floor and the rug"*, *"the mill — grass out of the tower and
from under the wheel"*. The field is procedural and camera-relative, so unlike
the bake it cannot be authored around a building. It has to be told.

## 3. The fix, in two halves

**Half one: read the list that already exists.** `grass_field.gd` now reads
`vegetation.json`'s own `footprints` through `scatter_rules.gd`, rather than
copying the numbers — for the same reason `_apply_clearing` reads the bush
tier's own drift numbers instead of duplicating them. Two lists of building
positions would be one edit away from disagreeing, and the way you would find
out is grass on a rug.

**Half two: let a structure declare its own ground.** The authored list covers
seven things in 16.8 km². It does not cover the workshop, the cottages, or the
Warrens' approach ramp — and **adding them to it is not free**: `footprints` is
hashed into `scatter_bake.gd::config_fingerprint`, so an entry there
invalidates the committed scatter bake, fails
`tests/test_scatter_perf_budget.gd`'s freshness assertion, and costs a re-bake
of 256 binary `region_*.bin` files. That is the right price for the *scatter's*
own placements and the wrong one for a structure only the runtime field grows
through — and `ralph/conventions.md` is explicit that generated state does not
belong in a branch bound for consolidation.

So a structure that knows its own extents says so from its own code:
`grass_field.gd` reads a `grass_clear` group whose members carry their own
radius, and `village.gd` and `burrow_warrens.gd` populate it. This also covers
what no baked list can — geometry built at load, and geometry the player builds.

**Which structures, decided from data rather than a hand-kept list.** A prefab
recipe with `Floor_` modules has a floor to stand on; one with a `room` is
fitted out inside; one with a `door` can be walked into even when its inside is
bare ground, which is `cottage_a` exactly. A fence run, a wagon, an oak, a gate
leaf and the castle shell have none of the three and are left alone. **The
castle is the one that matters**: its modules span 36 × 44 m, so a rule that
took every structure would have cleared a 29 m disc of meadow around it.

**The radius formula is validated, not invented.** Half the diagonal of the
recipe's own module extent plus 0.7 m, run against the buildings
`vegetation.json` already footprints by hand:

| building | derived | authored | |
|---|---|---|---|
| inn | 6.53 | 6.5 | |
| footbridge | 6.78 | 6.5 | |
| mill | 5.31 | 5.5 | |
| ranger station | 4.31 | 4.5 | |
| Grandpa's house | 6.74 | 6.5 | (shell, still covered by the authored entry) |

Every one within 0.3 m. So the structures nobody footprinted get the numbers the
authored ones would have got.

**Player-built floors.** Live nodes in `build_placer.gd`'s `placed_building`
group whose id is in `built_clear_ids` (just `floor`) are folded into the same
list each time the ring moves a cell. Only floors: a fence rail or a workbench
is a thing *standing* in the meadow, and clearing a disc of grass around one
would read as a scorch mark. The radius is `build_grid.gd`'s 2.0 m cell
half-diagonal, 1.45 m — the circle that covers a panel completely. The
inscribed 1.0 m circle does not: four of them around a shared corner leave that
corner uncovered, and a floor grid would sprout a tuft at every corner in a
regular pattern, which is a worse artefact than the one being fixed.

**Cost.** The shader loop runs `built_count` times per vertex, and
`built_count` is **zero** across almost the whole corridor. Where it is not, it
is a handful, and a bounding circle rejects the rest of the ring in one test
before the loop is entered. A mask texture would have cost a vertex texture
fetch everywhere to save work in the village, which is the wrong trade for this
world. All three tiers take the exclusion — gravel and bushes inside a
farmhouse are the same defect as grass inside it, and the scatter gates every
baked layer on footprints for exactly that reason.

## 4. Evidence

`tools/_probe_grass_indoors.gd` takes every state **from one boot**, because the
exclusion is a shader uniform and a before/after across two runs would be
comparing two different worlds:

- `-before` — `built_count` forced to 0: the field exactly as the owner played it.
- `-after` — the list the field actually computes.
- `-nofield` — every one of the field's MultiMeshes hidden. The attribution
  frame: anything still standing in it belongs to the baked scatter and is a
  different defect with a different owner.

**The result that matters: at Grandpa's house, `-after` and `-nofield` are the
same room.** Not "acceptable" — identical. Indoors is exactly as it was before
the field existed.

## 5. The general case, audited rather than assumed

The owner said "buildings"; the defect is "the field does not know about placed
geometry", so eight sites were shot rather than one.

| site | before | after | note |
|---|---|---|---|
| Grandpa's house | **meadow indoors** | clean | authored footprint |
| the inn | clean | clean | authored footprint |
| the workshop | **grass through the cobbled floor** | clean | self-registered, no footprint existed |
| cottage_a | **grass inside, a villager standing in it** | clean | self-registered via its `door` |
| cottage_b | inconclusive framing | — | 4 m across; see below |
| Warrens approach ramp | **grass up through the paved steps** | clean | self-registered by the function that builds it |
| relay station | not affected | — | the grass there is an outdoor yard, and correct |
| the stronghold | not affected | — | see below |

**The stronghold needed a correction, and it is worth recording because the
first answer was confidently wrong.** Its floor is at y 8.56 while the terrain
under it is at −0.65, so a camera seated on the terrain stood nine metres below
the room, inside the foundation void, photographing ground no player will ever
see — and it photographed a full meadow. Shot at the real floor height the
stronghold interior is clean flagstone with no cover in it at all. The probe now
lets a site name its floor height so this cannot happen again.

## 6. The risk this change carries, and what was done about it

Every footprint is a disc of ground with no cover on it, and the owner's
standing instruction is that the meadow looks identical everywhere else. A disc
that reached past a wall would read as a scorch mark ringing the building. Two
things bound it: the radii are the authored convention rather than new numbers
(§3), and the village was photographed **from outside**, from far enough back
that the ground between the buildings is most of the frame.

`village-exterior-before.png` and `village-exterior-after.png` are that pair,
and they are the same meadow: grass, flowers and bushes at the same density
right up to the stone of both cottages, and no ring anywhere. Every clearing
disc is under the building it belongs to.

**Do not read a pixel diff off that pair.** Unlike `_probe_grass_walk.gd`, this
tool leaves the WIND ON -- an interior is judged by whether there is grass in
it, and switching the wind off there would buy nothing -- so every blade has
moved between the two exposures and the frames differ by 15/255 on average for
that reason alone. The exterior comparison is a visual one and is stated as
such.

## 7. Left for someone else, deliberately

- **The scatter has the same gap.** `vegetation.json` footprints seven things;
  the workshop, the cottages and the Warrens ramp are not among them, so the
  *baked* scatter can put its own placements there too. This lane fixed the
  runtime field, which is what the owner is seeing, and did not touch the
  authored list, because doing so costs a re-bake of 256 binary region files
  that must not ride into a consolidation. Whoever owns the next bake should
  fold these in; `village.gd::_ground_clear_radius` already computes the exact
  numbers.
- **`cottage_b`** is 4 m across and even at a 1.6 m setback the probe could not
  get a clean interior view of it -- the camera ends up in its own wall. It has
  both a `room` and a `door`, so it is registered by the same rule that fixed
  `cottage_a`, and the field reports it among the footprints in reach. That is
  covered by construction rather than by a photograph, and it is stated here
  rather than implied.

## 8. Tests

`test_grass_field` (5 tests, 31 assertions), the scatter suite (33 tests,
958,342 assertions), `smoke_art` and `smoke_playground` pass on this branch.
