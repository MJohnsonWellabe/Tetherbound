# smoke_crossing_hall_circuit: "actual biome sign missing: meadows" (Systems bar 1)

Systems lane, tb/ev-systems, Tue 13 Oct 2026 (CT).

## Cause
F17#6 (fd1337f8) wrote a live arch's board as one Label3D, "Meadows\nRecommended Lv N".
The circuit smoke requires a visible sign whose text is exactly the biome's name.

## Fix (product, scripts/world/crossing_hall.gd)
The board keeps both painted lines, now as two labels at the same two line positions:
BiomeSign holds exactly the biome name, and AdviceSign below it holds "Recommended Lv N".
sign_text() is unchanged; test_f19_order_consumers still checks it. No test edited.
The parked Claude tablet signage (flag OFF) does not position AdviceSign. Handle that
before un-parking it.

## Proof (headless, local)
- Before: `godot --headless --script res://tests/smoke_crossing_hall_circuit.gd` FAIL
  "actual biome sign missing: meadows" (rc 1).
- After: PASS: all eight arches and eight pedestals reached; signs present (rc 0).
- smoke_net_crossing_hall_agreement PASS. f19_order_consumers + crossing_hall unit tests:
  10 tests, 0 failed.
