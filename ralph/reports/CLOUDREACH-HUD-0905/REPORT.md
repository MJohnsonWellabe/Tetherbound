# Full-team captain reward HUD — 2026-09-05

Environment base: pushed `ca7d87113`, `codex/cloudreach-cliffs`, draft PR #44.
This is a bounded HUD checkpoint, not chapter or final visual acceptance.

## Reproduced defect and change

An actual production captain checkpoint with five owned level-40 creatures,
each explicitly one XP short of leveling, produced five real level-ups from
the normal three-round captain reward path. The old centered MomentBanner
overlapped the enlarged relay party rail and hid the controlled creature.
The pre-fix frame remains locally at
`../CLOUDREACH-ENV-CORRECTION-0904/round4/hud-before/relay-west-live.png`.

The existing single presenter now uses an upper-right lane. Each creature's
level, actual stat gains, awarded XP and exact XP counter are grouped together;
the exact 150 Coin / 1 Rare Candy receipt and next relay instruction remain.
The full-team card receives ten seconds of reading time instead of six.
Width, safe margin and added per-member time live in progression feedback data.
This does not add a modal, hide a reward, create another feed or change payout.

## Verified evidence

Commands use `D:/Tetherbound-tools/godot/Godot_v4.7-stable_win64_console.exe`
from `D:/Tetherbound-source`.

- `--path . --rendering-method gl_compatibility --resolution 1280x800 --script
  tests/smoke_cloudreach_production_integration.gd -- --capture --full-party`:
  **74/74**, exit 0, no error lines. Actual captain start, three production
  resolution callbacks, five level gains, piloted movement, all three relay
  inputs, aftermath entitlement, disk reload and duplicate-payout guards.
  Added real widget bounds checks prove the reward/party rail are simultaneously
  visible, separate from one another and the relay prompt, leaving the center clear.
  Combat damage uses an explicit lethal test seam; it is not balance evidence.
- `--headless --path . --script tests/smoke_hud_presentation_lifecycle.gd`:
  **70/70**, exit 0. Exploration and relay layouts retain all five levels,
  fifteen stat fields, exact XP and payout, plus modal/save-epoch lifecycle.
  Actual full-team relay bounds at 1280×800: x819.2, y40, width396.8, height330.
- `--headless --path . --script tests/run_tests.gd --
  --only=test_hud_widgets.gd,test_level_up_announcement.gd`:
  **43 tests / 159 assertions / zero failures**.

The short headless fixture initially quit with eleven audio playback buffers
still active and reported a resource leak. Verbose output identified the real
level-up WAVs. Fixture teardown now stops its one-shots and waits for the audio
thread before quitting; `lifecycle-cleanup.log` has no error or leak lines.
Its expected no-player HUD warning remains explicit. Production audio is unchanged.

Four unretouched images are preserved in `_sheet.png`; originals are local in
`../CLOUDREACH-PRODUCTION-INTEGRATION-0905/live-full-party/`. Render log:
`../CLOUDREACH-ENV-CORRECTION-0904/round4/live-full-party-fixed.log`.

## Blind visual result and limits

Fresh code-blind Astra review (`JUDGE-ASTRA.md`) finds **no blocking visible HUD
defect**. Nonblocking findings remain: panels partially obscure the world-space
relay apparatus, receipt detail needs deliberate reading, and the combat Energy
track has weak contrast. The skill guided real-frame review, not self-acceptance.

These four arena views receive reference **A No / B Yes**. That is a different
sample from round 4's twelve environmental views (**A Yes / B No**), not a
replacement verdict. Bare paving, thin perimeter composition and inconsistent
relay finish remain environment work. Final owner acceptance is external.

Windows GTX 1060 3 GB / Compatibility / 1280×800, 24 measured frames per view:
2,035–2,215 draws, 6.794–7.960M primitives, 24.12–28.34 ms mean. A headless
continuous run shared the host during this capture; these short live samples
are not a quiet baseline, sustained frame-pacing result or ROG Ally acceptance.

Next: continue uninterrupted High Roost/upper/finale play, repair wild-grounding
reliability, and finish the separately owned round-5 environment correction.
