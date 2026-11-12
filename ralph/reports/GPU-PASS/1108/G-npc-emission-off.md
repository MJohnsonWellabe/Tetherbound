# GPU arm round 1108, G-npc-emission-off: captain_a and captain_b body emission off (live vs arm, GPU High plus ghost-glow, mapped)

**Verdict: no visible change; does not ship.**
- Gain is 0.00 on F41#15 and F39#29, and −0.04 on F41#7. No judge preferred the arm on any row.
- **All three judges still saw Marrow's face blown out to white on both sides.**
- This is what `ITEM-NPC-ALBEDO/CAUSE.md` predicts. Turning off the imported emission does nothing while the captain rank's **additive white emission floor** (`npc_ranks.json` `ranks/captain.emission_floor` 0.18, palette `#ffffff`) turns emission straight back on. Remember too that the metallic fix makes the body fully diffuse.
- **Next arm:** the same overlay plus `ranks/captain.emission_floor: 0.0`.

| Row | Live | Arm | Gain | Prefer arm |
|---|---|---|---|---|
| F41#15 Marrow and Nysa | 5.88 | 5.88 | 0.00 | 0/3 (3 level) |
| F41#7 Marrow trainer | 6.34 | 6.30 | −0.04 | 0/3 (2 level) |
| F39#29 Nalia and Nerissa | 5.13 | 5.13 | 0.00 | 0/3 (3 level) |

**Per judge, mapped (live → arm):**
- F41#15: 6.09 / 5.59 / 5.97, identical on both sides.
- F41#7: 6.59 / 6.22 / 6.22 → 6.47 / 6.22 / 6.22.
- F39#29: 4.84 / 4.84 / 5.71, identical on both sides.

**What the judges saw (all three):**
- Marrow's head and face are a white glow in every Marrow frame, on both sides.
- Nerissa is a small, pale figure behind the player's head in a dark, flat chamber; the framing hides her.
- The Stormwood deck is a flat lavender wash.
- One judge also saw a flat lavender slab on the left of the deck in one frame.

## Method
- **Frames:** `tb/gpu-frames-1108` (fa00cbf2), GTX 1060, Forward+ High 1920x1080. Live is main ba6778f45 plus the ghost-glow change (manifest note), shared by both NPC arms.
- **Batch:** one batch `G-npc` with 11 live-vs-arm pairs, three fresh code-blind judges, standard JUDGE_PROMPT and 3 pinned anchor pairs. The sides were shuffled with the key kept outside.
- **Fit:** `calibrate.py` linear, slope 1.254, intercept −0.932, r 0.846, anchor RMSE 0.615. Confirming batch; no warnings.
- **Scores:** on this batch's scale; read gains within the batch.
- **Judged:** LANE-SCOUT, 9 Nov 2026 ~07:10 UTC.
