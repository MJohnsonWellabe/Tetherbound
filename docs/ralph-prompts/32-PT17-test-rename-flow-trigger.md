# PT-17-test — Cover the exact creature rename flow

## Goal
Add a regression test for the **real rename path the player uses**, not merely the underlying nickname setter:

**press the rename hotkey/action (historically H on keyboard) on the Creatures screen -> `name_prompt` opens prefilled with the creature's current visible name/nickname -> player edits/confirms -> `set_nickname` updates that exact creature -> UI refreshes and persistence works.**

The backlog specifically says current testing proves the generic mechanism but not the trigger/path that failed in play.

## Inspect current main
Before writing the test, find:
- current action/binding that triggers rename; do not hard-code H if the action has been renamed/rebound;
- `tab_creatures.gd` input handling/focus contract;
- `scripts/ui/name_prompt.gd` open/prefill/confirm behavior;
- party `set_nickname` API and revision/update behavior;
- save serialization of nickname.

## Test requirements
Drive the actual screen/input route:
1. create/mount the normal menu and Creatures tab with at least two known creatures;
2. focus/select a specific creature;
3. send the real input event that current InputMap maps to rename (keyboard event for the historical bug, plus joypad equivalent if rename has one);
4. assert the actual `name_prompt` becomes open;
5. assert its edit field is prefilled correctly (existing nickname when present; current label/species default according to product behavior when empty);
6. replace text with a new nickname;
7. confirm through the prompt's normal confirm input;
8. assert the selected creature's nickname changed and the other creature did not;
9. assert the Creatures UI refreshes to the new label;
10. save/load and assert nickname persists if that path is not already covered by a stronger existing save regression.

## Input fidelity
Do not use `Input.action_press` as the only evidence for a focus/menu interaction. Use `Input.parse_input_event` with the real `InputEventKey`/joypad event where appropriate, following the project's known controller testing rule.

The test must fail if the configured key/button no longer opens the prompt, even if calling `set_nickname()` directly still works.

## Edge cases
- existing nickname is prefilled, not species name;
- empty nickname/default-name creature;
- cancel leaves nickname unchanged;
- rename one creature does not affect another same-species instance;
- prompt input ownership prevents the triggering press from immediately confirming/closing itself.

## Preserve
This is a test item. Do not redesign naming UI unless the new regression exposes a real current bug; if it does, fix the smallest root cause and keep the regression.

## Acceptance criteria
A CI regression now proves the exact player-visible rename trigger through prompt confirmation and would catch the original "the mechanism exists but H doesn't actually do it" class of failure.