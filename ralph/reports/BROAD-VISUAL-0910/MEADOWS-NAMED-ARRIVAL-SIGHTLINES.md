# Meadows named-arrival sightlines — 2026-09-10

## Result

The Settings/debug catalogue arrivals for the Burrow Warrens and Stronghold
Approach now use authored approach ground and explicit view headings. Both
previously invalid day/night views are readable in the production camera. No
world art, creature, pylon, collision, traversal route, encounter, or
progression state was removed or moved.

- **Burrow Warrens:** arrival moved from the cave-mouth centre
  `(-357, 2610)` to the already-authored exterior approach
  `(-328.7, 2581.7)`, 40 m in front of the mouth. The view faces -45 degrees,
  along the cave's 315-degree depth axis. The full mound, entrance, threshold
  apron, approach road, and trainer-scale foreground are visible; the nearby
  Burrowback and cave wall no longer collapse the camera.
- **Stronghold Approach:** arrival moved from the first pylon's exact centre
  `(-40, 7010)` to the approach config's own road entry `(0, 7000)`. The view
  faces north along the pylon run. The road, offset machinery line, creatures,
  and distant Hall silhouette are visible together; the first pylon no longer
  occupies the camera.

The optional `view_heading_deg` field is carried through the real Settings row
and `Game.debug_teleport_to`. It applies a one-shot trainer/camera arrival pose
and then returns control to ordinary camera input and movement. Catalogue
captures read the same field, so audit evidence and the player-facing Settings
destination do not disagree.

## Production capture evidence

Fresh evidence is under
`shots/catalogue/meadows/arrival-sightline-0910/` (ignored runtime evidence,
not committed binaries). The production Compatibility renderer captured six
day/night frames at 1280x800 with the ordinary HUD; the manifest reports
`complete=true`, 6/6 frames, and no failures. The requested subset also matched
the Band 5 id and therefore truthfully recaptured Meadows Hall alongside the
four target frames.

For both target locations and both clock states, the production spring arm
remained at its full 5.2 m length. Warrens settled at terrain ground without a
built-floor override and recorded view heading `(-0.7071, 0.7071)`.
Stronghold Approach likewise settled at terrain ground and recorded heading
`(0, 1)`. Direct inspection of all four target PNGs confirms neither frame is
occluded.

## Focused verification

`tests/test_four_biome_debug_teleport.gd`: **7 tests, 0 failed**. The new test
pins both safe coordinates, their measured clearance from the invalid centres,
and their headings. The existing Settings callback test now also proves every
row preserves its optional authored heading through the production call seam.
