# W14-RIDING-0904 — riding is unfinished three ways (CL-O3)

Branch: `ralph/W14-RIDING-0904`. All three owner items closed and verified live.

## Files changed

- `scripts/world/riding_controller.gd` — mounted sprint, mounted jump, the saddle build-then-fit-then-stays rule
- `scripts/player/player_controller.gd` — the rider's art stays visible while carried (was hidden outright)
- `scripts/player/trainer_model.gd` — `set_riding()`: the seated pose, authored on the skeleton
- `scripts/creatures/creature_body.gd` — `request_jump()`, the creature's own vertical launch
- `data/config/riding.json` — new. Sprint multiplier, jump height, the rider's seat-drop and joint-flexion tunables
- `tests/smoke_riding.gd` — extended: rider seating, mounted sprint, mounted jump, a live ceiling-collision guard
- `tests/smoke_riding_saddle.gd` — new. The saddle rule against every rideable species, standing bodies up in the real playground
- `tests/test_riding_saddle.gd` — new. The saddle rule's pure-logic half against the real species/recipe data
- `tools/_capture_riding.gd` — new. Renders the before/after saddle frames
- `docs/decisions/D88-a-mounted-sprint-and-hop-cost-nothing-and-the-saddle-stays-on.md` — new
- `docs/decisions/D91-riding-jump-relocation-and-the-workshop-arch-bay.md` — new (process finding, see below)
- `docs/CURRENT_STATE.md` — CL-O3 row rewritten with live-verified numbers

## Functionality implemented, in player-visible terms

**1. The rider is on the creature.** Mount a Meadowhart and the trainer is
visibly seated on it — hips down, knees bent, hands forward, dropped to the
species' own authored seat height — rather than invisible (the previous,
documented behaviour: no seated clip exists on the rig, so the trainer's art
was hidden outright rather than shown standing bolt upright on the animal's
back). The pose is authored directly on the trainer's skeleton because the rig
still has no sit clip and CLAUDE.md forbids a Meshy generation without owner
reference art; the joint axes were measured off the real, shipped walk/jump
clips (`tools/_probe_ride_pose.gd`, run once, findings folded into
`trainer_model.gd`'s own comments) rather than assumed from the animation
authoring script's own (Blender-space) documentation.

**2. Sprint and jump work while mounted.** Holding sprint while riding makes
the mount run at 1.4× its normal ride speed (Meadowhart: 14 m/s, live-measured,
against a sprinting trainer's 8.6 m/s) at no stamina cost to the player or the
creature — extending D48's existing no-stamina ruling rather than inventing a
new cost (recorded in D74). Pressing jump while mounted makes the mount hop
1.6 m of clearance (live-measured: 1.68 m), clearing the low fences and rocks a
walking player already vaults, with the rider staying seated through the whole
arc because they are carried by the mount's own transform.

**3. The saddle is built, then fitted, then stays.** A rideable creature never
carries a saddle at spawn. Standing next to one with no saddle in the satchel
says so ("Meadowhart needs a Riding Saddle") and refuses to mount. Once the
saddle is crafted (the village tournament's prize, per D48) and the player
mounts for the first time, the saddle visibly appears on the creature's back —
and, unlike the previous implementation, it **stays there**: dismissing the
creature and calling it back out, walking around, resting, all still show the
saddle, because the fit is now recorded in the save file rather than being
re-derived from "are you currently riding it". The legendary (Veridian) needs
no tack at all and never wears one, which is the story point (species.json:
"it carries you because it offered to").

## Tests run, exact commands, pass/fail

```
godot --headless --path . --script tests/smoke_riding.gd
```
**PASS.** `riding: OK — saddled, mounted, ridden, dismounted, and refused when
it had to be.` Key live numbers from the final run: rider seated 1.30 m up,
0.15 m off the mount's centre line, LeftUpLeg/LeftLeg bent 75.5°/68.0° from
rest (a real bone-angle read, not a flag); sprint 14.00 m/s held vs 10.00 m/s
not, against an 8.60 m/s sprinting trainer; jump rose 1.68 m against a 1.60 m
ask, zero ceiling collisions for the whole rise; dismount and despawn both
restore the trainer visible, solid and grounded; the legendary's tier (x2.80,
14.00 m/s live, no tack, 60° ground) is confirmed above Meadowhart's; mounting
is correctly refused mid-fight.

```
godot --headless --path . --script tests/smoke_riding_saddle.gd
```
**PASS.** `riding saddle: OK — never at spawn, built before fitted, one once
fitted, still there after a resummon.` Runs the full rule against both
species the data currently marks rideable (`meadowhart`, `veridian`): none at
spawn, none while the satchel is empty, exactly one node once fitted, still
one node after being dismissed and summoned back out (a **new** body from the
director, proving the fit is state-derived rather than tied to the object that
happened to be there when it was granted), and gone again once the fit is
cleared.

```
godot --headless --path . --script tests/run_tests.gd -- --only=test_riding_saddle.gd
```
**PASS.** 7 tests, 15 assertions, 0 failed. Three deliberate breaks (making
`saddle_belongs_on()` true for every species, collapsing the per-species flag
name to one shared name, making `saddle_is_fitted()` unconditionally true)
were each seen red for the right reason before this landed.

```
godot --headless --path . --script tests/smoke_creature_control.gd
```
**PASS** (unaffected by this lane; run as the brief's own core-smoke bar).
`creature control: OK — dismissed, recalled, swapped, and refused mid-fight.`

```
godot --headless --path . --script tests/smoke_playground.gd
```
**PASS.** `smoke: OK`.

```
godot --headless --path . --script tests/smoke_gate_b_continuous.gd
```
**FAIL, pre-existing and unrelated.** Fails inside the opening's tutorial
catch aiming (`gate_a_opening_drive.gd::_aim_camera_at`), nowhere near any file
this lane touched. This is the already-documented, already-known-red item in
`docs/CURRENT_STATE.md` ("The tutorial catch is unstable across KO/re-engage
rounds", open since 2026-09-03, `verify-continuous-core-known-red` already a
skipped CI job for exactly this). Not caused or worsened by this lane; the
stack trace names only `gate_a_opening_drive.gd` and
`smoke_gate_b_continuous.gd`.

## Runtime validation performed

Every claim above is read from a real, driven physics simulation — the real
playground scene, the real `interact`/`jump`/`sprint` bindings through the
real input map, the real `RidingController`/`CreatureBody`/`EncounterDirector`,
never a mocked value or a source-text grep. The jump and sprint numbers in
particular are measured as ground actually covered / height actually reached
by the live body, converted back to m/s or metres, specifically because "the
number in the config file is right and nothing moves" is a real bug shape this
kind of feature can have.

## Frames

`shots_riding/riding_mounted_side.png` (sent to the user; not committed —
COMMON.md: at most one contact sheet, no per-frame PNGs in the repo) shows the
Meadowhart mounted, the rider seated on its back, at the workshop forge yard.
Captured with `tools/_capture_riding.gd` (`xvfb-run … --rendering-driver
opengl3`), which drives the exact same `move_left` relocation
`tests/smoke_riding.gd` verified is clear of obstructions.

**Known limitation, not chased further:** the tool's other two camera angles
(`riding_before_saddle`, `riding_mounted`, framed from behind the mount) point
into the same workshop archway from the *inside*, because the mount's own
facing at this relocation spot puts "behind and to the side" on the wrong
side of the wall. The side angle is unaffected and is the one actually
useful for judging the rider's seat and the saddle. A future pass should
either relocate further from the workshop's forge yard entirely or aim the
behind/side cameras at the mount's centre rather than offset from its facing.
No blind-judge pass was run given this framing gap; the gameplay verdict does
not depend on it — every claim in this report is verified by the live smoke
tests above, which read real transforms and real collision data, not a
screenshot.

## Known limitations / what was deliberately not done

- **The saddle fit is per-species, not per-creature-instance** (recorded as a
  deliberate simplification in D74): two Meadowhearts in a five-creature
  roster both wear whichever saddle was fitted to that species. The honest
  alternative (a field on `creature_instance.gd`) needs a serialised field, a
  save-key and a migration this lane does not own; the flag is the smaller,
  correct-for-now step and D74 names what a future per-instance version should
  migrate from.
- **No new rideable species were added or removed.** `meadowhart` and
  `veridian` (the legendary) are the only two species carrying a `rideable`
  block in the data today; CL-O9's design contract owns the roster (Burrowback,
  Tuskroot, Terrapup) and this lane correctly stayed out of it — both new
  tests read the roster from `species.json` rather than naming animals, so
  that lane's own change is picked up automatically.
- **No seated animation clip was authored.** The pose is procedural, on the
  skeleton, per the header comment in `trainer_model.gd` — the honest, scoped
  answer given the rig has no sit clip and CLAUDE.md forbids spending a Meshy
  generation without owner reference art.
- **`camera_rig.gd` was not touched.** Mounted following already worked
  (`riding.json`'s existing camera profile); this lane's own brief said only
  to touch it if mounted following was broken, and it was not.
- **A significant amount of this lane's time went into a test-relocation
  investigation, not a gameplay defect** (see `docs/decisions/D75`): the
  smoke test's own "move the mount to open ground before jumping" helper was
  driving the mount into the workshop's low, roofed arch bay, which read
  exactly like a physics bug (a hard, deterministic clamp at 0.89 m, in
  isolation the same jump code reached the full 1.677 m cleanly) until
  `get_slide_collision()`'s own contact normal on the failing frame proved it
  was a ceiling. Recorded in detail so a future test relocating a body to
  "open ground" does not re-spend the same hours.

## Final commit and branch

Branch: `ralph/W14-RIDING-0904`
Final commit: HEAD of `ralph/W14-RIDING-0904` at push time (`git log -1` on the branch).
