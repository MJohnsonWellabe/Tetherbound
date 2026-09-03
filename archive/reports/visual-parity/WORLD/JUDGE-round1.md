# Visual Judge — WORLD round 1

Blind pass. No code, config, diffs, or history were read — judgment is from
the rendered frames and `docs/reference/` only.

## Specific defects, by frame

**Pale/white "ghost" trees at mid and long distance — the dominant defect, present in nearly every AFTER frame that shows a horizon.**
- `locations/01-village-approach-day.png`: the tree at top-right of frame is not a canopy, it is a cluster of hard-edged, pale mint-to-white triangular shards — reads as a broken alpha-cutout or blown-out material, not foliage.
- `locations/01-village-tournament-day.png`, `01-village-twins-day.png`: the entire background hillside is dotted with small cotton-ball-white trees, contrasting sharply with the one solid dark-green tree in the mid-ground.
- `survey/02-valley-floor.png`, `survey/04-three-quarter.png`, `stands/03-rise-overlook-day.png`, `stands/03-rise-overlook-golden.png`: every tree past roughly 15m is rendered pale mint/white instead of green — the whole horizon in the overlook shots reads as scattered white puffballs, not a wooded meadow.
- `locations/02-mill-pond-wheel-day.png`: same pale treeline visible past the pond.
- This is systemic, not a one-off: it appears in day, golden, and the one readable night frame alike, and at every distance band past "close." It is the single biggest visual difference from both references.

**`locations/02-mill-pond-approach-day.png` is a broken frame.** The camera appears to be clipped inside foliage geometry: the image is dominated by huge flat white and pale-green polygon shards with visible z-fighting edges, no readable ground, sky, or building. This frame currently carries no evidence value for the mill pond location at all.

**Night sky and moon read as a flat paste-on, not a lit sky.**
- `stands/01-spawn-outward-night.png`: almost entirely black; grass, the two NPCs and rock are barely legible, no stars, no moon visible in frame.
- `stands/03-rise-overlook-night.png`: the opposite problem — a single flat medium-blue wash covers sky and ground alike, with a hard-edged, textureless white disc (the moon) blown fully to white with no craters, phase, or soft glow falloff, partially cropped at the top of frame.
- `locations/01-village-tournament-night.png`, `01-village-twins-night.png`: same flat white moon disc, pasted with a hard silhouette edge against the navy sky, no halo.

**`stands/03-rise-overlook-dawn.png` is a uniform red/maroon wash across the entire frame** — sky and ground share almost the same hue and value, distinguished only by a faint horizon seam. This reads as a stuck color-grade or fog-color bug, not an authored dawn: there is no gradient, no warm-to-cool falloff, and no separation between land and sky.

**`stands/03-rise-overlook-golden.png` does not read as golden hour.** It is a flat gray-lavender/blue wash, cooler than the day frame taken from the same spot (`03-rise-overlook-day.png`). The label promises warmth the image does not deliver.

**Sun disc is a flat, hard-edged white oval with no bloom.** `survey/05-spawn-low-sun.png` and `stands/01-spawn-outward-golden.png` both show a pure-white ellipse with a crisp silhouette edge and no color falloff or glow radius — it reads as a UI sticker pasted onto the sky rather than a light source.

**Cloud texture is blotchy/streaked, worst near the sun.** `locations/02-mill-pond-standing-day.png` shows clouds smeared into a swirled, melted-looking pattern directly around the sun disc; `locations/01-village-standing-day.png` and `01-village-approach-day.png` show a harder-edged, more "brushstroke" cloud silhouette than the softer, more blurred clouds in the BEFORE set at the same locations.

**No landmark breaks the horizon in the overlook shot.** `survey/03-rise-overlook.png` and `stands/03-rise-overlook-day.png` show flat meadow to the horizon with only the small village roofline and the white tree artifacts for incident — no mountain, ridge, or built silhouette anchors the view the way the keyart's snow peak or the Palworld plateau screenshot does.

**No creature appears in any AFTER frame.** Every frame in both sets is empty of creatures — the rubric's scale-agreement criterion (trainer as the 1.80m ruler against a creature) cannot be judged from this evidence at all, which is itself worth flagging: a survey of "the world" that never shows the thing the game is named after is missing its own most important test.

## Per-axis: AFTER vs BEFORE

- **Sky/clouds** — **Worse.** BEFORE's clouds (`VP0.../01-village-standing-day.png`, `01-village-tournament-day.png`) are softly blurred, calm cumulus. AFTER's clouds are more sharply outlined and in `02-mill-pond-standing-day.png` visibly smear/swirl around the sun. AFTER does add a visible sun disc BEFORE lacked, but its flat hard-edged execution is worse than having none.
- **Sun** — **New, but poorly executed.** BEFORE shows no visible sun disc in any frame. AFTER's sun (`stands/01-spawn-outward-golden.png`, `survey/05-spawn-low-sun.png`) is a flat white ellipse with no bloom — an addition that currently reads as a bug rather than an improvement.
- **Time-of-day read** — **Mixed, net worse.** BEFORE had essentially one state (day) plus one broken solid-black frame (`before/05-spawn-low-sun.png`). AFTER attempts four states (dawn/day/golden/night) per stand, which is real ambition — but dawn is a uniform red wash, golden reads as cool/gray rather than warm, and night is either near-black (`01-spawn-outward-night`) or a flat blue wash with a paste-on moon (`03-rise-overlook-night`). Only the plain "day" state reads reliably in both sets.
- **Distance/haze** — **Worse.** BEFORE's overlook (`before/03-rise-overlook.png`) is a soft, low-detail grey-green fade-to-white — bland but clean. AFTER's overlook shots have more scattered detail at distance, but nearly all of that detail is the broken white-tree artifact, so the added density reads as noise/breakage rather than depth.
- **Ground cover** — **About the same.** Grass density and wildflower scatter are comparable in both sets and reasonably dense in the near field (e.g. `before/02-valley-floor.png` vs `survey/02-valley-floor.png`).
- **Tree canopy colour and silhouette** — **Clearly worse — the standout regression.** BEFORE trees, near or far, are solid mid-to-dark green with a readable rounded-canopy silhouette (`before/01-spawn-outward.png` top-left tree, `before/02-valley-floor.png`). AFTER's close trees are fine, but essentially every tree past close range is pale mint/white and shard-shaped, as detailed above. This is the largest single visual delta between the two sets.
- **Overall colour/value** — **Worse.** BEFORE's village frames carry a warmer, softly-bloomed, golden-hour-adjacent polish that sits closer to the keyart's honeyed palette. AFTER's day frames are cooler and flatter, and the broken dawn/golden stand frames actively damage value structure by washing the whole frame to one hue.

## Ranked: the three things that most separate these frames from the references

1. **The pale/white distant-tree breakage.** Both the keyart and every Palworld reference frame show trees as solid, richly-shaded green massing that reads instantly as "forest/grove" even in silhouette. In these AFTER frames, anything past near range is a cluster of blown-out, hard-edged pale shards — the opposite of a readable silhouette, and visible in nearly every wide or mid-distance shot (`locations/01-village-tournament-day.png`, `survey/03-rise-overlook.png`, `stands/03-rise-overlook-golden.png`).

2. **Time-of-day states that don't read as time of day.** The keyart's own night/dusk panels show a controlled, warm-to-cool gradient with a soft glowing moon and clear silhouette contrast (see the keyart's "NIGHT" panel and the stronghold-at-dusk panel). `stands/03-rise-overlook-dawn.png` (flat red wash) and `stands/03-rise-overlook-night.png` (flat blue wash with a pasted white moon disc) show no such gradient or lighting logic — they read as broken environment states, not authored moods.

3. **No landmark or built silhouette anchors the wide views.** Every keyart panel and three of the five Palworld shots put a mountain, tower, or ruin on the skyline to give scale and mood to the open field. `survey/03-rise-overlook.png` and `stands/03-rise-overlook-day.png` show flat meadow to the horizon with nothing but the tiny village roofline and tree-artifact noise — the world reads as emptier and less directed than either reference asks for.

## The two bar questions

**A. Do these frames read as belonging to the world in `docs/reference/tetherbound-meadows-keyart.png`?**
**No.** The near-field village shots (`01-village-grandpa-yard-day.png`, `01-village-twins-day.png`) get close on palette and cottage design — those two could plausibly sit next to the keyart's "STARTING SETTLEMENT" panel. But the moment a frame shows any real distance, the pale-tree breakage and the flat, ungraded dawn/night states pull it out of the keyart's world entirely; nothing in the keyart's carefully value-graded skies looks like `stands/03-rise-overlook-dawn.png`'s solid red wash or `stands/03-rise-overlook-night.png`'s pasted moon.

**B. Shown these frames beside `docs/reference/palworld-0*.jpg`, would someone say these are trying to be the same kind of game?**
**No, not as currently rendered.** The near-ground density and readable player silhouette in the day village shots are in the right family. But no Palworld reference frame shows shattered white foliage geometry, a flat monochrome sky wash, or a camera clipped into geometry the way `02-mill-pond-approach-day.png` is — those read as render bugs a shipping game would never show, and they are frequent enough in this set to dominate the comparison rather than be an outlier.

## Fixable-by-scene vs needs-new-art

**Fixable by changing the scene/render config (no new art required):**
- The pale/white tree breakage — near trees are fine, only distance bands are broken, which is the signature of an LOD, impostor, or distance-fade material problem rather than missing art.
- The flat red dawn wash and the cool/gray "golden" hour — both look like WorldEnvironment/fog-color or lighting-preset values that don't match their labels, tunable without new assets.
- The flat white sun and moon discs with no bloom/glow falloff — a post-process glow or sky-shader setting, not new textures.
- The near-black `01-spawn-outward-night.png` and the washed-out `03-rise-overlook-night.png` — exposure/ambient-light tuning for the night preset.
- The blotchy/melted cloud texture around the sun in `02-mill-pond-standing-day.png` — cloud-shader or noise-scale tuning.
- `02-mill-pond-approach-day.png`'s broken/clipped frame — almost certainly a camera-placement or collision issue in how this shot was captured, not an art problem.
- The lack of a horizon landmark in the overlook shot — likely fixable by composition/scene dressing (placing an existing large landform or structure in view) rather than new art, if such assets already exist in the project.

**Needs art not currently in the build:**
- Cannot be determined from this evidence. No creature appears in any AFTER frame, so the rubric's creature/character appeal and scale-agreement checks — the ones most likely to actually require new art — were not testable here. That gap in the evidence should be treated as a finding in its own right: a "world" survey that never shows a creature is not yet the evidence this rubric needs.
