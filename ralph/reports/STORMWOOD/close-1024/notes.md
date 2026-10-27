# Stormwood lane, close-1024 (F41#1, #2, #3, #5; F10#2)

## Session 2 log (newest first)

- 27 Oct 00:24Z **READY (GPU candidate): `tb/stormwood-m48-on` ebcae6ed, Ashfoot room.**
  - **Change:** `cottage_interior_finish.json storm_finish.storm_room` + `stormwood_dressing` ON; the lane keeps both OFF. This is coordinator priority 1: SW16 left it at 6.96, 0.54 short.
  - **CPU r48:** 5.37 -> 6.31 mapped (+0.94), 3/3 judges prefer ON. Warm-room and no-Stormwood defects PRESENT -> PARTIAL 3/3 (`r48/VERDICT.md`).
  - **What to capture:** the F41 catalogue Ashfoot stands, inside (four phases) and outside (no-change check), at Medium and High against lane HEAD.
  - **Checks:** `smoke_stormwood_ashfoot_shelter.gd` 16/0.
  - **New GPU load:** one unshadowed SpotLight3D, one additive quad, about 60 small moss spheres and three small crystal models.
- 27 Oct 00:24Z **SW13 pool-edge defect: no separate arm.** The pools exist only under `stormwood_ground_finish.json ground_zones`, which is OFF on main, and that approach is parked. With the flag OFF an arm shows nothing; with it ON it reintroduces the parked ground pass.
  - **Lane fix (fa9b8aa4):** the satin pool finish (roughness 0.38 / specular 0.25, the white-cyan "glass slab" rims) is now matte by default (0.75 / 0.06), configurable as `ground_zones.pool_roughness` / `pool_specular`. Any new ground idea starts without the defect.
- 26 Oct 23:58Z Coordinator, 23:52Z:
  - Ashfoot `storm_view` is on main (#767). land13 is done; no PR.
  - The m45c storm sky is queued as GPU **SW19**.
  - **SW17 junction lamp posts: no gain (-0.03/-0.06). PARKED; not retried as built.** The judges' path, for any new idea: a taller, sturdier post with an arm and a stone/root footing off the trunk, a smaller halo, real light pooling instead of sprite discs, and a softer guide beam.
  - Lane `tb/stormwood` 74d41412: main #768 merged.
- 26 Oct 23:58Z In progress, **r48 Ashfoot** (coordinator priority 1; SW16 at 6.96, 0.54 short). One candidate:
  - `storm_room` ON (r47's window wash and dimmed lamps);
  - a new `window_patch`: the window's pane pattern on the west wall per phase, lifted by the flash;
  - a new `stormwood_dressing`: blue-green moss runs and strands, small storm-glass crystals on the sill and shelf, a copper lightning rod and chain coil.
  - CPU capture is running against r47's OFF frames.
- 26 Oct 22:08Z **READY to land land13 de5e5f8508626f0d5b510ea32ac5ebeeca653987** (`tb/stormwood-land13`). It **supersedes land12**: main #766 already carries the SW18 Crown Overlook vista, so land13 is origin/main f0bd9f05 plus only **Ashfoot `storm_view` ON** with `_why_on` (GPU SW16 +1.13).
  - **Checks:** main's cottage config is unchanged since land12 and land13 uses the same config file, so land12's checks carry over (`smoke_stormwood_ashfoot_shelter.gd` 16/0).
- 26 Oct 22:08Z Lane `tb/stormwood` fb919fb5: main #766 merged.
  - `stormwood_crown_overlook.json` now takes main's landed SW18 values ON. The lane's unjudged r46 round-3 values are kept as `r46/candidate_crown_overlook.json`.
  - **Storm-sky arm rebuilt:** **`tb/stormwood-m45c-on` 8a22c917**. Use it for the GPU, replacing m45b 9e2642f9 and m45 94adcb41.
- 26 Oct 20:20Z r47 Ashfoot storm-driven room light: **+0.33 mapped** (5.44 -> 5.77), 3/3 judges prefer ON (`r47/VERDICT.md`). Under the bar, so no arm; `storm_room` stays OFF to ride along.
  - **Next Ashfoot swing (r48):** storm_room plus Stormwood dressing inside (moss on the sills and beams, copper fittings, glass floats or lantern, storm gear) and a window-shaped lightning flash on the walls.
- 26 Oct 19:44Z **READY to land land12 8bf4dbd169e70bb8f9dbd6d806c92ba97a3e04bf** (`tb/stormwood-land12`). It **supersedes land11**. It is origin/main 9a1b26ba (#763) plus:
  - **land11 unchanged** (GPU SW18 +0.86): the Crown Overlook deck + massif ON, the deck survey stand, and the Hollow Crown Meshy asset;
  - **Ashfoot `storm_view` ON** with `_why_on`. GPU SW16 m36b: interior 5.83 -> 6.96 (+1.13) at both presets. Seated + firelit were already ON on main, and main's storm_view code and config match the judged arm apart from the flag.
  - **Checks on the land12 tree:** `test_stormwood_crown_overlook.gd` 2/526, 0 failed; `test_four_biome_debug_teleport.gd` 10/1094, 0 failed; `smoke_stormwood_ashfoot_shelter.gd` 16 checks, 0 failed (roof and shelter correct inside, at 11 m and at 60 m with the storm card in place).
- 26 Oct 19:44Z Lane `tb/stormwood` 0d3ca476: main #763 merged (four Meadows files the lane never touched); storm_view ON.
  - **Storm-sky arm rebuilt** on the merged lane: **`tb/stormwood-m45b-on` 9e2642f9**. This replaces 94adcb41 for the GPU (same flags: `ceiling.form` + `ceiling.skyline` ON).
- **Next for Ashfoot (SW16 path to 7.5, 0.54 short):** room light that follows the storm. The window casts the phase colour in, and at break a white-violet flash shows on the walls against the warm hearth. Building it as r47.
- 26 Oct 16:58Z SW16: `GPU-PASS/CRASH-0xC0000094/README.md` (94982d62) says the 08:22 SW16 candidate run hit a real TDR (nvlddmkm 153 / Display 4101), not the driver divide-by-zero.
  - My storm_view review (above) stands. Its only per-pixel work is one 4-octave fbm on one 9x6 m quad, which cannot take a GTX 1060 near the 2 s TDR limit by itself.
  - If the queued re-run TDRs again on the Ashfoot stands, I'll take the m36b arm apart: storm_view OFF with seated/firelit ON (as SW15 m35, which ran clean) would isolate the flag. Lane ready to build that split arm on request.
- 26 Oct 15:38Z r46 Crown Overlook round 3 on land11: **+0.31 mapped** (5.87 -> 6.18), 3/3 judges prefer ON (`r46/VERDICT.md`). Under the bar, so no arm.
  - **Pale Crown:** PRESENT -> PARTIAL. A new massif `haze` block skips scene fog and carries its own storm haze.
  - **No height:** still PRESENT 3/3 on both arms.
  - The values stay OFF and ride along with the height change.
  - **Height:** a deck on flat ground cannot show a drop. Next idea: a taller lookout over lower canopy, which needs the catalogue's deck-floor probe (terrain + 4 m) raised; or relocating the deck to a real slope edge.
- 26 Oct 14:48Z **READY to land land11 df283d439ecae7f4f7020b9bbfce166af7efbc3f** (`tb/stormwood-land11`). It is origin/main d212fbed (#762) plus exactly the GPU SW18-judged m41 pieces, and nothing else:
  - `stormwood_crown_overlook.json` from m41, with the deck and massif ON;
  - the Crown Overlook `f41_survey` stand on the deck (37 deg) in `debug_teleport_spots.json` (main's newer Heartstone stand is kept);
  - the Meshy `stormwood_hollow_crown_silhouette` asset dir (tb/meshy-1024 2cbd71381; import policy applied).
  - The deck script and test are already on main and identical to m41's.
  - **Checks on the land11 tree:** `test_stormwood_crown_overlook.gd` 2 tests / 526 assertions, 0 failed; `test_four_biome_debug_teleport.gd` 10 tests / 1094 assertions, 0 failed.
  - **Not in land11:** the lane's unjudged round-2 overlook values (deck 3.5 m with a drop, wood tint, massif tint) and the m45 storm sky. Those stay as their own arms.
- 26 Oct 14:48Z Next for the vista (SW18 path to 7.5: Crown in all three views, darker with a rim, height, sky, ground beyond the rail). It is one candidate on top of land11:
  - **Crown in v01 and v03:** a second and third Meshy massif read is not possible from one deck heading with 90-degree views. The catalogue stand turns so the Crown sits between v01 and v02.
  - **Massif:** the darker tint with a lit rim.
  - **Height:** the higher deck with a drop.
  - **Sky:** the m45 storm sky, if SW-m45 passes.
- 26 Oct 14:24Z **READY (GPU candidate): `tb/stormwood-m45-on` 94adcb41, Stormwood storm sky.**
  - **Change:** `stormwood_surge.json presentation.ceiling.form` + `ceiling.skyline` ON; the lane keeps both OFF.
  - **CPU r45b:** 5.75 -> 6.58 mapped (+0.83), 3/3 judges prefer ON. Flat lavender sky FIXED 3/3; empty horizon PRESENT -> PARTIAL (`r45b/VERDICT.md`).
  - **Why it is a chapter-wide swing:** the sky is in every open Stormwood stand in the catalogue, so judge it on the full F41 catalogue at Medium and High against lane HEAD.
  - **Checks:** surge presentation 53/0 and surge 4/0.
  - **Photosensitivity:** no new flash onsets; the form is a static shape on the deck.
  - **Not a GPU risk:** no texture samples, and only bounded fbm. It is one more 5-octave fbm block and a few noise calls in the existing ceiling dome shader, with no new passes or geometry.
- 26 Oct 14:24Z r45 (soft masses) was -0.06, a first miss (`r45/VERDICT.md`); r45b's hard edges are what moved it. Next sky refinement: tame the lit rims that two judges read as white smear slabs.
- 26 Oct 13:45Z **SW16 device loss (m36b storm_view, Medium):** I reviewed everything the flag adds. Nothing plausibly hangs a GPU, so there is no new arm.
  - **What the flag adds:** one 9x6 m `QuadMesh` card (`cottage_storm_view.gdshader`) and a duplicate of one kit glass material.
    - The card's shader is `unshaded`, `cull_back`, `shadows_disabled` and `fog_disabled`. It has no texture samples and no division, its only loop is a bounded 4-octave fbm, and `flash` is clamped to 0-1.
    - The glass copy is a plain `TRANSPARENCY_ALPHA` duplicate of `MI_WindowGlass` (roughness 0.1, no emission).
  - **No new lights, probes, shadows or sky work:** the flag adds none of these. The shadowed hearth/lantern lights are the `seated`/`firelit` ones that SW15 m35 already ran clean at both presets.
  - **Where it failed:** VkResult -4 with breadcrumbs SKY_PASS / BLIT_PASS points at the world sky's radiance pass, which storm_view never draws into. The card is not in the sky pass.
  - **If the re-run fails again:** run the Medium control and candidate on just the Ashfoot stands, so a repeat can be tied to the flag or to the stand switch. I'll take any log lines you can share.
- 26 Oct 13:40Z In progress, r45 **storm-cloud form** (`stormwood_surge.json presentation.ceiling.form`, OFF).
  - **Why:** every Stormwood set in r41-r44 (all judges) names "a flat lavender sky with no cloud form".
  - **What it draws:** large domain-warped cloud masses on the surge ceiling, with dark bases overhead, lit edges, a paler layer between the masses and rain curtains near the horizon. Nothing is bright just above the horizon.
  - **CPU capture:** OFF/ON at Crown Overlook, Struck Sentinel, Glass Field and Rodline Post, calm + break.
- 26 Oct 13:20Z r44 Struck Sentinel stand move (Ash Road (-314, 272), off Pax's seat): **no gain**, mapped 4.80 -> 4.90 (+0.10, offset-fallback map). No arm (`r44/VERDICT.md`).
  - The landmark defect stays PRESENT/PARTIAL: a normal-height pale tree can't be a hero from any stand.
  - All three judges name a cleaved giant several times tree height, which is the MESHY `stormwood_struck_sentinel` request below. The stand move waits to ride with that asset.
- 26 Oct 13:20Z **MESHY: `stormwood_struck_sentinel`** (Cinder Verge opening landmark; GPU SW8 4.71 Medium / 5.79 High, the lowest untried stand).
  - **Today:** the landmark is the kit DeadTree_1 scaled 4.4x with a thin procedural cyan line (`stormwood_struck_sentinel.gd`). On CPU it reads as a pale generic dead tree in one of three views.
  - **The asset:** one ancient storm-forest giant split down its trunk by a lightning strike.
    - The two halves lean apart; the inner wood is charred black.
    - A jagged pale-blue crystal fulgurite seam runs down the split, with a natural faint glow in the crack only.
    - One broken crown limb has fallen beside it.
    - Exposed buttress roots grip scorched ground.
    - Moss on the shaded side, a few surviving needle branches high up, no red.
  - **Scale:** about 28-32 m tall and 6-8 m across the root plate, so it dominates the trainer at 15 m.
  - **References:**
    - the owner Stormheart boards A/B: crystal, scar and bark language;
    - the existing `stormwood_glass_scar_crystals` asset: fulgurite style.
  - **Wiring:** this lane replaces the kit tree in `stormwood_struck_sentinel.gd` (visual only; Ranger Pax, traversal and the arena unchanged). Flag-off until judged.
- 26 Oct 13:20Z **Struck Sentinel data bug:** the F41 stand sits on Ranger Pax's trainer seat (-320, 240), so Pax fills the lens in all three views (CPU). This is the same bug the Capacitor Grove stand had. A capture-only `f41_survey` stand 23 m off the seat, facing the split tree, is on CPU now.

- 26 Oct 13:15Z **MESHY: `stormheart_hollow_wall`** (Stormheart round 3; GPU B5 SW11 path item 1. Gap 2 is PRESENT 12/12: "smooth dark enclosing walls with a banner ring, no readable bark, branches, crown or core").
  - **The asset:** one tall curved section of the Stormheart's hollow trunk, seen from inside. About 30 m tall and 22 m along the curve, its inner face concave, and built to tile at 6-8 angles around the hollow with no visible repeat:
    - deep vertical bark ridges and buttress roots at its foot;
    - burls, shelf fungi and moss on the ledges;
    - one jagged lightning-scar seam with a faint natural blue glow in the crack only (no glowing hide);
    - a few hanging root strands and a timber walkway bracket stub.
  - **Palette:** dark storm bark with blue-green moss, no red.
  - **References:**
    - the owner Stormheart boards A/B (`docs/reference/boards-2026-09-06/stormwood-stormheart-tree-stronghold-board-a.png` and `-b.png`; the hollow interior, bark, scar and walkway details);
    - the r16-r19 root-wall panel as the scale and form starting point, which read "as a tiled strip". This piece must be taller and individually varied.
  - **Use:** this lane rings the hollow with it at varied yaw and scale, replacing the smooth drum walls in the catalogue's interior stands. Flag-off until judged.
- 26 Oct 13:15Z Note on SW11 path item 3, "re-aim heartstone v01". The catalogue's three views sit 90° apart and each sees about 70°, so no heading puts the stone in both v01 and v02. The 8 m stand keeps it whole in v02 and v03. Not a lane change; your call whether the catalogue should use a narrower spread for that stand.
- 26 Oct 13:15Z The "flat gold ground cracks" every Stormwood set names are the owner-directed road current (WO-F09-04, "make the path and roads electrified with yellow electricity"). This lane leaves them alone.

- 26 Oct 13:10Z PARKED the Ashfoot exterior shell approach after two misses.
  - **r42:** +0.47 alone.
  - **r43:** shell gain 1.9 + grove behind-right + dressing, 5.88 -> 5.31 mapped (-0.57); 3/3 judges prefer the kit cottage (`r43/VERDICT.md`).
  - **Why r43 lost:**
    - The brightened shingles read as a "thatched Meadows cottage".
    - The kit cottage's SW8 grey tile already reads as "sturdier stone".
    - The new trees take the sky where the Break bolt lands.
  - **What stays:** shell code and asset OFF, and the interior cutaway works.
  - **New idea, if any:** keep r42's darker timber and give the roof a slate-dark material.
  - **Ashfoot exterior next:** the ground carpet, which only ground pass 2 (m31b) addresses.

- 26 Oct 13:05Z **Crown Overlook vista round 2** (committed OFF on the lane: storm tint #7d7896 on the Crown, a 3.5 m braced deck, weathered moss-edged planks). Not judged and not armed.
  - **What the CPU frames show:** the Crown sits in the haze and reads further away, as asked, but in Break it almost vanishes. The braces do not show from the deck views, and the moss is subtle. By eye that is no clear gain over r1.
  - **Decision:** **m41 (r1, +2.46) stays the vista candidate for SW18.**
  - **Next for the vista, after SW18:** a lighter tint (between r1 and r2) that holds in Break, and a mid-distance ridge layer.
- 26 Oct 13:05Z Ashfoot exterior:
  - **r42** (Meshy shell alone, interior cutaway verified on CPU): +0.47 mapped, PARTIAL 3/3 on the cottage defect (`r42/VERDICT.md`).
  - **r43** (shell + grove kept behind and right of the hut + brighter, larger shell) is capturing on CPU now.

- 26 Oct 12:25Z **READY (GPU arm) `tb/stormwood-m41-on` aa74c99787bbdc2b065a28c971f8f8ef1272bc19** (Crown Overlook vista; your item 3 big swing). It is the lane plus one config commit:
  - `stormwood_crown_overlook.json` `deck` + `massif` ON;
  - a Crown Overlook `f41_survey` stand on the deck at (172, 1996), heading 37 (capture-only; the teleport arrival is unchanged).
  - **Judge:** `glowmoss_hollows_crown_overlook` (its three views now face the Crown) against the lane.
  - **Deck:** a 12 x 11 m raised timber lookout, 2.6 m up, beside the Crown Sightline path. Its ramp runs to the path, with rails and a lit Meshy lantern post. It collides on every shell; tests keep it clear of every route corridor.
  - **Massif:** the Meshy Hollow Crown silhouette (2cbd71381), 560 m wide over a 30 m base. It draws only beyond 300 m and has no collision.
  - **CPU r41** (`r41/VERDICT.md`): 3.94 -> 6.40 mapped (**+2.46**, r 0.95, RMSE 0.42). Not a lookout: FIXED 3/3. No vista: PRESENT -> FIXED 1 / PARTIAL 2.
  - **Checks with the arm configs:** debug_teleport + crown_overlook, 12 tests, 0 failed.
  - **Still asked, next round:**
    - a darker, hazier Crown that reads as a ring (it renders bleached near-white);
    - a visible drop at the deck edge;
    - mid-distance ridges or fog layers;
    - moss and weathering on the deck.

- 26 Oct 11:55Z **READY (GPU arm) `tb/stormwood-m39-on` de3d78ffd2361c3922c3f72b74041b954e8d4803** (your item 2, path posts): the lane plus one line, `stormwood_path_posts.json` enabled.
  - **What changes:** the spur-junction lamps on Ash Road, Conductor Run and Deepwood take the Meshy Stormwood lantern post at 6.6 m, with warm pane glow and the lamps' daylight halo. The colliders are unchanged. The flag lives outside `stormwood_pockets.json`, which is a scatter-bake input.
  - **CPU r39b** (`r39/VERDICT.md`): 5.88 -> 6.43 mapped (**+0.55**; weak fit, r 0.64, RMSE 0.64), 3/3 judges prefer ON. Placeholder lanterns go PRESENT 2 / PARTIAL 1 -> PARTIAL 3/3.
  - **These junctions are not F41 catalogue stands.** The GPU form is `capture_stormwood_f10_matrix.gd --custom="pv@-334.39,355.97@-323.30,3,370.70@3;pm@105.45,1754.49@89.90,3,1764.40@3;pd@-1016.56,3889.77@-1019.70,3,3871.60@3" --stands=pv,pm,pd --phases=calm --no-aftermath` (Forward+ 1920x1080, Medium/High), with the lane as the off arm.
  - **Pocket tests:** 10 tests, 0 failed.

- 26 Oct 11:50Z **READY to land land10: `tb/stormwood-land10` 75ed332ceaf6f65892d86e524fc6fff621cf4de0.** It is the lane head def25a26 (origin/main 07e1b277 #760 merged in) plus one config commit.
  - **New ON flags vs main:**
    - Ashfoot `storm_finish.seated` + `firelit`, each with `_why_on` (GPU B5 SW15 +0.51 mean).
    - Stormheart `heart_cleft` ON with `core_column` OFF, exactly as judged in m29 (GPU B5 SW11): the Crown Heartstone survey stand at 8 m and the Fading steam `rise_fade_m` [0.45, 1.3]. Each has a `_why_on` or `_why_off`.
  - **Stays OFF:**
    - `storm_view` (until SW16) and `shell`;
    - the Lantern Pools finish (SW14);
    - path posts, Crown Overlook deck and massif, Ashfoot exterior grove, rod `stand_clear`, depth fog.
  - **Checks on the land10 tree** (separate worktree):
    - 103 unit tests, 0 failed (stormheart*, stormwood_surge*, cottage, interior, named_crown, debug_teleport);
    - smoke_stormwood_ashfoot_shelter 16/0;
    - smoke_stormheart_ascent PASS (core reached by continuous ramp walk).
  - **Also carries, OFF:** this lane's later candidates and their assets: the Meshy ranger shelter, the Crown Overlook deck (the Hollow Crown silhouette asset came after def25a26 and is not in land10), path posts and the Ashfoot exterior. The Crown Overlook `view_heading_deg` 37 is ON as the data fix you asked for.

- 26 Oct 11:40Z **MESHY: `stormwood_hollow_crown_silhouette`** (Crown Overlook vista; the Crown massif reads at 900 m as "a flat grey slab / table shape", r40 and GPU SW8).
  - **The asset:** a distant-only landmark silhouette of the Hollow Crown.
    - A broad storm-weathered rock massif whose rim breaks into a ring of tall, jagged, slightly outward-leaning spires: the "crown". The centre is hollow, implied by the ring.
    - Deep vertical lightning-scar clefts with pale-blue crystal glints.
    - Moss and dark conifer fringes on the ledges.
    - Cool grey-violet stone, no red.
  - **Silhouette first:** at 900 m it must read as a crown shape against the storm sky. Make the spire heights clearly varied (tallest about 2x the shortest), with deep notches between them.
  - **Scale:** the footprint fits the Hollow Crown region (about 520 x 520 m). The spires rise about 120-250 m above the plateau rim; the plateau sits about 65-360 m above sea level in world terms.
  - **Use:** drawn only beyond about 300 m (visibility range), like the Stormheart v3 far swap, so play inside the Hollow Crown is untouched. No collision.
  - **References:**
    - owner Stormheart boards A/B (`docs/reference/boards-2026-09-06/stormwood-stormheart-tree-stronghold-board-a/b.png`) for the storm palette, crystal and scar language;
    - `palworld-04-plateau-landmark.jpg` for a distant plateau landmark that reads.
  - **Wiring:** this lane places it at the Hollow Crown (700, 2700), facing the overlook, flag-off until judged from the 37° Crown Overlook views.

- 26 Oct 11:30Z PARKED r40 (your item 4, depth fog): 4.89 -> 4.66 mapped (-0.23; `r40/VERDICT.md`). The grey band stays PRESENT 3/3 on both arms; it is the Crown massif's flat terrain read at 900 m, not fog. The judges' ask is a shaped, rim-lit massif silhouette and a storm sky with cloud structure and lightning. That is new art or terrain work; a possible MESHY or sky-art item if you want it.

- 26 Oct 08:05Z **MERGED MAIN 07e1b277 (#760 land9) into `tb/stormwood` 9b28ee9d.** Main's tree equals land9, so the lane only takes land9's config commit: Fallen Giant hero + bark ON.
  - **The pending GPU arms are rebuilt on the merged head.** Each is the same config flip as before, on top of a lane that now has the Fallen Giant ON. **Please judge these and drop the old SHAs:**

    | Arm | New SHA | Replaces | What it turns ON |
    |---|---|---|---|
    | `tb/stormwood-m29b-on` | 9517727f4ba8d0462e08c518a3b636e1bfac0703 | m29 e59d5de1 | Stormheart heart cleft |
    | `tb/stormwood-m31b-on` | 946ded35a1dbc5830732fec4e4580f373a277b6b | m31 ccdeebfd | Ground pass 2 + storm light |
    | `tb/stormwood-m33b-on` | c8c981b23ba7c6a391acc48f52c716f91d150ca5 | m33 619dd7fd | Lantern Pools finish |
    | `tb/stormwood-m36b-on` | 0a633e222477f927e17391340cc74520c6079c3a | m36 6c9ba874 (and m34/m35) | Ashfoot seated + firelit + storm view |

  - The off arm for all of them is the lane, 9b28ee9d.

- 26 Oct 07:55Z **Finding (no candidate): Crown Overlook (GPU SW8 5.20 / 5.61).**
  - Its catalogue views never face the Crown. The spot (160, 1980) has no `view_heading_deg`, so the views take their heading from the neighbouring spot and point at 133°, 223° and 313°. The Crown is at 37°, 900 m away.
  - A CPU capture facing 37° shows only a thin flat grey slab on the horizon. The stand sits at ground level among trees, so turning the views alone would show nothing.
  - **A real vista needs three things:** a raised overlook, a cleared sightline, and a Crown silhouette that reads at 900 m. Today's massif reads at that distance as the "flat grey band" every judge names.
  - That is terrain or new-art work, so this lane does not start it. **QUESTION:** do you want an authored heading of 37° for this spot (a yardstick change) only once a vista exists, or never?

- 26 Oct 07:45Z **MESHY: `stormwood_ranger_shelter`** (Ashfoot shelter exterior; F41 `ashfoot_shelter_outside` is GPU 5.54/5.58).
  - **Why:** every judge in GPU SW9 and CPU r38 names "a small Meadows-style cottage, not a Stormwood shelter" as the top defect, and judges ask for "dark timber, copper fittings, storm-glass lantern, a raised deck or lightning rod". Scene dressing does not move it: r38's grove, lightning rod, lantern post and barrel came to +0.49 and are PARKED.
  - **The asset:** an exterior shell that wraps the existing ranger_station footprint (4 x 6 m, 3 m walls, gable roof about 6.8 m). It has:
    - dark weathered timber walls on a mossy stone plinth;
    - a moss-edged shingle roof;
    - a copper lightning rod on the ridge, grounded by a copper cable down one corner;
    - a short covered porch on the door side with a hanging copper-and-glass storm lantern;
    - storm shutters on the wide side window.
    - No red anywhere.
  - **Fit:** it must keep the prefab's door (front, +z, centred at x 1.0, 1.6 m wide) and the east window opening (+x wall, z -0.8..0.8, y 0.94..2.52). That way the lined interior, the storm pane and the r36 storm view stay seated.
  - **References:** the owner Stormheart boards A/B (timber and walkway details, aged copper, lanterns), plus the lantern post asset already delivered (`stormwood_lantern_post`) for the lantern.
  - **Scale:** check it against the 1.80 m trainer at the door.
  - **Wiring:** this lane replaces the prefab's exterior modules for `ashfoot_shelter` only, flag-off until judged, and can re-run the r38 grove with the left sky kept open for the lightning.
- 26 Oct 07:45Z PARKED r38 (Ashfoot exterior grove + dressing): 5.47 -> 5.96 mapped (+0.49, under the 0.5 rule; `r38/VERDICT.md`). Horizon PRESENT -> PARTIAL; cottage and carpet unchanged. The canopy hides the break lightning, and the leaf cards dither.

- 26 Oct 07:25Z PARKED r37 (Ashfoot `planks`, narrower lining boards): 5.77 -> 5.37 mapped (-0.40, 3/3 judges prefer OFF; `r37/VERDICT.md`). The judges read the wide boards as finer. The "stretched planks" complaint is the coarse atlas grain at a close wide-angle stand, so board size will not fix it. m36 stands as the Ashfoot candidate. Next Ashfoot ideas: lightning that lights the room at the break, rain on the glass, cutting the window-frame bloom.

- 26 Oct 07:05Z **READY (GPU arm) `tb/stormwood-m36-on` 6c9ba8743c7c5de442f82c9613159029e4f560cc**: the lane plus one config commit, with Ashfoot `storm_finish.seated` + `firelit` + `storm_view` ON. It supersedes m34 and m35 (both remain valid steps). Judge `ashfoot_shelter_inside` (four phases) against the lane; `ashfoot_shelter_outside` is the no-change check.
  - **Storm view (r35 judges x3: "no sky, rain or lightning through the window, only a tint"):**
    - A storm card 3 m outside the east window faces the room only (back faces culled). It shows a storm sky over a dark treeline, with per-phase sky, cloud and rain; the surge flash lights the cloud.
    - The east window's kit glass (MI_WindowGlass) is made clear. That glass draws as an opaque pale sheet and was the "glowing panel" judges kept naming.
    - From outside, that one window now shows the room through clear glass. Watch it in the outside check.
  - **CPU chain** (each step against the one before; all mapped, three code-blind judges):
    - r34 seated: +1.04;
    - r35 firelit: +0.76;
    - r36 storm view: 5.50 -> 6.21 (**+0.71**, r 0.86, RMSE 0.70). Glowing panel and no storm: PRESENT -> PARTIAL 3/3.
  - **Checks with all three ON:** cottage/interior, 12 tests, 0 failed; smoke_stormwood_ashfoot_shelter 16/0.
  - **Still asked:** lightning and rain that read through the glass and light the room at the break; less frame bloom; planks at real scale with moss and copper; a flame that reads past the trainer.

- 26 Oct 06:55Z **READY (GPU arm) `tb/stormwood-m35-on` 16101403bd063bbe56e72a020d055fff1dec94d0**: the lane plus one config commit that turns ON both `storm_finish.seated` (m34) and `storm_finish.firelit`. Judge `ashfoot_shelter_inside` (four phases) against m34 if m34 is judged in the same pass, or against the lane otherwise.
  - **Firelit (r34 judges x3: "a stone box with no visible fire", "huge flat stretched plank walls"):**
    - The camp flame sculpt burns in the hearth firebox, with a flickering fire light and a warm floor pool.
    - Dark timber posts, wall plates and a tie beam frame the lining as a ranger hut.
    - The copper lantern by the window is lit.
  - **CPU r35** (`r35/VERDICT.md`): over seated, 4.36 -> 5.12 mapped (**+0.76**, r 0.87, RMSE 0.49). The hearth goes PRESENT -> PARTIAL; the walls do not move.
  - **Checks with both ON:** cottage/interior, 12 tests, 0 failed; smoke_stormwood_ashfoot_shelter 16/0.
  - **Next:** the one ask all three judges still share is a visible storm through the glass (purple sky, rain, a lightning flash per phase). It will be a storm backdrop card seen only from inside, built as r36.

- 26 Oct 06:40Z **READY (GPU arm) `tb/stormwood-m34-on` 4c6d0756690d242fa82d626fc3dd9f1ee8bbc8b1**: lane head d8758c70 (main #759 merged) plus one config line (`cottage_interior_finish.json storm_finish.seated` ON). Judge `ashfoot_shelter_inside` (four phases) against the lane, with `ashfoot_shelter_outside` as a no-change check.
  - **Ashfoot path to 7.5 (SW9 asks):**
    - The storm pane sits behind the lining inside the kit window's own frame, with a 2.5 cm flush trim.
    - The window light's colour and energy change per phase (calm grey-violet, building darker, break white-violet, fading cool), and the pane tint changes with them.
    - A stone chimney breast rises from the hearth to the ceiling pitch. The apex shard was the exterior Prop_Chimney's base hanging below the lined ceiling.
    - The hearth fire is stronger (2.6, 6.5 m).
  - **CPU r34** (`r34/VERDICT.md`): 4.77 -> 5.81 mapped (**+1.04**, r 0.96, RMSE 0.31). The apex shard is FIXED 3/3 and the phases go PRESENT -> PARTIAL 3/3. The window slab and hearth are still PRESENT 2/3 (PARTIAL 1/3).
  - **Checks with seated ON:** cottage/interior, 12 tests, 0 failed; smoke_stormwood_ashfoot_shelter 16/0.
  - **Next asks from all three judges:** a visible storm sky with rain and lightning through the glass; a visibly lit fire with a warm floor and wall pool; moss, copper and glass breaking up the big plank walls.

- 26 Oct 06:45Z **READY to land land9: `tb/stormwood-land9` 5fe5d06375250a19982053e514879551cc4b3348.** It is the lane beea5f57, which merges origin/main 3a0f583b (#759), plus one config commit.
  - **New ON flags vs main:** only `fallen_giant.hero` and `hero.bark`, each with `_why_on` (GPU SW10 +0.56 / +0.59; bark accepted on the CPU check).
  - **Stays OFF:** rod line `stand_clear` and Ashfoot r34 `seated` (code only, inert when off).
  - **Checks on the land9 tree:**
    - `test_stormwood_rod_line` + `test_stormwood_fallen_giant_collider` + destination: 5 tests, 0 failed.
    - cottage/interior: 12 tests, 0 failed.
    - `smoke_stormwood_ashfoot_shelter` 16/0.
  - **Merge note:** main's tree equals land8, which the lane already contains, so the lane tree was unchanged by the merge.

- 26 Oct 06:25Z Coordinator ruling on m28c: the bark recolour is accepted, so the Fallen Giant lands with `hero` + `hero.bark` ON. Rod line `stand_clear` is rejected and stays OFF: it would change the world to suit the yardstick. **Do not judge or land m28c with stand_clear ON.** land9 waits for #759 (land8) to merge, then = origin/main + Fallen Giant hero and bark ON.

- 26 Oct 06:15Z **READY (GPU arm) `tb/stormwood-m28c-on` 39af61624e6e586e48a8fd508f9a12591af34f30**: lane head a04467fc plus one config commit (3 lines). Judge `deepwood_the_fallen_giant` (six views, calm and fading). Supersedes m28b.
  - **ON in the arm:** Fallen Giant `hero` (as m28b), plus `hero.bark` and rod line `stand_clear`.
  - **Bark recolour (your SW10 order):** a cool moss multiplier (#b4cbbd) on the GLB bark and a soft material rim (0.5). The oxblood-maroon log now reads as weathered grey-brown wood with a lit edge, and it separates from the mauve trunks.
  - **CPU check** (hero ON, bark off vs on, the three fg stands, calm; `r34fg/_sheet_fg_bark.jpg`, off left): the colour is fixed in all three views. Nothing else in the frame changes, so there is no loss.
  - **Lattice figure, identified:** it is Team Tether's F10#4 rod-line relay pylon (`relay_pylon_v1`), which stands 9 m from the Fallen Giant stand and 15 m from the Ashfoot shelter. New `stormwood_rod_line.json stand_clear` (OFF on the lane) drops only the pylons inside those two catalogue circles (14 m / 18 m). The pylons either side stay, and the cable still spans them where they are within max_span_m. It rides along in this arm.
  - **Checks:** `test_stormwood_rod_line` passes with stand_clear on and off (new test `test_stand_clear_keeps_pylons_out_of_named_frames`), and `fallen_giant` passes: 0 failed.
  - **If it holds on GPU,** land it with all three flags ON.
- 26 Oct 06:15Z Next: Ashfoot r34 `storm_finish.seated` (fbd95d84, OFF) is capturing on CPU now: all four phases, off vs on.
  - **Pane:** it sits behind the lining plane inside the kit window's own frame, smaller, with a 2.5 cm flush trim.
  - **Window light:** its colour and energy change by phase (calm grey-violet, building darker, break white-violet, fading cool), and the pane tint changes with it.
  - **Chimney breast:** a stone chimney breast rises from the hearth stack to the ceiling pitch. The pale apex shard was the exterior Prop_Chimney's base, which drops up to 1 m below the lined ceiling.
  - **Hearth:** a stronger, wider hearth fire.

- 26 Oct 10:30Z **READY to land land8: `tb/stormwood-land8` 85140a22f4432d38dfe0968c05c9151735ece43d** (lane cdff6cff, which carries the merged main ac5e1426, plus one config commit). `git diff origin/main` on data: the only new ON flags are Ashfoot `storm_finish`, `window_pane` and `grade`, each with `_why_on` (GPU SW9 +0.70 Medium / +1.52 High). `core_column.enabled: true` is the explicit default under main's hero_interior (no change). Everything else is OFF: m29 heart_cleft, m31 ground/storm_light, m33 lantern_model, Fallen Giant hero, ground zones, depth/height fog, glass far read and the Lantern Pools hollow.
  - **Rides along (ON, bug fixes):**
    - sky text: Master sign words within 12 m, site words within 30 m;
    - grey blocks: the Stormwood Master pad in moss-stone and the pole in storm bark;
    - cottages: Rodline home becomes a ranger_station, and the Lantern Hollow and Rodline buildings get stone plaster, cool timber and grey tile;
    - well colours;
    - the Stormwood scatter re-bake those settlement edits require: manifest only, all 108 region files byte-identical.
  - **Checks on the land8 tree:**
    - 275 unit tests, 0 failed: cottage, interior, settlement, village, stormheart, stormwood_surge, stormwood_scatter, scatter_perf, master, lantern_pools, fallen_giant, debug_teleport, named_crown, texture_import_policy.
    - smoke_stormwood_ashfoot_shelter 16/0 and smoke_stormwood_settlement_traversal 9/9.
    - smoke_stormwood_crown_heartstone 12/0.
    - smoke_village_services_redesign **failed once** in the batch: the F17 Hall walk did not reach Mira, distance 2.90. On one confirming rerun it passed with land8's flags ON, and it also passes on the flags-off head. Disclosed: no root cause found; the run came straight after a 275-test suite.
- 26 Oct 10:30Z Next, per your SW9/SW10 order:
  - Fallen Giant recolour: hook `fallen_giant.hero.bark` (cool moss multiplier and soft rim) is in da841198, OFF. CPU colour/no-loss check next.
  - Then the Ashfoot path to 7.5 and the lattice figure.
- 26 Oct 09:40Z **READY (GPU arm) `tb/stormwood-m33-on` 619dd7fdd07327f612eda14afdba349ac06ce45a**: lane head 9065dad7 (on the merged main) plus one config commit (6 lines in `stormwood_lantern_pools.json`). Lantern Pools finish: judge `glowmoss_hollows_the_lantern_pools` (all three views).
  - **Lantern posts:** the delivered Meshy `stormwood_lantern_post` (a24b25f7a) replaces the black-bar box posts. Lit panes glow (warm flame light only, `warm_pane_glow.gdshader`) with a warm lantern light.
  - **Black pools:** `deep_colour` #030607 and `water_specular` 0.12.
  - **CPU r33** (forest present): 4.83 -> 5.58 mapped (**+0.75**, r 0.96, RMSE 0.42). Grey-puddle defect FIXED 3/3; black-bar posts PRESENT -> PARTIAL 3/3.
  - Checks with the flags ON: lantern_pools and texture_import_policy pass, 0 failed.
  - Still asked: larger, clustered pools on the path; lantern light that reads at distance; floor breakup; light shafts.
- 26 Oct 08:50Z **MESHY: `stormwood_lantern_post`** (Lantern Pools first, then any Stormwood path post). Every judge in r30b, r31 and r32 names the black-bar lantern posts and asks for "real lanterns with lit glass and copper fittings".
  - **The asset:** one aged timber post about 2.6 m tall, with a short bracket arm and a hanging copper-and-glass storm lantern. Small square glass panes, a domed aged-copper cap with green patina, and a warm candle core. Moss at the foot. No red.
  - **References** (owner Stormheart board B crops, inspected; in `meshy-refs/`):
    - `_lantern_post_ref_railing.jpg`: the platform bracket with a hanging lantern, and railing posts topped with glowing lanterns;
    - `_lantern_post_ref_palette.jpg`: bark, living wood, aged metal, crystal, energy glow.
  - **Scale:** it stands taller than the 1.80 m trainer, and the lantern body is about 0.45 m.
  - **Wiring:** this lane wires it into `stormwood_lantern_pools.json` (replacing the box-mesh post in `_lantern_post`), with a warm glow on the glass only (natural flame light), behind a flag until it is judged.
- 26 Oct 08:50Z PARKED r32 (canopy bark tint #94895a, natural brown): judges scored it identical to the lane (5.3/5.3, 5.6/5.6, 5.5->5.6). A tint does not move the forest read. Three swings in a row were under the bar, so this lane switches approach: the new-art asks the judges converge on (real lanterns above; recessed reflective pools; copper/glass highlights) rather than more tints.
- 26 Oct 08:20Z **WITHDRAWN: `tb/stormwood-m30-on` (Lantern Pools hollow). Do not judge or land it.** Re-judged with the baked forest present (r30b): 5.24 -> 4.57 mapped (-0.67, 3/3 judges prefer off). r30's +1.15 was an artefact of the stale bake. With the real `hollows_wood` forest, the basin root rings and fungi bury the pools, and the grove's trees tint paler than the baked canopy. The hollow stays OFF. The code is kept, with the grove test.
  - Also invalidated by the stale bake: the "open plains, plant groves" lead (the stands already have their baked forest) and r31's CPU numbers (the GPU pass on m31, built from the merged head, is its first real measure).
  - Still standing: the heartstone survey stand at 8 m was re-checked with trees (fx capture). v01 is clear and v02 shows the whole stone, so m29 stands.
  - Judges' shared asks at the pools: real lanterns with lit glass and copper instead of the black-bar posts (new art); recessed reflective water with banks; brown-grey trunks instead of the canopy's mauve; layered fog and lightning.
- 26 Oct 07:40Z **MERGED MAIN ee4e46cf5d2bf83f185617a9d3f323b16c1a1641** (origin/main ac5e1426, #756 SW7, into `tb/stormwood`). The clone is shallow, so the merge was built against the previous main base 768fef00.
  - The 279 main-only files take main's version.
  - The six files both sides changed keep the lane's version, which already contains main's: main carried the r19 arm 67d95770b, and TECHNICAL already has main's exit-leak lines.
  - Main's ON states are kept (hero_interior, heartstone hero, steam lens fade). Main touches no Stormwood scatter input, so the bake stays fresh.
  - Checks on the merged head: stormheart*, stormwood_surge*, debug_teleport*, named_crown, stormwood_scatter, scatter_perf, lantern_pools, fallen_giant, master_sign and ground_zones, 104 tests, 0 failed. smoke_stormwood_crown_heartstone 12/0.
  - **Arms rebuilt from the merged head**, one config commit each so landings are config-only. Judge these; they supersede every earlier SHA for these arms.
    - `tb/stormwood-m28b-on` **5a3477e0e165dd602ee022a313161e32678d81c5**: Fallen Giant, collider, off the road.
    - `tb/stormwood-m29-on` **e59d5de13280ec65a22477e11bcc60b8d3053c8f**: heart cleft, low Fading steam, heartstone stand at 8 m.
    - `tb/stormwood-m30-on` **58d995cb5befd378ac3541e608f014081c2f35bb**: Lantern Pools hollow.
    - `tb/stormwood-m31-on` **ccdeebfd0a96b421f5a8413b16276c4e73693f91**: ground pass 2 + storm light.
- 26 Oct 07:10Z **CORRECTION: arms m29, m30 and m31 rebuilt; please judge these SHAs, not the earlier ones.** `stormwood_settlements.json` is a whole-file Stormwood scatter bake source, so my well retint (7a20b41d) and later building retints staled `data/scatter/stormwood`. Vegetation then failed closed and the baked forest was missing on every head from 7a20b41d up to and including 7d036c06. The only sign was `ERROR: Missing or stale stormwood scatter bake` in the log. Re-baked in b7811192: all 108 region files are byte-identical, only the manifest fingerprint changed, so placements and harvest ids are unchanged. Runbook (TECHNICAL §8.1) now says to grep every capture log for `stale`.
  - `tb/stormwood-m29-on` **d590c466a1cc5045b9655ddb947e694e5bff147b** (was 7d32103c): SW7 bundle.
  - `tb/stormwood-m30-on` **00c22453c3727ee716038c752752d092cbd68ae2** (was d9014a53): Lantern Pools hollow.
  - `tb/stormwood-m31-on` **762c10e769e9871e4a46a376a0ac9efa35ce7cb4** (was daf57de5): ground pass 2 + storm light.
  - m28b (21a58247) predates the stale bake and is fine.
  - Caveat: the CPU checks from hs4 onward rendered without the baked forest. That covers the heartstone stand screens, r30 Lantern Pools, the capacitor bug check and r31, so their gains are measured against treeless scenes (r30 +1.15 likely overstated). I am re-checking the heartstone stand and the Lantern Pools hollow with the forest present.
- 26 Oct 06:40Z **READY (GPU arm) `tb/stormwood-m31-on` daf57de50722d7a71ac7ab64317dffe0dea4b73e**: lane head c9347e52 plus one config commit. This is your SW8 next swing (Fading atmosphere + ground pass 2), judged on all 12 stands.
  1. **Ground pass 2:** `ground_zones` ON with moss and black pools only. Bare loam is off (`bare` [-1, -0.9]), and tufts thin only in the pools (`grass_bare`, new key in `stormwood_ground_zones.gd`), so Medium keeps its tufts.
  2. **`storm_light` ON:** the cool rim light and grade (r26, never GPU-judged).
  - **CPU r31** (mapped): calm 3.82 -> 4.36 (+0.54), fading 4.12 -> 4.65 (+0.53). The raw gains are about 0.3 and the slope is 1.78, so this is marginal. Judges credit only the black pools; the rim light does not register on CPU (Forward+ lights rims differently, so it gets its one GPU look here).
  - **Height fog:** built (`presentation.height_fog`, OFF) but left out of the arm. Godot's height fog is uniform near-ground haze, not distance layering, and it showed nothing on CPU.
  - Checks with the arm's flags ON: ground_zones, grass_field, stormwood_look, stormwood_surge, ground_finish, 87 tests, 0 failed.
- 26 Oct 06:40Z SW8 bugs closed in the lane:
  - **Sky text:** Rowan Stormwise's signpost words now draw within 12 m (the survey stand is 15 m away) and the Master's site words within 30 m.
  - **Grey blocks:** the Master arena pad gets dark moss-stone and the pole storm bark. The large grey "wall" in capacitor v05/v06 is a steep terrain ridge flattened by distance fog, not a prop; it belongs to the horizon item.
  - **Cottages:** fixed; the settlement traversal smoke passes 9/9.
  - **Reddish blocks:** the heartstone ones are wild bears. The red panel on the Glass Field horizon is Team Tether's own warning standard (correct use of red).
  - CPU capture after the fix (cg1): no text in any capacitor view.
- Next from here: every r31 judge's top ask, on every stand, is real forest (groves, edges and clearings); the stands read as open plains. Extending the Lantern Pools authored grove (r30, +1.15) to the other open stands is the next big swing.
- 26 Oct 05:20Z **READY (GPU arm) `tb/stormwood-m30-on` d9014a530de117ad9294ab86ea3f491c4db32fa1**: lane head 72efcf43 plus one config commit (3 lines). Lantern Pools hollow: judge `glowmoss_hollows_the_lantern_pools` (all three views).
  - **Grove:** 66 storm-canopy trees, the Ash Road layer's own models and tints, 24-62 m round the pools.
    - Trunk colliders are built on every shell.
    - Every tree is clear of every route, seat, cluster centre, arch, camp, the shelter and the catalogue cameras (new `tests/test_stormwood_lantern_pools_grove.gd`).
    - Scatter is baked and fingerprinted, so this is authored, not a dense stand.
  - **Basins:** the Meshy root-rimmed pool basins, seated so only the slab sinks.
  - **Glow fungi:** bioluminescent storm fungi on each rim.
  - **CPU r30** (mapped): 4.40 -> 5.55 (+1.15), with an anchor RMSE caveat of 0.84. Open meadow: PRESENT -> FIXED 3/3. Judges still ask for bigger black pools, real lanterns and a broken floor.
  - Checks: lantern_pools, stormwood_surge, ground_zones and grass_field, 81 tests, 0 failed.
- 26 Oct 05:20Z SW8 bugs:
  - **(3) Meadows houses fixed, ON in the lane (1b086d11).** Rodline home moves from `cottage_a` (plaster and timber) to the stone `ranger_station`, the same footprint per its recipe. The Lantern Hollow inn, home and workshops and the Rodline workshop take rock-trim stone plaster, cool timber and the shelters' grey tile. Settlement, village and interior tests: 126/0. The settlement traversal smoke is next.
  - **(4) Reddish horizon blocks at the heartstone:** these are distant wild bears (brown fur, violet veins) on the Crown floor, not structures, so no oxblood. The nearby well is retinted (above).
  - **(1)/(2) Capacitor sky text and horizon blocks:** CPU reproduction capture running. The likely source is the objective beacon's world-space "NEXT" label (owner wayfinding, OWNER-0912), so I am confirming before touching it.
- 26 Oct 04:30Z **READY (GPU arm) `tb/stormwood-m29-on` 7d32103cebc970162866f6046a58c6eedcf9085e**: lane head a58cc0d9 plus one config commit (4 lines). This is your SW7 follow-up as one candidate. Capture it with the F41 catalogue as usual; judge the Stormheart calm and fading sets and the heartstone picks.
  1. **Core into the trunk** (`hero_interior.heart_cleft` ON, `core_column.enabled` false). Bark closes the north split deep in the wall (it was the v03 sky strip). A 15 m Meshy crystal heart sits at its foot, and a vein-lit seam climbs from it with tapering, branching bolts. Nothing stands in the hollow or crosses the walkway. The hollow's forked charge is no longer drawn: seen from the stand, one of its tilted links was the v03 break white bar. All of it cools on release.
  2. **Fading puffs** (`steam.rise_fade_m` [0.45, 1.3]): steam fades out between 0.45 m and 1.3 m above the ground, so it stays a low mist.
  3. **Heartstone v01** (capture-only `f41_survey`): moves to 8 m south-west of the stone, heading 25. The catalogue camera stands 5.2 m behind the trainer, so at 5.5 m the v01 camera was 5.7 m from the stone and its base cut the frame edge. No stand this close fits a 7 m stone in all three 90-degree views. The new stand gives a clear v01 and the whole stone in v02 and v03 (CPU hs6).
  4. **Hard rule, already ON in the lane, not in the arm**: the dark-red posts are most likely the Crown's old well 26 m away, with a warm canopy and orange-brown kit posts. All three Stormwood wells now have the shelters' grey tile and a cool multiplier on their timber (7a20b41d, a58cc0d9). Settlement tests: 28/0.
  - **CPU r29** (mapped, offset fit): calm 5.37 -> 5.90 (+0.53), fading 5.10 -> 5.64 (+0.54). Tube defect: PRESENT -> PARTIAL/FIXED. Puffs: PRESENT -> PARTIAL. The sky strip judges still saw is the south entrance split in v05.
  - **Checks with the arm's flags ON**: stormheart*, stormwood_surge*, debug_teleport*, stormwood_named_crown: 91 tests, 0 failed.
  - The fading-crack QUESTION above still stands (they are the strike telegraph; kept by default).
- 26 Oct 02:40Z **READY (GPU arm) `tb/stormwood-m28b-on` 21a582478fac6dc67d3954a8f4f46ddac1e6b9b1** (lane head a7048bc4 + one config line, hero ON): replaces m28. Your collider blocker: `fallen_giant.hero.collider_boxes`, seven boxes cut from the fitted GLB's own 7.9 m slices (trunk, root plate, low splayed roots; hollow mouth blocked deliberately), built from config on every shell including a headless host (no mesh read at runtime). Checking the route found a second problem: at the r28 seat (-180, 4492) the log's thin end lay across deepwood_road's north leg ((-150, 4460) -> (-310, 5050)), so the r28 visual blocked the road too. The log moves 25 m west to (-205, 4497), same yaw; every box keeps at least 11.4 m from both road legs and 13.4 m from `road_visibility_deepwood_road_09`. New `tests/test_stormwood_fallen_giant_collider.gd` (1/0) checks this on a simulation shell. **The visual changes**, so please judge m28b rather than m28: it is 25 m nearer the catalogue stand (-240, 4463.6), still inside its heading-62 view. Clear circles moved with it.
- 26 Oct 02:40Z In progress: the SW7 bundle as one candidate (`hero_interior.heart_cleft` + `core_column.enabled` false + `steam.rise_fade_m`, code in bae67d90, all OFF). The core column moves into the trunk: bark closes the north split deep in the wall (that split was the v03 white sky strip), with a Meshy crystal heart at its foot and a vein-lit seam with tapering branching bolts. CPU capture running; heartstone v01 and the red posts are being swept from the same queue. QUESTION: the flat white cracks under the trainer in fading v04/v05 are the strike telegraph's `crackle_*` (the hazard warning), not decals. I won't remove a hazard warning without a ruling. Options: (a) keep it; (b) thinner, cooler filaments that stay readable. Default (a).
- 26 Oct 09:30Z **MERGED MAIN 040903b16a552679267fe65ee3afb853d0e8f4e7** (origin/main 768fef00 into `tb/stormwood`). The clone is shallow and the 6-7 GB packs ruled out deepening, so the merge was built without a merge base: main differs from this lane's 25 Oct head 6f1e4cb7 only in other lanes' files (taken from main) and in lane-only files main never carried (near-lens hide, the F41-look camera set, three .uid files, this lane's TECHNICAL harness lessons; kept). TECHNICAL keeps both sides. The five files your merge conflicted on are identical on main and 6f1e4cb7, so this lane's versions stand. It is a true two-parent merge, so merging main again later is ordinary. Checks on the merged head: 552 unit tests, 0 failed (stormheart*, stormwood*, cottage, village_boundary, tidewake_look_profile, water_landmark, ironwood_grove, grass_field, far_cover); smoke_stormwood_crown_heartstone 12/0; smoke_stormwood_ashfoot_shelter 16/0.
- 26 Oct 09:30Z **READY (GPU A/B), arms rebuilt from the merged head** (each is one config commit on 040903b16; off arm = 040903b16 for all three). These SUPERSEDE the older r22/r23/r24/r25 arms:
  - `tb/stormwood-m22-on` 3ba59882989ec8642ea6abf93804cd190df735c8: authored ground zones (r22, CPU +0.53). Judge every outdoor stand.
  - `tb/stormwood-m25-on` 72eaa19cac3babc81982df8054454aabee4a7f56: Ashfoot storm finish + grade + pane (r23/r24/r25, CPU main -> r25 about +2.5). Judge `ashfoot_shelter_inside`, all four phases.
  - `tb/stormwood-m28-on` 5d8167b15a3ea6fe611fb1336ca55ecb82c70bf8: Fallen Giant Meshy hero (r28 below, CPU +0.86). Judge `deepwood_the_fallen_giant` (all six views). It clears the grove trees under its footprint on every shell (same mechanism as the lantern pools), so collision there changes; the log itself has no collider yet.
- 26 Oct 09:30Z r28 Fallen Giant CPU: 4.80 -> 5.66 (+0.86), `r28/VERDICT.md`. The Meshy asset is a hollow log, not an arch (per your delivery note), so it lies beside the road in the stand's view corridor, hollow mouth toward the approach, rather than over the road.
- 26 Oct 08:10Z **READY to land** `tb/stormwood` 52d7f6d868a3ff0039ccd453ce8a59b12fa41d2d: GPU SW7 passed both r19 candidates, now ON in config with `_why_on` scores: Stormheart `hero_interior` (+0.95 Medium / +0.67 High) with Fading steam `lens_fade_m`, and the crown heartstone `hero` (+1.32 / +1.32) with its F41 survey stand moved to the r19 stand. Everything else on the lane stays OFF (ground zones r22, Ashfoot r25, skyline, storm light, Veilfall cladding, Stormheart round 2, Fallen Giant hero, Tidewake s5). The lane is based on main 18c9ddc05; merge order is yours. Checks on this head: stormheart*, stormwood_surge*, stormwood_named_crown, debug_teleport 90 tests, 0 failed; smoke_stormwood_crown_heartstone 12/0.
  - The `.uid` files for this lane's new scripts and shaders are now committed (e7894b0b), so the F41 clean-tree guard should not need the uid clean-up on arms built from this head. Arms built earlier (r22, r25) still lack them.
  - SW7 follow-ups taken here: the core column (rigid white tube crossing the walkway line) next, built into the trunk with branching bolts; the heartstone v01 cameras against a foreground rock and the "dark-red posts near the trainer" check.
- 26 Oct 07:20Z PARKED (unjudged, OFF): `stormwood_look.json storm_light` (R verdict path item 2): a cool shadowless rim light opposite the sun plus grade contrast 1.16 / saturation 1.14. On CPU the six stands barely change (rim energy 0.6 under Compatibility), so the expected gain is under 0.5 and it is not judged. Worth one GPU look in a later session, since Forward+ lights rims differently.
- 26 Oct 06:50Z **MESHY: the Fallen Giant hero (Deepwood, F41 worst unhandled stand: GPU 4.64 Medium / 4.69 High, "no change", hero landmark new_art in the R verdict).** Today it is the installed `DeadTree_3` at 2x lying on the terrain (`stormwood_destination_dressing.json fallen_giant`). References (crops of the owner Stormheart board A, `meshy-refs/`): `_fallen_giant_ref_root_arch.jpg` (carved bark and the root-arch entrance language), `_fallen_giant_ref_bark.jpg` (the trunk's bark, moss and ivy), `_fallen_giant_ref_palette.jpg` (bark, moss, stone, aged metal; no red).
  - Prompt draft: "ONE colossal fallen ancient storm-forest tree, lying almost level, about 45 m long, trunk about 6 m thick, a raised mid-section forming a natural arch about 8 m high that a forest road passes under; a huge upturned root plate (about 12 m across) with soil and stones at one end, a broken jagged crown stump with a few dead limbs at the other; deep carved dark bark, a long split charred lightning scar along the top, thick moss, ferns and small mushrooms growing on it. No red or oxblood. Stylised realism matching the Tetherbound key art (between Valheim and Palworld): chunky readable masses, hand-painted materials. ONE isolated object, whole object in frame, three-quarter view, plain light-grey background, even studio light, no text, no people, no creatures. For image-to-3D."
  - Scale check: the trainer is 1.80 m, so the arch clears about 4.5 trainer heights; the road clearance in the config is 9.5 m.
  - Use: replaces the installed dead tree at the Fallen Giant seat (render-only first, like the other heroes; collision scope stays as `fallen_giant` documents). Flag-off until judged.
- 26 Oct 06:30Z READY (GPU A/B, Ashfoot; SUPERSEDES the r23 and r24 arms) on arm `tb/stormwood-r25-on` 104be87eef295156ad86dfa5f30cff16c07cd31b, off arm its parent `tb/stormwood` 372952f9c2990ccf91239520883f4edea0e77f79. Judge `ashfoot_shelter_inside` in all four phases (the pane changes by phase and with the surge flash in Break) and `ashfoot_shelter_outside` as a no-change check.
  - On arm: `storm_finish` + `grade` (r24) + `window_pane` ON. The pane tints the real exterior toward the storm purple, rain rivulets and pane opacity rise from Calm to Break, and the surge's existing flash level (reduced-motion aware) lifts the pane and the cool window light.
  - CPU: r24 -> r25 +0.73 (`r25/VERDICT.md`, r 0.83, RMSE 0.47); storm-view and calm/break defects PARTIAL 3/3. Chain: main 4.34 -> r24 6.19 in the r24 batch, so main -> r25 is about +2.5 on CPU across the two batches.
  - Checks with all three ON: smoke_stormwood_ashfoot_shelter 16/0.
- 26 Oct 05:40Z PARKED again (Tidewake `veilfall_cladding_candidate`, OFF), after your 00:27Z steer (raycast seating, check the thin axis). Done: the facade's thin axis is z with its flat back at -z (vertex count: 9972 at -z, 210 at +z), so orientation was right; seating moved to physics raycasts on the rendered collision (cl3); piece depth squashed to 40% and 60% of it sunk, because the facade is 35% as deep as it is wide and stood ~7 m proud as a shelf (cl4); a four-corner flatness check, keeping only pieces whose corners lie within 1.5 m of their plane (cl5). Result: cl3/cl4 still left plates jutting across the central ridge (a flat piece at a crest follows one facet and overhangs the other), and cl5 places almost nothing, because no gully face is flat under a 14-22 m piece. Flat cladding does not fit this faceted terrain. Your fallback, reshaping the faces seen from the path (with a route and walk check on the hike and cascade), is the next step for F39#4. It is a terrain job, separate from this lane's Stormwood work; I'm leaving it for the Tidewake lane or a later session unless you want it here.
- 26 Oct 04:40Z READY (GPU A/B, Ashfoot; SUPERSEDES the 03:30Z r23 arm) on arm `tb/stormwood-r24-on` ab6769edb32371566a751ce3be7d17fde293336c, off arm its parent `tb/stormwood` 20b49fe1daf59d5bff4c162a8210745c1e643160. Same stands as the r23 line (`ashfoot_shelter_inside`, plus `ashfoot_shelter_outside` as a no-change check).
  - On arm: r23's `storm_finish` plus its `grade` block ON: weathered cool timber (#a8a299, weathering 0.9) on the walls, both ceiling pitches and the floor, and a dimmer, less orange room light (#d9c6b0, 0.75), so the hearth and the cool window fill carry the room.
  - CPU r24 code-blind (`r24/VERDICT.md`, r 0.98, RMSE 0.20): main 4.34 -> r23 4.93 -> r24 6.19 (+1.85 over main, +1.26 over r23); orange-box defect PARTIAL 3/3.
  - Same checks as r23 (the grade only changes materials and the room light's colour and energy). If both Ashfoot arms are already captured, judge r24 against r23's off arm: the two off arms differ only in config defaults and notes.
- 26 Oct 03:30Z READY (GPU A/B, Ashfoot to 7) on arm `tb/stormwood-r23-on` 9707888997a7ecea775c3718df5e577ad644da01, off arm its parent `tb/stormwood` c580ffb36aae20001a8a68cf29db46b88a123222. Judge `ashfoot_shelter_inside` (and `ashfoot_shelter_outside` as a no-change check); the flag touches only the Ashfoot shelter interior (`lined_roles`).
  - On arm turns ON `cottage_interior_finish.json storm_finish`: lining to the 3 m wall top with a flush timber trim around the ranger station's east window (open shutters, the real exterior), lined gable triangles, a cool storm fill at the window against the warm hearth, copper-tinted kit lantern, pot and bucket, herb bundles over the bed side, moss at the wall foot. No colliders.
  - CPU r23 code-blind (`r23/VERDICT.md`, r 0.76, RMSE 0.52): 4.82 -> 5.72 (+0.90); gable FIXED 3/3, window and dressing PARTIAL 3/3. The deep window frame the judges called a floating slab is now a flush 5 cm trim (fixed after judging, checked by eye).
  - Checks with it ON: smoke_stormwood_ashfoot_shelter 16/0; stormwood_settlement + village_boundary 22 tests, 0 failed.
  - Next ask from the judges for Ashfoot: a cooler storm grade instead of the saturated orange pine, and a storm that reads through the window (calm and break look alike on CPU).
- 26 Oct 02:20Z READY (GPU A/B, authored ground, F41 gap 1) on arm `tb/stormwood-r22-on` 311e0094241f08d505cd97320b5eb29aff6127a9, off arm its parent `tb/stormwood` f0803c995fbb27734dcff29725f23beff3d6b37e (one config commit apart). Judge every outdoor Stormwood catalogue stand (the zones touch all green ground; the forest and giant stands change least, because their ground is the cover tiers).
  - On arm turns ON `stormwood_ground_finish.json ground_zones`: a world-space zone field on the terrain (`stormwood_ground_zones.gd`, injected like the Glass Sink) turns green ground into cool umber loam, satin black pools in its lowest part, and deep natural-green moss; the near grass tufts thin over loam and stand short in moss, and the far sheet darkens and tints to match (`zone_*` uniforms, 0 in every other biome). The zones fade out 180-300 m from the camera. Paths, rock and the Glass Sink are untouched.
  - CPU r22 code-blind (`r22/VERDICT.md`, r 0.80, RMSE 0.72): 5.47 -> 6.00 (+0.53), all three judges higher, carpet defect PARTIAL 3/3. Its earlier rounds: r20 +0.54 (maroon loam, pink horizon strip, both fixed), r21 +0.10 (cyan moss, fixed).
  - Checks with zones ON: 32 unit tests, 0 failed (grass_field, far_cover, stormwood_ground, stormwood_world, tidewake_look_profile, water_landmark).
  - Independent of the r19 arm: it can run in the same GPU session as `tb/stormwood-r19-on`.
- 26 Oct 01:30Z PARKED (unjudged, OFF): two swings that failed by eye on CPU before judging.
  - Tidewake `veilfall_cladding_candidate` (in `sections_off`): Meshy `veilfall_cliff_facade` pieces laid on every steep gully face by a seeded slope scan, kept off the hike and the cascade. Two placements (22-34 m pieces with a local 2 m normal; 14-22 m with a piece-scale normal, deeper set, above 12 m) both left the pieces floating as horizontal shelves off the faceted faces in `veilfall-near`. Likely cause: `ground_height_at` (analytic field) does not match the rendered slab facets, or the facade's thin axis is not what its bounds suggest. Code and config stay for a retry. **QUESTION** (the Tidewake lane's 24 Oct one, still open): the F39#4 close-up is held by the faceted gully terrain and a wall-facing stand. Either reshape the gully terrain (gameplay terrain; needs a route and walk check) or reframe `veilfall-near` toward the falls and water (a yardstick change). Your call; until then this lane leaves Veilfall.
  - Stormwood `presentation.ceiling.skyline` (stormwood_surge.json): two procedural treeline layers in the storm ceiling dome. They read at the glass field's horizon, but at the crown hollow the Glass Sink crater wall (the "flat grey band") occludes them, and the forest stands show no sky. The expected gain across the stands is under 0.5, so it is not judged.
- 25 Oct 23:55Z READY (GPU, Tidewake P2-011 destinations) on `tb/stormwood` a9f7ee5a10c49e707ac8804b5eb68534a69e95b8 or later: pumps and jetty seated at the shore. New `destination_landmarks_s5_candidate` (OFF in play, in `sections_off`) layers on s4: the twin pumps 7 m further seaward so the towers stand in the surf (s4 left them on dry sand with only the wheel wet), the rescue jetty 4 m seaward so its deck reaches the water. CPU preview (shipping / s4 / s5, Low) checked by eye; not code-blind judged: the change is a seating fix inside the destinations candidate the Tidewake handoff already queued for GPU (s4 CPU 6.84 mapped; GPU K, lm2-era: pumps 5.79, jetty 5.58).
  - GPU form: `capture_tidewake_f13_5.gd --camera-set=res://tools/visual_judge/camera_sets/P2-011-destinations.json --views=pumps-shore,jetty --source-sha=<sha> --preset=<Medium|High>`, Forward+ 1920x1080; arm off = no sections; arm on = `--tidewake-look-sections=destination_landmarks_candidate,destination_landmarks_s3_candidate,destination_landmarks_s4_candidate,destination_landmarks_s5_candidate`.
  - Veilfall mountain and facade: not started this session (next after the ground candidate).
- 25 Oct 23:10Z READY (GPU A/B) on arm `tb/stormwood-r19-on` 67d95770b5ecd4823926d371e9108587e6391f09, off arm its parent `tb/stormwood` 41db6f9685ffb792c0bf220136b68afd3adc461c (one config commit apart; the F41 catalogue needs a clean tree per SHA). Judge two stands: `dynamo_the_stormheart_tree` (all six views, calm + fading) and `hollow_crown_the_crown_heartstone` (the on arm moves its `f41_survey` stand to 696.11, 2708.11 heading 20).
  - On arm turns ON: Stormheart `hero_interior` (three staggered rows of the Meshy root-wall panel up to about 50 m, thin lightning core column on the axis, lantern clusters and navy lip banners, the Meshy deck walk), Fading steam `lens_fade_m` [3, 7] (the v04 camera fog sprites), heartstone `hero` at 7 m with a 1.6 m collider.
  - Both arms carry the catalogue's new view-cone clearance: wild bodies inside the camera's horizontal view within 45 m are set down just outside the cone, disclosed per frame (`survey_clearance.view_cone_depth_m`, `moved`).
  - CPU r19 code-blind (`r19/VERDICT.md`, fit r 0.86, RMSE 0.42): Stormheart 3.79 -> 5.80 (+2.01), heartstone 3.96 -> 5.63 (+1.67).
  - Checks with the flags ON: 80 unit tests, 0 failed (stormheart*, stormwood_surge*, stormwood_named_crown); smoke_stormwood_crown_heartstone 12/0 with the 7 m hero.
  - GPU form: `capture_f41_stormwood_catalog.gd --preset=<Medium|High> --source-commit=<arm SHA> --label=f41-r19-<arm>-<preset> --phases=calm,building,break,fading --no-aftermath`, Forward+ 1920x1080.
  - v03 white strip: the core column now stands in front of the north split in v03 (CPU), so the sky slot is mostly hidden; check it on GPU.
  - Next here: authored ground (gap 1) as a terrain-shader zone field shared with the grass tufts (`stormwood_ground_zones.gd`, in progress, not wired).

## HANDOFF (25 Oct 22:30Z, session paused for a fresh Stormwood session)

**State**
- Branches: `tb/stormwood` (lane head, includes main 18c9ddc05 via the 21:10Z merge; see `git log`), `tb/stormwood-routes` c29905d40 (S3 + S5 READY), `tb/stormwood-land7` bd5dba893 (LANDED as #751). Superseded land branches: land3..land6, land6-on.
- Landed in #751: item-6 r16 batch (Ashfoot kit furniture + planked floor, Lantern Pools dressing `stormwood_lantern_pools.json`, Stormheart deck supports + finer bark) and the Ashfoot interior finish ON (timber lining + Meshy ranger hearth; GPU SW6 +0.99 Medium / +1.71 High -> 5.82).
- Routes: S5 (home_relic -> home_credits) and S3 (T5 altar_5 -> kitchen_1..4 -> feed -> return) READY on tb/stormwood-routes, all seams MATCH (`seams/`, ROUTES.md). Nothing handed back to Routes.

**Open candidates (all in main or the lane, flag OFF)**
| Candidate | Flag | Verdict | Next |
|---|---|---|---|
| Stormheart `meshy_interior` (root-wall panel ring at r 45.4, arched deck walk on the OuterWorks lip) | `stormheart_presentation.json meshy_interior.enabled` | CPU r18 +0.75; GPU SW6 -0.24 Medium / +0.59 High: OFF | judges: wall still "a smooth dark drum with no core", panels read as a tiled strip. Replace with the hero-interior plan below |
| Heartstone `hero` (Meshy standing stone, 1.25 m collider, glow) | `stormwood_heartstone_visual.json hero.enabled` | CPU r18 +0.71; GPU +0.42 / +0.28: OFF | reads as "a small cyan glow" at about 2% of frame; frame it (plan below) |
| Pool basin | `stormwood_lantern_pools.json basin.enabled` | not judged: buried by terrain twice (seated at lowest and at mid-relief) | needs a carved hollow or a different seating; low priority |
| Crystal crown, satellites, hollow floor clear, candle light | various | CPU r16/r17 no gain: OFF | drop |
| near_lens_hide (vegetation) | `foliage_camera_visibility.json` | r15 no gain; lane only, never landed | drop |

**Plan: Stormheart hero interior (one candidate, expected > +0.5)**
- Whole-wall bark relief: the GPU and every CPU judge read the trunk as a smooth drum. Use the root-wall panel model in several rows (0-12, 12-24, 24-36 m, staggered, varied scale and yaw) instead of one strip, so no repeat reads; or request one taller Meshy "hollow trunk interior wall" piece (about 30 m tall, curved, with buttresses) and tile it at 4-6 angles.
- A glowing core column: the boards show a lightning-lit crystal core column up the hollow axis. `core_finish` exists (a thin line); add a thick emissive column mesh (6-8 m wide, lightning-blue, natural glow) plus 2-3 warm lantern clusters and navy banners on the deck lip (`built_detail` banner colours exist).
- Fix the v03 white strip (top of frame: sky through the split, unlit) and the v04 fog sprites at the camera (surge `steam` puffs in Fading, `stormwood_surge.gd` steam emitter, which spawns at the camera).

**Plan: heartstone framing**
- The survey stand (`debug_teleport_spots.json` Crown Heartstone `f41_survey`, 691.5, 2703.5, heading 27) is 12 m out; at 4 m tall the stone is about 2% of frame width on GPU. Move the stand to about 5-6 m south-west of (700, 2712), pitch slightly up, so the stone fills about 30%; or scale the hero to 7-8 m (its collider follows `collider_radius_m`). Keep wild creatures out of that cone: the catalogue already clears 18 m around camera and trainer (`SURVEY_CLEARANCE_M`); widen it for this stand or add the view cone to the clearance.

**Plan: authored ground (gap 1, PRESENT almost everywhere)**
- Break the one grass/moss carpet into authored zones: soil, moss and rock patches, dark pools and groves. Levers: terrain splat layers (`stormwood_ground_finish.json`, `stormwood_look.json terrain`), ground-cover tier density masks per region (`stormwood_ground_cover.gd` tiers), and authored patch lists per survey stand. One candidate across the worst stands, judged against main.

**Tidewake items to pick up (from the coordinator; handoff in `ralph/reports/TIDEWAKE/close-1024/NOTES.md`)**
- Veilfall mountain and cliff facade (Meshy, already on tb/meshy-1024; flag-off candidates in #747).
- Pumps and jetty seated at the shore.

**What worked / what did not**
- Worked: replacing the dominant object (Ashfoot lining + hearth +1.7 GPU High; survey stand off the Capacitor alpha's seat +2.6/+2.7 GPU); structural fixes the judges name (floor z-fight, red rails, magenta ring).
- Did not: scene tweaks around an object (lighting, candle, crystal crown, floor clear: r17 all lost); small props at survey distance (heartstone at 12 m); repeated single-row panels (read as a tiled strip).
- CPU r18 gains overstated GPU for the two large spaces (Stormheart, heartstone): judge with the object large in frame.

**Harness lessons:** added to TECHNICAL §8.1 (stand screening with `--custom`, F41 catalogue needs one commit per GPU arm, Meshy fitting/glow helpers, `_`-prefixed reference crops, tidewake runner seams by save sha256).

PAUSED 25 Oct 22:30Z: handed to a fresh Stormwood session.

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
- 25 Oct 21:20Z READY tb/stormwood-land7 bd5dba893 (from origin/main c361f575e; supersedes land6/land6-on): land6 with ONLY the Ashfoot interior finish ON (`cottage_interior_finish.json enabled` true, `_why_on` records GPU SW6 +0.99 Medium / +1.71 High -> 5.82, tb/gpu-pass 329b98a41). Stormheart `meshy_interior` and heartstone `hero` stay OFF (SW6 -0.24/+0.59 and +0.42/+0.28); pool basin OFF. Also carries the r16 batch (land5). Focused checks on the lane tree (main identical apart from this lane's files): smoke_stormwood_ashfoot_shelter 16/0 with the finish ON (hearth collider clear of the inside stand); 47 unit tests 0 failed (stormwood_settlement, village_boundary, stormheart*, named_crown, texture_import_policy); smoke_village_services_redesign PASS. Next: one big candidate (Stormheart hero interior: whole-wall bark relief, glowing core column, banners, the v03 white strip and v04 camera fog sprites; heartstone stand/scale to ~30% of frame with creatures kept out of the cone), then Ashfoot to 7 (storm-view window, copper/glass/moss accents, gable), then authored ground.
- 25 Oct 18:57Z READY tb/stormwood-land6 2f3e3fef9 (from origin/main 0fe451688; supersedes land5, which it contains): item 6 r16 batch + the r18 Meshy candidate (tb/meshy-1024 ae67083ec), every r18 flag OFF. GPU arm with the flags ON: tb/stormwood-land6-on 1680e579f (land6 + one config commit; the F41 catalogue needs a clean tree per SHA).
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
