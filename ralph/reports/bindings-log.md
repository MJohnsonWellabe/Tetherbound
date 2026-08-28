# Controller bindings lane — log

Branch `ralph/BINDINGS`. One defect, reported by the HUD/catch lane
(`ralph/reports/hud-catch-log.md`, branch `ralph/HUD-CATCH`) out of its own
gamepad-pinned render and flagged rather than fixed because the repair spanned
files it did not own.

**The game's first catch told an ROG Ally player to press a key the device does
not have.** CLAUDE.md's hard rules include *Controller first* and *Windows / ROG
Ally is primary*, and this is the tutorial line for catching — the mechanic the
owner separately reports as the worst-feeling thing in the game
(`ralph/OWNER_PLAYTEST_2026-08-28.md` §2a).

---

## 1. What was actually wrong

Verified against current `main` before changing anything, in the order the brief
asked for.

**The content is fine.** `data/progression/objectives.json`'s opening rung has
never hardcoded a letter:

```
"how": "Wear it down in the fight first, then pick an orb on the hotbar and press {combat_throw}."
```

**The binding is not, and it is not a mistake either.** `project.godot`:

```
combat_throw={ "deadzone": 0.5, "events": [Object(InputEventKey, ... 70 ...)] }
```

One event, keyboard `F`, no joypad event. CONTROLLER-MAP (owner directive
2026-08-22 §1, recorded as `docs/decisions/D68`) retired six verbs from the pad
rather than folding them into the held-button chords the same directive bans.
`tests/test_controls.gd::PAD_UNBOUND_BY_DESIGN` already lists all six with their
reasons and **asserts they have no gamepad binding** — so the map is a decision
under test, not drift.

**So `input_glyph.gd` was behaving correctly.** Handed an action with no pad
event, `pad_button_name_for_action()` returned `""` and `action_name()` fell
through to `key_name_for_action()`. It had nothing else to name.

The result on screen, gamepad-pinned, at 1920x1080 — every glyph on the frame a
pad glyph (View, Y, RB, LB, B and the d-pad on the quick bar) and the card in the
middle of it:

> *"Wear it down in the fight first, then pick an orb on the hotbar and press
> **F**."*

## 2. Establishing what the pad does today, before changing it

The brief was explicit that this is not a "just add a joypad event" fix, and it
is right. Three independent sources agree the pad already throws, via `interact`:

| source | what it says |
|---|---|
| `scripts/combat/combat_manager.gd::_throw_pressed()` | `combat_throw` **or** `interact` |
| `scripts/combat/throw_aim.gd` | same pair plus `combat_quick`; *"interact (X) is the pad's throw button now"* |
| `tests/smoke_controller_catching.gd::_open_aim()` | opens the aim by tapping a **physical `JOY_BUTTON_X`** and nothing else |

Runtime confirmation rather than reading alone: the probe below prints
`action_name("interact") = X` under a pinned pad, and the same X is what
`smoke_controller_catching` presses to reach the aim.

**So `project.godot` is correct and is deliberately unchanged by this lane.**
Giving `combat_throw` a joypad event would put a combat-context action on the
world's interact button — `data/config/input_contexts.json` and
`tests/test_world_verb_input_owner_enforcement.gd` both model `combat_throw` as
combat-context and `interact` as world — and would fail `test_controls.gd`'s
existing assertion. Two ways to throw, to fix a label.

The other obvious wrong fix, named in the brief and confirmed here: swapping the
token to `{interact}` **inverts** the bug. On a keyboard `interact` is `E` and
the throw really is `F`.

## 3. The repair

A device-aware alias, in the resolver, in three parts.

**`scripts/ui/input_glyph.gd`**

- `PAD_VERB_ALIAS` — the verbs CONTROLLER-MAP **moved** rather than retired,
  each entry quoting the reader that ORs the two actions together:
  `combat_throw -> interact`, `combat_run -> creature_recall` (D68: *"flee is
  `creature_recall` on RB, because putting your creature away IS
  disengaging"*), `use_tool -> interact` (`harvest_logic.gd`: *"X/`interact` is
  what chops and mines"*).
- `pad_button_name_for_verb()` — the action's **own** joypad event wins; the
  alias is consulted only when it has none. A player who binds a pad button to
  `combat_throw` in Settings is told about *their* button, not the alias's.
- `pad_button_name_for_action()` **stays literal**. The Settings tab's gamepad
  column rebinds exactly that cell, and `data/config/menu.json` says in as many
  words that an empty cell there is correct rather than broken. An alias must
  not appear in a cell the player cannot edit.
- `action_name()` (the plain-text resolver the objective card reaches through
  `quest_log.gd::hint_text()`) and `icon()`'s gamepad fallback both route
  through the verb resolver.

**`data/progression/objectives.json`** — content unchanged; the token was always
right. Its `_comment_guided` token contract now records that resolution is
device-aware, and that `{torch_toggle}`/`{build_open}` must **not** be written
because those two are not aliasable (below).

**`project.godot`** — verified, deliberately unchanged. See §2.

### The second defect the render exposed

The resolver fix alone did not change the card. `autoload/game_state.gd` resolves
`objective_hint` into a string with the button names already baked in, and
recomputed it **only when the rung moved** — so it froze whichever device was
live the last time the player advanced the chapter. `input_glyph.gd`'s whole
`HD1` design is live switching *"as the player's hands move between keyboard and
pad"*, and this one cached string was the only thing on the HUD that did not
follow. Picking up the pad on a desktop left the first-catch card naming `F`;
setting it down on the Ally left it naming `X`.

It now re-resolves on a device flip as well, polled with one boolean comparison.
Guarded: a `set_objective()` **pose** still sticks until the rung moves, because
several capture tools pin the device and pose a demo objective in the same run,
and a device flip taking their line down would be a new bug in place of the old
one.

## 4. The sweep

The brief asked whether other actions have the same shape. Every action in
`project.godot`'s `[input]` section was audited for a joypad event
(`InputEventJoypadButton` or `InputEventJoypadMotion`). Six have none, and they
are exactly `test_controls.gd::PAD_UNBOUND_BY_DESIGN`:

| action | key | pad reality | verdict |
|---|---|---|---|
| `combat_throw` | F | X, via `interact` | **aliased** — the reported defect |
| `combat_run` | Esc | RB, via `creature_recall` | **aliased** — same shape, not yet on screen |
| `use_tool` | LMB | X, via `interact` | **aliased** — wired ahead of a caller |
| `torch_toggle` | L | *no single button* | **reported, not guessed** |
| `torch_place` | P | *no single button* | **reported, not guessed** |
| `build_open` | B | *no single button* | **reported, not guessed** |

Every `{token}` in player-facing content was then resolved under a pinned pad.
The tokens in use are `{combat_throw}`, `{interact}`, `{inventory}`
(objectives.json) and `{menu_confirm}`, `{menu_cancel}`, `{menu_tab_left}`,
`{menu_tab_right}` (menu.json's footer, which draws both halves side by side and
reads the keyboard name on purpose). **`{combat_throw}` was the only one that
resolved to a keyboard key on a pad.** It is now the only aliased one in use.

### The three that are NOT the same defect

`torch_toggle`, `torch_place` and `build_open` lost their pad buttons in the same
directive, but they were **retired, not moved**: the torch and the build hammer
became hotbar tools, so the pad path is select-then-press and *no single button
performs the verb*. Aliasing them to `interact` would print "X toggles the
torch", which is false until the torch is the selected tool — a different lie,
not a fix. They are a **content** problem: a hint for one must name both steps in
prose, which `objectives.json`'s own gather and build rungs already do
(*"Select a tool on the hotbar, then {interact} at a tree"*). Nothing draws a
glyph for them today, so nothing is currently lying; this is recorded so the
next author does not reach for the alias table.

### Two adjacent things checked and found correct

- **`combat_hud.gd`'s aim-cancel prompt** draws `icon("cancel")` = B on a pad.
  `throw_aim.gd` cancels on `combat_run` **or** `menu_cancel`, and `menu_cancel`
  is B. Correct as it stands.
- **The exploration legend** draws only `map`, `inventory`, `creature_recall`
  and `party_cycle`, all of which have real pad events. Correct as it stands.

## 5. Verification

`tools/_probe_objective_hint_device.gd` (new). Mounts
`scenes/ui/playground_hud.tscn` standalone — the defect is entirely inside the
HUD scene, so a before/after pair costs two short runs instead of two full
Meadows boots — and **pins the device**, the way
`tools/_capture_ui_survey.gd::_pin_owner_device()` and
`tools/_probe_hud_quickbar_and_roster.gd` already do: under `xvfb-run` no joypad
is connected, so `game_state.gd` initialises from
`Input.get_connected_joypads()` and an unpinned frame photographs the keyboard
half — the half the defect is invisible in. Method reused from the HUD/catch
lane, not reinvented. It prints the resolved card text alongside the frame, so
the verdict does not rest on a screenshot.

```
xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . \
  --rendering-driver opengl3 --resolution 1920x1080 \
  --script tools/_probe_objective_hint_device.gd -- --out=shots/bindings --tag=after --device=gamepad
```

| device pinned | before | after |
|---|---|---|
| **gamepad** | *"...pick an orb on the hotbar and press **F**."* | *"...and press **X**."* |
| **keyboard** | *"...and press **F**."* | *"...and press **F**."* — unchanged |

The keyboard column is the point of the second render: a fix that makes the pad
right by making the desktop wrong is not a fix, which is exactly what swapping
the token to `{interact}` would have done.

`tests/test_input_glyph_verbs.gd` (new, 11 tests / 50 assertions) locks:

- the three verbs resolve to X, RB, X on a pad;
- the literal resolver still reports no pad binding, so Settings is untouched;
- an action with its own pad button is never aliased;
- the keyboard answers are unchanged (`combat_throw` -> F, `interact` -> E);
- **both directions of table rot** — every alias target still has a pad button
  to lend, and every alias key is still one of `test_controls.gd`'s
  pad-unbound-by-design actions;
- **the sweep itself** — every pad-unbound action is either aliased or listed
  with the reason it cannot be (never both, never neither), and every `{token}`
  in `objectives.json` resolves to a real pad button.

**Negative control run**, because a test that has never failed has not been
tested: deleting the `combat_throw` alias turns three of the eleven red,
including the content sweep. Restored and re-verified green.

## 6. What this does not prove

- **How catching feels, or how the pad feels in the hand.** [OWNER-ONLY]. This
  lane can verify which glyph renders; it cannot play it on the device.
- **That naming the right button makes the first catch good.** It stops the
  game lying on the tutorial line, which is a precondition for the mechanic
  being learnable, not a demonstration that it is now satisfying. The owner's
  §2a report about catching is a separate lane's problem.
- **That a real ROG Ally resolves to the same glyph.** The pin is a software
  pin of `Game._last_input_was_gamepad`; it exercises the same branch the Ally's
  always-connected XInput pad takes, but it is not the hardware.
