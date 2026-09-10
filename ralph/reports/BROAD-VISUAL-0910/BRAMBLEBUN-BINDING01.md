# Bramblebun redesign texture ownership

The installed Bramblebun redesign has its own UV unwrap, but ordinary, alpha
and shiny colourway lookup still defaulted to the legacy `bramblebun` folder.
The native orientation receipt showed `creature_bramblebun_redesign_lod0`
wearing `bramblebun_extracted_base_color_vivid.png`. The model faced forward;
the missing readable eyes and unrelated surface patches were not a yaw issue.

The candidate sets `placeholder.colourway_source_species` to
`bramblebun_redesign`. No derivative colourways exist for that redesign, so the
existing fallback retains the model's matching source texture. Alpha presence
still applies; shiny uses the existing generic tint fallback. No geometry,
UVs, size, animation, combat data or other species are changed. A static roster
scan found no other ordinary model-folder mismatch; intentional aspect reuse
uses a separate source path. That scan does not prove all older derivative
textures were generated from their current models.

The actual-body identity probe at 10:53:43–10:53:48 UTC was named
`bramblebun-binding-negative-first`, but the candidate was applied while that
process started, and it observed the corrected source. It is positive evidence,
not a successful negative control. The later stable
`bramblebun-variants-binding-first` run at 10:56:16–10:56:20 passed 12 assertions
with no errors: ordinary, alpha and shiny use the exact Texture2D resource
loaded from the redesign GLB and never use the legacy atlas. The reproducible
regression is `tests/smoke_bramblebun_colourway_binding.gd`.

Matched native presentation captures at 1280x800 completed cleanly at
10:54:12–10:54:22 UTC. The unchanged Mudsnout close and field controls have
identical SHA-256 hashes to the earlier baseline. Bramblebun's corrected close
and distant frames restore its eyes, muzzle, inner ears and coherent fur
regions. A fresh blind judge preferred corrected X over baseline Y in both
views and found a substantial genre-reference improvement, while rejecting the
commercial bar because harsh fine detail and crowded ear/antler forms remain.
These captures use an isolated plane and lighting fixture, not a production
habitat or gameplay camera. Full art smoke also passed at 10:58:10–10:59:12,
including installed model, animation and collider-fit checks; only the existing
Terrain3D interpolation deprecation warning was emitted.

The production-world diagnostic needed corrections before usable evidence:
the first run failed parsing an inferred animation-name type; the second
correctly rejected a subject behind the camera because native SpringArm child
placement had overwritten the diagnostic pose. The same Camera3D was then
reparented out of the arm. A third attempt was terminated by the memory guard
while a separate texture-processing job overlapped it. A fourth completed with
no engine errors, but visual inspection rejected its hillside framing because
terrain/vegetation obscured most of the creature. The capture guard alone did
not detect that occlusion; its clean status is not a visual pass.

The fifth run moved the audit subject to the already-played village area at
(8, 28), facing the fixed diagnostic camera. From 11:20:17–11:21:47 UTC it
completed four native frames with no errors. Root inspection confirms the
whole creature, actual terrain and procedural grass are visible. Day and night
each compare the corrected source with a process-local legacy-atlas control.
The control is cloned after the production clock settles, preserving matching
unclamped albedo values and emission energy: day 0, night 0.22. The body, pose
and camera match within each pair. Grass wind/cloud variation is incidental
and is not credited to the creature change. The tool is
`tools/capture_bramblebun_world_ab.gd`; output is
`shots/diagnostics/bramblebun-world01-fifth`.

This is audit spawning and fixed-camera habitat evidence, with hidden HUD and
frozen movement/animation. It does not validate natural encounter placement,
player-camera motion, a broad roster, or campaign completion. A fresh independent
world verdict is recorded separately in `JUDGE-BRAMBLEBUN-WORLD01.md` when ready.
