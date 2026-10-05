# Packaged PERF A/B instrumentation review

Reviewer `/root/f26_lookbar_review`: PASS for revised source, pending native
execution. Author actual check-only parsing against both isolated pinned PCKs:
PASS, exit 0, zero ERRORs with Godot 4.7 official `5b4e0cb0f`.

Both packs use the same external overlay and editor-capable engine host with
explicit `--main-pack`; there is no source filesystem fallback. Standard export
templates prohibit `--script`. This is a diagnostic engine-host comparison,
separate from shipping release FPS, shipping qualification and Ally acceptance.

BEFORE game source is `946bb39e55ba4485868b611eb0c15e5eb7c7be0c`.
Its export representation uses text mode 0 instead of binary mode 2 solely to
preserve production baked-scatter fingerprint inputs. Export exited 0 but its
seven shutdown resource-leak ERRORs retain a shipping preflight FAIL. The actual
produced PCK independently passed the production fingerprint/108-region check
with zero errors. Diagnostic use does not change that failed export verdict.
AFTER uses the byte-identical previously qualified release PCK from
`1b85fb4d985b7d622e022867055770b2f0de6b18`.

Review checked payload/dependency hashes, matching uncapping, production route
inheritance, camera floors, per-frame monitor alignment, slowest ceil(1%) FPS
math, required usable GPU profiler blocks, and child cleanup before lock release.
GPU interval markers exclude screenshot I/O and the first partial warmup block.
The engine profiler unregisters before debugger shutdown. Its samples require
matching route process-frame IDs and exclude partial boundary iterations.

Godot TIME_PROCESS and TIME_PHYSICS_PROCESS are cached approximately one-second
maxima. Correlation to slowest wall frames does not make them frame-specific CPU
costs. Supplemental EngineProfiler physics_time is the maximum individual
physics-step CPU duration in an engine iteration; physics_frame_time is the
simulation delta, not a CPU duration. Do not divide the maximum by step count.
Primary source: [pinned engine iteration](https://raw.githubusercontent.com/godotengine/godot/5b4e0cb0f/main/main.cpp).

No scene, realm floor, default, STATE, or Claude lane source changes.
