# Compact empty hotbar

The five empty binding slots now use 56 px minimum height instead of 132 px.
Any assigned item keeps the full 132 px height, including a depleted stack, so
item identity/count/durability remain visible. Autofill, bindings and interaction
prompt layout retain their existing behavior.

The guarded native `compact-hotbar-dock-first` check passed quiet, message,
long-prompt and combined states without script/engine errors. All five glyphs
remain present and the dock/prompt remain separated. Native Meadows, Stormwood,
Water and Cloudreach captures show the compact state. Multiple fresh judges
preferred its reduced obstruction; this is a UI improvement, not an environment
art pass.

`broad-hud-playground-first`, 2026-09-10 03:07:20–03:08:16 UTC, completed all
production playground assertions and exited 0. Occupied hotbar and prompt
rectangles did not intersect; gather, hotbar feedback and berry farming passed.
The guard correctly marked the run non-clean because the headless dummy renderer
emitted `Parameter "material" is null` from `material_get_instance_shader_parameters`.
The identical diagnostic occurs during equipped-tool validation in unchanged
pre-HUD commit ce6f5ccc8's CI core-verb log, lines 3477–3478, retained at
`.artifacts/broad-visual-0910/ci-ce6/job-102718734126-verify-core-verb-shard.log`.
It is a pre-existing headless-renderer finding, not a clean smoke receipt or a
reason to conceal the failure. No retry was used to turn it green.
