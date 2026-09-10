# FOLIAGE-BACKLIGHT01 candidate

2026-09-09/10. Bounded shared foliage-material candidate. This record does not
claim visual acceptance: no Godot process was launched in this lane. The root
coordinator owns the guarded import/render and fixed-frame comparison.

## Visible finding

The inspected production frames are:

- `shots/catalogue/meadows/broad-basal01/meadows__band1_lower_meadows__02__the_south_bridge__day.png`
- `shots/catalogue/stormwood/broad-platform-basal01/stormwood__dynamo__11__the_glass_field__day.png`

South Bridge's near-right bush becomes one dark opaque-looking mass with sharp
overlapping leaf contours while the terrain and spike grass behind it carry
strong direct light. Glass Field shows the same flat card response in its
near/mid foliage, even though Stormwood uses the source red leaf sheet rather
than the Meadows green replacement. The defect therefore survives different
albedo families and is not evidence for another shared exposure, grade,
emission, grass-density, or retexture pass. `JUDGE-SOUTHBRIDGE-BASAL01.md`
independently names the dark bush's missing internal value variation and flat
overlapping silhouettes.

## Production source evidence

Both target realms use the same installed model and the same material builder:

- `Bush_Common.gltf` has one `Leaves_TwistedTree` material. It declares
  `alphaMode=MASK`, `doubleSided=true`, `metallicFactor=0`, and only a base-colour
  texture. It has no normal, AO, or transmission texture.
- Its primitive does carry `NORMAL`; decoding the real accessor found 1,800
  vertices and 1,799 unique normals. `COLOR_0` is white on all 1,800 vertices.
  There is useful rounded geometric shading to preserve, and no black vertex
  colour multiplication to repair.
- The installed `stylized_nature` directory contains bark normal textures but
  no leaf normal texture. All configured `Leaves`, `Leaves_*`, and `Flowers`
  materials similarly lack a normal texture.
- Meadows' `vegetation.json` replaces/desaturates/tints the bush leaf.
  Stormwood's `stormwood_vegetation.json` places `Bush_Common.gltf` without a
  leaf override. `stormwood_world.gd` passes that realm config through the same
  `vegetation.gd` renderer Meadows uses.
- `vegetation.gd::_tint_for()` rebuilds the source as a StandardMaterial3D,
  copies the absent normal slot, sets roughness 0.94, and disables specular. It
  preserves double-sided alpha scissor but previously supplied no thin-surface
  backlight. Leaf faces turned away from the directional light therefore fall
  to ambient and merge into the observed cutout mass.

Godot documents StandardMaterial3D Back Lighting as transferring light from the
lit side to the opposite side and specifically identifies plant leaves and
grass as suitable thin surfaces:
<https://docs.godotengine.org/en/latest/tutorials/3d/standard_material_3d.html#back-lighting>.
This is direct-light response rather than emission and works in the project's
Compatibility renderer.

## Candidate

`data/config/art.json` now exposes the shared tunable
`environment.foliage_backlight_strength = 0.28`. The new
`ImportedMaterials.apply_thin_foliage_backlight()` applies that neutral value
only when a material is named exactly `Leaves`, begins with `Leaves_`, or is
named `Flowers`. It does not change albedo/texture, normal, transparency, cull,
shadow casting, exposure, ambient, emission, grass shaders, geometry, scatter,
or scale. Bark, roots, poles, trunks, rocks, opaque imported grass, characters,
and creatures do not pass the name gate.

The bounded call graph reaches the installed foliage family in all four realm
builders without claiming that unrelated vegetation systems share it:

| Realm/path | Actual material construction |
| --- | --- |
| Meadows scatter and Stormwood scatter | `scripts/world/vegetation.gd::_tint_for()` |
| Meadows authored harvest instances | `scripts/world/harvest_node.gd::_fixed_up_material()` |
| Meadows perimeter hedges/canopies | `scripts/world/world_perimeter.gd::_bush_mesh()` / `_tree_mesh()` |
| Water island scatter and Veilfall authored groves | `scripts/world/water_vegetation.gd::_presentation_mesh()`; Veilfall calls `add_authored_placements()` into this path |
| Cloudreach route bushes/flowers and installed trees | `scripts/world/cloudreach_world.gd::_apply_tree_palette()` |

Procedural Cloudreach solid-colour leaf primitives and custom GrassField output
are different material families and remain unchanged.

## Static verification and freeze

A Node static check parsed `art.json`, asserted the exact three material-name
branches, rejected bark from the gate, and required the helper call in the five
production constructors above. It reported:

```text
art.json valid; foliage_backlight_strength=0.28
meadows_stormwood -> scripts/world/vegetation.gd bound
authored_harvest -> scripts/world/harvest_node.gd bound
water_veilfall -> scripts/world/water_vegetation.gd bound
cloudreach -> scripts/world/cloudreach_world.gd bound
meadows_perimeter -> scripts/world/world_perimeter.gd bound
leaf gates pass; bark excluded
```

`git diff --check` is clean. Source was frozen at `2026-09-10T04:08:30Z`:

| File | SHA-256 |
| --- | --- |
| `data/config/art.json` | `CD5FBD9A25E6F543F30884A479832BFCDAEDC2E6FA2D75D8908B8319D55BAA66` |
| `scripts/world/imported_materials.gd` | `4D2BB3DAC25D61A028249C65F43A05BE281A75BF52828BA523766026645D5092` |
| `scripts/world/vegetation.gd` | `DBE0A083A66A5989741097DD00135622015EB2808FB186E206324C7CB4D9F370` |
| `scripts/world/harvest_node.gd` | `66155E09BCC6220BD6F3AD413ECF6739FF6E8449B51E41800ECBA02AC7481143` |
| `scripts/world/water_vegetation.gd` | `E1C2A09825360324F0E6E1167A516F54AB281F7425373C819F2199B19C2E512B` |
| `scripts/world/world_perimeter.gd` | `A4DFF4DF4E753A63B07571435E31A86B99E0B543CFA911A198F13C4C7E21D10E` |
| `scripts/world/cloudreach_world.gd` | `4F1FEFB504A16AAF86E07EA456385DBB669299FA1D47404C0527883FB02E650F` |

The Cloudreach file hash includes a pre-existing concurrent far-turf hunk from
another lane. This candidate's Cloudreach scope is only the imported-material
helper preload and `_apply_tree_palette()` leaf/flower gate and call.

## First guarded render and blind disposition

Root's guarded native Meadows capture ran from
`2026-09-10T04:13:11.5005809Z` through `04:14:47.9571428Z`, exited 0, reported
no errors, and left no Godot process in its census. It wrote four production
catalogue frames to `shots/catalogue/meadows/broad-foliage-backlight01` using
the ordinary catalogue survey at South Bridge and Grandpa's Rest, day and
night.

`JUDGE-SOUTHBRIDGE-BACKLIGHT01.md` blindly preferred the candidate South
Bridge day frame (F02), narrowly. It found lighter green upper-right crowns and
clearer separation between lit canopy and shaded mass, producing a slightly
more believable foliage response. The separate bars remained Meadows **Yes**,
same broad kind of game **Yes**, and commercial quality **No**. This is a
bounded background-canopy gain, not evidence that the whole foliage problem is
solved.

The large lower-right foreground plant remained an almost uniform dark olive
cutout in both frames. A follow-up production source-isolation capture disabled
GrassField cover bushes (1 draw object), selected baked understory assets (5),
authored Props foliage (13), authored Harvest foliage (6), and perimeter
foliage (12) one category at a time; the plant remained in every frame. Its
source was therefore outside those five systems and was excluded from this
candidate's visual gain. The completed second diagnostic below identifies it.

The matched Water off-control is also production-bound. Root's guarded
`water-rootwalk-backlight-control-first` run executed from
`2026-09-10T04:35:50.1469437Z` through `04:36:25.5183056Z`, exited 0 with no
reported errors or remaining Godot process, and captured exactly Reedhaven Root
Walk/day through the ordinary catalogue scene, player, CameraRig and HUD. Its
diagnostic subclass pinned only the helper's process-local cached strength to
0.0 before world load. The finished manifest is complete with no failures; it
records the cache at 0.0 before and after world construction and 18 distinct
bound thin-foliage materials under production WaterVegetation mesh/multimesh
owners, all with backlight disabled. This establishes a current-tree material
control for the separately captured backlight-on Root Walk frame; it does not
by itself establish a visible preference.

`JUDGE-REEDHAVEN-BACKLIGHT01.md` found **no meaningful preference** between
the matched Root Walk frames. Terrain, vegetation, player, water, lighting and
composition read effectively the same; the visible differences were the
location label, displayed minute and minimap orientation. Its separate bars
were key-art world **No**, same broad kind of game **Yes**, and commercial
quality **No**. Water therefore supplies clean negative visual evidence: the
helper is proven bound there, but 0.28 does not produce a judgeable full-frame
gain at this location.

## Foreground source conclusion

Root's expanded guarded source isolation ran from
`2026-09-10T04:42:00.3850460Z` through `04:44:55.7576911Z`, exited 0 with no
reported errors or remaining Godot process, and produced one baseline plus 15
diagnostic frames. The manifest completed with no failures. Removing the eight
baked canopy assets together removes the near-right plant. More precisely, the
single `Terrain3DMeshAsset/CommonTree_5` frame removes the whole large
foreground mass; each other individual canopy-model frame retains it. The
object is a baked `saplings`-layer tree canopy, not `Bush_Common`, GrassField
cover, an authored prop, harvest foliage or perimeter foliage.

The shipped bake establishes why it looks like a flat close bush. Decoding
`data/scatter/playground/region_0_5.bin` with the checked-in
`scatter_bake.gd` format consumed all 379,209 bytes and found three kept
`CommonTree_5` saplings around the fixed camera:

| Order | Position | Scale | Horizontal distance from camera |
| --- | --- | ---: | ---: |
| 964 | `(6.309, -0.274, 1294.878)` | 0.413 | 1.242 m |
| 963 | `(6.127, -0.609, 1298.240)` | 0.429 | 2.236 m |
| 967 | `(1.675, -1.172, 1294.252)` | 0.276 | 4.516 m |

For order 964, the camera is 2.684 m above the tree base. Dividing by the
instance scale places it at model-local y 6.49, inside `CommonTree_5`'s leaf
mesh range y 2.356–6.763. Its camera is physically inside the upper canopy.
The glTF leaf surface has 2,600 distinct geometric normals and uniform-white
`COLOR_0`, so missing normals or a black vertex multiply do not explain the
mass. Backlight can improve an externally viewed crown, as the South Bridge
judge saw in the background, but it cannot make several overlapping cards
read as a rounded object from inside their volume.

This foreground case is therefore a placement/camera-clearance defect. The
current sapling collider is a trunk cylinder: radius `0.35 * scale` and height
`4.0 * scale`. For order 964 that is only 0.145 m radius and 1.654 m high,
while the imported canopy reaches roughly 0.89 m from the trunk and 2.80 m
above its base. The SpringArm can enter the visible leaves without touching
the collider. The saplings layer also has a 10 m clump radius and no
`path_standoff`; its biased clump centre may start 12 m off a route while a
member lands back near the travelled/camera corridor.

A systemic correction should keep camera travel out of canopy volume, either
through a sapling route standoff derived from the camera reach plus the model
canopy radius, or a camera-only canopy proxy distinct from the player's trunk
collision. Enlarging the existing shared player collider would make the
trainer collide with empty space around every tree and is not supported by
this evidence. No such correction is included in BACKLIGHT01, and production
foliage remains frozen pending a separate bounded placement/camera candidate.

## Smallest shared near-camera mechanism

There is no existing production near-camera foliage fade to extend. A bounded
search of `scripts/`, `scenes/` and `data/` finds no use of the three
`distance_fade_*` properties or `proximity_fade_enabled`; the only production
`distance_fade_mode` assignment is an explicit disable on a combat-arena
material. All four realm scenes do share `scripts/player/camera_rig.gd`, whose
`SpringArm3D` installs a 0.25 m sphere cast and uses the default collision mask.
That robustly handles geometry with a collider. The installed foliage material
path has no camera-aware shader, however, and the shared Meadows scatter
colliders are deliberately trunk cylinders streamed around the player. This is
why the existing camera system misses the proven leaf volume even while the
nearby tree's trunk collider is resident.

The project runs Godot 4.7 stable `5b4e0cb0f` in GL Compatibility. That exact
engine source provides `BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER`. Its generated
shader computes `fade_distance = length(VERTEX)`, evaluates
`smoothstep(distance_fade_min, distance_fade_max, fade_distance)`, and discards
fragments against interleaved gradient noise. With the ordinary ordering
`min < max`, leaf pixels are absent below `min`, dither in between, and are
fully present beyond `max`. This is the desired near-camera direction; the
documented reversed bounds are unnecessary here. See the exact
[4.7 material source](https://github.com/godotengine/godot/blob/4.7-stable/scene/resources/material.cpp#L1721-L1745)
and [BaseMaterial3D distance bounds](https://docs.godotengine.org/en/latest/classes/class_basematerial3d.html#class-basematerial3d-property-distance-fade-min-distance).

Pixel Dither is the robust mode for this source case. Object Dither is cheaper,
but the same 4.7 shader measures from `MODEL_MATRIX[3]`, the instance origin at
the tree base. Order 964 proves a camera can be inside a tall canopy while
remaining nearly 3 m from that origin. Pixel Dither measures the leaf fragment
itself and is independent of tree height, scale, pivot, MeshInstance versus
MultiMesh/Terrain3D instance, and which realm placed it. Proximity Fade is not
the appropriate feature: it compares a material pixel with the depth buffer
for soft intersections, while the engine's own material guide recommends
Distance Fade dither to hide geometry close to the camera. Pixel Alpha would
move the cutouts into the costlier alpha-blend pipeline, create sorting risk,
and disable features including shadow casting. The guide recommends Object
Dither first for speed, but the proven base-origin mismatch here makes Pixel
Dither the smallest correct choice. See the official
[material fade guide](https://docs.godotengine.org/en/latest/tutorials/3d/standard_material_3d.html#proximity-and-distance-fade).

The smallest production shape is two shared environment tunables for fully
hidden and fully restored camera distance, applied beside BACKLIGHT01 inside
`ImportedMaterials.apply_thin_foliage_backlight()`. Its existing exact
`Leaves` / `Leaves_*` / `Flowers` gate and the five verified constructors reach
installed foliage in Meadows, Stormwood, Water/Veilfall and Cloudreach while
leaving bark, trunks, roots, poles, rocks, characters, creatures, procedural
GrassField, and solid-colour procedural Cloudreach foliage unchanged. This
requires no custom shader, new mesh, placement rebake, extra physics bodies or
per-frame script work.

The acceptance run should bind and record the actual fade mode/bounds on leaf
materials and reject them on bark; capture South Bridge at the exact fixed
camera plus a short ordinary orbit/walk through orders 963/964/967; and capture
one close installed-canopy approach in Stormwood, Water and Cloudreach. It must
show the obstructing cards clear smoothly while trunks and the rest of each
tree remain, and show fully unchanged foliage outside the small fade radius.
Because Pixel Dither adds fragment distance, smoothstep, noise and discard to
every covered installed leaf pixel and creates a new material shader variant,
the same runs need frame-time/shader-stutter sampling on the GL Compatibility
target. Alpha-scissored foliage already pays discard/overdraw, but that does
not make the added cost free.

Camera-only canopy colliders remain the fallback if dither is visibly noisy or
too costly. They would require a separate physics layer seen by SpringArm3D's
mask and ignored by the player, canopy-sized shapes, and realm-specific
streaming/registration for Meadows, Stormwood, Water and Cloudreach. Existing
Meadows collision streaming covers trunk batches only, and the other foliage
builders do not share that registry, so this is substantially larger and less
universal than the shared material path.

### FADE01 implementation freeze

After the matched Cloudreach BACKLIGHT01 control completed, FADE01 applied the
proposed material path with conservative bounds derived from the diagnosed
South Bridge instance: leaf fragments are fully absent inside 0.75 m, dither
from 0.75–1.75 m, and fully restored beyond 1.75 m. The two tunables live in
`data/config/art.json`; `scripts/world/imported_materials.gd` reads and clamps
them, then sets `DISTANCE_FADE_PIXEL_DITHER` inside the existing exact
`Leaves` / `Leaves_*` / `Flowers` gate. No constructor, cache identity,
physics, mesh, placement, actor, creature, grass, camera or global grade was
changed.

The frozen production hashes are:

| File | SHA-256 |
| --- | --- |
| `data/config/art.json` | `881A1ACAE0BEA06369189D3D91C38BDE05AD1669591380A6B2E2F48DD97A03A4` |
| `scripts/world/imported_materials.gd` | `A253C71D7D740C0811FE6E357CFFBCA134E97BCE910E744A4820FB6D845CADDC` |

`tests/test_foliage_camera_fade.gd` exercises the real CommonTree_5 model
through the production Meadows retint/material policy and requires Pixel
Dither on its leaf surface with bark disabled. The native diagnostic
`tools/probe_south_bridge_foliage_camera_fade.gd` retains the exact catalogue
frame, audits the actual Terrain3D CommonTree_5 bound mesh, and captures four
labelled frames through ordinary production look/move input with player,
CameraRig and camera transforms plus 45-frame timing samples. These are
prepared contracts; render and performance evidence still belongs to root's
guarded run.

## Final disposition

Retain BACKLIGHT01 for its bounded, blind-preferred Meadows background-canopy
gain. Water is a clean no-preference result despite proven material binding.
There is no full-frame bar uplift and no claim of a general all-realm visual
improvement. The near-right foreground failure is separately diagnosed as
camera-inside-`CommonTree_5` geometry and remains outside BACKLIGHT01. FADE01
is now a separate, frozen production candidate for that failure; it has no
retain/withdraw disposition until root's guarded material-binding, native
orbit/walk, blind visual and GL Compatibility performance evidence completes.
