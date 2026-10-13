# P2-092 — live Hollows spacing remains open

- 13 Oct 2026, 07:57 CT; branch `tb/codex-carryovers`. OFF source `1f6d7e210888244d544ea4290770cb844ca21a66`; private ON `7bcf144520f8168cda92ab9b84e600a3a099b830` changes only the scoped candidate boolean. Published flag remains OFF.
- Exact historical Low baseline retained from `365b344a1b04b83adb1cb8185029d1492514e871`: `D:/tetherbound/.artifacts/codex-service-carryovers/P2-092/hollows-live-Low-baseline.jpg`, SHA256 `94e026b708b578e4b4bd3196d501819f1bca3096a2659501cbf2d84e50f18f2a`.
- Fresh OFF/ON: Low, Compatibility, 1280x720, seed 2042, production fight camera, 18 s live piloted combat. Both processes exit 0; receipts qualify for review, no observation/scale gaps, 45 verified PNGs each.
- Both observe actual Stormwood Calm/rain. Existing Calm pin, direct party/level/healing/placement, and forced flee after the cap are disclosed. No earned route, F19, victory, device-performance or all-frame visibility claim.
- Dynamic combat differs: 42 versus 38 combat captures and four versus three tell cycles. Compare equal interval samples, not identical animation poses or camera trajectories.
- Neutral four-pair sheet: `D:/tetherbound/.artifacts/codex-service-carryovers/current-main-1f6d7e2/P2-092/blind-review-v1/_sheet.png`; full-size neutral frames and independent `JUDGE.md` are alongside it.
- Blind verdict: candidate A preferred; defect WEAK, full game bar FAIL. Ally spacing improves later, but opening visibility and trainer/boss overlap remain inadequate. Key-art bar NO, game-kind bar YES.
- Raw paired evidence: `C:/CodexTemp/tetherbound-native-service/.tmp/stormwood-phase2/service-p2-092-main1f-{OFF,ON}-Low/`; launch receipts under `C:/CodexTemp/codex-service-carryovers/current-main-1f6d7e2/P2-092/`.
- First OFF invocation rejected an unsupported output path; retained separately. Corrected retry used the fixture's existing permitted subtree without weakening its guard.
- Item remains open; no READY. A further approach must address trainer separation and opening readability without shrinking creatures.
- Fresh source candidate prepared behind `camera_presentation_enabled:false`: 70° side-on camera and trainer-beside-ally fields on Hollows Alpha; source gate filters only those two fields while OFF. Hollows Alpha contact-spacing override remains disabled.
- Root ran the absolute Godot `--check-only` parser on this candidate: exit 0. No native capture or visual pass has been run for the new candidate.
- Co-op limit: camera yaw is local to each participant; the trainer-aside flag affects ordinary/host `_place_fighters` placement. Joining realm-owned peers use `_place_realm_owned_ally` and deliberately retain their trainer transform, so do not claim trainer separation there without a later capture/fix.
- Future private pair recipe after the source commit is pinned: OFF uses that commit unchanged; ON privately flips only Hollows Alpha `combat.camera_presentation_enabled` false→true in `data/config/stormwood_encounters.json`. Common source changes are that config plus `scripts/creatures/wild_creature.gd`; the P2-092 capture/observer fixtures stay unchanged. No pins or launch packet updated yet.
