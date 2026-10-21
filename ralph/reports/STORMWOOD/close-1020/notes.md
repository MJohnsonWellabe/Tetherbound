# Stormwood lane, close plan from 20 Oct 2026 (F41, F26#3)

Renderer for every capture here: Godot 4.7 Compatibility (opengl3), Mesa llvmpipe, CPU, 1920x1080, Xvfb. Owner rule (17 Oct): a CPU three-judge Bar A mean of 6.7 or above counts as met, "CPU-provisional", until a GPU pass confirms 7.5.

Capture: `tools/capture_stormwood_f10_matrix.gd` (same five stands as `camera_sets/F41-look.json`, the only Stormwood matrix script that runs without a Forward+ preset) plus three fixed custom stands, used unchanged every round:
`--phases=calm,break --custom="reverse@-300,4420@-350,4,4330@-2;heart_near@-100,5330@-100,80,5470@18;hollows@-500,1550@-460,3,1640@0"`, aftermath pass on. 24 frames per run; about 33 min.

Judging: three code-blind general-purpose subagents. Each gets two shuffled sheets (X/Y, 8 stands x Calm/Break/aftermath), the Stormwood boards, the key art, the Palworld references and the written §4.1/§4 look bar. No code, diffs or labels.

## F26#3 — unrun
Needs matched High and Medium (Forward+) captures on a GPU. Forward+ does not run in this container. Recorded as unrun; not attempted.

## Round 1 (21 Oct, about 03:45 CT)
- Baseline: main 2124b1f6c, all candidates OFF.
- Candidate: shared look ON, Voltcap finish ON, Glass scar relief ON, fallen giant ON. Moss grass cover denser and cooler (density 0.16->0.55); bark retint lighter (#8f9580->#b3bfa6); slate roofs on the four Stormwood ranger stations. They were raw terracotta and read as oxblood beside the Stormheart.
- Bar A: baseline 4.2 / 4.6 / 4.3 = **4.37**; candidate 4.6 / 5.0 / 4.6 = **4.73** (+0.37). Bar B: 3.9 / 4.2 / 3.8 = 3.97 vs 4.3 / 4.5 / 4.1 = 4.30. All three judges preferred the candidate.
- Common defects (all three judges): the Stormheart reads as a plain pale trunk with a ladder and a rust strip, and needs new art; Break crushes the forest stands to near-black; pools are matte lilac slabs with hard edges; bare brown ground with sparse blades; generic meadow broadleaf trees; the rod cable reads red; a hot-pink bush on the Hollows horizon; the Glass Field stand shows no readable scar; the fallen giant doesn't read.
- Bug found and fixed: `stormwood_look.gd` `_process` typed a freed streamed node ("previously freed instance" script error). Now checked before typing.

## Round 2 (21 Oct, about 05:00 CT)
- Candidate = round 1 plus: moss terrain albedo (installed `meadow_grass_Color`, cool tint) on the dominant soil and grass slots; storm phase ambient lifted (Calm 0.6->0.9, Building 0.45->0.72, Break 0.5->0.72, Fading 0.58->0.88; aftermath stays 1.0, the "no ambient boost" contract); non-Break canopy shadow floor 0.68->0.55 (Break stays fully hard); cooler canopy leaves; copper cable #b8733a->#c98b52; darker damp ground; harvest bushes wear the scatter leaf policy (committed fix).
- The capture hit the tool's 1-hour limit; 21 of 24 frames (no aftermath for heart_near, hollows, reverse). Judged on the 21 matched frames with the baseline cut to the same set.
- Bar A: baseline 4.4 / 4.3 / 4.6 = **4.43**; candidate 5.1 / 4.6 / 5.2 = **4.97** (+0.54 over the matched baseline, +0.24 over round 1's best of 4.73; the first round gaining under 0.5). Bar B: 4.27 vs 4.40.
- Named: the moss now reads as saturated Meadows lawn and should be cooler and darker; the forest still crushes to black in Break; the trunks are flat cones; the pools are faceted lilac slabs; the Stormheart needs new art and its rust strip reads near oxblood; the rod cable still reads reddish; the pink object on the Hollows horizon is not a harvest node; the strike telegraph is a flat magenta ring in 1b.
- Conflict, not changed: the 1b magenta disc is the F10#3 strike warning (met with this fill; a thinner outline previously read as a target selector). F41#5's "no flat magenta rings" and F10#3 pull opposite ways; raised with the coordinator.

## Round 3 folded into round 4
- Round 3 = round 2 plus: a baked brighter bark texture (`derived/Bark_TwistedTree_lift175.png`, from the installed bark) with a mossier tint; moss cooled and darkened; depth haze per phase (aftermath stays under a quarter of Break); black wet-soil pools; taller, brighter Glass Field shards (`shard_finish`). Its Calm forest frame showed textured, readable trunks and black pools. A Break bolt wait took 22 min on llvmpipe, so the run was stopped and folded into round 4 (one batch per round).
- Round 4 = round 3 plus the coordinator's Meshy set from tb/meshy-props: Stormheart cand3 as the far silhouette (`meshy_hero`; the procedural hollow shell returns within 75 m), giant_tree_a/b on the giant_canopy layer (scale 23–28) with the Deepwood giant share 5%->15%, relay_pylon v1 on the rod line (9 m), and the soft strike telegraph (`soft_style`, coordinator ruling: same hue and timings).
- F10#3 telegraph tests with soft_style ON: test_stormwood_strike_countdown 4/0, test_stormwood_b_surge_phase_bolt_hold 4/0.
- On adoption, test_stormwood_surge_presentation (52 tests, 3 fail with the candidate): Break fill must be strictly lowest (Break ambient set to 0.68); the Calm shadow-floor assertion pins 0.68 and should read the authored config value; the pin-off path must disable the look profile, which forces the hour pin. test_stormwood_vegetation_palette pins the bark tint, and test_vegetation_shared_retint pins giant==storm canopy models; both are config-identity checks to update with the adopted values.

## Round 5 (21 Oct, about 07:25 CT)
- Candidate = round 4 with the Meshy giant trees grounded. Meshy GLBs are centre-origin, so round 4 had buried them by about 24 m; the new vegetation `height_offset` layer key fixes that. Round 4 was not judged.
- Real fight added: `tools/phase2_capture_stormwood_fights.gd --ids=glass_field_alpha --seconds=14 --interval=2.0 --fixed-fps 20` (production Engage path, pilot input, disclosed fixtures), 26 frames; six on the fight sheet. Candidate only; no baseline fight.
- Bar A: baseline 4.6 / 4.5 / 4.6 = **4.57**; candidate 5.6 / 5.5 / 5.9 = **5.67** (+1.10 over the matched baseline, +0.70 over round 2's best). Bar B: 4.20 vs 5.00. Fight sheet Bar A 5.8 / 6.0 / 5.6 = **5.80**.
- Named: a camera-near giant root at the reverse stand and a near-lens ghosted trunk at the forest stand; tiling, saturated meadow-green ground; the Stormheart's blue cotton-candy canopy and translucent cyan base sheet; the rod cable still reads oxblood; Break forest still near-black; the pink Hollows blob; fight lane telegraphs are flat magenta outlines (fights tell family); the fight camera gets occluded by foliage at impact; the Glass Field shards look floating.
