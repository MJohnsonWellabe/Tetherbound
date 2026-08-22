# D35 — Default controls align to Palworld's conventions

> Vocabulary note: written when the game called its creatures "pals"; R1.1 (2026-08-14) renamed the term to "creature" throughout the codebase without rewriting this historical record.
**Date:** 2026-08-13 · **Decided by:** the owner directive recorded this
session: align Tetherbound's DEFAULT bindings with Palworld's, "so a Palworld
player's hands land right," without breaking this project's existing
contextual bindings.

> **Amended by `D68` (2026-08-22).** The RT/LT attack defaults below survive
> intact. What is gone is the wider "these triggers are safe because their
> other readers are context-exclusive" argument as it applied to `torch_place`:
> the authored controller map took the pad binding off the torch entirely, so
> LT and RT are the creature's two attacks and build-mode rotation, and nothing
> else.

## The decision

`project.godot`'s default gamepad bindings for the two combat attack verbs
move onto the triggers, matching Palworld's RT-attack / LT-aim:

| Action | Before | After | Palworld equivalent |
| --- | --- | --- | --- |
| `combat_quick` | LMB / pad **A** (button 0) | LMB / **RT** (axis 5 +) | LMB / RT attack |
| `combat_charged` | RMB / pad **X** (button 2) | RMB / **LT** (axis 4 +) | RMB / LT aim |

Everything else already matched, was left alone by deliberate choice, or was
judged not worth the diff. See the table below.

## Full before/after table

| Action | Keyboard | Pad before | Pad after | Notes |
| --- | --- | --- | --- | --- |
| Move (WASD) | unchanged | — | — | already Palworld |
| `jump` | Space | A | A | already Palworld |
| `sprint` | Shift | L3 (button 7) | L3 | already Palworld |
| `combat_quick` | LMB | A (button 0) | **RT (axis 5 +)** | changed — see above |
| `combat_charged` | RMB | X (button 2) | **LT (axis 4 +)** | changed — see above |
| `combat_throw` | F | RB (button 10) | F / RB, unchanged | Palworld's throw is Q/RB; keyboard kept at F. See "Q, considered and declined" below |
| `pal_recall` | R | D-pad up | R / D-pad up, unchanged | Palworld's summon is E/LB; both are contended here. See "E and LB, considered and declined" below |
| `tool_cycle` | Q | LB | Q / LB, unchanged | not a Palworld action; kept as-is so `combat_throw` could stay put too |
| `hotbar_1`..`hotbar_5` | 1–5 | Y / D-pad L / D-pad R / D-pad D / LB | unchanged | **deliberately NOT Palworld's 1/3 pal-switch** — owner explicitly wants the 1–5 hotbar kept; see "What deliberately did not change" |
| `combat_switch_left`/`right` | ←/→ | D-pad L/R | unchanged | already Palworld-adjacent (Palworld uses 1/3, we use hotbar for that instead — see above) |
| `map` | M | View (button 4) | unchanged | already Palworld |
| `interact` | E | X (button 2) | unchanged | sacred, see below |
| `build_rotate_left`/`right` | wheel up/down | LT-stand-in / RT-stand-in glyph, real axis 4/5 | unchanged binding, now genuinely shared with combat | see "The trigger dual-use" below |

## The trigger dual-use, and why it's safe

`combat_quick`/`combat_charged` now sit on the same physical triggers
(RT/LT) as `build_rotate_right`/`build_rotate_left`. This is deliberate, not
an oversight, and mirrors the dual-use the project already ships elsewhere
(RB is both `combat_throw` and `backpack_drop`; A is `jump`, `combat_quick`
was, and `menu_confirm`).

It's safe because the two consumers can never both be listening at once:

- `scripts/build/build_placer.gd`'s `_physics_process` returns immediately
  when `GameState.pending_build == ""` — the build actions are inert unless
  a build ghost is actually armed.
- `scripts/combat/combat_manager.gd`'s `_read_player_input` is only called
  from `_tick_active`, which only runs in `State.ACTIVE` — the combat
  actions are inert outside a fight.

A build ghost cannot be armed during a fight (the menu that arms one is part
of the pause/build UI, which `menu_cancel`'s own note already establishes
can't open mid-fight), so RT/LT never mean two things at the same moment.
Documented in `data/config/menu.json`'s "Fighting" and "Building" group
notes, and covered by a new test,
`test_the_shipped_defaults_share_triggers_between_combat_and_build`, in
`tests/test_controls.gd`.

**Known gap:** the vendored Kenney glyph set
(`assets/ui/input_prompts/`) has no trigger PNGs, only `xbox_lb.png`/
`xbox_rb.png`. `scripts/ui/input_glyph.gd`'s `quick`/`charged` entries now
borrow those as stand-ins (the same convention `build_rotate_left`/
`build_rotate_right` already used), which means `combat_hud.gd`'s Actions
row currently draws `combat_quick`'s RT stand-in (`xbox_rb.png`) identical
to `combat_throw`'s real RB icon (`xbox_rb.png`) side by side. This is a
readability defect, not a functional one — flagged here rather than
"fixed" by pointing the glyph at the wrong button. Real trigger art closes
it; per CLAUDE.md, that's a Meshy/asset-pack task for later, not something
to invent mid-rebind.

## Q, considered and declined (`combat_throw` keyboard)

Palworld throws the Pal Sphere on Q. Tetherbound's Q is already
`tool_cycle` (next inventory tab / next exploration tool), documented in
`data/config/menu.json`'s `_comment_cycle`, shown in the on-screen footer
("Q / LB Next tab"), referenced in `scripts/ui/build_menu.gd`'s comments,
and the subject of `D14`'s own design note. `combat_throw`'s **pad** default
(RB) already matches Palworld exactly, so the only thing at stake was the
keyboard key. Moving `tool_cycle` off Q to make room would have touched five
places for a keyboard-only convenience on an action whose pad binding
already lands right — a larger diff than the ask justified. `combat_throw`
keeps F.

## E and LB, considered and declined (`pal_recall`)

Palworld's summon/retrieve is E/LB. E is `interact` here — CLAUDE.md-tier
sacred, never reassigned. LB is already `tool_cycle`'s pad button (and
doubles as `hotbar_5`'s pad button), both live during ordinary exploration
at the same time `pal_recall` would need to fire, so LB is genuinely
contended rather than just habit. `pal_recall` keeps its existing R /
D-pad-up default; R is Palworld-adjacent by feel (reload-adjacent muscle
memory) even though Palworld doesn't use it for this verb.

## What deliberately did NOT change

- **Hotbar stays on 1–5**, not Palworld's 1/3 pal-left/right + 2
  sphere-cycle + 4 pal-commands. The owner explicitly wants the 1–5 quick-item
  band (`HD2`) kept; this is the one place this pass intentionally diverges
  from Palworld's keyboard layout.
- `interact` stays E (sacred).
- `tool_cycle` stays Q/LB (see above).
- `pal_recall` stays R/D-pad-up (see above).
- `combat_throw` stays F/RB (see above).

## What changes on disk

- `project.godot` — `combat_quick`/`combat_charged` gamepad events swapped
  from buttons to the trigger axes described above. Keyboard/mouse halves
  untouched.
- `data/config/menu.json` — a new note on the "Fighting" group explaining
  the trigger dual-use, and an added clause on the existing "Building" group
  note cross-referencing it. No glyph table changes: `axis_4_+`/`axis_5_+`
  already read "LT"/"RT" from the pre-existing build-rotate entries, so
  `combat_quick`/`combat_charged` inherit correct on-screen labels for free.
- `scripts/ui/input_glyph.gd` — `quick`/`charged` gamepad icons repointed to
  the LB/RB stand-ins, with the collision against `throw`'s real RB icon
  called out in-line.
- `tests/test_controls.gd` — `test_the_shipped_defaults_already_share_buttons`
  and `test_the_defaults_clash_with_themselves_and_that_is_not_a_warning` no
  longer assert `combat_quick` shares pad A (it doesn't anymore); both now
  check the still-true A/`menu_confirm` clash instead. A new test,
  `test_the_shipped_defaults_share_triggers_between_combat_and_build`, covers
  the new RT/LT dual-use directly.
- `scripts/combat/combat_manager.gd`, `scripts/build/build_placer.gd`,
  `scripts/ui/combat_hud.gd` — untouched. They all read input by action
  name, so the rebind is invisible to them by construction; that's what
  made this a same-day change instead of a refactor.
