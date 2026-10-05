# Code-blind visual judge: homestead stations (r11)

Criterion: "Stations read as distinct objects at the normal camera."
Inputs: the 10 PNGs in this folder only. I read no source, docs or other reports.

## 1. Per-image inventory (blind guesses)

**forge_kitchen_day / forge_kitchen_night** (close, from the front). Left to right:
- A wooden table with a vise or clamp: **workbench**. Clear.
- A grey block furnace with a chimney, a glowing yellow mouth, an anvil on a stump and a quench bucket: **forge**. Clear. The glow carries it at night.
- A small side table beside a black cauldron on a lit fire ring under a frame: **cooking station**. Clear, and the fire glow reads at night.
- A white cross or obelisk on a plinth, with two candelabras: **shrine/altar**. Clear.
- At the right edge, part of a red-roofed building and a barrel. Cut off, so I can't call it.

**altar_day / altar_night and den_day / den_night** (close):
- Cauldron with table: **cooking station**.
- White cross with candelabras: **shrine/altar**.
- A small red-roofed hut with an arched black opening, a paw-print sign, a round cushion or bed, a bowl and a basket: **animal/creature shelter**. Clear, the paw sign gives it away.
- A raised wooden bed with green sprouts: **farm plot**. Readable, though small and partly behind the HUD and objective beam on the right.
- In den_*, a grey block cut off at the left edge (the forge). Not identifiable.

**farm_day / farm_night** (close):
- Altar at left, den in the centre-left (clear).
- Raised planter with rows of green seedlings: **farm plot**. Clear.
- Behind it are a tent, a campfire and wild creatures. These are village or camp props, not stations.

**row_day / row_night** (about 11 m, the "normal camera"). The row is seen from the **back**, so left and right are swapped compared with the close shots:
- Far left, a low raised bed (about 300,500): **farm plot**? It is tiny and half hidden by the grass. I could only guess it, and at night it is almost invisible.
- A red-roofed box with plain blank walls (about 540,460): **unclear**. It looks like a shed or outbuilding. From this side you can't see the door, paw sign, bed or bowl. At night it is a solid black silhouette.
- White cross (about 830,480): **shrine/altar**. Clear day and night.
- Cauldron on a fire with a side table (about 1050,480): **cooking station**. Clear, and the fire glow reads at night.
- Grey stacked blocks with a tall chimney (about 1350,450): **unclear**. With no visible glow or anvil from behind it reads as a stone block or chimney stub, not a forge. At night it is a flat blue-grey block.
- A long wooden table with benches (about 1610,485): it reads as a **picnic table or bench**. If this is the workbench, it looks just like the village picnic table. If it isn't, then **no workbench is visible in the row shot at all**.

## 2. Can a player tell the six apart?

- **From the front, at close range: yes.** All six are distinct in silhouette and props, day and night, and none is mistaken for another. Fire glow on the forge and kitchen helps at night.
- **In the 11 m row shot: no.** Only the altar and the kitchen read. The forge and the den lose their identifying features because they are seen from behind. The farm plot is too low and small to pick out of the grass at that distance. The workbench is either hidden or looks just like the village picnic table.
- Night makes the den (black mass) and farm (lost in the grass) worse. The forge's glow faces away from the row camera.

## 3. Problems with the frames as evidence

- The row shot faces the back of the stations. That makes it a worst case and not representative of how a player walking up would see them. It also means the criterion's "normal camera" frame is the one where most stations fail.
- The objective beam and minimap (right side) partly cover the farm plot and the area to its right in altar_*, den_* and farm_*.
- The close shots crop neighbouring stations (forge in den_*, den in forge_kitchen_*), so no single close frame shows all six.
- The den and forge are flat, untextured primitives (the den's door is a Pac-Man-shaped black cut-out). They still read from the front, but they clash with the textured village around them.
- Daytime HUD text and quest panels don't cover any station in the row shot.

## 4. Verdict: **PARTIAL**

| Station | Result | Reason |
|---|---|---|
| Workbench | FAIL (row) / PASS (close) | Close: clear wooden table with a vise. Row: not visible, or identical to the village picnic table. |
| Forge | FAIL (row) / PASS (close) | Close: anvil and glowing furnace. Row: seen from behind as plain grey blocks with no glow. |
| Kitchen | PASS | Cauldron on a lit fire reads at every distance, day and night. |
| Altar | PASS | White cross and candelabras read at every distance, day and night. |
| Den | FAIL (row) / PASS (close) | Close: paw sign, bed and bowl make it a creature shelter. Row: plain shed back wall, black at night. |
| Farm plot | FAIL (row) / PASS (close) | Close: clear planter of seedlings. Row: too low and small to find in the grass, almost invisible at night. |

To pass, the 11 m row capture should face the stations' fronts, or the stations need identifying features on every side (forge glow or a chimney spark, a paw sign or opening on more than one face of the den). The farm plot needs height or a border that stands out from the grass, and the workbench needs a silhouette unlike the village picnic table (tools or a vise visible from every side). Then reshoot day and night.
