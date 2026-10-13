# F04#6: one story-tied aftermath per fight, same camera before and after

Captures lane, Low/Compatibility (llvmpipe), 1280x720. This lane captures; it does not judge. Sheet built about 5:25 PM CT Mon 12 Oct (owner wind-down).

- **Mechanism:**
  - Each fight has its own `site_object` in `data/config/trainer_aftermath.json`: a BEFORE set and an AFTER set of installed props, lights, an installed NPC body or a smoke wisp.
  - `scripts/world/trainer_aftermath.gd` plants both sets and switches them with the trainer's persisted defeat flag, so a reload or a rematch shows the after state.
  - The cloth scraps are removed.
  - **Test:** `tests/test_trainer_aftermath_world_change.gd` passes: 5 tests, 55 assertions, 0 failed.
- **`sheet.jpg`:** 5 of 6 fights, one row each (before | after), same capture camera per pair.
  - **Vance (r9, `2d7243ad`):** the chained cage and the lit Tether lamp. After the win the cage is tipped, the chain off, the lamp out, and the captive Sela stands free beside it.
    - Sela inside the cage is not readable in the before frame. The fix (larger cage, a light on her, `cb39f21f`) is committed but not rendered.
  - **Oreth (r8, `1b901332`):** the checkpoint barrier, then dismantled with the barrel rolled aside.
    - The r9 fix (the barrier across the road, `f8f4053f`) is committed. Its render ran out of the time limit while the fight was still going.
  - **Halder (r9):** the watch-fire in a rock ring with the torches up. After the win: charred logs, a smoke wisp, and the torches lying apart.
  - **Vess (r8):** the rope line and lantern, then the line cut, a post toppled and the lantern out.
    - The r9 fixes are committed but not rendered (render timed out): a horizontal line instead of the wreath read, and the lantern moved off the stone (the clipping bar).
  - **Warden Aldis:** his arena banners hang, then come down.
- **Open:**
  - **Dell has no pair.** His fight was refused, the ally's seat search boxed in by the relay yard stair and the station props.
    - Cause: the tool's before-frame step moved the player and the ally there.
    - Fix, committed and not rendered: the step now applies only when the site is more than 40 m away (`acbed939`).
    - His site object, committed: the Tether pylon lit with a cyan spill, then dead and leaning with rubble.
  - The r9 renders of Vance, Oreth and Vess.
- **Staging (disclosed):**
  - The day clock is frozen; the tree is paused for the frame; UI layers and the player are hidden for the pair.
  - The follower is put away with the director's own dismiss.
  - For far sites, the player stands at the site before the before-frame so ground detail streams in, then returns.
  - The after frames show bare ground where the fight arena cleared grass (game state).
