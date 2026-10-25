# Tidewake close-1024 (lane tb/tidewake)

Rows: F13#5 (failing), F39#1, #2, #3, #5. Previous note: `../close-1022/NOTES.md`.

## TO COORDINATOR

- 2026-10-25 03:00 CT **READY: `tb/tidewake-land` at a6bbba553** (a6bbba553e87bd5d22a964202a6977ae7e87e99b). The fight HUD prompt-yield fix only (one cherry-picked commit on origin/main 124a7393c).
  - **Files:** `scripts/ui/playground_hud.gd` and `tests/smoke_fight_world_prompt_yield.gd`.
  - **Checks there:** HUD and prompt tests, 90 tests and 560 assertions, 0 failed. `smoke_fight_world_prompt_yield` passed.
  - **Not included:** the heightfield relief and every other OFF candidate.

- 2026-10-25 02:40 CT **READY (functional fix, worst-first on the sub-6 Venn fight): the fight HUD overlap, `tb/tidewake` fe26613a5.**
  - **The defect:** "E Gather Reef Stone" drew over "C Switch / Esc Flee" in every Venn fight frame. Every Tidewake fight judge since mx1 has flagged it.
  - **Why the earlier fix missed it:** 5fb669d7b hid the world prompt only while the legacy `_grid_panel` showed. The F42 system overlay hides that grid and draws the command strip itself.
  - **Fix:** the prompt now also yields while the overlay shows, except in a relay phase.
  - **Test:** `smoke_fight_world_prompt_yield` now covers the overlay path. It fails without the fix and passes with it.
  - **Checks:** HUD and prompt tests, 90 tests and 560 assertions, 0 failed.
  - **Landing:** this touches `scripts/ui/playground_hud.gd` (the UI lane's file), so it is a small cross-lane fix. Land it with my next head, or hand it to the UI lane, whichever you prefer.

- 2026-10-26 00:20 CT **WITHDRAWN: the 22:40 Veilfall crown READY (nv1/VERDICT.md).**
  - **Result:** on the reframed 750 m vista stand (your rule, both arms re-captured), shipping 4.75 vs crown 4.51, lower x2.
  - **Why:** mt1's win came from the old stand cropping the summit. With the whole island in frame, the small crown on a smooth cone reads as a placeholder next to shipping's broad main fall.
  - **State:** the crown stays OFF. The cap, its tests and its bake stay in the tree, OFF.
  - **Single READY head for the Veilfall row** on the new stand: T1e + `veilfall_falls_candidate` + `rain_fog_candidate`.
    - Please re-take the GPU Veilfall baseline on the new stand.
  - **Next idea:** carry the crown family down the face (terraced relief plus the main fall on the capped face). I'll report before building it.

- 2026-10-26 12:00 CT **INFO: the Veilfall face (fc1/VERDICT.md) is parked after three attempts that did not beat shipping on the 750 m stand.**
  - **Terraces:** they banded into sand stripes, so they are back to off and rebaked.
  - **Falls:** they are hidden under the crown's base.
  - **Options:**
    1. A terrain material pass so ledges get rock and grass instead of sand.
    2. A narrower crown so the falls show.
    3. A full-mountain Meshy asset instead of a crown. If you want this one, I can draft the request.
  - **Veilfall READY head is unchanged:** T1e + falls f2 + rain fog.

- 2026-10-26 10:10 CT **READY update: P2-011 destination landmarks s2 (lm2/VERDICT.md) replaces the lm1 numbers.**
  - **Change:** the jetty moved to the shoreline, and both are 13 m.
  - **CPU mapped, reframed P2-011 stand:** 5.36 → **6.81** (+1.45). All three judges higher.

- 2026-10-25 23:30 CT **READY for the GPU lane: P2-011 destination landmarks (lm1/VERDICT.md).**
  - **Change:** `destination_landmarks_candidate` places MESHY 11-12, the twin pumps and the rescue jetty.
  - **CPU mapped:** 4.33 → **5.58** (+1.25). All three judges higher.
  - **Capture:** `P2-011-destinations.json` (new), shipping vs `--tidewake-look-sections=destination_landmarks_candidate`.
  - **Known:** both are small and sit away from the water. Re-seating at the shoreline is next.

- 2026-10-25 22:40 CT **READY for the GPU lane: Veilfall crown + summit cap (mt1/VERDICT.md), `tb/tidewake` 42300a3af.**
  - **Built:** the cap is built as you approved, OFF until judged.
    - Walk band, anchors and gate are proved unchanged.
    - The cap's knee is 210 m, above the 196.9 m maximum walk.
    - Crown collision follows the drawn mesh (test). The terrain collision matches the capped bake.
    - The new key carries `scope` and `_why`.
  - **CPU mapped, veilfall-vista:** shipping 3.52 → **4.64**. That is +0.50 over T1e + falls. All three judges higher.
  - **Caveat:** the vista crops the crown, so judges mostly scored the smoother lower island. It is still under the 5.2 floor.
  - **QUESTION:** may I pitch the vista stand up so the whole landmark is in frame (the judges' ask)? It is a yardstick change.
  - **Dropped:** the two HUD READY entries (landed in #734).

- 2026-10-25 20:30 CT **INFO + QUESTION (MESHY 10-12 received, thank you).**
  - **Integration:** all three are in `tb/tidewake` flag-OFF. Textures are on mode 2 (policy check PASS on 9 sidecars) and the import is clean.
  - **`veilfall_terraced_mountain`:** placed as `veilfall_mountain_candidate`. The landmark loader gained an optional `stretch_xz`.
    - The crown cannot read as a render shell over the shipped terrain. Five far and vista probes showed why:
      1. At 1.4x it is buried by the render-only crag heap. The candidate now hides that heap while ON.
      2. With the heap hidden, it is buried by the 620 m terrain cone itself.
      3. Widened to 2.0x on a ~200 m base, it shows as a floating collar with the smooth summit poking through.
  - **QUESTION:** the fix is to cap the Veilfall terrain cone below the crown, above every walkable height, so the crown replaces the summit.
    - This uses the same masked heightfield mechanism as hf1 (`veilfall_relief`) and needs a rebake of the six Veilfall regions.
    - Walk band, anchors and gate would be proved unchanged, as in hf1.
    - Shall I build it? It is a terrain change.
  - **Twin pumps and rescue jetty:** imported, not yet placed. Each destination stand needs a placement probe first.
  - **Two rounds level, both OFF:**
    - `dune_grass_candidate` (the probe proved the tufts are the ground-cover grass field; random keep in colonies);
    - `shore_water_candidate` (shipping colours, softer step). See gw1/VERDICT.md.

- 2026-10-25 18:10 CT **READY addendum (rf1/VERDICT.md): `rain_fog_candidate`.**
  - **What it does:** Tidewake-only rain mist at 0.35 of the shared preset.
  - **CPU mapped, rain views:** 5.67 → **6.18**. All three judges higher. The fog-flattening defect is FIXED x3.
  - **Trade-off:** rain now reads only through streaks. A darker overcast grade is next.
  - **Overcast grade (rg1):** a darker sky, dimmer sun and ambient was level (6.36 vs 6.29), so it stays OFF. Making rain read needs wet sand and sea ripples, a material job.

- 2026-10-25 16:40 CT **STATUS against the 5.2 CPU floor (coordinator 25 Oct), plus READY addenda.**
  - **Currents:** T1e. Swim views 5.77, Deep Watch 6.09. Above the floor. READY.
  - **Shore:** T1e plus the surf line, 6.67 (vary 6.86). Above the floor. READY. Declutter D is READY separately.
  - **Deep Watch landforms:** T1e plus the surf line, 5.89 (vary 6.18). Above the floor. READY.
  - **Veilfall vista (vv1, vf4):** shipping 3.92 → T1e 5.06 (vv1).
    - **READY addendum: f2 `veilfall_falls_candidate`,** another +0.36 in a matched batch (vf4).
    - **The Meshy hero pieces** (cascade tier, plunge rocks, facade) lower the vista to 4.82, so they stay OFF.
    - **The rest is new art:** the mountain (MESHY 10). Please generate it when you can.
  - **Venn fight:** Fights PR #738. Not mine.

- 2026-10-25 13:30 CT **INFO (T4 beach grass): `dune_grass_candidate` reverted, not judged.**
  - **Tried:** fewer shore pioneers and tighter colonies in `water_ground_cover`.
  - **Result:** no visible change at Deep Watch. The even tufts there come from another layer.
  - **Plan:** the clump fix needs the layer that places those tufts found first.
  - **14:10 update:** a second try (`dune_groundcover_candidate`: fewer, denser Grass_Wispy_Tall clusters) also made no visible change, so it is reverted too.
  - **Re-scoped:** that's two candidates with no visible effect on the beach tufts. The beach-clump item is parked until the placing layer is identified with a toggle-off probe. Not guessing further.
  - **State of `tb/tidewake`:** head carries only judged candidates, T1e and T4 plus vary, all OFF in play.

- 2026-10-25 12:40 CT **READY addendum (t4c/VERDICT.md): optional `shore_surf_vary_candidate` on top of T4.**
  - **CPU mapped:** shore 6.63 → 6.86, Deep Watch 6.04 → 6.18. A small gain, every judge +0.1 to +0.2.
  - **Capture:** add it to the T4 section list.
  - **Grouped stones:** level to slightly lower, stays OFF.

- 2026-10-25 10:30 CT **READY for the GPU lane: T4 surf line, `tb/tidewake` 510f05426 (t4/VERDICT.md).**
  - **CPU mapped, on top of T1e in both arms:** shore views 6.10 → **6.67**, Deep Watch 5.37 → **5.89**. All three judges higher; r 0.993.
  - **Change:** a new optional water-shader surf band. It is 0 for every realm, so shipping is unchanged.
  - **Capture:** commands in the verdict, with `--tidewake-look-sections=current_flow,shore_surf_candidate`.

- 2026-10-25 08:10 CT **READY addendum (T1e also lifts Deep Watch landforms, dw1/VERDICT.md).**
  - The Deep Watch bay carries the same road markings (glowing at 23:00).
  - **CPU mapped:** shipping 5.46 → **T1e 6.09** (+0.63, all three judges higher).
  - **Please add to the T1e GPU run:** `P2-008-shore.json`, without and with `--tidewake-look-sections=current_flow`.

- 2026-10-25 07:20 CT **INFO (T1 parked at T1e): `tb/tidewake` head keeps the judged T1e candidate.**
  - **T1f made no visible change:** a deeper channel tint (0.22) and a lane sheen (new optional `lane_glint` uniform, inert at 0) barely showed in the captures. Not judged, config reverted.
  - **Two night-read attempts both made no visible difference:** `moon_glint`, then `lane_glint`. Per the two-attempt rule the night read changes approach, so T1 stops at T1e.
  - **T1e stays READY** (06:40 line).

- 2026-10-25 06:40 CT **READY for the GPU lane, replacing the 03:40 T1 line: T1e currents, `tb/tidewake` 63aeaefe6 (t1e/VERDICT.md).**
  - **CPU mapped, same batch as T1:** swim views T1 5.25 → **T1e 5.77** (+0.52), shore views 6.54 → 6.66. All three judges higher. The loud yellow pennants are FIXED.
  - **Capture:** same commands as `t1/VERDICT.md`, with `--tidewake-look-sections=current_flow`.
  - **Known gaps:** direction and the night read got weaker. That's the next round.
  - **INFO:** the water-colour route (T2, T2b) lost twice and is parked. Verdicts in `t2/` and `t2b/`.

- 2026-10-25 04:20 CT **MESHY: requests 10-12 (`meshy-requests.md`, third batch; inputs under `assets/props/meshy-1025/<name>/reference/`).**
  - **10, `veilfall_terraced_mountain` (P2-010):** 520 x 360 m render-only shell over the upper cone, from the board's exterior view. Scale check and placement are included.
    - The re-seated `veilfall-vista` views show the mountain as a heap of blocky crag pieces over a smooth cone, which scene work cannot turn into the terraced green cliff mountain.
  - **11, `tidewake_sluice_twin_pumps`, and 12, `tidewake_shellwatch_rescue_jetty` (P2-011):** destination landmarks for the two stands that still read as generic structures.
  - **Integration:** this lane integrates each result flag-OFF and judges it against shipping.
- 2026-10-25 04:20 CT **INFO (T3): re-seated Veilfall views are on `tb/tidewake` in F39-look.json.**
  - `veilfall-vista` and `veilfall-vista-rain` sit 200 m offshore of the landing stand, looking back at the mountain, the falls and the sea.
  - Please use them for the Veilfall row from now on. `veilfall-near` and `veilfall-rain` are unchanged, so the queued close-up comparisons (hf1, rock) still match.
  - Shipping and T1+T2 vista captures are running here.

- 2026-10-25 03:40 CT **READY for the GPU lane: T1 currents flow foam (P2-066), `tb/tidewake` 131b098c9 (t1/VERDICT.md).**
  - **CPU mapped:** currents swim views 3.66 → **5.92** (+2.26), shore views 5.87 → **6.64**. All three judges higher on both; road markings FIXED x3 on the swim views; r 0.961.
  - **Capture:** T2-current.json, plus F39-look.json `--views=shore-day,lesson-dune`. Each with and without `--tidewake-look-sections=current_flow`, at Medium and High (commands in the verdict).
  - **Still OFF in play** until the GPU passes it.
  - **Next:** night lane visibility, and quieter buoy pennants.

- 2026-10-25 02:00 CT **READY for the GPU lane: the Tidewake F39 matrix baseline (owner: worst-first to 6, then 7, then 7.5).**
  - **Capture:** at main (124a7393c or later), once at Medium and once at High, each command with `--capture-size=1920x1080 --preset=<Medium|High> --source-sha=<main sha>`:
    1. Look and weather, all nine stands: `tools/capture_tidewake_f13_5.gd --camera-set=res://tools/visual_judge/camera_sets/F39-look.json`.
       - First Shore at 12:00, 18:00, 23:00 and in rain.
       - The swim-lesson dune at 12:00, 05:00 and in rain.
       - The Veilfall close-up, clear and in rain.
    2. Currents and docks, the F13#5 stands: `tools/capture_tidewake_f13_5.gd --camera-set=res://tools/visual_judge/camera_sets/T2-current.json`.
    3. Shore landforms: `tools/capture_tidewake_f13_5.gd --camera-set=res://tools/visual_judge/camera_sets/P2-008-shore.json` (Deep Watch day and night).
    4. A real fight: `tools/phase2_capture_tidewake_fights.gd --trainer=water_trainer_venn --seed=2042 --expected-resolution=1920x1080`.
       - The output must be a fresh `res://ralph/reports/VISUAL/phase2/tidewake/<dir>`.
       - Judge four matched-moment state frames: tell-start 0.65, hit 0.70, hit 1.08 and tell-ended 1.32 s, which all seeded runs share.
  - **Known sub-6 on CPU:** the Veilfall close-up (4.2-4.4, with the heightfield relief F queued) and the Venn fight (5.4-5.7).
  - **Still queued:** declutter D and the Forward+ fixes.

- 2026-10-25 01:30 CT **READY for the GPU lane: F39#4 heightfield relief (hf1/VERDICT.md), `tb/tidewake` 2ea20e386.**
  - **CPU-visible:** close-up 4.39 against 4.17, matched Venn fight 5.72 against 5.36 (both all three judges higher), shore views level. The fight's black slab moved from PRESENT to PARTIAL.
  - **Gameplay:** the hike's walk band is byte-identical with the relief on and off (new `test_water_veilfall_relief_walk`). The route-grade audit is identical. Anchors and gate are unchanged.
  - **Bake:** only the six Veilfall terrain regions changed (3.8 MB).
  - **Capture command:** in the verdict.
  - **Not in any land head until GPU passes.**

- 2026-10-25 00:20 CT **READY for the GPU lane: F39#4 relief, two arms, on `tb/tidewake` dba5f5e8a.**
  - **Command:** `capture_tidewake_f13_5.gd --camera-set=res://tools/visual_judge/camera_sets/F39-look.json --views=veilfall-near,veilfall-rain`, on Medium and High.
  - **Control:** no `--tidewake-look-sections`.
  - **Arm 1:** `--tidewake-look-sections=veilfall_formation_relief_candidate`.
  - **Arm 2:** `--tidewake-look-sections=veilfall_formation_relief_fill_candidate` (judge it alone).
  - **Both arms are verified live in game:** each gate crag renders about 10k relief vertices instead of the coarse ~190, and arm 2's crag material carries the 0.14 fill. The inside-the-collider test covers both amplitudes.
  - **Plainly, though:** on CPU neither arm changes the veilfall-near frame (pixel diff at noise level).
    - The crags sit mostly behind or inside the terrain from that stand.
    - The huge dark faceted planes that fill the frame are Terrain3D, per the raycast probe: the hike's graded corridor and the steep cone flanks.
    - So the GPU arms may show little. The heightfield is the real target, as you said. I'm on it next, under the hike walk and route constraints.

- 2026-10-24 23:50 CT **INFO / QUESTION: F39#4 relief pass, the first result.**
  - **Why not the heightfield:** the Veilfall base terrain is a smooth analytic cone. The faceted "slabs" are:
    - (a) the `exterior_composition` gate crags: 9 segments x 4 rings, 34-76 m tall;
    - (b) the hike's trail-grading cut, which is the central ramp.

    Re-baking the heightfield would move the hike itself.
  - **What I built instead** (on the lane, OFF as `veilfall_formation_relief_candidate`):
    - a render-only relief mesh on the crags: faces subdivided 6x and pushed inward up to 1.6 m by noise plus bedding;
    - collision is still the coarse trimesh, so the hike and route clearances cannot change;
    - a test proves every relief point stays inside the collider shell (`test_crag_relief_stays_inside_the_coarse_shell`).
  - **CPU result: no visible change** (about 30k pixels, capture-noise level). The crag faces in the veilfall-near frame are in full shadow. On Compatibility there is no SSAO and the ambient is flat, so the varied normals do not shade.
  - **My read:** the "near-black faceted slab" is mainly the unlit shadow side of the crags, not their geometry.
  - **QUESTION:** do you want me to:
    - (1) try the relief at a larger amplitude plus a shadow-side fill (a local ambient lift on the crag material, which would change the look, not the geometry); or
    - (2) queue the relief for the GPU lane as it stands? Forward+ SSAO/SSIL would show the relief where CPU cannot.

- 2026-10-24 23:30 CT **READY for the GPU lane (dc1/VERDICT.md): First Shore declutter.**
  - **CPU pre-judge:** 5.77 against shipping 5.25, all three judges higher. "Cluttered" moved from PRESENT to PARTIAL or FIXED.
  - **Candidate:** the two OFF sections `stones_candidate` and `first_shore_declutter_candidate`.
  - **Capture command:** in the verdict, on `tb/tidewake` 57acc2c0a or later.
  - **Next:** the owner's water point, then the formation relief (F39#4). The relief code and its inside-the-collider test are on the lane, OFF.

- 2026-10-24 22:30 CT **INFO / QUESTION (rd1/VERDICT.md): F39#4's material route is exhausted; what remains is geometry.**
  - **Result:** the material-only gully fix (finer texture, short runnels, tighter bedding) loses the CPU pre-judge: close-up 3.94 against 4.34, all three judges lower. Shore and fight were also slightly lower. It stays OFF.
  - **Why:** the judges read shipping's long runnels as welcome "wet-streak detail". The "stretched slab" they name is the few huge faceted terrain faces themselves.
  - **QUESTION:** do you want either:
    - (1) a heightfield relief pass on the gully (a terrain bake on the hike: route and walk check plus earned-save pieces), or
    - (2) a Meshy slab-wall fitted to these exact faces?
- 2026-10-24 22:30 CT INFO: **owner declutter.**
  - **Candidate:** `first_shore_declutter_candidate` (OFF) drops the three First Shore p1 props by id (ids added to the shipped props). `stones_candidate` (OFF) is thinned to 0.2, grouped, with a soft tide band.
  - **Confirmed:** the beach "dot field" is the stone tier. With it off, the sand reads clean.
  - **Next:** the First Shore and lesson views are capturing for a CPU pre-judge, then READY for the GPU lane.

- 2026-10-24 21:00 CT **READY for the GPU lane: the Forward+ night-shadow and noon-seam fixes are staged OFF on `tb/tidewake` 3d0de8a9c.** This container has no Vulkan, so I could not render or verify them.
  - **Mechanism:** in `world_look.gd`, a key named `<key>_forward_plus` replaces `<key>` only on Forward+/Mobile. Compatibility is unchanged, with a test.
  - **Section:** `forward_plus_candidate`.
  - **Noon:** horizon haze 0.46/0.17 -> 0.62/0.22, to answer the Forward+ grade halving fog density.
  - **Night:** moon key 0.95 -> 1.35, ambient 0.26 -> 0.16, sky contribution 0.2 -> 0.08.
  - **Blending:** golden and dawn carry their own base values, so keyframe blending stays exact.
  - **Capture with:** `--tidewake-look-sections=forward_plus_candidate` on Medium/High.
  - **Rule:** please judge it against main and ship it if it beats.

- 2026-10-24 20:40 CT **INFO / QUESTION (vf3/VERDICT.md): the facade is level, so it stays OFF.**
  - **Scores:** close-up 4.59 against 4.56; matched fight 4.98 against 4.98.
  - **Judges' read:** a small tile pasted mid-slab at an odd angle. They unanimously name the giant stretched faceted terrain slabs and the wall-facing camera as the real fault.
  - **The F39#4 close-up now sits at 4.56 shipping,** after limestone and the rock family.
  - **QUESTION:** next step for F39#4, either:
    - (a) reshape or retexture the Veilfall terrain in that gully (gameplay terrain; needs a route and walk check); or
    - (b) reframe the `veilfall-near` stand toward the falls and water (that changes the yardstick, so it is your call).
  - Meanwhile I'm on your GPU asks: night shadow on Forward+ and the noon seam.

- 2026-10-24 20:10 CT **READY: `tb/tidewake-land` at 3e852e6be** (3e852e6be33f98ec068b3122efa75a199d99dc1a), one commit on origin/main d71bd31f6 (#728).
  - **ON:** `veilfall_family_candidate` (rf1: close-up 4.51 against 3.90, shore level, matched fight 5.01 against 4.85).
  - **Lane fixes:**
    - `test_veilfall_hero_pieces_stay_clear_of_the_hike`;
    - the `lift_m` key with its indent fix;
    - the vf2 re-placement off the hike (OFF);
    - the vf3 facade staged (OFF);
    - the facade request inputs under `assets/props/meshy-1025/veilfall_cliff_facade/reference/`.
  - **No Meshy GLBs** are in the land.
  - **Checks:** tidewake look, model preload, material family, dune cover and groves, and the five Veilfall test files: 36 tests, 2827 assertions, 0 failed.
  - **vf3** is being judged now, for a later land.

- 2026-10-24 19:20 CT **INFO (rf1/VERDICT.md): one rock family ships ON at `tb/tidewake` deb793527.** Every view it changes was judged; confirming batch, no extrapolation.
  - **Close-up:** 4.51 against 3.90, all three judges higher.
  - **Shore views:** 6.08 against 6.08, level.
  - **Matched fight:** 5.01 against 4.85.
  - The fight's top-right "black slab" is untouched by it. It isn't the kitbash or the formations; next I'll identify which piece it is.
  - **vf3** (the facade, lifted 14 m and facing the stand, 35.8 m off the hike) is capturing for its close-up and matched-fight round.
  - **After vf3**, your GPU asks: night shadow on Forward+ and the noon seam.

- 2026-10-24 18:15 CT **MESHY: `assets/props/meshy-1025/veilfall_cliff_facade/reference/`, 35 m wide x 30 m tall x 6 m deep (flat back), a slope-hugging Veilfall gully-wall cliff facade with a 2-3 tier white falls.**
  - **Placement:** flush on the west gully wall at (338.0, 3836.0), normal (0.902, -0.431), yaw 115.5. Clearance from the hike: 35.8 m at the centre, 24.8 m minimum at the front face.
  - **Inputs:** board crops (text, figures and structures removed), stone swatches, `prompt.txt`, `scale_check.png` (about 17x the 1.80 m trainer) and `placement.md`.
  - **Gate:** OFF until judged.

- 2026-10-24 17:55 CT **PARKED, with a MESHY suggestion: vf2 placement.** Off the hike, the veilfall-near slope is too steep for the cascade tier.
  - **Why it fails:** at 15 m or more from the trail, the tiers bury into the slope, and only their crowns show as pale lumps. Lifting them floats their downhill fronts toward the camera, which judges already called "pasted, floating".
  - **What it showed:** the only spot where the tier read (the close-up gain) was the trail itself, the gully floor.
  - **My call:** park vf2 OFF. Keep the GLBs on the lane and the config placement with its clearance test.
  - **The real fit is a slope-hugging asset,** not a free-standing tier. MESHY suggestion:
    - **What:** a 30-40 m wide stratified limestone cliff face with a 2-3 tier white falls.
    - **Form:** made as a thin, back-flat facade (about 6 m deep) to sit flush against the west gully wall, off the trail, like a skin over the existing slope.
    - **References:** the c2 cascade-tier concepts plus the board's exterior crop under `assets/props/meshy-1025/veilfall_cascade_tier/reference/`.
    - **Scale:** about 30 m tall against the 1.80 m trainer (about 17x).
  - **Your call:** should I draft the reference and scale check?

- 2026-10-24 17:30 CT **INFO: vf2's matched-moment fight is level (vfm: 3.56 against 3.64), but vf2 is withdrawn because it sat on the hike.**
  - **The problem:** the `veilfall_exploration_spine` (4 m, main path to the gate) runs up the gully floor I had placed in.
    - The plunge ring, which has a collider, sat 6.5 m from the trail centreline. The lower tier sat 8.4 m away.
    - My raycast probe read the graded trail as cliff.
  - **The fix:** every piece is now 15 m or more clear, with a regression test, `test_veilfall_hero_pieces_stay_clear_of_the_hike`, which fails on the old positions (`tb/tidewake` 5c… / d1939622c).
  - **Next for vf2:** the moved placement is re-capturing for its own close-up round.
  - **Land a167d0f67 is unaffected:** the limestone is a material change, and vf2 was OFF and excluded there.
  - **One rock family** (`veilfall_family_candidate`, OFF): the gate formations and crown crags move toward the limestone, material only.
    - The first look shows the crown crags pale tan.
    - Its views (Veilfall close-up and rain, the seven shore/lesson views) and matched fight frames are capturing for a judged round.

- 2026-10-24 16:30 CT **READY: `tb/tidewake-land` at a167d0f67** (a167d0f674e28cb143f891909183f71c0b2d0df9), one commit on origin/main 4fde48210, after #725 and #726.
  - **ON:** the Veilfall limestone (`veilfall_rock_candidate`), with every view it changes judged:
    - close-up 4.20 against 3.35 (vf1);
    - the seven F39-look views 5.29 against 5.24, which is level (ls1);
    - the Venn fight 4.90 against 4.77 (ls1).
  - **Staged OFF:** the `veilfall_hero_candidate` config and the `lift_m` spec key. The Meshy 7-8 GLBs are **not** in the land.
  - **Checks:** tidewake look, model preload, material family, dune cover and groves, and the five Veilfall test files: 35 tests, 2816 assertions, 0 failed.
  - I force-pushed over my own earlier land head; #725 has already merged it.
- 2026-10-24 16:30 CT **QUESTION (vf2/VERDICT.md): the Meshy 7-8 hero pieces split.**
  - **Close-up:** they beat vf1, 3.55 against limestone 2.85, with all three judges higher.
  - **Venn fight frames:** they lose, 4.29 against 4.72, with all three judges lower.
  - **Why the fight result is suspect:** every judge credits the control's frames 3-4 for the camp its live fight happened to swing towards, and no judge mentions the cascade in either side's fight frames.
  - **Shore views:** the hero pieces change them by less than run-to-run noise.
  - **Status:** OFF under the rule.
  - **The question:** do you want a matched-moment fight round (the same frame index, judged alone), or should the close-up decide? Either way, the judges' next ask is one rock family: the pale tiers against the black formation slabs.

- 2026-10-24 15:20 CT **INFO (ls1/VERDICT.md): the limestone ships ON; vf2 beats vf1.** All captures are on the #725-fixed code.
  - **Limestone on its other views** (seven F39-look shore and lesson views): 5.29 against main 5.24, which is level.
  - **Limestone in the Venn fight:** 4.90 against 4.77.
  - **Decision:** with vf1's close-up (+0.85), every view it changes is judged and none regresses, so `veilfall_rock_candidate` ships **ON** at `tb/tidewake` 76865d9ec.
  - **vf2:** the Meshy 7-8 cascade tiers plus the plunge ring on the probed gully ground score **3.55 against limestone 2.85**, all three judges higher (extrapolated below the anchors).
    - It stays OFF until its fight frames are judged, because the Venn fight camera stands at the Veilfall camp. Those are capturing now.
    - The judges still want one rock family: the pale tiers read pasted against the black formation slabs.
  - **F39#4 and F39#5 stay open** (all below 6.7).
  - A new land head with the limestone follows once the captures free Godot.

- 2026-10-24 14:10 CT **ANSWER (#725 review): p1 and p2 were not skewed. Regression test at `tb/tidewake` ff70faa67.**
  1. **p1 and p2 capture code.**
     - All four p1/p2 arms were captured at **8ce49fdaf**: `p1_ctl`, `p1_cand`, `p2_ctl` and `p2_cand` (each frame's `metadata.json` `source_sha`).
     - At that commit `shaders/stone_field.gdshader` has no `clump_patch`/`tide_band` uniforms, and `_build_stones` has no such keys. The grouping code first appears at 46d30d74d.
     - So neither arm rendered grouped pebbles. The 5.59 against 5.02 and 6.02 against 5.72 deltas are the props and the Deep Watch clusters alone.
     - The only frames that carried the bug are my limestone `ls_ctl`/`ls_cand` captures (46d30d74d), in both arms, and they have not been judged. I am recapturing them on the fixed code before judging.
  2. **The fix** is cherry-picked onto the lane as cabf2caab.
  3. **The regression test** is `test_water_dune_cover.gd::test_stone_grouping_never_inherits_the_grass_profile_keys`.
     - It builds the stone tier from the real shipping Tidewake profile, which sets grass `clump_patch_*` at the top level and has no stones override.
     - It asserts all five stone uniforms stay at the shader's 0.0 default.
     - It also asserts that a `stones` override still reaches the shader.
     - It **fails on the pre-fix `grass_field.gd` and passes on the fix**. `test_water_dune_cover`: 10 tests, 168 assertions, 0 failed.

- 2026-10-24 13:40 CT **READY: `tb/tidewake-land` at c542dcd8c** (c542dcd8cbdc99efa9a24c010a60066dd8e6af42), one commit on origin/main 45865499d.
  - **ON:** the Meshy beach props (p1: 5.59 against 5.02) and the Deep Watch shore site through `shipped_sites` (p2: 6.02 against 5.72).
  - **OFF:**
    - `stones_candidate`: the grouped-pebble shader uniforms, which do nothing at their defaults.
    - The capture-only `--tidewake-look-sections` arg.
  - **Not included:** the limestone and the Meshy 7-8 GLBs.
    - The limestone's extra views are captured, but the fight frames failed on a fresh main asset that was not yet imported here. Both are rerunning now.
    - The Meshy 7-8 GLBs (vf2) stay on the lane, unjudged.
  - **Checks:** 24 tests and 384 assertions covering tidewake look, model preload, material family, dune cover and groves, 0 failed. `water_alpha` is per your note: CI-green on main and environmental here.
  - **No F39 row closes**, because every score here is below 6.7.
  - I force-pushed this branch over beeea5516. Both are my own land heads; this one is rebuilt from origin/main.

- 2026-10-24 13:05 CT **INFO / BLOCKED (not this lane's): `smoke_net_water_alpha` is red on unchanged origin/main 45865499d in this container.**
  - Run: `tools/net/run_net_smoke.sh water_alpha` on two real peers.
  - The failing check is s15, "Client's engagement is authorized by remote host", with detail "No host-authorized local fight". Every other step passes.
  - The land head beeea5516 fails identically, so this lane's diff does not cause it. It may be the CPU container's timing, or something from the fights landing (#724); I have not root-caused it.
  - Logs are local (`/tmp/claude-0/sp/net_alpha*.log`).
  - **Please check it on CI.** The brief asks this lane to keep the smoke green, and I can't from here.
- 2026-10-24 13:05 CT INFO: your answers are applied on `tb/tidewake` 46d30d74d.
  - **Deep Watch:** it ships alone through a new `shipped_sites` switch on the shore-ecology candidate. The parent stays OFF, and a focused test covers both halves.
  - **Limestone:** the views it changes outside vf1 are being captured now: the seven F39-look shore and lesson views, plus the Venn fight where the judges saw the "black slab". They will be judged before it goes ON.
  - **Pebbles:** `stones_candidate` (grouped pebbles plus a tide band, OFF) is staged for the next round.

- 2026-10-24 12:45 CT **READY / INFO: 12:12 work order, all three steps done.** The land branch is `tb/tidewake-land` (SHA in the next line).
  1. **Meshy props (p1/VERDICT.md).**
     - What shipped: driftwood, a deck-work cluster and a 6.5 m hauled-up sloop on the First Shore and lesson beaches, plus driftwood at Deep Watch.
     - Score: mapped **5.59 against main 5.02** on the six F39-look views. All three judges scored it higher, and empty foreground moved from PRESENT to PARTIAL.
     - Decision: by your beats-main rule, `landmark_props_candidate` ships **ON**. It is presentation only with no colliders, so routes and encounters are unchanged.
     - The dock sections stay OFF (dk1 judged them level).
     - All six GLBs are already on main, so nothing has to be excluded from the land branch.
     - No F39 row closes: 5.59 is below 6.7.
  2. **P2-008 (p2/VERDICT.md).**
     - Fix: the Deep Watch clusters were behind the camera. They now sit 4-14 m out from the stand.
     - Score: mapped **6.02 against main 5.72**. All three judges scored it higher. **Not met.**
     - The candidate **stays OFF**: its parent flag would also turn on six other islands' clusters that nobody has judged.
     - **QUESTION:** do you want a per-site switch so Deep Watch alone ships ON by the beats-main rule?
     - What the judges still want: rock outcrops or a headland at the waterline (new-art scale), and the even `stone_field` pebble scatter fixed.
  3. **F39#4, said plainly: the Veilfall close-up cannot reach 6.7 in-scene.**
     - Shipping maps to **3.35** (vf1/). The best in-scene change, the limestone material, maps to **4.20**.
     - Four earlier OFF massing candidates from prior lanes did not get there either.
     - Every judge since mx1 names the same causes: low-poly faceted cliff slabs, the near-black kitbash crown, and a stand at the cliff foot where the falls read as a blown white smear.
     - Two of those are new art: **MESHY requests 7-8** (`meshy-requests.md`, references and scale checks under `assets/props/meshy-1025/`).
     - **Please reopen F39#4.** I'll integrate 7-8 when they arrive.
     - The limestone material also beats shipping (+0.85) but stays OFF under the "OFF until passing" rule. **QUESTION:** apply beats-main to it as well?
  - **Next:** I'll rerun F39#5/#3 now that `tb/fights` has landed (#724). Then I'll work the shared top asks: the pebble scatter clustering (scene) and the horizon haze band (scene).

(send_message refused: elevated_session_untrusted_device. Newest first.)

- 2026-10-24 06:45 CT INFO: thanks for landing #718. `tb/tidewake` has origin/main 7480d1a27 merged in (Creatures #717), and both review nits are fixed in ae5db2d29 (comments only, 7 look tests 0 failed): `tidewake_world_look.gd` no longer calls the regrade OFF, and the config's top-level `_comment` now describes the shipped state. These ride the next landing; nothing else is pending on the lane branch beyond notes and the Meshy 1025 reference inputs.

- 2026-10-24 06:00 CT INFO: **P2-008 (shore landforms, impact 100), first of the 12 Tidewake-scene items.** No judge round was run, because the existing candidate cannot move its own camera:
  - **The candidate places nothing in view.** `water_dune_cover.json` `shore_ecology_candidate` (via `--tidewake-shore-candidate`) does place 108 instances, two small clusters at Deep Watch among them. Those clusters sit in a sector at bearing -132.8 degrees, behind `P2-008-shore.json`'s camera (yaw 24.6). The control and candidate frames are identical, with identical per-island counts.
  - **The grass is not what reads as even.** The shipping dune profile already clumps it with real clearings (`clump_scale` 0.065, `clump_contrast` 1.0, `clump_patch_start/full` 0.47/0.64).
  - **The even scatter every judge names is the pebble field.** `grass_field.gd` hands the stones the same noise (stones fall back to the grass `clump_*` keys), but `stone_field.gdshader` only does `mix(1.0, noise, contrast)`, with no clearing threshold. So pebble density never reaches zero, and the beach reads as one even sprinkle.
  - **Smallest real fix:** add the grass shader's `clump_patch_start/full` smoothstep to `stone_field.gdshader`. That is a shared shader used by every biome, so it needs an OFF uniform default and a Meadows no-change check. Then judge P2-008 on a camera that faces the shore it changes.
  - **Next in this lane's 12:** P2-115 camp bed (ON since close-1022, never judged on today's yardstick) and P2-057 grass around named characters (candidate OFF). Both are bounded captures with existing candidates.

- 2026-10-24 05:40 CT **READY: `tb/tidewake-land` = 2a111298a** (contains origin/main 816dfa60f; merged after PR #716 landed, no file overlap). This is the land branch with the 7.07 time-of-day grade ON; everything else in it is OFF, a capture fix or evidence. Checks on that tree: 578 water/tidewake/veilfall/dock/drift/clock/weather/world-look/texture tests 0 failed, smoke_net_water_alpha ALL CHECKS PASSED, and after the merge `tidewake_look/water_surface/water_offshore/veilfall` re-ran with 20 tests, 0 failed. Commits on `tb/tidewake` after 2a111298a are notes and Meshy reference inputs only; they do not need to land.
- 2026-10-24 05:40 CT **MESHY (Veilfall hero, the real fix for F39#5's placeholder rock):** inputs are on `tb/tidewake` under `assets/props/meshy-1025/<name>/reference/` (each with `.gdignore`):
  - **(7) veilfall_cascade_tier**, 18 m wide x 10 m deep x 12 m tall (6.7x the 1.80 m trainer, see `scale_check.png`). Refs: `board_exterior_crop.png`, `board_falls_entrance_crop.png`, `board_palette_crop.png`, cropped from `docs/reference/boards-2026-09-06/water-veilfall-stronghold-board.png`. Full prompt in `prompt.txt`: pale stratified limestone tier with a pour notch, a wet pour line, mossy ledges and a turquoise catch basin; stackable flat base and top; no red.
  - **(8) veilfall_plunge_rocks**, 9 x 7 x 3 m. Refs: `board_approach_crop.png`, `board_palette_crop.png`. Prompt: water-worn pale limestone boulders around a shallow turquoise plunge basin.
  - Both land flag-OFF and get judged against vf1 (limestone 4.20, shipping 3.35). Acknowledged: the limestone material stays OFF meanwhile; telegraphs are left to tb/fights, and F39#5/F39#3 rerun once it lands.

- 2026-10-24 05:15 CT **READY: `tb/tidewake-land` (head named in the commit after this note).** It is origin/main plus lane work only. Everything since the 02:45 READY is OFF, a capture fix, or evidence:
  - **Meshy 1024 batch wired in OFF** (all judged: docks level, currents level).
  - The `veilfall_rock_candidate` limestone section, OFF.
  - The rain-sky capture fix.
  - The r3 wake removed from the OFF currents candidate.
  - **Verdicts:** dk1, mc1, mx1, vf1.
  - **ON is unchanged:** only the time-of-day grade (7.07 CPU-provisional).
  - **Checks on this tree:** 578 water/tidewake/veilfall/dock/drift/clock/weather/world-look/texture tests, 0 failed. `smoke_net_water_alpha` ALL CHECKS PASSED. Meshy textures pass `texture_import_policy --check` (mode 2).

- 2026-10-24 05:00 CT **ROW STATUS, newest** (coordinator's priority order):
  - **F39#5: NOT MET.** First defect pass over a matrix with weather and a real fight (mx1/). Floating bodies: none. Three defects remain:
    - **Magenta telegraphs in the fight.** The Fights lane owns this; it is the COMBAT spec's documented must-move colour, so this lane does not change it.
    - **Veilfall placeholder rock.** The limestone material candidate reduces it from PRESENT to PARTIAL, 4.20 vs 3.35 (vf1/), still OFF. The real fix is Meshy 7-8.
    - **"Clipping".** On inspection this is the same Veilfall rock seen from the fight camera, plus the camera set's stand against the cliff.
  - **F39#3: NOT MET** (mx1/). The look views pass at 7.07 (lt2), but rain maps to 5.31 and the real Venn fight to 5.10. The fight's weight is the magenta telegraphs, the HUD and the out-of-frame player creature; none of those are Tidewake scene items.
  - **F39#1/#2: NOT MET.** 43 items remain, 12 of them Tidewake-scene (table above); the other 31 belong to other lanes.
  - **F13#5: PARKED and failing.** Currents best 6.20; the Meshy reopening round (mc1/) scored level with r3. Docks map to 6.07 on today's yardstick (dk1/), so neither half is at the bar.
  - **ON this close:** the time-of-day grade, 7.07 CPU-provisional.
  - **Re-check request:** F39#4's close-up half maps to 3.35 today (vf1/), against a 7 Oct "met".
  - **Land branch:** rebuilt below.

- 2026-10-24 03:40 CT INFO: **docks re-measured, and the Meshy buildings judged** (dk1/VERDICT.md). Shipping docks map to **6.07** on the current yardstick (confirming batch, r 0.92, RMSE 0.50), below the 6.7 bar; the close-1022 figure of 6.77 predates the corrected prompt and should not be counted, so **F13#5 has neither half at the CPU bar**. The Meshy 1024 boathouse/smokehouse swap scores 5.97, level with the control, and stays OFF. The judges' ask is not new art: the three hamlets share one template's positions, banner and stall, so the landings read as one copied set however the models change, and the 20 m walk-in is bare sand with nobody working it. Next step is per-dock layouts that differ in placement plus a dressed walk-in (the sloop, nets, racks, residents), with the Meshy buildings scaled up.

- 2026-10-24 03:05 CT INFO (MESHY received, thank you): the six-item day-1 batch from `tb/meshy-1024` 38602bdb0 is in at 28c4e8282, OFF, textures on mode 2 (`texture_import_policy --check` PASS on 18 sidecars), import clean. Fitted from measured GLB bounds against the 1.80 m trainer: boathouse 5.5 m and smokehouse 4.5 m replace the two Medieval cottages per hamlet in `dock_village_candidate` (mixed per dock so the three hamlets stop repeating) with a work cluster by each pier; a 6.5 m sloop moors beside the rowboat in the new OFF `dock_dressing_candidate`; the 3.0 m driftwood log and 2.6 m spar buoys go into the OFF `current_flow` drift markers. Dock and current frames with all of it are capturing for a judged round. 76 tidewake/dock/drift/texture tests, 0 failed.
- 2026-10-24 03:05 CT INFO: F39#3 capture fixes. (1) Rain views rendered rain streaks out of a clear midday sky: the fixed-view loop called `look.set_weather({})` after `WorldWeather.set_weather()` had pushed the preset's sky delta, wiping it. Clear views keep that reset (so they stay identical to every earlier clear batch); other presets keep the delta. (2) The HUD location toast in the first rain frame reads "The Veilfall" at First Shore: a leftover banner from the previous view's teleport, a capture artefact, not a game defect. Reorder views or settle longer if it matters for the matrix.

- 2026-10-24 02:45 CT **READY: `tb/tidewake-land`** (rebuild below). Contents, all on origin/main 5f1f388cc with nothing else in front of it:
  - **ON, judged passing:** the Tidewake time-of-day regrade (`lighting_candidate` out of `sections_off`, score in `_why_lighting_candidate`). Mapped CPU Bar A **7.07** (6.98 and 7.16, the same frames judged twice in one confirming batch, anchors to 7.53, nothing extrapolated), against control 5.84. **CPU-provisional; a GPU pass is owed.** Night readability measured, not assumed: `frame_stats.py` near_luma 0.231 against 0.292 shipping and the 0.135-0.222 band `art.json`'s night contract accepted for Meadows. Verdicts in lt1/ and lt2/.
  - **OFF, shipped for capture:** `surfaces_candidate` (the water shelf stop, scored level with the control), `dock_village_candidate` (pavers off, unjudged), and the current-cue work under the existing `current_flow` gate.
  - **Shader and script changes that are no-ops at their defaults:** `water.gdshader` gains `mid_colour`/`mid_depth_m`/`depth_band_break_m` (0 = the old two-colour ramp exactly; the shelf stop mixes INTO the colour so the Tidewake offshore variant's injected deep tone survives); `water_current_flow.gdshader` gains the seam, wavelet-cap and tongue uniforms (0 = off); `water_current_drift_markers.gd` gains `lean_deg`/`wake_length_m` (absent = the old upright, wakeless post).
  - **F39#3 blocker fixed (folded into commit e858e6ae7, whose message does not mention it; recorded here instead):** the fixed-view capture path refused any weather preset but clear, which blocked F39#3's weather requirement outright. It now applies each view's own declared preset to the same frozen WorldWeather the clear path pins and reads it back, so a frame can never be captured under a different preset from the one asked for; an unknown name fails instead of silently capturing "clear". `F39-look.json` gains shore-rain, lesson-rain and veilfall-rain at the existing stands, and all three captured with `weather=rain` recorded per frame.
  - **Checks:** 543 water/clock/weather unit tests, 0 failed; `test_tidewake_look_profile` extended (it now asserts the regrade ships ON with its score recorded, and that both new candidates ship OFF); `smoke_net_water_alpha` ALL CHECKS PASSED with the grade on; 101 dock/current/drift tests, 0 failed.
  - **Not landed, and why:** nothing is enabled that a judge has not passed. The shoal reshape stays out (gameplay terrain, needs the water route/swim/heightfield tests and a rebake).

- 2026-10-24 02:10 CT READY-ISH / PARKED: **F13#5 currents parked at mapped CPU 6.20** (r3/VERDICT.md), below the 6.7 CPU-provisional bar, so the row stays failing with its evidence. Four judged rounds: 4.96 (close-1022) -> 6.11 (b5 tide-line seams) -> 6.16 (b6 foam tongues) -> 6.20 (r3 leaning stakes with wakes). Two consecutive rounds under +0.5 so the gain rule applies. Road markings and box-like floaters are FIXED/PARTIAL on every candidate; direction is the defect that holds it. Reopening condition, from all three judges across four batches: the cue has to come out of the water surface (flow-aligned shearing normals, foam that travels dock-to-horizon, drifting flotsam), not from furniture on it.
- 2026-10-24 02:10 CT INFO: lighting_candidate (OFF) pushed and judging: a real evening grade at 18:00, a directional moonlit night, stronger horizon haze and aerial perspective. This answers the largest finding in w1, which also blocks F39#3's day/night requirement.

- 2026-10-24 01:20 CT INFO: F13#5 currents, honest state. b5 mapped 6.11 and b6 appeared to reach 7.33, but both b6 passes were extrapolated past a 6.93 top anchor; the required confirming batch b7 (anchors to 7.53) puts the same frames at 6.06-6.09 against a control of 5.42. **The row does not meet the 6.7 CPU-provisional bar.** Road markings and the box-like floaters are FIXED by all three judges; direction is the one defect still PRESENT. b6 was the first round under +0.5, so one more parks the row. r3 (stakes leaning downstream with a trailing wake, the judges' own ask) is capturing now as the different approach. Verdicts: b5/, b6/, b7/.
- 2026-10-24 01:20 CT INFO: P2-009 water depth candidate pushed (OFF): water.gdshader gains a mid shelf stop and a world-space wander on the depth every ramp reads, so the sea stops meeting the horizon on a razor seam. All three judges in b6 and b7 named that seam. Judging now on the F39-look camera set.

- 2026-10-24 00:20 CT INFO: F13#5 currents batch b5 (b5/VERDICT.md): mapped CPU Bar A 6.11 for the tide-line-seam candidate, against control 5.64 and best 4.96 (+1.15). Road markings PARTIAL x3. Candidate OFF. b6 (tapered foam tongues, soft lane tint, larger caps) is capturing.

- 2026-10-23 CT MESHY: day-1 batch of 6, briefs/sizes/refs in `meshy-requests.md` (this folder): (1) tidewake_driftwood_log 3.0x0.5x0.6 m, current drift markers; (2) tidewake_moored_sailboat 6.5x2.0x6.5 m; (3) tidewake_boathouse 8x5x5.5 m stilt boathouse; (4) tidewake_smokehouse 4x4x4.5 m; (5) tidewake_channel_spar_buoy 0.9x0.9x2.6 m; (6) tidewake_dock_work_cluster 2.0x1.4x1.2 m. Please push GLBs to a branch and name it here or on tb/tidewake; all go in flag-OFF.

## F39#1 / F39#2 scope, as read on 24 Oct

The 44 Tidewake catalog rows (`ralph/reports/VISUAL/phase2/catalog.csv`) sort into four owners. Of the top 20 by impact, only six are this lane's to judge:

| Item | Impact | State |
|---|---|---|
| P2-008 shore landforms | 100 | candidate OFF (shore ecology, close-1022 b3; judged above control but below b2) |
| P2-010 Veilfall silhouette | 80 | candidate ON since close-1022; `water_veilfall_silhouette_visual.json` and `..._falls_visual.json` now ship `enabled: true` (the board note calling them false is the 2026-10-04 audit and is stale) |
| P2-011 named destination read | 80 | PARKED at 6.13/6.28 (close-1022) |
| P2-009 water and island depth | 60 | this close: the shelf candidate scored level with the control (w1), the lighting candidate is in judging |
| P2-026 Veilfall approach shallows | 36 | the shoal reshape stays OFF: it is gameplay terrain and needs the water route/swim/heightfield tests plus a rebake |
| P2-066 live current streaks | 36 | PARKED with F13#5 at 6.20 (r3) |

The other fourteen are **not this lane's**: P2-016, P2-028, P2-071, P2-101, P2-108, P2-119 and P2-063 are animation; P2-002, P2-001, P2-007 and P2-060 are UI; P2-089 and P2-113 are camera; P2-030 and P2-033 and P2-055 are the shared-art lane's material and mesh candidates (the shared-art note names the three configs that ship OFF). F39#1 asks for a before/after code-blind PASS on **every** top-20 item, so the row cannot close from the Tidewake lane alone; it needs the animation, UI, camera and shared-art lanes' rows for the same items. That is the structural reason F39#1 and F39#2 have stayed in_progress across several closes, and it is worth the coordinator's attention before another Tidewake-only round is spent on them.

## Where the Tidewake look actually stands, 24 Oct

Four judged items this close, all mapped through confirming batches (anchors reaching 7.35 or higher, so no score here is extrapolated):

| Item | Control | Best candidate | Bar |
|---|---|---|---|
| F13#5 / P2-066 currents | 5.42-5.75 | **6.20** (r3) | PARKED under 6.7 |
| P2-009 water depth (shelf stop) | 5.90 | 5.90 (no gain) | under 6.7 |
| F39 look, time-of-day grade | 5.60 | **6.21** (lt1, +0.61) | under 6.7 |

Three things are now established with evidence rather than opinion:

1. **The yardstick works, and it caught us.** The b6 batch read 7.33 for the currents candidate and would have closed the row; its anchors only reached 6.93, so the score was extrapolated. The confirming batch with anchors to 7.53 put the same frames at 6.06. Every number above is from a confirming batch.
2. **Tidewake's ceiling is light, not meshes.** Across four batches and twelve judge passes the same three things are named first: no time-of-day grade, no horizon haze, no cast shadow at night. The grade round moved the look more in one pass (+0.61) than three rounds of current-cue work moved the currents row (+0.09 in total after the first).
3. **Two rows cannot close from this lane.** F39#1 needs a before/after PASS on all twenty top items; fourteen belong to the animation, UI, camera and shared-art lanes (table above). F39#3 additionally needs weather and a real fight, and `capture_tidewake_f13_5.gd --camera-set` refuses any weather but clear, so the matrix cannot be captured with the tool this lane has.

## F39#5 defect scan: what twelve judge passes actually found in Tidewake

The four batches this close put the Tidewake frames in front of twelve independent code-blind judges. Against F39#5's four named classes:

- **Flat magenta rings or slabs: none in any Tidewake frame.** Every magenta finding in this close is in the Stormwood fight anchor (`f10_2_r3_capacitor`), not in Tidewake. Passed to the Fights lane: flat magenta telegraph quads and ground rings, no impact on the strike and impact frames, and a player creature that is never identifiable in frame.
- **Placeholder materials: one, and it is the chapter's hero landmark.** All six judges across lt1 and lt2 call the Veilfall close-up faceted untextured slabs with a waterfall that stops partway down with no plume, spray or pool, and mark it `new_art`. Meshy requests 7-8 cover it.
- **Floating bodies: reported once, did not reproduce.** A b6 judge described "a detached blue clawed flipper standing in the sand, a second creature buried in the dune to the shoulder" in the Brine Steps swim view. Checked at 4x on that exact frame: the creature stands beyond the dune crest and is cut off by the ridge line, which is ordinary terrain occlusion from a sea-level camera looking up a dune. No defect found, nothing filed.
- **Clipping: nothing in geometry.** Two judges named "a prop clipped by the right frame edge" in the dock rows; that is the fixed camera's framing at the authored stand, not geometry through geometry.

The honest state of the row: this is a scan of the look views, not of F39#5's full matrix, which depends on F39#3's matrix (now capturable under weather, still missing a real fight and the reverse/detail views). The scan on the 9-view matrix with the shipping look is capturing.

## F39#1 / F39#2: exactly what remains (24 Oct, for the coordinator)

F39#1 = every top-20 Tidewake item fixed on main with a before/after code-blind PASS. F39#2 = every other Tidewake item with impact > 12. None of the 39 below has a PASS on the current yardstick yet, so both rows remain open. Owner is by `fix_class` in the catalog; "Tidewake" marks the rows this lane can fix in the Tidewake scene.

### F39#1, top 20

| Item | Impact | Fix class | Owner | State this close |
|---|---|---|---|---|
| P2-008 shore landforms | 100 | scene | Tidewake | shore-ecology candidate OFF; judges keep naming even scatter and bare dunes |
| P2-016 creature hurt and movement poses | 100 | animation | animation (creatures/fights) | needs_capture |
| P2-002 map | 80 | ui | UI | open |
| P2-030 shiny creature finish | 80 | material | shared-art / Tidewake | shared-art candidate OFF |
| P2-033 ground pickup identity | 80 | mesh | shared-art / Meshy | open |
| P2-010 Veilfall silhouette | 80 | scene | Tidewake | Veilfall: the weakest frame in every batch, new_art from six judges; Meshy 7-8 requested |
| P2-011 named destination read | 80 | scene | Tidewake | parked 6.13/6.28 (close-1022) |
| P2-071 surface swimming trainer pose | 80 | animation | animation (creatures/fights) | animation candidate OFF |
| P2-028 creature faint state | 64 | animation | animation (creatures/fights) | needs_capture |
| P2-089 fight actor composition | 64 | camera | camera | deferred |
| P2-108 Aquaryn mounted-water pose | 64 | animation | animation (creatures/fights) | open |
| P2-113 catch camera distance | 64 | camera | camera | deferred |
| P2-119 Fly carrier grip pose | 64 | animation | animation (creatures/fights) | open |
| P2-001 menu shell | 60 | ui | UI | open |
| P2-007 secondary menu panels | 60 | ui | UI | open |
| P2-055 named character silhouettes | 60 | mesh | shared-art / Meshy | shared-art candidate OFF |
| P2-009 water and island depth | 60 | scene | Tidewake | shelf stop 5.90 = control (w1); grade ON 7.07 is the look, not this row |
| P2-063 shared fight tell and hit effects | 60 | animation | animation (creatures/fights) | open |
| P2-060 catch effect finish | 48 | material | shared-art / Tidewake | open |
| P2-101 Riverdrake fight ground contact | 48 | animation | animation (creatures/fights) | open |

### F39#2, the rest with impact > 12

| Item | Impact | Fix class | Owner | State this close |
|---|---|---|---|---|
| P2-069 flight and landing pose read | 48 | animation | animation (creatures/fights) | deferred |
| P2-115 authored camp creature bed silhouette | 48 | mesh | Tidewake | camp bed sailcloth ON since close-1022, unjudged on the current yardstick |
| P2-116 authored camp workbench identity | 48 | scene | Tidewake | needs_capture |
| P2-004 exploration HUD | 45 | ui | UI | open |
| P2-072 swimmer water contact | 45 | material | Tidewake | candidate_off |
| P2-045 candy pickup tiers | 36 | material | shared-art / Tidewake | open |
| P2-088 fight team roster contrast | 36 | ui | UI | candidate_off |
| P2-090 fight background creature ground contact | 36 | scene | Tidewake | needs_capture |
| P2-026 Veilfall approach shallows | 36 | scene | Tidewake | shoal reshape OFF: gameplay terrain, needs route/swim/heightfield tests and a rebake |
| P2-031 settings and binding instructions | 36 | ui | UI | open |
| P2-066 live current streaks | 36 | material | Tidewake | PARKED with F13#5 at 6.20 |
| P2-067 current restoration environment | 36 | scene | Tidewake | needs_capture |
| P2-073 dialogue camera framing | 36 | camera | camera | needs_capture |
| P2-103 named fight victory hierarchy | 36 | ui | UI | candidate_off |
| P2-109 Aquaryn dismount camera obstruction | 36 | camera | camera | needs_capture |
| P2-114 catch chance HUD contrast | 36 | ui | UI | candidate_off |
| P2-032 map active region | 27 | ui | UI | fixed |
| P2-061 catch result hierarchy | 27 | ui | UI | open |
| P2-075 dialogue foreground obstruction | 27 | camera | camera | needs_capture |
| P2-029 creature rest poses | 27 | animation | animation (creatures/fights) | candidate_off |
| P2-091 fight boss title overlay | 24 | ui | UI | open |
| P2-057 grass around named characters | 24 | scene | Tidewake | candidate_off |
| P2-074 dialogue speaker visibility | 18 | camera | camera | needs_capture |

**Count:** 20 top-20 + 23 impact>12 = 43 items; 12 are Tidewake-scene rows this lane can fix, the other 31 belong to the animation, UI, camera and shared-art lanes. Neither row can close until those lanes land PASSes on the same items.
- 2026-10-25 INFO wl1: waterline_declutter_candidate level on CPU (6.36 → 6.47 mapped), stays OFF. Judges name the pier stakes, the even pebble carpet and the cold 18:00 sky, not the drift markers. Evidence: wl1/.
- 2026-10-25 READY fc2 (Veilfall face, OFF): terraced flanks + mossy ledges + narrower crown + far rain veil, CPU mapped 5.27 → 5.98 (+0.71, x3); rain streaks FIXED x3. Sections: current_flow,veilfall_falls_candidate,rain_fog_candidate,rain_veil_candidate,veilfall_mountain_candidate. Head: 2b0d9b543. Judges name sawtooth terraces next; fc3 in progress.
- 2026-10-25 QUESTION (coordinator messaging is refused from this session): the dark-red creature in the pumps view is a wild spawn from water_sluice_isle_land (mirejaw/riptusk/cragclaw). Recolour that species, or move the pumps/camera to the shore so it is out of frame? Taking the move route unless told otherwise.
- 2026-10-25 READY fc3 (Veilfall face, OFF; supersedes fc2): 28 m soft terraces + dark ledges beat fc2 head to head, CPU mapped 4.41 → 5.34 (+0.93, x3); fc2 was +0.71 over shipping. Same sections as fc2. Code/config head 2 commits before the swim_candidate commit on tb/tidewake (fc3 commit). Next asks from judges: flank cliff masses, falls with mist, rain value.
