# Backlog derived from the full-state audit — 2026-08-31

**Not `ralph/BACKLOG.md`.** That file has its own Gate-F regeneration protocol
(§16.2: the reviewer receives run evidence blind, so appending to it out of
band would contaminate that process). This is a separate, dated ledger built
straight from the audit's own evidence — sections A–K (`ralph/reports/audit/
A..K-2026-08-31.md`), `GATE-F-FULL-2026-08-31.md`, `VISUAL-CENSUS-2026-08-31.md`, and the owner's 2026-08-30 evening playtest
(`ralph/OWNER_PLAYTEST_2026-08-30B.md`). Every item below cites its source.

## How this is organized

- **Wave 1 (launched 2026-08-31)** — bite-sized, no owner decision required,
  no file overlap with the ten Gate-F-leg lanes currently fixing game systems
  band-by-band. Each is its own `ralph/BACKLOG-<id>` branch.
- **Wave 3 (queued, not yet launched)** — the bite-sized half of the
  2026-08-31 visual census. Each is one material, scale, transform, lighting or
  placement value, or a fix to a capture tool. Read the census report's own
  coverage gaps before treating the table as complete.
- **Wave 2 (queued, not yet launched)** — bite-sized but deliberately held
  back because it touches a file or system a Gate-F-leg lane currently owns.
  Launch once the naming lane lands.
- **Needs an owner decision** — a real, cheap fix exists, but which fix is a
  call only the owner can make.
- **Not bite-sized** — real, cited, but multi-day/needs new art/needs a
  played chapter run. Feeds the completion plan directly; no lane assigned.

---

## Wave 1 — launched

| id | item | source | closing cost |
|---|---|---|---|
| `BACKLOG-C1-NESS-FACE` | Warder Ness's face is a black void at conversation range | Audit C1 | ~1hr investigation + re-render |
| `BACKLOG-D6-SEAM-PROBE` | visible terrain seams; clipmap AND generic mip-bias/debug-overlays now ruled out too — cause is named: per-tile detiling rotation in `terrain_ground.gdshader`'s `accumulate_material()` (see `ralph/reports/audit/D6-seam-probe/FOLLOWUP-2026-08-31.md`) | Audit D6 | cause is nameable now; needs a shader fix that softens the per-tile rotation discontinuity without removing detiling (which fixes the 2K-texture-repeat complaint it exists for) — new task, not attempted this session |
| `BACKLOG-I5-OBJECTIVES-TEST` | a test-fidelity bug in the objectives smoke test (not a game bug) | Audit I5 | ~15 min, test-only |
| `BACKLOG-I6-MINIMAP-HEADING` | minimap heading defect, standing, unowned | Audit I6 | ~half a day |
| `BACKLOG-I7-CREATURES-TAB-TEST` | Creatures-tab controller-isolation coverage gap | Audit I7 | ~half a day, new smoke test |
| `BACKLOG-B3-RARITY-LEGIBILITY` | rarity legible on sight fails for 3 of 4 tiers (direct code read, not a rendering judgement) | Audit B3 | code-level, contained |
| `BACKLOG-HUD-LAYOUT` | owner: health bar to lower-left; on-screen day/time tracker; shrink/relocate the main-story tracker | Owner playtest items 19–21 | HUD-only, contained |
| `BACKLOG-KNIFE-SCALE` | "the knife is comically large" | Owner playtest item 13 | mesh-scale only |

---

## Wave 2 — queued, held for file-ownership reasons

| id | item | source | why held |
|---|---|---|---|
| `BACKLOG-F3-GRANDPA-DIALOGUE` | Grandpa Elias has zero dialogue from tournament sign-up onward and no reaction to the ending, while every other named NPC has both (~30 lines, 5 conversations, one read-ladder in `sequence_director.gd`) | Audit F3 | Grandpa's house content is inside `GATE-F-LEG-S03`'s active scope |
| `BACKLOG-BED-SCALE-POSE` | owner: creature beds too small; creatures stand on beds instead of lying | Owner playtest items 11, 14 | bed prefab/placement is inside `S03`'s (home) and `S09`'s (camp) active scope |
| `BACKLOG-NPC-DIALOGUE-TERSE` | owner: "all NPCs talk too much, just have them be short and to the point" | Owner playtest item 5 | tournament/trainer dialogue (Mira/Tam/Oskar/Halda) is inside `S04`'s active scope; do the mechanical terseness pass once S04 lands so it isn't editing files S04 is also touching |
| `BACKLOG-GLOW-PICKUPS-ONLY` | owner: only key items/TMs/orbs/potions should glow; bulk nodes (trees/wood/stone) should not, or grass should clear space around them | Owner playtest item 3, adjacent to Audit D3 | risk of touching the same scatter/placement-rule code D3 already names as an open, harder defect — do after D3 is scoped |
| `BACKLOG-VILLAGE-BERRIES` | owner: "there needs to be more berries in the village" | Owner playtest item 15 | the exact file, `data/config/bands/band1_lower_meadows/harvest.json`, is `S03`'s to edit for GAME-F1/F5 right now |
| `BACKLOG-E-SCENE-TUNING` | E1 (village orientation fails by day), E3 (Team Tether occupation absent), E4 (2 of 3 camps fail as rest points), E5 (Warrens dressing/lighting) — all flagged "scene-tuning, cheap" | Audit E | camp/village/Warrens scenes overlap `S03`, `S06`, `S09` — sequence after they land |
| `BACKLOG-VILLAGE-LAYOUT` | owner: "the village layout is still terrible"; village NPC spread (owner items 4, 16) | Owner playtest + Audit E1 | placement of Mira/Tam/Oskar/Halda affects the tournament and practice systems `S03`/`S04` depend on; touch only decorative NPCs, after those land |

---

## Wave 3 — visual census (queued, not yet launched)

Source for every row: `ralph/reports/audit/VISUAL-CENSUS-2026-08-31.md`, which
carries the numbered catalogue, the verbatim blind critiques and the contact
sheets. The number in brackets is that catalogue's own defect number.

**These are the bite-sized half only.** The census also found 14 items needing
an owner decision, 14 blocked on owner-supplied reference art (`CLAUDE.md`'s
Meshy/mesh rule — none is proposed here), and 21 that are real but multi-day.
Those live in the census report, not in this table.

**Read before launching any of these:** the census covered 7 of 8 subject areas.
Area 4 got the wild encounter but no trainer/tournament battle. Area 7 got the
current exploration HUD — **including this week's health-bar, day/time and
story-tracker changes** — plus three inventory states and an independent
in-combat pass, but not the map tab, creatures tab, tournament board, build menu
or catch states (`capture_ui_suite.gd` measured ~450s per frame at 1920×1080 and
was stopped; run it at 1280×720 next time). Bands 4–5 have no landmark frames,
and the `J1`/`J2` Stormwall Hall silhouette regression was **not** re-measured.
Closing those gaps is worth one session before treating this table as the whole
picture.

**One dependency worth respecting:** `BACKLOG-VISUAL-SHADOW-RANGE` was the
single most-cited finding across three independent critics, but it was measured
under llvmpipe software rendering, which is exactly where a shadow judgement is
least trustworthy. Confirm it on the Ally before spending a lane on it; several
other lighting rows below become no-ops if it turns out to be a capture
artefact.

### Capture-tool fixes — these are defects in the evidence, not in the game

Cheapest wave to run, and they make every future visual pass more trustworthy.

| id | item | source | closing cost |
|---|---|---|---|
| `BACKLOG-VISUAL-QUARRY-APPROACH-STAND` | `_capture_locations.gd`'s Old Quarry approach eye sits inside foliage; ~95% of the frame is near-black, so the site's announcement shot is unjudgeable | Census 1 | one coordinate, one re-render |
| `BACKLOG-VISUAL-MILL-STAND-FRAMING` | the two mill stands splay the building's verticals and give 55–65% of frame to empty sky | Census 8 | FOV + pitch on two stands |
| `BACKLOG-VISUAL-WARRENS-DEN-STAND` | the trainer's torso and backpack interpenetrate the badger, front and centre of the den frame | Census 12 | stand placement |
| `BACKLOG-VISUAL-LINEUP-RULER` | `_capture_character_cast.gd`'s `14-lineup-all.png` is the one frame where relative scale is the point and the only one with the height annotation stripped | Census 96 | add per-figure ticks |
| `BACKLOG-VISUAL-BUILD-CORNER-ASSEMBLY` | `capture_build_pieces.gd`'s assembled corner does not assemble — roof-to-plate void, slab through the door and V-brace, fence post through the slab | Census 106 | transform values in the capture |
| `BACKLOG-VISUAL-BED-SCALE-RIG` | `creature_bed_scale_check.png` does not perform its own check: no 1.80m figure, two objects at different depths, and the creature that sleeps in the bed is in a different frame | Census 115 | rig change; converts a useless frame into the most valuable one in the set |
| `BACKLOG-VISUAL-BED-REST-LIGHT-RIG` | the two bed-rest frames use different light rigs on the same asset and stage, so the pair cannot be an A/B of anything | Census 116 | one light rig |
| `BACKLOG-VISUAL-BED-REST-EXPOSURE` | `07-creature-resting-far-side.png` crushes the creature to (0,0,0); the rear silhouette carries no recoverable form | Census 117 | exposure |

### Creature scale and material — all measured against the 1.80m trainer in frame

| id | item | source | closing cost |
|---|---|---|---|
| `BACKLOG-VISUAL-STARTER-SCALE` | both starters are taller than the player (terrapup 1.92m, ripplet 1.93m vs 1.80m), and ripplet is designed as a chibi pocket mascot | Census 64 | transform values |
| `BACKLOG-VISUAL-BADGER-LINE-SCALE` | the badger cub (terrapup, 1.92m) outranks the badger adult (burrowback, 1.66m) | Census 65 | transform values |
| `BACKLOG-VISUAL-ALPHA-SCALE` | the alpha is 1.14× a common field boar; a boss that size is not a boss you see coming | Census 67 | one scale value |
| `BACKLOG-VISUAL-ALPHA-GROUNDING` | `galecrest-alpha` floats — lit ground under and between every claw, rearmost toe in mid-air | Census 68 | one y transform |
| `BACKLOG-VISUAL-PIPWING-LINEUP-SCALE` | pipwing renders at 0.77m in its own frame and 1.05m in the lineup — 36% apart, while four other subjects reconcile to 2–4% | Census 69 | one display-scale value |
| `BACKLOG-VISUAL-CREATURE-ALBEDO-CLIPPING` | 31.9% pure-white on duskhush-shiny, 41.9% pure-black on burrowback-shiny, against 0.00%/≤0.01% on every Palworld creature sampled | Census 63 | albedo/exposure/fill |
| `BACKLOG-VISUAL-SHINY-SLOT-SCOPE` | the shiny system hue-rotates every material slot at once, so tuskroot-shiny loses both its moss crest and its tusks and reads worse than the base | Census 61 | recolour the body slot only |
| `BACKLOG-VISUAL-SHINY-OXBLOOD-EXCLUSION` | `reedwing-shiny` paints a friendly duck in Team Tether's reserved oxblood family | Census 62 | exclude a hue range |
| `BACKLOG-VISUAL-CREATURE-PALETTE-CONFORMANCE` | five off-board saturated colours (paddlenewt S=0.91 with 70% of pixels >110 from any keyart swatch; mosshell head; reedwing; ripplet; galecrest) — the board's strip has no cyan at all | Census 70 | material hue/saturation |
| `BACKLOG-VISUAL-PARTICLE-SPRITE` | one recoloured soft-circle sprite does ember, spark and shadow-magic duty across four creatures and reads as lens dust in all four | Census 71 | one sprite |
| `BACKLOG-VISUAL-CREATURE-PROP-SEATING` | burrowback's spine plate, tuskroot's flat moss slab and meadowhart's shoulder card-fan (which reads as a saddle on a wild creature) all read as attachments, not anatomy | Census 76 | reseat and blend |
| `BACKLOG-VISUAL-BROOKTAIL-TAIL-SEAM` | hard unblended material/hue seam at the rump, plus a stray orange dot at the tail base | Census 77 | material seam |
| `BACKLOG-VISUAL-VERIDIAN-MANTLE-GAP` | see-through gap between the shoulder mantle and the neck on `veridian-shiny-rear` | Census 78 | mesh/transform |
| `BACKLOG-VISUAL-MUDSNOUT-LEAF-BACKFACE` | the crown leaf card shows an untextured white/grey backface fringe | Census 80 | material |

### World, terrain and placement

| id | item | source | closing cost |
|---|---|---|---|
| `BACKLOG-VISUAL-SHADOW-RANGE` | shadows work in the near field and stop before the mid-ground; a 10m rock massif and a whole ridge tree line cast nothing. **Confirm on the Ally first** | Census 2, 29 | config, after a hardware check |
| `BACKLOG-VISUAL-DAYLIGHT-GLOW-BLOBS` | yellow-white ground-glow patches in daylight with no emitter, in three village frames; reads as debug lights left on | Census 30 | find and disable |
| `BACKLOG-VISUAL-TREE-LOD-TINT` | the same tree species renders a bright terracotta trunk in the foreground and a near-black trunk at 30m | Census 5 | LOD material |
| `BACKLOG-VISUAL-SPLAT-TRANSITION` | hard sand/grass material boundary with no transition fringe at the quarry | Census 14 | scatter fringe |
| `BACKLOG-VISUAL-SPLAT-RECTANGLE` | a hard-edged terrain splat patch with 90° corners painted on the hillside | Census 45 | one paint fix |
| `BACKLOG-VISUAL-QUARRY-PATH-TERMINUS` | the slab path begins and ends in open sand, squared off, connecting nothing | Census 16 | placement |
| `BACKLOG-VISUAL-QUARRY-FLOAT-BRANCH` | a bare branch floats in frame with no trunk behind it | Census 17 | remove or reseat |
| `BACKLOG-VISUAL-BOULDER-TEXEL-DENSITY` | a 4m boulder carries the same texel density as the 1m rocks beside it — reads as a small rock scaled 4× | Census 23 | UV scale |
| `BACKLOG-VISUAL-BASKET-SCALE` | the same wicker basket is ~1.2m in one frame and ~0.6m in another | Census 21 | one transform |
| `BACKLOG-VISUAL-MILL-OUTBUILDING-SEAT` | the mill's left outbuilding has its eaves at ground level and its walls buried in terrain | Census 7 | one y value |
| `BACKLOG-VISUAL-LEAF-ALPHA-EDGES` | foreground leaf cards show hard black alpha edges and inter-card slivers | Census 26 | alpha/material |
| `BACKLOG-VISUAL-SIGN-LEGIBILITY` | signpost text is a sub-pixel dark smear, illegible at any scale, in two quarry frames | Census 20 | glyph size or icons |
| `BACKLOG-VISUAL-WARRENS-BEAM-MATERIAL` | the Warrens ceiling beams carry the wall's rock texture, and one enters the wall with no bracket | Census 10 | material assignment |
| `BACKLOG-VISUAL-WARRENS-EMISSIVE-SLAB` | an unsourced emissive slab on the Warrens left wall — no geometry, no falloff, no emitter | Census 11 | remove or replace |
| `BACKLOG-VISUAL-WARRENS-ZFIGHT` | a thin white z-fighting sliver across the Warrens rock face | Census 13 | depth bias |
| `BACKLOG-VISUAL-DEN-LIGHTING` | the badger in the Warrens den gets no key, no rim and no bounce — a large creature in a dark room, flat-lit | Census 28 | one light |
| `BACKLOG-VISUAL-SUN-AND-SKY` | the sun disc is a hard-edged white circle with no bloom or scatter (bite-sized); the cloud layer under it is low-resolution and muddy (not) | Census 27 | sun half is bite-sized |

### Village

| id | item | source | closing cost |
|---|---|---|---|
| `BACKLOG-VISUAL-VILLAGE-GRASS-CLEARANCE` | grass grows to the doorsteps and through the paving; the settlement has no cleared negative space | Census 31 | suppression mask around structures and paths |
| `BACKLOG-VISUAL-FLOWER-SCALE` | the purple flower prop is 4–6× oversized (~1.2m clump) and is the loudest object on the whole census sheet | Census 33 | one scale value |
| `BACKLOG-VISUAL-ROOF-TINT` | two adjacent houses carry two clearly different roof hues and saturations | Census 35 | material tint |
| `BACKLOG-VISUAL-VILLAGE-STONE-VALUE` | chimneys and the well clip toward pure white — brighter than the sky, which the keyart never does | Census 36 | albedo |
| `BACKLOG-VISUAL-PAVING-SEAT` | paving slabs float with a ~10cm lip and a dark gap beneath; the cobble pattern is cut mid-stone at the seams | Census 37 | placement |
| `BACKLOG-VISUAL-HOUSE-PLINTH-SEAT` | a house sits on a thin grey slab hovering above the terrain with grass overlapping it | Census 38 | one y value |
| `BACKLOG-VISUAL-IVY-CARDS` | wall ivy floats off the masonry with jagged edges and green fringing | Census 39 | placement + alpha |
| `BACKLOG-VISUAL-CHIMNEY-SEAT` | the chimney sits on the tiles with a visible gap and no flashing, plus an undersized duplicate further along the ridge | Census 40 | placement |
| `BACKLOG-VISUAL-TILING-BREAKUP` | roof moss speckles and ground cobble both repeat at visible fixed intervals | Census 42 | UV/detail breakup |
| `BACKLOG-VISUAL-DEAD-BRANCH-PROPS` | two leafless dead-branch props stand in high summer beside fully-leafed trees | Census 43 | swap or remove |
| `BACKLOG-VISUAL-ORANGE-PLANT` | a flat unlit orange spiky plant reads as a broken asset | Census 44 | material or removal |
| `BACKLOG-VISUAL-SIGNPOST-STYLE` | signpost labels read as floating UI at four different text sizes, one clipped by and intersecting a cottage door | Census 47 | material + typography |
| `BACKLOG-VISUAL-NOTICE-BOARD` | the tournament notice board is a white plane at the wrong scale and depth, illegible, with the trainer's hair rendering through it | Census 48 | scale + placement |
| `BACKLOG-VISUAL-ELDER-SCALE` | the elder NPC reads ~1.3–1.4m and a different proportion family; he stands nearer camera than the trainer and tops out at his shoulder | Census 51 | one transform (the wider proportion problem is blocked) |

### Cast

| id | item | source | closing cost |
|---|---|---|---|
| `BACKLOG-VISUAL-CAPTAIN-FACTION-PALETTE` | the captains wear magenta/lilac/cyan heraldry and a pink cape — hues nowhere on the keyart strip — so they read as a different faction from the grunts they command | Census 86 | material recolour |
| `BACKLOG-VISUAL-CAPTAIN-CREST-UNLIT` | the captains' chest crest does not respond to scene light while the leather around it does; reads as UI pasted on armour | Census 87 | material flag |
| `BACKLOG-VISUAL-GLOVE-FINGERTIP-MATERIAL` | gold-tipped glove fingers on three captains — an unassigned material or skin punching through | Census 88 | material assignment |
| `BACKLOG-VISUAL-CAPTAIN-THROAT-GAP` | a bright tan wedge between beard and collar reads as a hole in the collar geometry | Census 89 | mesh/transform |
| `BACKLOG-VISUAL-RANK-INSIGNIA` | the officer rank badge is a plain glossy sphere with a specular hotspot; the captain's disc floats clear of the bandolier on its own plane | Census 84 | prop replacement + seating |
| `BACKLOG-VISUAL-RANK-PALETTE-DRIFT` | inside the rank ladder, the mid ranks render greyest — the drift runs the wrong way | Census 85 | material values |
| `BACKLOG-VISUAL-CAST-RIM-LIGHT` | no rim or back light anywhere in the cast set, so the Warden's layered coat collapses into one dark mass. Capture-rig half is bite-sized; the in-game half waits on the hardware shadow check | Census 95 | one light in the rig |

### Build kit, beds and camps

| id | item | source | closing cost |
|---|---|---|---|
| `BACKLOG-VISUAL-BUILD-KIT-MOIRE` | severe texture moiré: the floor slab dissolves into a regular dot-field, wall braces shimmer. Missing mipmaps or a grain frequency far above the texel density. Called the most visible defect in the set | Census 100 | sampling setting |
| `BACKLOG-VISUAL-BUILD-KIT-VALUE` | 9.4% of the build-kit lineup's pixels clip; no piece has any dark, which is why the kit has no weight. Exposure half is bite-sized; authored value in the textures is not | Census 98 | exposure + fill |
| `BACKLOG-VISUAL-ROOF-TILE-TINT` | the roof tile is a hot fluorescent orange with no counterpart on the keyart strip — the loudest object in the set | Census 102 | material tint |
| `BACKLOG-VISUAL-DUVET-TINT` | the bed duvet is pool-cyan (133,213,216), off the keyart strip | Census 109 | material tint |
| `BACKLOG-VISUAL-WALL-PLASTER-OFFSET` | the wall's plaster panel is a separate offset card, protruding past the timber frame with the frame shadowing onto it | Census 103 | transform |
| `BACKLOG-VISUAL-ROOF-UV-BLEED` | green fringe pixels along the roof ridge and tile end — UV atlas bleed / insufficient edge padding | Census 104 | UV padding |
| `BACKLOG-VISUAL-FLOOR-SLAB-THICKNESS` | the floor slab's near edge is a literal 2D plane, so every floor-to-wall junction shows a paper seam | Census 105 | mesh |
| `BACKLOG-VISUAL-BED-STUDS` | the bed's iron studs are painted-on flat circles with no bevel, shadow or recess | Census 110 | material/mesh |
| `BACKLOG-VISUAL-BENCH-STRAP-SCALE` | the bench's iron end-straps are ~30cm on a ~1.6m bench — the second-largest shape on the object | Census 112 | one scale value |
| `BACKLOG-VISUAL-BENCH-TOP-TILING` | visible tiling seam where the bench plank meets the metal end strap, plus a fixed-interval dash repeat | Census 120 | UV |
| `BACKLOG-VISUAL-REST-MAT-TEXEL-DENSITY` | the rest mat's woven interior is a muddy blur at visibly lower texel density than the rope ring around it | Census 119 | texture resolution |
| `BACKLOG-VISUAL-BED-FITS-CREATURE` | the creature still does not fit its bed — hindquarters and rear paws outside the ring, front paws on the rim. **This is `BACKLOG-BED-SCALE-POSE`'s own subject, still failing after that lane's change** | Census 113 | one scale value, then re-render |

---

### Combat and the in-combat HUD

The five `survey_combat.gd` frames are the census's only live-HUD evidence, so
these rows cover both subject areas.

| id | item | source | closing cost |
|---|---|---|---|
| `BACKLOG-VISUAL-COMBAT-ENEMY-OFFSCREEN` | a `LEVEL 2 / Bramblebun` boss nameplate and full health bar are displayed while the creature is nowhere in the frame, in two of five combat frames. Loudest single defect in the census | Census 121 | encounter placement or camera framing |
| `BACKLOG-VISUAL-COMBAT-CAMERA-FRAMING` | the combat camera frames the ally's rump in three frames, crops it to shell-and-one-leg in a fourth, and puts its skull in the bottom-centre of the fifth; it never gets both combatants into one readable composition | Census 122 | camera height, distance, look target |
| `BACKLOG-VISUAL-CONTROLLER-GLYPHS` | the ability tray and interact prompt show `E`/`F`/`C` and mouse-button icons. **`CLAUDE.md`'s hard rules say controller first**, so this is a rule violation visible in a still | Census 129 | glyph set |
| `BACKLOG-VISUAL-HOSTILE-BAR-COLOUR` | the hostile health bar is the same green as the ally bars — nothing in a combat frame is colour-coded as a threat | Census 127 | one HUD colour (not the reserved oxblood) |
| `BACKLOG-VISUAL-BOSS-NAMEPLATE-SIZE` | the boss nameplate is a large opaque slab dead-centre top, occluding the band where the encounter would establish itself; both references use a strip about a fifth the height | Census 128 | panel size and position |
| `BACKLOG-VISUAL-ARENA-DECAL` | the arena band is a flat unlit mint gradient that passes through fence posts, clips at a hard diagonal, and whose near edge is off-frame so the arena's shape cannot be read | Census 131 | decal tint, conform, extent |
| `BACKLOG-VISUAL-TARGET-CHEVRON-ANCHOR` | the target chevron floats over empty grass in three frames, in one case at the far-left edge while the action is centre-frame | Census 132 | anchor to target |
| `BACKLOG-VISUAL-PROMPT-OCCLUSION` | the `Engage` prompt is drawn across the creature's face | Census 139 | prompt offset |
| `BACKLOG-VISUAL-COMBAT-STRAY-GEOMETRY` | an unidentified dark grey box and a pale dome sit beyond the fence, reading as untextured placeholder geometry in the open world | Census 133 | remove or identify |
| `BACKLOG-VISUAL-COMBAT-LIGHT-CONSISTENCY` | five frames of one continuous fight in one place are lit two different ways — warm dusk with haze in the first, flat blown-out overcast in the other four | Census 134 | clock/weather pinning in the capture, or a real time-of-day bug |
| `BACKLOG-VISUAL-COMBAT-SIZE-RATIO` | the ally is 4–6× the opponent in linear size (Terrapup ≈1.25m at the shoulder vs Bramblebun ≈0.30m); in both fight references the opponent is the largest thing in frame | Census 123 | scale values; same fault as the starter-scale row above |
| `BACKLOG-VISUAL-TERRAPUP-FIELD-SEPARATION` | the starter's mint shell sits within a hair of the grass in hue and value, so its back half merges with the meadow | Census 138 | material hue |
| `BACKLOG-VISUAL-CLIFF-TEXTURE-TILING` | cliff rock texture repeats on a visible ~1m grid in three frames | Census 136 | triplanar or detail-break |
| `BACKLOG-VISUAL-FENCE-RUN-AUTHORING` | a fence run terminates in mid-air with no end post; elsewhere it is one unbroken mechanical arc with uniform spacing, no gate, no gap and no lean | Census 137 | placement |

---

### HUD and UI — the exploration pass

`hud_full.png` carries this week's HUD changes (health bar lower-left, day/time
tracker, shrunk story card), so these rows are against the current state.
**`BACKLOG-VISUAL-INPUT-GLYPH-LANGUAGE` is the one finding two blind critics
reached independently from different rigs, and it is a `CLAUDE.md` hard-rule
violation, not a taste call — take it first.**

| id | item | source | closing cost |
|---|---|---|---|
| `BACKLOG-VISUAL-INPUT-GLYPH-LANGUAGE` | five input languages at once; the exploration HUD shows **no gamepad glyph at all** (`M`/`I`/`R`/`C` keycaps, quickbar slots `1`–`5`), the tooltip shows a **mouse-click icon with no controller equivalent**, and two on-screen instructions for the same action contradict each other. Controller-first is a hard rule | Census 148, 129 | data/config for the language; redrawing the two unreadable glyphs is small art |
| `BACKLOG-VISUAL-FOOD-BAR-LEGIBILITY` | the FOOD bar is ~15% opacity with ochre text on ochre fill and grass reading through it; **at 35% it vanishes from the frame entirely** | Census 142 | opacity, contrast |
| `BACKLOG-VISUAL-HEALTH-BAR-CONTRAST` | "100 / 100" is light grey on a mid-green fill over a barely-darker track; reads as one green lozenge at a glance | Census 143 | contrast |
| `BACKLOG-VISUAL-VITALS-COLOCATION` | health and food are 350–500px apart, so the two numbers a player checks together are never in one glance | Census 144 | layout |
| `BACKLOG-VISUAL-HUD-SAFE-AREA` | nothing sits inside a 5% title-safe box; the health bar is 14px from the left edge (0.7%). First things clipped on a handheld with rounded corners | Census 145 | margins |
| `BACKLOG-VISUAL-HUD-ANCHORING` | the HUD re-flows with resolution instead of anchoring — the TEAM roster is present at 720p and absent at 1080p, the FOOD bar moves, the quickbar grows 50% | Census 146 | anchors |
| `BACKLOG-VISUAL-MODAL-HUD-SUPPRESSION` | the inventory modal neither dims nor suppresses the HUD, and loses to it: the minimap draws on top of the panel, with the panel's own "Day 1" label printed inside the minimap ring | Census 149 | z-order / visibility |
| `BACKLOG-VISUAL-INVENTORY-FOOTER-PLACEMENT` | the inventory footer legend sits outside and below its own panel, floating on the world and overlapping the live health bar | Census 150 | layout |
| `BACKLOG-VISUAL-PANEL-STYLE-SYSTEM` | six panel styles, three corner radii, five opacities; the minimap has hard square corners around an inset rounded ring | Census 151 | one style token set |
| `BACKLOG-VISUAL-MINIMAP-CONTENT` | the minimap is the darkest, heaviest object on screen and its interior is empty — no terrain, no path, no landmark, no N/E/S/W, a player marker that reads as a fir tree, and a second triangle cut in half by its own ring | Census 152 | map draw + marker art |
| `BACKLOG-VISUAL-STACK-COUNT-CHIP` | stack counts straddle the cell border with no background chip; unreadable at 35%, and a light icon behind one would erase it | Census 154 | chip behind the number |
| `BACKLOG-VISUAL-ITEM-STATE-MARKERS` | selecting an item destroys the quickbar-assigned marker, so you cannot see whether the selected item is assigned; neither marker is legended | Census 155 | state layering |
| `BACKLOG-VISUAL-HUD-ALIGNMENT` | four right-anchored HUD elements have four different right edges spanning 23px; two centred-looking elements are centred on axes 270px apart | Census 156 | alignment |
| `BACKLOG-VISUAL-CLOCK-VS-SKY` | the clock reads `Day 1 · 00:00` — midnight — over a bright midday sky with a long low sun shadow. Very likely the same root cause as owner playtest items 9/18/22/23 | Census 157 | clock source |
| `BACKLOG-VISUAL-OPEN-SLOT-LEGIBILITY` | "OPEN SLOT" rows are ~25% opacity with grass reading through them — the five-creature limit made visible, and nearly invisible | Census 158 | opacity |
| `BACKLOG-VISUAL-KO-CHIP` | the KO chip has ~2px clearance on both sides and is a **second danger red** that does not match the oxblood reserved for Team Tether | Census 159 | spacing + hue |
| `BACKLOG-VISUAL-QUICKBAR-CELL-LAYOUT` | the "x12" count hangs outside its cell; near-invisible dividers make slots 2–5 read as one empty box | Census 160 | layout |
| `BACKLOG-VISUAL-DISABLED-STATE` | the disabled action signals only through opacity plus a keycap colour change, which reads as a rendering inconsistency | Census 161 | state styling |
| `BACKLOG-VISUAL-DATE-FORMAT-CONSISTENCY` | the inventory header says "Day 1"; the HUD says "Day 1 · 00:00" | Census 162 | one formatter |
| `BACKLOG-VISUAL-INVENTORY-LAYOUT-WEIGHTING` | the preview pane is the widest column and ~93% empty while the item grid is squeezed into six columns | Census 163 | layout |
| `BACKLOG-VISUAL-DURABILITY-READOUT` | durability is plain text where a bar would read faster, while the two readouts that are bars are the two that are illegible | Census 164 | widget choice |
| `BACKLOG-VISUAL-INTERACT-PROMPT-MISSING` | the frame named `ui_explore_prompt` contains no prompt: the trainer stands beside the harvest node with no glyph, no highlight, no outline | Census 147 | tell a real prompt bug from a capture-timing one, then fix |
| `BACKLOG-VISUAL-NOTCHED-BOULDER` | a boulder with a right-angled notch cut into it and a pure-black unlit face — reads as a failed boolean or inverted normals, and it is beside a rock in a completely different material language | Census 165 | mesh/normals |
| `BACKLOG-VISUAL-SAPLING-INTERSECTS-PLAYER` | the harvest sapling passes through the trainer's arm | Census 166 | placement |
| `BACKLOG-VISUAL-HEIGHTMAP-STEP` | a right-angled terraced step with a flat top in the terrain — an unsculpted heightmap edge | Census 167 | sculpt |

---

## Needs an owner decision (real fix exists, no lane assigned)

- **C4** — Mira, Tam, Oskar, Old Bram fail "named characters individual" (two sex mismatches measured). An Option A/B decision is already on record; closing it is config-only once chosen.
- **C3** — two stylistic Team Tether bodies, cosmetic-only either way.
- **I4** — a harvest bare-hand doc/code drift, needs a small owner call plus ~1hr.
- **D5b** — the river reads as a canal; rim noise + regen exists as a fix, bank-angle change is capped pending an owner call. (Same defect the owner's own playtest item 8 names independently.)
- **D7** — aerial-perspective horizon-band limit needs an owner fog decision.
- **G4/G5** (from the earlier exit-criterion audit pass) — bands 4–5 introduce zero new catchable species; the challenge ladder's typing axis is flat across all 27 rungs. Both are content/design-scope, not bugs.
- **G3/roll_new_worlds** — `D-0830-1` stays off pending Gate F re-baseline; sequence after the Gate-F-leg lanes land.
- **STALE-GATE_AT** — `scripts/world/playground_world.gd::GATE_AT` is still `(27.5, -16.0)`, the pre-OP-0830-1 gate position; its own doc comment already says the real gate is "the point where that line crosses this road — (38.7, -19.9)" (`village_boundary.json`'s `RoadGate`, correct), but the constant itself was never updated to match. Found reconciling `GATE-F-LEG-S10CDE`'s merge, which had aimed a walk at the stale value and still passed (dead code: `GATE_AT` is never actually passed to anything that builds or checks a real interactable — only referenced in its own and a neighbour's comments — so nothing player-facing reads the wrong number today). Harmless now; worth a one-line fix before anything is ever wired to it.
- **TOURNAMENT-SEMI-DIFFICULTY** — `GATE-F-LEG-S04`'s isolated tournament run lost the semi-final to the same pattern 5+ times running (a Mosshell charged hit for 87.8 damage, one-shotting a creature at 64% HP) before the lane was cut off for unproductive iteration (13 runs, no stable result, its one behavioral change attempted a reactive auto-switch-on-faint that would have reversed `combat_manager.gd`'s documented D32 design — not that lane's call to make; discarded, not merged). `data/creatures/species.json`'s own mosshell entry admits "nobody has fought one yet." Potion/revive healing between rounds does work (confirmed by the same lane). At `tournament.json`'s own documented minimum entry state (`min_party_size: 5`, `min_level: 6`, checked against the five strongest of an owned team), this may be genuinely too hard for a blind first attempt, or it may be a scripted-battler-AI artifact (no real player uses potions/switches as reactively as a crude auto-battler). Needs either an owner balance pass on Mosshell's charged-move damage, or a real (human or better-scripted) playtest of the semi-final specifically before concluding it is actually too hard. Not fixed here.
- **B2-GRASS-SEPARATION** — `BACKLOG-B2-GRASS-SEPARATION`'s own lane swept Bramblebun's full safe height range (0.86m, the "too small to see" clearance floor, through 1.15m) and confirmed no point in it restores the pre-redesign 1.06-1.15 grass-separation ratio; `field_rim` was already proven a no-op-to-negative lever. Left at the already-best point in range (1.00m / rim 0.0), not silently reverted. Closing this for real needs an albedo/value change to the `bramblebun_redesign` mesh (a new Meshy generation, which CLAUDE.md gates on owner-supplied reference art) or an owner-approved size push past "modest." Full method in `ralph/reports/audit/BACKLOG-B2-GRASS-SEPARATION-2026-08-31.md`.

---

## Not bite-sized — feeds the completion plan directly

- **GAME-F2/F4/F5, PROGRESSION-F7, TRAVERSAL-F8** (GATE-F-FULL) — assigned to the ten active Gate-F-leg lanes; not duplicated here.
- **J1/J2** — the open world and the Meadows Hall read as two different productions; the Hall silhouette fix has *regressed* (+33.1 → +11.6) because a later lane landed art on top of it without re-running the measurement. Real, multi-day art/material work; also a process fix (re-run the silhouette probe on every future Hall-exterior landing) that should go in `ralph/conventions.md`.
- **D3** — open-field shape/silhouette interest; the scatter placement-rule defect is a design+code pass, not a bug fix.
- **I3** — progression legibility as a played path cannot be determined without a new smoke test (~half a day) *and* matches the owner's own item 17 ("what do I need for the tournament") — worth a real UI feature once S04 lands, not just a test.
- **J4** — ROG Ally performance; no container can determine this, needs the owner's hardware.
- Owner items 6 (village wall/gate), 7 (TEAM counter drift), 8 (river source), 9/18/22/23 (day/rest/clock — likely one root cause), 10 (building recipes illegible), 17 (training/tournament clarity), 24 (camping build-menu category) — all recorded in `ralph/OWNER_PLAYTEST_2026-08-30B.md`'s own triage; several are already being answered live by the Gate-F-leg lanes (S03's home-building fix, the tournament-requirement work).

---

## Sources

- `ralph/reports/audit/{A,B,C,D,E,F,G,H,I,J,K}-2026-08-31.md`
- `ralph/reports/gate-f-full/DEFECTS.md`, `ralph/reports/audit/GATE-F-FULL-2026-08-31.md`
- `ralph/OWNER_PLAYTEST_2026-08-30B.md`
- `ralph/reports/audit/VISUAL-CENSUS-2026-08-31.md` and its committed critiques
  and contact sheets under `VISUAL-CENSUS-2026-08-31-shots/`
