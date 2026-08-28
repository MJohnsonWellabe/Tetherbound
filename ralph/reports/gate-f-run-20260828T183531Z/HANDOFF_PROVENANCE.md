# Handoff provenance — gate-f-run-20260828T183531Z

Section B chains the journey by save handoff. `_step_save_out` checks only
that the slot file EXISTS, and `seed_save` put the previous segment's file
there at step 3 of the same segment — so a segment that never reached the
Save tab copies out the save it was HANDED, under this segment's name, and
reports a PASS (RIG-10). Identity of bytes is what settles it.

| exit save | bytes | md5 (12) | distinct? |
|---|---|---|---|
| `S02/saves/S02-exit.json` | 1414891 | `43c7cb73adce` | yes |
| `S03/saves/S03-exit.json` | 1415100 | `62344f09b811` | **NO — shared with 2 other** |
| `S04/saves/S04-exit.json` | 1415100 | `62344f09b811` | **NO — shared with 2 other** |
| `S05/saves/S05-exit.json` | 1415100 | `62344f09b811` | **NO — shared with 2 other** |

## The duplicates, and what each segment's own notes say about saving

### `62344f09b811` — S03, S04, S05

Byte-identical. At most one of these segments wrote this file; the rest
handed it on. Their own Save-tab verdicts:

**S03**
  - `PASS     ` S03-109 — open the pause shell for camp
  - `FAIL     ` S03-121 — open the pause shell for floor
      FAIL map did not open the pause shell: context panel:SwapPanel -> panel:SwapPanel (owner=SwapPanel)
  - `FAIL     ` S03-134 — open the pause shell for wall
      FAIL map did not open the pause shell: context panel:SwapPanel -> panel:SwapPanel (owner=SwapPanel)
  - `FAIL     ` S03-147 — open the pause shell for door
      FAIL map did not open the pause shell: context panel:SwapPanel -> panel:SwapPanel (owner=SwapPanel)
  - `FAIL     ` S03-160 — open the pause shell for roof
      FAIL map did not open the pause shell: context panel:SwapPanel -> panel:SwapPanel (owner=SwapPanel)
  - `FAIL     ` S03-176 — open the pause shell for bed 1
      FAIL map did not open the pause shell: context panel:SwapPanel -> panel:SwapPanel (owner=SwapPanel)
  - `FAIL     ` S03-187 — open the pause shell for bed 2
      FAIL map did not open the pause shell: context panel:SwapPanel -> panel:SwapPanel (owner=SwapPanel)
  - `FAIL     ` S03-196 — open the pause shell for bed 3
      FAIL map did not open the pause shell: context panel:SwapPanel -> panel:SwapPanel (owner=SwapPanel)
  - `FAIL     ` S03-231 — open the Satchel for entrant 1
      FAIL inventory did not open the pause shell: context panel:SwapPanel -> panel:SwapPanel (owner=SwapP
  - `PASS     ` S03-264 — Section B save handoff
  - `PASS     ` S03-265 — open the pause shell
  - `PASS     ` S03-266 — cycle right to the Save tab
  - `PASS     ` S03-267 — the Save tab is up
  - `PASS     ` S03-269 — press Save
  - `PASS     ` S03-271 — copy slot 4 out into the run directory

**S04**
  - `PASS     ` S04-63 — Section B save handoff
  - `FAIL     ` S04-64 — open the pause shell
      FAIL game_menu did not open the pause shell: context narrative_modal -> narrative_modal (owner=Dialo
  - `PASS     ` S04-65 — cycle right to the Save tab
  - `FAIL     ` S04-66 — the Save tab is up
      input_context=narrative_modal (wanted menu_save)
  - `PASS     ` S04-68 — press Save
  - `PASS     ` S04-70 — copy slot 4 out into the run directory

**S05**
  - `PASS     ` S05-62 — Section B save handoff
  - `PASS     ` S05-63 — open the pause shell
  - `PASS     ` S05-64 — cycle right to the Save tab
  - `FAIL     ` S05-65 — the Save tab is up
      input_context=menu_backpack (wanted menu_save)
  - `PASS     ` S05-67 — press Save
  - `PASS     ` S05-69 — copy slot 4 out into the run directory

## What this means for the chain

A segment whose entry save is a duplicate did not start where §B says it
did. Reading the chain in order:

- **S04** ended in the same world it was handed; the segment
  after it entered from a state one or more gates EARLIER than its name says.
- **S05** ended in the same world it was handed; the segment
  after it entered from a state one or more gates EARLIER than its name says.

Segments with an exit save, in order: S02, S03, S04, S05
