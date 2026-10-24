# F22#4 Riverwatch on main: GPU pass (24 Oct 2026)

**Verdict: REOPENED.**
- **Medium (Forward+) maps to 5.10.** All three judges still mark the captain's Brooktail **ghost or washed-out: PRESENT ×3**.
- **Low (Compatibility) maps to 6.39**, ghost FIXED ×3.
- Both are below 7.5.

**The cause on main is not the tell aura.** Main's renderer-aware aura (`aura_renderer_scale`: Forward+ rim ×0.3, no omni light) works as designed. The pale grey-mauve boss shows in every frame, including i05 and the after frame, outside any tell.

The cause is the **creature emission floor** (`data/config/art.json` `creature_emission_floor: 0.08`, the always-on base value from MEADOWS-0912).
- What it does: `creature_body.gd::_night_floor_material` gives every plain-PBR creature an **additive** emission sourced from its own albedo texture (white, op ADD, energy 0.08).
- On Compatibility this is a mild lift.
- On Forward+ it washes the captain's dark brown fur to a milky grey that reads as see-through.
- **With emission turned off and nothing else changed, Medium renders a solid brown otter that matches Low.**

## Runs (main 7b5d351da, GTX 1060, 1280x720)

- **Capture:** `tools/art_pipeline/capture_named_fight.gd --trainer=captain_riverwatch --live-member=captain_riverwatch:4 --ally=ripplet --frames=12 --interval=0.5 --tell-frames --keep-alive`, the same as r13 (`../VERDICT.md`). Queue: `f22_main_queue.ps1.txt`.
- **Judged arms:**
  - Medium r1 and r2: 23 frames each;
  - Low r2: 23 frames. Low r1 missed its last strike frame, so it was re-run.
- **Probe:** `f22_ghost_probe.gd.txt`, local and never committed. It runs the same capture, dumps the captain's bound materials, and per arm forces one material change every frame.

| Arm (Medium unless noted) | Boss at i05 and after (no tell) |
|---|---|
| shipped | pale grey-mauve, washed out |
| forced opaque, overlays dropped | unchanged (pale) |
| metallic 0 (texture dropped) | unchanged (pale) |
| roughness 1 (texture dropped) | unchanged (pale) |
| **emission off** | **solid brown, matches Low** |
| matte (metallic 0, roughness 1, emission off) | solid brown |
| Low shipped | solid brown |

**Material dump (`material_dump_medium.txt`, `material_dump_low.txt`):**
- The bound surface override is a StandardMaterial3D, opaque, `emission=true emission_colour=white emission_energy=0.08 emission_op=0 (ADD)`, with the emission texture equal to the albedo texture.
- **It is the same on Low.** The renderer, not the data, makes the difference.
- The GLB's metallic-roughness texture means are metallic 0.013 and roughness 0.91, so the material is not metal or gloss. This matches GHOST.md's earlier correction.

## Yardstick (batch b2, shared with the F17#6 diagnostic)

- **Batch:** `../../yardstick-b2-1024/`, built with `anchor_tiles.py --pairs 4 --include f36_0_npc:C1`.
- **Judges:** three fresh code-blind judges, each given `JUDGE_PROMPT.md` (main) verbatim.
- **Calibration:** slope 1.076, intercept 0.614, r 0.94, anchor RMSE 0.45. Confirming batch, no warnings.
- **Sets:** Medium r1 and Medium r2, each paired with Low r2.
- **Recorded defects:** r13's three (boss size, magenta telegraphs, no impact) plus the GPU ghost.

| Side | Raw (j1/j2/j3) | Mapped per judge | **Mapped mean** |
|---|---|---|---|
| Medium r1 | 4.5 / 4.0 / 4.0 | 5.46 / 4.92 / 4.92 | **5.10** |
| Medium r2 | 4.5 / 4.0 / 4.0 | 5.46 / 4.92 / 4.92 | **5.10** |
| Low r2 (both sets) | 5.5 / 5.3 / 5.3 | 6.53 / 6.32 / 6.32 | **6.39** |

The two Medium runs scored identically, so the fight timeline variance between runs did not move the score.

**Recorded defects (Medium, both sets, j1/j2/j3):**
- ghost: **PRESENT ×3**;
- magenta: FIXED ×3;
- impact: FIXED ×3. The ghost side's white splashes read more strongly than Low's bluer ones;
- boss size: FIXED / PARTIAL / PARTIAL.

**On Low:** ghost FIXED ×3, impact PARTIAL ×3.

**What every judge still names on both renderers:**
- the player's Ripplet is lost under the HUD and the rings;
- the HUD covers about a third of the frame;
- the grade reads yellow-green (Low) or muddy olive (Medium).

## Suggested fix (Creatures/Look lane, then Fights to re-judge)

- **Make the creature emission floor renderer-aware,** the way the aura already is:
  - on Forward+/Mobile, scale `creature_emission_floor` down hard by day, or drop the base 0.08 so only the night key (0.22) applies;
  - keep Compatibility as shipped.
- **Re-check other plain-PBR creatures.** This floor applies to every one of them in Meadows, Cloudreach and Tidewake. Tidewake's own config already records the night version of this as "flat white ghosts" (`night_creature_floor`). A matched day capture of a wild Meadows creature at Medium, with the floor at 0.08 and at 0, would show how wide it is.
- After the fix, re-run this capture at Medium. The emission-off arm suggests the ghost defect clears, and Medium should then land near Low's 6.39. The remaining asks (HUD footprint, the player's creature at combat distance) are separate.

## Files

- `_sheet_f22_4_main_ghost.png`: i05 at Medium (shipped, emission off, roughness 1) and at Low (78 KB).
- `material_dump_medium.txt`, `material_dump_low.txt`: probe dumps of the captain's bound materials.
- `f22_ghost_probe.gd.txt`, `f22_main_queue.ps1.txt`: the local tools.
- Yardstick: `../../yardstick-b2-1024/` (`key.json`, `sets.md`, `candidates.json`, `j1`–`j3`, `batch.json`, `mapped.json`).
