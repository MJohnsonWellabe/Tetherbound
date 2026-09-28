# F01#2 / F01#3 code-blind visual verdict: walk 122a8efb

Judge inputs: only the JPG frames in `day_122a8efb/` and `night_122a8efb/`, their `run_village_walk_lines.txt`, and `docs/reference/tetherbound-meadows-keyart.png`. I did not open any source, config, test, commit or report.
Criteria applied: the functional and readability clauses only. Each target has to be reached and has to be identifiable in the frames as what it is. Bars A/B are deferred and do not decide the verdict.

## 1. Reach tables

### Day (clock shows Day 1 · 08:00)

| Target | Frame(s) | Reached? | Evidence in the image |
|---|---|---|---|
| Grandpa (indoors) | day_002_end, day_003_reached-grandpa | YES | He is inside a plastered house room with a window and wardrobes. White-haired elder in a green vest, face visible. Prompt reads "Talk to Grandpa". |
| Bram (inn) | day_013_end, day_014_reached-bram | YES | He stands behind a bar counter with bottle shelves and a "…ALE · STOCK" sign, so the room reads as an inn. Prompt reads "Greet Bram". |
| Tam | day_021_end, day_022_reached-tam | YES | Silver-haired villager beside the player at a stone-and-timber doorway. Prompt reads "Greet Tam". |
| Mira (shop) | day_026_end, day_027_reached-mira | YES | She is behind a counter in a small room. Prompt reads "Greet Mira". The room reads only weakly as a shop: the counter is a bare untextured box and no goods are shown. |
| Oskar | day_033_end, day_034_reached-oskar | YES | Dark-haired villager in a vest at the paddock fence. Prompt reads "Greet Oskar". |
| Halda | day_041_end, day_042_reached-halda | YES | Blue-haired villager in a green jacket beside the player. Prompt reads "Greet Halda". |
| The old key | day_049_end, day_050_take-the-old-key, day_051_reached-the-old-key | YES | In 049 and 050 a clearly key-shaped gold key hangs on a post by The Rise gate, and the prompt reads "Take the old key". In 051 the post is empty. |
| RoadGate (The Rise) | day_053_end, day_054_at-gate-roadgate_-closed, day_055_reached-gate-roadgate | YES | The arch sign and a signpost both read "The Rise". The gate is closed in 054 ("Try the gate") and swung open in 055, with the line "There you go. The old key still turns." |
| Practice Meadow camp | day_069_end, day_070_reached-practice-meadow-camp | **PARTLY** | The player stands at a small cluster: crate, barrel, grain sack and a tiny untextured orange cone that stands in for a fire. There is no tent, bedroll, seating, sign or interaction prompt (the log shows prompt "-"). The only "Practice Meadow" text is an objective-beacon slab clipping the left screen edge, and only "…adow" is legible there. The scene reads as a supply cache with a small fire, not clearly as a camp. |
| TrailGate (South Bridge) | day_082_end, day_083_reached-gate-trailgate | YES | The arch sign "South Bridge" and a matching "South Bridge" signpost are both visible. The gate stands open and the player is under the arch. |
| PondGate (The Pond) | day_096_end, day_097_reached-gate-pondgate | YES | The arch sign reads "The Pond". The gate stands open and the player is on the path under the arch. |

### Night (clock shows Day 1 · 23:00)

| Target | Frame(s) | Reached? | Evidence in the image |
|---|---|---|---|
| Grandpa (indoors) | night_003_end, night_004_reached-grandpa | YES | Same room, with Grandpa fully visible in 004 and the prompt "Talk to Grandpa". In 003 he is hidden behind the player, but 004 resolves that. |
| Bram (inn) | night_013_end, night_014_reached-bram | YES | Bar counter with bottle shelves. Prompt reads "Greet Bram". |
| Tam | night_021_end, night_022_reached-tam | YES | Villager at the doorway, readable under moonlight. Prompt reads "Greet Tam". |
| Mira (shop) | night_026_end, night_027_reached-mira | YES | Behind the counter. Prompt reads "Greet Mira". The room has the same weak shop read as in the day walk. |
| Oskar | night_033_end, night_034_reached-oskar | YES | His figure is dark but has a clear silhouette against the lit grass. Prompt reads "Greet Oskar". |
| Halda | night_041_end, night_042_reached-halda | YES | Villager beside the player. Prompt reads "Greet Halda". |
| The old key | night_049_end, night_050_take-the-old-key, night_051_reached-the-old-key | YES | The gold key is clearly visible and glowing on the post in 049 and 050, with the prompt "Take the old key". The post is empty in 051. |
| RoadGate (The Rise) | night_053_end, night_054_at-gate-roadgate_-closed, night_055_reached-gate-roadgate | YES | The "The Rise" arch sign is legible. The gate is closed in 054 and open in 055, with the same key line. |
| Practice Meadow camp | night_069_end, night_070_reached-practice-meadow-camp | **PARTLY** | The player is at the crate, barrel and sack cluster, and a warm fire glow is the main cue. The hotbar panel covers the glow's right half. Two wild boars fill the left of the frame. The beacon slab, reading "NEXT • Practice Meadow", sits over the camera at the left edge. There is no tent, bedroll, sign or prompt. |
| TrailGate (South Bridge) | night_082_end, night_083_reached-gate-trailgate | YES | The "South Bridge" arch sign and signpost are both legible. The player is under the open gate. |
| PondGate (The Pond) | night_096_end, night_097_reached-gate-pondgate | YES | The "The Pond" arch sign is legible. The player is under the open gate. |

## 2. Verdicts

**F01#2 (day walk): FAIL.**
- The walk reached all eleven targets (the log ends with `PASS … visited=11`, and every frame puts the player at the target).
- Ten of the eleven are clearly identifiable: 6 NPCs by presence plus name prompt, the key as a visible gold key that disappears after pickup, and 3 gates by their destination signs.
- The decisive failure is the Practice Meadow camp. Frame day_070 does not show an unambiguous camp. It has no camp structure or bedding, the "fire" is a small untextured cone, and there is no camp name or prompt. The only label is a beacon slab clipped at the screen edge, with "…adow" legible.

**F01#3 (night walk): FAIL.**
- Same as the day walk: all eleven targets were reached, and ten are clearly identifiable at night. Signs, prompts and the glowing key all read well in the dark.
- The decisive failure is again the camp. In night_070 the fire glow is the only camp cue, and the hotbar panel covers half of it. The boars and the camera-clipping beacon fill the rest of the frame.

Both rows are one fix away from passing. I would call the camp a clear YES in each walk if it had an unambiguous camp read: a proper campfire (logs or stone ring) plus a bedroll, tent or lean-to, or a camp name or prompt. The arrival frame also has to show it without the beacon over the camera or the hotbar over the camp. If the owner rules that fire plus supplies already counts as a camp, both rows would PASS on the remaining evidence.

## 3. Remaining defects, ranked (functional and readability first)

1. **The camp does not read as a camp** (day_070, night_070). It is a supply cluster with a tiny fire: an untextured orange cone by day and a glow at night. There is no shelter, bedding, name or prompt. This is the only item blocking both rows.
2. **The objective beacon clips into the camera at the camp** (day_070, night_070). A translucent cyan slab covers about the left 15% of the frame. Its "NEXT • Practice Meadow" label is legible only by accident at night and is cut to "…adow" by day. The same beam is visible from a distance in day_042 and night_042.
3. **The hotbar panel occludes the mid-right of the world** (every frame, worst in night_070 and day_070). The five-slot panel sits at about y 370–550 on the right and cuts off the camp's fire glow and sack at night. It also covers the right side of every NPC and gate composition.
4. **The key pickup has no confirmation on screen** (day_051, night_051). The key simply vanishes from the post. No toast or item callout appears, and the satchel HUD does not change, so a player cannot tell from the frame that the key was taken. The only confirmation comes later, at the gate (055).
5. **Night interiors are lit like day** (night_004, night_014, night_027; also night_003). Windows glow white at 23:00, and the player and NPCs look bleached or over-exposed indoors. This does not stop identification, but it undercuts the night read indoors.

## 4. Bars A/B notes (deferred, non-blocking)

Against the Meadows key art, the exteriors get the broad palette right: rolling hills, fences, dirt roads, timber-and-stone houses, a readable moonlit night. The main shortfalls are these:
- Tree canopies render as noisy, dark or red-speckled leaf cards rather than soft oak masses (day_034, day_042, day_070).
- The interiors are sparse and use primitives. Mira's counter is an untextured box on a grass-textured shop floor (day_027, night_027). Wardrobes are pure-black silhouettes (day_003, night_004). The inn lantern is an oversized black-framed box (day_014).
- The camp and settlement props lack the cozy dressing the key art promises (well, banner, warm hearth).
- The night gates' lanterns barely glow, so the arches read as black frames (night_083, night_097).
- Night grass lighting is good, but interiors do not respond to night at all.
