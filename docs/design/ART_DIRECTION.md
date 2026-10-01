# Art Direction

## Contract and evidence boundary

Tetherbound is a Windows-first, controller-first creature expedition action RPG for one to four players. The current production pass covers four biomes in the order **Meadows → Tidewake → Cloudreach → Stormwood** (owner, 2026-09-29, RD-10), reached from one village road in the Meadows whose far end is the **Crossing Hall** portal building (RD-17, RD-29). The target normal clear is **15–25 hours** with an optional, rewarding grind loop (RD-01); this replaces the former "eight good hours" framing. Schemas and the Hall plan for eight biomes (RD-09); biomes 5–8 are not built in this pass and appear only as sealed arches and empty pedestals. Its visual job is to make the journey and the homestead loop feel lush, legible, inhabited and worth returning to, while keeping the five-creature relationship at the centre of every frame.

This document defines the target and the production boundaries. It does not declare the current game visually accepted. A configuration value, placed prop, imported mesh or passing screenshot test proves only that the element exists. Final visual acceptance requires current production captures, motion checks, an independent code-blind agent verdict against the settled references and recorded target-hardware telemetry.

**Bars A and B, redefined (owner, 2026-09-29, RD-24).** Every visual fix targets the full bar, not just the removal of its defect. Both bars are judged **at ordinary gameplay distance** (the normal player and fight cameras, not close-up turntables), on the **High and Medium** renderer presets; Low must stay readable (§2).

1. **Bar A — creature and world appeal:** do representative frames read as coherent, appealing Tetherbound, matching the intent of `docs/reference/tetherbound-meadows-keyart.png` and the chapter boards (§4.2), with **Palworld/Animo-class creature and world appeal**?
2. **Bar B — light and atmosphere:** do the same frames have **Valheim-class light and atmosphere** — sky, fog, sun shafts, time-of-day grade and weather mood — at commercial presentation quality? The per-biome look bar in §4.1 is the concrete target, written by F26.

Superseded (owner, 2026-09-29, RD-24): the former Bar A (identity against the key art alone) and Bar B (genre/finish beside `palworld-0*.jpg`) were "aspirational" directional questions. They are now the acceptance bar for every visual row (ACCEPTANCE §4, §6.2 F17#6, F26#3, F38–F41). A "yes" still claims no asset equivalence, copied composition or measured audience appeal. Neither bar is met today. Several creature and environment silhouettes are asset-gated. Texture work cannot repair unsuitable topology, a buried face, a missing feature or an animation set that cannot express the required action.

### What the full bar means per domain

The code-blind judge scores each domain separately (ACCEPTANCE §4). "Current gap" names the recurring Codex catalog theme (§9.1), not a verdict.

| Domain | Full bar (Bar A appeal + Bar B light) | Current gap | Rows |
|---|---|---|---|
| Creatures | Appealing, chunky, instantly readable silhouettes with a clear face and eyes, designed colour blocks and soft rim-lit materials. Idle, locomotion, hurt, faint, swim, fly-grip and ride poses read without a label. Every creature stands taller than the 1.80 m trainer; gear shows as a trim or glow accent; evolved forms read as the same individual grown up. | Poses and scale (P2-015/016/017/028/062/071), stand-in meshes, idle silhouettes held through hurt/move states. | F36, F29, F33#1 |
| Terrain and landforms | Sculpted, readable landforms: layered cliffs with strata, rolling hills that frame the route, shores and banks with believable transitions. Broad shapes at 400 m and material detail at 5 m. No flat tiled planes, seams or unexplained bare rectangles. | Terrain landforms theme: flat or smeared ground, weak cliff identity. | F38–F41 |
| Vegetation | Clustered groves, edges and clearings in three layers where ecology allows. Wind motion on grass and canopy. Light filters through canopy on Medium/High. Density follows ecology, never a uniform carpet. | Uniform scatter, sparse or mismatched families, cyan/white Nature Kit materials. | F38–F41 |
| Water, sky and light | Valheim-class atmosphere: layered depth fog, sun shafts where canopy or cloud breaks, a distinct time-of-day grade (morning, day, golden hour, night), and weather that changes mood as well as tint. Water has depth colour, shore foam and readable surface currents. Low keeps this identity through authored value and hue separation (§2). | Flat grade, fog absent under Compatibility, weather reads as tint. | F26, F38–F41 |
| Architecture (including the Crossing Hall) | One coherent installed village/stone family with human-scale thresholds and lived-in dressing. The Crossing Hall is the tallest village landmark, reads as the destination from Grandpa's farm door by day and night (F17#1) and has a lit nave: the home arch, three live-capable arches and four sealed but visible arches, each signed by biome, plus a Shrine Room of eight pedestals (F17#2). Biome landmarks (Veilfall, the Sky Aviary, the Stormheart tree) read at 400 m and 100 m. | Landmark identity, thin kitbash, flat signs. | F17, F38#4–F41#4 |
| Props, pickups and stations | Each pickup, gatherable, essence node and waystone reads by silhouette at pickup range before any label. The six homestead stations and their attachments read as distinct objects at the normal camera (F31#6). Portal keys and relics read as real items. | Item identity theme; stand-in boxes and floating labels. | F31, F32, F18, F38–F41 |
| Humans | Installed cast only (hard rule), two or three large colour blocks per silhouette, a distinct face and hair treatment for named NPCs, rank legible without a nameplate. Oxblood stays reserved for Team Tether. The six most repeated faces are Meshy priorities (§7.1). | NPC silhouettes theme; repeated bodies. | F36#0, F38–F41 |
| VFX | Every move shows its real object — pebbles, a boulder, a burning fireball, lightning striking from the sky — with a trail, an impact and a sound (F25). Ultimates are readable 2–3 s set pieces (F35). Mastery visibly scales an effect. Hit feedback reads as weight (F21). No flat magenta rings or slabs (F38#5–F41#5). | Magenta effects theme; generic bursts. | F21, F25, F35 |
| UI | UX tokens, controller-first, readable on a 7-inch screen. No bare menus, heavy HUD boxes or low-contrast text. The map shows terrain context. | UI theme (catalog UI rows). | F42 |

## 1. Visual thesis

The shared style is stylized realism: **Palworld/Animo-class creatures and world, lit with Valheim-class light and atmosphere** (RD-24). That means vibrant natural colour, large readable silhouettes, cozy places interrupted by restrained danger, strong foreground/mid-ground/distance separation, and air you can see (fog, shafts, weather). The key art's own notes ("stylized realism between Valheim and Palworld") remain the identity anchor. The older "roughly 80% of the key-art impression" figure is superseded as a bar by RD-24. It survives only as history, never as a machine score. The look is not photoreal, cinematic AAA, flat low-poly placeholder art, or a collage of unrelated marketplace packs.

The world uses one coherent nature family, one village/architecture family and one prop family, extended through authored materials and chapter palettes. Creatures remain the highest-contrast designed subjects. All 57 baseline species definitions stand taller than the 1.80 m trainer; relative-scale repairs grow the smaller side and never shrink the large creature to make a camera or doorway easier.

Every representative view should provide:

- a near rail or framing element roughly 3–10 m from the camera, usually biased to one side;
- a readable subject or choice roughly 15–80 m away;
- a distant mass, landmark or terrain silhouette roughly 150–600 m away;
- horizon crossings in roughly 20–35% of the frame rather than an uninterrupted flat skyline;
- one clear visual route and at least one optional visual lure where the chapter activity plan calls for a detour.

These are composition tools, not mandatory clutter. Open fields gain interest from landform, herds, outcrops, ruins, weather and distant silhouettes. They do not receive uniform prop scatter merely to fill pixels.

## 2. Renderer, platform and technical ceiling

**Built today:** Godot 4.7 with the Compatibility renderer (`project.godot::renderer/rendering_method="gl_compatibility"`). It supports ordinary directional shadows, which remain part of the look. It does not provide SDFGI, SSR, volumetric fog, SSAO/SSIL or directional PCSS soft shadows. Do not describe this as "no real shadows".

**Renderer plan (owner, 2026-09-29, RD-25; F26 — not built).** Build a Forward+ rendering path with three quality presets:

| Preset | Renderer | Look features (per-preset toggles, values in `data/config/art.json` and the biome look configs) | Role |
|---|---|---|---|
| Low | Compatibility | Today's feature set: directional shadows, painted sky, authored value/hue separation, no volumetric fog/SSAO/SSIL | Fallback and weak-device preset. Must stay readable and keep biome identity. |
| Medium | Forward+ | Volumetric fog, SSAO, glow, medium shadow quality and draw distance; SSIL off by default (starting value) | Handheld target. Owner ROG Ally test: holds ≥30 fps handheld, 40 preferred, on the scripted route (F26#5). |
| High | Forward+ | Volumetric fog, SSAO, SSIL, glow, high shadow quality, far LOD/draw distance | Desktop target and the judge's primary preset. |

- The shipped default stays **Compatibility** until the owner's Ally run on Medium passes. Only then does Forward+ Medium become the default (F26#5, ACCEPTANCE §7). The test build ships the preset choice in settings (F26#1). Superseded (owner, 2026-09-29, RD-25): "Compatibility is locked; no renderer migration in this plan." The engine stays Godot 4.7; only the rendering path gains an option.
- Visual rows are judged on **High and Medium**; Low must stay readable (ACCEPTANCE §4). No scene's *identity* may depend on a Forward+-only feature: fog, shafts and SSAO add atmosphere on top of an authored base that already separates depth on Low.
- The earlier finding that fog "was tried and rejected as the Meadows distance solution" concerned depth fog that washed out the Compatibility distance read. Volumetric fog on Medium/High is now part of the Bar B atmosphere target, but every biome look bar (§4.1) must keep the 150–600 m silhouette layer readable through it.
- SDFGI and SSR are not in the preset plan. Water keeps the stylized treatment (depth colour, foam, current lines) and needs no SSR. Adding either feature needs frame-time evidence and a look-bar reason.
- Effects (§5.3, F25) must draw on every preset. A GPU-particle body needs a Compatibility fallback (TECHNICAL §11.5).
- Contact grounding may use geometry, baked/painted contact, decals, SSAO on Medium/High, or restrained supported shadowing on Low.

The Compatibility choice followed repeated owner Ally/Vulkan freezes (TECHNICAL §1). That history is why the default switch waits for on-device evidence.

The required handheld performance presentation is **1920×1080 on ROG Ally at 15 W**. It targets a 30 fps floor with **P95 frame time ≤33.3 ms** and **P99 ≤50 ms** in the named representative scenario; this remains unproven until the device evidence passes. **1280×720** remains a downscale/legibility stress raster and diagnostic capture, not the shipping performance target. Desktop art review also uses 1920×1080. UI is judged separately in `UX.md`; art must leave safe negative space for its fixed HUD zones. A software-GL capture can establish composition, silhouette, geometry and colour relationships, but cannot close fine lighting or on-device performance.

Structural performance baselines remain:

- Stronghold/Hall approach: at most **4,000 draw calls** from the correct `hall_approach` stand.
- First Meadows band: provisional ceiling **7,500 draw calls / 12 million primitives** in its named representative view.
- No more than **four** shadow-casting Omni/Spot lights may affect one outdoor point. The Hall's authored interior set is separate; no total-light cap was ever completed, so this document does not invent one.
- Collision streaming baseline: **100 m** radius, **0.5 s** update interval, **32 m** cells.
- Meadows grass baseline: **75,000 tufts, four blades, three segments**. The Pond is the localized lush reference, not a density setting to spread everywhere.

These are structural guardrails, not proof of the Ally target. F26 adds per-preset frame-time captures at 1920×1080 for a scripted route in each biome (F26#4). Effects add per-archetype particle budgets, and a worst-case four-creature fight must hold frame rate on the Medium capture (F25#4). Release evidence uses the exact 15 W profile and named representative view/weather/creature/combat/co-op load above: a continuous **30-minute representative capture** records P95/P99 frame time, and a separate **3-hour session** records memory growth, streaming, transition and crash stability. Invisible cost is optimized before visible identity is removed.

## 3. Shared world grammar

### 3.1 Ground, vegetation and paths

Ground needs close-range material transitions that communicate path, disturbed land, shore, rock, drained land and ordinary terrain without relying only on colour. Avoid a single blurred tiled material, visible seams, uniform paint and unexplained bare rectangles.

Where ecology supports it, views use three readable layers: ground cover, a mid-layer such as shrubs/saplings/rocks, and canopy or a distant equivalent. Open water, exposed cliff faces, intentional clearings, stronghold courts and story scars are valid exceptions. Vegetation forms groves, edges, clusters and clearings; it is never a uniform random carpet. Broadleaf proportions move toward believable canopy mass rather than the current roughly 1:3 trunk-to-canopy read, but a scale range is not permission to re-roll placement after every load.

Paths belong to the land. Their edges transition through wear, verge, roots, stones, banks or drainage. A player should be able to read the main route without a GPS trail while still seeing authored pulls off it. Each of the **6–10 meaningful optional activities per chapter** needs a visual lure appropriate to its distance: a silhouette, glow, creature cluster, smoke/fire, person, landmark or changed material, then a distinct close approach.

### 3.2 Landmarks and settlements

Principal landmarks must read at about **400 m** as a silhouette and again at **100 m** as an authored place. Their approaches answer where the player came from, where the entrance is, what looks optional and how the location belongs to the terrain. A marked destination cannot be a hero prop standing alone in undressed ground.

Settlements use coherent modules and human-scale thresholds. Every authored road that crosses a settlement boundary has a functioning gate, and dressed terrain/fencing prevents jumping or walking around the boundary elsewhere. Team Tether hardware escalates toward each finale through pylons, drained ground, occupation geometry and disciplined oxblood accents.

**Village road and Crossing Hall (owner, 2026-09-29, RD-17, RD-29; F17 — target, not built).** The village stays inside the Meadows as **one straight road**. Grandpa's farm and the homestead plot sit at its start by the Meadows exit and South Bridge road. **8–10 houses** from the installed MegaKit/medieval family face the road on both sides: Mira's shop, Tam's workshop, the inn, Halda's tournament board and arena lawn, the research keeper, and named residents whose houses have lived-in dressing. The **Crossing Hall** caps the far end. Visual requirements:

- From the farm door at the normal camera, the Hall reads as the destination down the road, day and night (F17#1). It is the tallest village landmark and needs a strong roofline, warm lit openings at night and a stone mass that contrasts with the timber houses.
- The nave holds the home arch plus seven portal arches: Tidewake, Cloudreach and Stormwood live-capable, and four biome-5–8 arches sealed and dark but visible. Each arch is signed by biome. A locked arch, an open arch, the fifth arch's *stir* after the Stormwood key (RD-22: glow, low hum, dust, no quest marker) and a sealed arch must read differently without text.
- The side Shrine Room holds eight pedestals. A hung relic reads from the doorway; an empty pedestal reads as waiting, not broken.
- The Home Key arrival (RD-18) plays a ~2 s raise-and-glow on the trainer, then light at the home arch. It uses the gold progression family, never oxblood.
- The Hall is kitbashed from installed families (MegaKit stone and timber, Fantasy Props). Claude lanes may do this scene-level work; new meshes stay with Codex (owner, 2026-09-27).

Superseded (owner, 2026-09-29, RD-29): the WORLD §3.2 through-road with a side lane, berry field/grove/stone-work areas and the cap of five street villagers. The overhead-plan-plus-motion witness method still applies to the new road (F17#0).

### 3.3 Lighting, sky and weather

Day uses warm directional sunlight and cooler fill while keeping shaded materials readable. Golden hour and night are distinct looks, not exposure multipliers. Night must preserve the trainer's lower-body and route readability. Painted clouds and the existing day/golden/night mood are strengths to preserve. Bar B asks for more: a visible atmosphere layer (fog banks, haze, sun shafts on Medium/High), a colour grade that changes with the hour, and weather that shifts mood. Each biome's concrete version lives in §4.1.

True gameplay dark is the narrower 22:00–03:00 semantic window even when dusk or dawn looks dark. Weather must change more than screen tint. Stormwood has no day/night presentation: it is a fixed purple storm, and its Surge phases are named from motion, rain, flash rhythm and light within that look (owner ruling). Stormwood's Calm, Building, Break and Fading phases must be nameable from motion, light and sound without HUD text; the art half uses copper flicker, wind response, flash rhythm, moss/understory value and post-strike steam or afterglow.

## 4. Four chapter identities

Chapter order is Meadows → Tidewake → Cloudreach → Stormwood (owner, 2026-09-29, RD-10). Each chapter is entered through its Crossing Hall portal; the former physical crossings between biomes are retired (RD-17), so no chapter's look may depend on arriving from a neighbouring biome.

| Chapter | Palette and light | Ground/vegetation/structure language | Required distance read |
|---|---|---|---|
| **Meadows** (1) | Warm grass, cool blue distance, natural flower accents, welcoming village light; oxblood appears only with Team Tether. | Terrain3D grassland, localized lush Pond, alternating thin and dense woods, broad roads and worn verges, quarry/root/river/old-growth transitions, the straight village road, homestead and camp from one installed family. | Village roofs, the road and the Crossing Hall orient the opening. The bridge, Warrens, Relay, Ironwood and the Meadows Hall stronghold form the escalating spine. The stronghold's occupation/drain must dominate without turning every band red. |
| **Tidewake** (2) | Open cyan/navy water, warm inhabited docks, pale foam, wet dark rock and Veilfall white; avoid generic pirate sepia. | Twelve authored islands, readable shallows/beaches, dune sand and dune grass (owner direction below), reeds/marsh, salt rock, docks/pumps/sluices, current lines and the white-falls mountain. The water surface stays closed and readable around the trainer and a swimming Ripplet mount (RD-32). | Veilfall is visible from First Shore and gains detail over the journey. Docks read as lived destinations; currents and cliffs visually explain gated approaches. Nothing here may need Fly. The dock exchange closes the chapter, but Tidewake no longer ends the game (RD-22). |
| **Cloudreach** (3) | Bright open sky, pale weathered stone, grass and restrained high-altitude flowers; strong warm/cool separation rather than white washout. | Distinct stacked cliff silhouettes, strata, trees and stones, rope and timber bridges with rails, moored-island anchors, height-aware settlements, ruined skyroads, shrines and a rustic stone domed aviary. Grass appears on all plausible walkable surfaces, not sheer faces. GolfModel sakura is licence-conditional and remains a local accent, never a biome-wide replacement; procedural bushes are preferred when they read better. | Lower plateaus reveal inaccessible upper country; the Fly pivot makes old silhouettes newly reachable. High-perch captures must use a corrected camera. |
| **Stormwood** (4, finale) | Cool blue-green moss from below, copper and glass highlights, black reflective pools, white-violet lightning; little direct sky until the aftermath; after release, rain lightens and lightning stops, the purple sky stays and the scars remain (owner ruling). | Giant old trunks, glass-fused scars, copper vines, wet roots, fungi, rod-line scaffolds and Stormglass arches. Safe places are visibly calm and grounded. The storm bear (RD-28, §7.2) belongs to this palette. | The rod line and Dynamo grow as the destination; Surge phase and safe radius remain legible in motion. After release, sky and ordinary forest colour return without erasing scars. The finale leads to the Home Key homecoming and credits (RD-22). |

Superseded (owner, 2026-09-29, RD-22): the Tidewake row's former "without a fifth-chapter tease" line. After the credits the fifth arch in the Crossing Hall visibly *stirs* when the fifth key is used (§3.2). It is a stir, not an opening, a quest or a cliffhanger.

Each chapter preserves the shared family while changing dominant landform, lighting direction, vegetation rhythm and Team Tether intrusion. Repainting Meadows assets alone is insufficient if the land silhouette and structure language remain unchanged.

**Tidewake island direction (owner, 2026-09-28):** favour sand dunes and dune grass over green meadow grass across the islands, with a Lake Michigan dunes feel. Broad pale warm sand, sparse upright sage/straw beach-grass clusters, exposed windward slopes, damp darker shore edges and sheltered pockets of shrubs/woodland define the surface rhythm. The inspected National Park Service Sleeping Bear Dunes [photo reference](https://www.nps.gov/slbe/learn/photosmultimedia/index.htm) supplies ecological and palette direction only; no photographic pixels enter the game. Preserve the stylized creature-adventure language and Veilfall's distinct monumental stronghold. This supersedes the earlier blanket green island-ground treatment; it does not authorize changes to traversal, terrain collision or encounter placement. Judge new island scenes against this owner direction as well as the established game references.

### 4.1 Per-biome look bar (F26#2; authored target, visual acceptance open)

These targets define the ordinary-camera judgment for Bar A and Bar B together. The restored owner boards in §4.2 were inspected when authoring this bar. They establish compositions, colour relationships and materials; they do not prove the current build meets them. Values live in the named configs, never in scripts. Stormwood has no day/night presentation (owner ruling): its time grade is the Surge phase. No fog or bloom may obscure a creature's face, a safe route, a telegraph, a portal sign or a named landmark.

| Biome | Sky | Fog and haze | Sun shafts | Time or phase grade | Weather mood | Configs and reference anchor |
|---|---|---|---|---|---|---|
| Village and Crossing Hall | Blue painted-cloud sky leaves a clear interval around the Hall's tallest roof; golden-hour clouds frame it rather than merging with its stone. | Cool morning air separates farm foreground, occupied houses and distant Hall in three depth bands. The whole road and Hall entrance remain readable from the farm door. Interior haze gives the nave depth without hiding any of eight arches or pedestals. | Late warm light follows the straight road; window light reveals nave beams and floor volume. Shafts have a visible source and occlusion, never disconnected cones. | Warm neutral day, amber late sun against cool stone, then a genuinely blue dark exterior with small warm door/window pools. Hall silhouette and portal labels survive night. | Rain darkens stone and road, softens shadows and narrows the warm pools. The village stays welcoming without lifting the entire night frame to grey. | `meadows_look.json`, `art.json`, `weather.json`; Hall config authored by F17. Key art: STARTING SETTLEMENT, DAY, NIGHT. |
| Meadows | Saturated but natural blue and shaped white clouds; no white exposure veil over the oak canopy or distant ridge. | Low dawn river mist and increasingly cool distant hills separate path, groves and ridgeline. A grove's dark interior retains trunk detail and the deployed creature's eyes. | Broken light at woodland edges and Ironwood canopy, aligned with the sun; fine shafts reveal tree gaps without replacing contact shadows. | Morning cool distance/warm tops; midday green leaves with dark contact; golden hour warm rim and longer shadows; blue night with localized camp light. Night must change values as well as hue. | Rain visibly wets/darkens greens, reduces direct light and adds ground mist. Occupied bands keep their authored drained identity; weather does not spread Team Tether red into ordinary vegetation. | `meadows_look.json`, `art.json`, `weather.json`. Key art: oak grove, river, DAY and NIGHT; `palworld-02-open-field-path.jpg` for ordinary-camera depth. |
| Tidewake | Broad maritime blue, high cloud masses and an open horizon. Veilfall's white falls separate from both clouds and cliff stone. | Blue sea haze increases across successive islands; near water stays transparent enough to read shore depth and current direction. Veilfall spray thickens locally at its base and parts at the entrance. | Cloud breaks and falls spray catch pale light over water; lit spray and dark wet rock remain separate. No solid white light slab across the route. | Noon cyan water/warm pale dunes, evening warm dock lights against cooler sea, navy night with white foam and readable shore contours. Island ground follows the owner's dunes ruling, rather than Meadow-green grass. | Squalls reduce distance contrast and roughen the surface while preserving required human-swimmable paths. Chapter restoration calms the authored currents without repainting the whole sea. | Water look/atmosphere configs owned by F39, `art.json`. `boards-2026-09-06/water-veilfall-stronghold-board.png`: approach, close entrance, night and Heart Chamber panels; dunes direction in §4. |
| Cloudreach | Clear high blue with structured clouds below the walkable shelves. The Aviary dome and pale cliff strata remain distinct from the bright cloud sea. | Haze separates stacked shelves and anchors; height-aware cloud banks live below or between them instead of bleaching the whole screen. Foreground rails, ledge edges and landing platforms keep strong contrast. | Narrow cloud-gap shafts cut between cliff masses and through the Aviary glass. Window framing and canopy occlude light; shafts never hide a traversal landing or airborne creature. | Crisp warm stone/cool sky by day, pink-gold upper rims at sunset, then dark-blue night with contained warm Aviary windows and restrained stars. Pale rock retains surface colour, never pure white washout. | Wind moves vegetation and cloud layers in coherent directions. Wind-road storm mood reduces direct sun and thickens lower banks while keeping route silhouettes readable. | `cloudreach_look.json`, `cloudreach_atmosphere.json`, `art.json`. `boards-2026-09-06/cloudreach-sky-aviary-stronghold-board.png`: exterior, side, night and Great Aviary panels. |
| Stormwood | The fixed purple storm sky shows through canopy breaks, with the split crown readable against it. Purple stays after release; the environment does not acquire a new day/night cycle. | Wet ground mist follows roots and hollows; successive trunks and storm-scarred platforms retain depth. Strike steam is brief and local, with safe-radius boundaries continuously legible. | Lightning lights air around the split/core, not the entire frame. After release, soft cloud-filtered shafts reveal the living wood and copper remains; no permanently blinding core column. | Calm cool moss and wet bark; Building strengthens restrained copper/blue cues; Break provides brief white-violet contrast; Fading returns to the readable calm base. Flash cadence follows Surge state, not a clock. | Rain rhythm, glass/copper highlights and flash density build together. After release rain lightens and lightning stops, but purple sky and scars remain under the owner ruling. | `stormwood_atmosphere.json`, `stormheart_presentation.json`. `boards-2026-09-06/stormwood-stormheart-tree-stronghold-board-a.png` for exterior framing and board B for core/platform light. |

**Preset contract.** Low preserves these palettes, landmark silhouettes, ordinary directional/contact shading, depth colours and localized practical lights using Compatibility-safe haze and authored materials. Forward+-only controls remain visibly unavailable. Medium adds bounded volumetric depth and source-occluded shafts, SSAO and restrained glow; it must meet the same bar with SSIL off. High adds SSIL, finer shadow filtering and longer LOD distance, rather than relying on extra bloom to hide weak forms. Both Medium and High preserve creature faces and telegraphs. Shadow Off suppresses visible sun shadows; the existing Terrain3D Compatibility workaround retains a minimum shadow map to avoid black terrain, so Off is not claimed to eliminate every shadow-pass cost.

**Frame matrix and judgment.** Each biome uses the same ordinary-camera approach, forward gameplay, reverse view and near detail, plus a real fight. Meadows/Tidewake/Cloudreach add morning, noon, golden hour, night, clear and authored bad weather; Stormwood substitutes all four Surge phases and pre/post-release weather. The Hall adds farm-door approach, nave, each arch/sign and Shrine Room. Capture matched High and Medium views at 1920×1080 and Low readability controls; record preset, actual renderer, time/phase/weather, position, route revision and frame timing. A code-blind judge receives images/motion and these references without source changes or defect-only prompts. Any missing material, clipped body, floating object, unreadable route, magenta slab or placeholder silhouette blocks the full bar. F26#3/#4 remain open until those actual matrices and route measurements exist.

Cloudreach stone must read as related exposed beds and weathered ledges at the
ordinary camera, with moss following shelf orientation. Grain must retain a
believable metre scale across cliff walls and crown banks; it must not turn the
grey-green authored palette brown, form continuous barcode rings, shimmer at
distance or rotate a wall's lighting normal toward the sky. The F26 cliff-course
surface in `art.json` is a candidate, OFF in Low/Medium/High pending matched native
review (`ralph/reports/VISUAL/lookdev/f26-cliff-courses/`). It addresses material
coherence only; the archived Cloudreach High/Medium full-bar FAILs and F26#3 remain
open. Terrain shape, ecology, creature appeal and atmosphere still require their
own integrated matrix evidence.

### 4.2 Reference boards

For Bar A's chapter-specific comparison, use:

- **Meadows and village:** the key art `docs/reference/tetherbound-meadows-keyart.png` (including its STARTING SETTLEMENT, DAY and NIGHT panels) and `docs/art/reference/19_Meadows_Asset_Boards_Visual_Direction.png`.
- **Tidewake:** `docs/reference/boards-2026-09-06/water-veilfall-stronghold-board.png` and `water-realm-creature-roster-board.png`, plus the owner's dune direction in §4.
- **Cloudreach:** `cloudreach-sky-aviary-stronghold-board.png` and `cloudreach-cliffs-creature-roster-board.png` in the same folder.
- **Stormwood:** `stormwood-stormheart-tree-stronghold-board-a.png`, `-board-b.png` and `stormwood-creature-roster-board.png` in the same folder.
- **Creatures and cast:** the sheets in `docs/art/reference/`.
- **Genre and appeal:** `docs/reference/palworld-0*.jpg`.

These are identity and composition references, never export assets or a request to trace their pixels. No Valheim or Animo comparison frame exists in `docs/reference/` today. Until F26 records one under the same direction-only rule, Bar B is judged against the written look bar in §4.1. A code-blind reviewer records Bar A and Bar B separately for the correct chapter; a Meadows-only comparison cannot certify later-biome identity. Restore the reference boards in a fresh container before judging (CODEX_START_HERE §0 step 5).

## 5. Creatures, characters and presentation subjects

### 5.1 Creatures

At the 1280×720 stress raster, a normal companion should remain at least **80 px** tall in at least **80%** of sampled ordinary-travel frames and return within **12 m** after a ten-second sprint. It flanks from trainer velocity, sustains at least **5 m/s** while walking and **8.6 m/s** while sprinting, and never settles between the camera and trainer. A visible wild subject intended as a lure is at least **40 px** in its authored reveal; the first outdoor ambient creature also meets that floor. Road herds occur at intervals no greater than **250 m** on the authored opening route. Small creatures under 1.3 m stage within **12 m** of the route and tall creatures over 1.7 m within **25 m** when intended as route reads. Per-instance scale variation stays within **±6%**, and adjacent bodies do not share identical pose and facing. Rebaseline these recovered values against the live 1.90–7.20 m roster and current camera; do not shrink creatures to satisfy them.

Every final creature needs a readable face/eye region, ground contact, habitat separation, designed colour blocks and a silhouette distinguishable at the gameplay camera. Mipmaps are required on active albedos. Supported locomotion, idle, combat, bed, mount/swim/fly and release poses must not show material interpenetration or floor clipping. "Any conceivable pose" is not a testable bar. Every species must read correctly in **hurt, faint/collapse (grounded), swim, fly-grip and ride** poses (F36#1; catalog P2-015, P2-016, P2-028, P2-071). Fight scale stays consistent with the travel scale (F36#2; P2-017, P2-062).

**Redesign additions (owner, 2026-09-29; targets, not built):**

- **Evolution lines (RD-28, F29).** One line per biome, each taken at a breakthrough feast: Mudsnout → Tuskroot or Ashtusk (L20), Mosshell → Cannonback (L30), Craghorn → Stormcapra (L40), Staticub → the new storm bear (L50). The evolved form must read as the same individual grown up. Keep the nickname plate, keep traits and gear accents visible, and let the palette carry over. It is larger than its base form. Starters do not evolve. Superseded (RD-28): Mudsnout's former L15-plus-bond evolution.
- **Gear accents (RD-14, F33#1).** An equipped Harness or Charm shows as a trim or glow on the body, one family per tier (Rootiron, Tidesteel, Skyglass, Stormglass). Accents stay small and must not break the silhouette, hide the face or use oxblood.
- **Traits and alphas (RD-30, F30).** Rare traits may add a restrained visual cue that never displaces rarity, shiny or alpha presentation. Shinies remain cosmetic.
- **Ripplet (RD-32, F37).** Surface-swim mount and dive presentation replace the dropped Teleport promise. The rider pose and the water surface stay readable while crossing currents.

General habitat separation targets **1.5:1** value or hue contrast in representative day and night samples, but identity wins over a blind universal threshold. Burrowback's grey-olive rock armour is a named exception: target about **1.30:1**, preserving its dark identity and improving rim/contact separation rather than bleaching the armour. Colour is not the only differentiator: rarity uses restrained scale, VFX, animation, habitat, behaviour and encounter staging. Shinies remain cosmetic.

Combat VFX are per-instance mesh effects and remain attached to the deployed body; bench progression gets HUD/audio feedback without spawning a phantom body flourish. The attack wind-up ring remains depth-tested magenta `#ff40e6`; the capture seal is warm gold and orb-sized. The current amber HUD wording/ring mismatch is a known integration defect. The F38–F41 matrices must show **no flat magenta rings or slabs** (criterion #5). The telegraph therefore needs a grounded, terrain-conforming or volumetric form. Whether its hue also changes is a COMBAT/UX decision this document does not make (§5.3).

### 5.2 Trainer and cast

The 1.80 m trainer is the scale ruler. Trainer silhouette needs two or three large colour blocks readable during travel and combat. Trainer gear (RD-14) may add small visible pieces but keeps that silhouette. Tether Commands (RD-12) are support gestures and throws, never an attack pose, because the human never deals damage. The six most repeated NPC faces are Meshy priorities (§7.1); every other humanoid stays on the installed cast. Named NPCs need distinct hair/face/clothing treatment and story-weight-appropriate presentation using the installed cast. Rank must read as grunt, officer, captain or Warden without relying only on a nameplate.

Oxblood/red is reserved for Team Tether on human clothing and occupation hardware. Hair colour is a mask layer rather than a tint over the whole face. Shared dialogue uses the actual speaker's portrait; a genuinely bodiless generic faction line uses a faction plate. The three authored stronghold readouts that borrow the player portrait remain deliberate exceptions.

### 5.3 Move effects, ultimates and hit feedback (F21, F25, F35; target, not built)

- **Archetypes (RD-23).** About 24 archetypes with real bodies: pebble/rock/boulder throw, fireball, flame cone, ember burst, sky lightning strike, chain lightning arc, water jet, bubble volley, tidal wave, wind blade, tornado, ice shard volley, frost breath, shadow bolt, psychic pulse, root/stone spikes, quake ring, claw/bite slash trail, charge-dash trail, heal pulse, buff aura, debuff hex, guard flash and catch/tether beam. Guard flash is visual only, because blocking does not exist. Parameters separate close cousins: a pebble toss is three small stones, a rock throw is one boulder (F25#2).
- **Readability.** Each effect reads at gameplay distance by its object and motion first, and colour second. Type colour follows the semantic type palette. Oxblood is never an effect colour except on Team Tether hardware. Damage shows when the effect arrives (F25#3).
- **Mastery.** Ranks 1–5 visibly grow an effect's size, count or trail (F25#5).
- **Ultimates (RD-27, F35).** A shared type×role set, plus unique ultimates for the three starters, the legendaries and the evolved forms. Each is a 2–3 s set piece that stays readable in a four-player fight and grows at each breakthrough.
- **Hit feedback (RD-13, F21).** Hitstop, knockback, reaction poses, damage numbers (crit, super-effective and resisted styles) and stagger flashes. Shake and rumble each have an accessibility toggle.
- **Budget.** Each archetype declares a particle budget. Mesh or CPU particles are the default; GPU particles only with a Compatibility fallback (TECHNICAL §11.5).

## 6. Interface and object art

UI art follows `UX.md`: deep blue-gray translucent surfaces, pale borders, teal/cyan interaction, warm gold progression, semantic danger/success/type colours, strong focus states and Xbox-layout prompts. It does not use Meshy or fantasy-scroll ornament. World-space prompts and markers must be readable without becoming billboard clutter.

Placed items and gatherables require a pickup-range silhouette before a label is read. Camp pieces share one scale and material family.

**Redesign objects (owner, 2026-09-29; targets, not built):**

- **Homestead stations (RD-16, F31#6).** Workbench, Forge, Kitchen, Altar, Den, Farm plots and chests each read as a distinct object at the normal camera. An attachment (Bellows, Tide quench tank, Spice rack, Meadow lens and the rest) sits beside or on its station and visibly adds that biome's material family, so the one "next upgrade" is legible in the world as well as the menu.
- **Forward camps (RD-15, F34).** A bed, a portable cookpot and a field workbench, smaller than the home stations and from the camp family.
- **Waystones (RD-19).** A small shrine from installed families, with a clear inactive vs activated state readable at 30 m.
- **Portal keys, relics and the Home Key.** Real items with a distinct silhouette in the hand, the backpack icon and on the Shrine pedestal. The Home Key uses the gold progression family.
- **Materials (RD-33).** Tier materials reuse the existing item art. Tide Pearl and the attuned ingredients are new items that need an icon and a world silhouette. Essence nodes and type crops read by type colour and shape, and must never suggest hunting or butchering. Tools, saddle and held objects must read on the trainer or creature at gameplay distance. A flat plane, blank box or floating `Label3D` is not a final sign, banner or structure. A scoped temporary stand-in may support a reachable path, but release acceptance tracks its replacement explicitly rather than declaring every data row placeholder-free.

## 7. Asset, reference and provenance gate

**Who does art (owner, 2026-09-27):** Claude lanes may do scene-level art on their own rows from installed asset families (kitbash, materials, shaders, lighting, dressing). New meshes and Meshy work stay with Codex. This partly supersedes the 2026-09-26 ruling that ceded all art to Codex. Codex's queue is now the F36 priority list (§7.1) and the catalog backlog (§9.1). `ralph/reports/VISUAL/AUDIT.md` remains the historical audit.

**Owner-authorized workflow:** agents may draft new reference art and run it through the already-held Meshy license for scoped current-roster and hero-asset improvements. This supersedes the owner-supplied-reference-only rule. The approval is already given for that workflow; do not require another permission turn solely because an agent authored the reference. Preserve established creature identity, reuse accepted art where it works, and fix named visible defects before considering a wider replacement pass. Additional humanoid population, paid upgrades and unattended mass generation remain outside scope. New roster species remain outside scope with **one exception, the storm bear** (§7.2, RD-28). The overnight batch in §7.1 is the one bounded, agent-attended generation batch the owner authorized (RD-26).

1. Inspect and reuse installed assets first. Preferred coherent families are Quaternius Stylized Nature, Quaternius Medieval Village and Quaternius Fantasy Props; Kenney is fallback rather than a second family mixed indiscriminately.
2. Use code, existing materials, Blender and the installed processing pipeline to adapt an approved installed asset where that can meet silhouette, scale, animation and material needs without hiding a quality defect. Record the transformation and retain the source provenance. If the installed catalogue cannot fill an approved routine environment/prop role, an appropriately licensed free pack remains a fallback with provenance and in-engine fit checks; a creature/humanoid still needs a saved, inspected reference consistent with its established identity, now supplied by the owner or drafted under the authorized workflow. No paid acquisition is inferred.
3. If the needed final silhouette still does not exist, choose a scoped existing subject and record the defect and intended improvement. Draft an original reference matching canon, palette, silhouette and rig needs; inspect it before Meshy submission. Use the existing image-to-3D pipeline and available licensed credits, with a bounded candidate count and no purchased top-up. Keep the reference, prompt/settings, task ID, candidate and provenance. Tool access does not prove input/output rights, topology, rig or animation quality; inspect and validate before integrating. Avoid copying comparison-game characters or shipping reference-board pixels.
4. Historical exceptions and accepted ship-as-is decisions remain provenance. The new owner workflow authorization is independent of those exhausted exceptions; use it for a concrete current defect, not as a reason to rebuild accepted assets without evidence.
5. Add a provenance row before committing an asset. File presence is not a licence. Record source, creator, acquisition date, exact licence/terms and redistribution limits; source archives remain out of exports. This pass assumes no new purchase, commission or external vendor dependency.
6. Reference boards, owner images, MoonG material and comparison-game frames are direction only. Never ship, trace or directly derive their pixels. The camp-board paw/leaf marks were scrubbed before the historical Meshy input. The key art wins palette conflicts.
7. Validate orientation and colour with Blender turntables/probes and then in the game. Do not approve a 3D asset from `matplotlib`/`mplot3d` views.

### 7.1 Meshy overnight batch and priority list (owner, 2026-09-29, RD-26; F36 — target)

The owner authorized a **bounded, agent-attended** Meshy batch for **about 25–30 named priority assets**. It replaces the "no unattended generation batches" restriction for this list only; it does not extend to other subjects.

**Rules:**

1. **Cap:** at most **30 Meshy generations per night**, counting every task id submitted: image-to-3D, refine, retexture and retries. The owner can raise the cap (CODEX_START_HERE §8). Buying credits is not authorized. A per-night log of task ids and the running count goes in the lane's evidence folder (F36#3).
2. **Attended:** an agent submits, watches and inspects every task. No fire-and-forget queue.
3. **Per-asset pipeline:** draft an original reference that matches canon, the established identity and the rig needs, then **inspect it** → Meshy image-to-3D on the existing licence → import → **scale check** against the 1.80 m trainer (grow the smaller side, never shrink a larger creature) → rig and the F36#1 pose set → **code-blind before/after judge** in engine at gameplay distance → **provenance row** in §7.3 (reference, prompt/settings, task ids, candidate, preparation scripts) → flag on only on PASS.
4. **Failure:** a candidate that fails any step stays **flag-off**, and the current asset stays the default. A failed subject is recorded with its reason. Two failed attempts on the same subject mean change approach (WORKFLOW stop rule), not a third identical run.
5. **Order:** subjects run in the table order below unless F36 re-ranks them on evidence. Confirm-only rows use no generation unless the confirmation fails.

**Priority list skeleton.** Every row is a **candidate, confirm in F36** (F36 lane writes reasons and final status). Main-path picks come from the frequency of species in the current band spawn tables and the Tidewake, Cloudreach and Stormwood encounter configs; boss aces come from BOSSES.

| # | Subject | Category | Reason (candidate) | Status |
|---:|---|---|---|---|
| 1 | Terrapup | Starter | Player-exclusive companion, on screen for the whole game; Meadows ride mount | candidate, confirm in F36 |
| 2 | Ripplet | Starter | Tidewake swim mount and L30 Dive (RD-32); swim poses | candidate, confirm in F36 |
| 3 | Galewisp | Starter | Cloudreach flyer; fly-grip pose | candidate, confirm in F36 |
| 4 | Mudsnout | Main path, evolution base | Most frequent early Meadows wild; L20 evolution base | candidate, confirm in F36 |
| 5 | Bramblebun | Main path | Most frequent band 1 wild (redesigned under the nine-creature exception) | candidate, confirm in F36 |
| 6 | Burrowback | Main path | Most frequent band 2 wild; Warden team; named 1.30:1 contrast exception | candidate, confirm in F36 |
| 7 | Meadowhart | Main path | Frequent band 3–4 wild; dedicated Meadows mount | candidate, confirm in F36 |
| 8 | Galecrest | Main path, boss ace | Most frequent band 4 wild; Veyra's switching ace. Already rebuilt (§7.3), so confirm only | candidate, confirm in F36 (confirm only) |
| 9 | Mirejaw | Main path | Frequent Tidewake wild; Nerissa team | candidate, confirm in F36 |
| 10 | Riverdrake | Main path, boss team | Frequent Tidewake wild; Venn and Nerissa teams | candidate, confirm in F36 |
| 11 | Cloudfang | Main path | Most frequent Cloudreach subject; Veyra team | candidate, confirm in F36 |
| 12 | Aeriex | Main path | Frequent Cloudreach subject; Veyra lane controller | candidate, confirm in F36 |
| 13 | Tanglevolt | Main path | Most frequent Stormwood subject; Marrow team | candidate, confirm in F36 |
| 14 | Sparkit | Main path | Frequent Stormwood subject; Marrow team; current Stormheart placeholder body | candidate, confirm in F36 |
| 15 | Tuskroot | Boss ace, evolution | Warden's ace; L20 evolved form with a unique ultimate | candidate, confirm in F36 |
| 16 | Ashtusk | Evolution | L20 alternative evolved form with a unique ultimate | candidate, confirm in F36 |
| 17 | Cannonback | Boss team, evolution | L30 evolved form; Venn and Nerissa teams; frequent Tidewake wild | candidate, confirm in F36 |
| 18 | Stormcapra | Evolution | L40 evolved form with a unique ultimate | candidate, confirm in F36 |
| 19 | Staticub | Evolution base | L50 line base; must read smaller than the storm bear | candidate, confirm in F36 |
| 20 | Voltarach | Boss ace | Marrow's final send-out | candidate, confirm in F36 |
| 21 | Veridian | Legendary | Meadows legendary; per-participant offer; unique ultimate | candidate, confirm in F36 |
| 22 | Abyssal Guardian | Legendary | Tidewake legendary; unique ultimate | candidate, confirm in F36 |
| 23 | Solmane | Legendary | Cloudreach legendary freed after Veyra; unique ultimate | candidate, confirm in F36 |
| 24 | Storm bear (working name *Stormursa*) | New creature | The one authorized new species (§7.2) | candidate, confirm in F36 |
| 25 | Grandpa | NPC face | Opening, Home Key, homecoming; most story weight | candidate, confirm in F36 |
| 26 | Wandering trainer body | NPC face | Most repeated humanoid body in data | candidate, confirm in F36 |
| 27 | Team Tether grunt family (`grunt`, `grunt_a`–`c`) | NPC face | Most repeated enemy humans | candidate, confirm in F36 |
| 28 | Young trainer body | NPC face | Repeated trainer body | candidate, confirm in F36 |
| 29 | Trader body | NPC face | Shopkeepers across biomes | candidate, confirm in F36 |
| 30 | Innkeeper body | NPC face | Inn and dock NPCs | candidate, confirm in F36 |

Alternates if F36 evidence reorders: Mosshell and Craghorn (evolution bases), Trailpup, Pipwing, Riptusk, Glimmermoth, and the Halda/Mira/Tam bodies if a village face outranks a repeated body.

**Stormwood legendary (settled default, CODEX_START_HERE §8.1):** the freed legendary is **Fulgocobra**, the existing species the Stormwood roster board marks Legendary. It replaces the Sparkit placeholder at ×1.8 in `stormwood_dynamo.json::captive` (nicknamed "the Stormheart"). This is not a roster expansion. Fulgocobra is a candidate for this priority list (confirm in F36) and needs a unique ultimate (F35#1).

### 7.2 The storm bear (owner, 2026-09-29, RD-28; F29 — target)

- **Only authorized new creature this pass.** Staticub evolves into it at the **L50** breakthrough feast. Its working name is *Stormursa*; the owner names it (CODEX_START_HERE §8).
- **Identity:** a Stormwood storm bear that reads as Staticub grown up, in the Stormwood palette (copper and glass accents, white-violet lightning). It is **larger than Staticub and taller than the 1.80 m trainer** (F29#3).
- **Not wild; not a starter source** (F29#4). It gets a unique ultimate (F35#1).
- **Pipeline:** drafted and inspected reference → Meshy → rig and the full pose set → scale → code-blind PASS in engine → provenance row. It stays **flag-gated** until PASS, and counts against the nightly cap.
- **Asset folder:** `assets/creatures/tetherbound/<name>/`.

### 7.3 Provenance and disposition ledger

The nine-creature expansion exception covers exactly **Nightburrow, Stormtrail, Sparkit, Cindercub, Shadelet, redesigned Bramblebun, Riftfrill, Ashtusk and Frostclaw**. Other already-used, subject-specific exceptions are the camp tent/fire/bed set; pickup families; saddle and South Bridge gate; four Meadows shrines; TM orb; Ironwood; and the documented Team Tether hero objects/tether machine. The single 2026-09-07 reference-art pilot historically required three generated reference images, a code-blind selection, then Meshy; text-to-3D was fallback only if image generation was unavailable. That record is provenance. The current permission comes from the newer owner instruction allowing agent-drafted references and Meshy; it does not mandate repeating the historical three-image pilot.

This section is the live provenance/disposition ledger within the authorized document set. Keep new asset rows here and cite the archived Asset Ledger for acquisition detail; do not create another document:

| Subject | Standing disposition |
|---|---|
| Tuskroot/Ashtusk, Riptusk, Staticub, Fulgocobra, Solmane attack derivatives | Code-authored attack-only transformations of the already installed assets, 2026-09-26. Original mesh, skin, material, reference and acquisition/redistribution provenance remain unchanged; no new external asset or generation. `tools/art_pipeline/author_attack_candidates.py` pins source SHA-256 and preserves original binary data and all other clips. Ground-contact and native playback evidence: `ralph/reports/VISUAL/CREATURE-ATTACK-CONTACT.md`; whole-creature Bars A/B remain open. |
| Camp set | Owner selected the generated tent despite fidelity limits; fire-ring scaling and the bed passed. Preserve the accepted result unless current gameplay evidence reopens it. |
| Pickups | Candy and potion-plant assets shipped with known defects; revive and mushroom passed. Do not infer a general pickup-generation allowance. |
| South Bridge gate | Thin from inaccessible angles and explicitly accepted ship-as-is. Reachable-view failure may reopen it; an inaccessible reverse view does not. |
| Nature Kit | Many meshes lack a usable albedo/palette atlas and render cyan/white. Only known-safe uses such as logs are production-ready until the material path is repaired. Evaluated Kenney cliffs and Poly Haven mossy rock were not shipped. |
| Tidewake dune grass atlas | Codex-authored offline HSV remap of installed `assets/environment/stylized_nature/Grass.png` to `derived/Grass_C_dune_sage_straw.png`, reproducible with `tools/art_pipeline/derive_water_dune_grass.py` and the palette in `water_dune_cover.json`. Preserves source UV layout, neutral pixels and alpha; source licence/redistribution limits remain those recorded for the installed stylized-nature family in `archive/docs/specs-2026-09-19/ASSET_LEDGER.md`. The inspected Sleeping Bear Dunes NPS photograph supplies ecological/palette direction only; no external pixels, new model, acquisition or purchase. Local duplicated materials use the derived atlas outside Veilfall; original atlas/materials remain intact. Requires normal VRAM-compressed 3D texture import. Default-off candidate pending production visual review. |
| Ironwood | Static, collisionless presentation mesh with disconnected/non-manifold geometry. Do not deform it or use it as collision; material, workyard, arrival and night presentation remain open. |
| Tether machine | Missing chains, clamps, runes, brass and true emissive channel; ring is zero-thickness. These are geometry/material dependencies. Current staging is **19.5 m** around the **5.8 m** Veridian; 15 m is retired. |
| NPC board/cast | The 24-subject board excluded the Warden. At the ledger snapshot 22 bodies were rigged and 15 placed. Tam/Old Bram body-gender allocation, Bram/Old Bram naming, nearly-black “silver” hair, limited male variation, fused-body hair and missing captain accessory are known constraints. The lost traveler/merchant rigs were explicitly accepted as closed and are not required unique bodies. |
| Historical references | Owner-board/generated outputs retain their recorded proprietary or owner-licensed status. No reference image is an export asset or tracing source. |
| Phase 2 regional shiny colourways (P2-030) | Codex-authored HSV repaints of the thirteen installed Aquaryn, Cannonback, Riptusk, Tidecoil, Voltwig, Staticub, Voltarach, Pebbik, Fulgocobra, Stormcapra, Solmane, Cliffspike and Breezetail GLB albedos, prepared 2026-09-28 with `tools/repaint_creature_textures.py` and `data/creatures/four_biome_colourways.json`. No acquisition, generated mesh, external pixels or purchase. Licence and redistribution limits remain those of each installed source, as recorded in `archive/docs/specs-2026-09-19/ASSET_LEDGER.md`; this transformation grants no new rights. Inspected regional roster boards supply direction only. Cream markings and dark source detail are preserved. New `*_extracted_base_color_shiny.png` assets use VRAM compression and remain behind `phase2_shiny_finish_enabled=false` pending production-frame review; ordinary colourways are unchanged. |
| Galecrest complete rebuild | Owner-directed replacement on main (Codex `4dea7705c`, landed as `a2e8d65db`). Inspected project-authored imagegen reference and Meshy task `01a0e4a9-3cfa-7210-b6d6-70f332337328` on the existing licence; new mesh/UV atlas, measured bird rig, six clips, anatomically masked colourways and model-rendered portrait; established 3.50 m scale kept. Reference, raw source, settings and preparation scripts: `assets/creatures/tetherbound/galecrest/{reference,source}/rebuild/`. Scoped blind review passes anatomy, face/neck and production readability on 12 day/night frames; continuous motion/contact is not certified, and feather highlights and alpha night wing midtones remain polish (`ralph/reports/VISUAL/galecrest-rebuild/`). The commit's `data/config/companion_presence.json` head-tracking override did **not** land, because main lacks the code that reads it; head tracking uses the shared defaults. No Cloudreach criterion closes. |
| Veilfall Heart Chamber crystal | Original Codex-authored seven-part faceted mesh and Compatibility shader from the inspected Veilfall board's Heart Chamber/Crystal panels; no copied pixels, acquired asset, Meshy task or purchase. Generator and provenance: `assets/environment/tidewake/heart_crystal/source/`. Placed on main under the `_crystal` node (`water_veilfall.gd`, `0a53b089f`). Full chamber Bars A/B remain open. |
| Veilfall pump station | Codex V-CX-12 asset (`37336cb9e`, landed as `db0afb78c`). Inspected OpenAI imagegen reference, then Meshy task `01a0e4f2-00c1-71d4-bd87-8405c6b8763c` on the existing licence; no purchase or batch. Provenance: `assets/environment/tidewake/pump_station/source/`. Scoped native review PASS (`ralph/reports/VISUAL/veilfall-props-native/visual-judge-r2.md`). On main but **not placed**; placement contract in `ralph/reports/VISUAL/veilfall-props-native/integration.md`. |
| Veilfall Heart Chamber banner | Codex V-CX-13 asset (`37336cb9e`, landed as `db0afb78c`). Original folded blue linen mesh and diamond crest following the inspected Veilfall board; recoloured installed Quaternius Fantasy Props cloth luminance; no generation service or purchase. Provenance: `assets/environment/tidewake/heart_banner/source/`. Scoped native PASS at the validated under-gallery position (±18, 3.5, 105), yaw ±90. On main but **not placed**. |
| Veilfall sluice gates (18 m, 30 m) | Codex V-CX-12 asset (`727dccd9f`, landed as `dc935c1b8`). Reference-inspected authored Blender geometry reusing the installed Quaternius Medieval wood atlas; no generation service or purchase. Provenance and integration contract: `assets/environment/tidewake/sluice_gate/source/`. Scoped native r3 PASS (`ralph/reports/VISUAL/veilfall-props-native/visual-judge-sluice-r3.md`); static receiving drum and instantaneous hide disclosed. On main but **not placed**. |

This table records historical dispositions; current scoped generation authority is the explicit owner workflow at the start of this section. Preserve accepted results unless a current defect justifies an iteration. Pack rows recorded as CC0 still require the final release audit, and Plumberry Plains material retains its no-resale/repackaging and no-AI-training restrictions. Public release needs a fresh licence audit with creator credits preserved.

## 8. Current production state

| Area | Baseline state at `b8eda885` (current verdicts: the Acceptance Board and `ralph/reports/VISUAL/AUDIT.md`) | What remains |
|---|---|---|
| Renderer/sky/day-night | **Built foundation.** Compatibility, ordinary directional shadows, painted sky and time presets exist. Forward+ path and presets **not built** (RD-25). | F26: Forward+ path, Low/Medium/High presets, per-biome look bar (§4.1), per-preset frame times, owner Ally test before any default switch; night legibility. |
| Meadows locations | **Built and individually reviewed.** The prior ledger reports 23/23 named rows promoted. | Whole-chapter Bar A/B remain open; continuous cohesion, route pulls, creature/ground defects and representative motion still need acceptance. |
| Cloudreach | **Broadly built, visually unaccepted.** Current cited ledger is 0 PASS / 9 POLISH / 3 FAIL. | Correct high-perch camera, cliff silhouettes, settlement/route cohesion, grass/material quality and a fresh full ledger. |
| Stormwood | **Systems and presentation partially built.** World, Surge data, Dynamo and ending are mounted/focused-tested. | Full-route rendered evidence, distinct forest readability, phase clarity, final asset quality and Ally proof. |
| Tidewake | **World and finale systems partially built.** Islands, currents, Veilfall, Guardian ceremony and restored state exist. | Full chapter visual witness, shoreline/dock cohesion, mount presentation, water readability and final epilogue presentation. |
| Creature art | **Mixed stand-ins, generated exceptions and installed replacements.** Shared material/colourway systems exist. | The F36 priority list under RD-26, the pose set (hurt, faint, swim, fly-grip, ride), scale consistency, topology/rig/animation repairs, mipmaps and slope/contact validation. |
| Humanoid cast | **Installed and reusable.** Material variants, ranks and portraits exist. | Resolve named allocation/identity defects through approved cast/material work; no unapproved new humanoids. |
| Props/pickups/UI | **Substantial built foundation.** Camp/pickup families, UI tokens and prompt assets exist. | Known accepted defects stay closed unless gameplay reopens them; final consistency/accessibility pass and provenance audit remain. |
| Village road and Crossing Hall | **Not built.** The current village is the earlier road settlement; no Hall, portal arches, Shrine Room or waystones exist. | F17 layout and Hall kitbash, F18 arches/waystones, F38 burn-down to the full bar. |
| Homestead stations and camps | **Partial.** Existing home/camp pieces (tent, campfire, bedroll, beds, floor, walls, roof) exist; the six stations, attachments and forward camps do not. | F31, F34 station/camp identity; F31#6 judge. |
| Move effects and ultimates | **Partial.** Mesh-bound combat VFX, bursts, impact flash and projectiles exist; the ~24-archetype library, mastery scaling and ultimates do not. | F21, F25, F35. |
| Priority creature/NPC models and storm bear | **Not started** under RD-26. Galecrest and the Warden are prior rebuilds. | F36 priority list (§7.1), F29 storm bear (§7.2). |
| Codex catalog backlog | **Open.** 116 rows, 106 with impact >12 (§9.1). | F38–F41 burn-down to the full bar; routed camera/pose/UI rows. |

## 9. Acceptance package

For each chapter, capture the same representative matrix from the shipping build: arrival/approach, player-facing route, reverse route, close detail/material view, optional lure, key settlement, ordinary combat, finale at about 400 m and 100 m, and post-finale change. Capture day and night where the chapter supports them, plus its defining weather state. The F38–F41 frame matrix (approach, gameplay camera, reverse, detail, day/night, weather, a real fight) is judged on **High and Medium**, with Low checked for readability (#3). Include native 1920×1080 Ally 15 W presentation, the 1280×720 downscale stress raster and desktop 1080p. F42 also uses 1280×800 for screen readability. Visual work affecting motion also needs a short motion witness for ground contact, vegetation, weather, mount/fly/swim or VFX.

A fresh code-blind critic receives only current frames, the approved reference set and the rubric. It names frame-specific defects, ranks the largest three gaps and answers Bars A/B. It is not told what changed or the performance budget. Two rounds with no new defect and no measured movement establish a mechanism ceiling; change the asset or approach instead of repeating tint/scatter tuning.

Final reference parity, creature style and any asset-dependent silhouette compromise receive a code-blind independent agent verdict against the owner-settled Bars A/B and the saved reference set. Record exact frame, defect, chosen repair and the re-captured result. If an authorized asset path cannot meet the bar, keep it open rather than silently accepting a weaker silhouette. Performance acceptance requires device telemetry; a screenshot cannot prove it. Real audience appeal remains unmeasured without human players.

### 9.1 Codex visual catalog: the F38–F41 backlog

`ralph/reports/VISUAL/phase2/catalog.csv` is the defect backlog to the full bar. It has **116 rows, 106 of them with impact >12**, plus a `top20.csv` for each biome under `ralph/reports/VISUAL/phase2/<biome>/`. When read for this revision (2026-09-29), the status column held 45 open, 28 needs_capture, 23 deferred, 14 candidate_off, 4 fixed and 2 blocked. By fix class: scene 33, UI 24, camera 22, animation 14, material 12, mesh 10, lighting 1. Rows touch Meadows 46 times, Tidewake 44, Stormwood 44 and Cloudreach 41; many rows span biomes. The CSV is the live record; these counts are a snapshot, not status.

Recurring themes are terrain landforms, landmark identity, creature poses and scale, fight and catch camera, magenta effects, UI, item identity and NPC silhouettes.

Rules (CODEX_START_HERE §3.6):

- **Re-score after F26.** Each biome lane re-captures at least 200 frames and re-scores its rows against the new bar before fixing (F38#0–F41#0).
- **Fix to the full bar, in impact order.** First the biome's top 20, then every remaining row with impact >12. Each fix needs a before/after code-blind PASS, and a PR carries one or two items (#1, #2).
- **Deferral is not a status.** At re-score, each `deferred` row becomes open, fixed, or blocked with a named owner and reason. A `candidate_off` row counts as open until its fix is enabled on main with a PASS.
- **Routing across lanes.** Fight-camera and spacing rows (P2-062, P2-092 class) go to F21#4. Creature pose and scale rows (P2-015, P2-016, P2-017, P2-028, P2-062, P2-071) go to F36#1–#2. UI rows go to F42#0. The biome lane still re-verifies them in its matrix.
- **Hero landmarks** (village road and Crossing Hall, Veilfall, the Sky Aviary, the Stormheart tree) must read at distance and up close (#4). No flat magenta rings or slabs, placeholder materials, floating bodies or clipping may remain in the matrix (#5).

## 10. Out of scope

- Making Forward+ the default before the owner's Ally test passes; SDFGI, SSR or a PCSS requirement; any scene whose identity survives only on Forward+ (§2). Superseded (RD-25): volumetric fog and renderer work are no longer out of scope; they are the F26 preset path.
- New creature/humanoid meshes or Meshy generations without the reference and subject approvals above, beyond the §7.1 list, above the nightly cap, or any new species other than the storm bear.
- Pixel-copying comparison games or shipping reference art.
- Solving topology, face or silhouette defects through global saturation/tint alone.
- Uniformly filling open fields, cliffs or water with three vegetation layers.
- Shrinking creatures to fit cameras, arenas, doors or mounts.
- Building biomes 5–8 in this pass or adding an endless procedural world. The Hall's four sealed arches and the empty pedestals are the only visible eight-biome planning (RD-09).
- Claiming commercial finish from counts, config, isolated source renders or one attractive screenshot.

## 11. Recovery dispositions

- **S04/S30/S34, D10, D24, D63, D80, D85:** retain one-family coherence, stand-in/final distinction, shared-material correctness, mesh-bound VFX and evidence discipline; supersede obsolete scale values and green-faction examples.
- **S08 and owner asset recovery:** retain provenance-before-commit, redistribution audit and reference restrictions. Named historical carve-outs remain narrow; this file creates no new authorization.
- **DR19/D74:** preserve Burrowback's armour and the 1.30:1 bounded treatment rather than a blind universal contrast repair.
- **DR21/D80 and DR24/D94:** preserve deployed-body effects, magenta wind-up and orb-sized gold capture seal; record the current HUD colour inconsistency.
- **DR22/D81/D87:** preserve faction-plate and actual-speaker portrait rules, including the stronghold exceptions and mask-only hair colour.
- **B04/B11/B17/B26/B27:** carry chapter silhouette, weather, composition, route and subject-readability constraints; current counts and old coordinates are not acceptance.
- **B03/B16/B24/B33:** state landed/focused/continuous/accepted separately. Stormwood and Tidewake systems exist; neither has fresh four-chapter visual acceptance.
- **Owner redesign 2026-09-29 (RD-01, RD-09, RD-10, RD-17, RD-22, RD-24–RD-29):** redefined Bars A/B, the Forward+ preset plan, the Meshy overnight batch, the storm bear, the village road and Crossing Hall, the new chapter order and the fifth-arch stir supersede the matching earlier text in this file. Each supersession is marked where it occurs.
- **Archived Asset Ledger, Environment/UI Bible, Visual Bible V2 and Performance Budget:** retain their supported art, provenance and structural-budget rules; retire unsupported fog guidance, retired draw baselines and any implied Ally FPS guarantee.
