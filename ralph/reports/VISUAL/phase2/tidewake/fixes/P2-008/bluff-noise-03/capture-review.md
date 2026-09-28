# Gull Rest noise-neutral diagnostic

Two native 1920x1080 frames completed successfully at `45c737025aec8d890270640d9fb2f279e9f7f5f2`. Root inspected both images. In these masks white denotes mineral exposure and black denotes sand; this is diagnostic output, not the game palette.

Both the upper serrated cap and the triangular teeth along the lower left-wall boundary remain when `bluff_patch` is fixed to 0.5. Local widths change modestly, but the repeated teeth remain clear. Thus this noise perturbation is **not necessary** for the defect at this fixture. It does not prove which remaining input causes it, nor exclude interaction between slope, paint and height. Do not pursue noise-frequency tuning as the repair based on this pair.

The next material investigation should address how the slope transition is reconstructed over the terrain grid, using the earlier height/control/slope ablations alongside this result. A coherent surface repair still needs ordinary shaded comparison and an independent visual verdict. The large continuous rock-wall silhouette and weak grass colonies remain separate unmet visual requirements.

Capture integrity: two frames, exact image hashes and native sizes checked; current camera identity/lens, player, Sun and LOD retained. Camera origin delta is zero and basis maximum delta is 2.98023223876953e-8. Launcher exited 0; no script/parse/compile/shader errors. The existing interpolation deprecation warning is retained. Child process and lock cleanup were verified; no other capture was launched in this slot.

The original source-review and preparation descriptions are retained as historical pre-run evidence. `validation.json` and the native manifest record the completed run. These images do not pass Bars A/B or close P2-008. Production dune gates remain false.
