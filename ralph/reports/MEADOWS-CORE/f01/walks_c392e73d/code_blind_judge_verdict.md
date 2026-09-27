# F01#2 / F01#3 — code-blind judge verdict (rendered walks at c392e73d)

Judge: independent subagent, images only (no source, config or logs read).
Frames: GitHub render runs 36300927425 (day, 98 frames) and 36300929114
(night, 96 frames), `tests/capture_village_walk.gd --route=visits --from-title`.
Viewed: every start / reached / at frame in both runs, the "end" frame before
each weak reached frame, and 8 travel frames per run.

| Target | Day | Night |
|---|---|---|
| Grandpa | PASS 003 (prompt, face to face) | PASS 003 |
| Bram | PASS 013_end (prompt, at the bar); 014_reached alone FAILS (inn partition) | PASS 012_end; 013_reached same partition |
| Tam | PASS 022 | PASS 021 |
| Mira | PASS 027 (across the counter) | PASS 026 |
| Oskar | PASS 035 | PASS 032 |
| Halda | PASS 043 | PASS 040 |
| Old key | PASS 051 ("Take the old key" prompt) | PASS 049 |
| RoadGate | PASS 055 ("Try the gate"), 056 (gate opens) | PASS 053, 054 |
| Practice Meadow trainer camp | PASS 071 (crate, barrel, sack) | PASS 069 (crate, barrel) |
| TrailGate | PASS 083_end (archway, "South Bridge" sign); 084_reached alone FAILS (camera on a post) | PASS 082 (also 081) |
| PondGate | PASS 098 | PASS 096 |

Night readability: playable; paths, villagers, gates and signs readable under
moonlight and lanterns (044, 058, 075).

Defects (none prevents identifying a target):
- Bram reached frames (day 014, night 013): a partition covers the target.
  Evidence is the preceding frame. Fixed in the harness at af34e9b4
  (indoor targets orbit only near the approach bearing).
- Camp (day 071, night 069): a creature stands between camera and pack; at
  night the sack is in shadow partly behind the quick-bar HUD; the cyan quest
  beam covers the left third.
- TrailGate day 084: camera jammed against a gate post (083 carries it).
- Oskar night 032: a roof eave renders as a flat black mass.
- Player hair washes out near-blonde under interior/lamp light.
- Interiors are daylit at 23:00 (cosmetic mismatch).
- Close camera: day 030 nearly inside the player's back; day/night 001 hard
  against a wall.
- Right-side quick-bar HUD covers scenery near several targets, never a
  whole target.
- Old key reached frames (day 052, night 050) show the meadow after pickup;
  the prompt frames carry the evidence.
- Noisy dark foliage canopies (day 035, day 043, night 029).

VERDICT F01#2 (day): PASS
VERDICT F01#3 (night): PASS
