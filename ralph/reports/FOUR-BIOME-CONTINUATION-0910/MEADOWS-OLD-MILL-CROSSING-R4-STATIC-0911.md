# Meadows named location — Old Mill Crossing R4 static candidate (2026-09-11)

## Disposition

**STATIC CANDIDATE; production visual proof pending.** R3 solved the measured
south-road tree obstruction and added two installed night practicals, but its new
readable water wheel stood about eighteen metres from the mill, on the opposite
side of the bridge. The strongest silhouette was therefore not a believable mill
mechanism. This candidate moves that same visual-only wheel onto the installed
mill prefab's authored west-wall axle.

## Bounded change

- Parents `OldMillWaterWheel` to `Mill` at local `(-4.25, 2.10, 0)`, aligned to
  the prefab's existing wheel plane and collider.
- Keeps the same radius, ten paddles, timber palette, and visual-only/no-collision
  contract. Bridge, gate, road, river, terrain, interactions, progression,
  encounters, gatherables, props and canonical scatter are untouched.
- Deepens the existing practical colour from pale cream `#ffad55` to amber
  `#ff8f32` without changing light count, range, energy, collision or placement.
- Keeps R3's four matched route views. An attempted side-bank view landed inside
  dense foliage and was removed from the authoritative harness rather than being
  counted as evidence. The output directory advances to R4 so prior evidence
  cannot be overwritten.

## Exact scope and overlap

- `scripts/world/mill_crossing.gd`
- `tests/test_old_mill_crossing_visual_identity.gd`
- `tools/capture_old_mill_crossing_identity.gd`
- this report

All four paths were clean before editing. None overlaps the active Inn or
Stonewater files, the already-committed Highfield/Ranger/Stronghold paths, Band 3
vegetation/props/spawns, or generated scatter.

## Acceptance still required

- Focused identity suite passed first-attempt on this candidate: **5 tests / 53
  assertions / 0 failed**.
- Godot 4.7 `--check-only` passed independently for the production script,
  focused test and R4 capture harness (exit `0,0,0`).
- A real Compatibility-renderer R4 run must produce 8/8 valid frames with the
  production scene and authoritative scatter.
- Independent review must confirm the attached wheel remains readable from the
  south route, touches a believable water edge, avoids the bridge walking line,
  and does not compound the retained tree or Galecrest silhouettes.

Until those receipts exist, Old Mill Crossing remains **POLISH**, not hard PASS.
