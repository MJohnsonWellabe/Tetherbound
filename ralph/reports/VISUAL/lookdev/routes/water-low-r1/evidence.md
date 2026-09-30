# Water/Low computer route

Executed source: `1186526b921f7746dbaf514f0b7f7ac0649640f7`.
Renderer: Compatibility / OpenGL 3.3, NVIDIA GeForce GTX 1060 3GB.
Native result: exit 0, no `ERROR:`/`SCRIPT ERROR:`, both waypoints reached,
201 finite positive wall-frame samples and start/end PNGs at 1920×1080.
This is **one of twelve** required biome/preset cases for F26#4.

Raw files are exact copies from the completed runner output. `matrix.json`
includes the command, isolated device/save home, elapsed time and frame-time
summary. `route.json` includes every sample, actual camera, route configuration
SHA-256 and observed environment. Mean wall frame time is 42.115 ms; P95 is
87.356 ms, P99 236.848 ms. These are computer wall-frame timings, not GPU-only
measurements or an Ally performance verdict.

The route mounted the production Tidewake scene with an empty new-character
state, used one declared start teleport and then drove actual InputMap
locomotion through live collision. The normal clock ran from hour 8.042 to
8.373 during the timed interval. There was no speedup, render suppression,
earned progression, four-creature fight or visual acceptance claim.

Independent VFX source review caught the inherited still-capture callback
suppression before this run, then passed the source repair at this exact
commit. No native route re-run is needed for later source changes restricted
to separate, unloaded visual adapters or runner summary validation. Every
future route is pinned to its own executed source. The remaining presets,
biomes, High/Medium code-blind visual matrices, Hall material path and owner
Ally gate remain open.
