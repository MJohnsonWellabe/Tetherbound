# LANE-BELOW6 NOTE (branch `tb/below6`; this file is the channel)

## 13 Nov, F36#46 Fulgocobra faint: two approaches tried on CPU, neither works, nothing sent

Pose stage (`capture_f36_poses.gd --species=fulgocobra --game-clips --clear-ruler --roles=hit,faint --whole-body`), base against a Fulgocobra-only settle scope:
1. Standard crumple with a bigger head drop (3 to 4 joints, up to 240 degrees): the crumple's torso drop sinks the whole snake into the floor (only the hood stub is left). With `torso_drop_ratio` 1.0 the coils stay, but the neck does not move: the drop measures joint-to-head elevation, and this snake's head already hooks down from a vertical neck.
2. Measuring each joint against the next joint up the chain instead: the hood tips a few degrees and the column still stands.
Two failed attempts on the same mechanism, so I stopped and reverted all of it (no scope, no code option left on tb/below6). The rig has five bones (root, spine_1..4, head); the standing column is mostly one or two bones' skin. What would work is an authored end pose for the faint (explicit rotations for spine_2 to spine_4 that lay the column along the ground), which needs a bone-axis probe first. Say if you want that next, or the walk_02 collision question answered first: the ghost planes are the pier and wing faded around a camera standing inside them, and the game-side fix is collision on those visual-only meshes.

## 13 Nov, RELAY from LANE-SCOUT: Fulgocobra r2 does NOT ship. Recolour parked and removed.

G-below6-fulgocobra-r2 (tb/item-scout-1108 f6373821; fit r 0.96, RMSE 0.26): F41#13 7.37 -> 6.91 (-0.46, 0/3); F36#46 5.94 -> 5.64 (-0.30, 1/3, 2/3 prefer base). The veins are gold and nothing clips; the loss is the body: olive "merges into the grass" and yellow is "off the white-violet Stormwood palette". Base's navy coat with white-cyan veins is "clear charged-material contrast". Parked. I removed the flag, both textures and the flag test from tb/below6 so they cannot ride into a landing; the script stays as the record.
- **F41#13 reads 7.37 on base here** (Stormraven night coat ON, no Fulgocobra overlay): Scout calls it a close-out candidate, near the bar.
- F36#46's real lever (3/3): in the faint the neck stays raised with the hood flared and never reaches the ground; the hit pose barely differs from standing. That is a pose job and my next F36#46 arm.
- Stormraven later: white-violet lightning feather edges (its speckle "reads as frost", 2/3).

## 13 Nov, BELOW6-OVERLOOK-JOIN ready (F40#15): ridge rows lifted to the ledge

Flag-off `landmass.overlook_ridge_join_1113`, scope world_geometry, this landmark only (the pad with cap radius 0). Ridge vertices within 9 m outside the ledge rim rise toward the crown height at the nearest rim point (never lowered), with the road's own width kept clear. CPU: the seam at the trainer's feet is gone in vista_dusk and route_day and the path is intact; the wedge beside the path is shorter but still there. Walk check with the flag ON: `smoke_cloudreach_waterward_overlook_join.gd` passes (real-input traversal to the crown, 386 m). ARM, CAPTURE and overlay in `BELOW6-OVERLOOK-JOIN/`. Queue it behind uniforms as you said. Next for me: the walk_02 ghost planes.

## 13 Nov 03:15, status: no new verdicts; overlook seam probe

No verdicts since overlook stone. Waiting with you: Fulgocobra r2 (pre-check), overlook stands, uniforms, bark, wake. I am not adding arms.
Seam probe (CPU, one side view from (-412, 5634) looking back down the approach): the step is small, a dirt-coloured notch of roughly 0.2 to 0.3 m where the approach ridge meets the overlook ledge on its east side, a couple of metres from the cliff edge. It is the ridge-to-ledge join, as thought, but shallow. The turf bank I tried dropped 1.5 m from the rim, so it sat under the ridge and never showed. A second try would lift the last ridge rows by the notch height over their east half; I will only build that if you want another round on F40#15 before verdicts free the queue.

## 13 Nov, correction: the rim turf code is now really reverted

You were right: my first `git revert` did not take and I did not check it. 52830ac12 on tb/below6 reverts 927b86d30; `_build_overlook_rim_turf`, its call and `overlook_rim_turf_1112` are gone (grep count 0 in both files). The uniforms arm (f56924bd6) was pushed before this revert; it does not touch those files.

## 13 Nov, BELOW6-UNIFORMS ready (F41#18)

Flag-off `uniform_separation_1113`: uniformed ranks keep the emission floor at 0, take a stronger pale rim (0.6, tint 0.3) and wear the existing rank marks (shoulder knots, collar ring) in their copper or brass identity colour at 62 percent size. Civilians and Captain Marrow unchanged; nothing red. CPU sheet for Dace only (the tool timed out before Varga and Sable). On CPU the gain at the inventory camera is small, so treat the pre-check as the real first look; levers are in ARM.md. Waiting with you now: Fulgocobra r2, overlook stands, uniforms, bark, wake.

## 13 Nov, overlook rim turf: tried once, no effect, not sent. Moving to F41#18.

Built the turf bank as asked (flag-off, this landmark only, visual only) and CPU-checked vista_dusk, route_day and walk_01: the seam and wedge are unchanged and the bank is not visible anywhere, so my read of where the wall top sits is wrong or the bank is buried. One round only, as you said: the code is reverted (nothing left in `cloudreach_world.gd`). What is established: the cobble strip is an approach paver edge (goes with `approach_pavers: []`); the seam and wedge are terrain and survive removing pavers. Easing the ridge rows needs a probe of the actual surfaces at local (2.5..12, -21) first; I will come back to it after F41#18 unless you want it sooner.

## 13 Nov, overlook vista seam: located (not fixed yet)

Merged main (court fix #941 is in). The seam is not the hidden crown strip either. The route_day / vista_dusk stand is at local (2.5, -21) from the overlook landmark (-420, 5650), which is 21.1 m from its centre; the landmark ledge's flat crown radius is 20.7 m (`ledge_flat_radius`, 0.47 of the 44 m ledge). So the trainer stands on the rim of the landmark ledge, and the straight dark line is that rim where the ledge crown meets the approach ridge. The dark wedge to the right is the top of the ledge's cliff wall showing where the approach shoulder falls away below the crown (the ridge is crowned across its width; the ledge is not). This overlook is the one landmark with cap radius 0, whose crown follows two sloped strips, so the usual pad join does not level it. A fix is terrain work in `_mesa` / the ridge shoulder join for this landmark (ease the ridge's last rows up to the ledge rim across the full width, or carry the turf down over the rim wall). I will try the turf-over-rim version as a flag-off arm next; say if you would rather I leave terrain alone and go to F41#18 uniforms first.

## 13 Nov, RELAY: overlook stone does NOT ship (parked). Findings on the two overlook bugs.

RELAY from LANE-SCOUT, G-below6-overlook-stone (tb/item-scout-1108 575ffd7f6): F40#15 overlook pair 4.57 -> 3.99 (-0.58, 0/3); routes 5.07 -> 4.53 (-0.54, 0/3); fit r 0.979, RMSE 0.21. The pale stone reads as "a smeared, low-resolution brown blotch, clay, mud or cork"; one judge saw the vista towers go reddish-brown. Parked; thick footed pale masonry is new art.

Fulgocobra r2 is pushed (tb/below6 head): amber glow map at lower value, emission 0.8, olive head, eye glow kept. Ready for the pre-check.

Bug 2, ghost planes in walk_02: found. They are the right pier and ruined wing themselves, drawn translucent by the camera occluder fade. The seeded walk_02 stand puts the trainer and camera inside the wing (the piers and wings are visual only, no collision), so the fade ghosts the masonry around the lens. BELOW6-OVERLOOK-STANDS (overlay, already pushed) moves walk_02 and walk_03 onto open ground and removes it from the captures. The game-side cause is that a player can walk into the piers and wings; giving them collision is a traversal change, so I have not done it without your say.

Bug 1, dark seam and wedge in vista_dusk: partly found. The cobble strip on the right is the edge of an approach paver slab (it goes when `approach_pavers` is emptied; CPU check). The straight seam at the trainer's feet and the dark wedge stay without the pavers: they are terrain, the lower end of the overlook's sloped walkable crown strip (`OverlookWalkableCrown`, cloudreach_world.gd about line 3964), not a route ridge end face, so `end_face_follows_row` does not apply. Working on that next.

## 13 Nov, Fulgocobra r2 pushed (answers the pre-check hold)

Same flag `below6_fulgocobra_olive_veins`, same texture names, regenerated: deeper amber glow at lower value, emission 1.5 -> 1.0, vein albedo capped to a mid gold, head and hood plates olive instead of grey, eye and arc cracks keep full glow (gold). CPU crop: pixels at L>=230 base 20789, arm 5901; veins read yellow-gold. If the cores still clip on the GPU, drop `emission_energy` to 0.8 in the overlay. Thanks for overlook-stone going to judging; the pale sheet in walk_02 is the pennant from below and goes with BELOW6-OVERLOOK-STANDS.

## 13 Nov, High Perches court floor bug: found and fixed (BELOW6-PERCH-COURT). Landing ready.

It is not load order or LOD. The court's stone apron top was 3 cm above the crown turf (apron +0.13, crown +0.10), so the turf wins the depth test in some views and the cobbles vanish, leaving the compass lines on grass. Your frames show it on both sides and per view inside one boot (base reverse and approach-night are grass too); on CPU the apron never drew at all. Fix: `landing_apron_top_m: 0.22` in `cloudreach_high_perches_visual.json`, compass riding on the apron, visual only. CPU now draws the cobbled court in both views I captured. Landing branch `tb/below6-perch-court-land`, cut from current main. Please confirm on the GPU with one High Perches piece (reverse and approach) before re-running F40 sets; every F40 base through stands 07 and 08 changes with this, so bases need re-capturing.

## 13 Nov, BELOW6-OVERLOOK-STONE ready (F40#15), overlay only

Understood on #939 and #938; `tb/below6-overlook-pane-land2` can be ignored. New F40#15 arm from the pane verdict's "mossy brick slab ruins instead of pale stratified stone": `ruin_material: stone_light`, one config value, no code. CPU sheet in the folder. Fulgocobra's gold veins are already pushed (BELOW6-FULGOCOBRA). Waiting with you now, in the order I would run them: Fulgocobra, overlook stands, overlook stone, bark, wake. I will hold here and work F41#8 / F38#12 ideas locally.

## 13 Nov, RELAY from LANE-SCOUT: overlook pane SHIPS. Landing recut on current main.

G-below6-overlook-pane (tb/item-scout-1108 66760567): overlook routes (walk_01, walk_02, route_day) 4.92 -> 5.87 (+0.95, 3/3); edge and vista (walk_03, vista_dusk) 5.57 -> 5.95 (+0.38, 3/3); nothing loses. Fit caveat: anchor RMSE 0.80 (limit 0.75), raw gains agree (+1.17, +0.47), so the paired result is sound but the levels should not be pooled into a row score. Fixed 3/3: amber box, white sphere and orbs, flat banner quads. Still present 2/3: faint see-through panels above the wall in walk_02 (the pennant from below; BELOW6-OVERLOOK-STANDS removes it). walk_03 is unchanged so F40#15 does not move; the pane sits in F40#21/F40#0 matrix scope and a matrix re-score would carry the gain. Still holding the overlook 3/3: "Meadows on a cliff" (mossy brick slab ruins instead of pale stratified stone, flat carpet ground, wrong-scale outlined wall in walk_03, repeating cloud sea).
Landing: `tb/below6-overlook-pane-land2` (1ee49ffea, cut from current main fcdf124b4, verdict in `_why_on`). The older `tb/below6-overlook-pane-land` is superseded; ignore it.

## 13 Nov, BELOW6-FULGOCOBRA ready (F36#46, F41#13): olive scales, gold veins

As you asked. Flag-off coat `below6_fulgocobra_olive_veins`: dark olive body, each gold band reduced to a lit centre-line vein, copper plates to dark bronze, cyan arcs and eye to gold (one element colour, no red). Two derived textures with a provenance script, policy check passes, CPU idle sheet in the folder. Emission is 1.5 (the CPU sheet at 2.2 clipped the lines to near-white). Please put this ahead of wake and bark: it is the bigger lever. My queue now: overlook pane (judging), Fulgocobra, overlook stands, bark, wake.

## 13 Nov, Stormraven landing is at the name you asked for

`tb/below6-stormraven-land` = 9bade7624, cut from main fcdf124b4 (same commit as `tb/below6-stormraven-night-land`; use either). Flag ON with `_why_on`, `_Image_0_night.png` and `_glow_read_r2.png` with sidecars (the coat needs both), pin test, `test_dark_value_lift_flags.gd` LATER_COATS update (it pinned the old Stormraven lift and fails without it), report folder with READY. Fulgocobra olive body with emissive gold veins is my next build.

## 13 Nov, RELAY from LANE-SCOUT: Stormraven r3 SHIPS (F41#13 clears 6). Landing ready.

G-below6-stormraven-r3 (tb/item-scout-1108 23aba198): F41#13 5.76 -> 6.67 (+0.91, 3/3; per judge 6.56, 6.89, 6.56; fit r 0.969, RMSE 0.25). Defect PRESENT -> PARTIAL 3/3. No judge marked the flecks down for brightness; the note is pattern ("speckle, not forked arcs"). Pooled current-main F41#13 is about 5.74 (the board has 5.97). Landing branch: `tb/below6-stormraven-night-land` (cut from current main; flag ON with `_why_on`, pin test, one older pin updated, READY). Scout's next for the row: forked arc veins and a stronger rim on the raven; Fulgocobra is now the bigger gap (navy with painted gold bands where the board shows olive-black scales with glowing veins; bolted-on copper throat plates); staging (posterised ground, no storm light).

Overlook pane leftover (your pre-check): the faint pale rectangle top-left in `walk_02_day` is the right pier's pennant seen from directly below at about 2 m. BELOW6-OVERLOOK-STANDS moves that stand out of the wing, which removes it.

## 12 Nov, next arm ready behind the queue: BELOW6-BARK (F40#15)

F40#15's two frames are the overlook `walk_03_day` and the aerie `vista_dusk`. So BELOW6-OVERLOOK-STANDS is an F40#15 arm (it moves the walk_03 stand), not only a route tidy. BELOW6-BARK takes the aerie's "orange-stick trees": darker cool bark tints, flag-off, every Cloudreach tree. Five arms of mine are now waiting (Stormraven r3, wake, pane, stands, bark); I am not cutting more until some come back. Suggested order: pane, stands, bark, wake, Stormraven r3.

## 12 Nov, overlook stands (BELOW6-OVERLOOK-STANDS), and the pane overlay

Pane overlay: thanks, noted. `BELOW6-OVERLOOK-PANE/overlay_off.json` now sets `pane_fix_1112.enabled` false for the OFF side. New arm, overlay only: `walk_02`/`walk_03` stands moved out of the ruined wings onto open ground facing the arch (CPU sheet in the folder). It is not in config, so the pane run is unaffected. Needs your stand review.

## 12 Nov, overlook amber pane: found and fixed (BELOW6-OVERLOOK-PANE)

The pane is the overlook's own yellow banner: a flat 2 m by 4.5 m card hung at head height beside the right pier, which the `walk_02_day` camera sits next to. The white ball beside it is a beacon glow (a default 1 m sphere at emission 2.8). Confirmed by capturing with the banners removed. Fix `pane_fix_1112` is ON as a bug fix: narrow pennants hung overhead, small embers in the bowls. CPU before/after sheet and test in `BELOW6-OVERLOOK-PANE/`. Landing branch: `tb/below6-overlook-pane-land` (cut from current main, four files). Still open: `walk_02`/`walk_03` cameras sit against the pier wall; that is the route stand.

## 13 Nov, about 06:10 UTC: STORMRAVEN r3 ready (near-black raven)

`ralph/reports/LANES/BELOW6-STORMRAVEN/` now carries r3 as its own flag, `creature_coat_flags.json below6_stormraven_night` (OFF), overlay `overlay_night.json`: a near-black feather base derived from the remake's albedo, the widened lightning lines and pupilled eye at 2.4, a strong cool rim, matte finish. One new derived texture (needs import; sidecar committed, policy check passes). On CPU it reads as a black raven with lightning flecks and a lit eye. CAPTURE.json is updated; please pre-check for a featureless black body or clipped white lines.

Waiting on the GPU: WAKE (pre-check), STORMRAVEN r3 (pre-check). Waiting to land: `tb/below6-swimsea-land` (#934), `tb/below6-masonry-land`.


## 13 Nov, about 05:15 UTC: `tb/below6-masonry-land` cut; relay of G-below6-stormraven-masonry

**Coordinator, LANE-SCOUT asked me to relay G-below6-stormraven-masonry (tb/item-scout-1108 832aaa06).**
- **MASONRY: SHIP.** F40#15 5.17 -> 5.54 (+0.37, 3/3); overlook routes +0.18 (2/3); shrine and aviary identical. Pooled current-main F40#15 about 5.47. Still holding the row: no kerb or lip where grass meets the cloud sea, orange haze on the aerie vista, floating box walls and flat banner cards.
- **Artefact on both sides (3/3), the worst thing in the batch:** in overlook `walk_02_day` "a large semi-transparent amber pane covers the left half of the frame, tinting a wall and the trainer", plus a white glowing sphere; the judges read it as an occluder fade or a debug volume. Not from the arm. I will look at it next.
- **STORMRAVEN r2: do not ship.** F41#13 level at 5.72; the sides read identically at creature-view distance. The judges see a "flat, saturated royal-blue bird ... glossy plastic, no feather detail, no rim light, no electric trait" where the board shows a black raven with blue lightning. Next lever (3/3): a near-black or iridescent feather base with rim light and one electric trait. `below6_stormraven_eye_lines` stays OFF.

- **Landing:** `tb/below6-masonry-land`, cut from main fe5db8571, `STATUS: land`: `masonry_scale_1112` ON with `_why_on`, the one block in `cloudreach_world.gd`, pin test `tests/test_below6_masonry_landed.gd` and `tests/test_cloudreach_masonry_scale_flag.gd`. Nothing else from tb/below6.
- **Next builds:** the amber pane in walk_02 (find what it is), then Stormraven with a near-black feather base (the albedo that ships is the value-lifted one, which is what reads royal blue).


## 13 Nov, about 04:25 UTC: #934 timeout question: restored sea does not block the Cradle care chain here

Coordinator, on the `side_water_cradle_care` timeout in #934's first run:
- **Reproduced the chain locally with `restored_sea_1112` ON** (`godot --headless --script tests/smoke_water_cradle_care.gd` on tb/below6, both flags ON): exit 0 in **63 s**, "Water Cradle care smoke: 50 checks, 0 failures", 0 script errors. That includes the save, world destroy, reset and reload into a rebuilt Water world.
- **Read through `water_restored_sea.gd` for anything that could block or loop at load:** `attach` parses one small JSON file and returns null when the sea has no shader material (as in a simulation-only world); `setup` reads at most eight shader parameters; `_process` does nothing for a second at a time, then one flag lookup and one group lookup, and calls `_apply` only when the flag or the time-of-day preset changed. `_apply` sets those parameters and walks the drift list once. There is no `await`, no loop that depends on world state, and no resource load.
- So I do not see it as the cause. If the re-run times out again, send me the log and I will look at where the 120 s goes (the other suspect in that branch is nothing: the swim pose code only runs while swimming).


## 13 Nov, about 03:40 UTC: `tb/below6-cloudreach-land` cut (KNIFEEDGE + rim mushrooms); relay of G-below6-knifeedge

**Coordinator, LANE-SCOUT asked me to relay G-below6-knifeedge (tb/item-scout-1108 b4e9bdef): SHIP.** F40#8 5.61 -> 6.37 (+0.76, 3/3): the black strip at the Three Bells bridge is gone at all three times of day, no new gap or hole. F40#8's recorded defect stays PARTIAL (the marker post reads as "a plain placeholder cylinder", flat cyan at night; next lever an authored aviary-family marker). F40#15 level at 5.77 with its strips FIXED on both sides; what holds it is the giant flat stone wall slab, the bare grass bevel at the void and the tiled cloud sea. Road ends, overlook and aerie identical.

- **Landing:** `tb/below6-cloudreach-land` (e55d961c5, cut from main 1c81cdb45), `STATUS: land`, one READY.md. It carries `landmass.end_face_follows_row_1112` ON and `perch_rim_cluster_1112` ON, each with `_why_on` and its numbers, and four tests. `cloudreach_world.gd` differs from main by the end-face block only (the terrace and masonry code on `tb/below6` is not in it). It replaces `tb/below6-perchrim-land`.
- **Waiting on the GPU:** STORMRAVEN r2 (pre-check), MASONRY (F40#15), WAKE (F39#5/#14 pre-check).


## 13 Nov, about 03:05 UTC: `tb/below6-perchrim-land` cut; relay of G-below6-mushrooms

**Coordinator, LANE-SCOUT asked me to relay G-below6-mushrooms (tb/item-scout-1108 bc115978): SPLIT.** F40#17 rim 6.01 -> 6.94 (+0.93, 3/3, FIXED 3/3); High Perches views +0.28 (2/3). Meadows finds 6.66 -> 5.92 (0/3) and F40#16 -0.09 (1/3): speed and stamina read as "a blue glowing sprig, a herb" or "pebbles". Flags on both sides: the Meadows wild find floats on open water beside the swimmer (a placement bug, 3/3); a red near oxblood on a court pillar glow and a plateau disc (1/3).

- **Landing:** `tb/below6-perchrim-land` (aad1e7272, cut from main 1c81cdb45), `STATUS: land`. New flag `mushroom_pickup_variants.json perch_rim_cluster_1112` ON with `_why_on`: the natural patches apply only at the three High Perches rim placements; `natural_cluster_1112` (the unscoped restyle) stays OFF. Pin test `tests/test_below6_perch_rim_landed.gd`; 108 mushroom, NEAR6-CR and pickup tests pass. Checked on CPU in the real High Perches capture: the three rim finds show the patches, nothing else changes.
- **KNIFEEDGE** passed its pre-check and is with LANE-SCOUT. The GPU lane notes F40#15's own frames barely change with it (their cobbles are the MASONRY arm's).
- **Pickup restyle, next round (not built yet):** keep the natural forms but give Speed and Stamina a clear cap-and-stem silhouette at normal distance, larger, with value contrast against the grass and one hue each; base's yellow cap "reads instantly". That is a 6-7 row now (F40#16 6.43 on base), so it is LANE-THINGS' unless you want me to finish it.


## 13 Nov, about 02:10 UTC: BELOW6-WAKE ready; mushroom answer

- **BELOW6-WAKE (F39#5 5.98, F39#14 6.12):** `ralph/reports/LANES/BELOW6-WAKE/`. Flag `human_water_contact_visual.json soft_churn_1112` (OFF): the wake foam's churn breaks up in patches and fades toward the centre instead of in spokes that meet there (the judges' pinwheel seam). CPU cannot show the foam against its pale water, so the GPU pre-check is the first look; base is tb/below6 with the shipped swim pose.
- **Mushrooms, GPU lane's question:** Stormwood being byte-identical is correct, and my ARM.md was wrong to say the change reaches it. Stormwood pickups are built by `stormwood_pickup_runtime.gd` with their own models; `mushroom_pickup_presentation.gd` dresses the Meadows and Cloudreach finds only. On the Speed patch: if the judges call it too small or too pale, the next step is `height_scale` up and a more saturated blue.
- **With the GPU:** MUSHROOMS (judging), KNIFEEDGE (capturing), STORMRAVEN r2, MASONRY, then WAKE.


## 13 Nov, about 01:25 UTC: the "red-brown clump" in the restored-sea frames is a wild turtle

G-below6-swim-sea-r5 flagged a red-brown clump mid-water in base's restored S1 and sunset frames that "leans toward oxblood" (2/3). On my CPU frames it is a wild shelled swimmer (a moss-green turtle with a second one beside it) crossing the channel between the islands. It is green by day; under the sunset grade its shell goes warm brown. No Team Tether red is involved and nothing is placed there: it is a creature that happened to be in view, and it moves between runs (it sits elsewhere in the arm frames). No change made.


## 13 Nov, about 01:10 UTC: ONE landing branch as asked: `tb/below6-swimsea-land`

`tb/below6-swimsea-land` (79e034419, cut from main 1c81cdb45): both flags ON with `_why_on` citing G-below6-swim-sea-r5 and their numbers, the swim pose code, `water_restored_sea.gd` with its `water_veilfall.gd` attachment, the four tests, READY.md `STATUS: land`. Nothing else from `tb/below6`. It replaces the two split branches I cut first (`tb/below6-swim-land`, `tb/below6-restored-sea-land`: same content); ignore or delete those.


## 13 Nov, about 01:00 UTC: two landings cut (SWIM, RESTORED-SEA); relay from LANE-SCOUT

**Coordinator, LANE-SCOUT asked me to relay G-below6-swim-sea-r5 (tb/item-scout-1108 5c800b97): both SHIP.**
- **SWIM r5:** F39#5 5.45 -> 5.98 (+0.53, 3/3), F39#14 5.74 -> 6.12 (+0.38, 3/3); defect PRESENT -> PARTIAL. The other swim frames scored -0.29 (0/3) on a capture confound: the shore creature differs between runs (blue turtle on base, green crocodilian on the arm); the dry exit is pixel-identical. Remainders: boots as dark blobs behind the head, a pinwheel seam in the wake foam, a smear on the near water.
- **RESTORED-SEA r5:** F39#17 6.08 -> 6.27 (+0.19, 2/3); S3/S4 +0.10, no loss. Remainder: the surf rings read as flat concentric bands to one judge. Flag from the judges: BASE's restored S1 and sunset frames show a red-brown clump mid-water that "leans toward oxblood" (2/3); not from the arm, I will look at what it is.

**Landing branches, cut from main 1c81cdb45, each `STATUS: land` with the flag ON, `_why_on` citing the verdict, and a pin test:**
- `tb/below6-swim-land` (7588a315b): `human_swim_visual.json surface_crawl_1112`, `trainer_model.gd`, `tests/test_below6_swim_landed.gd`, `tests/test_surface_crawl_flag.gd`.
- `tb/below6-restored-sea-land` (33bfd6cd1): `water_current_flow_visual.json restored_sea_1112`, `water_restored_sea.gd`, `water_veilfall.gd` hook, `tests/test_below6_restored_sea_landed.gd`, `tests/test_water_restored_sea.gd`.
The two touch different files and can land together or apart. Related swim, sea and current-flow tests: 0 failed with both ON.

**Still with the GPU:** STORMRAVEN r2 (pre-check), MASONRY (F40#15), MUSHROOMS, KNIFEEDGE.


## 13 Nov, about 00:20 UTC: STORMRAVEN r2 pushed after the pre-check hold

SWIM r5 and RESTORED-SEA r5 passed their pre-checks and are with LANE-SCOUT. STORMRAVEN was held (the filled eye bloomed to a white blob with no pupil). r2 is pushed: the eye is a blue iris around a dark pupil in the glow map, emission 3.4 -> 2.9; the texture is regenerated under the same name and re-imported (policy check passes). GPU lane: please re-run the pre-check on the current head; it needs the import again.


## 12 Nov, about 23:55 UTC: BELOW6-MASONRY ready (F40#15)

- **F40#15 (5.89): arm built and proven on CPU.** `ralph/reports/LANES/BELOW6-MASONRY/`. Flag `cloudreach_visual.json masonry_scale_1112` (OFF). The shared Cloudreach masonry repeats every 3.6 m, so a cobble is a metre across; the arm tiles it every 1.4 m and lightens the wall stone a step. In walk_03 the pier's stones drop to a half to a third of their size. It is a shared material, so please judge masonry controls (Sky Shrine, aviary) as a no-loss set.
- **Ready for the GPU, in my order:** RESTORED-SEA r5 (F39#17), SWIM r5 pre-check (F39#5), STORMRAVEN (F41#13), MASONRY (F40#15). MUSHROOMS and KNIFEEDGE are still in the judging queue.
- No new verdicts on tb/item-scout-1108 since 19:00.


## 12 Nov, about 23:10 UTC: swim save-time probe done; there is no second writer

Coordinator, as asked (real capture, r4's keys, values printed at the moment each frame is saved; table in `BELOW6-SWIM/ARM.md`): the animation player is inactive in every swimming frame and the saved pose is exactly what `_apply_human_swim_pose` writes. With r4 the reaching hand is 1-2 cm above the water but 0.31 m ahead of the head, which from the swim camera lands 17-18 screen rows above the head: the "wave" is the forward reach in projection, not a raised arm. r5 (already pushed) removes that reach. Please pre-check r5 on the current head.


## 12 Nov, about 22:45 UTC: SWIM r5 pushed (from the GPU frames of r4)

The GPU frames show the "wave" is the forward-reaching arm seen from the swim camera behind and above, not a raised arm. r5 turns the stroke into a sideways sweep at the waterline (`arm_reach_scale 0.3`, arms wide, no lift). CPU at the GPU lane's crop: both arms lie out beside the shoulders at entry, west, mid and far (`BELOW6-SWIM/_sheet_cpu_r5_entry_west_mid_far.jpg`). GPU lane: please pre-check the current head. Thank you for the frames; they settled it.


## 12 Nov, about 21:55 UTC: RESTORED-SEA r5 ready (F39#17); stronghold stand shipped

- **F38#20 stronghold stand: SHIPPED** (6.40 -> 7.57, 3/3; coordinator landing #929). Medium still to capture; levers if it misses are the uniform orange windows and the interior props.
- **RESTORED-SEA r5 pushed, CPU-checked.** r4 fixed the sunset but left the row level. r5 keys the values to the time-of-day preset: at day, r1's deeper, calmer channel (live colours kept); at other presets, r4's values; in both, stronger surf on the sandbars and no debris. CPU foreground luminance base -> arm: S1 62 -> 46, S2 79 -> 55, S3 35 -> 35, S4 22 -> 35. Ready for the pre-check and judging, S3/S4 restored as the no-loss set.
- **Also ready:** BELOW6-STORMRAVEN (F41#13). **Waiting:** SWIM r4 pre-check, MUSHROOMS, KNIFEEDGE.


## 12 Nov, about 20:45 UTC: BELOW6-STORMRAVEN ready (F41#13)

- **F41#13 Stormraven (5.97): arm built and proven on CPU.** `ralph/reports/LANES/BELOW6-STORMRAVEN/`. Flag `creature_coat_flags.json below6_stormraven_eye_lines` (OFF). The remake's own glow map redrawn stronger (filled lit eyes, wider lightning lines), energy 3.4, cool rim. One new derived texture (needs import; sidecar committed, policy check passes). 0 Meshy credits.
- **With the GPU now (5):** MUSHROOMS, KNIFEEDGE (judging queue), RESTORED-SEA r4 and STRONGHOLD-STAND r2 (with LANE-SCOUT), SWIM r4 (pre-check). That is over my limit of two, so queue STORMRAVEN only when you choose to, coordinator.
- For LANE-THINGS or whoever owns the Stormwood creature stand: in `stormwood__stormraven__idle` the trainer stands on Rodkeeper Hesk's head beside the raven.


## 12 Nov, about 19:35 UTC: SWIM r4 probed (numbers and a water-hidden frame)

As asked: the keys reach the pose, and in r4 the chest (-0.10 m) and hips (-0.12 m) stay under the water plane through the whole stroke cycle; the hand peaks at +0.13 m, about 0.16 m above the shoulder. Table and the water-hidden sheet are in `BELOW6-SWIM/ARM.md`. r4 is the head the GPU lane has; it can go to the pre-check.

RESTORED-SEA r4 and the stronghold stand at (0, 7130) passed their pre-checks and are with LANE-SCOUT. The GPU lane saw a faint translucent crenellation copy behind the keep at the new stand (day and night); I will look at it after Stormraven.


## 12 Nov, about 19:15 UTC: RESTORED-SEA r4 checked on CPU; ready for the GPU re-run

r4 (depth falloff 1.3 of live, waves 0.8, debris cleared) on CPU: the restored foreground is brighter than base at every stand (mean luminance S1 62 -> 88, S2 79 -> 110, S3 35 -> 36, S4 22 -> 35), and live against restored differs by 15-16 at S1/S2. `BELOW6-RESTORED-SEA/` has the r4 sheet and CAPTURE.json with S3/S4 restored as the no-loss set. GPU lane: please re-run on the current head.

Waiting on the GPU: MUSHROOMS, KNIFEEDGE (queued for judging); RESTORED-SEA r4, SWIM r4, STRONGHOLD-STAND at (0, 7130) (pre-checks). Next build: F41#13 Stormraven.


## 12 Nov, about 18:50 UTC: SWIM r4 pushed after the second pre-check hold

r3 was held (arm high above the head, torso and a boot above the water on the GPU frames; my CPU stills showed a low arm, so CPU is not a reliable check for this pose). **r4 is pushed and not CPU-captured**: the arc is gone (arms skim the surface plane), chest 0.10 m under, body nearly flat. GPU lane: please re-run the pre-check on the current head. If r4 is held too I park the pose approach.


## 12 Nov, about 18:30 UTC: reworks pushed; ready to re-run

- **SWIM r3 (F39#5):** pushed, CPU-checked (`BELOW6-SWIM/`). Head, shoulders and upper back at the waterline, one arm low and forward. Ready for the GPU pre-check again.
- **STRONGHOLD-STAND (F38#20):** the block now uses **(0, 7130)**. Every stand from z 7210 up crops the keep's top or sits in the trees; at 7130 the whole keep stands against the sky at the end of the road. Ready for the GPU pre-check again.
- **RESTORED-SEA r4 (F39#17):** pushed, **not yet checked on CPU** (the GPU lane offered a 10-minute re-run of all four stands, which is faster than my 22-minute CPU pass). r1-r3 all lowered values that darken low-sun water; r4 widens the shallow colour instead (depth falloff 1.3 of live, waves 0.8, alpha unchanged, debris cleared). Hold it at the pre-check if S4's foreground is darker than base.
- MUSHROOMS and KNIFEEDGE: still no verdict on tb/item-scout-1108.
- New row taken: F41#13 Stormraven (5.97): eyes and lightning-line feather edges; next build.


## 12 Nov, 16:45 UTC: three arms being reworked; do not judge them until the next NOTE entry

- **RESTORED-SEA (F39#17): SPLIT** (G-below6-restored-sea: S1/S2 row 6.21 -> 6.88, 3/3; S3/S4 6.61 -> 6.17, 0/3: the sunset foreground goes near-black and the day turquoise thins). Cause: I set an absolute depth falloff of 2.2 against a live profile of 16 or more, which shrinks the shallow colour to rings. r2/r3 keep the live colours and scale falloff and waves from the live values (`water_scale`); r3 (falloff 0.8 of live) is capturing on CPU now.
- **SWIM (F39#5): held by the GPU pre-check** (the body floats on the GPU's transparent water and the raised arm reads as a wave). r3 is pushed: chest 0.07 m under the surface, flatter body, narrower arms, the recovering arm low. CPU recapture queued.
- **STRONGHOLD-STAND (F38#20): held by the GPU pre-check** (the keep's top is cropped at z 7405). Screening z 7385, 7365 and (-18, 7350) on CPU now; I will move the block to the first one with sky above the battlements.
- MUSHROOMS and KNIFEEDGE: still no verdict.


## 12 Nov, about 18:00 UTC: BELOW6-RESTORED-SEA ready (F39#17, my top row); queue order

- **F39#17 current restoration (5.50): arm built and proven on CPU.** `ralph/reports/LANES/BELOW6-RESTORED-SEA/`. Flag `water_current_flow_visual.json restored_sea_1112` (OFF). While `water_currents_restored` is set the sea takes a restored look (calmer surface, clearer shallows showing the shoals) and the drifting debris leaves the lanes; it reads the existing replicated fact, nothing else changes. Live against restored at one camera: mean difference 2.4 -> 10.0 on CPU.
- **Coordinator, my queue order once a slot frees (MUSHROOMS and KNIFEEDGE still hold both):** 1. BELOW6-RESTORED-SEA (F39#17, 5.50), 2. BELOW6-SWIM (F39#5, 5.64), 3. BELOW6-STRONGHOLD-STAND (F38#20, needs your stand review). If you would rather swap one of these ahead of MUSHROOMS (a 6-7 row now), do.
- Parked on my side: F40#1 (terraces not sent), F41#8 character side, Fulgocobra, F39#8.


## 12 Nov, about 16:40 UTC: F38#20 stand proposal; two arms ready behind the queue

- **F38#20 stronghold (5.72): stand proposal for your review, coordinator.** `ralph/reports/LANES/BELOW6-STRONGHOLD-STAND/PROPOSAL.md`. The Band 5 approach stand is 590 m from the keep, so the row's two approach frames show a speck (a black cut-out at night). A switched-off candidate stand 130 m from the gate shows the keep, towers, gate ramp and lit windows. `approach_override_for` now reads any enabled `candidates_*` block. The courtyard frame is untouched.
- **Ready and waiting for a slot, in this order:** BELOW6-SWIM (F39#5), then the stronghold stand if you approve it.
- **In flight:** MUSHROOMS, KNIFEEDGE. No verdicts yet.


## 12 Nov, about 15:45 UTC: BELOW6-SWIM ready; waiting for a GPU slot

- **F39#5 swimmer (5.64): arm built and proven on CPU.** `ralph/reports/LANES/BELOW6-SWIM/` (ARM.md, CAPTURE.json, overlay.json, sheet). Flag `human_swim_visual.json surface_crawl_1112` (OFF). Cause: the active stroke candidates sink the chest 0.14 m under the surface with the arms below the body. The arm puts the chest at the surface and lifts the recovering arm out of the water.
- **Coordinator:** MUSHROOMS and KNIFEEDGE still hold my two slots. Queue BELOW6-SWIM as soon as one of them comes back (or now, if you would rather swap it ahead of MUSHROOMS, which is a 6-7 row).
- Next on CPU: F38#20 stronghold (5.72).


## 12 Nov, about 14:40 UTC: F40#1 terraces not sent; five new below-6 rows taken

- **F40#1:** `BELOW6-TERRACES/NOT-SENT.md`. Low terraces from the world's own `_mesa` builder (flag `terrace_mesas_1112`, OFF) went three CPU rounds and end as plain pale-grey drums without strata; I expect level or worse, so it is not queued. Parked on my side until there is a new idea (terrace geometry inside `_mesa`).
- **New rows from G-rescore-stale-tier2 (coordinator, 13:21):** F39#5 swimmer pose (5.64), F38#20 stronghold (5.72), F38#12 harvest rewards (5.89), F40#15 (5.89; the strips are FIXED on its own frames, the rest is the cobble wall and lawn), F41#18 (left to LANE-THINGS' STORMUNIFORM). Next for me, worst-first: F39#5, then F38#20.
- **In flight:** MUSHROOMS, KNIFEEDGE (2 of 2). No verdicts yet.
- A capture of mine died after one frame at about 13:45 with no error in its log; the rerun completed. If the GPU machine or another lane saw a kill at that time, it was not a script error.


## 12 Nov, about 12:55 UTC: owner directions taken (below-6 only; no 0.5 threshold)

- **My rows now:** F41#8 (5.80), F36#46 Fulgocobra (5.87), F40#1 (5.90, back from LANE-PLACES), F39#8 (parked). F38#6, #12 and #14 are LANE-THINGS'.
- **Hesk portrait:** main (c73dcc80) already carries the `plates_by_profile` fix and its test, so no landing is needed. Ignore `tb/below6-hesk-portrait` and `tb/below6-hesk-portrait-2` (the second differs from main only by its READY file; I cut it before checking). Both can be deleted.
- **In flight:** MUSHROOMS and KNIFEEDGE (2 of 2). I will cut a landing for each one that ships.
- **Not shipped under the new rule either:** NAMEDFACES was level (row 5.57 -> 5.57, dialogue +0.04 with 1/3 preferring), so it does not pass the ship rule.

**For LANE-THINGS (F38#6, #12, #14; CPU looks on main, 12 Nov):**
- F38#14: main shows no magenta. The ring is a thin teal circle and the authored capture orb is already on (`camfx.json catch_orb`). In frames 02-05 the orb is small against the creatures and the "broke free / So close" banner sits on every frame, including orb-in-flight and strike. `phase2_capture_catch.gd` only accepts an output under `res://ralph/reports/VISUAL/phase2/<biome>/`.
- F38#6 / F38#12: the Meshy props already differ in silhouette (wrapped candy, potion in a basket, sack on cloth, orb basket, travel pack). The weak one is the `attack_tonic` harvest: a small teal bottle with a glow, about a quarter of the candy's size. `item_identity_props.json` (OFF) lists one authored prop per item family.
- I built nothing on these rows.


## 12 Nov, 12:20 UTC: merged main b3dc2139; overlap with LANE-THINGS on the pickup rows

- `tb/below6` has main b3dc2139 merged (conflicts were the coordinator's own cuts of F40#3 and STORMDECK; main's side taken; 69 lane tests pass).
- MUSHROOMS and KNIFEEDGE: no verdict yet.
- **Overlap, coordinator please decide:** G-things-toys-ui shows LANE-THINGS already working F38#6 (Meadows pickups, tone-down lost -0.84: "small blobs that are hard to identify"), F40#16 (mushroom tone-down level at 5.76) and the catch card (F40#13 shipped). So F38#6, F38#12 and F38#14 look like LANE-THINGS' ground; I will not build on them unless you say so. My MUSHROOMS arm is a different idea from their tone-down (new silhouettes per type, not a smaller cap), but their result is a warning for it: if the judges call the Speed patch too small, the next step is a larger patch (`height_scale` up), not parking.
- With both GPU slots in use and those rows in question, I have nothing else assigned that I can build without duplicating another lane.


## 12 Nov, about 11:10 UTC: F38#14 catch effect, CPU look on main

The recorded defect ("dominant saturated magenta ground ring and flat bright orb") is not what main shows now. In the five catch frames (02 orb in flight to 05 orb shakes) the ring is a thin teal circle and there is no magenta anywhere. What I see instead: the orb is a small grey puff that is hard to find against the creatures, and the "Bramblebun broke free / So close" banner sits at the top of every frame, including the orb-in-flight and strike frames it does not belong to (the F40#13 stale-message item, or the capture's staging). I am waiting for the coordinator's GPU re-score text before building anything here: without the judges' current words a change would be a guess.


## 12 Nov, about 10:45 UTC: BELOW6-KNIFEEDGE sent (GPU slots 2 of 2: MUSHROOMS, KNIFEEDGE)

- **F40#15 black strip: cause found and fixed behind a flag.** It is the end face of the route shoulder `BrokenCausewayMainCliffShoulders/Ridge000`, hanging from a straight line between the row's two outer vertices and so standing up to 0.8 m above the pad crown as a zero-thickness black wall. `cloudreach_visual.json landmass.end_face_follows_row_1112` (OFF) makes every shoulder end face follow its row; render only, collider unchanged. On CPU the strip is gone in the day bridge frame. Folder: `ralph/reports/LANES/BELOW6-KNIFEEDGE/`.
- Coordinator: this and BELOW6-MUSHROOMS can be judged as one Cloudreach batch as you suggested. The two overlays touch different files.
- Also seen in the same frame, not touched: the anchor pylon behind the trainer reads as a white pencil with a gold cone (`CloudreachChapter/lower_west/tether_pylon`).
- Next while these wait: F38#14 catch effect (CPU look first).


## 12 Nov, about 10:10 UTC: new rows taken; BELOW6-MUSHROOMS sent (GPU slot 1 of 2)

Coordinator's new rows (09:14): F40#15, F40#17, F38#14, F38#6, F38#12. Stormursa is not recoloured.

- **F40#17 and F40#15 on main:** both placement defects were already fixed by NEAR6-CR (`rim_pickup_in_view`, `rim_pickup_cluster` ON; F40#15 FIXED 2 of 3). The 8-9 Nov GPU write-up (F-cloudreach) says what now holds F40#16/#17 is "oversized and toy-saturated" caps, and for F40#15 a dark straight strip in the F40#8 bridge frames (next for me).
- **BELOW6-MUSHROOMS is ready for the GPU queue**: `ralph/reports/LANES/BELOW6-MUSHROOMS/`. Flag `mushroom_pickup_variants.json natural_cluster_1112` (OFF): each mushroom find becomes a small patch of installed mushrooms in a muted colour (Speed slate blue, Stamina ochre, Wild rust-orange shelf fungus). Frames: F40#16 (two inventory frames) and F40#17 (two High Perches rim frames). Shared presentation, so Meadows and Stormwood mushroom finds change too.
- Next: the F40#15 dark strip in the bridge frames (probe `tools/probe_p2049_dark_strips.gd`), then F38#14 catch effect.


## 12 Nov, 09:15 UTC: F41#8 character side is parked; I need a row

- **BELOW6-NAMEDFACES: LEVEL** (G-below6-namedfaces, 244c8064): row 5.57 both sides, dialogue 6.39 -> 6.43. The judges cannot see the tint at these distances. `named_tint_1112` stays OFF.
- With the posts (-0.49) that is two character-side attempts on F41#8 without a gain, so the character side is **parked**. What the judges name first on this row is not mine: the Stormwood ground and grade (crushed black posterised patches, flat lavender sky: LANE-PLACES) and pink bears. Bryn's and Hesk's face textures ("blown out", "blotchy and posterised") would need texture work on the installed bodies; no idea yet that I expect to gain 0.5 on a row where the figures are tiny.
- Still good to land: `tb/below6-hesk-portrait` (ride-along data fix).
- **Coordinator: both my assigned rows are parked (F41#8 character side, F36#46 Fulgocobra). GPU slots used: 0 of 2. Please assign the next below-6 row.** One candidate if nobody owns it: the "pink / salmon bears" the judges name on F41#8 and F41#15. Stormursa is an owner style-bar creature, so I will not recolour it without your say; I can first measure whether the salmon is the coat or the storm grade.
- **Measured (09:20):** it is the coat. Stormursa's live albedo has mean hue 353-12 (red-brown, saturation 0.38-0.39, value 0.35-0.52), so under the lavender storm light it reads salmon. A programmatic hue move to about 25-30 (plain brown bear) with the saturation eased would keep species, silhouette and markings and move it off the red side. It is an owner style-bar creature, so this waits for your word.


## 12 Nov, 08:52 UTC: F41#15 is out of the below-6 tier

G-things-stormpost (tb/item-scout-1108 b3ff7d0d): LANE-THINGS' creature clearance with the stormdeck dressing takes F41#15 5.13 -> 6.97 (+1.84, 3/3). It covers the three STORMDECK flags, so `tb/below6-stormdeck-ride` does not need to ride on its own; the coordinator can drop that branch once the stormpost landing carries the flags. Remaining on the row (tier 7 work): Marrow's hair and the left-edge player bloom to white. If BELOW6-NAMEDFACES wins, `named_tint_1112` can take a `marrow` entry for his hair.


## 12 Nov, 08:45 UTC: landing branch for the Hesk portrait fix

`tb/below6-hesk-portrait` (d7ad322b7, cut from main a4ad0486): the `plates_by_profile` data fix and its test only, READY `STATUS: ride-along`. Batch it with any Stormwood landing. BELOW6-NAMEDFACES is still waiting for its verdict.


## 12 Nov, about 08:30 UTC: named posts dropped; BELOW6-NAMEDFACES sent (GPU slot 1 of 2)

- **Named posts: DO NOT SHIP** (G-below6-namedposts: F41#8 row 5.92 -> 5.43, dialogue 6.38 -> 5.65, 0/3). `named_posts_1112` stays OFF; parked.
- **BELOW6-NAMEDFACES is ready for the GPU queue**: `ralph/reports/LANES/BELOW6-NAMEDFACES/` (ARM.md, CAPTURE.json, overlay.json, CPU sheet). Flag `stormwood_character_presentation.json named_tint_1112` (OFF): Maud, Hesk and Bryn's body albedo is multiplied by a neutral grey so their faces stop clipping to white. On CPU the emission floor and the rim were both ruled out first (no change); with the tint, near-white pixels in the dialogue crops fall by a third to a half and features read.
- **Direct data fix riding along (both sides):** Hesk's dialogue portrait was the dark-haired boy (`villager_male`) because his new alpha_tracker body had no plate. `plates_by_profile` now maps alpha_tracker to the installed `sorrel.png` and lost_traveler to `tobin.png`. Bryn's lines already resolved to his own plate. Coordinator: this fix can land with anything; tests `test_stormwood_distinct_body_portraits.gd`.
- Not mine, named by the judges on F41#8: repeated background sentinels and tan-vest figures (new art), salmon bears and cobalt wolves, hard black path patches, the player's own bloom.


## 12 Nov, about 07:10 UTC: F41#8 arm sent (GPU slot 1 of 2)

**BELOW6-NAMEDPOSTS** is ready for the GPU queue: `ralph/reports/LANES/BELOW6-NAMEDPOSTS/` (ARM.md, CAPTURE.json, overlay.json, CPU sheet). Flag `stormwood_character_presentation.json named_posts_1112` (OFF). One installed storm-lantern post beside Elder Maud, Rodkeeper Hesk and Warden-elect Bryn; on CPU the black road around them becomes a warm pool and their legs separate from the ground. Character side only; the road is untouched. No new assets, 0 Meshy credits.

Nothing else of mine is waiting on the GPU. STORMDECK flags and code are unchanged for LANE-THINGS. Fulgocobra stays parked (no new idea yet).


## RESTARTED (12 Nov 2026, about 04:30 UTC, on the coordinator's relay of the owner's direction). `origin/main` d777b905 is merged into `tb/below6`.

| Row | Arm | Status |
|---|---|---|
| F41#15 / F41#7 Marrow's head | landed | PR #918 (4.55 -> 5.95 on his two frames). |
| F40#3 Cloudreach landmark read | landing | in PR #919 (the coordinator's own cut, same content as `tb/below6-f40-3-land` ca60c3d10, which needs no PR). **Evidence for #919, flags ON, lane checkout with main 3b7d04b5 merged:** `--only=capture_approach_overrides,cloudreach_landmark_crowns,cloudreach_old_wind_observatory_presentation,cloudreach_windscar_beacon_site,cloudreach_friendly_palette,cloudreach_production_integration,cloudreach_counterweight_seal,realm_shell_transition_guard,capture_stand`: 10 test files, 41 tests, 614 assertions, 0 failed. |
| Stormheart banners and split wood | `BELOW6-STORMDRESS` | **judged RIDE-ALONG** (Marrow frames +0.48, split frame +0.47, F41#1 row +0.10; all under 0.5, nothing loses). The aged wood rendered rose-mauve on GPU (hue 332); **retuned and measured** (CPU slab hue 35, saturation 0.39; details at the end of its ARM.md). Check the GPU pixel hue before it rides with the next Stormwood landing. |
| Stormheart dressing (warm deck wood, cloth banners, aged split wood) | ride-along landing | **judged RIDE-ALONG** (G-below6-stormdeck: F41#15 row 4.62 -> 5.10, +0.48, 3/3; split frame +0.40, 3/3; no pink, nothing loses). **Ready-made: `tb/below6-stormdeck-ride`** (cut from main 3b7d04b5; three flags ON with `_why_on`, pin test, 40 tests / 5094 assertions pass). READY there says STATUS: ride-along: batch it with LANE-THINGS' Nysa creature clearance, do not land alone. It carries two unjudged flag-off candidates inside `stormheart_tree.gd` (ramp body, core shader), named in its READY. |
| What is left on those frames after it: the flat lavender grade and sky, the dialogue box over Marrow's lower half | none | not started (the grade overlaps LANE-PLACES' storm-light rows) |
| F36#46 Fulgocobra (5.87) | `BELOW6-FULGOCOBRA` | parked, not sent (`NOT-SENT.md`, with a correction) |
| F40#1 Cloudreach open terrain (5.90) | moved to LANE-PLACES (coordinator, 12 Nov) | findings handed over below ("For LANE-PLACES (F40#1 ...)") |
| F39#8 (5.66) | none | parked |

`origin/main` 3b7d04b5 (#918) is merged into `tb/below6`. One merge commit (fa2766d3, never pushed alone) carried conflict markers in two config files; the next commit took main's versions, and every `data/config` JSON parses.

Merge notes: main's landed versions won every conflict. Kept on top, flag-off: `ramp_body_1112`, `aged_heartwood_1112`, `heartwood_1111.core_v2`, `below6_floor_fulgocobra`, `below6_marrow_self_lit_off`, `identity_floor_1112`, `landmark_crowns_1111`. Dropped: `below6_flinch_abyssal` (lost on GPU). After the merge, `--only=stormheart,creature_coat_flags,creature_clip,character_body_flags,capture_approach_overrides,remakes_floor_landed,below6,texture_import_policy,dark_value_lift`: 20 test files, 60 tests, 1 failed (the broken Fulgocobra path, fixed; `creature_coat_flags` re-run: 6 tests, 0 failed).

---

# Wrap-up of 12 Nov 02:45 UTC (kept for its tables and runbook; superseded by the restart above)

## WRAPPED (12 Nov 2026, about 02:45 UTC, on the owner's wrap-up direction). No new arms. Everything is pushed.

### 1. Ready to land now
| What | Branch | Verdict |
|---|---|---|
| **F41#1 Stormheart approach stand, ON** (capture_stands `approach_overrides`, the `phase2_capture_locations.gd` hook, its test, a TECHNICAL §8.1 bullet; aged heartwood NOT included) | **`tb/below6-stormheart-stand-land`** (2844f884d, cut from origin/main 6eae79177). `ralph/reports/LANES/BELOW6-STORMHEART-STAND-LAND/READY.md`, STATUS: land. 17 tests / 61 assertions pass. | G-below6-stormheart-approach: row 5.10 -> 6.81 (+1.71, 3/3) |

### 2. Already on main or in the coordinator's PRs (nothing to do)
Voltarach and Ribbonray coats (#910); Abyssal matte hide (#911); Stormheart heartwood and Thundertunnel coat (#912); Mirejaw grounded hit (#914, cut by the coordinator). Water Mosshell travel pose was landed by LANE-THINGS.

### 3. Not on main, not judged: built flag-off on `tb/below6`, each needs a GPU verdict before it could land
| Item | Flag (OFF) | Files | State |
|---|---|---|---|
| **F41#15 / F41#7 Captain Marrow's white head** | `character_body_flags.json below6_marrow_self_lit_off`; `stormwood_character_presentation.json identity_floor_1112` | `character_model.gd` (one allowed body-flag key), `stormwood_character_presentation.gd`, `captain_a_lod0_texture_0_floor1.png` + sidecar; `BELOW6-MARROW/` (ARM.md, CAPTURE.json, overlay, two sheets) | **Ready for GPU, never captured there.** The cause is found (he emits his own texture plus a floor from the Stormwood presentation file). CPU: body fixed, face only faintly readable. This is the biggest open gap on the list (4.49) and the one thing here most worth a GPU run. |
| F41#1 split trunk's orange exposed wood | `stormheart_presentation.json split_bark_finish.aged_heartwood_1112` | `stormheart_split_wood.gdshader`, `stormheart_split_bark.gd`; `BELOW6-RAMP/` | CPU-checked; needs one split-facing frame as its own small arm (no judged frame shows the split from the new stand). |
| F41#1 entrance ramp body | `stormheart_presentation.json ramp_body_1112` | `stormheart_tree.gd _ramp_body`, `tests/test_stormheart_ramp_body.gd` | Built and tested; no judged frame shows the ramp. Built on my wrong first diagnosis of the orange slab. |

### 4. Losing or parked experiments (flag-off on `tb/below6`; no landing needed)
- `creature_clip_flags.json below6_flinch_abyssal`: **lost on GPU** (-0.25, 1/3; adds a white block at the front foot in hit 025 and 050). Drop.
- `stormheart_presentation.json heartwood_1111.core_v2` and `stormheart_heartwood_core.gdshader`: parked after three CPU looks (`BELOW6-COREV2/NOT-SENT.md`).
- `creature_coat_flags.json below6_floor_fulgocobra` (+ its texture and the `fulgocobra` grade in `grade_remakes_floor.py`): not sent, no visible change on CPU.
- `cloudreach_visual.json landmark_crowns_1111` (LANE-MESHY's, carried over): not sent, the dome is out of frame or tiny.
- The heartwood's optional axis collider (`body_enabled`, OFF, already on main inside #912): stays off; it breaks the tree's pinned physics tests. A player can walk into the root cage.

### 5. A fix that is on `tb/below6` only and is worth taking with any later landing
None beyond section 3. The lane's copies of `creature_coat_flags.json`, `creature_clip_flags.json` and `tests/test_remakes_floor_landed.gd` were synced to main at 8df122a83 and are now behind main (#911, #912, #914 flipped flags there): **do not land those three files from this branch.**

### 6. Below-6 rows as I leave them
| Row | Score | Where it stands |
|---|---|---|
| F41#15 Marrow's head | 4.49 | arm ready, unjudged (section 3) |
| F40#3 Cloudreach landmark read | 5.65 | crowns not sent; the frames say the row is about framing and bare ground, not what sits on the landmark |
| F39#8 Aquaryn mounted water | 5.66 | parked, no new idea |
| F36#46 Fulgocobra | 5.87 | grade not sent; a rim, not an albedo lift, is the untried idea |
| F40#1 Cloudreach open terrain | 5.90 | nothing built; eight dressing candidates already failed; the untried lever is raising the island crown itself |
| F41#1 Stormheart | 6.81 with the new stand | out of the tier once the stand lands; judges still name the missing crown, decal banners, a black pool with an orange crack line, smooth trunks |
| F36#52 Mirejaw | 6.32 | out of the tier; the snout still renders whitish in hit frames (PARTIAL 3/3), the tail still passes the trainer |
| F36#29 innkeeper | 7.03 | GPU High baseline done; out of the tier |
| F36#88 Water Abyssal Guardian | 6.32 with the stage fix | needs a new mesh |

### 7. Runbook additions from this lane
- **Build the subject through the real path before tuning it.** Marrow's material is built by `decorate -> trainer_npc.model_config -> character_model`; printing that material showed the emission texture and where the floor came from in one headless run, after three GPU arms had changed the wrong file.
- **A CPU frame that reproduces a "glow" rules out bloom.** Then switch one contributor off per capture and measure a face box and a body box.
- **Check that a built fix changes the judged frame before writing it up.** I took the orange slab for the ramp, built a ramp body, and only then saw the frame unchanged.
- **Landing tests catch contract breaks the arm did not:** the heartwood's collider broke the tree's pinned physics; an older test pinned Thundertunnel's replaced texture. Grep `tests/` for the species, flag and texture names before a landing.
- Landing branches without a worktree: `GIT_INDEX_FILE=<tmp> git read-tree <main>`, `git update-index --add --cacheinfo` per file, `write-tree`, `commit-tree`, push the commit to the branch name.
- Outdoor Stormwood frames take about 5 minutes each on CPU, dialogue frames about 10 minutes a launch; screen stands on the GPU with `--spot=<id>@x,z@heading`.
- Never `git add` a glob that can match locally excluded `.uid` files: the add fails and takes the `&&` chain with it.
- **Meshy:** no generations (owner, 11 Nov). Credits spent: 0.

---

# Earlier state (superseded by the wrap-up above)

## State (12 Nov 2026, about 03:30 UTC)
| Row | Arm | Status |
|---|---|---|
| F41#15 (4.49), F41#7 (6.24): Captain Marrow's white head | `BELOW6-MARROW` (two flags, one new texture) | **ready for GPU.** Cause found: he emits his own texture plus a 0.18 floor that comes from `stormwood_character_presentation.json`, which no earlier arm touched. Body fixed on CPU; the face only partly (scene light remains). See ARM.md. |
| F41#1 Stormheart approach frames | `BELOW6-RAMP` (new approach stand from the GPU screen + aged heartwood) | **ready for GPU**, all four frames. Read ARM.md: my first diagnosis (the ramp) was wrong and is corrected there. |
| F36#52 Mirejaw, F36#30 Abyssal Guardian hit reactions | `BELOW6-HITS` | ready for GPU (queued by the coordinator as BELOW6-MIREJAW earlier) |
| F36#29 innkeeper | `BELOW6-INNKEEPER-BASE/CAPTURE.json` | baseline request pushed (one side, main, High) |
| F41#1 heartwood, F36#80 Thundertunnel | landing | PR #912 |
| F36#30 Abyssal matte hide | landing | PR #911 |
| F41#1 core follow-up | `BELOW6-COREV2` | parked, not sent |
| F36#46 Fulgocobra, F40#3 crowns | | not sent (NOT-SENT.md in each folder) |
| F36#88 Water Abyssal Guardian | | material lever spent; needs a new mesh: parked |
| F40#1 Cloudreach open terrain (5.90) | none | nothing built; the untried lever is raising the island crown itself |
| F41#8 (5.31) | `tb/item-f41-8-bodies` | rides with LANE-PLACES' storm-light pass |
| F39#8 (5.66) | | parked |

**For LANE-PLACES (F40#1 moved to you, 12 Nov):** everything I found is in `ralph/reports/LANES/BELOW6-F40-1/` on `tb/below6`: `NOT-SENT.md` (the bank-UV hypothesis: built, captured, no pixel changed, removed; what the brown band at the Realm Gate Crag approach really is: the island's side wall seen by a camera past the rim, player at (-8.2, 150.1, -152.6), camera at (-9.9, 153.0, -157.4)); `_sheet_cpu_bank_uv_no_change.jpg`; `_sheet_cpu_pad_on_vs_off.jpg` (the row's three frames with the stone trail on and off); `overlay_pad_off.json` and the `candidates_off` switch in `cloudreach_f40_items.json` / `cloudreach_settlement_life.gd items_config` (default unchanged), which lets an overlay skip a candidate that ships ON. Six base frames of the row on today's tree are in my scratch only; the capture command is in the NOTE's earlier sections.
**For LANE-PLACES (storm light):** after Marrow's own emission is off, the DynamoCore deck's scene light still clips a pale face on CPU. Captain_b (Nerissa) has the same missing `body_emission_enabled` in `art.json`.
**For LANE-THINGS:** Voltarach's hit is recipe-driven; a clip flag cannot reach it.
**Meshy:** no generations (owner, 11 Nov). Credits spent: 0.

**Lane checkout:** `creature_coat_flags.json`, `creature_clip_flags.json` and `tests/test_remakes_floor_landed.gd` are synced to main 8df122a83 (the #910 flags ON) with this lane's OFF flags appended. The branch is not otherwise merged with main (shallow checkout).


**Left on the two landed rows (judges, arm side):** Voltarach's face is one blue eye spot with no head mass, its hit barely differs from standing, some gold sheen on leg tips. Ribbonray's upright two-legged anatomy is mesh: parked without Meshy unless a pose or rig idea turns up.

The three creature arms are LANE-REMAKES' work carried over unchanged (files taken from `tb/remakes` ac738b144; folders renamed REMAKES-* to BELOW6-*). All flag-off. One import of this branch serves all three (new `*_floor1*.png` textures, different species). I looked at the three CPU sheets: each shows a clear change in the named defect (gold fields to charcoal with thin cracks; magenta to navy with the tail attached in the hit; less saturated navy with a cream belly).

## For the coordinator
- **Voltarach's 5.11 was scored on the 1 Nov remake, which the owner switched off on 9 Nov.** The base capture in `BELOW6-VOLTARACH` re-baselines the native spider that ships.
- **For LANE-THINGS (faint grounding):** Water Mirejaw's 5.52 is the belly-up floating faint only (crimson frills and dark blob both read FIXED 3/3), so that row has no material work left for this lane. LANE-FLOOR2 measured that the existing settle does not reach either water variant (`water_mirejaw`, `water_abyssal_guardian`); its handoff names the early returns in `creature_pose_settle.gd apply` to check first.

## Next for this lane
1. F41#1 Stormheart finale (5.78): crown and glowing core from installed pieces, with LANE-FLOOR2's flag-off mesh lightning (`FLOOR2-STORMBOLT`) as a rider.
2. F40#3 Cloudreach landmark read (5.65) and F40#1 Realm Gate Crag approach landform (5.90).
3. F41#8: `tb/item-f41-8-bodies` (5.72) goes to LANE-PLACES with their storm-light pass when they ask.
4. F39#8 stays parked (no new idea yet).
