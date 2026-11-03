# Visual lane v1/ui1b: Tidewake catch (F39#9 camera distance, F39#23 catch-chance contrast), CPU A/B (3 Nov 2026, ~10:45 UTC)

**Arms:** the UI set as in v1/ui1a (all ON together). Base: this branch with all OFF. Frames: the items' `job.json` repro (`phase2_capture_catch.gd --biome=tidewake --seed=2042`), CPU llvmpipe, Compatibility.

**Yardstick:** JUDGE_PROMPT verbatim, 3 anchor pairs (f36_0_gap:C4, f36_0_npc:C4, craft; confirming batch), three fresh code-blind judges, `calibrate.py`: linear, slope 1.43, intercept -2.88, r 0.84, anchor RMSE 0.48, no warnings.

| Row | Item | CPU base (mapped) | UI arms ON (mapped) | Raw base / ON |
|---|---|---|---|---|
| F39#9 | P2-113 catch camera distance | 5.77 | **6.01** | 6.3 6.0 5.9 / 6.2 6.3 6.2 |
| F39#23 | P2-114 catch chance HUD contrast | 5.34 | 5.29 | 5.9 6.0 5.4 / 5.8 5.9 5.5 |

**Decision: not flipped yet.**
- With the whole UI set ON, both catch captures (Meadows and Tidewake) failed to finish a catch ("sequence B never produced a catch to photograph"); on the base, both completed. One of the arms (framed_camera.r2, catch_kit, catch_orb, catch_card or message_clears_prompt) may change catch behaviour, not just presentation.
- What the judges see differ is the message placement. On the base, "not even close - weaken it first" is drawn on top of the "LT Aim · 19 orbs" hint bar; with the arms ON it moves to a banner. That is `hud.json message_clears_prompt`. It is now being captured alone (`.artifacts/vl/msg`), with catch completion checked, before any flag turns ON.

**Judges (all three):** the trainer is wedged between Cannonback and Terrapup in every catch frame; the capture-chance label is orange on the pale shell and sand with a tiny caption; the throw and cancel hints are micro text. Asks: a raised three-quarter catch camera with the trainer offset, a solid plate for the percentage anchored off the subject, teal controller glyphs. All scene fixes.
