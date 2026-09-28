# P2-021 native baseline

All five catalog sightings were recaptured using their original scripts and seed
2042. The retained rounds contain six location views and five seeded route views,
including comparison views beyond the five sightings. Each engine manifest reports
completion; raw images are 1920×1080 on Windows, Godot 4.7 Compatibility/OpenGL 3.3,
NVIDIA GeForce GTX 1060 3GB, driver 560.94. This is a computer capture, no Ally hardware.

The original windowed launch produced 1920×1061 and was stopped before usable
frames. A small viewport/image sizing probe established that `--fullscreen`
produces 1920×1080; `--borderless --position 0,0` did not. The retained reproduction
commands include this launch adjustment. APPDATA was isolated under the ignored
`.artifacts/cloudreach-phase2/profile` directory. Teleports, frozen time and hidden
HUD are the existing capture fixtures; this is not earned-route evidence.

The captured runtime source matches commit `71ff7e84203f632e53bdde8de0f08c21f9158fb1`,
whose default-off skyline profile was committed after these runs. At capture start,
the branch was based on `2e13ba43f9cd549e6eeb47ea2654d654f014e381` with that two-file
candidate in the working tree. The candidate stayed disabled for both runs.
`tools/phase2_compact_evidence.py --capture-manifest` retained the contact sheets,
full per-frame metadata and source hashes; both compact rounds verified. Raw frames
remain local and are not committed.

Several shrine sightings seat the trainer on the 1020 m plateau. The landmark
close view seats it on the shrine dais at 1051.3 m, and the existing chapter matrix
describes shrine approach stands at 1050 m. The fresh images show broad grass,
empty horizons, and apparent suspended rock/grass. Route-grounded comparison is
still required before separating lower-plateau presentation from a misplaced
capture stand. No before/after PASS or regional acceptance is claimed.

Baseline checks: texture policy `--apply` changed zero sidecars; `--check` passed
424 runtime 3D sidecars. `tests/run_tests.gd --
--only=test_texture_import_policy.gd,test_creature_viewport_framing.gd` passed
15 tests and 629 assertions with zero failures. The headless test process logged
RID/resource leaks during teardown; these are not described as a clean engine log.
Native captures also warned about unresolved physical pickup/wild placements;
their gameplay ownership remains outside this presentation item.
