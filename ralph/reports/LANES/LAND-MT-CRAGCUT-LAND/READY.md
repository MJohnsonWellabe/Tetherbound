# READY: tb/land-mt-cragcut-land

STATUS: land. GPU-judged ship (G-land-mt-cragcut on tb/judge, LANE-JUDGE, 13 Nov).

**Verdict.** F39#19 High and Medium 6.85 -> 6.92 (+0.07, 2/3 prefer, 1 tie), no set loses; control F38#38 8.08 (normal panel). Ship rule met. F39#19 not closed; the crag-shell approach is parked for that row.

**What.** The Venn fight's black overhead wedge is the inner side (back faces) of the Veilfall crag shells, which the `cull_disabled` crag shader drew dark. Crag back faces nearer than 150 m are now discarded, so the camera sees the real Veilfall terrain behind. Far views see front faces and are unchanged.

**Files.**
- `shaders/water_veilfall_crag.gdshader`: `back_face_cut_m`, plus `back_face_lit` and `back_face_probe_colour`, both off.
- `data/config/water_veilfall_crag_kitbash.json`: `back_face_cut_m` 150 with `_why_back_face_cut_m`; `back_face_lit` 0.
- `tests/test_veilfall_crag_back_face_cut.gd`.

**Tests run.** `tests/run_tests.gd --only=test_veilfall_crag_back_face_cut.gd`: 2 tests, 6 assertions, 0 failed (headless, on this tree's config). No other test reads the crag kitbash config.
