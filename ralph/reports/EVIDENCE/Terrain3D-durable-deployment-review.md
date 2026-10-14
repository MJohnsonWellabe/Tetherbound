# Terrain3D 4.7 deployment review

October 14, 2026. Source/deployment review only: no build, binary replacement, engine execution, workflow dispatch or native-stage mutation. Root's Hall/biome GPU queue remains the native priority.

Implementation follow-up (root-authorized after this review): the existing branch now replaces only the Windows debug library with the exact accepted `5cf87b3a...` candidate. `addons/terrain_3d/BUILD_PROVENANCE.json` records all four targets, original recovery identity, build inputs, per-notice hashes and immutable proof commit `1e584e800637b8b6b5a88b33e00919c1c3fc4847`. Windows release and both Linux binaries remain stock/open. Runtime notice text accompanies the provenance through the existing staging script; target selection and library-copy behavior are unchanged. No new target-aware binary hash gate is included. No compiler, engine or shared-stage action occurred in this follow-up.

CPU verification matched the staged candidate SHA256, all four index blob IDs, the unchanged four-selector declaration, 14 staged notice hashes, the stock recovery backup and exact reconstruction of the consumed CRLF profile from the committed LF profile. Original notice hashes are retained; only line endings were normalized. Authored-code/manifest whitespace checks passed; the full check reports retained upstream notice spacing/blank-line findings (recorded, not suppressed). The nine-line shell notice-copy addition was inspected but not executed locally because Bash is unavailable. Existing accepted component/guardian evidence is reused at its original scope; package execution and optional hash-gate review remain open.

## Accepted evidence and its boundary

Root's independent `takeover-native/terrain-guardian-5bc/independent-review.json` reports `PASS_GUARDIAN_CANDIDATE_SCOPE_ONLY`: source `5bc0ac3ea71ad524d956751423f650432ac9de1b` with candidate Windows debug DLL `5cf87b3a5dea907b788f187e7ede6347f3aaba25396610269120a3cf2a903306`, natural exit 0 in 345.747 seconds. Original assertions checked active/reserve XP 228/184, typed defeat receipt, saved rewards without replay and two 382,113-instance/50,883-solid censuses. Stderr was empty and no warning exemption was used. The source includes a disclosed approach-helper correction and generated L16/cap20 boundary; this is not an earned chapter, shipping or stock-source result. Stock DLL was restored afterward according to root.

Retain the earlier failed stock-DLL witness unchanged. The successful overlay is an artifact, not a durable installed repair. Component and guardian evidence does not validate a Windows release or Linux library, editor tooling completeness, all GPU scenes, or an exported Windows package.

## Four distinct deployment targets

The committed `addons/terrain_3d/terrain.gdextension` declares `terrain_3d_init`, minimum compatibility 4.4, and four separate x86_64 libraries:

| Runtime path | Selected filename in `addons/terrain_3d/bin/` | Present repair evidence |
| --- | --- | --- |
| Windows editor/source runs and debug export | `libterrain.windows.debug.x86_64.dll` | Profile candidate component/guardian evidence only; artifact overlay |
| Windows release export, used by `release.yml` | `libterrain.windows.release.x86_64.dll` | Patched build and runtime UNRUN |
| Linux editor/source CI and debug export | `libterrain.linux.debug.x86_64.so` | Patched build and runtime UNRUN |
| Linux release export, used by `verify_export.sh` | `libterrain.linux.release.x86_64.so` | Patched build and runtime UNRUN |

Do not rename the debug DLL into the release slot, map both selectors to it, claim the Windows PE works on Linux, or weaken diagnostics. The compatibility minimum is the addon/API contract, not a warning switch; the scoped repair keeps the pinned 4.4 bindings and checks runtime version at the obsolete call. Only the locked Godot 4.7 runtime has this candidate evidence.

`ci.yml` produces Windows **debug** and invokes `tools/verify_export.sh`. `release.yml` produces Windows **release** and invokes that same verifier. The verifier itself exports and executes **Linux release**. Consequently, the current export runtime gate is useful Linux evidence but cannot establish that the selected Windows release DLL loads in the shipping executable. Checking a Windows PE header and file size does not fill that gap.

## Source and build provenance to preserve

The tested candidate is a profile build, not merely a recompilation of the stock library with one C++ condition changed. Its identity must include all of these inputs:

- Terrain3D `0077405b52e353c5e5dc3a094e7ede49833ba6fe` (v1.0.2-stable), godot-cpp `6388e26dd8a42071f65f764a3ef3d9523dda3d6e`, API 4.4.
- Patch `tools/native/terrain3d-1.0.2-runtime-interpolation.patch`, SHA256 `2ef511e3a4af884db548dbd0a1d24506153b1432d0a72e9e641aeeb86a96d7c4`. Patched mesher SHA256 `14e85373e5209bdd1ec6616840eacd8d13ef276eda88117c99c3f761c21f7d95`.
- The reviewed profile: 80 enabled names, 79 generated classes out of 952, and 145 methods omitted from retained classes by the pinned generator. Runtime coverage is bounded; future Terrain3D C++ changes require a fresh dependency-closure review.
- Exact tested profile bytes (CRLF) SHA256 `f8b88b38c88da7e254e0292ed54d709c21a680a3cb0c5e3acb16b42b062c73a1`; trimmed API bytes SHA256 `7785c54c3d85dc78ebf0c24adc5a96e838d8b47578a9c77fcc19afc34dc88bec`.
- Source-only copy now retained as `tools/native/terrain3d-1.0.2-build-profile.json`, LF SHA256 `68ffd41034910d2a66274003a8d45c5a7cde3ebe46d11d0e30838720a716c07a`. Parsed JSON equality with the tested profile was checked. This line-ending normalization does not claim byte identity or a rebuild; future build receipts must record the bytes actually consumed.
- Portable MinGW-Builds `16.2.0-rt_v14-rev1`, x86_64 POSIX/SEH/UCRT, archive SHA256 `26788998d615856a915e1eeacb0854fce87bc608fa9a0c16f96bcbfdcf3415c0`; SCons 4.4.0 wheel SHA256 `cbbd73b83cf85f1aaaf986370359de1bbfd3af97a765cb3554734f6dcec734e1`. Acquisition manifests retain compiler, linker, wheel and source-file hashes.

Recorded candidate invocation: `python -m SCons target=template_debug platform=windows arch=x86_64 use_mingw=yes debug_symbols=no build_profile=<reviewed profile> -j1`. Candidate is 3,110,912 bytes, PE AMD64, exports `terrain_3d_init`; independent static review reports only KERNEL32/UCRT imports, no external MinGW runtime DLL imports. Static runtime linkage still belongs in the retained build provenance and notice inventory. Keep Terrain3D/godot-cpp MIT notices and the applicable linked-runtime notices from the pinned toolchain; compiler tools themselves are not game payload.

Windows release needs its own `target=template_release` output and review. Linux needs a pinned Linux toolchain/environment and both `template_debug` and `template_release` builds using the same source, patch and reviewed profile; the Windows MinGW environment does not supply those Linux artifacts. Neither acquisition nor build is authorized by this review itself. Root retains admission and resource controls, including the failed full-profile build evidence.

## Durable integration and package checks

1. Preserve this source recipe/profile and exact build manifests independently of temporary directories. Record each accepted artifact's target, SHA256, size, architecture, dependencies, source/patch/profile hashes, command, toolchain identity, runtime evidence and scope. Use explicit local fork provenance; do not present patched/profile binaries as official upstream v1.0.2 release bytes.
2. Root may integrate an independently accepted Windows debug candidate as a **Windows-debug-only** repair. The per-target manifest must still show the other three stock hashes and their open repair status. A complete project-wide repair requires all four individually built and verified outputs; a debug-only landing cannot close release/Linux acceptance.
3. Keep the four established filenames and selector mapping. Commit accepted binaries with their provenance together, or introduce a deterministic hash-verified artifact acquisition step before **every** import/test/export consumer. A dependency downloaded only during release leaves source CI and editor runs on stock. The existing committed-binary layout is the smaller deployment change.
4. `tools/stage_gdextension_libs.sh` prefers the export-directory flat library and mirrors it to its `res://` path; if absent, it copies the project library. It traverses all platform entries, so Windows packages also receive the fallback Linux files and the other build mode. It currently checks existence, not approved target/hash, and can succeed with zero staged files. Before shipping a repair, require the selected flat and nested library hashes to match the target's accepted manifest; preserve required non-selected entries honestly, or separately review a target-filtered staging change. Do not silently trust a stale flat file over the reviewed project binary.
5. Validate the actual exported Windows release executable with its `.pck` and selected release DLL, then the final ZIP's contents/hashes. Retain Linux release export coverage separately. Reuse unchanged component/guardian evidence at its exact identity; do not relabel it as release evidence or rerun broad suites merely to populate the matrix.

Pending concrete dependencies: Windows release artifact/acceptance, Linux debug and release toolchain/artifacts/acceptance, target-aware package hash gate and actual Windows release runtime check. None were built or changed in this review. Shipping and earned-chapter criteria remain open.

Local evidence read: `C:/CodexTemp/tetherbound-terrain-build/{source-manifest.json,acquisition-review.json,profile-candidate.json,build-profile-review.json,build-r2-profile/receipt.json,build-r2-profile/independent-static-review.json}` and coordinator `ralph/reports/EVIDENCE/takeover-native/{terrain-profile-build,terrain-profile-runtime,terrain-guardian-5bc}/`. The recorded proof dispositions are preserved, including older preparation-only statuses in immutable manifests.
