# F04#6 aftermaths: what each Meadows trainer win leaves in the world

Captures lane, Low/Compatibility (llvmpipe), 1280x720, real time. This lane captures; it does not judge.

- **Source:** `tb/ev-captures`. The scene work is at `c99810ba`. No aftermath script, config or capture-tool change since then, so every row runs the same aftermath code.
  - Dell, Vance, the relay console and the mill crossing: the run finished about 8:45 PM CT Sun 11 Oct.
  - Oreth, Halder, Vess, Hald and the Warden: one trainer per run, finished between 11:13 PM CT Sun 11 Oct and 1:00 AM CT Mon 12 Oct.
- **Tool:** `tools/capture_f04_6_aftermaths.gd --trainers=<id> --no-guardian --no-reload`.
  - It wins each fight through the production trainer battle (`_resolve_won`), then frames the site.
  - **Disclosed:** the ally is a fixture ("Camera") enrolled in the party. Before each site frame the ally is recalled with `creature_recall`, so the site is clear.
- **`sheet.jpg`**, one row per trainer (before, after, site):
  - **Dell, Vance:** the relay standard is raised before the fight. After it, the standard is down and its cloth lies on the ground.
  - **Oreth, Halder, Vess:** each captain's standard stands before the fight. After it, the standard is gone, the fallen cloth lies at the post, and the captain's sigil stone (Rock_Medium_1 with its sigil) is lit.
  - **Keeper Hald:** after the win the stronghold's Tether readout screen shows text strokes, a gauge and a waveform.
  - **Warden Aldis:** his two arena banners hang before the fight and are gone after it (`defeated_warden`).
  - **Last row:** the relay console before the press and 14 s after it, then the Old Mill Crossing after the relay falls.
- **Not in this sheet:**
  - The Warrens guardian, which has its own sheet in F04-0.
  - The save/reload pass. It was skipped (`--no-reload`) because the full pass exceeded the container's 2-hour job limit.
  - **Covered by unit tests instead:** `tests/test_trainer_aftermath_world_change.gd` checks the settled stone, the touch props, Dell's standard, the Warden-banner source and the readout texture. It passes: 14 tests, 103 assertions, 0 failed.
- **Earlier runs, not used:**
  - One was killed for memory (exit 137) while running beside other captures.
  - One hit the 2-hour limit at the guardian pilot. Neither is in the sheet.
