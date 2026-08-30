# Tetherbound — Hall Asset Upgrade Pack

## Goal
Fix the Hall's core visual problem identified by blind review: it currently reads as a clean cream castle instead of an **ancient weathered ruin reclaimed by nature with Team Tether industry bolted onto it**.

Do **not** rebuild the Hall from scratch and do **not** ask Meshy to generate the whole fortress. Keep the authored level geometry and gameplay layout. Upgrade the visual language with a hybrid asset approach.

## Budget
**Target: $0. Hard cap: $10.**

Start with free assets. Only buy something if the free options cannot solve a specific blocker. Do not purchase multiple overlapping packs.

## Asset strategy

### Use free/existing downloadable assets for
1. Weathered stone / ruin materials and modular masonry.
2. Ivy, moss, vines, and overgrowth.
3. Broken wall tops, rubble, damaged parapets, and ruined masonry.
4. Arched gate / keystone / portcullis pieces.
5. Roof pieces and generic courtyard dressing.

Useful starting points already identified:
- **Quaternius Medieval Village MegaKit** — free modular medieval architecture and props. Search/download from Quaternius.
- **Makovice Ancient Ruins Asset Pack** — free ruin-oriented GLB/Godot assets. Search/download from itch.io.
- If the free ruin pieces are clearly insufficient, a low-cost fallback previously identified was **Dungeon Throne Ruins** on itch.io at roughly $5. Do not buy it automatically.

Prefer GLB/glTF assets that can be used directly in Godot.

### Generate in Meshy
Generate only the five custom Team Tether props included in `/art_boards/`:

1. `01_team_tether_timber_scaffold_tower.png`
2. `02_team_tether_boiler_chimney_retrofit.png`
3. `03_team_tether_pipe_valve_kit.png`
4. `04_rift_siphon_wall_machine.png`
5. `05_team_tether_oxblood_banner_rig.png`

These are the high-value assets that create the faction-specific "industrial retrofit over ancient ruin" identity.

---

# Hall Visual Formula

The final Hall should read as two layers.

## Layer 1 — Ancient Hall
- Weathered gray/tan stone, not clean cream walls.
- Visible surface roughness and normal variation.
- Per-stone color/value variation.
- Moss in mortar joints and damp areas.
- Ivy and vines climbing walls and towers.
- Broken parapets and collapsed wall tops.
- Missing or damaged roof areas.
- Rubble and old debris.
- A convincing arched gate with keystone and portcullis.
- Courtyard weeds, crates, barrels, broken stone, timber, and signs of age.

## Layer 2 — Team Tether Occupation
- Blackened timber scaffolding.
- Aged iron braces and bolts attached directly to old stone.
- Pipe runs driven across and through ancient walls.
- Boiler/chimney retrofit.
- Rift siphon machinery with restrained purple Rift glow.
- Oxblood cloth banners and faction hardware.
- Work areas, temporary repairs, crates, lamps, cables, and industrial clutter.

The contrast between the two layers is the point: **old sacred ruin + recent invasive industry**.

---

# Meshy Generation Instructions

Use each art board as the primary visual reference. Generate each prop as a **separate production asset** rather than asking Meshy to generate a scene.

General requirements for all five:
- Game-ready stylized/semi-realistic 3D prop.
- Strong silhouette from gameplay distance.
- Low-to-medium detail density; avoid tiny surface clutter.
- PBR materials.
- Clean topology / retopology suitable for Godot.
- Prefer modular/separable components where indicated.
- No environment or floor baked into the final asset.
- Preserve readable proportions from the art board.
- Export GLB/glTF.
- Keep origin/pivot practical for placement.
- Do not generate text labels into the mesh.

## 1. Team Tether Timber Scaffold Tower
**Reference:** `art_boards/01_team_tether_timber_scaffold_tower.png`

Generate a modular wall-attached scaffold made from heavy weathered timber, iron straps/brackets, rope lashings, ladders, and plank platforms.

Must have:
- Broad timber uprights.
- Cross braces.
- Platforms.
- Ladder.
- Iron bolting/brackets.
- Dark aged timber.
- Modular readable construction.

Prefer separate logical pieces if Meshy supports it: beams, ladder, platform, brace sections.

Do not bake the stone wall into the finished prop; the wall shown on the board is context only.

## 2. Team Tether Boiler & Chimney Retrofit
**Reference:** `art_boards/02_team_tether_boiler_chimney_retrofit.png`

Generate a chunky industrial boiler assembly meant to look crudely bolted into an ancient fortress.

Must have:
- Large cylindrical boiler body.
- Tall smokestack/chimney.
- Furnace door with orange interior glow potential.
- A few thick pipes.
- Pressure tank / gauge details.
- Riveted blackened iron.
- Service ladder/platform only where needed.

Avoid excessive steampunk micro-detail. This must remain readable at gameplay distance.

## 3. Team Tether Pipe & Valve Kit
**Reference:** `art_boards/03_team_tether_pipe_valve_kit.png`

This should ideally become a modular kit rather than one giant sculpture.

Priority pieces:
- Straight pipe.
- 90-degree elbow.
- T-junction.
- Shutoff valve.
- Wall bracket/clamp.
- Optional pressure gauge.

Aged iron with some oxidation. Built to bolt onto stone walls and route around corners.

If Meshy cannot deliver clean modular pieces in one generation, generate the straight/elbow/T-junction/valve as separate assets while keeping scale and material consistent.

## 4. Rift Siphon Wall Machine
**Reference:** `art_boards/04_rift_siphon_wall_machine.png`

This is the signature bespoke Team Tether Hall prop and should receive the most attention.

Generate a wall-mounted arcane-industrial machine with:
- Large central caged energy chamber.
- Heavy iron frame and brackets.
- Several large tanks / conduits.
- Thick pipes and cables.
- A small readable control/valve cluster.
- Purple Rift-energy core suitable for emissive material/VFX in Godot.

Do not bake a giant complex purple particle effect into the geometry. Build a readable chamber so Claude/Godot can add emissive material and particles afterward.

The machine should look invasive: clearly manufactured equipment strapped onto ancient architecture.

## 5. Team Tether Oxblood Banner Rig
**Reference:** `art_boards/05_team_tether_oxblood_banner_rig.png`

Generate a wall-mounted banner assembly with real 3D cloth folds rather than a flat plane.

Must have:
- Heavy iron wall bracket / horizontal bar.
- Oxblood-red cloth hanging vertically.
- Broad cloth folds.
- Worn/torn lower edge.
- Aged brass/iron hardware.
- Optional chain/pulley detail.

Important: do not rely on Meshy to reproduce small exact faction-logo typography. A simple broad emblem shape is acceptable, or leave the central cloth area suitable for applying the canonical Team Tether emblem as a texture/decal in Godot later.

---

# Claude Integration Instructions

When these assets are added to the repo:

1. **Preserve gameplay geometry and traversal.** This is an art upgrade, not a Hall redesign.
2. Replace the clean/uniform stone read with weathered ruin materials first.
3. Add moss/ivy/overgrowth with deliberate clustering, especially joints, wall bases, damaged tops, shaded faces, and collapsed sections.
4. Use broken masonry pieces to destroy the "perfect finished castle" silhouette.
5. Upgrade the main entrance with a proper arched/keystone/portcullis read.
6. Add roof assets only where architecturally sensible; keep ruined/missing sections visible.
7. Place the five Team Tether Meshy assets as a coherent retrofit layer, not randomly scattered props.
8. The **Rift Siphon** is the signature machinery and should be given a hero placement where it supports story/gameplay.
9. Scaffold, pipes, boiler, banners, and machinery should visibly attach to or intrude on ancient stone.
10. Use the canonical Team Tether oxblood faction color already defined in the project rather than inventing a new red.
11. Keep purple Rift glow selective. It should draw the eye to important machinery, not make every industrial prop purple.
12. Add courtyard dressing from free/existing props: crates, barrels, timber piles, rubble, work lamps, weeds, tools, and temporary barricades.
13. Run the existing Hall visual capture/blind-judge process again after the asset pass.

## Success criterion
The Hall should no longer be describable as a clean cream castle. A blind viewer should immediately read:

> **ancient weathered ruin reclaimed by vegetation, then occupied and industrially retrofitted by Team Tether.**

