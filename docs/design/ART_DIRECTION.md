# Art Direction

## Contract and evidence boundary

Tetherbound is a Windows-first, controller-first creature expedition action RPG for one to four players. The current production pass covers the Meadows, Cloudreach Cliffs, the Stormwood and Tidewake. Eight good hours is an acceptable first clear, not a duration floor; density, finish and a complete homecoming matter more than stretching playtime. Eight biomes remain a future ambition and do not expand this four-biome pass. Its visual job is to make a finite authored journey feel lush, legible, inhabited and worth exploring while keeping the five-creature relationship at the centre of every frame.

This document defines the target and the production boundaries. It does not declare the current game visually accepted. A configuration value, placed prop, imported mesh or passing screenshot test proves only that the element exists. Final visual acceptance requires current production captures, motion checks, an independent code-blind agent verdict against the settled references and recorded target-hardware telemetry.

The two existing comparison questions remain open and explicitly **aspirational**:

1. **Bar A — identity:** do representative production frames read as belonging to the world in `docs/reference/tetherbound-meadows-keyart.png`?
2. **Bar B — genre/finish:** beside `docs/reference/palworld-0*.jpg`, do the frames look like they are trying to be the same kind of polished creature-adventure game?

A “yes” means the candidate is moving toward the intended identity and production register. It does not claim asset equivalence, commercial readiness or copied composition. Current whole-chapter evidence has not closed either bar. Several creature and environment silhouettes are asset-gated; texture work cannot repair unsuitable topology, a buried face, a missing feature or an animation set that cannot express the required action.

## 1. Visual thesis

The shared style is stylized realism between Valheim's environmental readability and Palworld/Fortnite's environmental finish: vibrant natural colour, large readable silhouettes, cozy places interrupted by restrained danger, and strong foreground/mid-ground/distance separation. The recovered visual direction asks for roughly 80% of the website/key-art impression. That percentage is an aspirational human comparison, not a machine score or permission to declare commercial parity. It is not photoreal, cinematic AAA, flat low-poly placeholder art, or a collage of unrelated marketplace packs.

The world uses one coherent nature family, one village/architecture family and one prop family, extended through authored materials and chapter palettes. Creatures remain the highest-contrast designed subjects. All 57 baseline species definitions stand taller than the 1.80 m trainer; relative-scale repairs grow the smaller side and never shrink the large creature to make a camera or doorway easier.

Every representative view should provide:

- a near rail or framing element roughly 3–10 m from the camera, usually biased to one side;
- a readable subject or choice roughly 15–80 m away;
- a distant mass, landmark or terrain silhouette roughly 150–600 m away;
- horizon crossings in roughly 20–35% of the frame rather than an uninterrupted flat skyline;
- one clear visual route and at least one optional visual lure where the chapter activity plan calls for a detour.

These are composition tools, not mandatory clutter. Open fields gain interest from landform, herds, outcrops, ruins, weather and distant silhouettes. They do not receive uniform prop scatter merely to fill pixels.

## 2. Renderer, platform and technical ceiling

Godot 4.7 Compatibility is locked. There is no renderer migration in this plan. Compatibility supports ordinary directional shadows, which remain part of the look. It does not provide SDFGI, SSR, volumetric fog, SSAO or directional PCSS soft shadows for this project. Do not describe this as “no real shadows,” and do not design a scene whose identity depends on unsupported features.

Depth comes from authored value and hue separation, terrain-material aerial gradients, silhouette layering and supported shadows. Fog was tried and rejected as the Meadows distance solution. Water uses the established stylized non-reflective treatment; SSR is not a future acceptance dependency. Contact grounding may use geometry, baked/painted contact, decals or restrained supported shadowing. A renderer switch is outside scope.

The required handheld performance presentation is **1920×1080 on ROG Ally at 15 W**. It targets a 30 fps floor with **P95 frame time ≤33.3 ms** and **P99 ≤50 ms** in the named representative scenario; this remains unproven until the device evidence passes. **1280×720** remains a downscale/legibility stress raster and diagnostic capture, not the shipping performance target. Desktop art review also uses 1920×1080. UI is judged separately in `UX.md`; art must leave safe negative space for its fixed HUD zones. A software-GL capture can establish composition, silhouette, geometry and colour relationships, but cannot close fine lighting or on-device performance.

Structural performance baselines remain:

- Stronghold/Hall approach: at most **4,000 draw calls** from the correct `hall_approach` stand.
- First Meadows band: provisional ceiling **7,500 draw calls / 12 million primitives** in its named representative view.
- No more than **four** shadow-casting Omni/Spot lights may affect one outdoor point. The Hall's authored interior set is separate; no total-light cap was ever completed, so this document does not invent one.
- Collision streaming baseline: **100 m** radius, **0.5 s** update interval, **32 m** cells.
- Meadows grass baseline: **75,000 tufts, four blades, three segments**. The Pond is the localized lush reference, not a density setting to spread everywhere.

These are structural guardrails, not proof of the Ally target. Release evidence uses the exact 15 W profile and named representative view/weather/creature/combat/co-op load above: a continuous **30-minute representative capture** records P95/P99 frame time, and a separate **3-hour session** records memory growth, streaming, transition and crash stability. Invisible cost is optimized before visible identity is removed.

## 3. Shared world grammar

### 3.1 Ground, vegetation and paths

Ground needs close-range material transitions that communicate path, disturbed land, shore, rock, drained land and ordinary terrain without relying only on colour. Avoid a single blurred tiled material, visible seams, uniform paint and unexplained bare rectangles.

Where ecology supports it, views use three readable layers: ground cover, a mid-layer such as shrubs/saplings/rocks, and canopy or a distant equivalent. Open water, exposed cliff faces, intentional clearings, stronghold courts and story scars are valid exceptions. Vegetation forms groves, edges, clusters and clearings; it is never a uniform random carpet. Broadleaf proportions move toward believable canopy mass rather than the current roughly 1:3 trunk-to-canopy read, but a scale range is not permission to re-roll placement after every load.

Paths belong to the land. Their edges transition through wear, verge, roots, stones, banks or drainage. A player should be able to read the main route without a GPS trail while still seeing authored pulls off it. Each of the **6–10 meaningful optional activities per chapter** needs a visual lure appropriate to its distance: a silhouette, glow, creature cluster, smoke/fire, person, landmark or changed material, then a distinct close approach.

### 3.2 Landmarks and settlements

Principal landmarks must read at about **400 m** as a silhouette and again at **100 m** as an authored place. Their approaches answer where the player came from, where the entrance is, what looks optional and how the location belongs to the terrain. A marked destination cannot be a hero prop standing alone in undressed ground.

Settlements use coherent modules and human-scale thresholds. The Meadows village is a road settlement: recognizable village-house silhouettes sit along roads, with a berry field, tree grove and stone-working area. It has at most five street villagers; population is redistributed into the journey. Every authored road that crosses the village boundary has a functioning gate, and dressed terrain/fencing prevents jumping or walking around the boundary elsewhere. Team Tether hardware escalates toward each finale through pylons, drained ground, occupation geometry and disciplined oxblood accents.

For the Meadows village, WORLD §3.2 fixes the new road topology. The visual witness must include a comparable overhead road plan and production-camera approach, centre, side-lane and departure motion at day and night. A blind reviewer must be able to identify the through-road, a meaningful side lane, the berry field/grove/stone-work areas and the bridge exit from the actual scene. The old compact circular silhouette with new colour or props does not pass.

### 3.3 Lighting, sky and weather

Day uses warm directional sunlight and cooler fill while keeping shaded materials readable. Golden hour and night are distinct looks, not exposure multipliers. Night must preserve the trainer's lower-body and route readability. Painted clouds and the existing day/golden/night mood are strengths to preserve.

True gameplay dark is the narrower 22:00–03:00 semantic window even when dusk or dawn looks dark. Weather must change more than screen tint. Stormwood's Calm, Building, Break and Fading phases must be nameable from motion, light and sound without HUD text; the art half uses copper flicker, wind response, flash rhythm, moss/understory value and post-strike steam or afterglow.

## 4. Four chapter identities

| Chapter | Palette and light | Ground/vegetation/structure language | Required distance read |
|---|---|---|---|
| **Meadows** | Warm grass, cool blue distance, natural flower accents, welcoming village light; oxblood appears only with Team Tether. | Terrain3D grassland, localized lush Pond, alternating thin and dense woods, broad roads and worn verges, quarry/root/river/old-growth transitions, village and camp from one installed family. | Village roofs and roads orient the opening; bridge, Warrens, Relay, Ironwood and Hall form the escalating spine. The Hall's occupation/drain must dominate without turning every band red. |
| **Cloudreach** | Bright open sky, pale weathered stone, grass and restrained high-altitude flowers; strong warm/cool separation rather than white washout. | Distinct stacked cliff silhouettes, strata, trees and stones, rope and timber bridges with rails, moored-island anchors, height-aware settlements, ruined skyroads, shrines and a rustic stone domed aviary. Grass appears on all plausible walkable surfaces, not sheer faces. GolfModel sakura is licence-conditional and remains a local accent, never a biome-wide replacement; procedural bushes are preferred when they read better. | Lower plateaus reveal inaccessible upper country; the Fly pivot makes old silhouettes newly reachable. High-perch captures must use a corrected camera. |
| **Stormwood** | Cool blue-green moss from below, copper and glass highlights, black reflective pools, white-violet lightning; little direct sky until the aftermath. | Giant old trunks, glass-fused scars, copper vines, wet roots, fungi, rod-line scaffolds and Stormglass arches. Safe places are visibly calm and grounded. | The rod line and Dynamo grow as the destination; Surge phase and safe radius remain legible in motion. After release, sky and ordinary forest colour return without erasing scars. |
| **Tidewake** | Open cyan/navy water, warm inhabited docks, pale foam, wet dark rock and Veilfall white; avoid generic pirate sepia. | Twelve authored islands, readable shallows/beaches, reeds/marsh, salt rock, docks/pumps/sluices, current lines and the white-falls mountain. Water surface stays closed and readable around trainer and mount. | Veilfall is visible from First Shore and gains detail over the journey. Docks read as lived destinations; currents and cliffs visually explain gated approaches. Restored currents and civilian dock use close the regional story, without a fifth-chapter tease. |

Each chapter preserves the shared family while changing dominant landform, lighting direction, vegetation rhythm and Team Tether intrusion. Repainting Meadows assets alone is insufficient if the land silhouette and structure language remain unchanged.

For Bar A's chapter-specific comparison, use the Meadows key art with `docs/art/reference/19_Meadows_Asset_Boards_Visual_Direction.png` in Meadows; `docs/reference/boards-2026-09-06/cloudreach-sky-aviary-stronghold-board.png` and its creature-roster board in Cloudreach; both Stormwood boards in that folder with its creature-roster board in Stormwood; and the water-veilfall-stronghold plus water-realm creature-roster boards there in Tidewake. These are identity and composition references, never export assets or a request to trace their pixels. Bar B uses the same existing gameplay comparison frames for every chapter. A code-blind reviewer records Bar A and Bar B separately for the correct chapter; a Meadows-only comparison cannot certify later-biome identity.

## 5. Creatures, characters and presentation subjects

### 5.1 Creatures

At the 1280×720 stress raster, a normal companion should remain at least **80 px** tall in at least **80%** of sampled ordinary-travel frames and return within **12 m** after a ten-second sprint. It flanks from trainer velocity, sustains at least **5 m/s** while walking and **8.6 m/s** while sprinting, and never settles between the camera and trainer. A visible wild subject intended as a lure is at least **40 px** in its authored reveal; the first outdoor ambient creature also meets that floor. Road herds occur at intervals no greater than **250 m** on the authored opening route. Small creatures under 1.3 m stage within **12 m** of the route and tall creatures over 1.7 m within **25 m** when intended as route reads. Per-instance scale variation stays within **±6%**, and adjacent bodies do not share identical pose and facing. Rebaseline these recovered values against the live 1.90–7.20 m roster and current camera; do not shrink creatures to satisfy them.

Every final creature needs a readable face/eye region, ground contact, habitat separation, designed colour blocks and a silhouette distinguishable at the gameplay camera. Mipmaps are required on active albedos. Supported locomotion, idle, combat, bed, mount/swim/fly and release poses must not show material interpenetration or floor clipping. “Any conceivable pose” is not a testable bar.

General habitat separation targets **1.5:1** value or hue contrast in representative day and night samples, but identity wins over a blind universal threshold. Burrowback's grey-olive rock armour is a named exception: target about **1.30:1**, preserving its dark identity and improving rim/contact separation rather than bleaching the armour. Colour is not the only differentiator: rarity uses restrained scale, VFX, animation, habitat, behaviour and encounter staging. Shinies remain cosmetic.

Combat VFX are per-instance mesh effects and remain attached to the deployed body; bench progression gets HUD/audio feedback without spawning a phantom body flourish. The attack wind-up ring remains depth-tested magenta `#ff40e6`; the capture seal is warm gold and orb-sized. The current amber HUD wording/ring mismatch is a known integration defect.

### 5.2 Trainer and cast

The 1.80 m trainer is the scale ruler. Trainer silhouette needs two or three large colour blocks readable during travel and combat. Named NPCs need distinct hair/face/clothing treatment and story-weight-appropriate presentation using the installed cast. Rank must read as grunt, officer, captain or Warden without relying only on a nameplate.

Oxblood/red is reserved for Team Tether on human clothing and occupation hardware. Hair colour is a mask layer rather than a tint over the whole face. Shared dialogue uses the actual speaker's portrait; a genuinely bodiless generic faction line uses a faction plate. The three authored stronghold readouts that borrow the player portrait remain deliberate exceptions.

## 6. Interface and object art

UI art follows `UX.md`: deep blue-gray translucent surfaces, pale borders, teal/cyan interaction, warm gold progression, semantic danger/success/type colours, strong focus states and Xbox-layout prompts. It does not use Meshy or fantasy-scroll ornament. World-space prompts and markers must be readable without becoming billboard clutter.

Placed items and gatherables require a pickup-range silhouette before a label is read. Camp pieces share one scale and material family. Tools, saddle and held objects must read on the trainer or creature at gameplay distance. A flat plane, blank box or floating `Label3D` is not a final sign, banner or structure. A scoped temporary stand-in may support a reachable path, but release acceptance tracks its replacement explicitly rather than declaring every data row placeholder-free.

## 7. Asset, reference and provenance gate

**Owner-authorized workflow:** agents may draft new reference art and run it through the already-held Meshy license for scoped current-roster and hero-asset improvements. This supersedes the owner-supplied-reference-only rule. The approval is already given for that workflow; do not require another permission turn solely because an agent authored the reference. Preserve established creature identity, reuse accepted art where it works, and fix named visible defects before considering a wider replacement pass. New roster species, additional humanoid population, paid upgrades and unattended mass generation remain outside scope.

1. Inspect and reuse installed assets first. Preferred coherent families are Quaternius Stylized Nature, Quaternius Medieval Village and Quaternius Fantasy Props; Kenney is fallback rather than a second family mixed indiscriminately.
2. Use code, existing materials, Blender and the installed processing pipeline to adapt an approved installed asset where that can meet silhouette, scale, animation and material needs without hiding a quality defect. Record the transformation and retain the source provenance. If the installed catalogue cannot fill an approved routine environment/prop role, an appropriately licensed free pack remains a fallback with provenance and in-engine fit checks; a creature/humanoid still needs a saved, inspected reference consistent with its established identity, now supplied by the owner or drafted under the authorized workflow. No paid acquisition is inferred.
3. If the needed final silhouette still does not exist, choose a scoped existing subject and record the defect and intended improvement. Draft an original reference matching canon, palette, silhouette and rig needs; inspect it before Meshy submission. Use the existing image-to-3D pipeline and available licensed credits, with a bounded candidate count and no purchased top-up. Keep the reference, prompt/settings, task ID, candidate and provenance. Tool access does not prove input/output rights, topology, rig or animation quality; inspect and validate before integrating. Avoid copying comparison-game characters or shipping reference-board pixels.
4. Historical exceptions and accepted ship-as-is decisions remain provenance. The new owner workflow authorization is independent of those exhausted exceptions; use it for a concrete current defect, not as a reason to rebuild accepted assets without evidence.
5. Add a provenance row before committing an asset. File presence is not a licence. Record source, creator, acquisition date, exact licence/terms and redistribution limits; source archives remain out of exports. This pass assumes no new purchase, commission or external vendor dependency.
6. Reference boards, owner images, MoonG material and comparison-game frames are direction only. Never ship, trace or directly derive their pixels. The camp-board paw/leaf marks were scrubbed before the historical Meshy input. The key art wins palette conflicts.
7. Validate orientation and colour with Blender turntables/probes and then in the game. Do not approve a 3D asset from `matplotlib`/`mplot3d` views.

The nine-creature expansion exception covers exactly **Nightburrow, Stormtrail, Sparkit, Cindercub, Shadelet, redesigned Bramblebun, Riftfrill, Ashtusk and Frostclaw**. Other already-used, subject-specific exceptions are the camp tent/fire/bed set; pickup families; saddle and South Bridge gate; four Meadows shrines; TM orb; Ironwood; and the documented Team Tether hero objects/tether machine. The single 2026-09-07 reference-art pilot historically required three generated reference images, a code-blind selection, then Meshy; text-to-3D was fallback only if image generation was unavailable. That record is provenance. The current permission comes from the newer owner instruction allowing agent-drafted references and Meshy; it does not mandate repeating the historical three-image pilot.

This section is the live provenance/disposition ledger within the authorized document set. Keep new asset rows here and cite the archived Asset Ledger for acquisition detail; do not create another document:

| Subject | Standing disposition |
|---|---|
| Camp set | Owner selected the generated tent despite fidelity limits; fire-ring scaling and the bed passed. Preserve the accepted result unless current gameplay evidence reopens it. |
| Pickups | Candy and potion-plant assets shipped with known defects; revive and mushroom passed. Do not infer a general pickup-generation allowance. |
| South Bridge gate | Thin from inaccessible angles and explicitly accepted ship-as-is. Reachable-view failure may reopen it; an inaccessible reverse view does not. |
| Nature Kit | Many meshes lack a usable albedo/palette atlas and render cyan/white. Only known-safe uses such as logs are production-ready until the material path is repaired. Evaluated Kenney cliffs and Poly Haven mossy rock were not shipped. |
| Ironwood | Static, collisionless presentation mesh with disconnected/non-manifold geometry. Do not deform it or use it as collision; material, workyard, arrival and night presentation remain open. |
| Tether machine | Missing chains, clamps, runes, brass and true emissive channel; ring is zero-thickness. These are geometry/material dependencies. Current staging is **19.5 m** around the **5.8 m** Veridian; 15 m is retired. |
| NPC board/cast | The 24-subject board excluded the Warden. At the ledger snapshot 22 bodies were rigged and 15 placed. Tam/Old Bram body-gender allocation, Bram/Old Bram naming, nearly-black “silver” hair, limited male variation, fused-body hair and missing captain accessory are known constraints. The lost traveler/merchant rigs were explicitly accepted as closed and are not required unique bodies. |
| Historical references | Owner-board/generated outputs retain their recorded proprietary or owner-licensed status. No reference image is an export asset or tracing source. |

This table records historical dispositions; current scoped generation authority is the explicit owner workflow at the start of this section. Preserve accepted results unless a current defect justifies an iteration. Pack rows recorded as CC0 still require the final release audit, and Plumberry Plains material retains its no-resale/repackaging and no-AI-training restrictions. Public release needs a fresh licence audit with creator credits preserved.

## 8. Current production state

| Area | Baseline state at `b8eda885` | What remains |
|---|---|---|
| Renderer/sky/day-night | **Built foundation.** Compatibility, ordinary directional shadows, painted sky and time presets exist. | On-device lighting/performance validation; night legibility; no renderer switch. |
| Meadows locations | **Built and individually reviewed.** The prior ledger reports 23/23 named rows promoted. | Whole-chapter Bar A/B remain open; continuous cohesion, route pulls, creature/ground defects and representative motion still need acceptance. |
| Cloudreach | **Broadly built, visually unaccepted.** Current cited ledger is 0 PASS / 9 POLISH / 3 FAIL. | Correct high-perch camera, cliff silhouettes, settlement/route cohesion, grass/material quality and a fresh full ledger. |
| Stormwood | **Systems and presentation partially built.** World, Surge data, Dynamo and ending are mounted/focused-tested. | Full-route rendered evidence, distinct forest readability, phase clarity, final asset quality and Ally proof. |
| Tidewake | **World and finale systems partially built.** Islands, currents, Veilfall, Guardian ceremony and restored state exist. | Full chapter visual witness, shoreline/dock cohesion, mount presentation, water readability and final epilogue presentation. |
| Creature art | **Mixed stand-ins, generated exceptions and installed replacements.** Shared material/colourway systems exist. | Final style selection, owner-supplied or agent-drafted references, a three-creature proof at real camera distance, topology/rig/animation repairs, mipmaps and slope/contact validation. |
| Humanoid cast | **Installed and reusable.** Material variants, ranks and portraits exist. | Resolve named allocation/identity defects through approved cast/material work; no unapproved new humanoids. |
| Props/pickups/UI | **Substantial built foundation.** Camp/pickup families, UI tokens and prompt assets exist. | Known accepted defects stay closed unless gameplay reopens them; final consistency/accessibility pass and provenance audit remain. |

## 9. Acceptance package

For each chapter, capture the same representative matrix from the shipping build: arrival/approach, player-facing route, reverse route, close detail/material view, optional lure, key settlement, ordinary combat, finale at about 400 m and 100 m, and post-finale change. Capture day and night where the chapter supports them, plus its defining weather state. Include native 1920×1080 Ally 15 W presentation, the 1280×720 downscale stress raster and desktop 1080p. Visual work affecting motion also needs a short motion witness for ground contact, vegetation, weather, mount/fly/swim or VFX.

A fresh code-blind critic receives only current frames, the approved reference set and the rubric. It names frame-specific defects, ranks the largest three gaps and answers Bars A/B. It is not told what changed or the performance budget. Two rounds with no new defect and no measured movement establish a mechanism ceiling; change the asset or approach instead of repeating tint/scatter tuning.

Final reference parity, creature style and any asset-dependent silhouette compromise receive a code-blind independent agent verdict against the owner-settled Bars A/B and the saved reference set. Record exact frame, defect, chosen repair and the re-captured result. If an authorized asset path cannot meet the bar, keep it open rather than silently accepting a weaker silhouette. Performance acceptance requires device telemetry; a screenshot cannot prove it. Real audience appeal remains unmeasured without human players.

## 10. Out of scope

- Renderer migration, SDFGI, SSR, volumetric fog or a PCSS requirement.
- New creature/humanoid meshes or Meshy generations without the reference and subject approvals above.
- Pixel-copying comparison games or shipping reference art.
- Solving topology, face or silhouette defects through global saturation/tint alone.
- Uniformly filling open fields, cliffs or water with three vegetation layers.
- Shrinking creatures to fit cameras, arenas, doors or mounts.
- Expanding the current four-biome pass to the future eight-biome ambition, or adding an endless procedural world.
- Claiming commercial finish from counts, config, isolated source renders or one attractive screenshot.

## 11. Recovery dispositions

- **S04/S30/S34, D10, D24, D63, D80, D85:** retain one-family coherence, stand-in/final distinction, shared-material correctness, mesh-bound VFX and evidence discipline; supersede obsolete scale values and green-faction examples.
- **S08 and owner asset recovery:** retain provenance-before-commit, redistribution audit and reference restrictions. Named historical carve-outs remain narrow; this file creates no new authorization.
- **DR19/D74:** preserve Burrowback's armour and the 1.30:1 bounded treatment rather than a blind universal contrast repair.
- **DR21/D80 and DR24/D94:** preserve deployed-body effects, magenta wind-up and orb-sized gold capture seal; record the current HUD colour inconsistency.
- **DR22/D81/D87:** preserve faction-plate and actual-speaker portrait rules, including the stronghold exceptions and mask-only hair colour.
- **B04/B11/B17/B26/B27:** carry chapter silhouette, weather, composition, route and subject-readability constraints; current counts and old coordinates are not acceptance.
- **B03/B16/B24/B33:** state landed/focused/continuous/accepted separately. Stormwood and Tidewake systems exist; neither has fresh four-chapter visual acceptance.
- **Archived Asset Ledger, Environment/UI Bible, Visual Bible V2 and Performance Budget:** retain their supported art, provenance and structural-budget rules; retire unsupported fog guidance, retired draw baselines and any implied Ally FPS guarantee.
