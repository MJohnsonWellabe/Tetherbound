# F03 lure-walk saves (gzip)

These are gzipped copies of Gate F leg saves under `ralph/reports/`, so that `render.yml` (whose checkout leaves out `ralph/`) can load them. The walker's receipt sha256 is of the inflated JSON, so it matches the original. **None of them is earned play** (strict re-score, 2026-09-27): S04-exit is the hand-authored seed of leg s05 (`gate-f-leg-s05/RUN_METADATA.json`); S06-exit-band3 and S07-exit-band4 are written by `tools/gate_f/build_s07_entry_synthetic.gd` / `build_s08_entry_synthetic.gd`; S07-exit-band3 and S08-exit-band4 are exits of legs played from those synthetic entries. They are fine for dry runs that find blockers; a criterion close needs an earned save such as `tests/fixtures/earned_saves/checkpoints/seed4_hall/`.

| file | source |
|---|---|
| S04-exit.json.gz | ralph/reports/gate-f-leg-s05/saves/S04-exit.json |
| S06-exit-band3.json.gz | ralph/reports/G3-BAND3-0903/gate-f-s07-v4/S06/saves/S06-exit.json |
| S07-exit-band3.json.gz | ralph/reports/G3-BAND3-0903/gate-f-s07-v4/S07/saves/S07-exit.json |
| S07-exit-band4.json.gz | ralph/reports/G3-BAND4-0903/gate-f-s08-run/saves/S07-exit.json |
| S08-exit-band4.json.gz | ralph/reports/G3-BAND4-0903/gate-f-s08-run/S08_fixed/saves/S08-exit.json |

**Derived (disclosed):** `S07-exit-band3-plus-1wood-1fiber.json.gz` is S07-exit-band3 with exactly one `wood` and one `fiber` added to the first two empty satchel slots. That is the state of a player who has gathered the materials Doss asks for. It is used only to capture Doss's repair action for F03#1; the original save has neither item, so there Doss repeats his request.

**Derived (disclosed):** `S04-exit-pose-on-road.json.gz` is S04-exit with only `player_pose.position` moved from the porch spot `[18.88, 0.18, 12.61]` to the road beside it, `[13.2, 0.4, 20.0]`. On main 32bd3307 the original pose loads the player entombed inside the home porch geometry, and the player controller then snaps back to it about 30 s into any walk (render.yml 36270090216 and 36271079428, reproduced twice). That is Meadows core's village issue, reported on PR #289. This fixture is used only for Bram's F03#0 lure walk; party, flags, inventory and clock are unchanged.

**Seeded (disclosed):** `S09-exit-seeded.json.gz` is an unmodified gzipped copy of `ralph/reports/gate-f-leg-s09/saves/S09-exit.json`. That save is **not earned play**. Its leg began from a hand-authored idealised seed (`S09-seed.json`: five Lv18 creatures, all three Sigils, every Band 1–4 completion flag), and its own `S09-LEG-FINDINGS.md` labels it "CONDITIONAL, ISOLATED evidence". The Stronghold approach was then driven for real (Sigil gate, Watchman Corr, Warder Ness), which leaves the team at Lv19. The coordinator accepted it on #289 (option 1) for the Hall F03#1 capture only. The player walks back to the off-road alpha and fights it with ordinary input; every Lv11–13 lure save loses that fight.

**Derived (disclosed, F03#0 vault lure):** `S06-exit-band3-warrens-uncleared.json.gz` is S06-exit-band3 with exactly one change: the `warrens_cleared` entry is removed from `progression.flags`. That is the Warrens state a player walks into before beating the required guardian, with the guardian standing and the vault door shut with its lit seam. The saves that would carry this state (after the South Bridge, before the guardian) were never kept. The owner ruling on #356 (07:03 UTC, 2026-09-27) allows declared start saves when disclosed.
