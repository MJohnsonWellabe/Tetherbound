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

## 4a. GATE2-EVIDENCE-0903 and its residual (2026-09-04, G3-BAND1-FINISH-0904)

`ralph/reports/GATE2-EVIDENCE-0903/JUDGE.md` judged sixteen stands taken from a REAL
played route's own 2 Hz trace (the gameplay camera, HUD on, where the player actually
stood) rather than the posed survey above — a stronger instrument that found things §4's
posed set could not, most importantly that the South Bridge itself had never been framed
by any prior judge. Both bar questions answered **no**. Gate 2's own tasks (2.2–2.7) could
not move that verdict: every residual gap it named was props, fence, signposts, water and
terrain, none of it in vegetation/creature/night scope (see that report's §6). This
section is the residual band's own record, not a replacement for §4.

**Fixed this pass**, each reachable through props/scripts/materials, no new mesh:

- **The South Bridge read as unbuilt** — "a bare plank frame, half off-corner, no gate, no
  banner, no guard, for the chapter's first physical gate and the thing Team Tether is
  supposed to be holding" (JUDGE.md §3). `scripts/world/south_bridge.gd` now builds a
  checkpoint gatehouse over the existing gate leaf — two posts, a lintel, and two hanging
  oxblood banners carrying the same compass sigil `road_gate.gd`'s own Sigil Gate already
  established (`tether_sigil.gd`), at this bridge's own human scale rather than the Sigil
  Gate's monumental one. Reuses an existing mechanism (`road_gate.gd::
  _build_faction_gatehouse`/`_hang_sigil_banner`) rather than inventing a second one.
- **The oxblood reservation was broken** — "the reddest objects in this world are the
  village roofs ... while the one Team Tether grunt wears unrelieved black" (JUDGE.md §2,
  §8.1 item 3). Four of six settlement roof prefabs (`workshop`, `cottage_a`, `cottage_b`,
  `farmhouse_shell`, plus the mill) had NO roof retint at all and exported at the kit's raw,
  more saturated default; only `inn` had been tuned. All five now share `inn`'s own already-
  approved muted terracotta (`#8a5a3a`, `data/config/building_prefabs.json`), clear of both
  oxblood tones in the game (`#6b2a20`, `#7a2430`). The grunt's own colour and the friendly
  HUD icon half of this finding are outside this lane's file ownership (trainers.json /
  `scripts/ui/**`) and are unaddressed here.
- **Orphan fence segments at the bridge approach** (2.13). `bridge_approach_fence`
  (`data/config/bands/band1_lower_meadows/props.json`) was four ~2m panels spaced ~20m
  apart — four isolated posts, not a fence line. Five interpolated panels close the two
  INTACT runs to ~6-7m spacing; the run leading into the already-toppled panel keeps the
  widest gap, on purpose, since that is the stretch meant to read as rotted away.
- **Signposts as bare posts** (2.13). `scripts/world/signpost.gd` now plants a small,
  jittered ring of stone blocks around every post's own foot (deterministic per site) —
  every signpost in the game, not just Band 1's, since this file is shared.
- **No roster decision on the direct Band 1 route** (2.12; Gate 2.5's own acceptance).
  Both of Band 1's authored "temptation" creatures (the Meadowhart herd at the bridge
  approach, the elder Mosshell at the Pond) were sited to require a deliberate detour off
  the corridor spine — by design, per their own `_why_d1` entries. The played
  GATE2-EVIDENCE-0903 route, walked straight with no detour, met neither.
  `data/config/bands/band1_lower_meadows/spawns.json` order 1005 (the Meadowhart pair) is
  moved along the same perpendicular from the same route point, 40m → 12m off centreline,
  so part of its scatter draw now lands on the walkable line itself. Order 1900 (the elder
  Mosshell) is untouched — it stays the region's deliberately curiosity-gated temptation.

**Named but not fixable from this lane's files:**

- **Tree scale and trunk proportion** — "trees measuring only ~2.3× the 1.80m trainer on
  redwood-thick trunks" (JUDGE.md §8, §8.3). `data/config/vegetation.json` `layers.trees`
  (`CommonTree_1/2/3`, `scale_min`/`scale_max` 0.5/1.45) is the only place this is
  authored, and this project's freshness-guarded global bake means it cannot be touched by
  this lane (see CLAUDE.md and this report's own rules). **Proposed, not applied**: raise
  `scale_min`/`scale_max` toward roughly 2.2/4.0 so the range's own top clears 12–18m
  against the 1.80m trainer, verified against `tools/measure_models.gd`'s real native
  mesh height rather than guessed — the trunk-diameter complaint is very likely a symptom
  of being undersized at this scale rather than a separate mesh defect (a correctly-scaled
  tree from the same mesh should not read as a redwood stump), but that needs a render to
  confirm once the scale itself moves. Per CLAUDE.md, grow the trees; never shrink the
  trainer.
- **Scatter reading as a rule, not a layout** — "twelve identical evenly-spaced trees...
  a one-mesh tree wall with no mouth" is `vegetation.json`'s own `corridor_bands`/
  clearings authoring, equally off-limits to this lane.
- **The mill's "add sails" note is a mis-statement of the actual gap.** `building_prefabs.
  json`'s `mill` prefab is a WATER mill with a real turning wheel (fence pickets as
  paddles, an axle, seven paddles at r=1.75m) — a deliberate choice (`village.json`'s own
  note: "The TowerWindmill is gone, not replaced... a mismatched second-family landmark is
  exactly the split-the-difference failure D24 closed"). Adding sails would re-open that
  closed decision, not fix a gap. The real, still-open question is whether the existing
  wheel reads clearly enough at the distances the route actually sees it from; that is a
  legibility check this pass did not have evidence to act on (no G2C stand frames the
  mill), not a sails request.
- **Water shading** — the pond/stream/river material (`data/config/water.json`,
  `scripts/world/water.gd`) already carries eight blind-judged, CONVERGED tuning rounds
  (`_comment_round1`–`_comment_rounds5_8` in that file) and an explicitly recorded ceiling:
  no reflections, by design (bible §15 rules out the expensive tier; the Compatibility
  renderer has no SSR). The GATE2-EVIDENCE-0903 complaint ("appears once, as a small flat
  blue shape... no shore transition and no reflection") is the pond seen once, at extreme
  distance, in the background of one frame — a framing/distance artefact of that one stand,
  not a shading defect this file's own converged values should be re-opened for.

**Blind judge, same stands, after this pass:** full verdict and per-item measurements in
`ralph/reports/G3-BAND1-FINISH-0904/REPORT.md` §8; summarised here so this gap list stays
the living record. Both bar questions are still **no** — none of this residual band's fixes
were ever going to move that verdict alone, since the judge's own headline finding both
before and after is that no creature appears in any of the sixteen stands, which is content
this lane cannot supply. What DID move, confirmed by a fresh blind pass reading the
re-rendered frames with no knowledge of what changed: the South Bridge checkpoint now reads
as a real Team Tether presence ("three bright red banners... carrying a white circular
emblem, hung under a dark timber arch over the only bridge... does read as 'somebody has
claimed this'") where the prior pass saw a bare plank frame; and the oxblood-reservation
finding is resolved by measurement (roof hue 29°/sat 0.42 against the checkpoint banner's
own hue 14°/sat 0.74 in the same render batch, both sampled directly from the rendered
pixels). Two things the same pass still names as open, honestly carried forward rather than
claimed fixed: the gate leaf itself did not read as a clear physical barrier from the one
recorded camera stand at the crossing ("the arch is completely open... nothing spans the
road" — the leaf and its lock are unchanged and functional, this is a framing/legibility
finding, not a mechanism one), and the one Team Tether grunt in frame is distant, off the
road and carries no faction colour of his own (`trainers.json`, not this lane's file).

**W22-BRIDGE-SIGNPOST-0904 (2026-09-04) — the signpost and the bridge brought toward board 18
without Meshy (prompt 74 §7), and the South Bridge held from the approach (CL-B3's in-rules
half).** Board 18 (`docs/art/reference/18_Signpost_Bridge_Modular_Props.png`) was sampled by
crop median before anything was retuned: its signpost planks are H25 S57 V52–58 with CREAM
lettering, its post H29 S64 V57; the old `#c8a874` plank rendered lit at #ffdf9d (near
white) with dark ink. `scripts/world/signpost.gd` now builds each arm as one pointed plank
(full height at the post, 0.92 by the far end, then a point), a bracket at the golden-angle
mount, three rope coils above the top arm and a pointed cap; post and plank albedos are the
board's targets divided by the measured 1.3× sun lift, and the ink is cream with a dark edge.
`_label_scale()` fits the tapered body's shallow end; `tests/test_signpost_geometry.gd` asks
a built signpost whether every label still sits inside its plank and whether the arms still
mount apart and stack clear. The bridge deck (`building_prefabs.json` `south_bridge`, used by
both gated crossings) was rendered in isolation first (`tools/_capture_bridge_deck_isolated.gd`):
kit floor slabs with grain along the span, railed by fourteen field-fence pickets. Now the
slabs are yawed so their plank seams run across the walk, the pickets are gone, and a `rail`
block builds squared posts on stone footings, two sagging hemp ropes and rope wraps at every
post (`gated_crossing.gd::_build_rail`), with the kit timber retinted toward the board's
weathered brown; the rail colliders are unchanged. In front of the generated checkpoint gate
(`south_bridge.gd::_build_occupation`): two staked oxblood sigil banners, crossed-timber
barricade frames on both shoulders with crates and a barrel against the archway, a post
lantern with the faint `tether_teal`, and a posted grunt (`south_bridge_dressing.json`, no
prompt) who stands down when the gate is opened — D74. Verdict: __W22_VERDICT__

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
