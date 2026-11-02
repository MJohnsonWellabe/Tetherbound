# CREATURES-F36 r6: coat value lift for four dark creatures (CPU, three judges)

**Verdict: GPU READY.** Arm `tb/co-f36-4-on` 529829e88 (control: main a41e1b30). All four species gain at least 0.5.

**Targets:**
- GPU ROSTER-1 High (31 Oct, coordinator) item 3, "rim light and value lift": cindercub 7.13, duskhush 6.77, ashtusk 6.68.
- GPU CO12 (31 Oct): thundertunnel 6.49 / 6.50, still "a dark mound with no readable face" after its first lift.

| Species | Live coat (probed in engine) | Median value | Mapped main | Mapped arm | Gain | Dark-body defect (main / arm) |
|---|---|---|---|---|---|---|
| **Cindercub** | `creature_cindercub_nat1024b_Image_0.jpg` (embedded) | 0.26 -> 0.40 | 5.83 | **6.93** | **+1.10** | PRESENT x3 / PARTIAL x3 |
| **Duskhush** | `creature_duskhush_lod0_base_color_vivid.png` | 0.22 -> 0.38 | 5.42 | **6.56** | **+1.14** | PRESENT x3 / PARTIAL x3 |
| **Ashtusk** | `ashtusk_native_extracted_base_color_ashtusk.png` | 0.24 -> 0.38 | 5.74 | **6.79** | **+1.05** | PRESENT x3 / PARTIAL x3 |
| **Thundertunnel** | `thundertunnel_extracted_base_color_vivid.png` (CO12's lift) | 0.34 -> 0.44 | 6.01 | **6.70** | **+0.69** | PRESENT 2, PARTIAL 1 / PARTIAL x3 |

**Fit:** linear, slope 1.38, intercept −1.99, r 0.996, RMSE 0.14. Confirming batch (craft, f36_0_npc:C1). No warnings.

**The change:**
- `tools/art_pipeline/grade_coat_value.py` grades each live coat.
- Dark, low-saturation texels gain value (x1.25 to x1.6, plus a small floor), feathered.
- The darkest texels (eyes, mouth) and saturated accents (Cindercub's embers, Thundertunnel's quills) keep their exact pixels.
- The reserved-red share is unchanged from each source: Cindercub's ember texels sit at 2.2% in both.
- Each grade sits beside its source as `<stem>_coat_lift.png`, with import settings matching the source (VRAM-compressed).

**Arm shape (coordinator process, 31 Oct):**
- Flag-off code: `_apply_coat_flags` in `scripts/creatures/creature_body.gd`, run right after the base colourway.
- Config: `data/config/creature_coat_flags.json`, flag `creatures_f36_coat_lift`, `enabled` false.
- An enabled flag maps the live albedo path to the graded file. The emission slot follows when it carried the same image. Shiny bodies are untouched.
- The four new textures need one import on the GPU tree.

**Tests:** `test_cloudreach_source_colourways`, `test_creature_texture_for_jpg_albedo`, `test_pebbik_colourway`, `test_phase2_shiny_finish`, `test_companion_presence`, `test_creature_rest_pose` pass with the flag on and with it off (56 tests, 867 assertions, 0 failed each time).

**What the judges still see:**
- All four: no rim light on the stage, and small or hidden eyes.
- Cindercub: its ember cracks over the fur. One judge flagged them as glowing seams on fur, which the owner rule forbids. They are main's, not this change.
- Duskhush: about trainer height. CO-F36-3 grows it x1.35, and the two arms combine.

Sheet `_sheet_r6.jpg`: main on the left, arm on the right; rows are Cindercub, Duskhush, Ashtusk, Thundertunnel. Tiles: standing, hit 050, faint 050, faint 100.
