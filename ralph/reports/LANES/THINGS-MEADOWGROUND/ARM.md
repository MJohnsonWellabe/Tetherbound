# THINGS-MEADOWGROUND: the Meadows ground pass that was built on 1 Nov and never judged (P-GROUND)

**Cause group.** `CLUSTERS-6TO7.md` rank 1, P-GROUND: "blurry, smeared ground", "uniform olive carpet", "grass reaches the waist around characters" (3/3 in four of tonight's batches). Meadows rows in the group: F38#20 6.02, F38#22 6.10, F38#30 6.02, F38#26 6.85.

**What it is.** `meadows_look.json cause_ground` (OFF on main since PR #792; built by the cause lane, `ralph/reports/LANES/CAUSE-MEADOWS/READY.md`). No verdict for it exists in GPU-PASS/1108. Nothing new is built here; this arm puts it in front of the judges.
- Terrain: two-tone macro variation in place of the olive smear, sharper mip bias (0.86 -> 0.7), stronger near grain.
- Grass: ground zones at full strength and a larger scale, so a frame shows clearings, lawn and tall grass; deeper clump contrast; flowers in drifts.
- Viewport (Meadows only, restored on leaving): 16x anisotropic filtering and a -0.35 texture mip bias, for crisp ground and village textures at grazing angles.

**CPU** (`_sheet_ground_off_vs_on_cpu.jpg`; top main, bottom arm; village close, day): the flag still works on current main. The grass opens into clearings round the stall and the characters' feet show; the path edge is cleaner. The two runs also differ in cloud position and overall light, so read only the ground from this pair. The filtering half cannot be judged on CPU.

**Risk.** Thinner grass can read as bare; the anisotropic setting costs a little GPU time (record frame time on Medium).

**Ask.** The four rows' job.json frames plus two Meadows no-loss frames (a fight, a creature idle), base vs arm, High, with time of day and weather pinned on both sides.
