> **Provenance.** Owner-supplied, delivered 2026-08-11. Everything below the
> rule is the owner's document, unedited. Made canon by
> `docs/decisions/D24-one-nature-family-one-village-family.md`.
>
> Read it alongside `docs/MEADOWS_PROGRESSION_SPEC.md` (D23): that one says what
> the Meadows chapter *is*, this one says what it should *look like* and what
> art to buy. Where they overlap, D24 records which wins.
>
> The rule this document does **not** state, and which now governs every
> generation: **no Meshy spend without an owner-supplied reference sheet first**
> (owner directive, 2026-08-11). §6's "only after reference art exists" is the
> same instruction; it is now a hard rule in `CLAUDE.md`.

---

# TETHERBOUND — PALWORLD-QUALITY ENVIRONMENT + HUD UPGRADE PLAN

**Owner directive:** Use this document to raise Tetherbound's environment and HUD toward the visual *quality, readability, density, and cohesion* of Palworld without copying Palworld assets or UI one-for-one.

**Project context discovered in repo**
- Engine: Godot 4, currently pinned to **Godot 4.7-stable**.
- Renderer: **Compatibility / OpenGL**, intentionally chosen for ROG Ally stability.
- Terrain: existing Terrain3D-based pipeline. **Do not replace Terrain3D just to chase visuals.**
- The project already has authored Meadows terrain, procedural vegetation/scatter, village/interior work, and sourced Quaternius-style props in places.
- All third-party assets must be recorded in `docs/ASSET_LEDGER.md` before commit.

---

# 0. EXECUTIVE DECISION

Do **not** spend Meshy credits generating routine environment assets.

The best-value path is:

1. **Keep Terrain3D.**
2. Standardize the world around **one coherent stylized nature family**.
3. Standardize Meadows buildings around **one modular stylized village family**.
4. Add a coherent **prop family**.
5. Rebuild terrain painting, scatter, lighting, atmosphere, and composition around Palworld-quality reference principles.
6. Re-skin/rebuild the HUD using native Godot `Control` nodes plus CC0 UI/icon/input assets.
7. Use Meshy only for **Tetherbound-specific hero landmarks** that cannot be assembled from modular packs.

The environment should not become a pile of unrelated marketplace assets.

---

# 1. PALWORLD VISUAL REFERENCES

These images are **reference only**. Never redistribute them as Tetherbound assets.

Claude should use them to study:
- screen-space density
- vegetation layering
- terrain breakup
- path softness
- rock/grass transitions
- building-to-landscape integration
- atmospheric depth
- HUD panel opacity
- icon scale
- information hierarchy

## Reference A — lush exploration meadow / flowers / rock formations

Page:
`https://www.gamereactor.pt/palworld-131323/`

Image found during research:
`https://www.gamereactor.pt/media/56/palworld_4185633b.png`

Study:
- grass covers most visible soil outside paths
- many small flower/color accents
- large rocks are rounded and embedded in terrain
- trees form layered backgrounds rather than evenly spaced isolated props
- HUD occupies corners and leaves the center readable

## Reference B — base overlooking a green clearing

Page:
`https://medium.com/@nigelmills2000/five-of-the-best-designed-pals-in-palworld-837c01d0fc2f`

Image:
`https://miro.medium.com/1%2A0w05R_Iv8bI99vVBkJE40w.png`

Study:
- buildings are visually grounded into the clearing
- the clearing is not empty: props, beds, workstations, Pals, paths, and trees create hierarchy
- forest edge provides a dense frame
- near-ground texture is noisy enough to feel natural but major silhouettes remain clear

## Reference C — open grass/path gameplay

Page:
`https://games.gg/palworld/guides/palworld-10-release-date-time-details/`

The search/reference image shows:
- bright grass
- soft dirt track
- rock cuts
- trees concentrated at the edge/ridge
- very limited HUD clutter in exploration

Study this specifically for the **terrain + path + grass relationship**.

## Reference D — early base / settlement composition

Page:
`https://www.chip.pl/2024/01/palworld-odkrywamy-fenomen-opinia`

Image:
`https://konto.chip.pl/uploads/2024/01/palworld-opinia-odkrywamy-fenomen.jpg`

Study:
- base clearings use negative space intentionally
- fences and small structures create sub-areas
- Pals and props provide mid-ground detail
- rocks/trees make the base feel embedded in the world rather than placed on a flat level

## Reference E — inventory UI

Page:
`https://gamewith.jp/palworld/434719`

Image found during research:
`https://img.gamewith.jp/img/dbf1175cc506299796d342c5cee9aea5.png`

Study:
- dark translucent panel
- subtle border
- strong grid
- icon-first presentation
- limited color accents
- high information density without giant decorative frames

## Reference F — crafting UI

Reference image:
`https://blog.kakaocdn.net/dna/cihHH4/btsE8CMUyli/AAAAAAAAAAAAAAAAAAAAAJpqFwYCMWQlh4NwH5_gW2bFFompOsd9iprrMyTSbqFF/img.png`

Study:
- centered production panel
- dark transparency
- cyan/blue action accent
- clear ingredient rows
- strong quantity/action button hierarchy

## Additional official/reference sources

Palworld Steam media page:
`https://store.steampowered.com/app/1623730/Palworld/`

Palworld press kit:
`https://www.igdb.com/games/palworld/presskit`

Claude may capture additional environment/HUD screenshots from these sources for private reference if needed.

---

# 2. PACKS TO ACQUIRE — PRIORITY ORDER

## PRIORITY 1 — QUATERNIUS STYLIZED NATURE MEGAKIT

**Pack name:** `Stylized Nature MegaKit`  
**Creator:** Quaternius  
**License:** CC0  
**Primary use:** trees, bushes, flowers, plants, rocks, grass forms  
**Vendor page:**  
`https://quaternius.com/packs/stylizednaturemegakit.html`

Itch:
`https://quaternius.itch.io/stylized-nature-megakit`

Current researched tiers:
- Standard — free / name-your-price
- Pro — $9.99+
- Source — $14.99+

The pack currently advertises:
- 116 unique nature models
- 40 trees
- 35 plants/flowers
- 27 rocks
- grass/bushes/etc.
- glTF support
- CC0
- Source edition includes a Godot project and stylized wind/shading shaders

### Recommendation

**Start with Standard if Claude can download it automatically.**

If the owner is willing to spend about $15, the **Source edition is the single highest-value paid environment purchase** because it provides the full asset family and Godot implementation/shader examples.

### Critical rule

The Source project's Godot version is older than Tetherbound's current 4.7 pin.

Do **not** copy its project settings or addons wholesale.

Import:
- models
- textures
- selected shader logic after inspection

Adapt shaders to:
- Godot 4.7
- Compatibility renderer
- current Terrain3D/scatter pipeline

---

## PRIORITY 2 — QUATERNIUS MEDIEVAL VILLAGE MEGAKIT

**Pack name:** `Medieval Village MegaKit`  
**Creator:** Quaternius  
**License:** CC0  
**Primary use:** Meadows village, Grandpa-area buildings, bridge structures, mills, walls, roofs, doors/windows  
**Vendor page:**  
`https://quaternius.com/packs/medievalvillagemegakit.html`

Itch:
`https://quaternius.itch.io/medieval-village-megakit`

Current researched tiers:
- Standard — free / name-your-price
- Pro — $9.99+
- Source — $14.99+

The pack advertises:
- 300+ modular environment pieces
- grid-snapping architecture
- walls/floors/stairs/roofs/doors/windows
- glTF
- CC0
- Source version includes Godot setup, customizable wear shaders, and optimized collisions

### Recommendation

Use this as the **primary Meadows civilian architecture kit**.

Do not mix three different village kits in the same settlement.

Use:
- one roof family
- one wall family
- one wood treatment
- one stone treatment
- consistent window/door proportions

Then recolor/material-grade the kit to Tetherbound.

---

## PRIORITY 3 — QUATERNIUS FANTASY PROPS MEGAKIT

**Pack name:** `Fantasy Props MegaKit`  
**Creator:** Quaternius  
**License:** CC0  
**Primary use:** crates, barrels, tools, carts, sacks, signs, small settlement clutter, interior/exterior dressing  
**Itch page:**  
`https://quaternius.itch.io/fantasy-props-megakit`

Current researched tiers:
- Standard — free / name-your-price
- Pro — $9.99+
- Source — $14.99+

Use this to solve the "empty settlement / empty world" problem cheaply.

### Do not

Dump hundreds of props everywhere.

Use authored clusters:
- work area
- farmhouse yard
- bridge repair site
- quarry station
- trainer camp
- relay station

Every cluster should imply a purpose.

---

# 3. FREE FALLBACK PACKS

If Quaternius downloads are unavailable or Claude cannot automate the itch flow, use these CC0 fallbacks.

## Kenney Nature Kit

`https://kenney.nl/assets/nature-kit`

- 330 3D files
- CC0
- trees / rocks / foliage
- completely free

Use as a **fallback or supplement**, not an equal visual partner if its art style clashes with the selected Quaternius family.

## Kenney Fantasy Town Kit

`https://kenney.nl/assets/fantasy-town-kit`

- 160 files
- CC0
- fantasy/medieval modular town assets
- free

Use only if the Quaternius village kit is unavailable.

Do not combine both heavily in the same village without a material/style pass.

---

# 4. GODOT TOOLING — KEEP / ADD

## KEEP — Terrain3D

Tetherbound already uses Terrain3D.

Current Terrain3D releases support:
- multi-texture terrain
- LOD
- foliage instancing
- texture painting
- detiling
- color/wetness painting

Do not replace the project's working Terrain3D integration with a different terrain generator.

**Do not blindly upgrade the Terrain3D addon either.**

The project is pinned to Godot 4.7 while public store listings may target older stable versions. Inspect current local version and compatibility first.

## OPTIONAL — Godot Asset Placer

**Pack/plugin:** `Godot Asset Placer`  
**Use:** authored placement of buildings/rocks/prop clusters on Terrain3D  
Godot Store:
`https://store.godotengine.org/asset/levinzonr/godot-asset-placer/`

It supports:
- Terrain3D placement
- surface placement
- random selection from palettes
- bottom/origin alignment
- transform tools

Use it as an editor productivity tool only if compatible with current 4.7.

Do not add it if Claude's existing placement scripts already solve the workflow cleanly.

---

# 5. HUD / UI PACKS

Do **not** use Meshy for UI.

Use native Godot `Control`, `PanelContainer`, `TextureRect`, `NinePatchRect`, `GridContainer`, etc.

These packs provide raw visual primitives and icons.

## Kenney UI Pack — RPG Expansion

`https://kenney.nl/assets/ui-pack-rpg-expansion`

- 85 files
- CC0
- panels/buttons/sliders/RPG interface parts

Use for:
- panel slices
- buttons
- selectors
- inventory framing components

Do not use its default visual style untouched if it looks too medieval.

Recolor/recompose it into Tetherbound's cleaner translucent system.

## Kenney UI Pack

`https://kenney.nl/assets/ui-pack`

- 430 files
- CC0

Use as a broad source of:
- panel corners
- tabs
- bars
- sliders
- toggles

## Kenney Input Prompts

`https://kenney.nl/assets/input-prompts`

- ~1500 glyphs
- CC0
- Xbox / PlayStation / Steam Deck / keyboard+mouse / touch

This should replace improvised text prompts.

Tetherbound targets:
- PC mouse/keyboard
- Xbox-layout controller / ROG Ally

Use SVG where practical so Godot can scale cleanly.

## Kenney Game Icons + Expansion

`https://kenney.nl/assets/game-icons`  
`https://kenney.nl/assets/game-icons-expansion`

Use as temporary/production icons where they fit.

Custom Tetherbound icons should eventually replace generic ones for:
- Orb
- Pal types
- bond
- Tether Rift
- Sigils
- unique progression items

---

# 6. DO NOT BUY / GENERATE THIS STUFF

Do not spend Meshy credits on:
- common trees
- grass
- bushes
- rocks
- crates
- barrels
- chairs
- generic cottages
- fences
- normal bridges
- normal signs
- standard HUD icons

These are solved better by coherent asset packs.

Meshy should be reserved for Tetherbound-specific hero objects such as:
- Tether Rift machinery
- biome-specific Tether pylons
- iconic Stronghold centerpiece
- legendary containment/tether device
- a signature artifact that no modular kit can provide

Even these should be generated only after reference art exists.

---

# 7. ENVIRONMENT TARGET — WHAT "MORE LIKE PALWORLD" ACTUALLY MEANS

This is not "copy Palworld."

The transferable visual qualities are:

## A. Dense ground layer

The player should almost never stare at a giant plain, uniformly colored terrain surface.

Use:
- terrain base
- grass coverage
- small weeds
- flowers
- pebbles
- occasional bare soil
- roots
- localized clutter

The terrain texture is the foundation, not the visible final surface.

## B. Layered vegetation

A good forest edge has:
1. ground grass
2. flowers/weeds
3. shrubs
4. small saplings
5. medium trees
6. large silhouette trees
7. distant tree mass/haze

Do not scatter one tree type uniformly.

## C. Clusters + clearings

Avoid evenly spaced procedural noise.

Vegetation should produce:
- dense groves
- empty paths
- meadow clearings
- rock clusters
- wetland bands
- hedgerows
- tree lines

Use placement rules tied to:
- slope
- elevation
- distance to water
- path distance
- landmark distance
- biome subzone

## D. Strong mid-ground

The repo's visual reviews have already identified sparse mid-ground/horizon composition.

Every major sightline should contain at least one or more of:
- tree line
- rock ridge
- river
- hill
- building group
- fence
- landmark
- grove

Avoid empty terrain extending directly into sky.

## E. Buildings embedded into landscape

No building should look dropped onto a flat disc.

Around buildings:
- flattened terrain only where physically necessary
- grass transitions at edges
- footpaths
- fences
- flowers/weeds
- rock foundation
- props
- wood piles
- carts
- barrels
- garden rows

## F. Controlled saturation

Palworld-like readability comes from bright color relationships, not max saturation everywhere.

Tetherbound Meadows:
- warm yellow-green sunlit grass
- deeper cool forest greens
- warm dirt
- neutral gray/brown rocks
- modest flower accents
- teal Tetherbound magical accents

Avoid fluorescent lime terrain.

---

# 8. TERRAIN MATERIAL PLAN

Keep Terrain3D and build a deliberate Meadows layer set.

Recommended paint materials:

1. **Meadow Grass Base**
   - dominant
   - mid-bright yellow-green
   - subtle large-scale variation

2. **Deep Grass / Forest Floor**
   - cooler/darker
   - used under groves and trees

3. **Dry Grass**
   - golden-brown accents
   - hilltops, disturbed ground

4. **Packed Dirt**
   - paths, village circulation, camps

5. **Rich Soil**
   - under disturbed ground, quarry edges, farms

6. **Gray Meadow Rock**
   - steep slopes / exposed stone

7. **Mossy Rock**
   - shaded/wet faces

8. **Wet Bank**
   - river/pond margins

Do not use all eight equally in every view.

### Terrain transition rules

- Paths need feathered irregular edges.
- Dirt should break into grass with weeds/tufts.
- Rocks should emerge from terrain instead of forming flat painted decals.
- Forest floor should extend beyond the exact tree trunk footprint.
- Wet banks should transition gradually into water.

---

# 9. GRASS TARGET

Grass is one of the highest-impact upgrades.

Create 3–5 grass variants:
- standard meadow blade clump
- tall clump
- dry clump
- broad-leaf weed
- flowering grass

Randomize:
- scale
- rotation
- color within a narrow family

Use wind.

But avoid synchronized "whole field waving like fabric."

### Density philosophy

Near player:
- high enough that terrain surface is partially obscured

Mid distance:
- use simpler clumps / Terrain3D foliage LOD

Far:
- terrain macro-color should approximate vegetation mass

Performance target remains ROG Ally / Compatibility renderer.

Do not solve density by creating thousands of individually instanced Node3Ds.

Use MultiMesh / Terrain3D foliage.

---

# 10. TREE TARGET

Use Stylized Nature MegaKit as the default tree language.

Select a **small approved subset**, not all 40 trees.

For Meadows:

### Hero trees
2–3 large forms:
- broad oak
- asymmetrical old tree
- tall landmark tree

### Standard canopy
3–4 medium forms

### Young/small
2–3 sapling forms

### Wetland
1–2 forms near river

Create controlled material variants:
- spring green
- deep green
- slightly yellow-green

Do not make every individual tree a different color.

### Placement

Trees should:
- cluster around terrain features
- create shade belts
- form forest walls
- frame paths
- avoid blocking every gameplay route

Large trees near gameplay spaces need clean collision proxies, not full mesh collision.

---

# 11. ROCK TARGET

Use one rock family across the Meadows.

Required:
- 3 small
- 3 medium
- 2–3 large
- 1 cliff/formation family if available

Material grade:
- warm neutral gray
- slight moss on shaded/top surfaces
- avoid shiny rock

Placement:
- partially bury rocks
- rotate naturally
- cluster related sizes
- tie clusters to slope/quarry/river logic

Do not put identical rocks upright at equal spacing.

---

# 12. BUILDING TARGET

Use Medieval Village MegaKit as the default civilian Meadows building vocabulary.

Do not make the Meadows into a generic medieval town.

Tetherbound customization:
- simpler structures
- warm timber
- pale plaster
- moss/green accents
- muted terracotta or warm wood roofs
- practical survival/explorer details
- less ornate fantasy decoration

Build a limited modular language:

### Farmhouse
- one wall family
- one roof
- stone base
- porch/awning

### Village house
- 2–3 modular variations

### Workshop
- broader doors
- exterior clutter

### Mill / crossing
- water/bridge architecture

### Ranger station
- compact functional building

### Bridges
- timber + stone abutment

Create prefabs/scenes from modules once, then reuse.

Do not construct every building from loose pieces at runtime.

---

# 13. TEAM TETHER ARCHITECTURE

Do **not** use the same civilian village kit with only dark paint.

Team Tether should feel like an intervention imposed on the world.

Use:
- existing modular stone/wood pieces where useful
- plus Tether-specific generated hero pieces

Team Tether visual language:
- dark stone/metal supports
- controlled symmetry
- vertical pylons
- green/teal energy
- brass/gold rank accents
- natural environment visibly cut through by infrastructure

Meshy credits, if ever used again, should target:
1. Tether energy pylon
2. relay apparatus
3. legendary tether machine

Those 2–3 assets can make generic modular architecture feel faction-specific.

---

# 14. LIGHTING + ATMOSPHERE

Do not chase Palworld through geometry alone.

### Day target

- strong readable sun direction
- warm sunlight
- cool ambient fill
- soft enough shadow edges to avoid harsh low-budget look
- sky brighter than terrain but not blown white
- distant fog/haze creates depth

### Compatibility renderer constraint

Tetherbound intentionally uses Compatibility renderer for device stability.

Do not re-enable Forward+ features simply to gain:
- volumetrics
- expensive GI
- higher-end shadows

Fake the look using:
- world fog if stable
- depth haze
- sky gradient
- baked/material ambient
- directional light
- carefully tuned environment colors
- simple transparent mist planes only if performant

### Time of day

Do not let noon, sunset, and night each look like entirely different art styles.

Keep consistent:
- saturation behavior
- fog/horizon language
- exposure
- terrain readability

---

# 15. WATER

The Meadows needs a real pond/stream/river visual layer.

Use water to:
- add depth
- break up green terrain
- create progression gates
- support Water Pal ecology
- create reflections/highlights

Target:
- readable stylized surface
- modest transparency
- shallow-edge color shift
- foam only at meaningful contact points
- vegetation/reeds at banks

Do not build a physically expensive simulation.

---

# 16. HUD TARGET

The HUD should borrow **information design principles**, not Palworld's exact layout.

## Tetherbound exploration HUD

Keep visible:
- player health/stamina only when relevant
- current active Pal / party shortcut
- Orb count / currently selected usable item
- concise current objective
- contextual prompt
- minimal compass/wayfinding if already part of design

Hide or fade:
- irrelevant bars
- huge permanent text
- crafting menus
- tutorial panels once learned

### Visual language

- dark blue-gray translucent backgrounds
- 70–90% readable text contrast
- thin pale borders
- teal/cyan Tetherbound accent
- warm gold for important progression
- type-color accent only where meaningful
- rounded corners
- compact spacing
- no giant fantasy scroll frames

## Inventory

Target:
- strong grid
- dark transparent backing
- selected slot bright outline
- category tabs
- item detail panel
- clean quantity / weight
- large enough on 7-inch ROG Ally display

## Crafting

Target:
- recipe list or grid
- selected recipe hero panel
- ingredient rows with owned/needed
- clear primary action button
- disabled state obvious

## Dialogue

Do not imitate Palworld if Tetherbound's character presentation benefits from more personality.

Use:
- compact speaker name
- readable dialogue box
- portrait only if consistent art exists
- controller-first continue prompt

---

# 17. HUD SCALE RULE — ROG ALLY FIRST

The repo authors at 1920x1080 specifically for the Ally.

Test HUD at physical 7-inch scale.

Do not judge only on desktop monitor.

Minimum philosophy:
- body text should remain comfortably readable
- icons large enough to recognize without leaning in
- prompts readable peripherally
- do not cover center combat area

Use anchors/containers rather than hardcoding desktop pixel positions everywhere.

---

# 18. INPUT PROMPTS

Use Kenney `Input Prompts`.

Map dynamically based on last-used device if existing input architecture permits.

Examples:
- E / X button for interact
- mouse / right stick for camera
- left mouse / trigger for primary combat input
- Esc / menu button

Do not display both keyboard and controller prompts simultaneously unless context requires it.

---

# 19. ASSET ACQUISITION PROCEDURE FOR CLAUDE

Before downloading anything:

1. Read `docs/ASSET_LEDGER.md`.
2. Search the repo for existing copies of:
   - Quaternius
   - Kenney
   - Stylized Nature
   - Medieval Village
   - Fantasy Props
3. Do not duplicate an existing pack.
4. Verify license on the source page at download time.
5. Record it in `docs/ASSET_LEDGER.md` **before commit**.
6. Save source zips outside exported runtime folders.
7. Import only assets actually selected for the game.

Recommended source staging:
```text
assets_raw/vendor/quaternius/stylized_nature_megakit/
assets_raw/vendor/quaternius/medieval_village_megakit/
assets_raw/vendor/quaternius/fantasy_props_megakit/
assets_raw/vendor/kenney/ui/
```

Production assets:
```text
assets/environment/meadows/nature/
assets/environment/meadows/buildings/
assets/environment/meadows/props/
assets/ui/
```

Do not commit giant vendor source projects if the repo does not need them.

---

# 20. PACK DOWNLOAD PRIORITY UNDER ZERO BUDGET

If spending **$0**:

1. Quaternius Stylized Nature MegaKit — Standard
2. Quaternius Medieval Village MegaKit — Standard
3. Quaternius Fantasy Props MegaKit — Standard
4. Kenney UI Pack
5. Kenney UI Pack RPG Expansion
6. Kenney Input Prompts
7. Kenney Game Icons / Expansion

This is enough to make a major visual upgrade without another Meshy credit.

---

# 21. IF OWNER WILL SPEND ~$30

Best use:

- Stylized Nature MegaKit **Source** — ~$14.99
- Medieval Village MegaKit **Source** — ~$14.99

Why:
- gives fuller coherent sets
- Godot implementation examples
- nature shaders
- building shaders/collisions
- dramatically more leverage than two random Meshy objects

Do **not** buy everything.

Fantasy Props Standard is likely enough initially.

---

# 22. IMPLEMENTATION ORDER

## Phase A — Reference + audit

1. Save/capture the Palworld reference frames listed above into `docs/reference/external/palworld/` if legally/technically convenient.
2. Mark them `reference-only`, excluded from export.
3. Audit current environment assets and ledger.
4. Screenshot current Meadows from:
   - open field
   - forest edge
   - village
   - Grandpa house
   - river/lowland if present
   - stronghold approach
5. Compare current frames side-by-side with reference frames.

## Phase B — Nature kit

6. Acquire Stylized Nature MegaKit.
7. Build an approved Meadows asset subset.
8. Replace weakest current tree forms first.
9. Replace weakest grass/flower/rock forms.
10. Create performance-friendly collision proxies.
11. Rebuild scatter rules around clusters/clearings.
12. Re-render comparison shots.

## Phase C — Terrain

13. Re-grade terrain material palette.
14. Add/repair packed dirt and forest floor.
15. Improve path feathering.
16. Integrate mossy/wet bank materials.
17. Add actual water feature if still absent.
18. Tune macro variation to avoid flat uniform fields.

## Phase D — Buildings

19. Acquire Medieval Village MegaKit.
20. Define 1 canonical Meadows architecture language.
21. Rebuild/skin Grandpa house exterior if it materially improves cohesion.
22. Rebuild village structures from a limited modular subset.
23. Add mill/bridge architecture for progression.
24. Add prop clusters from Fantasy Props.
25. Ground every building with paths/grass/foundation/clutter.

## Phase E — Lighting/atmosphere

26. Establish canonical sunny Meadows environment.
27. Tune warm sun / cool fill.
28. Tune fog/horizon depth compatible with OpenGL renderer.
29. Remove inconsistent sky/fog states between viewpoints.
30. Validate night/day consistency.

## Phase F — HUD

31. Acquire Kenney UI + Input Prompts.
32. Build Tetherbound UI theme tokens.
33. Rebuild exploration HUD.
34. Rebuild contextual prompt.
35. Rebuild inventory.
36. Rebuild crafting.
37. Rebuild objective tracker.
38. Test at ROG Ally physical readability.

## Phase G — Cohesion pass

39. Capture the exact same 6 Meadows viewpoints again.
40. Compare against both old Tetherbound and Palworld references.
41. Judge:
    - ground density
    - tree quality
    - mid-ground layering
    - path integration
    - settlement cohesion
    - atmosphere
    - HUD polish
42. Fix the three biggest gaps.
43. Repeat until further improvement is mostly asset-quality-limited rather than scene-composition-limited.

---

# 23. QUALITY METRICS

A Meadows screenshot should pass these questions:

### Terrain
- Does the ground look alive at player distance?
- Are transitions irregular/natural?
- Are paths visually integrated?

### Vegetation
- Are there clear clusters and clearings?
- Are tree silhouettes varied but coherent?
- Is there enough mid-ground mass?

### Buildings
- Do structures feel embedded in the terrain?
- Do all civilian structures appear to belong to the same culture?
- Are props clustered with purpose?

### Atmosphere
- Can you perceive near/mid/far depth?
- Is the horizon pleasant rather than empty?
- Does lighting unify the scene?

### HUD
- Does it feel like finished game UI rather than debug UI?
- Is the center of screen clean?
- Is information easy to parse at handheld size?
- Are controller and keyboard prompts professional?

---

# 24. WHAT NOT TO DO

Do not:
- replace Terrain3D with a new terrain engine
- switch back to Forward+ merely for prettier effects
- import all 300+ assets and scatter them indiscriminately
- mix five art packs equally
- Meshy-generate routine environment props
- copy Palworld UI graphics
- copy Palworld building models
- copy Palworld screenshots into shipped game files
- use photorealistic PBR packs beside stylized characters
- solve "empty" by uniform random scatter
- add foliage without LOD/performance testing
- forget ROG Ally

---

# 25. FINAL ART DIRECTION

Tetherbound should not look like a Palworld clone.

The target is:

> **Palworld-level environmental richness and readability, with Tetherbound's softer creature-training identity, Meadows palette, hand-built adventure progression, and distinct Team Tether magical-industrial language.**

Use Palworld to answer:
- how full should the frame feel?
- how clearly should the terrain read?
- how should UI information be organized?
- how does a settlement feel integrated into nature?

Use Tetherbound's own art to answer:
- what colors?
- what characters?
- what creatures?
- what architecture?
- what story?
- what faction language?

---

# 26. FIRST ACTION FOR CLAUDE

Execute this, do not only plan it:

1. Audit current repo environment packs and `docs/ASSET_LEDGER.md`.
2. Determine whether Stylized Nature MegaKit is already present.
3. If not, acquire the free Standard version if possible without owner interaction.
4. Determine whether Medieval Village MegaKit is already present.
5. If not, acquire the free Standard version if possible.
6. Acquire the free Kenney UI Pack, RPG Expansion, Input Prompts, and Game Icons if not already present.
7. Do not spend money or require paid downloads without asking the owner.
8. Do not upgrade Terrain3D without proving compatibility with Godot 4.7 and the current repo.
9. Build an environment comparison report from current Meadows screenshots vs. the references listed in this document.
10. Start with the **nature/ground-density pass**, because it affects the largest percentage of every gameplay frame.
