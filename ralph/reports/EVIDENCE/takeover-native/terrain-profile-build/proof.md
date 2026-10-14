# Terrain3D profiled debug build and pending native validation

Build/static review PASS. This document preserves the preparation state before root admission on October 13 at 11:54 PM US Central, when runtime was UNRUN and the DLL had not yet been installed. Root subsequently installed the disclosed candidate overlay and completed the bounded component checks; see [runtime proof](../terrain-profile-runtime/proof.md). Guardian and broader release, platform and visual criteria remain open. No binary DLL is committed here.

## Exact candidate and inputs

- DLL artifact: `C:/CodexTemp/tetherbound-terrain-build/Terrain3D-profile/project/addons/terrain_3d/bin/libterrain.windows.debug.x86_64.dll`, 3,110,912 bytes, SHA256 `5cf87b3a5dea907b788f187e7ede6347f3aaba25396610269120a3cf2a903306`.
- Original official Windows debug DLL remains recoverable and unchanged: SHA256 `bf72686a7e1d8d8370ba9ba5eaa70c59375ee2cb5638d63b8942f1ad7d448cda`. Root must preserve and verify it before any isolated overlay.
- Terrain3D source `0077405b52e353c5e5dc3a094e7ede49833ba6fe`; godot-cpp `6388e26dd8a42071f65f764a3ef3d9523dda3d6e` (4.4 API). All 187 selected source/build/header/API/doc-generation inputs matched pinned Git blob IDs and SHA256. No demo assets acquired.
- Patch SHA256 `2ef511e3a4af884db548dbd0a1d24506153b1432d0a72e9e641aeeb86a96d7c4`; resulting mesher SHA256 `14e85373e5209bdd1ec6616840eacd8d13ef276eda88117c99c3f761c21f7d95`. It is the sole authored source difference.
- Official MinGW-Builds GCC16.2.0 x64 POSIX/SEH/UCRT archive SHA256 `26788998d615856a915e1eeacb0854fce87bc608fa9a0c16f96bcbfdcf3415c0`, 107,890,935 bytes; matched GitHub release digest before extraction. SCons4.4.0 wheel SHA256 `cbbd73b83cf85f1aaaf986370359de1bbfd3af97a765cb3554734f6dcec734e1`; all isolated Python wheels matched their exact PyPI hashes.
- MIT source notices, compiler component licenses, GCC Runtime Library Exception3.1 and MinGW-w64 runtime notices are retained. The complete compiler suite is not a game dependency to distribute; required notices remain with the candidate evidence.

## Two bounded build outcomes

The first full binding build was deliberately stopped at its 600-second cap at 11:16PM CT on October13. It remains FAILED/capped, with334 of952 generated class objects preserved and no DLL. It did not fail a compiler diagnostic. Its receipt SHA256 is `d371d1dc43b35ef4291fb12e6b3e2c536470cb052686fac5b859c09597cf2d87`; the second run does not overwrite or relabel it.

After separate root admission, the profile build completed compile/link in258.25 seconds around11:24PM CT with exit0 and empty stderr. Command: `python -m SCons target=template_debug platform=windows arch=x86_64 use_mingw=yes debug_symbols=no build_profile=<terrain-profile-80.json> -j1`. Receipt SHA256 `ae3b9d29fa98caa0cac8dc505183e0dd6f7e1aff79b16da4f3c1560bd9a6171d`.

The DLL is AMD64 and exports `terrain_3d_init`. Static import inspection found KERNEL32 and Windows UCRT API sets only, with no additional libgcc/libstdc++/libwinpthread DLL requirement. Static inspection is not a successful loader test. All logs matched receipt hashes. Resource minima in the successful run: C14,016,999,424 bytes free; physical RAM3,619,229,696; available commit3,953,438,720. Scratch peaked at1,035,516,344 bytes, below3GiB. Original pre-acquisition C free was15,966,998,528 bytes; concurrent machine activity means drive delta is not an allocation attribution. No cleanup/deletion was needed.

## Why the patch is appropriate, and what remains uncertain

Godot moved 3D interpolation into the SceneTree in [PR104269](https://github.com/godotengine/godot/pull/104269). The [4.5 RenderingServer compatibility method](https://github.com/godotengine/godot/blob/4.5/servers/rendering_server.compat.inc#L48-L53) only emits a warning; it does not mutate interpolation or transforms. [Terrain3D PR772](https://github.com/TokisanGames/Terrain3D/pull/772) already gates the call by compile-time4.4 and reports testing4.5 with interpolation enabled. The patch additionally checks the running engine, preserving reset on4.4 while avoiding the obsolete call on4.7. All transform writes remain intact. A Node reset replacement would act on a different abstraction and is unnecessary for these direct rendering RIDs.

Exact locked4.7 engine source was not retrieved by this review; the4.7 raw-source tag/hash requests returned404. Therefore compatibility reasoning is supported by the4.5 transition and the observed old-DLL warning, while actual4.7 behavior remains a native validation gate.

The official pinned build-profile generator includes ancestors and mandatory low-level classes, and removes methods referencing omitted classes. Source audit selected80 names, yielding79 generated API classes (ClassDBSingleton is synthetic), excluding873 classes and145 methods on retained classes. Exact differences are embedded in `raw-evidence.json`. Profile SHA256 `f8b88b38c88da7e254e0292ed54d709c21a680a3cb0c5e3acb16b42b062c73a1`; trimmed API SHA256 `7785c54c3d85dc78ebf0c24adc5a96e838d8b47578a9c77fcc19afc34dc88bec`.

This trims extension C++ wrappers, not the engine's GDScript/ClassDB API. All current Terrain3D C++ units linked successfully, ruling out direct unresolved wrapper calls in this build. It does not establish editor callback coverage, all resource/instancer paths, future source compatibility, or release/Linux behavior. No missing function was stubbed and no compiler diagnostic was suppressed. Terrain runtime tests below remain necessary.

## Preserved preparation packet: NOT ADMITTED at build-stage review

`native-request.json` binds coordinator source `5bc0ac3ea71ad524d956751423f650432ac9de1b`, locked engine SHA256, exact DLL and the adjacent leaf. It lists 1,652 source/resource Git blob bindings. The prepared executable supervisor additionally verifies 876 materialized input SHA256/size snapshots (44,314,860 bytes), covering resident assets plus recursively referenced GDScript/config dependencies. Stock Git ancestry and index are checked separately from the disclosed DLL/leaf overlay; no claim of stock-source runtime is permitted. Root may reuse the existing native stage only under a fresh idle-writer lease, verified clean base, canonical input materialization, and byte-exact external backup of the original DLL. This packet remains NOT_ADMITTED.

1. Parse the small component leaf,45s cap.
2. Run existing `tests/smoke_f18_resident_terrain_support.gd` unchanged,120s cap: real Meadows terrain, dynamic collision movement, body contacts and control-hole rejection.
3. Run `terrain_clipmap_component.gd`,120s cap, Compatibility renderer. Four near/step/far/return cameras use actual committed terrain with interpolation enabled and no background terrain fill. Require nonblank visible-versus-hidden terrain pixels, exact native snapped positions, resident regions and stable LOD count. Independently verify each LOD's native snap log against the source formula and inspect eight PNGs for holes/seams. Fixture camera/light/grey material are disclosed; this is not an art score, earned route or performance proof.
4. Only after those independent checks pass, re-admit the original guardian reward witness with its600s cap, unchanged assertions and two scatter censuses. Original d36 FAILED evidence remains retained. The deprecated RenderingServer warning must be absent: no warning allowlist, stderr suppression or test weakening.

At this preparation checkpoint the leaf had not been Godot-parsed or executed; the later bounded parse/runtime result is recorded separately in the linked runtime proof. Root must review source changes since d36 before reusing historical focused prerequisites, preserve the original DLL, and apply the disclosed candidate overlay only after fresh admission. Stop at the first failure and preserve outputs.

`raw-evidence.json` contains 38 exact UTF-8 files (1,160,533 raw bytes), including both receipts/logs, build/source/provenance reviews, patch, profile/differences, licenses and the pending runtime packet. Each embedded text round-trips byte-for-byte with its recorded SHA256; no binary DLL is embedded. Nothing here claims runtime PASS.

## Executable admission packet

The copied `native-supervisor/run_terrain_profile_validation.ps1` reuses the proved root resource/lease/owned-process guards. It launches only parse (45 seconds), unchanged resident physics (120 seconds, exact 28 checks), and clipmap render (120 seconds). It uses fresh short per-step homes and preserves failures. Original guardian replay remains a separately admitted follow-up.

- Supervisor SHA256: `c280f149aa8e03f42843247becde55b7b2639c9999334d4edb7e5dbd274762d3`.
- Job SHA256: `9400208b3fc2ac6af28a5f54b46c31f96c275fba1e40b11e1b0d618301d87f00`.
- Request SHA256: `57ab04b19da7e8c950d19632cd12a8b1da5ad530f9b6e98bffe9391b3ecb9147`.
- Leaf SHA256: `baebfdc13f344916624ba736846730db80e54187542f729e942ba1348ba2f442`.

CPU-only packet preflight passed. Synthetic postcheck fixtures accept valid snap/image data and reject wrong LOD positions and blank terrain. These are supervisor checks, not native proof. The independent pixel/log validator is also bound by the job.

Fixture verbosity returns from EXTREME to normal before node destruction/quit, after collecting required snap observations. This respects the native logger's documented debug-on-quit hazard; warnings and errors remain enabled, and the original deprecation is never allowlisted. Settled near/far frames establish component visibility and clipmap placement only. They cannot establish transient interpolation correctness or replace the original guardian warning gate. Raw snapshots bind resident inputs and code/config closure; dormant unrelated art/report references do not become claims of runtime coverage.

Independent source review found no blocking source findings. It independently verified all 876 canonical snapshot SHA/length bindings against source 5bc and repeated CPU packet preflight. The initially reported six missing raw bindings were a reviewer field-selection error, explicitly withdrawn in `independent-source-review.json`. Those native checks were UNRUN at this source review; the linked runtime proof records the subsequent component results. Guardian remains separate.

The later separately admitted generated-boundary guardian warning gate also passed; see [candidate guardian proof](../terrain-guardian-5bc/proof.md). This does not rewrite the historical build/source checkpoint or its immutable raw bundle and does not establish shipping acceptance.
