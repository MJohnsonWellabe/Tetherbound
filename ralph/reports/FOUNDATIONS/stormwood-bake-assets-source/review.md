# Offline asset configuration source review

The coordinator's camera-corrected bake at integration
`862385aa92f4b198cc5ccf22448d66f8acfb6e28` reported two initial native errors
loading an empty resource path. The previous camera error was absent. That bake
remains failed, and its output must not establish acceptance.

The installed plugin declares version 1.0.2. The corresponding official stable
[native source](https://github.com/TokisanGames/Terrain3D/blob/0077405b52e353c5e5dc3a094e7ede49833ba6fe/src/terrain_3d.cpp)
initializes a blank asset list during `set_camera()`, then reloads a valid asset
list from its resource path on tree entry when `free_editor_textures` is enabled.
Its entry condition lacks an empty-path check. The
[header](https://github.com/TokisanGames/Terrain3D/blob/0077405b52e353c5e5dc3a094e7ede49833ba6fe/src/terrain_3d.h)
defaults the setting to true. This matches the observed empty-path errors after
the camera initialized the dynamic assets. This is source-based diagnosis;
the installed DLL's exact upstream build commit is not asserted.

The [official API](https://terrain3d.readthedocs.io/en/stable/api/class_terrain3d.html#class-terrain3d-property-free-editor-textures)
documents texture freeing at readiness and reloading on tree entry. The local
Water baker and Water runtime both disable this optimization for dynamically
created Terrain3D nodes. Stormwood now applies that same setting immediately
after instantiation, before the real camera and tree entry. This retains the
in-memory asset list rather than attempting to reload a nonexistent asset file.

The correction adds only a comment and this existing configuration call.
Subtracting those two lines reproduces the coordinator's entire pinned producer.
The other five fingerprint sources are preserved. Physics, rendering, camera,
heightfield, imports, painting, region scope, saves, and freshness logic remain
unchanged. There is no error filtering or assertion change. The source cut pins
the primary-source reference bytes and proposed fingerprint; runtime validation
requires the coordinator's fresh full bake and native channel comparison.

No engine, import, parser, render, bake, CI, agent, manifest, region, or coordinator
worktree writes occurred here.
