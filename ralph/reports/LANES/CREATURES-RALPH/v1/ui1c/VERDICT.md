# Visual lane v1/ui1c: F39#9 with `message_clears_prompt` alone, and F40#14 Cloudreach map label (3 Nov 2026, ~12:00 UTC)

**Why this batch:** in v1/ui1b, F39#9 rose 5.77 -> 6.01 with the whole UI arm set ON, but that set broke catch completion (3 of 3 catch captures with it ON never finished a catch; the base finished every time). The only change the judges named was the message no longer drawn over the aim hints, which is `hud.json message_clears_prompt`, so it was captured alone. With it alone the catch completes (exit 0, every frame through 09-caught-banner).

**Yardstick:** JUDGE_PROMPT verbatim, 3 anchor pairs (f36_0_npc:C3, f36_0_gap:C6, craft; confirming batch), three fresh code-blind judges, `calibrate.py`: linear, slope 1.51, intercept -3.22, r 0.81, anchor RMSE 0.69, no warnings.

| Row | Item | CPU base (mapped) | Candidate (mapped) | Raw base / cand | Decision |
|---|---|---|---|---|---|
| F39#9 | P2-113 catch camera distance | 6.14 | **6.75** (+0.61) | 6.0 6.2 6.4 / 6.5 6.5 6.8 | `message_clears_prompt` **ON** |
| F40#14 | P2-048 Cloudreach map region label | **6.29** | 6.24 (UI set) | 6.3 6.0 6.5 / 6.3 6.0 6.6 | at or above 6.0 on the current branch; the "cut after LOWER" defect is FIXED on both sides |

All three judges prefer the single-message side: "two prompt strings overlap ... a legibility artefact" on the base. Still asked for (scene): a wider, offset catch camera with the trainer clear of both creatures, a solid plate for the capture chance, and larger controller glyphs.
