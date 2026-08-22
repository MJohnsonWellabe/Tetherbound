# D68 — The authored controller map has no held buttons

**Status:** accepted, 2026-08-22. Owner directive, recorded in
`ralph/OWNER_DIRECTIVES_2026-08-22.md` section 1.

## The decision

> "don't make a user hold a button down for any action. if that's not possible
> ask what to get rid of as an action. you should be using every button before
> going to hold down as a choice though."

Hold-to-modify chords are **banned** as a mapping solution. When a verb does not
fit on the fourteen buttons an Xbox-layout pad has, the answer is to remove or
merge a verb and say so — never a modifier chord, and never a tap/hold split on
one button.

The authored map (ROG Ally / Xbox layout):

| Input | Verb |
|---|---|
| Left stick / L3 | move / sprint |
| Right stick / R3 | camera / recentre |
| A | jump |
| X | interact — talk, gather, chop, mine, mount, throw the selected orb, place while building |
| Y | inventory |
| B | hotbar 1 |
| D-pad ← ↑ → ↓ | hotbar 2–5 |
| LB | cycle party member |
| RB | call out / put away your creature |
| LT / RT | creature charged attack / quick attack |
| View | map |
| Menu | game menu |

Build mode: X place, B exit, LT/RT rotate, D-pad up/down snap step and rotate,
LB/RB catalogue category, Y dismantle. Map screen: LT/RT zoom, stick pans.
Menus: A confirm, B back, LB/RB tab.

## What had to give for it to fit

Three verbs left the button map and became hotbar entries. This is what makes
the map fit without chords, and it is the owner's own answer to "what would you
get rid of":

- **The torch** is a tool on the bar ("torch doesn't need a button").
- **The build hammer** is a tool on the bar: select it, press interact, you are
  in build mode (`playground_hud.gd::_hammer_opens_the_catalogue`, which stands
  aside whenever the interaction arbiter has a real target, so a hammer in hand
  still talks to Grandpa).
- **Catching** is an orb selected on the bar and thrown with interact.

`tool_cycle` is retired outright — the hotbar is direct-select on both devices.
`use_tool`, `combat_throw` and `combat_run` keep their keyboard keys and lose
their pad buttons. Keyboard bindings are untouched throughout: this is a
fourteen-button problem, not a hundred-key one.

## Consequences that are deliberate

- **Fleeing is RB.** Putting the creature away IS disengaging. `combat_run` gets
  no button of its own.
- **"Cycle party member" and "switch which creature you are piloting" are one
  verb on LB.** This is what retires the d-pad collision: the d-pad is hotbar
  2–5 in every context including combat, so food and orbs stay reachable
  mid-fight.
- **LT/RT are idle while no creature is out.** Accepted rather than papered over
  with an invented verb.

## What this supersedes

- **D32's tap-vs-hold party selector.** Holding the switch button opened a
  five-row selector; the hold is banned and the selector had no other way in, so
  it was removed. `PartyStrip` is already on screen while a switch is available
  and shows the same five rows.
- **The hold-LB hotbar chord** shipped by the DPAD-COLLISION branch.
- **D35's trigger dual-use argument** survives for combat/build (a fight and an
  armed ghost are still mutually exclusive) but no longer has to carry
  `torch_place` on RT, which has no pad binding at all now.

## How it is kept true

`data/config/input_contexts.json` declares which actions are live together, in
which context. `tests/test_input_context_collisions.gd` crosses that with
`project.godot`'s `[input]` section and fails if two live actions share a joypad
button or axis.

That test exists because the d-pad collision passed every check the project had.
`tests/test_world_verb_input_owner_enforcement.gd` asks whether a poller
consults `input_owner.gd` — a real question, and a different one. D32's
`combat_switch_left` and HD2's `hotbar_2` were both properly gated, both
legitimately live in a fight, and both on joypad button 13. One press, two
verbs, and nothing in the suite could see it.
