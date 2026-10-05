# Code-blind visual judge: homestead stations (r6)

Judge: code-blind (only the eight PNGs in this folder were viewed; no source, config or docs read).
Criterion: "Stations read as distinct objects at the normal camera."

## 1. Objects seen per image (unhinted guesses)

Same objects in every frame, listed left to right:

| # | Object | Guess |
|---|---|---|
| A | Low wooden table with clamps/trestle legs, tools on top | **Workbench** (bench) |
| B | Grey block furnace with chimney, glowing mouth, anvil on a stump, quench bucket | **Forge** |
| C | Plain light-wood table with a barrel beside it | Unclear on its own. Reads as a prep table belonging to D, or an extra unlabeled table |
| D | Iron cauldron hung in a wooden frame over a glowing fire ring | **Cooking station** |
| E | White stone pillar/cross on a stepped base, flanked by two iron candelabra | **Shrine / altar** |
| F | Open-sided shed with a cream canvas roof, three round pale pads on the floor | Shelter / lean-to. Could be a market stall or rest canopy. The floor pads hint at animal beds, but "creature shelter" is not obvious |
| G | Low raised timber bed with rows of green sprouts, small crate beside it | **Farm plot** |

- row_day / row_night: A–G all visible. G is small at the far right edge, partly under the teal quest beam, but you can still tell what it is.
- forge_kitchen_day / _night: A, B, C, D, E fully visible. Only the corner of F's roof shows at the right edge.
- altar_day / _night: C, D, E, F and G visible. G is next to a hitching-rail/notice-board prop and the teal beam.
- den_farm_day / _night: E, F and G visible, with D cut off at the left edge. A teal waypoint beam overlaps the hitching-rail prop right of G, but not G itself.

## 2. Can the six be told apart, day and night?

Yes, as separate objects. Each has its own silhouette, size and material, and they are spaced well apart on the dirt pad. Nothing overlaps or merges, day or night.
- Night: B and D carry their own warm light and read even better. E's white stone stays bright. F's cream roof stays readable. G's sprouts stay visible against the dark soil. A goes dark but keeps its silhouette.
- Confusable or weak:
  - **F (Den):** clearly a distinct object, but it does not say "creature shelter". It reads as a generic canopy or stall. Nothing on it suggests creatures: no straw, no hay bedding, no bowl, no den opening, no creature sitting in it.
  - **C (plain table + barrel):** an extra station-like object between the forge and the cauldron. A player counting stations sees seven candidates, and C could be mistaken for the workbench or for its own station. It works best if it clearly belongs to the kitchen.
  - **G (Farm):** easy to read up close. In the row shot it is the smallest object and sits at the frame edge, so it is the last one a player would notice.
- B (forge) works because of the anvil and the glow, but the furnace body is flat untextured grey blocks and looks like placeholder geometry next to the textured props.

## 3. Occlusion and whether the frames work as evidence

- The frames are fit as evidence. The HUD (quest panel, hotbar, minimap) does not cover any station in the close views.
- In row_day the "Grandpa's House" signpost overlaps the front of F a little, and the right-hand teal quest beam clips the area beside G. F stays readable in row_day. G is identifiable but marginal there.
- The trainer stands in front of F in den_farm and covers part of its interior.
- Camera height and distance look consistent with normal gameplay.

## 4. Verdict: **PARTIAL**

All six render as separate, non-overlapping objects day and night. One of them, the Den, does not read as what it is meant to be.

| Station | Result | Reason |
|---|---|---|
| Workbench | PASS | Trestle bench with clamps; clearly a work table. |
| Forge | PASS | Chimney, glowing mouth and anvil read instantly. The furnace body looks like untextured placeholder. |
| Kitchen | PASS | Cauldron over a fire is unmistakable. The adjacent plain table + barrel (C) is ambiguous and could be read as an extra station. |
| Altar | PASS | White stone monument with candelabra reads as a shrine, day and night. |
| Den | **FAIL (identity)** | Distinct object, but reads as a generic canopy or stall, not a creature shelter. Needs creature cues such as straw bedding, a food bowl or a resting creature. |
| Farm plot | PASS (marginal) | Raised bed with sprouts is clear up close. Small and at the frame edge in the row view. |
