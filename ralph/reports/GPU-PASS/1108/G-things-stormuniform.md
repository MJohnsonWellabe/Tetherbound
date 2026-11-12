# G-things-stormuniform: Stormwood uniform and civilian emission floor to 0 (F41#18; officer and civilian dialogue ride along; GPU High)

## Verdict: DO NOT SHIP as it stands. The target row is level and does not get 2/3 preferring the arm.

| Set | Base | Arm | Gain | Prefer arm | Arm per judge (mapped) |
|---|---|---|---|---|---|
| **F41#18 row** (Varga, Dace, Sable; inventory camera) | 5.56 | 5.60 | +0.04 | 1/3 (1 prefers base, 1 tie) | 5.44, 5.68, 5.68 |
| F41#18 dialogue (same three) | 6.04 | 6.04 | 0.00 | 1/3 (2 prefer base) | 5.92, 6.04, 6.15 |
| Officer dialogue (Sera, Maren, Nysa) | 5.84 | **6.11** | +0.27 | 3/3 | 6.04, 6.39, 5.92 |
| Civilian dialogue (Ivo, Tamsin, Wen; no-loss) | 6.94 | 6.94 | 0.00 | identical | 6.98, 6.86, 6.98 |

- **The arm does what it set out to do, and the judges see it.** In conversation, base's uniforms carry "a pale, washed haze ... ghostly and desaturated rather than lit" or "a chalky ghost wash" (3/3). The arm's uniforms are "darker" and the haze is gone (3/3).
- **Why it doesn't score:** the darker cloth now "sinks into the dark green and black ground", where "only the chevrons and the face separate" (3/3). At the inventory camera the officer "partly merges with the black mud path" (2/3). The arm trades the ghost wash for blending, so the recorded defect is PARTIAL on base and PRESENT on the arm at gameplay distance (2/3).
- **Officer dialogue gains 3/3 (+0.27).** Removing the wash helps most in close conversations, where the face carries the read. That set is a ride-along and does not carry the row.
- **No loss.** Civilian frames score the same per judge, and villagers look unchanged, as the GPU lane's pre-check found.

## What the row needs next (3/3 unless noted)
1. **Keep the floor at 0 and add separation another way.** All three judges independently ask for "a cool white-violet rim or key light" on the uniformed cast plus "a slightly lifted cloth albedo" and "a distinct shoulder, collar or rank trim colour" (copper or steel; not red). Scene work. The judges did not ask for near-black: they asked for dark cloth that is lit.
2. **Rank or individual markers.** None are legible at the inventory distance on either side (3/3). This is half the recorded defect and no lighting arm fixes it.
3. **Identity (T-IDENTITY), 3/3:**
   - "Officer Maren" uses the same mesh and the same portrait as "Lieutenant Sera".
   - "Officer Nysa" is Varga's mesh and face.
   - Varga's face texture is "blotchy orange-brown" and Sable's is "pale and mottled" (3/3). New art or data.
4. **Background pulls the eye (3/3).**
   - The bears behind Nysa are flat salmon pink, and the ravens are flat cobalt; both read as placeholders. No red or oxblood is involved.
   - The black mud road has orange crack lines.

## Pooled current-main F41#18
- G-things-stormrim put the row at 6.22 on its arm (`overlay_player_rim_off`). This batch's base is that same overlay and scores 5.56 (row) / 6.04 (dialogue).
- The rim-off overlay is on main (`stormwood_look.json` `player_character_rim_scale` 0.0), so both panels are on-main state. Pooled current-main F41#18 at High: row ≈ 5.89 (6.22, 5.56), dialogue ≈ 6.34 (6.63, 6.04).

## Frames
- **Source:** `tb/gpu-frames-1108` section `G-things-stormuniform` (cb3d65be1), High.
- **Capture:** `phase2_capture_dialogue.gd --biome=stormwood --fixed-fps 20`, every Stormwood post plus its dialogue frame. 86 frames per side, 0 blank, 0 script errors. The exit 1 is the known catalogue count check (86/45).
- **Build:** `tb/things` 50b041a7b on both sides.
  - **base:** STORMRIM `overlay_player_rim_off`.
  - **arm:** base plus STORMUNIFORM (`stormwood_character_presentation` uniform/civilian `emission_floor` → 0).
- **GPU lane pre-check:** officer coats L ≈ 125 → ≈ 100 (mid-grey, not the near-black the pre-check asked for). Pushed as captured on the coordinator's word.
- **Render check:** mean per-frame difference 0.1–4.6. Captain Marrow is unchanged (0.1), so F41#15 is not in this batch. Nysa's conversation changes most (4.6). By eye, Varga's coat is visibly darker on the arm.
- **Sets** (three frames stacked, 1280×720 each): see `yardstick_g_things_stormuniform/frames.json`.

## Batch `G-su`
- Three code-blind judges, standard prompt, four candidate sets.
- Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** linear, slope 1.182, intercept −0.463, r 0.899, anchor RMSE 0.61. No warnings.

**Raw Bar A (judges a, b, c):**

| Set | Base | Arm |
|---|---|---|
| F41#18 row | 5.0, 5.4, 4.9 | 5.0, 5.2, 5.2 |
| F41#18 dialogue | 5.6, 5.6, 5.3 | 5.4, 5.5, 5.6 |
| Officer dialogue | 5.4, 5.6, 5.0 | 5.5, 5.8, 5.4 |
| Civilian dialogue | 6.3, 6.2, 6.3 | 6.3, 6.2, 6.3 |

Bar B: no on every candidate set (3/3).
