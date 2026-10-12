# F04#6 r8: one story-tied aftermath per fight, same camera before and after

Captures lane, Low/Compatibility (llvmpipe), 1280x720. This lane captures; it does not judge.

- **New approach (after two FAILs on the shared banner template):**
  - **Config:** each fight has its own `site_object` in `data/config/trainer_aftermath.json`. It is a BEFORE set and an AFTER set of installed props and lights.
  - **Placement:** `scripts/world/trainer_aftermath.gd` plants both sets at the trainer's post and switches them with the trainer's persisted defeat flag, so a reload or a rematch shows the after state.
  - **Removed:** the flat red cloth scraps and Halder's olive pack. The standard still sinks away.
  - **Sigil stones:** brighter, with a bigger emblem.
- **`sheet.jpg`, 4 of 6 fights**, one row each (before | after):
  - **Vance (captive):** the captive's cage stands chained beside a lit Tether lamp. After the win the cage is knocked over, the chain thrown off and the lamp out.
  - **Oreth (river path):** a Tether checkpoint barrier crosses the path. Afterwards the barrier is dismantled flat at the verge and the barrel rolled aside.
  - **Halder (field):** a Tether watch-fire burns in a ring of rocks with two torches up. Afterwards the fire is cold (charred logs) and the torches lie lowered.
  - **Vess (Ridgeline Watch):** the lookout's rope line is strung between two posts with a lit lantern. Afterwards the line is cut down, a post toppled and the lantern out.
- **Still rendering:**
  - **Dell:** his Tether pylon is lit with a cyan spill before, and dead and leaning with rubble after.
  - **Warden Aldis:** his banners come down.
- **Tool:** `tools/capture_f04_6_aftermaths.gd --trainers=<id> --no-guardian --no-reload`. It wins each fight through the production trainer battle.
  - Each site is framed by ONE capture camera per trainer, before the fight and after it.
  - **Staging, disclosed:**
    - The tree is paused for the frame itself, so the post-fight talk camera cannot take the view.
    - UI layers and the player are hidden for the pair.
    - The follower is put away with the director's own dismiss.
    - Before the before-frame the player stands at the site, so nearby ground detail streams in, then returns to the fight's stand.
  - **Not a capture difference:** the after frames show bare ground where the fight arena cleared grass.
- **Source:** `tb/ev-captures` at `1b901332` (site objects `960932b7` and `73811180`). Finished between 8:25 AM and 10:24 AM CT Mon 12 Oct.
- **Check:** `tests/test_trainer_aftermath_world_change.gd` passes: 5 tests, 55 assertions, 0 failed.
  - Every fight's site object is its own and changes.
  - `settle` swaps before for after.
  - A beaten trainer re-attaches straight into the after state (reload and rematch).
