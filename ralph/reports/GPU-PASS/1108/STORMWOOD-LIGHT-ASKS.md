# STORMWOOD-LIGHT-ASKS: what GPU judges asked for on light, fog, sky and bolts (8 F41 rows)

LANE-SCOUT, 11 Nov 2026. Read-only brief for the Stormwood storm-light lane (LOW-HANGING-6TO7 #5).
- **Sources (this folder):** F-stormwood (8–9 Nov High baseline), the G-* Stormwood reports listed in the request, LOW-HANGING-6TO7 #5. G-floor2-dawn-haze-storm-grade is Tidewake (F39#30); it is cited only as a storm-grade technique that won (+0.58).
- **Scores** are GPU High mapped, from the latest report that judged the row. Paired scores from different batches are not on one scale; read gains within a batch.
- **Already on main:** A3 key light (`light_pass_1101` values); de-pink wet earth with thin near rain plus groves (shipped together); bark on `Bark_TwistedTree`; giant-tree sight fade; `charged_1105`. The storm-glow-lines arm shipped on `tb/floor2`.

## Shared asks (build these first)
| Ask | Rows naming it | Judge phrases |
|---|---|---|
| **Per-phase key light and lightning cadence:** white-violet bolts, sky darkens at Break, light shafts | 7 (#2, #4, #5, #12, #13, #8, #19 via the batch-wide note) | "phase key light with white-violet bolts"; "no lightning and no shafts, the sky never darkens at break"; "per-phase key light, fog density and lightning cadence" |
| **Layered storm sky** to replace the flat lilac/lavender card | 6 (#2, #4, #5, #8, #12, #13) | "flat lavender sky card"; "purple sky is built from blocky, faceted polygons with streak artefacts"; "a flat painted band"; "a layered storm sky and lightning" |
| **Layered fog** between near and far, in place of the single purple treeline/fog wall | 5 (#2, #4, #5, #12, #17 batch) | "purple fog wall reads flat"; "no fog layering between near and far"; "flat lavender fog band with a hard white cliff block" |
| **White-violet rim** on dark creatures and villagers | 4 (#3/#6 fight, #8, #13, batch) | "a white-violet rim light to separate the dark bodies"; villagers "glow against the scene" with no rim light |
| **Emission discipline:** eyes and lines, no whole-body wash or bloom blobs | 3 (#13, #6 via Voltarach, #3) | "an effect hull, not a bird"; Voltarach "a gold bloom blob"; "light bulbs" |
| **Value, not darkness:** lift black pools to reflective dark pools with value; cap wet specular | 5 (#4, #5, #8, #12, #13) | "crushes the path to near-black"; "black ground patches read as holes"; "blown specular blot around the trainer" |
| **Rain** thin or translucent, never the brightest thing in frame | 4 (#8, #12, #13, batch) | "thick white sticks"; "Rain streaks are the brightest thing in frame" |

**Lessons that bound the build:**
- **Lift, don't darken.** A darker grade or height fog lost 0/3 on the forest stands (#4 −0.31, #5 −0.22). The brighter A3 key won. Keep near-ground value.
- **Fog glare:** scoped fog put a "bright white lens blob" on the Glass Field (#12 −0.24). Cap fog density and emission there; #19 shares that stand.
- **Write to `light_pass_1101`.** It overrides `storm_light` and the surge sun at runtime, which voided arms a and a2. Check luma before you send an arm to the judges.
- **Rim at fight distance is invisible** (0.00 at two strengths). Cut Voltarach's emissive instead.
- **Red rule.** Not a light ask, but judges keep flagging these: salmon-pink bears (3/3, several reports), salmon/pink trunks, a small red flag in #12 frame 2 on both sides (possible oxblood leak), orange cracks in the rod_line pool (1/3, borderline). Any pink or warm-red light ask goes to cool violet or white, never red. The cottage reads "over-warm orange": cool it.

## Already tried
| Arm | Rows | Result | Parked |
|---|---|---|---|
| storm-light-a (height fog only; key never applied) | #2, #4, #5, #12, #17 | no ship (split: #4 −0.31, #5 −0.22) | height fog on forest stands: yes, as built |
| storm-light-a2 (exposure via `storm_light`) | same | VOID (inert) | — |
| **storm-light-a3** (sun #cfc0ff 2.05, exp 1.5, amb 2.2, rim #c3b6ff) | #2 +0.73, others flat | **shipped** (main) | — |
| storm-fog-scoped-r2 | #2, #4, #5, #12, #17 | no ship (+0.04 to +0.16; #12 −0.24) | fold into a bigger swing only, with Glass Field glare fixed |
| `building_glow_1104` (in-cloud sheet lightning) | #2 | no ship (0.00; invisible on CPU and GPU) | **yes, lever spent** |
| swing-1 wet earth (pink loam) | #4, #5, #12, #17 | no ship (−0.23 to −0.41) | superseded by de-pink |
| swing-2 de-pink + thin rain + matte pools | same | neutral; shipped as base under groves | — |
| **groves** (on swing-2) | #17 +0.55, #5 +0.50, #4 +0.27, #12 −0.09 | **shipped** | — |
| fight rim (arm and armTone) | #3, #6 | no ship (0.00 vs live2) | rim on Voltarach fights: effectively yes |
| storm-light-b line-of-sight fade | #3 | no ship (0.00) | — |
| `charged_1105` | #13 | **shipped** (+0.61) | — |
| charge-lines r1, r2 (line-only accent, far range) | #13 | no ship (−0.62, −0.49) | **yes, parked** |
| stage r3 `creature_ruler_depth` | #13 | +0.82 (staging gain) | — |
| **storm-glow-lines** (cut accent and coat emission) | #13 | **shipped** on `tb/floor2` (+0.64) | — |
| Hesk cap and scarf | #8 | no ship (0.00) | accessory scale: yes |
| distinct bodies (`distinct_bodies_1111`) | #8 | +0.29, 2/3; flag-off, to ride inside this swing | — |
| Glass Sink shards; lip ring (VOID); lip seated on rim | #10 (Glass Field neighbour) | no ship (+0.04, −0.68) | lip: **yes, parked** |

## Per row

**F41#2 Surge phase presentation: 6.15** (A3 arm, shipped; the later fog-r2 batch read A3 live at 5.62, a scale difference). Board 6.10.
- Asks: Calm, Building and Break "differ only in rain density" (PRESENT 3/3); per-phase key light, fog density and lightning cadence; the sky darkens at Break; the sky is "blocky, faceted polygons with streak artefacts".
- Frames: struck_sentinel ×3 (the phase stills). A3's first still, with "visible violet sky lightning and a brighter cloud layer", is the only phase judges credited. Do the same on the other two.
- Tried: a (fog), a2 (void), **a3 shipped**, building_glow (parked), fog-scoped r2 (no ship).

**F41#4 Named destination identities: 6.50** (groves, shipped).
- Asks: "destinations read as similar grass and trees"; layered fog silhouettes in place of the "single purple treeline card"; a storm sky with white-violet lightning. A darker grade "muddies the trunks and path".
- Frames: lantern_pools, crown_overlook, fallen_giant.
- Tried: a (−0.31), a3 (flat), fog r2 (+0.08), swing-1 (−0.23), swing-2 (−0.03), **groves shipped** (+0.27).

**F41#5 Forest ground and distance layers: 6.28** (groves, shipped).
- Asks: "no fog layering between near and far"; "flat treeline band"; ground "darker moss-and-mud" with value, "capped specular on wet pools"; not "crushed" to black.
- Frames: struck_sentinel, crown_overlook, crown_heartstone.
- Tried: a (−0.22), a3 (0.00), fog r2 (+0.11), swing-1 (+0.14), swing-2 (−0.08), **groves shipped** (+0.50).

**F41#6 Named wild danger and opening cues: 6.80** (F-stormwood, FIXED 3/3; no later valid score).
- Asks: Voltarach "over-bloomed into a gold-white mass" (cut emissive and bloom, not add rim); flat magenta telegraphs (3/3, several reports); the grey-blue tiled "missing skybox" behind the canopy on the far side of the Capacitor arena. Live read best when "Voltarach reads strongly against the purple storm sky".
- Frames: `capacitor_alpha-tell1-e-impact` (one frame, shared with F41#3).
- Tried: fight rim (confounded −0.89/−0.99, never re-judged on matched framing).

**F41#8 Named character silhouettes: 5.43 base / 5.72 arm** (G-meshy-f41-8, 11 Nov; board 5.31). G-f41-8 had 6.11, in a different batch.
- Asks (scene, 3/3, the top drag): "crushed black pools covering about half of each frame"; "a flat lilac sky card with no lightning"; villagers "small, over-bright, near-white … no rim light"; thick rain sticks across the characters; salmon-pink bears.
- Frames: inventory frames of elder_maud, rodkeeper_hesk, warden_elect_bryn.
- Tried: Hesk cap (0.00, parked), distinct bodies (+0.29, flag-off; recolour Hesk or Bryn when it rides).

**F41#12 Charged road surface: 6.41** (groves arm, shipped; −0.09 against base 6.50). Board 6.60.
- Asks: A3 lifted the "crushed teal-black" road (+0.27 in arm a); avoid fog glare at the Glass Field; cap the wet specular; thinner rain. Red flag in frame 2 (both sides).
- Frames: lantern_hollow day, glass_field, lantern_hollow night.
- Tried: a (+0.27), a3 (+0.05), fog r2 (−0.24, glare), swing-1 (−0.41), swing-2 (−0.07), groves (−0.09).

**F41#13 Electric creature finish: 6.66** (storm-glow-lines, shipped on `tb/floor2`; matches LOW-HANGING). Other reads: F-stormwood 5.59, rescore 5.00.
- Asks: glow on "eyes and feather-edge or vein lines … no full-body bloom"; "a white-violet rim light"; lightning arcs on the raven. Board colours: a near-black raven with violet-blue charge, and an olive-black cobra with gold veins (not navy, not amber "light bulbs"). Fix the ground and sky under the stand: "black path reads as a void", "flat painted band" sky, over-warm cottage. Sparkit has no visible electric trait.
- Frames: fulgocobra idle, stormraven idle (and hurt), sparkit idle (control).
- Tried: **charged_1105 shipped**, charge-lines r1/r2 (**parked**), stage r3 (+0.82), **storm-glow-lines shipped**. Do not dim the raven body further: the dark body on dark ground lost twice. Judges ask for "a lit, rim-lit body".

**F41#19 Glass Field spike bases: 6.56** (F-stormwood only; PARTIAL, FIXED, PARTIAL).
- Asks: none row-specific in the sources. The batch-wide asks apply (phase key, white-violet bolts, rim, charged emissive, layered fog). Fog glare at the glass_field stand is the known risk.
- Frames: not named in these reports; see manifest-F-stormwood.json.
- Tried: no arm targeted it.

## Suggested arm order
1. **Phase storm-light arm** (data flags in `light_pass_1101` / `stormwood_surge.json`): a per-phase key and exposure (Calm brighter, Break darker sky with lit ground), white-violet bolt cadence, and a layered storm sky to replace the flat or faceted card. Judge #2, #4, #5, #12, #19 and #8.
2. **Layered fog in the same tree,** scoped and capped. Fog goes behind the near ground, never over it. Glare cap at the Glass Field. Fold in fog-scoped r2's scope logic.
3. **Value pass in the same tree:** dark reflective pools with value instead of voids, capped wet specular, thin translucent rain. Ride along `distinct_bodies_1111` plus one villager recolour, a soft villager rim, and a cooler cottage.
4. **Emission arm:** cut Voltarach's gold emissive and bloom (#6, #3). Move #13 toward the board colours with the shipped glow-lines emission level and a rim. Fix the tiled skybox on the far side of the Capacitor arena.
5. Then re-score #13 and #17 under the close-out exception (#17 is at 7.23). Fixes for the salmon bears and trunks, and for the Crown Arch plinth, ride inside any arm above.
