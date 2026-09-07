# N03-CREATURE-BODY

**Source:** W07-WARRENS-0904 (CL-G7), W12-COMPANION-0904 reports.

## Why
Two independent lanes each found a real bug in `scripts/creatures/creature_body.gd` and left
it because the file was outside their ownership. Both are precisely specified.

## Owns
`scripts/creatures/creature_body.gd` only.

## Do

**1. CL-G7 — dangling material RID on rebuild (W07), patch given verbatim.** In
`_build_model()` (around line 491 as of `f8a47ee4` — confirm by function name, not line
number), freeing a child `MeshInstance3D` without first clearing its per-body
`set_surface_override_material()` override leaves a dangling material RID, producing
`ERROR: Parameter "material" is null.` on every `apply_size_multiplier()` rebuild. This is the
known-benign error four lanes have seen and none has fixed (`docs/AGENT_WORKFLOW.md` §6 names
it). Fix: before `child.free()`, clear every surface override material to `null` on that child
(`child.set_surface_override_material(i, null)` for each surface index) so no dangling RID
survives the free.

**2. `play_rest()` has the same signed-roll bug W12 already fixed once in this file (W12).**
W12's report fixed a grounding bug in the camp/rest pose: rolling a body either way dips its
lower corner by about a radius, so the correct lift is `+radius * abs(sin(roll))` — written
signed (without the `abs()`), a negative roll turns the lift into a dip. W12 fixed this for one
call site (commit `5eaa4e07` on that lane's branch, now on `main`) but flagged that
`creature_body.gd::play_rest()` uses the same signed form for the creature-bed sleeping pose,
so any species with a negative `rest_roll_deg` (confirmed: terrapup and trailpup, both -45)
has the same latent dip when they sleep in a bed. Find the exact fix W12 applied (search
`git log -p` on `origin/main` for the `5eaa4e07`-equivalent commit, or grep for the sibling
lift calculation in this same file) and apply the identical `abs()` correction to
`play_rest()`.

## Verify
- For item 1: reproduce the null-material error first (run a smoke that rebuilds a creature
  body's size multiplier, e.g. an existing Warrens or companion smoke), confirm it's gone
  after the fix, and confirm the known-benign error *count* in `docs/AGENT_WORKFLOW.md` §6's
  distinct-error-set does not need updating elsewhere (it should simply stop appearing).
- For item 2: write a test that puts terrapup or trailpup into the bed-sleep pose and asserts
  the pivot height matches the un-rolled height ± the corrected lift (not the dip) — mirror
  whatever test W12 used to pin the original camp-pose fix (search for it in
  `tests/test_companion_presence.gd` or similar on `main`).
- Full `creature_body.gd`-adjacent smoke pass afterward (`smoke_companion`, `smoke_riding`,
  `smoke_warrens`, `smoke_combat`) to confirm no other pose regressed.

## Acceptance
Both fixes verified red-then-green. The known-benign `material is null` error stops appearing
in any smoke log that exercises a size-multiplier rebuild. No species with a negative
`rest_roll_deg` shows a ground-clipping or floating dip in its bed-sleep pose.
