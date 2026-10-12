# F17#6 Low blockers, round 2: CAPTURE-READY (not self-judged)

- **Source:** branch `tb/ev-coop-chapters`, commit `555beaa81`, merged with `tb/ev-coordinator` (`90bfa7849`). Imported with no errors.
- **Renderer:** Low/Compatibility on llvmpipe.
- **Frames:** the same 18 matched frames as round 1 (`VISUAL-PROOF/F17-6` on `tb/ev-captures`), scaled to 1280x720 in `frames/`; `sheet.jpg` shows all 18.
- **Exterior (14):** `tests/capture_f17_visual_matrix.gd` at 1920x1080. It is the same real walk; only the mid-street stand moved, to x>47.
- **Interior (4):** `tests/capture_f17_hall_interior.gd` at 1280x720.
- **Captured:** about 4:56 AM CT Mon 12 Oct.

## Blockers addressed (round-1 judge order)
1. **Red banners (hard rule).** Hall banners are village teal `#426b69`. The old `"*"` retint matched no material, and the kit's oxblood COLOR_0 vertex tint survived any multiply. `MI_Banner` is now named and its vertex colour dropped. No other red in the village or Hall configs.
2. **Cyan beam.** It is the real next-objective beacon, not a debug marker.
   - The tube now fades in over its lower 30% and out above 82%.
   - It uses additive blend with a faint halo 2.6x wider.
   - It no longer paints a bar over the companion. It still shows through canopy (owner wayfinding test kept).
3. **Rain.**
   - 1600 streaks, 3 cm x 0.9 m, over a 20 m ring.
   - Cool mist (`fog_density_add` 0.0055), a desaturated grade (x0.86).
   - Terrain wetness 0.6 (darker, glossier ground).
4. **Placeholder planes.**
   - Sealed arches are bricked with the kit's brick, dark but visible.
   - Locked arches hold the kit's `Door_8_Flat`.
   - The home membrane culls its back face, so the entrance shows into the lit Hall.
5. **Interiors.**
   - 79 window modules get the matching `Window_Wide_Flat1` glass (cool panes, dim glow). This also removes the hard white sun rectangles.
   - The nave end wall gets two teal banners and a lantern.
   - Lecterns are 1.3x on stone plinths (the kit's platform, 0.9 x 0.3 x 0.9 m).
   - Hall night ambient drops 0.25 -> 0.12 for lantern pools.
6. **Bench.** The mid-street stand moved to x>47, midway between the bench pairs at x 40.3 and 58.3.

## Not addressed
- **Cobble scale.** The floor shares `MI_UnevenBrick` with the walls.
- **Nave top-right gap.** Not visible after glazing; it needs the judge's call.
- **Shrine Room at night.** Still reads close to day.
- **Full-bar items, for later at Medium/High with Codex:**
  - Distance fog and aerial perspective; the mountain card.
  - Night lamp pools and window spill.
  - Street wear, meadow ground cover, tree groups.
  - NPC idles, village clutter.
  - UI collisions: the clock over the tower, the quest panel over signs, keyboard glyphs in the interiors.
- **Checks run:** affected unit tests 52 + 32 + 16, all passing; `crossing_hall.gd` parse check clean.
