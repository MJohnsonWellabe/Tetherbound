# THINGS-GLIDEBANK: banked glide (F38#15 close-out)

**Row.** F38#15: High 7.70, Medium 7.37 (`G-medium-f38-15-galeland.md`, bce34cf3). 3/3: "the glide is still a flat, symmetric, fully spread wing; judges want a banked or swept-back glide, distinct from the landing flare". Close-out exception: the row needs +0.13 at Medium.

**Change** (flag `fly_traversal.json glide_bank_1112`, OFF): the carrier art rolls into a turn (from sideways acceleration, up to 36 degrees) and dips its nose with forward speed (up to 8 degrees). Art only: movement, collision, the rider and the grip are untouched. Remote carriers are not banked yet (local presentation only).

**Capture.** The glide frame on main is a hover with no stick held, so a bank cannot show. New capture option `--glide-steer` (both sides): fly forward, start a right turn, take the frame mid-turn (`--glide-steer-frames=20`). Use the default carrier, `--seed=2042`, and pin time of day and weather on both sides (LANE-SCOUT's note: part of the last gain was the sky).

**CPU** (`_sheet_glide_base_vs_bank_cpu.jpg`: glide frame, left to right: base with the steer, bank at 24 degrees, bank at 36 degrees as shipped in the flag): on the arm Galecrest is rolled into the turn with one wing high, and the rider hangs straight from the feet. 24 degrees was too close to the base turn to read; 36 is a clear bank. Landed frame unchanged.

**Tests.** `tests/test_glide_bank_1112.gd` (4).

**Not done.** No rim light on the carrier (the judges' second suggestion): that is light, LANE-PLACES. The wings still cannot sweep (no wing bones).
