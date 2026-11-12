# GPU arm round 1108, G-npc-floor-grunt-officer: grunt and officer emission floor off, captain untouched (live vs arm, GPU High plus ghost-glow, mapped)

**Verdict: flat. Mean gain −0.02 over 4 rows; nothing clears the ship rule with a meaningful gain.**
- F39#29 (+0.12, 2/3) technically passes, but it is within this batch's noise.
- **F39#18 (Bex, Irva): −0.04 here**, against +0.28 (3/3) for the all-ranks arm in `G-npc-floor.md`.
  - The all-ranks arm also turned off the captain floor and the captain_a and captain_b emission. This one changes only grunt and officer.
  - So the earlier F39#18 gain did not come from the grunt floor, or it was within run-to-run noise. Single-row gains of 0.1–0.3 are not reliable in these arms.
- **The ghost look is unchanged.** All three judges again call every Tidewake speaker (Adair, Iona, Rowan, Bex, Daro, Irva, Nalia) half-transparent, with "the sand shows through their bodies".
  - Two judges again call it a camera fade applied to the speaker by mistake.
  - With the albedo grade, emission opt-out, rank floor and day rim all tested and flat, the **dialogue `occlusion_fade`** (`camera.json`, `fade_transparency` 0.8) is the strongest remaining suspect for the Tidewake speakers.
  - One capture with `occlusion_fade.enabled: false` on an F39#26 or F39#18 stand would settle it.

| Row | Live | Arm | Gain | Prefer arm | Note |
|---|---|---|---|---|---|
| F39#29 Nalia and Nerissa | 5.04 | 5.16 | +0.12 | 2/3 (1 level) | Nerissa still hidden behind the player |
| F41#8 Stormwood named silhouettes | 4.84 | 4.88 | +0.04 | 1/3 (2 level) | Silhouettes still repeat (PRESENT 2/3) |
| F39#18 Daro, Bex, Irva | 5.76 | 5.72 | −0.04 | 2/3 | Contradicts the all-ranks +0.28 |
| F39#26 Adair, Iona, Rowan | 6.12 | 5.92 | −0.20 | 0/3 (1 level) | The two captures differ in which creature wandered into frames 2–3 (an Aquaryn on one side, a turtle and crab on the other). That run-to-run difference, not the arm, drives the score. |

**Per judge, mapped (live → arm):**
- F39#29: 5.32 / 4.35 / 5.44 → 5.56 / 4.35 / 5.56.
- F41#8: 4.96 / 4.72 / 4.84 → 5.08 / 4.72 / 4.84.
- F39#18: 6.16 / 5.08 / 6.04 → 5.80 / 5.20 / 6.16.
- F39#26: 6.52 / 5.32 / 6.52 → 6.16 / 5.32 / 6.28.

## Method
- **Frames:**
  - Arm: `G-npc-floor-grunt-officer` (beddece2), main ba6778f45 plus ghost-glow plus `COORDINATOR/overlays/npc_floor_grunt_officer.json`.
  - Live: the G-npc-albedo live set; for F41#8, `G-npc-floor-grunt-officer-live` (1c8afe85).
  - All on a GTX 1060, Forward+ High.
- **Batch:** one batch, `G-go`: 4 pairs plus 3 pinned anchor pairs, three fresh code-blind judges, standard JUDGE_PROMPT, sides shuffled with the key kept outside.
- **Fit:** slope 1.206, intercept −0.469, r 0.827, anchor RMSE 0.649. Confirming batch; no warnings.
- **Data note:** one judge's JSON carried a stray `bar_b_placeholder` key on one side. Its score was read normally.
- **Judged by:** LANE-SCOUT, 9 Nov 2026 ~09:00 UTC.
