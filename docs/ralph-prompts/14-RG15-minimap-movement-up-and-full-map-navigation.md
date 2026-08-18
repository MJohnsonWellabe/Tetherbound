# RG15 — Minimap movement-up orientation + full-map navigation

## Owner intent

The current minimap does not behave correctly in live play even though the code comments say it is player-up.

Owner requirement:

> "Minimap doesn't do what it says. I should always be moving in the up direction. The tip of the triangle should point where I'm looking."

For the full map, the previously proposed behavior is approved:
- keep the full map north-up,
- fit the whole current world initially,
- allow zoom in/out,
- once zoomed, allow panning,
- controller-first operation,
- preserve fog, discovered landmarks, objectives, player marker, and legend.

## Goal

Make the minimap communicate two different directional concepts correctly and independently:

1. **Travel direction controls map rotation.**
   - When the player is actually moving, their movement direction must always read as straight toward the top of the minimap.
   - This is NOT the same as camera yaw or character/look direction.

2. **The player triangle communicates look direction.**
   - The triangle stays centered on the minimap.
   - Its tip points toward the direction the player/camera is looking relative to the movement-up map orientation.
   - If the player is moving north while looking east, the map should rotate so north is up while the triangle points right.
   - If the player strafes right while still looking forward, the map should rotate so the strafe direction is up while the triangle points left/right relative to that travel direction as appropriate.

Also upgrade the full map from a fixed fit-only view to a usable strategic map with zoom and pan while preserving its current north-up behavior and shared map data.

## Current state to inspect before editing

Relevant files/systems include at least:
- `scripts/ui/minimap.gd`
- `scripts/ui/tab_map.gd`
- `scripts/ui/hud.gd`
- `autoload/map_state.gd`
- `scripts/world/map_baker.gd`
- `scripts/world/world_extent.gd`
- player/camera code that exposes actual world movement and current look/camera heading
- `scripts/ui/input_glyph.gd`
- `project.godot` input actions

The current minimap code says it derives map rotation from `player_yaw` and uses that same rotation for terrain and markers. That is not the owner requirement. Live play has confirmed the behavior is wrong.

The current full map explicitly documents itself as north-up, whole-world-fit, and with no pan/zoom. That limitation now needs to be removed.

## Critical design distinction

Do not collapse these into one angle:

### Movement direction
This determines **how the minimap world layer rotates**.

Use the player's actual horizontal movement vector in world space, not merely:
- character facing,
- camera yaw,
- last look direction,
- input stick direction before collision resolution,
- or a guessed heading.

Prefer an authoritative movement signal such as actual horizontal velocity/displacement after player movement resolution. Inspect the current controller architecture and use the cleanest existing source.

### Look direction
This determines **how the centered player triangle rotates** relative to the already-rotated map.

Use the authoritative horizontal camera/look heading used by normal exploration controls. The triangle tip should visually answer: "where am I looking?"

## Stationary behavior

A player who stops moving has no new travel vector. Do not let the minimap spin unpredictably or snap to camera heading when velocity approaches zero.

Required behavior:
- retain the most recent valid movement-up orientation while stationary,
- allow the triangle to continue rotating as the player looks around,
- when movement resumes in a new direction, smoothly/cleanly rotate the map so the new travel direction becomes up.

Use a small movement deadzone/hysteresis so analog stick noise or tiny physics drift does not make the minimap jitter.

Do not invent an unrelated compass mode.

## Minimap implementation requirements

1. Inspect the current live path from player movement/camera to `minimap.update_view(...)`.
2. Identify why current main does not satisfy the claimed player-up behavior.
3. Separate minimap state into at least:
   - player world position,
   - movement heading / last meaningful movement heading,
   - look heading.
4. Rotate the terrain, fog, landmarks, objective markers, discovered markers, and any other world-relative content from the movement heading.
5. Draw the player triangle independently from look heading relative to map rotation.
6. Keep the player centered.
7. Preserve the existing shared `Game.map` data source.
8. Preserve fog-of-war and marker visibility rules.
9. Preserve the rule that the minimap is not wild-creature radar.
10. Preserve current performance discipline: do not repaint/rebuild expensive map state unnecessarily every frame.
11. Avoid jitter when movement is nearly zero.
12. Do not silently change world coordinate conventions to make the drawing easier.

## Player-facing examples that must work

Acceptance examples:

- Walking straight forward while looking forward:
  - movement is up,
  - triangle points up.

- Walking forward while rotating camera 90 degrees right:
  - movement remains up,
  - triangle points right.

- Strafing right while camera continues facing forward:
  - the actual strafe/travel direction becomes map-up,
  - triangle shows the look direction relative to that new orientation.

- Backpedaling while looking forward:
  - actual backward travel is up on the map,
  - triangle points down because the player is looking opposite the direction of travel.

- Stop moving, rotate camera:
  - map keeps the last movement-up orientation,
  - triangle rotates with look direction.

- Resume in a different direction:
  - map transitions to the new movement-up orientation,
  - triangle remains correct relative to it.

## Full map requirements

Keep the full map strategically different from the minimap:

### Orientation
- Full map remains **north-up**.
- Do not rotate the full map with either movement or look direction.

### Default view
- Opening the full map should initially fit the whole current playable world/biome sensibly within the panel.
- Preserve world aspect ratio; do not stretch the terrain texture.

### Zoom
- Add controller-accessible zoom in/out.
- Choose existing appropriate input actions if they already exist.
- If new actions are truly required, add the minimum clean set and expose their glyphs/labels in the map UI.
- Zoom should have bounded minimum/maximum levels.
- Minimum zoom must never zoom farther out than a useful whole-world fit.
- Maximum zoom should be close enough to inspect local landmarks/routes without turning terrain pixels into meaningless blur.

### Pan
- At whole-world fit, panning can be disabled or naturally clamped because the whole map already fits.
- Once zoomed in, allow pan across the world.
- Clamp pan so the player cannot scroll the entire world completely off-screen into empty space.
- Controller behavior must not fight menu focus/navigation.
- Inspect the existing menu input architecture before assigning sticks/d-pad/triggers.

### Full-map player marker
- Keep the player's world location accurate.
- Keep a visible facing/look indicator if current map already has one.
- It is acceptable and desirable for the full-map player marker's arrow to show look/facing direction while the map itself remains north-up.

### Preserve
- fog-of-war,
- surveyed percentage,
- discovered region names,
- discovered/silhouette landmark logic,
- objectives,
- dynamic camp markers,
- icon vocabulary,
- shared terrain bake,
- one map database for minimap/full map.

## UI / controller requirements

This is ROG Ally/controller-first.

- Full-map zoom/pan controls must be discoverable on-screen using the existing glyph system.
- Do not make the player infer how to zoom/pan.
- Keep labels compact enough for the handheld screen.
- Ensure map controls do not break normal Back/Cancel behavior.
- Ensure opening/closing the map restores normal world/menu control ownership correctly.

## Do not do

- Do not rotate the minimap from camera yaw alone.
- Do not force the player triangle to always point up.
- Do not use input-stick direction as the only movement source if collision/physics can produce a different actual travel direction.
- Do not snap the map to arbitrary north when the player stops.
- Do not convert the full map to movement-up/player-up.
- Do not create a second map database or duplicate fog/landmark state.
- Do not remove fog-of-war to make navigation easier.
- Do not turn the minimap into a nearby-wild-creature radar.

## Testing / verification

Add/extend automated tests where practical, but this item requires live visual/controller verification because orientation semantics can pass unit math while still feeling wrong on device.

At minimum verify:

### Minimap
- forward movement + forward look,
- forward movement + side look,
- strafing,
- backpedaling,
- stopping then looking around,
- resuming in a new direction,
- diagonal analog movement,
- movement against/colliding with world geometry,
- mounted/alternate movement modes if they are Meadows-reachable and use the same minimap.

Verify world markers rotate with terrain and do not drift/mirror.

### Full map
- initial whole-world fit,
- zoom in/out through all levels,
- pan at zoomed levels,
- clamping at world boundaries,
- controller focus does not get trapped or leak to unrelated menu controls,
- cancel/back exits correctly,
- fog/landmarks/objective/player marker stay spatially aligned at every zoom/pan level.

## Definition of done

RG15 is done when, on the real game build:

- while the player moves, their actual travel direction is always toward the top of the minimap,
- the centered triangle's tip independently points where the player/camera is looking,
- stopping does not cause orientation jitter or arbitrary rotation,
- the full map remains north-up,
- the full map opens at whole-world fit and supports usable controller-first zoom and pan,
- existing fog, markers, objectives, discovery, and shared map data remain intact,
- and no input ownership/menu regressions are introduced.
