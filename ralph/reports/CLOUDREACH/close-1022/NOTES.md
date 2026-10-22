# Cloudreach lane — close 22 Oct 2026 (tb/cloudreach)

Starting state: `../close-1020/NOTES.md` RESUME. Renderer for every capture here: Low preset, Compatibility (gl_compatibility), Mesa llvmpipe CPU, 1280x720, xvfb. Judging follows the yardstick (`tools/visual_judge/`, #706): standard prompt, at least 4 anchor tiles per batch, mapped scores via `calibrate.py`. Done = mapped Bar A mean 7.5 (CPU-provisional 6.7 per CLAUDE.md).

## TO COORDINATOR
(send_message to the coordinator session is refused here with elevated_session_untrusted_device, so lines go here.)

- 2026-10-22 09:15 CT MESHY F40#1 P2-022 (tb/cloudreach @ 9d7a39ba). Two assets, references drafted with dimensions, a 1.80 m trainer and board crops:
  1. `cloudreach_aviary_drum_ring_v2`, ref `assets/environment/cloudreach/meshy_refs/aviary_v2/drum_ring_v2_ref.jpg`. Hollow round drum, 56 m outer diameter, 12 m wall (+1.2 m stepped plinth OUTSIDE only), 16 amber pointed-arch windows, royal-blue wing banners between them, open arched entries 7x9 m at +Z and −Z (see-through), gold-ribbed blue-glass dome and lantern cupola to ~44 m at the finial. **No floor, no base disc, no interior step**: the existing court floor must show through (the last shell failed because its base step read as a greybox floor). Pale warm-grey limestone #a89c8a–#c4b8a4, gold #c9a24a, slate roof #3d4a66, no red/oxblood. Origin at drum centre, ground level, +Z entry facing +Z.
  2. `cloudreach_aviary_belvedere_tower`, ref `.../aviary_v2/belvedere_tower_ref.jpg`. 26 m to the finial, ~6 m tapering round limestone shaft, corbelled balcony, amber belfry arches, conical slate-blue roof, gold finial, one blue banner. Single tower; the lane places four copies at 55/125/235/305°.
  Both stay flag-off (items flag) until judged. Please push the GLBs (e.g. `assets/props/meshy-1022/`) to a branch and note the path here or on #572.
