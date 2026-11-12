# GPU rechecks 1108: F39#21 victory focus and F38#1 faint (GPU High, mapped)

## F39#21 named-fight victory hierarchy: `G-recheck-f39-21` (main aa23cda5b, `hud.json victory_focus` on)

**Verdict: improved, +0.96 with 3/3 judges preferring the recheck. Not at 7.5 (6.66).**
- **What victory_focus does:** with it on, the exploration HUD (team roster, quick-item bar, key-hint bar, "Gather Reef Stone" prompt) is gone during the win. Only health, food and the "Officer Venn defeated" panel remain.
- **Recorded defect:** FIXED (1 judge) or PARTIAL (2) on the recheck, against PRESENT 3/3 on the old frames.
- **Two things still hold it back (all three judges):**
  - **The reward is still a small top-right toast** with no hero beat. Next scene change: centre and enlarge the reward card.
  - **A flat, untextured grey plane runs across the foreground in the aftermath frame** (`venn_resolve__aftermath-142_53`). It reads as a water-plane or terrain-hole artefact. All three judges flagged it; worth checking on current main.
- **Nerissa's win frame** is still null; her seat fix is in batch 26 (PR #872).

| Pair | Old (F-tidewake-add frames, be95950b) | Recheck (aa23cda5b, victory_focus on) | Gain | Prefer recheck |
|---|---|---|---|---|
| F39#21 Venn win and aftermath (2 frames) | 5.70 | **6.66** | **+0.96** | **3/3** |

- **Per judge, mapped (raw):**
  - Old side: 5.78 / 5.53 / 5.78 (4.9 / 4.7 / 4.9).
  - Recheck: 6.91 / 6.53 / 6.53 (5.8 / 5.5 / 5.5).
- **Scale note:** the old frames scored 4.75 in `F-tidewake.md`, on another batch's scale. Read the gain within this batch.
- **Fit:** slope 1.2504, intercept −0.3423, r 0.867, anchor RMSE 0.575. Confirming batch; no warnings.
- **Batch:** one pair plus 3 pinned anchor pairs, three fresh code-blind judges, sides shuffled with the key kept outside. The two frame sets are different images (md5 checked).

## F38#1 creature collapse and rest: `G-recheck-f38-1` (ghost-glow state)

This was judged in the `G-floor` batch; see `G-npc-floor.md`.
- **Result:** +0.47, 3/3 over the F-meadows frames (6.11 → 6.58 on that batch's scale).
- **Terrapup frames:** the see-through faint is gone.
- **Veridian fainted:** still a white, wispy shape above the grass.

Judged by LANE-SCOUT, 9 Nov 2026 ~08:20 UTC.

## F39#21 combined score: Venn win and aftermath plus Nerissa win (`G-recheck-nerissa-win`, main d9d79ff93 with the #872 seat fix)

**F39#21 combined, one-sided, GPU High: 5.69 mapped.**
- **Per judge:** 5.77 / 5.29 / 6.01 (raw 5.4 / 5.0 / 5.6).
- **Recorded defect:** FIXED (1 judge) or PARTIAL (2). The exploration HUD is gone during the win; only health and food remain.
- **What pulls the score down:**
  1. **The Nerissa win frame** (`nerissa_resolve__win-207_25`):
     - The camera sits inside huge translucent pale-blue light-shaft slabs, with a flat orange or peach box clipping the foreground. All three judges called it an artefact.
     - A "Put Bramblebun away" prompt sits mid-screen and competes with the reward toast.
     - This is the coordinator's known "camera behind translucent slabs" issue.
  2. **The reward is still a small top-right toast** with no centred moment or creature framing (3/3).
     - One judge also read a doubled slash ("100//100") in the HUD.
     - None of the three named the known doubled reward text explicitly.
  3. **The flat grey foreground plane** in the Venn aftermath frame (see above).
- **Scale note:** this is lower than the Venn-only recheck (6.66) in the paired batch above. The two numbers come from different batch scales: 6.66 was a live-vs-recheck pair, while this is a one-sided score with Nerissa's frame added.
  - The judges' notes put most of the difference on the Nerissa frame's light-slab artefact.
  - Against the F-tidewake 4.75, the row is better. It is not near 7.5 until the reward is staged centrally and the Nerissa camera clears the light shafts.
- **Fit:** slope 1.204, intercept −0.734, r 0.838, anchor RMSE 0.630. Confirming batch; no warnings.
- **Frames:** 3 in a 2x2 grid at 640x360: Venn win and aftermath from `G-recheck-f39-21` (aa23cda5b, victory_focus on) and the Nerissa win from `G-recheck-nerissa-win` (580fe172, d9d79ff93).
- **Judged:** three fresh code-blind judges, standard JUDGE_PROMPT, 3 pinned anchor pairs. LANE-SCOUT, 9 Nov 2026 ~09:45 UTC.
