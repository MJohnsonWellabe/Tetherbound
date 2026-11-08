STATUS: parked
BRANCH: tb/item-f36-29  HEAD: see the commit that adds this READY (pushed head)

Lane LANE-MESHY, queue row 13 (coordinator 8 Nov): F36#29 Innkeeper (Wilhelm) body and face. No config change.

## Stand
- The GPU 5.90 came from the F36(0) NPC face round (matched-camera GPU Medium close frames, native Windows). Its CPU equivalent is `tools/_capture_character_cast.gd`: an identical 3 m portrait camera for every character, front and three-quarter, on a flat stage, built through `character_model.gd`, which applies `character_body_flags.json`.
- The cast tool writes a fixed `shots/characters/` folder, so each round's `round.json` was assembled from its captures (`qj_job.json` holds the stand). The packet and finish steps are the standard `quick_judge.py` ones: JUDGE_PROMPT verbatim, three fresh code-blind judges, pinned anchors, calibrate.py.

## Noise floor (session floor for this lane)
- `qj/noise-r0/`: live vs live (two separate live captures, 0.1-0.3% of pixels different). Mapped 7.36 -> 7.36, **N = 0.00**; all three judges scored both sides identically (6.3 / 6.0 / 6.2). Fit: slope 1.62, r 0.89, RMSE 0.54.
- Floor = max(N, 0.3) = **0.3**. This N is judge noise only; live-world rows (spawns, wind) may need their own.

## Arm round
- `qj/look-r1/`: `npc_vis_look_innkeeper` ON (graded albedo, day rim 0.25, relaxed idle) vs live. It changes 11.6% (front) and 10.8% (three-quarter) of pixels; sheet `_sheet_visibility.jpg`.
- Result: mapped **6.78 -> 6.64 (-0.14)**. Raw live 5.7 / 6.2 / 5.5, arm 5.3 / 5.7 / 6.0.
- Two of three judges preferred live: on the arm the skin reads "paler, chalkier" and the cloth "flatter, lower-contrast". The third preferred the arm for its "warmer skin, better value separation".
- **Stays OFF.** `npc_vis_body_innkeeper` (the graded albedo alone) was already flat on dialogue frames (VIS-STORMWOOD `qj_inn`). This item's grade approach has now failed twice, so it is parked.

## Judges' asks (all three)
- An identity-preserving refinement of the face texture: sharper eyes and mouth, skin tone variation without chalk, and distinct cloth and leather values. This is new art.
- A relaxed idle pose.

**Next idea:** a Blender texture pass on the innkeeper atlas, limited to the face and eyes, that keeps the warmer live value range rather than lifting it. Judge it on this cast stand.

## Tests
- No config or code changed, so no test applies. Files: `ralph/reports/LANES/ITEM-F36-29/**`.
