# Visual bible — target, rubric and the current gap

**Status:** canonical visual document, 2026-09-02. Consolidates
`docs/specs/TETHERBOUND_VISUAL_BIBLE_V2.md` (the owner-directed target, kept verbatim as
the long-form spec), `.claude/skills/visual-judge/SKILL.md` (the rubric), and the
findings of the Visual Parity program (`archive/docs/VISUAL_NEXT_AGENT_HANDOFF.md`,
`archive/docs/VISUAL_PARITY_*.md`, `archive/reports/visual-parity/`). Read this first;
open the spec for pillar detail.

## 1. The target, in one paragraph

A lush, colourful, stylised, highly readable creature-adventure world: stylised realism
between Valheim and Palworld, vibrant natural palette, silhouettes and landmarks
readable from distance, cozy and inviting with hints of mystery, distinct day and night
moods. Lush rather than sparse, layered rather than flat, composed rather than
scattered, populated rather than empty, with strong foreground / mid-ground / distance
separation. Not photoreal, not AAA cinematic, not a pile of marketplace assets, not a
single good screenshot angle. Real-time on a ROG Ally.

References, in priority order: the owner-approved world boards
(`docs/website/redesign-2026-08-30/02_WEBSITE_ART_BOARD_FINAL.png`, crop at
`site/img/page-board.jpg`); `docs/reference/tetherbound-meadows-keyart.png` for
Tetherbound identity; `docs/reference/palworld-0*.jpg` as the owner's shipping-quality
bar for density, layering and composition. Never copy another game's assets or
compositions.

## 2. The seven pillars (from the spec)

A. Lush ground coverage in layers (terrain, grass, groundcover, weeds, flowers, litter),
never bare green terrain with scattered grass models. B. Vegetation in clusters and
ecological patterns (groves, stream edges, forest edges, lone hero trees), never a
uniform scatter. C. Terrain breakup: rocks, roots, banks, paths cut into the ground.
D. Layered composition per view: foreground element within a few metres, a mid-ground
subject, a distant mass with warm/cool separation. E. Atmosphere and skies that give
depth without eating the world. F. Landmarks integrated into the land, readable at 400 m
and again at 100 m. G. Life: creatures and people that make the world read as inhabited.

Regional variation matters: broad open pasture with long sightlines; sparse copses;
lush pockets at the Pond, groves and river edges; rocky quarry and warrens; river and
crossings; high pasture and old growth; drained, occupied land near Team Tether. Do not
extrapolate the Pond's density across the whole map.

## 3. How visuals are judged

Only a **code-blind** critic judges. Render real frames (`tools/survey.sh` for the five
fixed stands; the VP capture set for locations), hand the critic the frames, the
references and the rubric in `.claude/skills/visual-judge/SKILL.md`, and tell it nothing
about what changed. It scores nothing; it names addressable defects per frame, ranks
the three biggest gaps to the references, and answers the two bar questions:

- **Bar A:** do the frames read as belonging to the key art's world?
- **Bar B:** shown beside the Palworld frames, would someone say these are trying to be
  the same kind of game?

Rubric criteria: silhouette and readability at small size; colour and value structure;
intentionality (authored vs generator output); lighting; horizon and depth; interface;
artefacts; scale agreement (the trainer is 1.80 m and is the ruler in every frame).

Frames from this container use the Compatibility renderer under software GL: trust
composition, silhouette, colour relationships, scale, geometry; do not trust fine
lighting or post-processing. Every survey stage needs a known-albedo reference surface
(a 2.3× exposure error once produced three wrong "high-key pastel" verdicts).

Stopping rule: two consecutive rounds with no new defect and no measured movement means
a ceiling under the current mechanism. Record the ceiling and the mechanism; do not
run a tenth tuning round. Prove by number (crop medians, luminance, pixel-diff %)
decided before the render.

## 4. Where the build stands (fresh frames, current `main`, 2026-09-02)

Rendered this session from the current tree with `tools/survey.sh`
(`ralph/reports/reset-2026-09-02/_sheet_survey.png`), and read against the final Visual
Parity verdict (`archive/reports/visual-parity/VP11-final/JUDGE-final.md`: 6.5/10,
Bar A yes, Bar B partial).

**What holds up.** The sky model (soft painted cloud banks, real golden-hour and night
moods). The village buildings and their materials. The stronghold approach, gate and
courtyard, and the Hall silhouette at 400 m. The Team Tether relay's oxblood/teal
faction language. Creature scale hierarchy where several sizes stand together.
Night village legibility from window and torch light.

**What does not, ranked by distance from the references.**

1. **Composition: subject on a plain.** From the Rise (`03-rise-overlook`) the world
   reads as a vast, evenly textured plain with one village and one hill in it; no
   groves, no tree lines, no mid-distance masses, no route hierarchy. The reference has
   a foreground element, a mid-ground subject and a distant mass in nearly every frame.
   This is the highest-value gap and it is scene work, not art work. Owner of the fix:
   the Gate 2 composition pass in `docs/ROADMAP.md`.
2. **Ground reads as a blurred green smear with hair on it.** The grass carpet is on
   (75k tufts, decided; density is not the defect) but blades are isolated 1–2 px
   spikes on a low-frequency ground texture; there is no mid-layer (bushes, saplings,
   rock lines, litter) between carpet and canopy. The blade shape decision (clump cards)
   is put to the owner and not shipped; the mid-layer is Gate 2 work.
3. **Trees are repeated puffballs.** Flat rounded canopy masses at a handful of scales,
   no asymmetric silhouettes, no clustering into groves. Silhouette variety from the
   installed nature family and clustering by the composition plan is scene work; true
   canopy structure is art not in the build.
4. **Creature and character material split.** Creatures carry heavy cel outlines and
   flat painted textures in a different language from the trainer and from the
   low-poly terrain; night creature meshes render unlit beside lit humans. Material and
   shader work only (no new meshes).
5. **Creatures vanish in habitat.** Value/hue camouflage, silhouettes broken by
   spawning inside shrubs, no ground-contact shadow. Spawn siting landed; material
   value/saturation and contact shadow remain.
6. **Band-to-band sameness.** Bands 1–5 are the same meadow re-lit. Per-band kit
   variation and drained-land grammar near Team Tether are Gate 3 work.
7. **Named mechanism ceilings** from the parity program, each waiting on a mechanism
   change rather than tuning: dawn far-plain desaturation (a terrain aerial-fade colour
   decoupled from `fog_colour`); night far ground too blue and bright; the Hall gate
   jamb unlit at night (a light inside the gate mouth); Warrens mouth flanks in shadow
   (a fill light); Hall silhouette soft at 200–400 m (a silhouette lever, not
   weathering); weather variants indistinguishable from clear (rain/fog need a visible
   delta).
8. **Placeholder-grade elements inside finished scenes:** tournament banners are flat
   unshaded rectangles (the relay pennant proves the kit has a cloth flag); signpost
   text is a `Label3D` resolution smear; one world site renders near black.
9. **Capture harness defects that masquerade as world defects:** three location
   stands are framed inside foliage or at the player's boots; Terrain3D streams around
   the player, not the camera, so distant-camera captures drop the player below the
   stand. Fix the stands before judging those locations again.

A code-blind critic judged the same five frames this session
(`archive/reports/reset-2026-09-02/JUDGE-survey.md`). Its three ranked gaps: no creature
appears in any survey frame, so nothing genre-defining is in view; the distant village
does not survive fog at small size the way the references' landmarks do; the same flat
dark boulder is the dominant foreground object in three of five frames and reads as
placeholder set dressing, with a scale mismatch against the trainer. It also named a hard
shadow-wedge artefact on the spawn field. Its bar answers were **no / no**, with almost
everything fixable by scene changes (creatures in the survey stands, rock variety and
placement, fog falloff, uniform tree spacing) and two items needing art (a detailed rock
mesh, a stronger distant-landmark silhouette). The orchestrator's read, above, is one
step more generous on Bar A because the palette match is real; the composition verdict is
the same.

**Bar answers on the fresh survey frames (orchestrator):** A — yes on palette and mood,
no on composition. B — yes up close (village approach, spawn field), no from any elevated or
distant view. The fixable half (1, 2 mid-layer, 3 clustering, 5, 6, 7, 8, 9) is work in
`docs/ROADMAP.md` Gates 2–3. The half that needs art not in the build (true canopy
structure, a unified creature/character material language) is deferred by hard rule.

## 5. Owner decisions that bound visual work

- Creatures should stand taller than the trainer; fix relative scale by growing the
  smaller side (2026-09-01).
- Grass density stays at 75k tufts / 4 blades / 3 segments; blade-shape redesign
  (clump cards) awaits the owner's answer (2026-09-02).
- The Burrow Warrens interior is approved; never touch it.
- No more villagers; the village population was cut to 13 on owner complaint.
- Every village road has a gate and the boundary cannot be jumped (verified 47 panels,
  22 corners).
- The Pond pocket's density is the approved lush reference; do not spread it.

## 6. Where the knobs are

Sky, light, time: `data/config/art.json`, `scripts/world/world_look.gd`,
`shaders/sky_clouds.gdshader`. Terrain: `data/config/terrain_playground.json`,
`shaders/terrain_ground.gdshader`. Scatter: `data/config/vegetation.json`, per-band
`vegetation.json` (`layer_anchors`), `scripts/world/scatter_rules.gd`; re-bake after any
edit. Grass carpet: `data/config/grass_field.json`, `scripts/world/grass_field.gd`.
Props and camps: `data/config/bands/<band>/props.json`, `data/config/village.json`.
Hall: `data/config/stronghold.json`, `scripts/world/stronghold.gd`,
`assets/environment/team_tether/hall/hall_stone.gdshader`. Warrens:
`data/config/burrow_warrens.json`. Relay: `data/config/tether_relay.json`. Visibility
ranges: `data/config/performance.json`. Perf proxy (draws/prims, not FPS):
`tools/perf_render_stats.gd`; provisional budgets band1_open ≤ 7500 draws / 12.0M prims,
hall_approach ≤ 4000 draws. On-device frame time is the owner's measurement on the
Ally and has never been taken.
