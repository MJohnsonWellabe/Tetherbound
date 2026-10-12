# F17#6 Crossing Hall interiors — claude-r1 (landmarks-claude lane)

Flag: `hall_interiors_claude_enabled` in `data/config/crossing_hall_claude.json`, **OFF** as committed.
Code: `scripts/world/crossing_hall_claude.gd` (new), hooks in `scripts/world/crossing_hall.gd`
(build before the night-ambient pass, `set_night` in `_refresh_interior_ambient`, `place_signs`
in `apply_display`). Presentation only: no collider, portal state, route or save change.

Sheet `before-after-Low.jpg`: `tests/capture_f17_hall_interior.gd` stock cameras (nave/shrine,
08:00/23:00), Low/Compatibility (llvmpipe) at 1280x720 with the ordinary HUD. Left: flag off;
right: flag on (enabled locally for capture only).

What it changes:
- Night lantern pools: additive unshaded floor quads under each wall/hanging lantern, plus a
  flame halo billboard. Compatibility caps lights per object, so real lights cannot pool on the batched shell.
- Sealed arches: one continuous stone reveal (jambs + soffit, 0.28 m deep) with a voussoir ring on
  the face; the brick infill moves to the back of the reveal and is stretched to its outline.
- Signs: sealed arches have a pale stone tablet in the recessed head with dark lettering; locked
  doors carry a larger wooden plaque at eye level; open arches keep the plaque above the opening.
  Placement follows arch state at runtime.

Gate: handoff `r4-handoff-tools/measure.py` prints ALL CLEAR (`measure.txt`). Tests `--only=crossing` 23/309/0 with the flag off and on; `--only=hall` 23/155/0 flag off.

Own code-blind judge (images + defect line only), five rounds, all **WEAK**. Rounds 3–5 verdicts:
warm lantern pools FIXED; sealed recessed reveal + voussoirs FIXED; signage PARTIAL. The open signage items are:
- night legibility of the sealed tablets: pale inlay read as UI text; dark lettering read as illegible;
- the near Locked board reads as a dark tooltip and is cut by the frame edge at this camera;
- mid-distance door signs remain small at the stock camera.

Not posted as CAPTURE-DONE; parked for the coordinator's call.
