# Code-blind judge: homestead stations r12

Judged only the ten PNGs in this folder. I read no source code, docs or configs.

Criterion: "Stations read as distinct objects at the normal camera."

## 1. What I see in each image (left to right, guessed without hints)

**row_day / row_night (about 10 m)**
1. A wooden plank table on legs with a small lit item on it. Guess: **bench / workbench**. It reads as a table, but no tools are visible at this distance.
2. A grey block furnace with a tall chimney and a glowing yellow mouth, with an anvil on a stump and a bucket in front. Guess: **forge**. Clear.
3. A small side table with a pot on it, next to a black cauldron hung in a wooden frame over a glowing fire basin. Guess: **cooking station**. Clear.
4. A white cross-topped pillar on a stepped plinth between two iron candelabras. Guess: **shrine/altar**. It reads as a shrine, though the shape is close to a grave marker.
5. A large house-shaped box with a red roof, a triangular gable, a big black crescent/arch on the front wall, a barrel, and a yellow cushion at its base. Guess: **unclear at this distance**. It reads as a small village building or shed. The paw sign is not legible here. A signpost reading "Grandpa's House" points right beside it, which suggests to the player that this box *is* Grandpa's House.
6. A low raised wooden bed with green sprouts and a basket. Guess: **farm plot**. Readable but small, behind the signpost and partly crowded by its arrow.

**forge_kitchen_day / night**: workbench (a sturdy plank bench, now clearly a work table), forge (anvil, furnace, chimney, bucket), cooking station (cauldron over fire plus prep table), shrine (cross pillar with candles), and the den edge at the right. All four left-hand stations read correctly.

**altar_day / night**: forge (partly cut off at left), cooking station, shrine, den, farm plot. From here the den shows a paw-print sign, a water/food bowl, a basket and a round cushion/bed. **Animal/creature shelter (a big kennel)**, readable. Farm plot reads clearly.

**den_day / night**: workbench (cut off at left), forge, cooking station, shrine, den (paw sign, bowl and bed visible: **creature shelter**), and the farm plot partly hidden behind the signpost.

**farm_day / night**: cooking station (cut off), shrine, den (paw sign, bowl, bed: **creature shelter**), farm plot (sprouts in a raised bed with a basket). Clear **farm plot**.

## 2. Can a player tell the six apart?

- Forge, cooking station, shrine and farm plot each have a distinct silhouette and props, and read day and night. At night the forge mouth, the cauldron fire and the altar candles glow, which helps readability.
- The workbench is distinct from the others but generic. At 10 m it is "a table"; in the close views it is a believable workbench. At night it is the dimmest station and the least lit, but its silhouette still separates from the ground.
- **The den is the weak one at row distance.** It looks like a small house, the same kind of object as village buildings, and the adjacent "Grandpa's House" signpost makes the confusion worse. The paw sign, bowl and bed that identify it only become legible at the close distance. The black crescent "doorway" reads as a flat decal or cut-out shape, not as a dark opening a creature could enter. Up close it does read as a kennel or creature shelter.
- Nothing among the six looks like another station. The only confusion is den versus village house.
- Fidelity note (not readability): the forge furnace, den and altar are flat, untextured primitives next to textured props (anvil, cauldron, barrel, bench). At night the den roof turns dark maroon/oxblood, which drifts toward the reserved Team Tether red.

## 3. Occlusion and fitness as evidence

- The frames are fit as evidence. The HUD (quest box, hotbar, prompts) never covers a station.
- In row_day/night and den_day/night the village signpost stands between the camera and the den and farm plot. Its arrow overlaps the den's right edge and the farm plot area, and in the den close views the post partly hides the farm plot.
- Each close view crops the stations at its left edge (the workbench is never fully shown in a close view except forge_kitchen). Together, the close set still covers all six.
- The player character stands in front of the den in altar, den and farm views, covering part of its front, but the identifying props stay visible.

## 4. Verdict

### Row view (about 10 m): **PARTIAL**: the den fails

| Station | Result | Reason |
|---|---|---|
| Workbench | Pass (weak) | Reads as a distinct wooden bench/table, but generic with no visible tools |
| Forge | Pass | Furnace with chimney, glowing mouth and anvil is unmistakable day and night |
| Kitchen | Pass | Cauldron over fire plus prep table reads as cooking |
| Altar | Pass | White pillar on plinth with candelabras reads as shrine (slightly grave-like) |
| Den | **Fail** | Reads as a small village house or shed. The identifying paw sign, bowl and bed aren't legible, and the "Grandpa's House" sign beside it misleads |
| Farm plot | Pass | Raised bed with green sprouts is clear, though small and crowded by the signpost |

### Close views: **PASS** (den is marginal)

| Station | Result | Reason |
|---|---|---|
| Workbench | Pass | Sturdy plank work table, distinct from the kitchen side table |
| Forge | Pass | Anvil, stump, furnace and bucket; strong glow at night |
| Kitchen | Pass | Hanging cauldron over fire basin with prep table |
| Altar | Pass | Candle-lit shrine pillar, distinct in white |
| Den | Pass (marginal) | Paw sign, bowl and cushion bed make it read as a creature kennel, but the flat black crescent doorway and plain box still look like a placeholder building |
| Farm plot | Pass | Sprouting raised bed with basket, clear day and night |

### Suggested fixes for the den
Make the opening a real recessed dark doorway. Give the den a silhouette unlike a house (lower and wider, a rounded or thatched roof, or open sides with visible bedding). Put the paw sign or a creature-colored banner where it is legible from 10 m. Move or turn the "Grandpa's House" signpost so it does not sit beside the den.
