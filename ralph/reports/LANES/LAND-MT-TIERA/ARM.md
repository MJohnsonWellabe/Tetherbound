# LAND-MT-TIERA: take the lower cascade tier off the Veilfall fall sheet

**Row.** F39#31 Veilfall hero landmark (5.93 High clear-day baseline, pre-#958; G-rescore-f39-31-clear-day-pre958 on tb/judge).

**Defect (3/3).** "A rock cluster with a sapling seems to float on the sheet" in the close frame (`veilfall-near`).

**Cause, and how I know.**
- A ray from the `veilfall-near` camera through that spot crosses `WaterLandmarkModels/Landmark_veilfall_cascade_a`, about 39 m out, before reaching the terrain at about 50 m.
- That piece is the Meshy cascade tier from `tidewake_look.json` `veilfall_hero_candidate` (ON), at (352, 3846) with `lift_m` 8. From the close stand it sits over the white fall.
- With it removed (this overlay), the large pale rock on the right of the sheet is gone in `veilfall-near` (sheet).

**Change.** Overlay only: `veilfall_hero_candidate` without the `veilfall_cascade_a` entry. Tier B and the plunge ring stay.

**CPU before / after.** `_sheet_tiera_off_vs_on_cpu.jpg`: top base, bottom arm; `veilfall-vista` (left) is unchanged, and in `veilfall-near` (right) the big rock on the sheet is gone. 0 script errors.

**Not fixed by this arm.**
- A smaller rock with a sapling higher on the sheet is still there; it is a different piece, not yet named.
- The plunge pool and foam ask is separate.

**By-eye line for the GPU lane.** `veilfall-near`: no large pale rock sitting on the right half of the fall sheet.

**Risk.** The tier was added on 24 Oct (close-1024 vf2) to dress the gate shoulders the close stand looks up at. Without it the shoulder is plainer. The `veilfall-vista` frame is the no-loss check.
