# Grass normal candidate — independent source review

2026-09-27. Read-only inspection of both grass shaders, their production material/mesh builders and the local paired capture script. No engine, import or production edit. No visual verdict.

**Verdict: the back-face correction is consistent with the shaders' existing upward-lighting intent. Use the proposed dedicated Cloudreach grass flag, including both Cloudreach material factories. No source blocker found for that bounded implementation.**

## Compatibility mechanism

The project pins Godot 4.7 Compatibility. Its [4.7 GLES3 material compiler](https://github.com/godotengine/godot/blob/4.7-stable/drivers/gles3/storage/material_storage.cpp#L1307) enables `DO_SIDE_CHECK` for `cull_disabled`. The [4.7 scene shader](https://github.com/godotengine/godot/blob/4.7-stable/drivers/gles3/shaders/scene.glsl#L2058) negates back-face normals before invoking user fragment code. Thus `if (!FRONT_FACING) { NORMAL = -NORMAL; }` cancels that inversion and retains the interpolated authored normal on either side. It does not flatten every normal to world UP or add emission.

`grass_field.gdshader` explicitly changes each blade normal to `normalize(vec3(nx*.35, 1, nz*.35))`, then applies its lattice yaw. `cloudreach_ground_cover.gdshader` blends the input normal toward local UP in vertex. Without the correction, back-face lighting reverses those intentionally upward vectors. Restoring them changes diffuse/ambient response, and the field's directional BACKLIGHT response, while preserving tint, roughness, translucency values, geometry, wind and alpha/depth rules. This is stylized field lighting, not physically distinct front/back leaf normals.

## Production scope and guard

- `grass_field.gdshader` is loaded as the GrassField's grass material. Stone, generic cover-tier and far-cover layers have separate shader paths; an unconditional correction in this dedicated shader does not reach those layers.
- Cloudreach's shader is shared by grass, flowers and understorey bushes. Do not apply the correction unconditionally there. `camera_clearance` currently selects the grass materials, but it controls near-camera geometry shrinking and is not a durable lighting classification.
- Add `uniform bool grass_upright_normals = false;` to the shared Cloudreach shader and gate the fragment correction with it. Enable it for `grass_material` and `dry_grass_material` in `cloudreach_ground_cover.gd::build`.
- **Also enable it in `cloudreach_look.gd::_tuft_material` (around line 1206).** That factory supplies the main, dry and far tuft materials (calls around lines 858–860). Omitting this factory would leave another visible grass population on the old lighting path.
- Leave the common `_cover_material` default unchanged so flowers, leaf cards and woody bush components remain false. No palette, scattering, clearances or non-grass lighting change is needed.

## Transforms and limits

Cloudreach uses positive nonuniform instance scales and UP-axis yaw; GrassField lattice instances use identity bases and shader-authored yaw/shape. The fragment negation is applied after the engine's normal transform, so it restores that transformed vector without introducing a second scale transform. Sign cancellation commutes with a linear normal transform, including inverse-transpose; it does not require manually constructing world UP. [Godot's spatial shader reference](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html#fragment-built-ins) documents fragment NORMAL/view space and the nonuniform-scale normal matrix.

This does not correct any pre-existing discrepancy between deformed blade geometry and its deliberately softened normal, nor establish that every renderer/instance scale has physically exact normals. Neither shader currently uses a tangent-space normal map, so NORMAL alone is sufficient for this correction. A future normal-map/TBN change would need another review. Neither enables vertex lighting; forced vertex-lighting configurations would need separate validation because fragment changes cannot redo vertex-computed direct light.

No vertices, draws, textures or extra texture reads are added. The cost is a small fragment-facing condition/negation and a uniform guard on Cloudreach. Shadow silhouette, alpha cutout and vertex shadow bias inputs remain unchanged. Device timings are not established by this source review.

## Probe evidence limits

The local harness changes the loaded shader in memory, pairs the same live scene/stand, waits 24 process frames per variant and restores baseline code after each pair. Its Cloudreach `camera_clearance` guard reaches current grass factories while leaving flowers/bushes unchanged, so it is a reasonable diagnostic proxy for the dedicated flag above. Confirm the final production flag covers the same materials.

Wind/time can advance between sequential pairs; this is not a deterministic per-pixel proof of identical blade positions. Staged fixtures and camera-arm checks do not establish traversal, all lighting/camera conditions, device performance or visual acceptance. Native comparison remains the parent's separate evidence lane.
