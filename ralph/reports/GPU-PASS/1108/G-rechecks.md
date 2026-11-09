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
