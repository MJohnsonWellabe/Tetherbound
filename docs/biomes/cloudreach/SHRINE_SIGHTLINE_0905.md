# High Roost interaction sight line — 2026-09-05

Fixed a real shared interaction defect exposed by the continuous Cloudreach
route: rays toward low shrine prompts could hit the viewing player's own capsule
after endpoint trimming. The west-vane reproduction had the player at
`(1098.98,1051.301,2938.479)` and prompt at `(1099,1050.8,2940)`; the first
collision was the player itself, not a wall or a competing wild creature.

`Interactable._has_line_of_sight` now excludes only the interaction arbiter's
actual querying collision body when its position matches the supplied origin.
The same rule covers a piloted creature. Areas remain excluded as before;
other actors, walls, floors, range and endpoint trimming are unchanged.
Invalid/off-tree viewers are not dereferenced.

## Evidence

- Expanded `tests/smoke_interactable_sightline.gd` with an actual raised capsule
  and low prompt. Before the fix, precisely the two new positive controls failed.
  Afterward, exit 0: own capsule permits the offer, a real wall still blocks it,
  removing the wall restores it, and an unrelated body still blocks it. Existing
  open-ground, wall, loft-floor, own-body and 40m distance controls also pass.
  Logs: `ralph/reports/CLOUDREACH-CONTINUOUS-0905/sightline-before.log`,
  `sightline-after.log`, and final off-tree-guard rerun `sightline-final.log`.
- Production `tests/smoke_cloudreach_shrine_services.gd` passes with the original
  approach offsets: actual controller input activates all three vanes, completes
  Sora's `cloudreach_sora_storm_engine_truth` dialogue and its production effect,
  and operates the windlass to unlock the upper route. `shrine-services4.log`
  ends PASS, exit 0, without engine/script errors.
- This isolated fixture explicitly seeds the previously earned Act I/Fly
  preconditions. Earlier fixture runs omitted Act I and could not apply Sora's
  effect; that was corrected in the test, not bypassed in production dialogue.
  This is not itself an uninterrupted chapter proof. The clean continuous
  replay starts from its original Meadows-completed fixture without Cloudreach
  unlock seeding.

No interaction radius, quest requirement, shrine transform or floor was changed.
