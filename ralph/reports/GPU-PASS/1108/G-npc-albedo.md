# GPU arm round 1108, G-npc-albedo: albedo-only grades on the ghosted NPC profiles (live vs arm, GPU High plus ghost-glow, mapped)

**Verdict: essentially flat.**
- One row passes the ship rule narrowly: **F41#15, +0.17, 3/3**.
- Every other row is level or within 0.17 either way, and F39#26 goes slightly down (−0.17, 0/3).
- **The NPC ghosting is not an albedo problem.** All three judges still call Bex, Irva, Daro, Adair, Iona, Rowan and Nalia semi-transparent or ghosted on both sides. Marrow's face is still blown out to white.
- **Recommendation:** don't ship this overlay as a fix for ghosting. The F41#15 gain is small, and the judges' notes give no visible reason for it.

| Row | NPCs | Live | Arm | Gain | Prefer arm | Ship rule |
|---|---|---|---|---|---|---|
| F41#15 | Marrow, Nysa (captain_a) | 5.88 | 6.05 | +0.17 | 3/3 | Passes (small) |
| F39#18 | Daro, Bex, Irva (young_trainer, grunt_c) | 5.55 | 5.59 | +0.04 | 1/3 (2 level) | No |
| F39#13 | camp NPC (innkeeper) | 5.76 | 5.76 | 0.00 | 0/3 (3 level) | No |
| F39#29 | Nalia, Nerissa (courier, captain_b) | 5.13 | 5.13 | 0.00 | 0/3 (3 level) | No |
| F41#7 | Marrow (captain_a) | 6.34 | 6.34 | 0.00 | 0/3 (3 level) | No |
| F41#20 | Fenn (trader) | 6.34 | 6.34 | 0.00 | 0/3 (3 level) | No |
| F41#11 | portrait identity | 6.88 | 6.84 | −0.04 | 0/3 (2 level) | No |
| F39#26 | Adair, Iona, Rowan (field_researcher, trader) | 5.80 | 5.63 | −0.17 | 0/3 (1 level) | No |

**What the judges saw (all three):**
- The Tidewake speakers are ghost-translucent on both sides, and the player's head and back crowd the frame.
- Fenn and Oswin share one model and one portrait (F41#20 dialogue reuse).

**What this rules out:**
- The albedo grade, and the `day_rim` / `idle_relax` strip on field_researcher and grunt_c, are ruled out as the cause of the Tidewake ghosting.
- The remaining suspects, from `ITEM-NPC-ALBEDO/CAUSE.md`:
  - the rank emission floor, for the grunts and officers;
  - the dialogue camera `occlusion_fade` (`fade_transparency` 0.8), which two judges again tie to the speaker;
  - the glow itself.
- A cheap test: one capture of an F39#18 or F39#26 dialogue stand with `camera.json occlusion_fade.enabled: false`.

## Method
- **Frames:** `tb/gpu-frames-1108` (fa00cbf2), GTX 1060, Forward+ High 1920x1080. Live is main ba6778f45 plus the ghost-glow change (manifest note), shared by both NPC arms.
- **Batch:** one batch `G-npc` with 11 live-vs-arm pairs, three fresh code-blind judges, standard JUDGE_PROMPT and 3 pinned anchor pairs. The sides were shuffled with the key kept outside.
- **Fit:** `calibrate.py` linear, slope 1.254, intercept −0.932, r 0.846, anchor RMSE 0.615. Confirming batch; no warnings.
- **Scores:** on this batch's scale; read gains within the batch.
- **Judged:** LANE-SCOUT, 9 Nov 2026 ~07:10 UTC.
