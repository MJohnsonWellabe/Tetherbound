# Code-blind judge — Stormwood forest, rod line, restored sky (F10#4)

Inputs judged: F01–F24 at full resolution (F01, F02, F04, F07, F09, F11–F18, F20, F23, F24 opened at 1920x1080), the four contact sheets, LABELS.txt, ART_DIRECTION.md, the visual-judge SKILL.md method, both Stormheart stronghold boards, the Stormwood creature-roster board, the Palworld frames and the Meadows key art. I judged pixels only and read no code, history or PR text.

## Overall F10#4: **FAIL**

None of the three subjects clears both bars. The restored sky comes closest. The rod line is weakest: nothing in frame reads as a rod-line structure. What is there is a glowing gold route marking painted on the ground.

---

## 1. Forest (F01–F12)

**Bar A (identity): PARTIAL**
- These points carry it. There is a fixed purple storm sky in every frame. The gold electric veins cross the ground (F03, F09, F12). Blue storm creatures read as Stormwood fauna: two wolves in F07 carry a crackle pattern close to the Tanglevolt card, and a spider in F11/F12 is in the Voltarach family. A giant pale trunk mass sits on the horizon (F11, F12).
- These points sink it. ART_DIRECTION asks for giant old trunks, wet roots, moss lit from below, fungi, black reflective pools, glass-fused scars, copper vines and Stormglass arches. I could not find any of those at readable size in any frame. The trees are the same mid-size broadleaf and bare-snag models as a generic forest (F01, F05, F07), spaced across open grassland with lilac flowers. That reads as the Meadows under a purple filter, not as Stormwood.
- Meadows-family half-timbered cottages further weaken the chapter identity: F09, a red-roofed one in F18, two in F16 and a distant red roof in F01.
- The Stormheart should be the defining landmark of both boards: a colossal split tree with platforms, banners, walkways and a lightning core. In F11/F12 it is a grey rectangular column with no crown, no split and no glow. In F18 it is a flat, bark-less grey slab.

**Bar B (genre/finish): PARTIAL**
- These points carry it. The third-person camera sits over a small trainer with a large companion close by, the same register as Palworld 01/02. There is dense grass and flower scatter in the foreground (F01, F13), and the creature silhouettes are readable.
- These points sink it. Past the first tree line the terrain opens into a flat, empty, undulating plain with no backdrop (F01, F04, F07, F13, F17). Every Palworld frame has cliffs, hills or landmarks. The Break phase crushes to near-black (F04, F06, F08, F10). Several props look like untextured primitives (see the defects list). The main companion has a clay-like, lightly textured finish that sits below Palworld's finished creature surfaces.

**Forest defects**
| # | Frame | Defect | Fix type |
|---|---|---|---|
| F-1 | F11, F12, F18, F23 | The Stormheart / giant trunk reads as a grey untextured rectangular column or slab. It has no crown, no split, no bark, no platforms and no lightning core. F18 shows a normal tree placed in front of the slab, which destroys its scale. | **Asset** (hero tree mesh matching the boards) |
| F-2 | F04 (right horizon), F17 | A hard-edged flat grey card or wall sits on the skyline with a straight top edge, and it reads as a billboard. | Scene (remove it or hide it behind landform/trees), otherwise asset |
| F-3 | F01, F05, F07, F13, F16 | Trees are few, mid-size and evenly spaced over open grass. The canopy never closes, so the frames read as parkland, not an old forest. There are no giant old trunks near the path. | Scene (density, clustering, larger-scale instances), plus asset for true giant trunks |
| F-4 | F01, F04, F07, F13, F17 | The world ends in a bare, flat purple-grey plain at the horizon, with no silhouette depth. | Scene (distant tree walls, ridges, terrain shaping) |
| F-5 | all forest | No moss-from-below, roots, fungi clusters, black pools, copper vines or glass scars are visible. Lilac Meadows flowers dominate the ground. | Scene if installed kit pieces exist; otherwise asset |
| F-6 | F09, F16, F18, F01 | Meadows half-timbered cottages with orange-red roofs break the chapter identity, and the red roof edges toward the oxblood reservation. | Scene (swap or retint to a Stormwood structure family), possibly asset |
| F-7 | F09, F16 | A saturated blue castle-gate box reads as a flat-shaded primitive. | Scene (material), otherwise asset |
| F-8 | F11, F12, F23 | The cyan crystal spikes are plain cones with hard glowing rings where they meet the ground. They read as debug geometry, not Stormglass. | Scene (material and ground blend), otherwise asset |
| F-9 | F11, F12 | Small red box/banner props near the tower. If they are not Team Tether, that is oxblood leakage. If they are, they are too small and flat to read. | Scene |
| F-10 | F04, F06, F08, F10, F17 | In the Break phase the whole frame crushes to near black, and the companion and trainer lose their silhouettes. A storm peak should get darker at its extremes, with flash and afterglow, not settle into uniform murk. | Scene (lighting and exposure floor, rim light on actors) |
| F-11 | F07 foreground | A blue spiky creature right next to the camera is a flat, saturated blue mass with no readable form. | Scene (camera/actor placement); the creature's material may need an asset pass |
| F-12 | F01, F02 | A shorter hatted humanoid stands closer to the camera than the trainer but renders at about the same height. Check whether this is intended (a child or dwarf) or a scale error. | Scene/verify |

---

## 2. Rod line (F13–F18)

**Bar A (identity): NO**
- ART_DIRECTION calls for rod-line scaffolds, copper, and the rod line and Dynamo growing as the destination. In these frames the "line" is two or three wavy gold glowing stripes decaled onto a dirt path (F13–F18). The only built structure is a small dark spire with a cyan tip at the vanishing point, roughly 60–90 px tall (F13, F14, F15, F17, F18). No rods, pylons, cable runs, copper fittings or Stormglass appear along the route. The spire does not visibly grow between R1 and R6: it is about the same size in F13, F15 and F18.
- The gold colour matches the "Energy Glow" swatch on board B, but the boards' lightning is white-violet or blue with gold accents. Here gold is the only electric colour on the ground.

**Bar B (genre/finish): PARTIAL**
- F15 is the best frame in the whole set: a converging lit path, a centred trainer, a framing tree avenue and a destination spire. That route-pull composition fits the genre.
- The finish breaks down in several ways. The glow decals show rectangular quad edges (F14 at y≈850–880, F12, F09). F17 is nearly unreadable. In F18 the Meadows cottage and the grey slab trunk are the two largest objects in frame.

**Rod line defects**
| # | Frame | Defect | Fix type |
|---|---|---|---|
| R-1 | F13–F18 | The rod line has no physical rods, scaffolds or cabling. It is a painted gold road marking. | **Asset** or kit-bash from installed props (poles, copper, crystal) placed at intervals along the route, with the glow running between them |
| R-2 | F13, F15, F18 | The destination spire is tiny and the same size at every stand, so it does not "grow as the destination". | Scene (scale it up, raise it on terrain, add a light beacon) plus asset for a proper Dynamo silhouette |
| R-3 | F09, F12, F14 | The glow decals show hard straight quad edges and seams where tiles meet or clip terrain. | Scene (decal feathering, projection, tiling) |
| R-4 | F13–F16 | The glow is uniform saturated gold with no white-violet core or flicker variation, and the same stripe pattern repeats on every path. | Scene (material colour ramp, per-segment variation) |
| R-5 | F17 | The Break phase crushes the rod line and the trainer to near black, so only the stripes survive. | Scene (lighting floor) |
| R-6 | F18 | The mole creature fills the lower left as a black-blue spiky mass that reads as a porcupine. It does not match Thundertunnel's roster design (brown-black fur, pink snout, claws, blue arcs). | **Asset** |
| R-7 | F14 | The Stormraven pair are plausible in silhouette and scale (about 1.3x the trainer), but the flat blue material has no feather value range and no glowing arcs compared with the roster card. | Scene (material) or asset |

---

## 3. Sky after victory (F19–F24 vs pairs)

**Bar A (identity): PARTIAL**
- These points carry it. It matches the owner ruling that the purple sky stays, rain lightens and scars remain: in every pair the rain drops from heavy streaks to a few drops, and the ground glow largely goes out.
- These points sink it. The art direction also says "sky and ordinary forest colour return", but foliage, grass and ground are essentially unchanged in every pair. And the lightning has not stopped: see S-1.

**Bar B (genre/finish): PARTIAL**
- The broken cloud layer in F20/F24 gives the sky more shape and depth than the flat purple before it.
- The dark cloud wisps are low-resolution, smeared blobs with soft blotchy edges (F20 upper right, F24 middle band), not painted cloud forms. The terrain under the sky is still the empty plain from the forest section.

**Does the after-victory state read as the storm having ended?** Partly: it reads as rain easing off, not as a restored sky.

| Pair | What changed | What did not |
|---|---|---|
| F01 → F19 | Less rain, the gold path glow is almost gone, dark cloud wisps appear | The same purple sky tone. The white lightning bolt on the central trunk is still there. Foliage and ground colour are unchanged. |
| F02 → F20 | This pair shows the clearest change: heavy rain has become almost none, the ground is lighter, and the path glow is reduced to faint traces | The white bolt on the tree is still present. The sky gets darker streaks rather than lighter gaps. There is no warming or opening of light. |
| F03 → F21 | The rod glow near the companion is mostly gone | The sky is nearly identical. At contact-sheet size this pair is barely distinguishable. |
| F09 → F22 | The ground veins are reduced to faint remnants | The sky, light and colour are the same. |
| F11 → F23 | Rain is gone and the veins are faint | The grey slab tower, cyan cones and sky tone are unchanged. Nothing marks the Stormheart as released: no glow change and no calm light on it. |
| F14 → F24 | The gold path is almost extinguished and the cloud texture is added | Lighting on trees, grass and the trainer is nearly identical. |

**Sky defects**
| # | Frame | Defect | Fix type |
|---|---|---|---|
| S-1 | F19, F20 (vs F01, F02) | A static white lightning bolt stays on the central tree trunk after victory, which contradicts "lightning stops". If it is meant as a scar, it needs to read as glass-fused bark, not an active bolt. | Scene (hide the bolt or swap it for a scar material) |
| S-2 | F19–F24 | "Ordinary forest colour returns" is not visible: foliage, grass and ground value and hue are unchanged. | Scene (post-victory environment/lighting profile: raise ambient, warm the key light slightly, lift saturation) |
| S-3 | F20, F24 | The cloud-break layer is low-resolution, blotchy, dark smears. It reads more ominous than calm. Restoration should show lighter gaps or thinning cloud, not added dark streaks. | Scene (sky texture and parameters) |
| S-4 | F23 | Nothing visible changes on the landmark tree after the release. It is the region's climax object. | Scene (glow or light change) plus the F-1 asset |
| S-5 | F21 | The after state is almost identical to F03 at a glance. | Scene (same fixes as S-2/S-3) |

---

## Creatures (required first-look note per the method)

At normal distance the companion rock-plated red-panda/bear is appealing and reads well at about 2x the trainer's height (F01, F13), and the scale agreement is good. Its surface is a smooth clay-like body with painted blotches and flat grey plates, below Palworld's finished creature materials (Palworld 01). The Stormwood wild creatures vary: the wolves (F07) are the closest to the roster board, the ravens (F14) are acceptable silhouettes with flat material, and the spider (F07, F11) and mole (F18) read as saturated blue blobs or wrong species. This is not the F10#4 subject, but it lowers Bar B in every frame they appear in.

---

## Ranked fix list (most impactful first)

1. **Replace the Stormheart / giant-trunk slab with a real hero tree** (F11, F12, F18, F23; also the F04 skyline card). This is the largest identity gap against both boards. **Asset.**
2. **Build a physical rod line.** Put rods, scaffolds, copper and crystal at intervals along the route, with the glow running between them. Make the destination spire or Dynamo large enough to grow visibly across R1–R6 (F13–F18). **Asset/kit-bash plus scene.**
3. **Give the forest Stormwood structure.** Close the canopy, add giant trunks near the path, cluster trees instead of spacing them evenly, and hide the empty plain horizon (F01, F04, F07, F13, F16, F17). **Scene** using installed trees and terrain, **asset** for giant trunks.
4. **Make the restored state read.** Remove or convert the persistent white bolt (F19/F20), return forest colour and light, and turn the cloud break into lighter gaps instead of dark smears (F19–F24). **Scene.**
5. **Fix Break-phase exposure** so the actors and landmarks keep their silhouettes (F04, F06, F08, F10, F17). **Scene.**
6. **Fix glow-decal quad seams** and add colour variation with a white-violet core (F09, F12, F14). **Scene.**
7. **Remove or restyle Meadows cottages and primitive props** in Stormwood: the blue gate box, cyan cones and red boxes (F09, F11, F16, F18, F23). **Scene**, falling back to asset.
8. **Stormwood creature fidelity:** the mole (F18) and spider (F07/F11) against the roster board. **Asset.**

---
Provenance (VIS, added after the judge returned). The frames came from render.yml runs 36310761889 (before victory) and 36310774685 (after victory: `--variant=aftermath` plus 42 main-path flags set directly, a disclosed shortcut). Both runs were at `tb/vis` `f0d278c6`, which is main `4316362e` plus the `--flags`/`--times` args in `tools/capture_visual_audit.gd`. Capture details are in `CAPTURE.md`.

The judge saw only the frames, the neutral `LABELS.txt` and `/tmp/claude-0/judge/refs/`. Stormwood has no day/night cycle (owner ruling WO-F10-08), so the time axis is the storm phase. The fading phase, Dynamo core, Stormheart close-up and motion were not captured.
