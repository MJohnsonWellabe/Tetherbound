# Meadows visual pass — main 5f172772

A blind judge (the visual-judge skill) looked at 21 in-game frames: the five
`tools/survey.sh` landscape shots, eight `tools/_capture_quick_tour_meadows.gd`
frames (menus excluded) and eight `tools/survey_combat.sh` frames. It was given
the key art and the Palworld references, and was told nothing about recent
changes. Frames were captured with Compatibility/OpenGL under xvfb.

To regenerate the frames:

```
tools/survey.sh <godot>
xvfb-run ... --script tools/_capture_quick_tour_meadows.gd -- --out=res://shots/tour
tools/survey_combat.sh <godot>
```

## Verdict

- **(A) Does it read as the key-art world?** Partly no. The village, day and night
  (tour_01) and the relay (tour_03) carry it. The open meadows (survey 01–05) and the
  overlook (03) sink it: no flower drifts, groves, water or layered valley.
- **(B) Does it read as the same kind of game as Palworld?** Yes in intent, no in
  execution. The trainer, the orb throw and the over-creature camera carry it. The
  creature presentation and the fights, which have no spectacle, sink it.

Ranked gaps:

1. **Creatures and fights.** The opponent reads as tiny and far away. Your own
   creature is only ever seen from behind. Hits land with no hit VFX. The fight
   does not fill the frame.
2. **Ground and foliage.** The grass is an even carpet of oversized blades on a flat
   olive texture, with lone trees, no clustering and no flower colour.
3. **Depth and landmarks.** The overlook shows an empty plain ending in a white fog
   wall. The quarry's sci-fi pylon breaks the asset family.

## Scale claim, verified: not a size bug, a staging one

The judge measured Bramblebun at about 0.5m against the trainer. That is wrong
about the data:

- `smoke_art` renders every creature at its declared height: Bramblebun 2.05m,
  mudsnout 2.00m, trailpup 2.30m.
- `lineup_with_trainer.png`, from `tools/_capture_creature_roster.gd`, shows every
  creature taller than the 1.80m trainer.

What the judge actually saw is the combat framing. The camera sits just behind
the ally, with the opponent at about 6m spacing. Perspective shrinks the
opponent, and the ally's face, which the lineup shows is its most appealing
feature, is never in frame. See `08-orb-in-flight.png`. This is fixable in the
scene, through camera and staging. No new art is needed.

The judge also found the three creatures stylistically mismatched. The lineup
shows a more coherent chibi family from the front than the combat frames suggest.
The deer-like alpha is the clearest outlier. This remains an art question for the
owner.

## Fixable by changing the scene

1. Combat framing: keep the whole opponent in frame and large, show the ally at
   three-quarter view rather than straight from behind, and never let the ally or
   a sapling hide the target (combat_04).
2. Hit and charged-hit impact VFX. Soften the cyan arena wall where it cuts
   through trees and fences.
3. Grass: drifts with density falloff, flower colour patches, smaller blades near
   the camera, varied ground tint, carved paths and clearings.
4. Tree trunks read maroon/oxblood, the colour reserved for the villains. Move
   them to grey-brown. Tone down the orange well roof.
5. Rocks: contact darkening, mid-tone and moss variation, and clusters with
   bushes instead of lone black monoliths.
6. Overlook distance: forest masses, river line, hamlets, blue haze instead of a
   white wall, and a horizon landmark.
7. The unlit white-green grass plane beside the stronghold causeway (tour_04), and
   the hard square grass decals on the hilltop (survey 03).
8. The placeholder grey cubes and slab in the village (tour_01).
9. Low-sun exposure hides the player (survey 05). The night moon is oversized and
   blown out.
10. HUD: four "OPEN SLOT" rows and empty hotbar cells. The red "STAGGERED — recover"
    and the cyan "it's open — hit it" contradict each other at a glance.
11. The quarry's sci-fi pylon and untextured plank fences (tour_02).

## Needs art not in the build

- A unified creature style pass and hero-quality silhouettes to the Palworld bar:
  an owner decision, using the Meshy workflow.
- Distance landmark assets and flower/bush variants in the key-art palette. Check
  the installed families first.

## Harness faults found

- The quick tour's `08_creature` and `09_character` frames do not contain their
  subjects.
- The tour's combat step could not engage a wild, and its gather check reported
  "interact gathered nothing". Neither is yet classified as a game or harness
  fault.

## Round 2 (after PR209, main d94586aa)

Landed and render-checked in PR209:
- Bark moved from oxblood to grey-brown, through a presentation overlay kept outside the scatter-bake fingerprint.
- The well now has a round stone curb, grounded posts and a roof matching the cottages.
- Golden-hour exposure raised, with a player rim light.
- Smaller moon.
- Thinner, denser grass, with lilac and gold flower drifts.
- Bluer horizon haze.
- Lighter dark rocks.
- The drained ground no longer reads as an unlit white plane.
- Combat lens changed from 68°/6m to 46°/9.5m, recorded in COMBAT.
- Softer arena wall.
- The stagger prompts no longer contradict each other.
- Quieter vacant party rows.
- smoke_combat point-blank flake fixed.
- Quick-tour framing and gather check corrected.

A fresh blind judge on 21 new frames gave these verdicts:
- **(A) key-art world:** "no overall, yes in places". The village by day and night, the relay and the stronghold carry it. The open meadows and the overlook still sink it.
- **(B) same kind of game as Palworld:** yes. Round 1 was "yes in intent, no in execution".

The judge's remaining ranked gaps:
1. Fights still do not read as events: target occlusion behind the ally, no visible hit sparks in the captured frames, low-contrast creature textures.
2. No landmarks, mountains or water in any frame.
3. Ground value is one olive band, and two tree families clash.

Rejected on checking:
- **Scale:** smoke_art and the trainer lineup show every creature at its declared height, above 1.80m.
- **The red canopy under the beam, and the relay banner:** both are Team Tether hardware, which ART_DIRECTION calls for.
- **Collapsing the empty TEAM rows:** UX requires all five slots to stay visible.

Still open and fixable in the scene, not yet done:
- A dead-bush prop stands inside the fight ring.
- Vines on the village house render white at night.
- Grass needs darker clumps.
- The quarry has untextured plank ends.
- The causeway cobbles show tiling seams.
- The hilltop splat has hard edges, and the distant plain has no forest masses. Both need a terrain/scatter re-bake.

Needs art or owner decisions:
- A creature texture pass with clean colour blocks, for Terrapup, Bramblebun and the boar. The judge ranks this the biggest gap against Palworld.
- A distant mountain or landmark hero asset.
- Water placed where the survey frames can see it.

## Creature texture regrade (owner-approved, local)

The owner chose a local regrade over Meshy. It runs through the existing
`tools/repaint_creature_textures.py` pipeline, driven by
`data/creatures/shiny_colourways.json`. There is no new art and no
generation. Each creature keeps its hues, pattern and overlays; the regrade
changes only saturation, value and colour-blocking.

- **Terrapup:**
  - The shell moves from clay (hue 95, sat 0.16) to mint (hue 150, sat
    0.36–0.4), which the species' own data calls its "mint shell". Its
    saturated greens get the same treatment, since at hue 95 they rendered
    lime, inside the grass band.
  - The coat goes amber: sat ×1.45, val ×1.12.
  - Finish: despeckle 9, posterize 4 at 0.75.
- **Mudsnout:** finish despeckle 9, posterize 4 at 0.6. Its value stays at
  the shipped 0.8. At 0.95 and 0.85 the pale patches blew out through the
  emission slot.
- **Bramblebun:**
  - It renders `bramblebun_redesign`'s own embedded texture, which had no
    vivid colourway at all. It now has one, derived from that same texture:
    a warmer honey coat (sat ×1.15, val ×0.88) with the same finish.
  - At ×1.4 / ×1.05 it rendered glowing fire-orange.
  - `smoke_bramblebun_colourway_binding` now accepts a colourway derived
    from the redesign albedo (same folder and aspect). Its legacy-atlas
    guard is unchanged.
- **Stale import cache:** the render cache hid the first rounds. The engine
  loads imported copies of PNGs, so a regraded texture needs
  `godot --headless --import` before it renders.

Evidence: `lineup_after_regrade.png` and `combat_after_regrade.png`. In the
combat frame, Terrapup's mint shell and orange coat now separate from the grass.

## Round 3 blind judge (after the regrade, main 9074ce51)

Verdicts:
- **Key art:** partly yes.
- **Palworld:** yes in genre, no in finish.

What the judge found:
- **Terrapup's front** is the first view it said meets the Palworld creature
  bar: clean colour blocks, an appealing face, and a silhouette that reads at
  30%.
- **Terrapup from behind** (a mottled shell) and the other creatures still
  fall short.
- **Bramblebun** turns brown and dissolves against the dirt in the world,
  and its ears are blown out in the studio shot.

Checked and rejected: the claim that Mudsnout "has three looks". The dark
bristly boar in the lineup is Tuskroot, a different species.

The judge's top ask is still flat two-to-three-colour blocks.

## Meshy retexture pilot: rejected

- **Task:** one owner-authorized task, 01a0cfcd-84ea-7243-a723-1c1b205739de.
  It retextured the shipped rigged Terrapup GLB using the Terrapup panel of
  `docs/reference/owner-board-2026-08-15-creature-colors.png` as the style
  image, with original UVs kept.
- **Geometry:** the output kept identical vertices, faces and UVs, so it
  could be integrated as a texture alone.
- **Why it was rejected:** the render (`meshy_terrapup_rejected_front.png`)
  lost the species' identity. The dark badger mask around the eyes is gone,
  the face washes to yellow, the shell design is gone, and the surface is a
  noisy dotted orange that blows out through the emission slot. That fails
  CLAUDE.md's "preserve established identity" rule.
- **What shipped:** the local regrade stays. No further Meshy tasks were run.

## Round 2 scene fixes: vines at night and occluders in the fight ring

Two of round 2's "still open and fixable in the scene" items.

**Vines rendering white at night.**
- **Cause:** the kit's flat wall vines (`Prop_Vine1/2/4`) ship with every
  normal pointing up (+Y), although each is a vertical sheet standing off its
  wall toward +Z. They were lit as if they were ground. On the shop's side
  wall, which faces away from the night moon (yaw 25°, pitch −20°), the plaster
  went dark and the vine lit to near-white. By day the same vines washed out
  pale.
- **Ruled out first:** the shop's interior lamp stands 2.5m behind that wall
  (`tools/_probe_village_vines.gd` lists every vine with the lights that reach
  it). Taking the vines out of the interior lights' cull mask was built,
  rendered, and changed nothing, so it was reverted.
- **Fix:** `building_prefabs.gd::wall_foliage_mesh()` gives those three sheets
  the wall's own outward normal (+Z) when a prefab is built. Geometry, UVs,
  triangles and material are unchanged. The draped vines (`Prop_Vine5/6/9`)
  wrap corners and keep their normals.
- **Left as it was:** the stronghold's ruin ivy, built from the same sheets
  in `stronghold.gd`. The fix was rendered at the gate stand. Facing a sunlit
  wall, the corrected ivy lit a paler mint than before. That is a look
  decision, not the night defect, so it was reverted.
- **Result:** in the village-hub stand, the shop's vine now reads green at
  night and a deeper green by day (`_sheet_round4_scene_fixes.png`, top pair).
- **Tests:** `tests/test_wall_foliage_normals.gd`.

**The dead tree in the fight ring.**
- **What was in the frame:** the survey fight opens at (25, −44) on band 1's
  "Gather deadwood" node, a `DeadTree_2` model with no collider. Other rings
  hold `bushes`/`deadfall` scatter, which carries no collider either.
- **Fix:** `combat_arena.gd` takes both out of view when a fight opens, within
  its radius plus `arena.occluder_clear_margin` (2m), and puts them back when
  the arena closes.
  - Scatter goes through `vegetation.gd::hide_fight_occluders()` and
    `restore_fight_occluders()`.
  - Authored harvest nodes built from the same models hide their model
    through `harvest_node.gd::set_fight_hidden()`.
- **What stays as it was:**
  - It is presentation only, and each peer does it locally.
  - Nothing collides differently, and nothing is saved or replicated.
  - Trees, saplings and rocks collide, so they stay.
  - A bush harvested during the fight, or ground `clear_area()` already
    cleared, never comes back.
  - Overlapping rings count their hides.
- **Tests:** `tests/test_fight_ring_occluders.gd`.

**Harness:**
- `tools/_capture_quick_tour_meadows.gd` gained `--stands=<ids>` and
  `--locations-only`. One stand re-renders in about 7 minutes instead of 21.
- It no longer writes `.png.png`.

**Still open:**
- **Frame 03 after the fix:** the opponent is hidden behind our own Terrapup.
  That is the judge's ally-occlusion gap, which is camera framing, not
  scatter.
- **Frame 06 (charged hit):** the survey's charged pilot missed within its
  240-frame window in both runs after this change. It landed in the one run
  before.
  - A control run on the same tree with `arena.clear_soft_occluders` set to
    false also missed. So the miss does not come from the ring clear.
  - The pilot presses charged from 2.8m at an enemy that circles on
    cooldown. The miss belongs to the capture tool's pilot, and it stays
    open there.

## Ally hiding the foe (frame 03): investigated, owner decision

- **Geometry:** the neutral combat tracker orbits at a fixed 35° off the
  ally→foe axis (`combat.json` camera.tracking.composition_yaw_deg).
  - Terrapup (3.85m, radius 1.46m) at the 9.5m/46° lens subtends about 11°
    of half-width.
  - A Bramblebun 2–3m in front of it moves only about 7° off Terrapup's
    centre at 35°.
  - Clearing it needs roughly 70–90°.
- **Tried and reverted:** an occlusion-driven composition that widened the
  angle while the foe was hidden.
  - The combat survey cannot show it. The survey pilot sets the camera yaw
    straight at the foe every frame to steer, so frame 03 is always taken
    from dead behind.
  - The screen-box overlap measure over-reports. An ally's bounding box
    covers empty space, so frame 05 read "fully hidden" at 70° off-axis.
  - Combat movement is camera-relative. Widening the composition toward 80°
    would turn stick-forward nearly sideways to the foe. That is a control
    change, so it needs the owner's decision.
- **Options for the owner:**
  - **(a)** A wider automatic composition for large-ally pairs, accepting
    that stick-forward points off the foe.
  - **(b)** A see-through silhouette of the foe while it is behind the ally.
    Controls are unchanged; it adds a visual language element.
  - **(c)** A larger shoulder offset (camera.max_shoulder_offset 4.5m) for
    big allies.
  - Whichever is chosen, the survey needs a neutral-look frame (no forced
    yaw) to judge it.

## Round 5 (owner: "get all visuals to pass"; branch claude/peaceful-brahmagupta-u0a94r)

Changes judged in R7 (all presentation-only, local to each peer):
- Fight framing, owner-delegated choice: the piloted ally dithers (OBJECT_DITHER, 40% coverage) while it hides the foe from the live camera. Alpha was tried first and drew the creature's far side through its back. `GeometryInstance3D.transparency` is ignored by the Compatibility renderer (measured).
- Horizon: two ridge layers drawn in the sky shader (`meadows_look.json`, realm overlay).
- Ground: macro variation taken most of the way to white and slightly cooler (`terrain_presentation.json`), softer grass tints and clumping. Ground band moved from S 0.86-0.95 / V 0.34-0.45 to about S 0.62-0.70 / V 0.60.
- Stone: harvest deposits use their own light tints over Rock030. Scatter rocks swap to a lifted, desaturated copy of the pack texture (`Rocks_Diffuse_meadows.png`).
  - A runtime `retexture_adjust` rendered white. So did the first import of the copy (2D lossless, no mipmaps). Importing it with the pack's own VRAM and mipmap settings fixed it.
- Water: a mill-pond stand added to the quick tour.
- Combat survey: the charged press waits for the opponent's recovery window. Frame 06 now lands.

**R7 blind verdict** (19 frames: 5 survey, 6 tour, 8 combat)
- **(A) key-art world: no.** The village day and night and the forest camp carry it. The survey meadows, the overlook, the yellow-olive palette and the stronghold's generic kit castle sink it.
- **(B) same kind of game as Palworld: yes.** Genre reads at once. Creature quality, missing impact effects and the empty world mark it as a lower tier.

Ranked gaps:
1. The fight is not an event.
   - The dithered ally reads as a ghost.
   - No impact effect is visible on either hit.
   - The capture throw does not show its target.
   - Terrapup's clay-like body and white-splotch texture look generated.
2. The world is empty and evenly scattered.
   - Single-blade grass at even spacing.
   - An empty plain from the overlook.
   - Three buildings in an open field.
3. Horizon and landmarks.
   - The sky-drawn ranges read as a striped cardboard cutout.
   - A hard green line in S-04.

Other defects it named:
- The hill crown's hard-edged grass islands (S-03).
- Scatter rocks white (S-03, S-04, fixed after that render).
- Three rock families.
- Mixed tree families: leaf cards versus lollipops.
- The same hero plant at bottom centre.
- The aim camera inside grass cards (C-07).
- "NOT ON TARGET" clipped at the bottom edge.
- Black-dash aim arc.
- Red stagger text on the player's own creature.
- Magenta wind-up ring.
- Squashed moon.
- Trainer in a stiff pose in tour frames.
- The ranger NPC in a different style.
- Pale untextured slope beside the causeway (T-05).
- A soft shadow smear in S-01.
