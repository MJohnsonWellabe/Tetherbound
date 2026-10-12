# F17#6 Low blockers, round 2: CAPTURE-READY (not self-judged)

- **Source:** `tb/ev-coop-chapters` `555beaa81` (merged `tb/ev-coordinator` at `90bfa7849`); clean import; Low/Compatibility, llvmpipe; captured about 4:56 AM CT Mon 12 Oct.
- **Frames:** the round-1 matched 18 (`VISUAL-PROOF/F17-6`, `tb/ev-captures`), 1280x720 in `frames/`; all 18 on `sheet.jpg`.
- **How:** exterior 14 by `tests/capture_f17_visual_matrix.gd` at 1920x1080 (same real walk; only the mid-street stand moved, to x>47); interior 4 by `tests/capture_f17_hall_interior.gd` at 1280x720.

## Addressed (round-1 judge order)
1. **Red banners (hard rule):** now village teal `#426b69`. The `"*"` retint matched no material and the kit's oxblood vertex tint survived; `MI_Banner` is named and its vertex colour dropped. No other red in the village/Hall configs.
2. **Cyan beam:** it is the real objective beacon. It fades in over its lower 30% and out above 82%, additive, with a faint 2.6x halo; no bar over the companion. Canopy-proof depth kept (owner wayfinding test).
3. **Rain:** 1600 streaks (3 cm x 0.9 m, 20 m ring), cool mist (fog add 0.0055), grade saturation x0.86, terrain wetness 0.6 (darker, glossier).
4. **Placeholder planes:**
   - Sealed arches bricked with the kit's brick (dark but visible); locked arches hold the kit's `Door_8_Flat`.
   - The home membrane culls its back, so the entrance shows the lit Hall.
5. **Interiors:**
   - 79 window modules get the matching `Window_Wide_Flat1` glass (cool panes, dim glow); the hard white sun rectangles are gone.
   - Nave end wall: two teal banners and a lantern.
   - Lecterns 1.3x on 0.9 x 0.3 x 0.9 m stone plinths (the kit's platform).
   - Hall night ambient 0.25 -> 0.12.
6. **Bench:** the stand moved to x>47, midway between the bench pairs at x 40.3 and 58.3.

## Not addressed
- **Cobble scale:** the floor shares `MI_UnevenBrick` with the walls.
- **Nave top-right gap:** not visible after glazing; needs the judge's call.
- **Shrine Room at night:** still close to day.
- **Full-bar (later, Medium/High with Codex):** fog and aerial perspective, mountain card, lamp pools and window spill, street wear, ground cover, tree groups, NPC idles, clutter, UI collisions (clock, quest panel, keyboard glyphs).
- **Checks:** affected unit tests 52 + 32 + 16, all passing; `crossing_hall.gd` parse check clean.
