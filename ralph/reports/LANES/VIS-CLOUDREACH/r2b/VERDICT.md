# VIS-CLOUDREACH round 2/2b: P2-118 full-party catch frame, CPU

- **Capture:** `phase2_capture_catch.gd --biome=cloudreach --seed=2042`, CPU llvmpipe Compatibility 1280x720. The catch tool now takes the 'Take Good Candy' pickup that held the interact offer beside the wild (the 31 Oct GPU blocker), so the catch completes on main. Scored frame: `09-caught-banner` (the job's only P2-118 frame).
- **Round 2 arm** `menu.json:release_choice_focus` (`--release-choice-focus-candidate`): no visible change in the scored frame (the release ceremony is not open 30 frames after the catch). Not judged; stays OFF.
- **Round 2b arm** `hud.json:catch_card` (existing UIPOSES arm, never judged on Cloudreach; previewed with the new `--catch-card-candidate` capture flag). Random wild spawns differ between boots: the base caught Pebbik, the arm Skyrill.
- **Judging:** standard prompt verbatim, `anchor_tiles.py --pairs 3 --include craft --seed 110405`, three fresh code-blind judges in parallel, `calibrate.py` linear (r 0.66, slope 0.93, anchor RMSE 0.62). Warning: both sides lie below the anchors' measured range (extrapolated).

| Item | Board | CPU base | CPU arm | Delta | Defect calls (arm) |
|---|---|---|---|---|---|
| P2-118 full-party catch choice legibility | F40#18 | 3.77 | **4.61** | +0.84 | FIXED 2 / PARTIAL 1 |

**Verdict: gain; `hud.json:catch_card` ships ON** (all three judges scored the arm higher; the HUD steps back and the result reads as one framed card). The catch completed with the card on (the earlier "UI set broke catch completion" finding was for the whole set together). Test: `tests/test_vis_cloudreach_landed.gd`; `tests/test_capture_readout_side.gd` now asserts the calm seal follows `catch_card.enabled`.

**What all three judges asked for next:** the production camera faces blurred ground at the catch moment, with no creature, sky or Cloudreach stone in frame; frame the caught creature against the world; and show the keep-or-release choice itself with large controller prompts.
