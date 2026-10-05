# F01#3: night walk reaches every opening NPC, camp and gate, readably

The reproof row3 code-blind judge failed this row on four points: the camp could not be confirmed, and Tam, Maren and Nessa were each only marginally readable at night. Each fix is scene data plus one config-driven light. The coordinator approved all four files, the village_npcs.gd hook included, with conditions.

| Judge finding | Cause | Fix (commit) |
|---|---|---|
| Camp: no cue; the only prompt was "Strip meadow grass" | a band1 meadow-grass harvest node at (24,-24), 1.5 m from the camp tent, won the arbiter at the camp | the node moves to (16.5,-20.5); a "Practice Meadow Camp" trailhead fingerpost stands beside the camp spur, 2.5 m off the road, with its arm on the fire (7bbc7653) |
| Camp: a large rock fills the lower right | the ground-essence node `essence_meadows_ground_01` (Rock_Medium_1) at (22,-28) sits between the arrival camera and the player; confirmed on the night3 arrival and travel frames before the move | moved to (24,-33): anchor offset (8,-5), 5.139 m off the main route, recorded (9ad7461a) |
| Tam and Maren dark against dark walls and trees | no fill at 23:00 under Compatibility | `night_light_default` plus `night_light: true` on both (`scripts/world/villager_night_light.gd`): soft, unshadowed, night-only, no visible source, cool #c9d6ee, never red (d2362512, 7bbc7653) |
| Nessa hidden behind the trainer at prompt distance | she stood in the research house doorway, 0.9 m from `research_house_walk`, so the walk stopped 0.8 m from her, straight behind the trainer | moved into the open yard at (60.0,10.6), 2 m clear of both walk segments, facing the walk (7bbc7653) |

Not in scope and left as found: the judge's other notes, namely the flat campfire flame, the quest beam through ceilings, and the white and pink boxes near Oskar.

## Checks

- **Unit:** `test_f32_material_census`, `test_f32_essence_census`, `test_harvest`, `test_harvest_permanence`, `test_signpost_geometry`, `test_village_road_topology` and `test_meadows_named_location_ledger_0912`: 84 tests, 0 failed. The census counts are unchanged. The essence census asserts each node's recorded route distance, so the moved node's distance was updated to the value it measures.
- **Placement proof for the moved essence node:** `godot --headless --path . --script tests/smoke_f32_material_sites.gd -- --realm=meadows --essence --site=essence_meadows_ground_01` PASS. It walks to the node, gathers it, saves the owner and ACK, and reloads it at the new spot.

## Final night capture and fresh code-blind judge

- **Capture:** tb/f01-fixes at 9ad7461a, local 4 vCPU, Xvfb, Mesa llvmpipe, Compatibility renderer:

  ```
  xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 --resolution 1280x720 --script tests/capture_village_walk.gd -- --time=night --route=visits --from-title --capture-dir=<abs dir>
  ```

  Exit 0, `PASS route=visits time=night captures=105 max_off_road_m=0.00 visited=12` (`night-walk-receipts.txt`).
- **Judge:** a fresh agent saw only 20 frames, the manifest (`judge-frame-manifest.txt`) and the criterion text. It saw no code. The frames are not committed (owner decision #12).

**Verdict: PASS, but barely.** Every target was reached, and none was NO, CAN'T TELL or POOR. The table compares with row3:

| Target | Row3 judge | This judge |
|---|---|---|
| Practice Meadow camp | CAN'T TELL / MARGINAL | **reached YES**. The approach frame reads "Practice Meadow Camp" on the signpost. The arrival frame is still MARGINAL: tent, bed and fire show, but the camera faces the village, no camp label is in view, and the fire sits in the foreground. |
| Nessa | MARGINAL (hidden behind the trainer) | **GOOD**: beside the trainer, light apron |
| Maren | MARGINAL | **GOOD**: clear against the hillside |
| Tam | MARGINAL | still **MARGINAL**: dark blue against the dark forge, half behind the trainer |
| others | YES | YES; Bram is MARGINAL because the camera clips into the shop ceiling |

**Remaining defects the judge named, worst first:**
1. Bram (indoors): the camera clips into the ceiling beam and a half-wall.
2. Tam: low contrast against the forge, half behind the trainer. The fill light could be stronger or offset toward the camera; this is config-only (`night_light` dictionary override on Tam).
3. Camp arrival: no label in view, the camera faces away, and the fire is in the foreground over the HUD.
4. PondGate looks like daytime at 23:00.
5. The quest beam shows through interior ceilings.
6. Small sign text.

Points 1 and 3–6 are camera, lighting or quest-marker issues outside this lane's approved files.
