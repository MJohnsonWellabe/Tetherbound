# Aquaryn C3 visual verdict

**Framing: 12/16 (75%) — below the 90% bar.**
Fails:
- `t-000.00` — the ally (Ripplet) is a point-blank, out-of-focus wall of polka-dot skin covering the left third of the frame; not identifiable as a creature.
- `tell-start-000.68` — the ally's teal body merges into the black cliff shadow beside the telegraph ring; no contrast separation, effectively unreadable.
- `hit-001.52` — Ripplet's own back/head fills the frame center; Aquaryn is reduced to a sliver of mane and fin-tip above the ally's shoulders.
- `hit-001.60` — same occlusion, worse: almost none of Aquaryn's body is visible.
All other 12 frames read both fighters clearly.

**Tells: 4/4 tell-start readable** (`tell-start-000.68`, `-004.48`, `-008.63`, `-013.27`). The magenta ring and the "!! HEAVY — get clear" banner are legible in every one. Caveat: the ring encircles Aquaryn's own body rather than projecting a lane toward the target, so it reads as "stay out of this radius" rather than pinpointing an exact landing spot — legible, but less precise than a directional tell.

**Presentation breaks:**
- Camera clipping into the ally's own geometry at fight open (`t-000.00`) and during both hit frames (`hit-001.52`, `hit-001.60`), where the ally's body eclipses the named opponent at the exact moment the rubric cares most about (just after a hit).
- A steep, flat, bare rock cliff face fills 30–45% of frame width in roughly ten of the sixteen frames (`tell-start-004.48` onward), crowding the arena into a visually dead corner despite open shoreline being visible behind it.
- Minor: an unrelated distant tortoise sits on the far shore in `t-040.02` — background only, not intruding on the fight space.
- No exploration HUD, no void frames, no sunk/floating fighters observed.

**C3: FAIL** — framing is below the 90% target, and two of the failures are the hit frames themselves.

**Top three defects, ranked:**
1. **Own-creature occlusion at the hit moment** — `hit-001.52` and `hit-001.60`: Ripplet's back blocks the opponent precisely when the rubric requires it be visible.
2. **Camera inside/against own creature at fight start** — `t-000.00`: an unreadable close-range texture wall opens the encounter.
3. **Cliff crowding the arena** — from `tell-start-004.48` on, a flat dark rock slope eats up to half the frame every shot, instead of using the open water/shore behind it.

**Bar A (matches `tetherbound-meadows-keyart.png` world): No.** The blue/green/teal water palette and grass terrain are in the right family, but the creatures render as flat, hard-edged, cel-shaded shapes (visible faceting, thick color patches, no shading gradient) — a much simpler, more toy-like look than the key art's painterly, richly lit creatures and landscapes.

**Bar B (reads as the same game as `palworld-0*.jpg`): No.** Palworld's shots keep the boss and player readable on open, well-lit ground with detailed creature shading. These frames repeatedly wedge the fight against a flat cliff and let the ally's own body block the boss at the hit beat, so side by side this does not read as the same tier of encounter staging or creature rendering.

**Fix split:**
(a) *Scene/camera/placement/VFX* — relocate the arena off the cliff base or reframe to keep it out of shot; add camera-vs-ally collision handling so the camera can't sit inside/against the player creature; bias hit-reaction framing so the ally can't eclipse the opponent; consider a directional ground lane/reticle on the tell so landing location reads faster than "somewhere in this ring."
(b) *New art* — the flat, hard-edged cel shading on the creature models needs a shading pass toward the roster board's painterly look, if it is not simply an artifact of the current (Compatibility) render pipeline.
