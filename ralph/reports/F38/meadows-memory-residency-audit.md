# Meadows startup memory residency audit

## Existing host capture

Source: `D:\tetherbound\.artifacts\codex-service-gpu\harvest-stream-startup\direct-host-r3\runs\direct-host-memory420-91fc3fc5e40a4a9cab0d096210a41028\godot.stdout.log` and `supervisor.jsonl`.

- `godot.stdout.log` line 7 reports vegetation placement and batch phases complete; line 18 reports 386,474 props in 36 batches, 56,283 harvest registrations, and 266 of 51,210 collision placements resident.
- Stronghold setup follows at lines 58–76 and climax setup at lines 78–79. The process stopped at the physical-memory guard during that later work.
- The final supervisor sample reports 2,134,900,736 bytes physical available, 4,533,784,576 bytes process private, and 2,676,776,960 bytes working set; the receipt says the guard stopped the process when physical or commit availability fell below 2 GiB.
- `playground_world.gd::_dress_the_meadow()` awaits `Vegetation.build()` before logging scattered props. Its local `by_layer`/`by_model` collections are therefore out of scope by the guard phase. Releasing those arrays helps construction peak only; it does not explain the later resident stop.
- The vegetation log labels `_harvest_points` as `nodes`; that counter counts every registration. It does not report `_harvest_nodes.size()` and is not evidence that 56,283 harvest `Node`s were resident.

## Large retained owners and readers

| Owner | Observed scope | Why it remains live |
|---|---:|---|
| Terrain3D scatter | 386,474 instances, 36 batches | The instancer owns their render transforms and the registered mesh scenes/materials. These are the world being rendered. The capture has no resource-level byte attribution. |
| Collision batch placement records | 51,210 placement entries | `_stream_batch()`, `_make_collision_shape()`, `clear_area()`, and permanent harvest need position, scale, optional slope normal/yaw, and harvest identity. The prior full scatter dictionaries held more fields than these readers require. |
| Collision residency | 266 live shapes across 51,210 placements at initial stream | The old parallel `Array` reserved one nullable `Variant` slot per placement. Streaming and removal need only live nodes. The sparse map is already in commit `5205e1b4`. |
| Harvest registry/cells | 56,283 registrations | Chopping, permanent removal, restore, and spatial clear queries read the per-point data and cell index. No safe deletion was found in this audit. |
| Render position index | 386,474 positions | Already a `PackedVector3Array`; `clear_area()` and fight hide/restore paths read it. |
| Soft occluder census | Per placement in configured soft-solid layers | Already columnar packed arrays; ground clearance and fight visibility read/mutate them. |
| Stronghold/climax nodes | 407 structural members, 87 interior props, 21 lights, 3 gauntlet trainers, 1 climax trainer, 15 pylons | The capture shows a few hundred authored scene objects, not a source of tens of thousands of resident objects. |

`_make_mesh_asset()` packs each retinted mesh into the Terrain3D assets list, and `_assets` remains the render owner. The code does not establish that imported source meshes/textures are duplicated in memory at the guard, so this audit makes no asset-byte claim and does not unload renderer-owned resources.

## Theoretical payload bounds

The old collision residency array had `51,210 - 266 = 50,944` null slots in the captured initial stream. Godot 4.7 documents a 24-byte `Variant` on 64-bit platforms and describes `Array` as holding Variants. The raw null-slot payload is therefore `50,944 × 24 = 1,222,656` bytes (about 1.17 MiB), before sparse-dictionary overhead, allocator capacity, or fragmentation. This is a gross payload estimate, not measured net savings. [Godot 4.7 Variant documentation](https://docs.godotengine.org/en/4.7/engine_details/architecture/variant_class.html)

The current candidate compacts each retained collision record in place. At minimum, it removes the per-placement `model` key/value pair after grouping, while retaining the fields its live readers need. With 51,210 records and two 24-byte Variant slots per key/value pair, that is 2,458,080 bytes (about 2.34 MiB) of raw Variant slots removed before hash-table and allocation effects. This is likewise a theoretical gross bound, not an observed saving. It excludes additional dropped metadata and makes no claim about net process memory.

## Candidate and validation boundary

`scripts/world/vegetation.gd` now stores collision residency sparsely and replaces each retained full scatter placement dictionary with a compact collision record. It preserves placement count, collision radius, shape scale/normal/yaw, positions, and harvest identities. Stream, clear, proximity, harvest, force-resident, and count readers were traced. Static source assertions and a 300-sequence CPU reindexing model passed; `git diff --check` passed before this report was added.

No engine, native capture, CI, or visual setting was changed or rerun. Runtime memory impact remains unmeasured; the estimated few MiB cannot account for or clear the reported multi-gigabyte guard failure.
