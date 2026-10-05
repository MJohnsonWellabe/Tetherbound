# F31 stations r4: code-blind visual judgement

Criterion: "Stations read as distinct objects at the normal camera."
Judge saw only the six PNGs in this folder. It read no source, config or docs and got no hint about the order of the stations.

## 1. Objects seen and blind guesses

Order from left to right in the row frames. Labels A–F are the judge's own.

| # | What is on screen | Blind guess | Confidence |
|---|---|---|---|
| A | Low wooden plank table with dark legs and a small pot of greens next to it | **Bench / workbench** | High |
| B | Pale grey-blue block with a tall chimney and a dark firebox opening, with an anvil on a stump and a small bucket in front | **Forge** | High (the anvil and chimney carry it). The block itself is an untextured primitive. |
| C | Pale wooden table with a blue pot on it, a barrel to its left and a black three-legged cauldron to its right | **Cooking station**, probably | Medium. Only the cauldron says "cooking". The table on its own reads as a second bench. |
| D | Pale blue cylinder with a light-blue cap and a small dark bowl at its base | **Unclear.** It reads as a canister, bin, water cooler or bollard. | Low. Nothing suggests a shrine or altar. |
| E | Open frame of four posts with a flat pale roof, and a row of white lumpy cushions on the ground underneath | **Animal shelter**, weakly. It also reads as a pergola, market stall or carport. | Low–medium. The bedding is the only clue, and it looks like stepping stones or snow. |
| F | Low, empty rectangular wooden crate frame on the grass | **Unclear / maybe farm plot.** It also reads as an empty raised bed, crate or pallet. | Low. No soil, rows or crops are visible. |

Background objects that are not stations but compete with them: in den_farm frames, a tent and campfire behind E; pink glowing wisps near A; a signpost.

Per image:
- **row_day**: A, B, C, D, E and F are all present. F is tiny at the right edge, just under the quest panel, and is barely legible. The signpost stands in front of the gap between D and E.
- **row_night**: same layout. A and B still read. D and E's roof turn into the same flat pale-blue tone, and F is almost invisible.
- **forge_kitchen_day**: A, B, C and D, with the edge of E on the far right. A and B read well. C reads as a table with a cauldron. D is still an unexplained cylinder.
- **forge_kitchen_night**: same. B shows no fire, glow or light at 23:00, which is a missed readability cue. The cauldron at C stays readable as a dark silhouette.
- **den_farm_day**: C and D at the left edge, E in the centre, F to the right of the player. E reads as a shelter or stall. F reads as an empty crate.
- **den_farm_night**: same. E's cushions are the brightest thing in the frame and look like stepping stones. F is a faint outline.

## 2. Can a player tell all six apart?

- **Distinct and readable, day and night:** A (workbench) and B (forge).
- **Easy to confuse:** C (kitchen) and A (workbench). Both are plain tables, and C is only told apart by the cauldron placed beside it. If the cauldron were moved or hidden, C would just be a second bench.
- **Unreadable:** D (altar). Nothing about the cylinder says shrine or altar: no stone, offering, symbol, glow or base. At night it is a pale-blue blob.
- **Weak:** E (den) reads as "some open shelter". A player might guess it is for animals because of the bedding, but it does not read as a creature den.
- **Unreadable at this distance:** F (farm plot). It is small and low, and there is nothing growing in it. At night it nearly disappears.

At night the untextured pale-blue primitives (B's body, D and E's roof) all fall into one flat colour, which makes them look even more alike.

## 3. Problems that make the frames weaker evidence

- **den_farm_day and den_farm_night:** a large brown faceted object, apparently the camera clipping into a rock or building, fills about the right third of the frame, with a cyan beam running through it. It does not hide E or F, but these frames are not clean evidence. Reshoot without the clipping.
- **row_day and row_night:** the quest panel and hotbar cover the right side, so F is at the panel's edge and too small to judge. The signpost sits in front of the D/E area.
- The player character is centred and covers nothing important. The HUD in general is fine.

## 4. Verdict: **PARTIAL**

- Workbench: **PASS.** It clearly reads as a wooden work table.
- Forge: **PASS.** The anvil and chimney make it unmistakable, but it has no fire or glow at night.
- Kitchen: **MARGINAL.** It is a plain table that depends on a cauldron sitting beside it, and it is easy to confuse with the workbench.
- Altar: **FAIL.** It is a featureless pale-blue cylinder that reads as a canister or bin, not a shrine.
- Den: **MARGINAL / FAIL.** It reads as a pergola or market stall with white lumps under it, not a creature shelter.
- Farm plot: **FAIL.** It is an empty, low crate frame with no soil or crops, and it is barely visible at 8 m, especially at night.

Suggested fixes, judged from the images only:
- Give the altar a stone base and a symbol or glow.
- Give the den walls or a rounded roof plus straw.
- Give the farm plot dark soil with visible rows and sprouts.
- Make the kitchen's own silhouette say "cooking", with a hearth, a hanging pot or smoke.
- Add a lit firebox to the forge at night.
- Reshoot the den/farm frames without the camera clipping.
