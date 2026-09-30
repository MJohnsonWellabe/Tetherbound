# F26#4 twelve computer render routes

All twelve requested biome/preset combinations have passing native route receipts. This artifact records the computer capture criterion only; no full visual bar, Ally threshold, material census, earned chapter traversal or F49 credit follows from these routes. Independent overall strict review is required before acceptance.

| Biome | Preset | Executed source | Frames | Mean ms | P95 ms | P99 ms | Max ms | Waypoints | Receipt |
|---|---|---|---:|---:|---:|---:|---:|---:|---|
| Tidewake | Low | `1186526b921f7746dbaf514f0b7f7ac0649640f7` | 201 | 42.115 | 87.356 | 236.848 | 366.189 | 2/2 | [water-low-r1](routes/water-low-r1/route.json) |
| Tidewake | Medium | `840ede55d539d6d87aa70377e4c4ab74cfc9ffa1` | 234 | 34.799 | 53.700 | 72.199 | 82.479 | 2/2 | [water-forward-r1](routes/water-forward-r1/medium/route.json) |
| Tidewake | High | `840ede55d539d6d87aa70377e4c4ab74cfc9ffa1` | 182 | 44.724 | 84.879 | 91.341 | 107.849 | 2/2 | [water-forward-r1](routes/water-forward-r1/high/route.json) |
| Meadows | Medium | `424ca00d876ecb5b4f751e4732e3b1c15d28a2a1` | 506 | 40.413 | 45.007 | 46.443 | 97.609 | 3/3 | [meadows-forward-incremental-r4](routes/meadows-forward-incremental-r4/medium/route.json) |
| Meadows | High | `424ca00d876ecb5b4f751e4732e3b1c15d28a2a1` | 481 | 42.677 | 49.397 | 52.734 | 247.006 | 3/3 | [meadows-forward-incremental-r4](routes/meadows-forward-incremental-r4/high/route.json) |
| Meadows | Low | `d5e0c30dc14048521649432330d9dfa583cc56dc` | 411 | 49.723 | 59.175 | 85.558 | 127.057 | 3/3 | [meadows-low-hall-r2](routes/meadows-low-hall-r2/low/route.json) |
| Cloudreach | Low | `05e9d4a964dd8a91c377d19810f6ce9c7072fa44` | 15064 | 11.629 | 15.222 | 16.410 | 260.463 | 3/3 | [cloudreach-r1](routes/cloudreach-r1/low/route.json) |
| Cloudreach | Medium | `05e9d4a964dd8a91c377d19810f6ce9c7072fa44` | 10423 | 16.799 | 30.380 | 31.494 | 89.554 | 3/3 | [cloudreach-r1](routes/cloudreach-r1/medium/route.json) |
| Cloudreach | High | `05e9d4a964dd8a91c377d19810f6ce9c7072fa44` | 8229 | 21.277 | 29.412 | 32.967 | 90.712 | 3/3 | [cloudreach-r1](routes/cloudreach-r1/high/route.json) |
| Stormwood | Low | `81148bbf2c51236709cb57d605a0d7bf92c221d8` | 11021 | 13.739 | 18.107 | 26.301 | 152.297 | 2/2 | [stormwood-r1](routes/stormwood-r1/low/route.json) |
| Stormwood | Medium | `81148bbf2c51236709cb57d605a0d7bf92c221d8` | 5895 | 25.749 | 30.547 | 32.483 | 209.890 | 2/2 | [stormwood-r1](routes/stormwood-r1/medium/route.json) |
| Stormwood | High | `81148bbf2c51236709cb57d605a0d7bf92c221d8` | 4601 | 32.967 | 37.949 | 41.555 | 52.936 | 2/2 | [stormwood-r1](routes/stormwood-r1/high/route.json) |

Locked Godot4.7; native Windows1920x1080; GTX1060 3GB. Low is Compatibility; Medium/High are Forward+. Each renderer process has isolated saves. Real production scenes, controller InputMap walking and collision follow declared authored routes after one staged initial placement. Warmup/loading/screenshot I/O are excluded; complete raw wall/process/physics samples, native exit/logs and unmodified start/end PNGs remain at the linked evidence. These are wall-frame measurements, not GPU-only timings. Medium/High share one scene with per-preset pose reset and warmup; no independent cold-start claim. Stormwood has two authored waypoint legs, Water has two, Meadows/Cloudreach three. Clocks/weather continue during measurement.

Passing earlier Water/Meadows/Cloudreach evidence is reused for unchanged relevant route/render production source, with its exact executed commit retained; later source deltas are the owned process-tree timeout fix and Meadows-only pre-mount fixture declaration. The corrected Meadows Low uses the same current F17 farmhouse-to-Hall road as the retained Medium/High. Seven post-opening flags are declared before mounting the scene and listed in its receipt; this is not proof of earning the opening. No modal dismissal, speedup or teleport between route waypoints was introduced.

The first current Meadows Low failed native1/zero waypoints because Grandpa opening dialogue held ordinary movement. Its original matrix, samples, dialogue-visible PNGs and logs are retained in routes/meadows-low-hall-r1, separately from the corrected pass. Earlier renderer/debug failures also remain archived. The archive helper initially assumed three Stormwood waypoint legs; validation caught that mistake and the report now derives the actual authored count. Its raw Stormwood log preserves an original trailing space; source/document diff checks exclude raw log whitespace, without editing runtime evidence.

Compatibility remains the default. Owner Ally testing and F26#0/#3/#5 remain open. No unit or full-suite rerun was needed for this capture/evidence batch under RD36/RD37.
