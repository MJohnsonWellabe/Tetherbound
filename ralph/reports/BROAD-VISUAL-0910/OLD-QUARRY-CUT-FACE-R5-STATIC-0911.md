# The Old Quarry cut-face R5 — static candidate

## Outcome

**Static candidate; expected disposition remains POLISH pending production proof.**
R4 retained the extraction wagon but its production report explicitly found that the
wide arrival still read as low quarry dressing in a forest clearing. R5 targets that
single remaining hierarchy problem with an installed-rock cut face rather than scaling
the ordinary wagon again or changing shared terrain and vegetation.

## Bounded composition change

One Band 2 `old_quarry_cut_face` prop cluster adds three overlapping mid-height masses
and three smaller descending spoil pieces on the west shoulder of the worked floor.
All six use the existing `Rock_Medium_1/2/3` models from the established Meadows nature
family. The large pieces are scale `1.95..2.15`, producing roughly 4–5 m irregular
crowns from source bounds; the spoil bench steps down at scale `0.58..0.72` toward the
retained wagon, crates, foundations, Rootstone and conduit head.

The centres form a diagonal from `(377,1810)` to `(390,1802)`. Every centre lies inside
the union of the existing quarry clearing `(400,1800) r17` and final-approach clearing
`(387,1813) r12`. No vegetation edit or scatter bake is required. The three large masses
remain at least 10.8 m from the nearest live Band 2 spine segment; their installed
horizontal half-extents leave over 7 m beyond the rock body to the road centreline. The site adds no interaction, harvest amount,
encounter move, faction explanation, or light.

## Evidence contract

`tools/capture_old_quarry_visual_identity.gd` now writes only to
`OLD-QUARRY-CUT-FACE-R5`. Its established arrival, worked-floor, and conduit-head
day/night pairs remain, and a fourth reverse-shoulder pair directly tests whether the
new mass reads as one excavated wall behind the work gear without closing the route.
No production renderer was started for this lane.

A fresh eight-frame production receipt must establish silhouette, grounding, route
clearance, and night readability before retention. Even if successful, the honest
expected result is a stronger POLISH location; HARD PASS requires the arrival frame to
show the cut face, extraction gear, Rootstone and live conduit as one unmistakable
commercial composition without the new rocks reading as a generic boulder pile.

## Focused validation

- `test_old_quarry_visual_identity.gd`: 5 tests, 89 assertions, zero failures.
- `capture_old_quarry_visual_identity.gd`: Godot `--check-only`, exit 0.
- Band 2 `props.json`: PowerShell JSON parse successful.
- Owned diff: `git diff --check`, no whitespace errors.
