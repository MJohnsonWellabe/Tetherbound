# D34 — Build system v2: a Valheim-inspired panel, and its own input

**Date:** 2026-08-13 · **Decided by:** the owner, implementing the UI spec's
§12–§13.

## The decision

Build selection moves from wherever it currently lives in the pause menu
into an in-world panel carrying the warm `build_theme.tres` (`D28`), with
category tabs read from `buildables.json`'s existing `category` field
(`shelter`, `structure`, `utility` — present on every entry today and read
by nothing), a dense thumbnail grid (spec §12.3: 10×5 at 1080p), and a
resource strip showing owned/required per piece (spec §12.4). Placement
gains rotation, snap-point highlighting, and a local placement grid (spec
§13.2–§13.3) — all centred on the ghost, none of it a permanent floor grid.

New input actions, added to `project.godot`'s defaults the same way every
prior action has been (`D15`: defaults live there and are never written to
at runtime):

| action | keyboard/mouse | gamepad |
|---|---|---|
| `build_place` | LMB | X |
| `build_cancel` | RMB / Esc | B |
| `build_rotate_left/right` | mouse wheel | LT / RT |
| `build_snap_cycle` | Shift | d-pad down |

## Two deliberate deviations from spec §13.5, and why

The spec's own controller mapping (A place, bumpers rotate) does not fit
this project's existing bindings:

- **Place is X, not A.** `project.godot` already binds A to `jump`,
  `combat_quick` *and* `menu_confirm` (`D15` §3, one of the four deliberate
  default clashes). Placement happens during exploration, where A is jump —
  reusing it for `build_place` would place a structure on every jump.
- **Rotate is triggers (LT/RT), not bumpers.** The bumpers already carry
  `tool_cycle` (LB) and `combat_throw`/`backpack_drop` (RB); triggers were
  the only pad inputs `D15` left unclaimed, which is also why
  `build_snap_cycle` takes d-pad down. It is consumed contextually — inert
  unless a ghost is armed, the pattern `interact` already follows.

## This retires a double-read

`build_placer.gd::_physics_process` currently reads
`Input.is_action_just_pressed("interact")` directly to place a piece, while
`interaction_arbiter.gd` separately owns `interact` as "the one place
`interact` is read outside combat" (its own header comment). `build_place`
gives placement its own action; `build_placer.gd` stops touching `interact`.

## What changes on disk

- `scripts/build/build_panel.gd` — new. Category tabs from `buildables.json`'s
  `category` field, thumbnail grid, resource strip, `build_theme.tres`.
- `scripts/build/build_placer.gd` — ghost gains rotation state (`yaw_deg`),
  snap-point highlighting, and a local grid overlay (spec §13.3: 6–10m
  radius, 0.5m minor / 1.0m major spacing, conforms to the build plane,
  fades at the edge). Reads the five actions above in place of `interact`.
- `project.godot` — the five new actions, added as defaults per `D15`'s
  rules (documented, never rewritten at runtime). Already in place.
- Save format — placed buildings gain `yaw_deg` alongside `{id, position}`
  (`D27`), riding the v2 bump alongside `D30` and `D33`.

## What was deliberately not built

- **Structural-integrity simulation.** Spec §14's colours apply to
  *placement validity only*, via checks `build_placer.gd` already runs
  (slope, cost). No load-bearing simulation exists to visualize.
- **A rebuilt resource/crafting system.** The resource strip reads the same
  `build_cost_for` / `can_afford` gate `D14` already put in place.
- **New build categories.** `SURVIVAL` / `FARMING` / `TETHER` tabs stay
  unbuilt — `buildables.json` only populates three categories today, and
  the panel does not draw an empty tab (spec §12.2).

## What it supersedes

The pause-menu build tab's flow (`scripts/ui/tab_build.gd` arming
`GameState.pending_build`, unchanged) hands off to the new in-world panel
and placer rather than a flat catalogue list. `build_placer.gd`'s use of
`interact` is retired outright, resolving the double-read
`interaction_arbiter.gd`'s header names as the thing it exists to prevent.
