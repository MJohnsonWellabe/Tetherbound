# Cloudreach lane — close 24 Oct 2026 (tb/cloudreach)

Rows in order: F40#0 recapture + rescore, F40#5 defect pass, F40#3 matrix bar, F08#3, F40#1/#2.
Renderer for every capture: Low preset, Compatibility (`gl_compatibility`/`opengl3`), Mesa llvmpipe CPU, xvfb.
Judging: `tools/visual_judge/` yardstick (standard prompt, ≥3 anchor pairs, `calibrate.py`); CPU-provisional bar 6.7.

## Log
- 24 Oct: branch `tb/cloudreach` cut from origin/main 5f1f388cc. Container had no Godot; installed 4.7-stable (CI's URL). First import done (exit 0, ~45 min).
- 24 Oct ~03:48 CT: F40#0 recapture started at source 22b88b52 (main content + this note), `tools/capture_cloudreach_f40_matrix.gd --preset=Low --low-resolution=1280x720`, pieces d*8+3..d*8+7 per stand (day clear/rain, golden clear/rain, night clear x approach/gameplay/reverse/detail = 20 frames). Measured: world load ~9 min, ~6 min per frame on llvmpipe (4 cores, ~105 settle frames per capture), so ~2 h per stand; stands run one Godot process at a time in order 0, 6-11, 4, 1, 2, 5. Stand 3 (Broken Skyroad Arch) was refused by the teleport slope guard on 21 Oct; its stand gets probed and corrected after the chain. Frames stay local (`.artifacts/f40/r1/`); names and hashes go in the evidence manifest.
- 24 Oct 15:39 CT: stands 0, 6, 7, 8, 9, 10 complete, 20/20 frames each, no refusals (120 frames). Stand 11 running; the F40 fight capture is queued after stand 5. Coordinator 13:06: F40#0 is a capture-and-rescore row; F40#5 scan in the same pass.
- 24 Oct 12:00 CT coordinator (owner, 24 Oct): GPU decides done; the CPU-provisional 6.7 rule is retired. CPU frames iterate and pre-judge only; READY lines carry the capture command for the GPU lane, which closes rows at mapped >=7.5 Medium and High. F40#1/#2 split into one row per catalog item (top-20 + impact >12), each on its own GPU before/after. F40#0: finish the CPU capture and per-row rescore; the GPU lane captures the matrix at High/Medium.
- 24 Oct 16:39 CT: stand 11 complete (140 frames). Stand 4 running.
- Plan: pass 1 = yardstick batch (standard prompt verbatim, one-sided set per stand + the F40 fight, anchors, calibrate) for F40#3's Bar A; pass 2 = catalog rescore of all 41 Cloudreach rows (severity/exposure/importance, FIXED/PARTIAL/PRESENT, honest NO_CURRENT_EVIDENCE) plus the F40#5 defect sweep, same three judges' frames. `tools/rescore_cloudreach_f40.py` needs a High+Medium four-leg pair audit, which a CPU container cannot produce; the F39#0 precedent (three-judge row scores, CPU-provisional) is followed and the GPU legs stay owed.

## TO COORDINATOR
(newest first)
