# Stormwood lane, close-1024 (F41#1, #2, #3, #5; F10#2)

Baseline: origin/main 5f1f388cc, where the r11 look is ON (commit 30b8264f4). Previous round notes: `../close-1022/notes.md`.
Renderer: Godot 4.7 Compatibility, Mesa llvmpipe CPU, 1280x720, Xvfb. CPU-provisional bar 6.7 mapped; GPU 7.5.

## Meshy request (day 1)
References drafted as crops of the owner boards (`docs/reference/boards-2026-09-06/`), in `meshy-refs/`:
1. Stormheart v3 hero: `stormheart_v3_ref_a.jpg` (board a exterior) + `stormheart_v3_ref_b.jpg` (board b exterior). About 380 m tall, height:width 1.6:1; keep v2 identity (V-split trunk with a glowing blue cleft), wooden platforms and walkways, navy banners only (no red), green crown. Used beyond `swap_radius_m` 75 m; scale to the 1.80 m trainer goes through the procedural shell. Purpose: judges r11/r12 call the distant Stormheart squat.
2. Glass-field strike scar crystals: `glass_scar_ref_details.jpg` (lightning crystal, electric roots) + `glass_scar_ref_palette.jpg`. A cluster of pale-blue fulgurite glass spikes rising from a scorched, fused ground crust, about 4 m wide x 2.5 m tall (taller than the trainer). Purpose: judges cannot read the glass-field scar.

## Round r14 result (24 Oct, about 04:00 UTC)
- Batch: same fixed anchors (craft, f10_2_r3_capacitor, f36_0_npc:C5, f36_0_gap:C2), three fresh code-blind judges, JUDGE_PROMPT v1 verbatim. Files: `r14/` (`_sheet_r14.png` = Calm set). Control = the r13 control frames (main).
- Fit: linear, slope 0.92, intercept 0.91, r 0.74, anchor RMSE 0.77 (warning: > 0.75). Confirming batch (top anchor 7.35).

| Set | Control raw (j1/j2/j3) | Control mapped | Candidate raw | Candidate mapped | Gain |
|---|---|---|---|---|---|
| F41#3 Calm | 5.2/5.0/4.9 | 5.53 | 5.3/5.3/5.2 | 5.75 | +0.22 |
| F41#3 Break | 4.7/4.0/4.1 | 4.83 | 4.6/4.3/4.4 | 4.98 | +0.15 |
| F41#3 aftermath | 5.3/5.1/5.0 | 5.63 | 5.5/5.5/5.3 | 5.90 | +0.27 |
| F10#2 glass_field | 5.3/5.4/5.6 | 5.90 | 5.6/5.2/5.5 | 5.90 | 0.00 |
| F10#2 capacitor | 5.2/5.4/5.6 | 5.87 | 5.1/5.3/5.5 | 5.78 | -0.09 |

- What moved: all three judges picked out the Stormheart v3 tower ("closer to the stronghold board"; squat defect PARTIAL from two judges) and the glass crystals (scar PARTIAL from two). Still PRESENT for all three: Break forest near-black, lightning not lighting trunks/ground in the forest stands, near-lens trunk/root (giant, reverse), black foreground patch (forest), repeating ground, flat sky, no shafts or rim light. Fights: one judge flagged the candidate's foreground crystal at the glass_field lens edge.
- Gain rule: r12, r13, r14 all under +0.5; r14 was the clearly different approach (new art + fill). **F41#3 and F10#2 park** at the mapped scores above (CPU, Compatibility/Low). The r14 candidate beats main on every matrix phase but is not judged passing, so it stays OFF (flag-off land below).
- Remaining gap, per all six r13/r14 judges, is mostly outside this lane's config surface: fight HUD about 40% of frame (UI), tiny pilot (Creatures), magenta outline telegraphs and spark-sized impacts (Fights: `combat.json charger_lunge.lane_charged` is on main OFF; the feet ring keeps the settled hazard hue), near-lens occluders at the fixed stands (needs a stand reframe or an exploration near-lens rule; the Meshy-tree fade route costs about 3x render), and a real lighting model for the canopy interior (Compatibility has no SSAO/volumetrics; shadow opacity is pinned by the surge design tests).

## F41#5 defect scan (r13 + r14 matrices, six judge passes)
- Flat magenta strike disc in the matrix: FIXED on both arms (no disc seen in any Break frame).
- Placeholder materials, floating bodies: none flagged in the matrix sets.
- Clipping / camera in foliage: near-lens trunk (giant), root (reverse) and a dithered near-lens trunk (forest) PRESENT in the matrix; in the fights, canopy/trunk edges intrude (PARTIAL).
- Magenta in the real fight: thin magenta lane/ring outlines PARTIAL (Fights-owned telegraph).
- So F41#5 is not clean. Open items: the near-lens occluders and the fight telegraph outlines.

## F41#1 top-20 (from `ralph/reports/VISUAL/phase2/stormwood/top20.csv`, owner lane as listed there)
| Item | Subject | Impact | Owner | Status / this lane |
|---|---|---|---|---|
| P2-042 | Surge phase presentation | 100 | x04-stormwood | fixed (csv) |
| P2-015 | creature collapse and rest | 100 | x04-meadows | Creatures |
| P2-016 | creature hurt/movement poses | 100 | x04-meadows | Creatures |
| P2-037 | Stormheart finale | 100 | x04-stormwood | r14: v3 tower PARTIAL; `_model_v3_candidate` OFF |
| P2-092 | named wild fight actor spacing | 100 | x04-stormwood | Fights |
| P2-002 | map | 80 | x04-meadows | UI |
| P2-017 | normal creature scale | 80 | x04-meadows | Creatures |
| P2-030 | shiny creature finish | 80 | x04-tidewake | Creatures |
| P2-033 | ground pickup identity | 80 | x04-meadows | Shared art (candidate OFF on main) |
| P2-093 | named wild danger/opening cues | 80 | x04-stormwood | Fights (`lane_charged` OFF) |
| P2-038 | named destination identities | 80 | x04-stormwood | open, not captured this round |
| P2-039 | forest ground and distance layers | 80 | x04-stormwood | open; judges: repeating ground PARTIAL |
| P2-081 | named trainer dialogue identity | 64 | x04-stormwood | UI/dialogue |
| P2-113 | catch camera distance | 64 | x04-tidewake | Camera |
| P2-119 | Fly carrier grip pose | 64 | x04-meadows | Creatures |
| P2-001 | menu shell | 60 | x04-meadows | UI |
| P2-007 | secondary menu panels | 60 | x04-meadows | UI |
| P2-055 | named character silhouettes | 60 | x04-tidewake | Shared art (candidate OFF) |
| P2-063 | shared fight tell and hit effects | 60 | x04-meadows | Fights |
| P2-095 | craft recipe text | 48 | x04-meadows | UI (the craft anchor's "after" side) |
- 6 of 20 are Stormwood-lane items; 14 belong to Creatures, UI, Fights, Camera or Shared art. F41#1 cannot close from this lane alone.

## Round r15 (F41#5 fix per coordinator 24 Oct 04:01Z), capturing
- Coordinator ruling: fix the near-lens occluders for the player (no stand reframe); this lane owns `charger_lunge.lane_charged`.
- Near-lens rule (`foliage_camera_visibility.json near_lens_hide`, committed OFF; code in vegetation.gd, test `test_near_lens_hide.gd`): per layer, instances whose surface (axis distance minus collision_radius x scale x reach) comes inside the layer's fade band move from the opaque Terrain3D instancer into a small local MultiMesh drawn with a narrow pixel-dither near fade, and back when the camera leaves. Layers: giant_canopy reach 4.0 fade [5.0, 5.5]; storm_deadwood 4.5 [4.0, 4.5]; storm_canopy 1.0 [4.5, 5.0]. A covered layer drops the wide always-on near_lens_fade (3-7 m), which was the forest stand's "ghost trunk".
- What was tried first and dropped: (1) hiding whole instances near the lens with a "tree the player stands at stays" rule: missed the reverse root, which is the root flare of giant_canopy#356 standing ahead of the player; (2) a depth rule (hide only trunks not beyond the player): same miss; (3) a wide 2.5-4.5 m band: half-dithered ghost trunks. Preview: forest ghost gone (solid trunks now frame the shot at 5-6 m), reverse root at the lens dissolves (a darker root arch beyond remains), giant-stand left trunk unchanged (it sits beyond the band).
- `lane_charged` ON in the candidate. Checks with it ON: test_charger_lunge, test_stormwood_b_hosted_lunge_outcome, test_stormwood_b_named_lunge_lanes (+ near-lens, fight ring, sight scope, camera visibility) 36 tests / 188 assertions, the only failure being test_off_by_default (expected: the candidate turns the rule on); smoke_charger_lunge 54 checks, 0 failed.
- Candidate = r14 + near_lens_hide ON + lane_charged ON (`r15-candidate.patch`). Control: main frames (r13 control).

## Round r15 result (24 Oct, about 06:30 UTC)
- Same fixed anchors, three fresh code-blind judges, JUDGE_PROMPT v1 verbatim. Files: `r15/` (`_sheet_r15.png` = aftermath set). Fit: linear, slope 1.05, intercept 0.15, r 0.74, anchor RMSE 0.77 (warning > 0.75); confirming batch.

| Set | Control raw (j1/j2/j3) | Control mapped | r15 raw | r15 mapped | Gain |
|---|---|---|---|---|---|
| F41#3 Calm | 4.7/5.2/4.9 | 5.33 | 5.0/5.5/5.3 | 5.68 | +0.35 |
| F41#3 Break | 4.2/4.8/4.3 | 4.81 | 4.3/5.0/4.5 | 4.98 | +0.17 |
| F41#3 aftermath | 4.7/5.0/5.0 | 5.30 | 5.0/5.6/5.4 | 5.75 | +0.45 |
| F10#2 glass_field | 5.4/6.1/5.5 | 6.10 | 5.4/6.0/5.6 | 6.10 | 0.00 |
| F10#2 capacitor | 5.4/6.2/5.6 | 6.17 | 5.0/5.9/5.2 | 5.79 | -0.38 |

- F41#5 near-lens: all three judges still mark "near-camera occluder" PRESENT on both arms. With the swap rule the reverse root at the lens dissolves, but the judges now flag the solid trunks at 5-7 m (forest, giant, frame 8) and the root arch beyond as occluders. Regression: the capacitor candidate's frame 3 has a trunk across the spider (all three judges): dropping the wide near_lens_fade for covered layers also removed the fight camera's existing 3-7 m protection.
- Verdict: second failed approach on the near-lens defect (whole-instance hide, then narrow-band swap). **Parked** with this evidence; `near_lens_hide` stays OFF on tb/stormwood (cfaf19da2). If resumed: keep the wide near_lens_fade in fights, and treat 5-7 m frame-edge trunks as a camera-framing problem (an exploration camera rule), not an instance rule.
- Matrix scores sit at the r14 level (r14 candidate 5.75/4.98/5.90 vs r15 5.68/4.98/5.75): F41#3 stays parked, F10#2 stays parked.
- lane_charged was ON in this candidate (before the coordinator's 04:29Z Fights-lane message reached this session). Judges still mark the magenta outline telegraphs PARTIAL; lane_charged changes only solid lanes. It is not in any committed config or land branch here; Fights owns it.

## TO COORDINATOR
- 25 Oct 21:40Z READY tb/stormwood-land6 2f3e3fef9 (from origin/main 0fe451688; supersedes land5, which it contains): item 6 r16 batch + the r18 Meshy candidate (tb/meshy-1024 ae67083ec), every r18 flag OFF. GPU arm with the flags ON: tb/stormwood-land6-on 1680e579f (land6 + one config commit; the F41 catalogue needs a clean tree per SHA).
  - r18 code-blind CPU (VERDICT `r18/VERDICT.md`, sheet `r18/_sheet_r18.png`; slope 1.19, RMSE 0.66, no warnings), off -> on mapped: Ashfoot inside 4.33 -> 6.07 (+1.74: timber lining over the plaster + ranger hearth with fire light), Stormheart interior 4.37 -> 5.12 (+0.75: root-wall panel ring + arched deck walk on the OuterWorks lip), Crown heartstone 3.89 -> 4.60 (+0.71: Meshy hero stone, crystal glow, slender 1.25 m collider). Pool basin wired but OFF (buried twice; not judged).
  - Checks: smoke_stormwood_crown_heartstone 12/0 with the hero ON and OFF (a bug the smoke caught: the hero branch skipped the stone's light and prompt; fixed); 47 unit tests 0 failed with the candidate ON and OFF (stormheart*, named_crown, settlement grounding, village_boundary, texture_import_policy); texture policy PASS (15 sidecars mode 2); smoke_village_services_redesign PASS (r16).
  - GPU command, run per arm (land6 = off, land6-on = on), Medium and High: `godot --path . --rendering-method forward_plus --resolution 1920x1080 --script tools/capture_f41_stormwood_catalog.gd -- --preset=<Medium|High> --source-commit=<arm SHA> --out=<fresh dir> --label=f41-land6-<arm>-<preset> --phases=calm,building,break,fading --no-aftermath` (import first). The heartstone is framed by the Crown Heartstone survey stand's second heading (f41_survey 691.5, 2703.5, heading 27).
  - Main merged into tb/stormwood (8fb782402). Next per your order: authored ground (gap 1) as one big candidate.
- 25 Oct 13:20Z MESHY + dominant objects (your 13:04Z directive; refs are crops of the owner Stormheart boards a/b, in `meshy-refs/`, inspected; every asset flag-off until its stand is judged, one change per candidate):
  1. Stormheart interior (3.51): dominant object = the deck ring and its bare wall. MESHY A `stormheart_deck_segment`: one curved timber deck segment, about 8 m long on a 26 m radius arc, 3 m wide, plank floor, square-post railing with lantern posts, knee brackets under the deck, aged warm wood; tiles around the ring. Ref `stormheart_deck_ref.jpg` (interior view, walkway, platform detail, platform bracket, bridge railing). MESHY B `stormheart_root_wall_panel`: an interior trunk-wall panel about 12 m tall x 8 m wide, deep carved bark with root buttresses and a few thin glowing blue lightning-vein roots (natural lightning glow only), slight inner curve. Ref `stormheart_wall_ref.jpg`.
  2. Crown heartstone (4.13): dominant object = the heartstone. MESHY C `crown_heartstone_hero`: an ancient standing stone about 4 m tall on a mossy root-and-stone plinth, one large faceted blue crystal embedded in its face with fine glowing crystal veins through cracked grey stone; reads as sacred from 12-50 m. Ref `heartstone_ref.jpg` (lightning crystal, crystal swatches, stone, moss).
  3. Ashfoot interior (4.65): dominant object = the plaster room shell. Structural rebuild in this lane (timber plank lining over the plaster interior walls with a stone wainscot, shuttered windows). MESHY D `ranger_hearth`: a small stone-and-timber hearth with a hanging iron kettle, about 1.8 m wide x 2.2 m tall, for one wall corner. Ref `ranger_hearth_ref.jpg` (wood plank, stone, warm lantern, walkway, arch) - no hearth exists on the boards, so the prompt carries the shape.
  4. Lantern Pools (4.70): dominant object = the ground carpet with no real pools. MESHY E `glowmoss_pool_basin`: a sunken natural pool about 7 m across, irregular stone-and-root lip, dark still water surface, glowmoss and small fern clumps on the rim, sits into the ground (no floating rim). Ref `lantern_pool_ref.jpg` (biome-context lake, moss, stone, lantern, leaves).
  5. Capacitor grove (1.07): dominant object = the held Capacitor alpha in the lens; fixed structurally by the catalogue survey stand (land4, merged in #743). Needs the GPU catalogue recapture, no Meshy.
  The two tb/meshy-1024 assets are already wired: glass_scar_crystals (glass field, flag-off), stormheart_v3_far (far LOD, judged no gain).
- 25 Oct 12:30Z r17 (item 6) LOST, reverted: crystal crown on the heartstone, a candle key light with a dimmer room light in the cottage interior, and clearing the Stormheart hollow's ground cover. Same yardstick, r17 vs r16 in one batch (linear slope 1.22, intercept -0.62, anchor RMSE 0.68, no warnings): Ashfoot 4.91 -> 4.47, Stormheart 5.24 -> 4.75, heartstone 4.79 -> 4.63, pools 6.58 -> 6.50. All three switched off (code kept, flags off); land5 is unchanged and stays the READY batch. Gain rule: first round under +0.5 for these items. Judges' shared asks: layered depth fog and distant tree silhouettes instead of the grey horizon band; warm interior exposure without blown windows; a hero heartstone mesh and Stormheart wall/deck kit (new_art, Meshy, your call). Now running the T5 kitchen route pieces on tb/stormwood-routes with the tb/routes fixes; next look round tries the horizon/depth-fog lever.
- 25 Oct 11:15Z READY tb/stormwood-land5 90140cf6d (from origin/main 1d5faebac): work order item 6, round r16, code-blind CPU (3 fresh judges, standard prompt, 4 anchor pairs incl. craft 7.35, calibrate.py linear slope 0.73 / intercept 2.00, anchor RMSE 0.87 > 0.75 WARNING: report with caveat). Mapped Bar A before -> after (same fixed stands, calm; evidence `r16/`, sheet `r16/_sheet_r16.png`):
  - Ashfoot inside 4.46 -> 5.89 (+1.43): planked floor (cut-wood shader on the kit atlas), the village kit's bed/chest/barrel/shelf/peg rack on solid footprints, lower warmer light. Shared `cottage_interior.gd`, so every cottage-template interior gets it; `smoke_village_services_redesign` now accepts furniture by collider footprint and PASSES.
  - Lantern Pools 5.74 -> 6.16 (+0.42): new `stormwood_lantern_pools.gd` + `stormwood_lantern_pools.json` (client presentation): dark still pools with a glowmoss lip, rim stones, lantern posts at heightfield-screened flat spots; scatter inside each pool cleared on every shell (vegetation clear_area) so physics agree. Only one pool reads clearly (second heading); a fill-the-hollow level hid them (reverted).
  - Stormheart interior 5.50 -> 5.89 (+0.39): `deck_supports` (posts + knee braces at the trunk wall under OuterWorks, 12 hanging lanterns, 6 lit) and finer/deeper bark (repeat 16 -> 9 m, normal 0.65 -> 1.0).
  - Crown heartstone 5.02 -> 5.06 (no gain): 3.6 m stone + veined stone ring; judges still cannot find the stone and read the veins as wireframe. Kept OFF (height 2.4, satellites disabled); code stays.
  - F10#2 fights re-judge on main (#741 in), one set with each fight a side: capacitor_alpha 5.94, glass_field_alpha 5.77 mapped (GPU had 4.74 / 4.38).
  Checks on the lane tree (main identical to land5's base): test_stormwood_named_crown, settlement_grounding, village_boundary 21/0; smoke_stormwood_crown_heartstone 12/0; smoke_village_services_redesign PASS. Judges' shared top asks: depth fog and authored ground instead of the grass carpet and grey horizon band; brighter fights with real lightning impacts and a readable player creature; hero heartstone and buttressed Stormheart (new_art). Next round: heartstone (new approach), Ashfoot window/walls, more readable pools, depth fog.
- 25 Oct 07:30Z READY tb/stormwood-land4 ac706226e (your review of a63de1c12). Blocker fixed: merged origin/main (clean, 0ec056fd8); my earlier passes ran on tb/stormwood, which already carried main's tell_style, not on land4 alone. On the merged land4 tree (main checkout detached there, fresh --import): 96 unit tests 0 failed (strike_countdown, surge, surge_presentation, lightning_spare, surge_phase_bolt_hold, four_biome_debug_teleport, village_boundary); smoke_stormwood_ashfoot_shelter 16/0; smoke_stormwood_lightning 54/0. Fixes: (1) crackle time is TIME x pulse_enabled, so reduced motion freezes it; the 14 Hz hard flicker is now a 1.5 Hz soft shimmer (20 % depth), no flashing. (2) cottage props stand on FLOOR_TOP 0.10 (bed, chest, rug no longer sink or float). (3) `_scope` on the telegraph block (client-local presentation) and both f41_survey entries (capture-only). (4) feet: with the full 0.28 m pull the current drew over a standing trainer's boots (CPU capture, trainer 1.2 m from the strike centre); inside the rim it now lifts only inner_pull_m 0.1 and the boots and legs draw in front; scorch darkening on the feet is negligible. (5) the test now checks the built material and the shader's uniform list instead of source text.
- 25 Oct 05:10Z READY tb/stormwood-land4 a63de1c12 (stacked on land3 56ff32969, from origin/main; same commits on tb/stormwood). Your GPU work order items 1-5, functional and hard-rule first; nothing judged yet (each is a defect fix, CPU frames checked by eye; sheet `wo-1025/_sheet_wo1025.png`):
  1. Ashfoot floor: not grass but terrain z-fighting. `cottage_interior.gd` put the room floor exactly level with the terrain (building sunk 0.05, slab top +0.05), coplanar on the flat settlement pad. Slab centre -0.10 -> -0.05 (5 cm sill, under step height). CPU ash_in before/after: moss pattern across the floor -> clean floor. `smoke_stormwood_ashfoot_shelter.gd` now also checks the trainer stands >= 3 cm above terrain inside (16 checks, 0 failed). Every cottage interior gets the same 5 cm lift. (Separate look note: that interior is untextured flat colour.)
  2. Stormheart "red rails": the ring decks, fascia and pickets (cut-wood shader over the kit's orange WoodTrim atlas, tint #c4aa87 -> albedo about (111,66,29)). New `weathering` desaturation in `stormheart_cut_wood.gdshader`; `stormheart_presentation.json built_detail` wood_tint #dcd2c4, wood_weathering 0.75 -> aged grey-brown about (101,87,74). CPU six-heading before/after: red gone.
  3. Magenta strike ring: `stormwood_surge.json presentation.telegraph.outline_off` true (gated by `TELL_STYLE.outlines_off`, so combat.json `high_contrast_markers` brings the outline back). No rim, dashes or hazard-hue disc; a noise-broken scorch chars the soil inside strike.radius_m, live-current crackle runs over it and brightens with the countdown, the six leaders read as wider white-violet sparks, all lifted to grass height. Timing, radius, leaders and contact mark unchanged. The first try (scorch + thin sparks) vanished on night soil; that is why crackle/width were added. `test_stormwood_strike_countdown.gd` +1 test (10 tests, 0 failed).
  4. Capacitor grove: the catalogue stood ON the Capacitor alpha's seat (-1080, 3020), so the held alpha filled the lens; moving wild bodies cannot fix that (it is held there). Catalogue-only stand `debug_teleport_spots.json f41_survey` (old/new coordinates + _why; teleport arrival unchanged) 26 m back on the approach side (screened four candidates for a lens free of glowcaps and ferns). Plus a disclosed per-frame survey-lens clearance in `capture_f41_stormwood_catalog.gd`: wild bodies within 18 m of camera or trainer are set down just outside it, listed per frame in the receipt (`survey_clearance.moved`).
  5. Crown heartstone: catalogue-only `f41_survey` stand 12 m from the stone, heading 18 deg left of it (old 50 m, stone dead centre behind the trainer). The teleport keeps its tested 45 m clearance from Wen.
  Not runnable here: the F41 catalogue refuses CPU (High/Medium presets only), so 4 and 5 were checked with a local subset run (validation bypassed in an uncommitted edit, calm only). Please include both stands in the next GPU catalogue pass. Next for me: item 6 shared levers on the worst stands.
- 25 Oct 03:40Z READY tb/stormwood-land3 56ff32969 (from origin/main): Ashfoot shelter, your 03:03Z bug. Reproduced in the live production Stormwood with new `tests/smoke_stormwood_ashfoot_shelter.gd` (15 checks, 0 failed): inside the roof, roof + lightning shelter ON; 11 m out, roof OFF (near rain correct) but lightning shelter ON because the spot is inside the Ashfoot camp safe zone (`stormwood_surge.json safe_zones.ashfoot` r 42; WORLD §5.2 "camps with rods ... are safe"; `smoke_stormwood_b_surge_phase_traversal` asserts the same for camp zones); 60 m out, past the zone, both OFF. So the game follows the spec and the F41 catalogue capture's expectation was wrong; `capture_f41_stormwood_catalog.gd` now requires, at the 11 m stand, no roof and visible rain (unchanged) and lightning shelter equal to the zone rule's answer. No game code changed. QUESTION if you want "sheltered only under the roof": that would shrink the camp safe zones (a WORLD §5.2 change), so it needs an owner ruling; current rule kept.
- 24 Oct 06:35 UTC PARKED F41#5 (near-lens part) after two approaches: r15 judges (3/3) still mark the near-camera occluder PRESENT; the swap rule dissolves the reverse root at the lens but 5-7 m frame-edge trunks remain, and dropping the wide near-lens dither cost the capacitor fight -0.38. Code is on tb/stormwood (cfaf19da2, near_lens_hide OFF, focused test) and NOT in a land branch. F41#5 magenta: noted your 04:29Z message (arrived here 06:16Z); lane_charged only appeared in the judged r15 candidate, never in committed config; I won't touch it again. Rerun the defect pass after the Fights telegraph change lands.
- 24 Oct 06:35 UTC Status unchanged: F41#3 and F10#2 parked (best mapped CPU matrix 5.75/4.98/5.90, fights ~6.1); tb/stormwood-land dd722a9c9 still the only READY batch. Stopping the lane here unless a new direction arrives.
- 24 Oct 04:10 UTC READY (flag-off, no behaviour change) tb/stormwood-land dd722a9c9, from origin/main 5f1f388cc: glass field `shard_finish.crystal_model` (unset = off) + focused test `test_fulgurite_clusters_build_only_with_their_model`; both meshy-1024 Stormwood assets with provenance and texture policy; `_crystal_model_candidate` / `_model_v3_candidate` keys with the r14 scores in `_why`. Checks: test_stormheart_presentation, test_stormwood_glass_field_approach, test_stormwood_glass_field_identity, test_stormwood_scar_relief, test_texture_import_policy = 15 tests, 1569 assertions, 0 failed; texture_import_policy --check PASS (834).
- 24 Oct 04:10 UTC PARKED F41#3 and F10#2 (gain rule: r12/r13/r14 under +0.5; r14 was new art + fill). Best mapped CPU: matrix Calm 5.75 / Break 4.98 / aftermath 5.90 (r14 candidate, OFF); fights glass_field 5.91 / capacitor 6.34 (r13, within noise of main). No row at 6.7. Details in "Round r14 result".
- 24 Oct 04:10 UTC BLOCKED F41#5 (not clean): (a) near-lens trunk/root at the fixed giant/reverse/forest stands: needs your call on reframing those `--custom`/F41-look stands, or an exploration near-lens rule for the Meshy giant trees (about 3x render on llvmpipe, measured 22 Oct); (b) magenta lane/ring outlines in the real fights: Fights-owned (`combat.json charger_lunge.lane_charged`, OFF on main). Say if this lane should turn lane_charged on in a judged round.
- 24 Oct 04:10 UTC F41#1: top-20 listed above; 14 of 20 are other lanes' items (Creatures/UI/Fights/Camera/Shared art). P2-037 moved (v3 tower, PARTIAL). F41#1 and #2 cannot close from this lane.
- 24 Oct 04:10 UTC Messaging: send_message to your session is still refused here (elevated_session_untrusted_device). Your two messages (Meshy delivery 00:54Z, priorities 03:30Z) arrived. My meshy-refs were pushed at f40da8414 (tb/stormwood) before the request.
- 23 Oct 22:35 CT MESHY (send_message refused: elevated_session_untrusted_device). (1) Stormheart v3: `ralph/reports/STORMWOOD/close-1024/meshy-refs/stormheart_v3_ref_a.jpg` + `_b.jpg`, ~380 m, h:w 1.6:1, far LOD only, keep v2 V-split cleft, navy banners, no red. (2) Glass-scar crystal cluster: `meshy-refs/glass_scar_ref_details.jpg` + `glass_scar_ref_palette.jpg`, ~4 m wide x 2.5 m tall, pale-blue fulgurite on scorched crust. Return GLB paths on a branch; both stay flag-off until judged.

## Round r13 (in progress, 23 Oct)
- Baseline = origin/main 5f1f388cc (r11 look ON, commit 30b8264f4). Candidate = config only, OFF on main until judged:
  - wet-soil patches (`stormwood_ground_finish.json forest_layers.wet_soil`): tint #1e2420/#2a312b -> #39362b/#4a4738, item_size 2.8 -> 2.2 (the black patches fill the lower third of forest/giant frames);
  - `stormwood_surge.json sky_lightning.ground_light_exposure` 0 -> 0.6 (Break bolts light trunks and ground);
  - `presentation.telegraph.soft_style.enabled` true (F41#5: strike warning not a flat disc);
  - `stormwood_glass_field.json shard_finish`: height_scale 0.45 -> 0.8, emission 0.45 -> 1.1, crust_footprint 0.9 -> 1.05 (glass scar unreadable).
- Capture fix (run option only, no tool change): Break stills without `--fixed-fps` advance ~2-5 s of game time per CPU frame, so a 0.25 s bolt has decayed by the screenshot (why `_await_sky_bolt` "mostly timed out"). Matrix now runs as two passes per arm: Calm + aftermath at normal stepping, then `--phases=break --no-aftermath` with `--fixed-fps 10`. `--fixed-fps 20` for the whole run was tried and dropped: the 6 s phase blend then costs ~5 min per frame.

## Round r13 result (24 Oct, about 02:30 UTC)
- Batch: 4 anchor pairs, fixed: craft, f10_2_r3_capacitor, f36_0_npc:C5 (`--include`), plus f36_0_gap:C2; 5 candidate sets; three fresh code-blind judges, JUDGE_PROMPT v1 verbatim. Files: `r13/` (spec, sets, key, recorded defects, batch, mapped, `_sheet_r13.png` = Calm set).
- Fit: linear, slope 1.18, intercept -0.49, r 0.73, anchor RMSE 0.78 (warning: > 0.75). Confirming batch (top anchor 7.35).

| Set | Control raw (j1/j2/j3) | Control mapped | Candidate raw | Candidate mapped | Gain |
|---|---|---|---|---|---|
| F41#3 Calm | 5.5/4.9/4.8 | 5.48 | 5.6/5.0/4.8 | 5.56 | +0.08 |
| F41#3 Break | 5.0/4.5/4.3 | 4.93 | 5.1/4.5/4.3 | 4.97 | +0.04 |
| F41#3 aftermath | 5.8/5.2/5.2 | 5.87 | 5.9/5.3/5.2 | 5.95 | +0.08 |
| F10#2 glass_field | 5.7/5.4/5.2 | 5.91 | 5.6/5.2/4.9 | 5.68 | -0.23 |
| F10#2 capacitor | 5.9/5.8/5.5 | 6.26 | 5.9/5.8/5.7 | 6.34 | +0.08 |

- Control is main's ON r11 look; its mapped scores (5.48/4.93/5.87/5.91/6.26) sit near r12's mapped candidate scores, so main holds roughly the r11/r12 level.
- Reading: the r13 config changes are below the judges' resolution. Gain rule: r12 and r13 are two consecutive rounds under +0.5. Before parking, one clearly different approach (r14).
- F41#5 defect scan, all three judges: no flat magenta ground disc in Break on either side (FIXED); the fights still show thin magenta lane/ring outlines (PARTIAL; Fights-owned `charger_lunge`/telegraph). Other recorded defects still present: near-lens trunk/root (forest, giant, reverse), black foreground patch (forest), squat Stormheart, unreadable glass scar, Break forest near-black, lightning not lighting trunks and ground in the forest stands.
- Judges' top changes (all three): (scene) relight forest interiors (lift shadow and fill, rim on trunks, lightning lighting ground and trunks, depth fog); (scene, out of lane) slim the fight HUD and frame the pilot larger, real arc/crack telegraphs and impact bursts; (new_art) a tall split Stormheart hero, a strike-scarred glass field.
- Coordinator delivered the Meshy batch on `tb/meshy-1024` 38602bdb0: `assets/props/meshy-1024/stormwood_stormheart_v3_far` (about 1.2:1, faint cleft) and `stormwood_glass_scar_crystals`. Unwired.

## Round r14 (clearly different approach: new art + interior fill), capturing
- Candidate = r13 patch plus (`r14-candidate.patch`):
  - Stormheart hero `meshy_hero.model` -> `assets/props/meshy-1024/stormwood_stormheart_v3_far` (coordinator Meshy, tb/meshy-1024 38602bdb0), height 300 m, shape 0.8/1/0.8 (v3 is about 1.2:1; 380 m ran the crown off the top of the 300 m stand's frame);
  - glass field `shard_finish.crystal_model` -> `assets/props/meshy-1024/stormwood_glass_scar_crystals`, `crystal_height_scale` 0.55 (one fulgurite cluster per scar, 3.9-7.2 m); new code `_add_crystals` in stormwood_glass_field.gd (no key = off), focused test `test_fulgurite_clusters_build_only_with_their_model` (fails without the code);
  - forest-interior fill: `stormwood_look.json rig.environment.ambient_energy` 1.65 -> 2.3 (shadow opacity is pinned by the surge tests; ambient is not).
- Both Meshy folders: texture_import_policy --apply then reimport; --check PASS (6 sidecars mode 2).
- Control: the r13 control frames (main 5f1f388cc, unchanged rendering path).
