# F01#3: normal-controller NIGHT walk reaches every opening NPC, camp and gate

**Verdict: FAIL** (code-blind judge). The walk mechanically reached all 12 targets; the judge confirmed 11 of them and could not confirm the camp, and rated three NPCs only marginally readable at night.

- **Commit:** `9a5a43655620252c98dd9fde9bd8544d6c9381f5` (origin/main, PR #541 merge)
- **Run:** 2026-10-05, 14:07 to 15:26 UTC. Local 4 vCPU, Xvfb, Mesa llvmpipe, Compatibility renderer.
- **Command:**
  ```
  xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 \
    --resolution 1280x720 --script tests/capture_village_walk.gd -- \
    --time=night --route=visits --from-title --capture-dir=<abs dir>
  ```
  `--from-title` plays the real opening (title, wake, starter, naming, walk-out, first catch) in the same world, so no flags are written and the player is not placed.
- **Run note:** the first launch wrapped the walk in `timeout 3600`. Under software rendering it was about half done at 51 minutes, so I killed the `timeout` wrapper (the Godot process kept running untouched) and let the walk finish. Its exit code was therefore not captured. Its own receipt line is the verdict: `[village-walk] PASS route=visits time=night captures=103 max_off_road_m=0.00 visited=12`.

## Engine receipts (`night-walk-receipts.txt`)

All 12 targets were reached on the road band, with a maximum of 0.00 m off-road. For each NPC, its own prompt won the interaction arbiter.

| Target | Distance (m) | Prompt |
|---|---|---|
| Grandpa | 1.30 | Talk to Grandpa |
| Tam | 1.05 | Greet Tam |
| Mira | 1.75 | Greet Mira |
| Bram | 1.98 | Greet Bram |
| Nessa | 0.82 | Greet Nessa |
| Maren | 1.32 | Greet Maren |
| Oskar | 1.31 | Greet Oskar |
| Old key | 1.34 | Take the old key (taken with interact) |
| Practice Meadow camp | 2.51 | none (counted by position; arrival radius 7 m) |
| RoadGate ("The Rise") | 0.49 | Try the gate (opened with the key) |
| TrailGate ("South Bridge") | 0.34 | none |
| PondGate ("The Pond") | 0.31 | none |

## Code-blind judge

A fresh agent saw only 21 frames and the criterion text: the 13 arrival frames, the start, the key, the closed gate and six travel frames. It saw no code. Its verdict was **FAIL**:

- **Reached YES:** all seven NPCs, the key and all three gates. Travel frames show the road clearly; lit windows, lamps and the minimap help, and no frame is too dark to navigate.
- **Practice Meadow camp: CAN'T TELL, MARGINAL.** A tent, bedroll and fire are beside the trainer, but the only prompt is "Strip meadow grass". Nothing on screen marks the camp as arrived or interactable, a large rock fills the lower right, and the flame is a flat untextured shape.
- **Tam: MARGINAL.** Dark clothing against a dark stone wall; his face is barely visible.
- **Maren: MARGINAL.** Lit on one side only, against dark trees. A brighter villager nearby competes with her as the apparent target.
- **Nessa: MARGINAL.** Almost entirely hidden behind the trainer at the interaction distance (Bram partly as well).
- **Other notes:** the cyan quest beam renders through interior ceilings (Mira, Bram), and untextured white and pink boxes appear in the Oskar frame. The judge also flagged the gate signs not matching the file names. That is not a fault: `village_boundary.json` labels RoadGate "The Rise", and TrailGate is the South Bridge exit.

## Root cause (for the coordinator; no product code changed here)

1. **Camp has no arrival cue.** Within the camp radius, a gather node (meadow grass) wins the interaction arbiter, and the camp has no prompt, marker or HUD line of its own. The judge cannot tell the player has reached a camp. Fix area: Practice Meadow camp dressing and prompt priority, or a camp-arrival line (WORLD / UX).
2. **No night fill light on villagers.** Dark-clothed NPCs (Tam, Maren) lose their silhouette at 23:00 under Compatibility. Fix area: village night lighting or NPC rim light (ART_DIRECTION, scene-level; Claude lanes may do this).
3. **Trainer occludes the NPC at prompt distance.** The exploration camera sits behind the trainer, so a doorway NPC (Nessa, Bram) is hidden when the prompt appears. Fix area: camera framing on interaction, or the NPC stand spots (UX / COMBAT camera).

Frames are not committed (owner decision #12: new evidence images do not go in the repo). They were judged locally from the run's capture directory.
