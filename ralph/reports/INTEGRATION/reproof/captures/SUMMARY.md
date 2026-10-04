# Re-proof captures — summary

Code under test: 826d273c3 (origin/tb/integration → main via PR #525), except F37#3, re-scanned on main a0f9e50b3. Renderer: software renderer (Compatibility), Xvfb + llvmpipe, opengl3. Every visual verdict is a fresh code-blind agent that saw only the frames, the criterion text and the ART_DIRECTION §4 bar/reference boards. Lane retired by the coordinator (owner-approved restructure) before the queue finished; unfinished items listed at the end.

| Item | Verdict | Evidence | Top defects |
|---|---|---|---|
| F01#2 day walk | FAIL | F01-2/ | Walk harness FAIL: stalls 9.29 m short of Mira (reached Grandpa, Tam only); start camera blocked by farmhouse wall |
| F01#3 night walk | FAIL | F01-3/ | Same stall, 9.32 m from Mira (reproduced); interiors lit as daytime at 23:00 |
| CH-Meadows#M1 (walk part) | FAIL | CH-Meadows-M1/ | Reuses F01 walks (10/12 targets unreached); gate-B chains belong to the retest lane |
| F04#0 Warrens guardian | FAIL | F04-0/ | Smoke FAIL (tell/recovery 1.00/0.90 vs expected 0.85/1.10; Earth Fist cone/lunge not from MoveDB); both attacks share one magenta-ring tell, question only in HUD text, camera too close/occluded in 8/10 frames |
| F08#3 high-perch camera | FAIL | F08-3/ | Tool FAIL 11/12: night departure jump won't launch; cameras behind arch/pillars/rock (arrival-lip, arrival-landed, rim-out); white untextured disc platform |
| F08#4 settlements/cliffs | FAIL | F08-4/ (frames in CH-Cloudreach-C2/) | Settlements are flat Meadows lots, no height; cliffs are brown extruded blocks; grey/white void instead of cloud sea |
| CH-Cloudreach#C2 art | FAIL | CH-Cloudreach-C2/ | Blocked cameras (rock-filled shrine frames, creatures fill bridge/aviary frames); placeholder banners/props, barcode strata; no cloud sea, no pale stone |
| F40#4 Sky Aviary | FAIL (Low); High/Medium needs native GPU | F40-4/ (frames in CH-Cloudreach-C2/) | Aviary invisible at 850/400 m; "greenhouse on a gate" up close, no drum/turrets; no warm night windows; placeholder box on summit |
| F10#3 lightning/phases | FAIL | F10-3/ | Telegraph passes (1.2 s ring, ~3 m, visible bolt); Surge phases indistinguishable without HUD (no copper Building, no white-violet Break); reduced motion identical to normal |
| F10#4 Stormwood matrix | FAIL | F10-4/ | Stormheart is two untextured mauve slabs with floating foliage; glass scars are primitive cones; no lightning in Break; rod line leads nowhere |
| F13#5 Tidewake T2 matrix | FAIL | F13-5/ | No Veilfall visible from any island; cube/slab placeholders at three docks (one blocks the trainer); identical uninhabited piers |
| F14#2 current restore | FAIL | F14-2/ | Smoke 87 PASS/0 FAIL and blind A/B 2/2 correct (change visible); but after-reload frames land on open sea, so persistence never shown on screen |
| F17#1 Hall from farm door | PASS (narrow) | F17-1/ | Hall reads by layout not mass (barely taller than houses); oversaturated 08:00 foreground; trainer over-lit at night |
| F26#2 look bars documented | PASS | F26-2/ | All five biomes have sky/fog/shafts/grade/weather + existing boards; no Crossing Hall board; Hall/Tidewake configs unnamed |
| F37#3 Ripplet Teleport removed | PASS (on a0f9e50b3) | F37-3/ | First scan on 826d273c3 FAILed (ACCEPTANCE S4 cell); fixed by PR #526; re-scan clean |
| F38#4 Village road + Hall | FAIL (Low); High/Medium needs native GPU | F38-4/ | Tool 28/64: 36 stands "no physical floor supports the resolved land stand" (main road, Hall front); Hall nave placeholders (flat blue portal fills, open roof, mirrored labels, 6 not 8 arches) |
| F21#4 fight camera size matrix | ERROR — needs native GPU | F21-4/ | All 9 live cases exceed the 30 s budget on llvmpipe; 0 frames, no judge possible |
| F39#4 Veilfall far/close | ERROR | F39-4/ | F39 matrix tool: 0/20 frames, `ERROR: F39 production weather service unavailable` (capture_f39_catalogue.gd:95); interior close-ups captured but unjudged |

## Totals

- Items: 22 assigned. Recorded: 18 (PASS 3, FAIL 13, ERROR 2). Not run: 4 (F04#3, F22#4, F10#2, F14#0).

## Unfinished (lane retired)

- **F04#3 Warden**: `tools/art_pipeline/capture_named_fight.gd --trainer=warden_aldis --live-member=warden_aldis:4 --dodge --tell-frames --keep-alive --resolve=won --after-frames=28` capture + code-blind judge.
- **F22#4 named fights**: `smoke_meadows_named_c2c3.gd`, `smoke_water_named_c2c3.gd` (`--party-level=43`), `smoke_stormwood_b_named_c2c3.gd`, all `--seeds=24` headless `--fixed-fps 60`; C3 captures for captains/relay officers (capture_named_fight.gd), Nerissa/Tess (capture_tidewake_named_fights.gd), Stormwood (capture_stormwood_b_named_fights.gd), Veyra (capture_cloudreach_f40_fight.gd); code-blind judge per fight.
- **F10#2 Stormwood named**: smoke_stormwood_b_named_c2c3 `--seeds=24` + C3 capture (`tests/capture_stormwood_b_named_fights.gd --fixed-fps 20 --seconds=18`) + judge.
- **F14#0 Tidewake named**: smoke_water_named_c2c3 `--seeds=24 --party-level=43` + C3 captures (`--wild=aquaryn`, `--trainer=water_trainer_tess …`) + two independent judges.
- **F21#4**: native-GPU run of `smoke_combat_camera.gd --matrix-live --matrix-preset=Low --source-commit=<40-hex>` + judge.
- **F39#4**: fix/diagnose the F39 weather-service failure (or run base `capture_lookdev_catalogue.gd --biome=water --subset=veilfall --preset=Low`), judge distance; judge the captured interior close-ups; High/Medium on native GPU.
- **F38#4, F40#4**: High/Medium presets on native GPU (Codex F26 lane).
