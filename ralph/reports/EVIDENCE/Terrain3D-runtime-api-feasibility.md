# Terrain3D runtime API repair feasibility

Status: source patch prepared and application checked; no compiler, extension build, engine run, native-stage mutation, or acceptance claim.

The d36 guardian remains FAILED under the existing warning policy. All gameplay witness assertions passed, but the native Terrain3D initialization called the deprecated RenderingServer compatibility method. Raw evidence remains at `D:/tetherbound/.artifacts/s/run-d36guardian-r1`; the supported Node reset calls in playground_world.gd are unrelated.

## Exact installed provenance

All four native-stage x86_64 libraries match the official Terrain3D v1.0.2-stable archive byte-for-byte. The bounded download is 42,312,488 bytes, SHA256 `a071850250ec5e596aa54da61c01d75768774eb379ee997584d426a45f4884a2`. No library was extracted into the project or stage.

| Library | SHA256 |
|---|---|
| Windows debug | bf72686a7e1d8d8370ba9ba5eaa70c59375ee2cb5638d63b8942f1ad7d448cda |
| Windows release | 40900e649c3c6c7619c383d28732c3e2e8dc87c2938de43b29122a668aedcf86 |
| Linux debug | 178ae39467bb0743c1bbdf854a00f8e7d258a3691bcc1b63d4493beb6bde865e |
| Linux release | e79ebb2e48a63a5d6189a825f1d63ec847319dc8fa030936d95bf6fad8f294ef |

[Official release](https://github.com/TokisanGames/Terrain3D/releases/tag/v1.0.2-stable) tag object `4b4c4117b4ab099d588e9964551e7a65d333e511` resolves to source commit `0077405b52e353c5e5dc3a094e7ede49833ba6fe`. Its godot-cpp gitlink is `6388e26dd8a42071f65f764a3ef3d9523dda3d6e`; extension_api.json identifies Godot 4.4.0 stable. Source mesher blob is `38922802f009719510c477932566d976f8df6335` (verified by Git blob hash).

At that exact source's `src/terrain_3d_mesher.cpp:383`, the old call is gated by compile-time GODOT_VERSION_MINOR == 4. That admits it when the 4.4-built binary runs on Godot 4.7. Upstream [issue771](https://github.com/TokisanGames/Terrain3D/issues/771) and [PR772](https://github.com/TokisanGames/Terrain3D/pull/772) document removal of the server interpolation API for 4.5+. Reinstalling the latest stable archive cannot change this behavior because it is already installed. This corrects the earlier uncertainty about mismatched local binaries.

## Minimal source change

`tools/native/terrain3d-1.0.2-runtime-interpolation.patch` adds the Engine header and a cached runtime version check inside the existing compile-time guard. It invokes the server reset only when the running engine is also 4.4. On 4.5+ it skips this obsolete call, while retaining every terrain transform, collision and mesh operation. It does not suppress diagnostics or alter Godot, bindings, shaders, terrain assets or addon APIs. Patch SHA256 `2ef511e3a4af884db548dbd0a1d24506153b1432d0a72e9e641aeeb86a96d7c4`; `git apply --check` passed against the verified exact source blob. Compilation and runtime behavior are UNVERIFIED.

## Prerequisites and bounded build proposal

No Terrain3D C++ source checkout/build recipe is vendored in this game. No cl, clang++, g++, SCons, Docker, CMake or Ninja was found on PATH; the bundled Python cannot import SCons. Targeted standard Visual Studio/LLVM/MSYS locations were absent. The local tools/cache/Downloads inventories found no native Terrain3D checkout or compiler. WSL returned install/help output rather than an installed distribution. These are bounded search results, not a claim that every disk location was inspected.

The pinned upstream Windows workflow cross-compiles on Ubuntu22.04 using mingw-w64 POSIX, SCons4.4.0, and `scons target=template_debug platform=windows arch=x86_64 debug_symbols=no -j2`. A suitable compiler environment is the concrete unavailable local prerequisite. Do not substitute a whole new Terrain3D branch or upgrade the Godot lock to get around it.

For root's later serialized build:

1. Supply a verified x86_64 compiler/linker environment and isolated SCons4.4.0. Obtain only the exact Terrain3D and godot-cpp commits above; hash/pin source inputs and compiler versions. Keep any dependency acquisition separately bounded before build admission.
2. Apply the patch with a clean application check. Build only the Windows debug extension first with `scons target=template_debug platform=windows arch=x86_64 debug_symbols=no -j1` (MinGW/compatible host environment). Never invoke or build Godot.
3. Proposed initial stop limits, not measured resource predictions: one compiler job, 900s wall time, 2GiB build-directory growth, 1.5GiB build-process-tree commit; retain root's existing machine memory/disk floors, with admission stricter if needed. Abort rather than expanding limits automatically. Do not run alongside a native proof.
4. Record source/patch/compiler/command and resulting DLL hash. Root independently reviews it, inspects required DLL dependencies, and stages only after fresh admission. First run a bounded real Terrain3D initialization/transform smoke on the locked Godot4.7 with unchanged diagnostic policy. Then rerun guardian only if that check passes. A quiet warning stream alone is not terrain/collision correctness proof.
5. Build Windows release and both Linux libraries serially from the same patch before a portable shipping dependency claim; the debug-only prototype does not close release or Linux evidence.

Audit inputs and exact comparison JSON: `D:/tetherbound/.artifacts/codex-takeover-systems/terrain-feasibility/`. The official archive, fetched source excerpts, upstream tree, binding API header, and patch preparation script are retained there. No purchase, toolchain install, build or native-stage change was performed.
