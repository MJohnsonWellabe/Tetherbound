# AUDIT-J — blind visual judge pass, 2026-08-31

**Judge:** a fresh subagent with no access to this conversation, no design
context, no knowledge of what changed or what any prior lane claimed to fix.
Given only: the frame paths below, the two reference sets
(`docs/reference/tetherbound-meadows-keyart.png`,
`docs/reference/palworld-0*.jpg`), and the visual-judge rubric (embedded in
the brief, plus one added question on cross-system coherence for J1).

**Frames judged:** `main` @ `453107fb` (post-LAND-0830J).

- Open-world sheet: `ralph/reports/AUDIT-J/shots/survey/_sheet.png` + the 4
  full-resolution frames beside it (`tools/survey.gd`, canonical 5-stand
  survey minus `05-spawn-low-sun`, which failed to render — see the main
  report's evidence-validity section).
- Stronghold/Hall sheet: `ralph/reports/AUDIT-J/shots/hall/_sheet.png` + the
  11 full-resolution frames beside it (`tools/_judge_capture_hall.gd`, the
  same rig JUDGE-6 and T1-HALL-4 used, so directly comparable in method).

**This lane did not frame these shots for the judge to see raw — it received
only file paths and rendered them itself via its own Read calls, with no
narration of what to look for beyond the rubric.** Separation rule per
`ralph/conventions.md` and the visual-judge skill: satisfied.

---

<the full judge report, verbatim, follows>

---

I have read all 15 frames plus both reference sets. Findings below.

# TETHERBOUND — BLIND VISUAL PASS
### Open-world sheet + Team Tether stronghold ("J Hall") audit, judged against the project keyart board and the Palworld competitive bar

Calibration note applied throughout: I have discounted noise, aliasing, shadow-cascade softness, and absence of ambient occlusion. Where a defect could plausibly be renderer-only I say so explicitly. Where a defect is present *in the art itself* — geometry, scatter, palette, texel density, asset placement — I treat it as real regardless of renderer.

---

## 1. SILHOUETTE AND READABILITY AT SMALL SIZE

I viewed both sheets first, thumbnail-only, before opening anything full-res.

**Open-world sheet, at thumbnail:** three of the four tiles are unidentifiable as anything but "green field." Tile 1 (`01-spawn-outward`) reads as a grass texture with a dark wedge across it. Tile 3 (`03-rise-overlook`) reads as a pale mint gradient. Tile 4 (`04-three-quarter`) reads as green with one small building. Only tile 2 (`02-valley-floor`) survives thumbnail scale, because it has a large dark boulder mass, a tree line at two depths, and a red roof cluster — i.e. it is the only frame with a value anchor and a focal object.

**Specific defects:**

- **`03-rise-overlook`** — the entire region y≈195–400, full frame width, contains zero identifiable content. This is an *overlook* shot: the beat is "player crests a rise and sees where they are going." What is visible is one four-house cluster at ~(640–780, y300–350), roughly 140px wide in a 1280px frame, and one bare grey knoll at (180–400, y265–330). At thumbnail this frame has no subject at all. The keyart's own top-left panel is the same beat and puts a mountain, a bell tower, a windmill, a river, a road, and three depth bands of trees in it.
- **`04-three-quarter`** — the house at (585–700, y110–190) is the sole silhouette element and it sits *on* the horizon line rather than breaking it meaningfully; its roof rises maybe 60px above the ridge. Nothing else in the frame reads at 30%.
- **`H-01-approach-400`** — this is the stronghold's establishing beat and the stronghold is **not readable**. The keep occupies roughly (600–650, y370–420) — about 50×50px — it is the same grey-green value as the hazy hill behind it, and it is bisected by the tree line in front of it. At thumbnail the frame reads as "forest," full stop. The keyart art-direction notes literally say *"Silhouettes and landmarks visible from distance."* This frame is the direct failure of that line.
- **`H-02-sigil-gate`** — better, because the two red banners at (400–430, y365–430) and (540–570, y365–430) punch through at thumbnail. Those banners are doing more landmark work than the entire keep behind them. Worth noting as a positive: red is the most efficient readability tool currently in the build.
- **`H-05-east-flank`** — reads at thumbnail as a wall, correctly, but reads as an *unmodulated* wall: tower / panel / tower / panel at identical rhythm. No silhouette event, no tallest point, no direction cue toward the gate.

**What does survive small:** `H-03-ramp-foot` (all three time variants), because of the strong converging-perspective ramp and the twin-tower gate mass. `H-07-courtyard`, because of the two big red sigil banners. Those two compositions are the only ones I would call thumbnail-competent.

---

## 2. COLOUR AND VALUE STRUCTURE

**The open-world set has a collapsed value range.** In `04-three-quarter`, sampling by eye from top to bottom, essentially everything from y=200 to y=720 sits inside roughly a 25% luminance band of one desaturated green. There is no dark. There is no light. `03-rise-overlook` is worse: from y=0 to y=400 the frame is a single pale grey-mint wash, sky and ground barely differentiated, with the sky/sea/land boundary at y≈180–195 collapsing to three near-identical values.

By contrast the keyart's meadow panels carry deep near-black shadow under the oak canopies, a full-saturation mid-green in sunlight, and a high-key white cumulus sky — a genuine three-stop structure. Palworld-01 and -03 do the same with dark trunks and shadowed foliage against a bright field.

**Frames are not one time of day.** `01-spawn-outward` and `02-valley-floor` read as warm late-morning: yellow-green grass, warm cloud undersides. `04-three-quarter` reads cool and blue-shifted, closer to overcast dusk — the greens have gone sage-blue and the sky has darkened. `H-05-east-flank`'s sky is a noticeably duller, darker blue than `H-04-gate-mouth`'s in what should be the same session and the same hour. These are meant to be one place; they read as three different days.

**Hue variety is near-zero in the open world.** The single exception is worth calling out as the thing that works: `02-valley-floor` has a band of rust/ochre grasses at roughly (0–350, y330–460), and that one hue break does more for the frame than anything else in it. `H-01-approach-400` does the same thing with yellow-greens and scattered purple/white flowers in the foreground, and is the best-feeling ground plane in the entire set. Neither treatment appears anywhere else.

**Faction colour discipline — mostly good, two leaks:**

- The oxblood/red is genuinely reserved for Team Tether. Banners in `H-02`, `H-03`, `H-04`, `H-05`, `H-07`. Nothing in the open world uses it except the *village roof tiles* in `02-valley-floor` (x330–500, y185–225) and `03-rise-overlook` (x640–780, y300–350) and the house roof in `04-three-quarter`. That is a genuine leak: terracotta roof and faction oxblood are close enough at distance that the friendly village currently reads with an enemy-colour signal. Palworld's plateau landmark (ref 04) reserves its cyan-white spire colour absolutely.
- The **grunt's uniform in `H-07-courtyard`** is a desaturated dusty pink-mauve, not the banner's oxblood. Standing directly in front of two full-saturation red banners, he reads washed-out and off-hue — the faction's own soldier is the weakest expression of the faction's colour in the frame.
- **The ivy is actively fighting the faction colour.** In `H-04-gate-mouth`, the ivy curtain (490–760, y200–500) is the most saturated object in the frame and it occludes the red panels at (490–560) and (900–960) almost entirely. In `H-05-east-flank`, the banners at (505–540), (690–720) and (1130–1170) are half-buried behind vine clumps. The stronghold's identity colour is being hidden by decoration in two separate frames.

**Cyan.** There is a fourth colour in play — a cyan/teal tech glow — and it is currently reading as an artefact rather than a signal. See §6.

---

## 3. INTENTIONALITY — AUTHORED VS GENERATED

This is where the build is weakest and where the fixes are cheapest.

- **`04-three-quarter`, y250–720, full width:** the small bush scatter is one asset, at one scale, at near-uniform spacing, with no clustering and no clearings. This is the clearest generator tell in the set — you can see the distribution's regularity.
- **`01-spawn-outward`, x430–1280, y155–235:** the post-and-rail fence runs unbroken across the entire mid-ground at perfectly uniform post spacing and uniform height, tracing the terrain contour exactly. No gate, no gap, no leaning post, no rotted section, no reason for it to exist. It reads as a spline stamp, not as a farmer's fence.
- **`H-01-approach-400`, x110–620, y330–450:** the tree line is a straight row of near-identical trees at regular intervals with a flat common canopy height. Compare Palworld-02, where the treeline is clumped, varied in height, and broken by rock outcrops.
- **`02-valley-floor`, x820–1280, y230–330:** a band of identical low round shrubs at regular spacing.
- **`H-05-east-flank`:** modular wall kit with zero authoring on top. Tower / wall panel / tower / wall panel, identical crenellation, and — the giveaway — **the same ivy clump instance repeated on each panel at the same density and the same height.** Nothing is collapsed, nothing is repaired, nothing is newer than anything else. The keyart stronghold panel is defined by exactly the opposite: asymmetric ruin, one collapsed corner, timber scaffolding bolted on, machinery grafted to old stone.
- **`03-rise-overlook`:** the lone knoll at (180–400, y265–330) sits by itself in empty field. Landscape features in isolation with no supporting scatter is the signature of "placed one at a time in an empty world" rather than composed.

**Counter-examples where authoring is visible and working:** the foreground of `H-01-approach-400` (varied ferns, grasses, flowering plants, hue variety, believable density falloff) and the composition of `H-03-ramp-foot` (converging fences, framing towers, brazier rhythm leading the eye to the gate). Both prove the team can do it.

---

## 4. LIGHTING AND FORM

Discounting renderer-side shadow quality, the following are real:

- **`01-spawn-outward`:** a huge, hard-edged shadow wedge crosses roughly (180,330) → (900,720) with a razor-straight boundary and **no visible caster anywhere in frame.** Even allowing for a cascade artefact, a shadow this large with an edge this geometric and no source object reads as broken. Related: three yellow-white blown-out hotspots at approximately (180,235), (600,180) and (1210,350) sitting on the grass with no light source — probable renderer specular pops, flagged as *uncertain category*.
- **`01-spawn-outward`, trainer at (665–690, y225–320):** I see no contact shadow grounding him. He is standing in the lit region so this should be visible. Partially discountable to renderer; noted because in `H-07-courtyard` the grunt *does* have a soft grounding shadow at (600–800, y680–780), which is one of the better-grounded objects in the set — so contact shadows are clearly achievable.
- **`H-05-east-flank`, x400–1280, y440–560:** the wall base meets the grass on a clean line with no dirt skirt, no rubble, no gravel, no vegetation crawling up, and no darkening into the join. This is not a renderer issue — there is no *art* at the intersection. The wall reads inserted into the terrain rather than founded on it. Same at the tower base in `H-06-west-keep` (650–1050, y540–780).
- **`H-06-west-keep`:** the keep mass on the right is effectively pure black from x=650 to x=1280. Some of that is the software renderer's lack of bounce, but the geometry underneath is also the problem: it is a plain rectangular slab with two small arrow-slits, no buttressing, no massing, no offset volumes. Even correctly lit it has no form to reveal.
- **`H-03-ramp-foot` (day):** there is a hard shadow terminator down the left of the ramp — the left retaining wall (0–380, y270–500) is near-black while the geometrically equivalent right wall is fully lit. The golden-hour variant makes the same split. Flag as *possibly renderer*, but the fact that it survives across two different sun angles argues it is at least partly a geometry/normals issue.
- **Time of day reads clearly in the three `H-03` variants** — day, golden, night are legibly distinct, and the night frame's moon + brazier points + cool blue key is the most *atmospheric* frame in the set. Positive.
- **`H-03-ramp-foot-night`:** however, the braziers at (460–500, y210–270) and (700–800, y200–270) emit almost nothing — small point glints, no pooled light on the deck, no rim on the stone. A night approach to an enemy stronghold should be lit *by* the enemy's fire. The keyart's own NIGHT panel is built entirely on that idea (orange campfire glow against blue).

---

## 5. HORIZON AND DEPTH

- **`03-rise-overlook`** is the frame that most damages the build. The haze is so aggressive that by ~150m everything is a milky mint wash with no detail, and there is a flat blue-grey band at y≈178–195 that appears to be ocean. The combined read is: *this world is a small plate with nothing on it, floating in fog.* That is the exact opposite of Palworld-02 and -04, where distance is carried by rock walls, silhouetted trees, and structures at four or five depth bands, with haze applied *on top of* content rather than *instead of* it.
- **`H-02b-sigil-gate-raised`, x0–500 y400–420 and x950–1280 y395–420:** an explicit, hard, straight world edge where green terrain terminates against a flat pale plane, with the white fence line running along the boundary like a barrier. This is a visible edge-of-map tell and it is in a hero establishing shot.
- **`H-02b`, x380–980, y250–420:** a flat grey-blue mass with **vertical downward streaking** behind the keep. This does not read as rain, fog, or a mountain — it reads as a stretched/smeared texture or a broken distance LOD. It is the single most bug-like large-scale element in the set and it sits directly behind the landmark.
- **`H-02-sigil-gate`, x300–900, y290–340:** the same grey band appears with a hard, straight bottom edge — a fog card or mis-fogged distant LOD, not weather.
- **`02-valley-floor`:** the mountains at (430–560, y150–200) and (1080–1280, y150–210) are pale, detail-free, and have a hard bottom edge cutting into a uniform pale haze band at y≈195–215. This is the "terrain ends, fog begins" seam again.
- **The cloud layer is the same smeared streak texture in all fifteen frames.** In `H-01-approach-400` the dark grey smear at (250–620, y40–120) reads as a dirty smudge on the lens rather than a cloud. Whatever this is — a low-res cloud texture, a stretched panorama — it is uniform across the whole build and is a cheap, high-impact fix. The keyart uses crisp stacked cumulus in every panel; Palworld-04 and -05 do the same.

---

## 6. ARTEFACTS

Ranked by how much they read as a bug:

1. **The cyan hairline / bar.** Appears in `H-02b` (from ~(760,470) to (1280,395)), `H-03-ramp-foot` (upper right, ~(830,215) → (1280,60)), `H-03-golden`, `H-03-night`, `H-04-gate-mouth` (right edge, y≈320), `H-06-west-keep` (295–310, y390–460), and worst of all **`H-07-courtyard` (x0–520, y440–465)** — where it is a perfectly straight flat cyan line lying across the courtyard cobbles and continuing up the far wall. In `H-07` this is unambiguously a z-fighting decal or a light volume clipping the floor plane. It is not readable as an authored tether/energy effect in any frame; a 1px hairline crossing the sky reads as a rendering error every time.
2. **`H-08-wall-close` UV seam.** The left strip x≈0–180 uses the same stone texture at roughly **55% the texel scale** of the main panel to its right, with a hard vertical seam at x≈180 and a second at x≈240. Two adjacent wall pieces at different texel density. Real, addressable, not a renderer issue.
3. **The black braziers/anvils in `H-04-gate-mouth`** at (25–215, y265–410) and (1040–1230, y260–400). These are the two largest foreground objects in the frame and they are solid matte black with no texture, no material variation, no emissive, no rim. Everything about them says *missing material assignment*. They appear the same way in all three `H-03` variants at (460–500) and (700–800). If this is an unassigned material rather than an unmade asset, it is the highest value-per-minute fix in the entire audit.
4. **`03-rise-overlook`, x825–900, y415–465:** the large green boulder has a flat brown rectangular face on its upper left that does not match the rest of the rock. Reads as a wrong-material face or a misplaced decal.
5. **`03-rise-overlook`, x380–780, y560–700:** clearly visible flat-shaded terrain triangles on the slope. Terrain normals / LOD, not antialiasing.
6. **`01-spawn-outward`, x0–110, y360–620:** a second humanoid (orange-brown tunic) is sliced in half by the left frame edge, torso and arm only, apparently standing inside the camera's near plane. Whether this is a framing choice or an NPC intersecting the camera, it reads as a mistake.
7. **`04-three-quarter`, x100–600, y430–560:** repeating diagonal streak banding in the grass — visible texture or wind-noise tiling.
8. **`H-04-gate-mouth`, (140–165, y225–245) and (1075–1105, y215–250):** sparse white specks. Too few and too uniform to read as embers; reads as an unfinished particle emitter.
9. **`H-07-courtyard`, x300–540, y250–465:** the doorway interior is pure black with one visible hard corner. No interior light, no falloff — reads as an unfinished room rather than a dark room.
10. **`H-06-west-keep`, x0–380, y620–700:** flat grey rectangular slabs lying on the grass with hard edges and no blend. Reads as placeholder foundation decals.
11. **`H-02-sigil-gate` and `H-03-ramp-foot`:** large regions of bare, blindingly pale sand/dirt terrain with **straight geometric edges** against the grass — in `H-02` at (0–260, y480–540) and (1000–1280, y460–540); in `H-03` a hard diagonal seam running (600,780) → (1100,430). This is an unpainted terrain mask or a navmesh cut showing through, not a road shoulder. It is one of the most visible defects in the fortress approach.

---

## 7. SCALE AGREEMENT

Using the trainer/grunt as the 1.80m ruler:

- **`H-04-gate-mouth` — the main gate is roughly half the size it should be.** The crate at (620–710, y490–570) is ~90px tall; a crate of that shape reads ~0.9m. The gate arch at (530–745, y265–490) is ~225px tall at only slightly greater depth. That puts the *main gate of a faction stronghold* at roughly **2.2m tall and 2.2m wide** — a doorway, not a gate. The full gatehouse, crenellations included, is about three crate-heights, so ~8m total. The keyart's TEAM TETHER STRONGHOLD panel shows a vaulted entry arch of at least 5m inside a structure four to five storeys tall. **The build's gatehouse is roughly 2x under-scaled against its own concept, in the wrong direction.** This is the most consequential scale defect: it turns a fortress into a folly, and it will read even worse once a creature has to walk through it.
- **`H-03-ramp-foot`:** consistent with the above — the gate opening at (595–700, y195–270) is about twice the width of the crate on the ramp at (630–670, y265–300).
- **`H-07-courtyard`:** interior scale is *fine*. The grunt at (545–745, y345–780), the bench at (925–1160, y485–560), the crate at (665–730, y430–475), and the doorway at (270–580, y210–465, ~2.3–2.5m) all agree. This frame is the scale reference the exterior should have been built to.
- **`02-valley-floor`:** the hero boulder at (555–830, y150–350) reads roughly 8–10m tall against the trainer at (480–510, y265–305). That is defensible as a glacial erratic landmark — but it is simultaneously the largest and the least-finished object in the frame (see §8), so the scale reads as *unintentional* rather than as a landmark.
- **`01-spawn-outward`:** the near-camera grass occupies the bottom third at what would be 1.5m+ if taken literally. Almost certainly just camera proximity, but the effect is that the player's own frame is a wall of grass. Compare Palworld-02/03, where the grass is knee-height and the camera sits above it so the field reads as traversable.
- **`04-three-quarter`:** the house at (585–700, y110–190) reads correctly for a two-storey dwelling. No complaint.
- **No creatures are visible in any of the fifteen frames.** In a creature-training game whose own competitive reference (Palworld-01, -03, -04) puts creatures in the centre of every single screenshot, that absence is itself a finding — I cannot assess creature scale, and neither can anyone else looking at this set.

---

## 8. CROSS-SYSTEM COHERENCE — THE MAIN QUESTION

**What genuinely carries across both sets:**
- The ground scatter library. The same grass blade, the same white five-petal flower, and the same round-leaf broadleaf plant appear in `01-spawn-outward`, `02-valley-floor`, `H-01-approach-400`, `H-03-ramp-foot`, and `H-05-east-flank`. This is the strongest continuity thread in the build.
- The salmon/terracotta-trunked tree, in both sets.
- The white post-and-rail fence, in both sets.
- The smeared cloud sky and the haze treatment, identically in both sets.

**What breaks, specifically:**

1. **Two different material fidelity tiers.** The open world is low-frequency and nearly untextured: the boulder in `02-valley-floor` (555–830, y150–350) is a single flat dark mass with essentially no surface detail; the terrain in `03-rise-overlook` is a blurred wash with visible facets. The fortress interior is high-frequency hand-painted work: `H-08-wall-close` has confident stroke language, warm mortar, painted highlights and dark keylines; the barrel in `H-04-gate-mouth` (630–790, y655–780) has crisp stave separation and a studded metal band. **Walking 100m from the meadow to the gate moves you between two texture budgets.** Worse, it happens *within* `H-04` itself: that beautifully painted barrel sits 200 pixels from a completely untextured black brazier.

2. **Two different colour philosophies.** Open world: desaturated, cool, hazy, low-contrast, single hue (`03`, `04` especially). Fortress: warm brown ground, high contrast, saturated oxblood red, saturated cartoon green. These are not the same colour script and they do not blend at the boundary — `H-02-sigil-gate` is the transition frame and you can see the two languages sitting next to each other without a gradient between them.

3. **Two different foliage rendering philosophies.** Meadow vegetation is soft, blended, tonally integrated. Fortress ivy (`H-04` 490–760 y200–500; `H-05` 330–950 y225–430) is hard-edged flat leaf cards at a saturation nothing in the meadow reaches, with no shadowing into the wall behind it. They are recognisably not from the same plant library.

4. **The same asset is tinted differently in adjacent shots.** The ivy in `H-06-west-keep` (0–460, y350–460) is a pale mint green. The ivy in `H-04` and `H-05` is a saturated grass green. Same wall, same location, shots taken minutes apart.

5. **The same wall is brown up close and grey at distance.** `H-08-wall-close` is warm khaki-brown. `H-04` and `H-05` read cool grey. Some of that is fog tint, but the delta is large enough that the material does not read as one material across viewing distances.

6. **Three stone tones in one frame with no unifying tint.** `H-07-courtyard`: warm brown cobble floor, cool grey right-hand wall, third-tone banner wall behind. Nothing ties them.

7. **Two architectural languages on one building.** The small orange conical-roofed turret at (820–865, y200–260) in `H-03-ramp-foot` — and again at (700–725, y345–395) in `H-02-sigil-gate` — is a fairytale village turret grafted onto a military keep. It is the wrong genre of roof on the wrong genre of building.

8. **The green shingle roof in `H-05-east-flank`** at (0–230, y175–215) is a flat teal-green that appears nowhere else in the world palette.

9. **No shared silhouette language.** All the vertical landmark authority in the build is at the fortress. The open world has none — no tower, no windmill, no standing stone, no rock spire. The keyart has all of those and uses them precisely as the connective tissue between "field" and "destination." That connective layer is simply absent.

---

# A. THE THREE THINGS THAT MOST SEPARATE THESE FRAMES FROM THE REFERENCES

**1. Distance carries no content — the world stops having things in it.**
`03-rise-overlook` has literally nothing between y≈195 and y≈400 across the full 1280px width, and `H-01-approach-400` reduces the stronghold to a ~50px grey smudge at the same value as the hill behind it, occluded by a tree line. Palworld-02 and Palworld-04 keep authored content at four or five distinct depth bands — rock walls, structures, tree clumps, a spire against sky — and apply haze *over* that content. The keyart's top-left panel does the same with a mountain, a tower, a windmill and a river. Here haze is being used *instead of* content, and the result is that the game appears to be a small green plate with a visible edge (`H-02b`, x0–500 y400–420).

**2. Value structure has collapsed, and the two systems don't share a colour script.**
`04-three-quarter` and `03-rise-overlook` live inside roughly a 25% luminance band in one hue. The keyart panels and Palworld-01/-03 both carry a genuine three-stop structure — deep shadow, saturated mid, bright sky — and Palworld reserves one high-saturation hue for the thing that matters. Meanwhile the fortress runs warm/high-contrast/saturated and the meadow runs cool/flat/desaturated, so even the two systems' *failure modes* don't match.

**3. Material fidelity is not consistent, and the gap is visible inside single frames.**
`H-04-gate-mouth` contains, within one composition, a hand-painted barrel with stave detail and stud work, and two completely untextured matte-black foreground objects the size of a person. `02-valley-floor` puts an 8–10m hero boulder in frame with no surface detail at all. In every Palworld reference, grass, rock, architecture and character are shaded in one language at one fidelity — that consistency is most of what makes those frames read as shipped.

---

# B. THE TWO BAR QUESTIONS

### B1. Do these frames read as belonging to the world in the keyart reference? — **NO.**

**What carried:** `H-07-courtyard`'s banners are excellent and are straight off the keyart's stronghold panel — the oxblood field and the cream ringed-cross sigil are exactly right, and they are the best faction expression in the build. `H-08-wall-close`'s painted stone is the one material in the set that matches the board's painterly intent. `H-03-ramp-foot-night` gets the "mysterious by night" line right.

**What sank it:** two things, and they are structural.

First, **the stronghold in the build is a different building from the one on the board.** The keyart panel shows a ruined, asymmetric, multi-storey stone hall — collapsed upper masonry, heavy vine growth on *broken* stone, timber scaffolding bolted on, visible machinery and apparatus, a broad flight of steps, banners hung on a structure four to five storeys tall. The build's version is a clean, symmetrical, structurally intact toy castle at roughly half that mass, with evenly-distributed decorative ivy, no ruin, no scaffold, and **no machinery of any kind**. This is not a lower-fidelity version of the concept; it is a different object.

Second, **the meadow on the board is not the meadow in the build.** The board's meadow is defined by oak groves with real canopy shadow, streams and ponds, wildflower banks, warm sun shafts, and clearings between masses. `03-rise-overlook` and `04-three-quarter` are open empty field with uniformly scattered bushes, no water anywhere in any of the fifteen frames, no grove structure, and no clearings — because there is nothing to clear.

### B2. Shown beside the Palworld screenshots, would someone say these are trying to be the same kind of game? — **YES.**

**What carried it:** the genre read is unambiguous. Third-person over-the-shoulder camera on a small trainer figure in a wildflower meadow with a fortified enemy landmark on the horizon; stylised proportions; cel-adjacent foliage; a masked uniformed faction grunt with a sigil. `H-03-ramp-foot` and `02-valley-floor` would both pass as early-access screenshots of a game in Palworld's category without anyone asking what genre it is. The ambition is legible even where the execution isn't.

**Caveat that stops short of sinking it:** nobody would mistake these for *shipped*. The differentiator is density and finish, not intent — and critically, **there is not a single creature in any of the fifteen frames**, while every Palworld reference puts creatures front and centre. Judged as "same kind of game," yes. Judged as "same completeness," visibly not.

---

# C. CROSS-SYSTEM COHERENCE — **NO. This does not read as one deliberately art-directed game.**

It reads as a gallery: an open-world pass and a fortress pass built to different standards, sharing a scatter library and a skybox but not a philosophy.

**Reasoning, concretely.** The shared grass, flowers, trees, fence and sky do real work — I want to credit that, because it is the thing keeping the two sets in the same universe at all. But everything above the ground plane diverges. The fortress is warm, high-contrast, saturated, and hand-painted at high texture frequency (`H-08`, `H-04`'s barrel, `H-07`'s banners). The open world is cool, low-contrast, desaturated, and nearly untextured (`02`'s boulder, `03`'s terrain, `04`'s whole frame). The fortress's ivy and the meadow's foliage are recognisably from different libraries. The same wall reads brown at 2m and grey at 50m. The same ivy is mint in `H-06` and grass-green in `H-04`. A fairytale conical turret sits on a military keep. And a hand-painted barrel sits 200px from an untextured black blob in a single frame — that last one is the clearest possible statement that no single pass has been made across this content.

The most damning version of the test: `H-04-gate-mouth` and `04-three-quarter` would not be believed as screenshots of the same product by anyone who didn't already know.

---

## FIXABLE BY CHANGING THE SCENE vs NEEDS ART THAT ISN'T IN THE BUILD

**Scene-level — no new assets required (this is most of the list, and it is where the biggest perceived-quality jump lives):**
- Cluster the scatter and cut clearings. `04-three-quarter` (bushes), `H-01` (tree row), `02-valley-floor` (shrub band). Vary scale ±40%, cluster in threes and fives, leave negative space.
- Fill the empty distance bands in `03-rise-overlook` and `04-three-quarter` with existing trees, boulders, and fence fragments at three depths, then pull the fog density back so haze sits *on* content instead of replacing it.
- Break the fence runs in `01-spawn-outward` and `H-02-sigil-gate` — gaps, gates, leaning and missing posts. Reskin the stronghold's perimeter fence so it isn't the friendly farm asset.
- Break the `H-05-east-flank` wall repeat using pieces already in the kit: vary ivy density per panel (some bare, some heavy), rotate/offset a tower, add a rubble and dirt skirt at the wall/grass join, and expose the red banners by removing ivy from those panels.
- Move the ivy off the banners in `H-04-gate-mouth` and desaturate it toward the meadow's green.
- Paint the bare terrain wedges in `H-02-sigil-gate` (0–260, y480–540; 1000–1280, y460–540) and `H-03-ramp-foot` (the diagonal at 600,780→1100,430).
- Lock one sun/sky setup across all frames — `04-three-quarter` and `H-05-east-flank` are currently drifting off the set's time of day.
- Fix the cyan line: it is a decal/z-fight/light-volume issue, clearest in `H-07-courtyard` at (0–520, y440–465).
- Re-tile the mismatched wall piece in `H-08-wall-close` (seam at x≈180).
- Assign a material to the black braziers in `H-04`/`H-03` — near-certainly a missing assignment, not a missing asset, and probably the single best minutes-to-impact fix here.
- Push the night braziers in `H-03-ramp-foot-night` to actually pool light on the deck.
- Re-hue the grunt uniform in `H-07` toward the banner oxblood, and pull the village roof tiles in `02`/`03`/`04` away from that red so the faction colour stays exclusive.
- Replace or resample the cloud layer — it is the same smeared streak in all fifteen frames and it cheapens every sky.

**Needs new art or geometry that is plainly not in the build:**
- **Rebuild the gatehouse mass at roughly 2x.** The `H-04` arch at ~2.2m cannot be fixed by scene dressing; the keyart calls for a vaulted 5m entry in a four-to-five-storey structure. This is geometry work and it is the most consequential item in the audit.
- **The stronghold's machinery, scaffolding and relay apparatus.** These are the defining feature of the keyart's TEAM TETHER STRONGHOLD panel and there is not one piece of them anywhere in the eleven fortress frames. Without them the building has no faction identity beyond hung banners, and it reads as a generic castle.
- **Ruin and asymmetry for the keep** — a collapsed section, repaired-in-timber patching, differential weathering. The board's building is a taken-over ruin; the build's is intact.
- **Distance-readable landmarks for the open world.** A tower, a windmill, a standing stone, a rock spire — the keyart has all four, the open-world frames have none, and this is why `03-rise-overlook` has nothing to look at.
- **A mid/far LOD tree and rock set** so the distance bands can hold content at all without cost.
- **A stone material family that reconciles** the fortress's painted stone with the open world's flat boulders — currently `H-08` and `02-valley-floor`'s boulder are from different games.
- **Creatures in frame.** Not strictly an art gap, but no visual audit of a creature-training game is complete on fifteen creature-free screenshots, and the competitive reference set makes that absence conspicuous.
