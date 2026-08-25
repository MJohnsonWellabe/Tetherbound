# Handover — `ralph/CONSOLIDATION`, one blocker from landing

Written to be picked up cold. Branch: `ralph/CONSOLIDATION`, tip `bec4a355`,
216 commits ahead of `main` (`571d9e86`).

## What this branch is

Everything the visual programme produced, plus a night of fixes found while
trying to land it. `main` has not moved since OP23-FIXPACK.

Fully contained in it, verified by `git merge-base --is-ancestor`, not assumed:
`ralph/VISUAL-CORRIDOR` (which itself carries VIS-CAST, VIS-SITES,
STRONGHOLD-R2, VISUAL-GROUNDCOVER, VISUAL-LIGHT, CREATURE-IDENTITY-2,
CREATURE-PRESENTATION), plus `ralph/VIS-MAKE` and `ralph/VIS-UI`, which
VISUAL-CORRIDOR never consolidated.

Nothing of substance is outside it except the Gate F protocol doc (see
"Still owed"). `ralph/integration-W2` and `W3` are superseded — W3's unique
commits are already ancestors of `main`, and W2's only real content
(SITE-DRESSING's band 2/3/4 `props.json`, `props.gd`, the band-split fixture)
is already in the tree. Both are safe to delete.

## Where it stands

CI 2412 (`db326f3d`), by shard:

| shard | state |
|---|---|
| `verify-core-verb-shard` | green |
| `verify-regions-shard` | green |
| `verify-owner-regressions-shard` | green |
| `verify-gate-evidence-shard` | green |
| `verify-combat-shard` | green |
| `verify-unit-tests` (×4) | green |
| `verify-gate-a-ui-build-shard` | **RED — the one blocker** |
| `verify-continuous-core-known-red` | red, and does not block |

`verify-continuous-core-known-red` carries `continue-on-error: true`. It reports
red without failing the run, by design — its own comment in `ci.yml` says so, and
tells you to remove the flag when CONTINUOUS-CORE is fixed. It has been red on
runs that finished green and landed on main, including 2391 (the fog fix). Do not
read it as a verdict. I did, for hours.

## The one blocker: the village road gate seal fences in its own key

`road_gate.gd` gained an opt-in `seal_half_width` this session, because the
owner ruled (2026-08-25) that "gates have to be physically sealed — there needs
to actually be something keeping a player from walking around it". It builds
wing panels from the same prefab as the leaf, out to the given half-width.

That is right for the **Sigil Gate**, which sets 16.0m: its wings terminate in
the flanking gorges, so the barrier ends where the ground does. `smoke_traversal`
now reports the locked gate stopping the player at every offset probed, where it
used to walk past at 22.9m.

It is the wrong shape of fix for the **village road gate**, which stands in open
meadow with no terminator. At `seal_half_width` 12.0 the wings enclose
`GATE_KEY_AT` (24,-10) — 6.8m along the gate's own fence line, and the wing at
local x -8.13 builds at world (24.85,-8.31), about 2m from the key. The player
cannot get inside the key's prompt radius, so nothing actionable is offered and
the ambient "Put Bud away" line (distance 0.0, priority -1, actionable false) is
all that is on screen. `smoke_opening` then fails with "the arbiter picked
something else", which reads as an arbiter bug and is nothing of the kind.

Widening does not help: 12 -> 20 was tried and encloses more. Reverted to 12.

`tools/_probe_road_gate.gd` prints every collision box the gate builds, with
local offsets and widths, so this is measured rather than argued about.

**What it needs:** authored flanking, not a programmatic fence. Fence running to
`cottage_b` (21,-14) on one side and to `village.json`'s existing `fence_run` at
(19.5,-25.5) on the other — which is what `road_gate.gd`'s own header has always
claimed is there ("stands in a fence line that already runs off both its ends").
It does not. That is content work needing eyes on it; picking another constant
is how the fence ended up around the key.

Until then the honest options are (a) author the flanking, or (b) set the village
gate's `seal_half_width` back to 0.0, accept that a sliding player can walk round
it, file it, and relax `smoke_opening`'s crossing assertion to match. (b) leaves
a gate that does not gate, which the owner ruling explicitly rejects.

## The pattern worth carrying forward

Six defects this session shared one shape: **a budget or a bounded search that
could never succeed, filed as an intermittent flake because whether you REACH it
is what varies.** None was flaky.

- `_wait_for_the_bramblebun_back_on_its_feet()` waited 900 physics frames = 15
  simulated seconds, for a respawn that `spawns.json` sets at 45.0. It could
  never once have succeeded.
- The tournament harness computed attack reach as a constant 3.6m while
  `combat_manager.gd::_with_reach_for_the_bodies` grows the player's reach with
  the bodies in the fight. VIS-MAKE's `body_clearance` 1.8 -> 2.75 (correct, it
  stopped creatures embedding in each other) pushed the standoff past 3.6m, and
  the harness stood there with a ready attack refusing to throw it.
- `player_quick.lunge` is 3.6: the attack CARRIES the fighter forward, so at a
  standoff a ready swing is how you close. The harness saved the one move that
  would break the deadlock until after the deadlock broke.
- `_close_in_until_offered()` sidestepped `"move_right" if attempt % 2 == 0 else
  "move_left"` — alternating every attempt, net displacement ~zero, forty times.
- `_arbiter_offers()` demanded the winning provider BE the creature node, but the
  wild engage line is published by `encounter_director.gd`. It rejected the offer
  it was waiting for.
- `smoke_opening`'s gate check measured proximity to a point 15m along the
  player-to-gate ray, which on an oblique approach runs parallel to the fence.

When a test reports something the game plainly does, suspect the harness's model
of the game before the game.

## What I got wrong, so nobody re-derives it

- **"The un-aimable tutorial catch is the terrain rebuild."** Wrong. The bisect
  was confounded: reverting terrain forced a scatter RE-BAKE, and the re-bake is
  what fixed it. The cause was scatter density — a bush blocking the aim ray.
  STRONGHOLD-R2's stronghold approach road was dropped on this bad reading and
  has since been restored.
- **"The wedge is the terrain."** Wrong. `tools/_probe_wedge.gd` measures a
  smooth 6-degree slope with `Rock_Medium_3` 1.29m away. It is a boulder.
- **"Move the scatter to fix the wedge."** Tried. One wedge became two, at a new
  location. Re-siting relocates pockets, it does not remove them.
- **"The gates were fine before."** They were not. Both were only ever gating a
  player who walked straight at them. Sliding exposed that; it did not cause it.

## Other things this branch changes

- **Density (the ROG Ally lever).** `vegetation.json`'s carpet layers halved:
  grass 2.8 -> 1.4, drygrass 2.0 -> 1.0, flowers 1.5 -> 0.8, which its own
  GROUND-LAYERS comment argues for ("the meadow needs NEGATIVE SPACE... the
  honest first thing to give back if the ROG Ally needs headroom"). Rock clumps
  36 -> 12 per clump: `Rock_Medium_*` are 3.0-3.5m across, so 36 inside
  `clump_radius` 11.0 is a maze, not scatter. Measured: 801,026 -> 466,922
  placements, bake 371s -> 233s. **Not verified on device.**
- **Sliding (OF15).** `player_controller.gd::_unwedge` deflects along an obstacle
  after 0.2s of no progress while pushing. Horizontal only, one
  `move_and_slide()` per frame, lapses when the player asks for a different
  direction, and refuses to steer anywhere without ground under it
  (`_ground_under`, added after it walked the player off a ledge in the warrens
  and CI reported them "2669.9m" from the vault — that is world spawn).

## Landing mechanics, learned the hard way

- `ralph-sweep.yml` **rebases** branches onto main and hits content conflicts. A
  plain `git merge origin/main` does not. This cost about twelve hours before
  anyone noticed.
- The sweep is fast-forward-only to main, so a branch must not be behind.
- Always `godot --headless --import` after a merge or a bake; the import cache
  goes stale and the failure looks like anything but that.

## Still owed

1. **The village gate flanking** — the blocker above.
2. **`GATE_F_AUTHORITATIVE_PLAYTEST_AND_BACKLOG_REGENERATION.md`** — the owner
   uploaded it 2026-08-24 with instructions to add it to the repo once
   everything is on main and point the Gate F coordinator at it. It is committed
   nowhere; `git log --all` finds nothing. It is docs-only and lands in minutes.
3. **Delete `ralph/integration-W2` and `W3`** — superseded, evidence above.
4. **The density numbers on real hardware.** The owner's report was "freezes
   every few feet"; OP23-01 (the map-fog repaint, on main) was the cause of that
   one, and this density cut is the next lever. Nobody has run either on an Ally.

## Verifying this branch yourself

    godot --headless --import --path .
    godot --headless --path . --script tests/smoke_traversal.gd     # wedge, both gates
    godot --headless --path . --script tests/smoke_opening.gd       # THE BLOCKER
    godot --headless --path . --script tests/smoke_gate_a_opening_segment.gd
    godot --headless --path . --script tests/smoke_tournament_bracket.gd
    godot --headless --path . --script tests/smoke_party_count_after_catches.gd
    godot --headless --path . --script tools/_probe_road_gate.gd    # what the seal builds
    godot --headless --path . --script tools/_probe_wedge.gd        # terrain + scatter at a spot

All pass on this box except `smoke_opening`, which fails at the key the seal
encloses.
