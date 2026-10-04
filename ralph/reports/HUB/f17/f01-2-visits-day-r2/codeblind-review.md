# Code-blind review: F17 / F01-2 village visits, DAY walk (r2)

Criterion: "A normal-controller DAY walk reaches every opening NPC, camp and gate."

Inputs reviewed: 15 frames in `frames/` (1280x720, ordinary player camera) and the `[village-walk]` lines of `walk_log.txt`. No source, config, history or other reports were opened.

## Per-target verdict

| Target | Frame | Log (dist / prompt) | What the frame shows | Reached? |
|---|---|---|---|---|
| Grandpa | 004 | 1.45 m / "Talk to Grandpa" | Inside the house, Grandpa standing in front of the player; prompt "Talk to Grandpa". | Yes |
| Tam | 014 | 0.78 m / "Greet Tam" | On the cobble step of the open-front workshop, Tam right beside the player; prompt "Greet Tam". | Yes |
| Mira | 025 | 1.92 m / "Greet Mira" | Inside a shop, Mira behind the counter facing the player; prompt "Greet Mira". The log shows a door opened first ("Open Door"). | Yes |
| Bram | 035 | 1.65 m / "Greet Bram" | Inside the tavern (ALE/STOCK sign, bottle shelves), Bram behind the bar next to the player; prompt "Greet Bram". | Yes |
| Nessa | 041 | 0.80 m / "Greet Nessa" | Outside a cottage door, Nessa (yellow dress) beside the player; prompt "Greet Nessa". | Yes |
| Maren | 043 | 1.18 m / "Greet Maren" | Maren (glasses, brown coat) faces the player on the path. Nessa is still visible at left. Prompt "Greet Maren". | Yes |
| Oskar | 048 | 1.10 m / "Greet Oskar" | Oskar faces the player on the stone step; prompt "Greet Oskar". | Yes |
| the old key | 063, 064 | 1.08 m / "Take the old key" | 063: a gold key hangs on a post beside the player; prompt "Take the old key". 064: the key is gone from the post and the prompt has gone. This agrees with the log line "satchel has key=true". | Yes (taken) |
| gate RoadGate | 067, 068 | 0.51 m / "Try the gate" | 067: the player is at the closed gate under "The Rise" arch; prompt "Try the gate". 068: the gate leaf has swung open and Grandpa's line reads "There you go. The old key still turns." This agrees with "road_gate_open=true". | Yes (opened) |
| Practice Meadow camp | 073 | 2.70 m / "-" | The player stands next to the camp: an A-frame tent, a bedroll, a campfire and a supply sack. The prompt shown is "Strip meadow grass" (a nearby gatherable), not a camp prompt. | Yes (camp visibly at the player) |
| gate TrailGate | 082 | 0.14 m / "-" | The player stands under a gate arch signed **"South Bridge"**, with a fence beside it. No gate prompt; the only prompt is "Call out Bud". | Yes, the gate is at the player. The name does not match: see note 1 |
| gate PondGate | 098 | 0.12 m / "-" | The player stands under an arch signed "The Pond", with the gate leaf swung open in the foreground. No gate prompt. | Yes |

All 12 targets have a frame placing the player at interaction distance (NPCs, key) or physically at the gate/camp. The log ends `PASS ... visited=12 max_off_road_m=0.00`.

## Contradictions, stalls, clipping, hidden targets, broken frames

1. **Name mismatch (TrailGate).** The log calls the target "gate TrailGate", but the in-world sign reads "South Bridge". Without code I cannot confirm that this arch is the intended TrailGate. The frame is consistent with the log position, but a naming check is advisable. This is not counted against the criterion.
2. **No camp/gate prompt for three targets.** The camp, TrailGate and PondGate log `prompt="-"`, so the walk shows the player reached these places, not that they could interact with them. That meets "reaches" as worded. If the criterion intends a camp interaction (for example rest or set up), this evidence does not show it.
3. **Stalls.** None visible. Positions advance steadily between captures. The only paired identical positions are the normal "end"/"reached" pairs. One automatic sidestep was needed near `Trainer_1` on the way out of Mira's shop. A normal player would not notice it, but it shows a body sitting in the doorway path.
4. **Clipping (minor).**
   - 068: the opened RoadGate leaf passes through the left gatepost and overlaps the fence rails.
   - 073: the player's legs sink into a purple bush.
   - 014: the player and Tam nearly overlap (0.78 m).
5. **Occlusion (minor, no target hidden).**
   - 035: a ceiling beam cuts across the top third of the tavern view and a flat grey plane fills the space above it (unfinished interior ceiling or camera above the roof line). Bram is still readable.
   - 048: a house eave fills the left half of the frame. Oskar is still visible.
   - 073: a large boulder fills the lower right. The camp is still visible.
6. **Cosmetic.**
   - The clock reads "Day 1 · 08:00" in every frame, while food drops from 100% to 97%. The clock may be pinned for the capture. Worth confirming that this is intentional.
   - The campfire in 073 is a flat, low-poly orange flame shape that looks placeholder next to the rest of the scene.
   - A cyan quest beam cuts through the tavern interior in 035.
7. **Broken frames.** None. All 15 frames render fully, with HUD and lighting intact.
8. **Frame/log contradictions.** None, apart from the sign name in note 1. The key disappearance and gate opening in the frames match the log.

## Verdict: PASS

The DAY walk reaches every target:
- All seven opening NPCs, each shown with its own named interaction prompt at 0.78–1.92 m.
- The old key, taken, with before and after frames.
- RoadGate, tried and opened with the key.
- The Practice Meadow camp, the TrailGate arch and the PondGate arch, each with the player physically at the structure.

The frames contain no stall, broken frame or hidden target. Open follow-ups, none of which blocks this criterion:
- Confirm that the "South Bridge" arch is TrailGate.
- Decide whether the camp needs its own prompt as evidence.
- Fix the RoadGate leaf clipping through its post.
- Fix the grey void above the tavern ceiling.
