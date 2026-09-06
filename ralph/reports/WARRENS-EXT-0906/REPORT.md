# WARRENS-EXT-0906 — Burrow Warrens exterior, rounds 4–6

Branch `claude/warrens-exterior-0906` (from `claude/second-biome-completion-n1deay`).
Owner evidence: `docs/owner/OWNER_PLAYTEST_2026-09-05.md` OP-0905-09 and the
2026-09-06 addendum ("the warrens still need work, particularly the entrance from
the outside and how the mounds read externally"). Rounds 1–3 were done before this
lane; this report covers rounds 4, 5 and 6 and the trajectory of all six verdicts.

## What the exterior is now, in plain words

A grassy earth bank about 18 m tall standing in the meadow, with a crowned main dome
behind the entrance and five smaller dig-heaps around it (two flanking the mouth, one
over the warren chamber, one over the vault, one behind the den) plus a shoulder heap,
so the skyline seen from the approach has three peaks rather than one ridge. The
settled slopes read as grass; the dug face beside the opening (about 6 m tall, 46
degrees), each heap's throw side, the fans below every warren hole and the threshold
in front of the mouth are raw, darker earth with no growth on them. The bank mesh ends
where its own height ends instead of laying a pale earth sheet over the surrounding
meadow. Seven rock outcrops sit tilted in soil skirts with grass on their crowns;
eight head-high spoil boulders cluster on the down-slope side of the mouth and holes,
half buried, each in its own soil cone; the crest trees stand in root mounds.

The mouth is an 8 m earth throat with a worn, lumpy earth brow around its outer ring,
short turf along the brow's crown, five bark roots hanging into the opening (tips
above 2.3 m), a warm amber light 2.4 m inside so the hole reads as depth, a mounded,
ragged-edged trodden threshold fan spilling 8 m out onto the road, claw scrapes and
rubble, and a lit Team Tether lamp post with an oxblood collar standing at the
threshold as the 2.6 m scale reference. The red tree beside the mouth is green. The
den guardian stands at 3.57 m with its head raised and faces the player who enters.

## Trajectory of the six blind verdicts

| Round | Verdict in one line |
|---|---|
| 1 | No bank at all; a flat slab with a hole, a metal-framed doorway in a field. |
| 2 | A mound, but a ribbed primitive; a paved-looking threshold; the red tree steals focus; the guardian small. |
| 3 | Mouth closer; the bank still one smooth ridge with rocks glued on; a black cutout mouth; the red tree still steals focus; the guardian curled and small. |
| 4 | The mound is a landmark from 60 m (a cone crowned with trees); the arch reads as smooth clay; the mouth unlit at the threshold; boxy rocks with flat moss tops; the cable across the walkway; ferns jungle-sized; the guardian under size and flank-on. The red tree is gone. |
| 5 | Scale passes (arch 3–4 m against the 2.6 m post; guardian a touch under its 3.4 m door); the entrance still stacks unrelated materials (earth tubes, brown boulders, tropical ferns, a grey stone doorway visible inside); the throat glow painted the dome instead of the hole; pancake spoil mounds; the lamp unlit and faction-less; trunks and boulders without ground contact; the threshold a flat plane with a straight edge; the meadow ground pale and the mound near-black; the guardian rump-first. |
| 6 | See `JUDGE-round6.md` (filled in below). |

Both bar questions were "no" in every round so far, with the exterior moving from
"no landmark" to "a landmark that does not yet read as dug earth" and the remaining
"no" resting mostly on things outside this lane (below).

## Root causes found and fixed this lane

- **The red tree.** Not the vegetation retint. `tools/_probe_cherry_materials.gd`
  prints CherryBlossom_3's imported surface materials: `Bark_NormalTree` and
  `Leaves_CherryBlossom`, and the second matches both the `grove` layer's `retint`
  and `retexture` keys exactly — the vegetation.json entries work as written (which
  is also why the round-3 hero clear removed the cherry hero and the red tree stayed).
  The red tree is the bank's own `TwistedTree_3` crest tree, hand-placed by
  `_build_bank_crest_trees()` on the mouth's left shoulder, wearing the pack's
  crimson `Leaves_TwistedTree` texture, which nothing ever retextured. Crest trees now
  go through the same `_dress_skirt_flora()` leaf swap the site's bushes already use;
  `LEAF_GREEN` now points at the meadow's own desaturated bake so the site and the
  field share one green. vegetation.json was not touched. Verified in the round-4
  render: no red tree in any exterior frame.
- **The "pale flagstone" threshold.** Two things. The bank grid drew its whole
  60×80 m rectangle, coplanar with the terrain, and the shader's crest-fraction band
  painted everything that low as earth: a pale sheet around the mound. Grade-level
  quads are now skipped, the noise term fades with bank height, and the height band is
  off (`height_blend_on` 0). The remaining pale strip in front of the mouth is the
  terrain's own baked dirt-path road arriving at the threshold
  (`tools/_probe_warrens_threshold_render.gd`, marker spheres at `ground_height_at`
  sit on the rendered ground; the strip is where that road is). Out of this lane.
- **One smooth ridge.** Five chamber cones plus a uniform `crest_boost_m` drew a
  55 m plateau at 10–12 m with one crown. The fixture now prints the skyline profile
  (max over z per x) and counts maxima with ≥1 m prominence: before, 1; now 3
  (x=−21 15.6 m, x=0 18.1 m, x=+19 14.6 m).
- **A walk-up slope, not a face.** The crown bump was added after the face carve
  and reached 11 m out in front of the doorway uncarved; the earth beside the opening
  measured 22 degrees. The crown is now carved with the rest; measured 46 degrees
  outside the corridor (fixture readout).
- **The buried lamp.** `lamp_forward_m` 1.2 stood the post 1.2 m outside the
  dome-face doorway, a point inside the 60-degree face once the throat ran 8 m. It
  now stands at the threshold on the bank surface.
- **The dark bank.** Crop medians: meadow ground (112,125,102), bank (40,44,35),
  unchanged by a grass brightness change because the dome's slopes sat above the
  32-degree earth threshold everywhere. The slope band moved to 42/58 and the
  remaining earth is lifted 1.5×. Measured again after round 6 below.
- **The guardian's posture.** The burrowback rig has six clips (idle, walk, run,
  attack, hit, faint; `tools/_probe_burrowback_clips.gd`) and no alert idle. A
  per-body `SkeletonModifier3D` pitches neck/head/spine up on top of the idle (sign
  measured with `tools/_probe_burrowback_pose_sign.gd`: −30° on `neck` raises the
  head 0.10 m) and blends out whenever the creature has an opponent, so no combat
  clip changes. Facing in the frame: the creature's own watch-the-player idle now sees
  the capture's hidden player at the camera, which is what a player entering the den
  gets.

## Tests run

- `tests/smoke_warrens_fixture.gd` after every change: `WARRENS FIXTURE OK`, with the
  new readouts (skyline maxima 3; face 46°; spoil mask threshold 1.00 / crest 0.00 /
  all heaps raw; capsule channel clear; crest 18.1 m).
- `tests/smoke_warrens.gd` rounds 4, 5 and 6: `warrens smoke test passed`, zero
  `ERROR:` lines each run (round-6 line recorded below).
- `tests/smoke_playground.gd` once after the crest-tree fix: `smoke: OK`; distinct
  ERROR set: `ERROR: Parameter "material" is null.` only (the known alpha-resize line).
- Renders: `xvfb-run … tools/capture_warrens_63.gd`, eight frames per round; the
  only `ERROR:` in the render logs is the box's missing ALSA device
  (`Condition "status < 0" is true. Returning: ERR_CANT_OPEN`, audio driver).

## Distinct ERROR set across the lane

- `ERROR: Parameter "material" is null.` (smoke_playground, known, alpha resize)
- `ERROR: Condition "status < 0" is true. Returning: ERR_CANT_OPEN` (render logs
  only, ALSA audio on a headless box)

## What remains, and why

- **The meadow ground's value and density** (pale grey-green, lighter than the sky,
  sparse blades) is named in rounds 4 and 5 as the biggest palette gap. It is the
  terrain/grass-field palette, Meadows-wide, not this dungeon's.
- **Grey masonry visible through the mouth** (the mouth chamber's straight jambs
  and lintel, and a bright patch at the corridor's far end): chambers, passages and
  lights were out of bounds for this lane. An earth-clad first bay would need the
  chamber wall material to change.
- **The interior** (rectangular rooms, beams, mushrooms, generic loot props, the
  badger's art style beside the guardian): not exterior work; the judge's own split
  puts the room geometry and the creature/world style match under "needs art".
- **Foreground focus stealers at 60 m** (orange dry grass, red trunks, the shrub
  repeat): band scatter of the surrounding meadow.
- **The arch's material continuity.** Rounds 4–5 still read the brow as a smooth
  clay tube against faceted boulders. Round 6 removes the pancake mounds and the
  ferns, tilts and skirts the rocks, and lights the hole; whether the tube-brow itself
  passes is the round-6 verdict's call. If not, the next move is a brow built as part
  of the bank height field (a raised lip in the grid) rather than a swept tube, which
  this lane did not attempt.
