# LAND-MT-CRAGCUT: the Venn fight's dark overhead wedge, second approach

**Rows.** F39#19 (6.95 High, 7.27 Medium on the strict 13 Nov panel), F39#7 (7.11).

**Defect (G-land-mt-cragback, 3/3, both sides).** "A dark navy or black wedge or round mesh hangs into the top right" of t-000 and t-003.

**Cause, and how I know (attempt 2 of 2 on this item).**
- I rebuilt the GPU's t-000 fight camera as a fixed, deterministic view: the position comes from the fight tool's `frames.json` (384.3, 12.0, 3789.2), aimed at the two fighters' midpoint (yaw 125, pitch -19; FOV 60 and 75).
- Painting the crag shader's back faces magenta turns the whole black wedge magenta (`_sheet_t0_backface_probe_cpu.jpg`). So the wedge is the inner side of the Veilfall crag shells, which dip around the arena.
- Why attempt 1 (CRAGBACK, flip the back-face normal) was level on GPU: the engine already flips back-face normals there (`shaders/water_veilfall_spray.gdshader` says so and undoes it), so the extra flip did nothing.

**Change.** `back_face_cut_m` 150 (overlay only): crag back faces closer than 150 m are discarded. From inside a shell the camera sees the real Veilfall terrain behind it. This does not depend on how a renderer lights back faces.

**CPU before / after.** `_sheet_cragcut_off_vs_on_cpu.jpg`: the fixed t-000 view at FOV 60 and 75, top base, bottom arm. The black polygon is gone. What shows instead is the mossy cliff and the sand, with a soft cast shadow where the shell still blocks the sun. 0 script errors.

**By-eye line for the GPU lane.** t-000 and t-003: no black or navy polygon at the top right; mossy cliff and sand there instead, with at most a soft shadow. If a hole to the sky opens, hold.

**Risks.**
- The shell still casts its shadow, so a darker soft patch stays on the sand under where the wedge was. If judges call it out, the next step is `cast_shadow` off for the shells within the same radius, a separate change.
- No-loss: F39#2 job frames and the F39#31 frames (`veilfall-vista`, `veilfall-near`). Those views are 700 m or more out and see front faces, so they should be unchanged; `veilfall-near` is closer and is the one to check.
- A GPU eye check before judges is still sensible, though no longer required to find the cause.

**Code.** `shaders/water_veilfall_crag.gdshader` (`back_face_cut_m`, `back_face_probe_colour`), `data/config/water_veilfall_crag_kitbash.json` (`crag_shader.back_face_cut_m` shipped 0). CPU-ready on the fixed t-000 view.
