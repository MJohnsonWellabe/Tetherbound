# LAND-MT-CRAGCUT: the Venn fight's dark overhead wedge, second approach

**Rows.** F39#19 (6.95 High, 7.27 Medium on the strict 13 Nov panel), F39#7 (7.11).

**Defect (G-land-mt-cragback, 3/3, both sides).** "A dark navy or black wedge or round mesh hangs into the top right" of t-000 and t-003.

**What is known, and what is not.**
- CPU probes (Compatibility) on later fight frames (t-001 onward): back faces of the Veilfall crag shells painted green filled the dark corner. In those frames, lighting back faces (`LAND-MT-CRAGBACK`) turned the corner grey.
- **On GPU, CRAGBACK changed nothing** on t-000 and t-003 (mean frame difference 0.02 to 0.57). Two possible reasons, not yet told apart:
  1. Forward+ already handles back-face normals differently, so `back_face_lit` does nothing there; or
  2. the t-000 / t-003 wedge is a different mesh. The fight's opening framing is not deterministic, and none of my CPU probe runs reproduced the t-000 camera with the probe on.
- So **step 1 is a GPU eye check, not a judged arm.**

**Step 1: GPU eye check (no judges).** `probe_overlay.json` paints crag back faces magenta (emissive). Capture t-000 and t-003 at High.
- If the wedge turns magenta, it is the shell's inner side: go to step 2.
- If it stays dark, it is another mesh: hold, and tell LAND-MT. The next probe would paint the crag's front faces, then the Veilfall exterior formations.

**Step 2: the arm.** `overlay.json` sets `back_face_cut_m` to 150: crag back faces closer than 150 m are discarded, so the camera sees the real Veilfall terrain wall behind the shell, lit by the existing Veilfall rock pass. This does not depend on how a renderer lights back faces. Far views see front faces only (the shells are 700 to 1,100 m wide, and distance views are 700 m or more away), so the mountain silhouette is unchanged.

**By-eye line for step 2.** t-000 and t-003: the top-right wedge is gone, showing rock or terrain behind. If a hole to the sky opens instead, hold.

**No-loss frames.** F39#2 job frames, the F39#31 frames (`veilfall-vista`, `veilfall-near`), and the Veilfall landing walk.

**Code.** `shaders/water_veilfall_crag.gdshader` (`back_face_cut_m`, `back_face_probe_colour`), `data/config/water_veilfall_crag_kitbash.json` (`crag_shader.back_face_cut_m` shipped 0). Not looked at on CPU yet: the CPU cannot reproduce the GPU's t-000 framing.
