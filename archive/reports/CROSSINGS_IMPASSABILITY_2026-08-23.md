# Are the one-bridge choke points actually impassable?

**Owner question, 2026-08-23:** several places in the Meadows are designed
around crossing at a single bridge. That only works if the barrier is genuinely
impassable everywhere else — a gorge or a river you cannot get across. Confirm
whether it is.

**Answer: the river is. The three short trenches are not, and were never going
to be.**

Tool: `tools/_probe_crossings.gd`. Every number below is measured off the
**baked** Terrain3D dataset via `Terrain3D.data.get_height()` — the surface
collision is generated from — not off `playground_heightfield.gd`, which is
only the recipe the bake was made from. `playground_world.gd` loads the bake
from disk and errors if it is missing, so the two can drift, and this sweep has
already measured them drifting by up to 22 m near the river channel.

## The river (SE21) — SEALED

The barrier the Old Mill Crossing exists for. It holds.

**No 64 m window anywhere across the corridor's full 2,048 m width lets a route
reach the far bank** — at the player's own 45° `floor_max_angle`, or at the 60°
a ridden legendary gets from `riding_controller.gd`. The Old Mill Crossing is
the only way over, which is what it was designed to be.

The cut is real along its whole length, and the bake is faithful to the recipe:

| x | baked depth | steepest wall | recipe depth |
|---|---|---|---|
| −980 | 13.2 m | 70° | 13.2 m |
| −800 | 15.2 m | 71° | 15.2 m |
| −280 | 16.6 m | 75° | 16.7 m |
| −152 *(the crossing)* | 21.1 m | 80° | 21.8 m |
| 320 | 15.6 m | 73° | 15.6 m |
| 860 | 11.4 m | 69° | 11.5 m |

188 stations, every one between 11.4 m and 21.1 m deep except the two end
fades, and every baked depth within about a metre of what the config asks for.
The design reached the played surface intact.

Thirteen column profiles straight across the channel, from x −1000 to x +1000,
all say the same thing: the gentlest of them still has a 2.21 m-per-metre step
in it (65°), and the narrows at the crossing has 5.50 (80°).

### One stale comment, worth fixing even though it did not break anything

`playground_heightfield.gd::_river_carve` says of its end fade:

> *"Both ends are outside the perimeter ring, so this fade is never something a
> player can stand in."*

That is the pre-corridor 235 m ring. `OW5C` replaced it with a 2,048 m-wide
corridor and the course now ends **at** the west wall and **3 m short of** the
east one, so the fade does land inside the playable area — measured at 3.9 m
deep / 12° in the west and 0.0–1.7 m / 12–43° in the east. The windowed scan
says those fades still do not open a route, so this is not currently a hole.
It is a comment asserting a safety property that stopped being true when the
world changed shape, sitting on the one piece of geometry the whole of Band 3
depends on. Worth correcting to say what actually keeps it sealed.

## The South Bridge gully and both Sigil Gate gorges — NOT barriers

| barrier | authored | length | scan |
|---|---|---|---|
| South Bridge gully | 11 m deep, 72° | **90 m** | passable across the whole 400 m test span |
| Sigil Gate gorge, west | 11 m deep | **108 m** | passable across the whole 400 m test span |
| Sigil Gate gorge, east | 11 m deep | **108 m** | passable across the whole 400 m test span |

These are 90–108 m bars in a corridor **2,048 m wide**. The trenches themselves
are deep and steep exactly as authored — the point is that you walk round the
end of one in about a minute. Nothing in the terrain closes the ground either
side of them.

This is not a regression and it is not a surprise: `terrain_playground.json`'s
own river block says so, in the course of explaining why the river had to exist
at all —

> *"Both ends run PAST world_perimeter's 235m ring … which is the property
> SC14's own `_comment_crossings_reach` said a real division needs **and its
> gully could not have**."*

So the gully was known not to divide anything when it was built, in a 470 m
world. In a 2,048 m one it divides proportionally less. **Whether that matters
is a design question, not a bug**: the South Bridge may be intended as a
signposted route rather than a gate, and `CLAUDE.md` puts traversal philosophy
under ask-rather-than-invent. Flagged, not decided.

## What this probe got wrong first, and why it is recorded

Four runs produced confident wrong answers before the fifth was right. Recorded
because the failure mode is general and the sweep has paid for it before.

1. **Transects measured along the ditch.** The straight-carve cross-sections
   used `Vector2(sin, cos)` where `playground_heightfield.gd::_prepare_carve`
   uses `Vector2.RIGHT.rotated()` — 90° off, so they cut lengthwise down the
   trench and reported an 11 m gully as 2.5 m deep.
2. **The flood band did not straddle the river.** The course swings 142 m in z
   between its ends; a band starting at z 4120 left the whole river outside it
   at both ends, so the fill walked open ground and reported 2,041 of 2,049
   columns crossable — next to transects measuring 80° walls.
3. **A plain fill cannot say where a barrier fails.** One leak spreads along
   the entire far bank, so a per-column read of it means only "the far bank is
   one connected surface". Confining each fill to a sliding 64 m window fixed
   that.
4. **The criterion itself was wrong, and this is the one that matters.** The
   fill tested a PATH GRADIENT — "is the height difference between these two
   adjacent cells within 45°". Godot tests the contact **surface normal**
   against `floor_max_angle`, which does not care which direction you approach
   from. On a planar 70° face a path near the contour has a gentle gradient, so
   the fill switchbacked down cliffs and reported 1,509 m of the river
   passable. A real player slides: a 70° face is unwalkable in every direction.
   Replacing the test with a local-gradient-magnitude one — the actual surface
   normal — turned that 1,509 m into SEALED.
5. **A sample off the end of the baked world is not flat ground.** The column
   scan skipped its check when a neighbour returned NaN, so the outermost
   columns fell through as walkable and it reported 1 m and 3 m "holes" at the
   corridor walls, with a "gentlest grade 0.00" printed beside them — a zero
   gradient at the world edge being the tell. The windowed scan had it right
   because it treated NaN as unwalkable.

The general lesson, and the reason all five are written down: **when two
measurements of the same thing disagree, that is a fact about the measurements,
not a finding about the world.** Runs 2 through 4 each had a number that
contradicted the transects sitting in the same output, and each time the
contradiction was the most informative thing on the page.
