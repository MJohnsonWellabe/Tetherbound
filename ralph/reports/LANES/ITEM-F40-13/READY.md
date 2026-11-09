STATUS: ready (land; bug fix, no score claim)
BRANCH: tb/item-f40-13-card
HEAD: see git log

# F40#13 stale catch card (LANE-MESHY, 9 Nov)

- GPU pass, F40#13 Cloudreach frame 2: "Pebbik broke free" still on screen while the next throw shows "100% CAPTURE CHANCE". A failed throw raises the breakout card for catch_card.breakout_seconds (1.8 s), and nothing ended it when the next orb was released.
- Fix: `hud.json catch_card.clear_on_release_1107` ON with `_why_on` (combat_hud.gd `_on_orb_released`, already wired to throw_aim's `orb_released`): releasing an orb ends a breakout card; success cards and other messages keep their hold.
- New test: tests/test_catch_card_clear_on_release.gd (ships ON with a reason; release ends a breakout card; release keeps a success card).
- Checks: tests grepping hud.json / catch_card / clear_on_release / combat_hud + the new test: 167 tests, 0 failed. smoke_catching exit 0. Net smoke catch_race: ALL CHECKS PASSED.
- Pre-existing, unchanged by this (fails identically on main): smoke_catch_retry "throw 1: could not re-arm the aim within 3 presses".
- Note: the earlier F38#14/F39#9 frames were a CPU wall-time artefact (ITEM-CATCH-CARD); this F40#13 GPU frame is the real player-facing case.
