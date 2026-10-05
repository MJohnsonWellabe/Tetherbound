# Cloudreach High unbound source review

**Finding: the six reported records are intentionally hidden fallback or superseded presentation geometry in this captured route. No unresolved visible unbound binding was found among these six.** This is a bounded source/record review, not full material or visual acceptance.

Reviewed all 12 raw `material_census` snapshots in [the manifest](D:/tetherbound/.artifacts/f26-census-2/cloudreach-high/frames/manifest.json), rather than relying on the summary's latest-record deduplication. Constructors and visibility handling were read from pinned revision `4e14b7919a0f242147a0464f878a84ec77074046` using read-only Git operations. No engine, Blender, image judging, tests, new tooling, or Git mutation ran.

Every snapshot contains exactly six `unbound_primitive_default_requires_source_review` bindings: surface 0 of `Player/Model/Body`, `Player/Model/Nose`, and the four `MasterT4/@MeshInstance3D@6096` through `@6099` cylinders. Each distinct binding occurs in all 12 snapshots, always with `visible_in_tree=false`: **72 observations, zero true visibility records**.

| Day destination | Unbound records | Recorded visible |
| --- | ---: | ---: |
| Realm Gate Crag | 6 | 0 |
| Galefoot Waycamp | 6 | 0 |
| Three Bells Bridge | 6 | 0 |
| Broken Skyroad Arch | 6 | 0 |
| Windscar Beacon | 6 | 0 |
| Windscar Flight Aerie | 6 | 0 |
| Sky Shrine | 6 | 0 |
| The High Perches | 6 | 0 |
| Cliffhold | 6 | 0 |
| Old Wind Observatory | 6 | 0 |
| Summit Eyrie | 6 | 0 |
| Stormward Overlook | 6 | 0 |

## Source disposition

The two capsules share `scenes/player/player.tscn::Mesh_1`, created without a material in [player.tscn](D:/tetherbound/redesign-lookdev/scenes/player/player.tscn:11). The scene explicitly retains them as missing-model fallbacks; Body and Nose are instantiated at lines 33 and 37. [trainer_model.gd](D:/tetherbound/redesign-lookdev/scripts/player/trainer_model.gd:88) attempts the chosen appearance and then trainer fallback. After `_build_art` succeeds, [character_model.gd](D:/tetherbound/redesign-lookdev/scripts/characters/character_model.gd:144) calls `_hide_placeholders`; [its implementation](D:/tetherbound/redesign-lookdev/scripts/characters/character_model.gd:223) hides every direct Node3D child except the loaded art. Their recorded hidden state is consistent with this deliberate fallback lifecycle. It does not establish the loaded trainer's visual quality.

The four cylinders are the generic fly supports constructed without materials by [master_site.gd](D:/tetherbound/redesign-lookdev/scripts/masters/master_site.gd:133). [master_t4.tscn](D:/tetherbound/redesign-lookdev/scenes/masters/master_t4.tscn:5) identifies the root as MasterT4; [masters.json](D:/tetherbound/redesign-lookdev/data/config/masters.json:227) assigns `fly_only` access and its four support offsets begin at line 259. Mounting builds the supports and then invokes the realm dressing at [master_site.gd](D:/tetherbound/redesign-lookdev/scripts/masters/master_site.gd:72). [cloudreach_world.gd](D:/tetherbound/redesign-lookdev/scripts/world/cloudreach_world.gd:4304) explicitly hides direct CylinderMesh children except ArenaFloor, then constructs a stratified rock islet using realm materials at line 4309. These four records therefore describe retained, superseded generic supports, not an unresolved visible replacement surface.

## Limits

The links identify source locations; the conclusions above use their pinned revision, not a promise that the working tree will remain identical. `visible_in_tree` is the node's tree visibility flag, as recorded by [the census collector](D:/tetherbound/redesign-lookdev/tools/capture_renderer_material_census.gd:130); it is not a pixel inspection. Twelve snapshots do not prove visibility between captures, on failed model loads, in other realms/modes, or outside this route. The materials of the loaded trainer, replacement islet, other bound/untextured records, and all captured-image quality remain **OPEN**. No FPS, traversal, campaign, or full material acceptance follows from this finding.
