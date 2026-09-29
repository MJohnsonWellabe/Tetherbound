# Local Tidewake shadow diagnostic source notes

Research date: 2026-09-28. Scope: local diagnostic only. No production change or visual acceptance follows from this note.

## Observed evidence supplied by root

- Five-case Gull Rest surface ablation: banding survives removing ripples and procedural grain; setting shadow opacity to zero removes it. Flat fragment normals worsen jagged edges.
- Six-case bias/normal ablation: normal bias zero worsens bands; constant bias .2 provides no useful improvement; corrected vertex normals change the cliff boundary but leave bands.
- Therefore do not integrate corrected normals or treat this as a palette problem.
- The first ablation manifest records Sun normal bias approximately 1.7, constant bias .06, shadow opacity 1, shadow mode 1 and maximum shadow distance 220 m. Installed Terrain3D plugin.cfg is version 1.0.2.

## Primary sources

1. [Godot 4.7-stable Compatibility rasterizer](https://github.com/godotengine/godot/blob/4.7-stable/drivers/gles3/rasterizer_scene_gles3.cpp#L1809): directional receiver normal bias is the Light parameter multiplied by each cascade's shadow texel size. Thus 3.4 and 6.8 double/quadruple the 1.7 contribution for an unchanged cascade; they are not metre offsets. The directional caster constant-bias path separately divides the Light parameter by 100 and applies its bias scale.
2. [Godot 4.7-stable Compatibility scene shader](https://github.com/godotengine/godot/blob/4.7-stable/drivers/gles3/shaders/scene.glsl#L791): shadow coordinates are computed in vertex processing using normalized vertex normals and light direction. Directional fragment shadow sampling uses those interpolated coordinates. Fragment LIGHT_VERTEX updates happen afterward and do not rebuild the coordinates. The built-in caster bias also scales with light-view distance.
3. [Godot issue 101119](https://github.com/godotengine/godot/issues/101119): open issue reporting LIGHT_VERTEX does not affect Compatibility shadows. Its reproduction used 4.3/4.4-dev; the 4.7 source above independently establishes the relevant path, rather than assuming the old report alone proves current behavior.
4. [Godot 4.7 spatial shader reference](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/spatial_shader.html): IN_SHADOW_PASS identifies shadow-map rendering. With skip_vertex_transform the shader supplies view-space VERTEX while projection still follows. [Compatibility compiler mapping](https://github.com/godotengine/godot/blob/4.7-stable/drivers/gles3/storage/material_storage.cpp#L1297) and [registered built-in](https://github.com/godotengine/godot/blob/4.7-stable/servers/rendering/shader_types.cpp#L83) confirm availability.
5. [Godot Light3D reference](https://docs.godotengine.org/en/4.7/classes/class_light3d.html#class-light3d-property-shadow-bias): insufficient bias causes self-shadowing; excessive bias separates shadows from casters. Normal bias moves the shadow lookup along the normal.
6. [Terrain3D shader design](https://github.com/TokisanGames/Terrain3D/blob/main/doc/docs/shader_design.md): terrain normals are intentionally calculated in fragment processing because clipmap LOD spacing makes vertex normals problematic. [Maintainer issue 169](https://github.com/TokisanGames/Terrain3D/issues/169) documents vertex-normal artifacts at the LOD0/1 boundary. Current upstream explanations are context, not a claim that the installed 1.0.2 plugin matches current main or should be upgraded.

## Next diagnostic: inference to test, not an established fix

`dune_shadow_receiver_ablation.gd` retains the existing validated Gull Rest Beach day/close stand and original normals. Despite the filename, its terrain-specific intervention changes CASTER depth. Cases:

| Case | Sun normal bias | Constant bias | Terrain caster offset |
|---|---:|---:|---:|
| baseline | measured baseline, expected 1.7 | measured baseline, expected .06 | 0 |
| normal_bias_34 | 3.4 | baseline | 0 |
| normal_bias_68 | 6.8 | baseline | 0 |
| terrain_shadow_push_002 | baseline | baseline | .02 m |
| terrain_shadow_push_005 | baseline | baseline | .05 m |
| terrain_shadow_push_010 | baseline | baseline | .10 m |

After the terrain's existing world-to-view VERTEX assignment, only the last three cases inject `if (IN_SHADOW_PASS) { VERTEX.z -= offset; }`. Negative light-view Z moves the terrain caster farther from the light. Ordinary visible terrain, collision, fragment materials, original normals and other objects' caster shaders remain unchanged. No LIGHT_VERTEX workaround, global shadow disable or opacity reduction is used.

Each case resets original code, modified shader uniforms and the pinned daytime Sun shadow settings; readbacks include active/original shader hashes, normal/constant biases, opacity, enabled state, mode and maximum distance. Finish restores the original shader/resource settings through the existing shell.

Judge band removal separately from trainer/creature contact shadows, grass/rock shadows and cliff boundaries. Terrain-cast shadows may shift with caster depth; preservation must be inspected, not inferred from source. Higher global normal bias can detach other objects' shadows. Keep all candidates local pending native comparison. No performance conclusion follows from these stills.
