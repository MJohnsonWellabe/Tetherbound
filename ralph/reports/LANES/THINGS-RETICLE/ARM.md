# THINGS-RETICLE: catch aim ring (F38#7 close-out, 7.49)

**Row.** F38#7 catch aim: 7.49 after the beam fix (`G-things-beam`, d7a1d3b0). Judges' remaining ask: "the reticle is a tiny cyan slab; make it a bright ring with a dark halo".

**What is on screen.** The ring is there, but `ring_style_1104` (ON since 4 Nov) draws it at 0.7 width and 0.55 alpha with no outline, so against grass and fur it is a faint hairline. What the judges read as the reticle is the teal strap on the creature's flank.

**Change.** Config only, `capture_readout_visual.json ring_style_1104`: `alpha_scale` 0.55 -> 1.0, `width_scale` 0.7 -> 1.15, `outline_px` 0 -> 1.5 (a thin dark halo). This is not the 4 Nov round 1 that lost (a heavy outline and arcs x1.35 hid the creature): the arc stays about 3.5 px with a 1.5 px halo.

**CPU** (`_sheet_reticle_off_vs_on_cpu.jpg`; left main, right arm; top 0%, bottom 82%; the camera angle differs between runs): the ring and its chance arc read at once in the tier colour, and the creature is still fully visible through it.

**Not in this arm.** The teal strap on the hare (creature dressing, a separate look), the trainer near the target's legs, and the white ground puffs.

**Ask.** F38#7 job.json frames (phase2_capture_catch.gd, Meadows), base vs arm, High then Medium. Tidewake's F39#23 uses the same ring: one catch frame there as a no-loss check.
