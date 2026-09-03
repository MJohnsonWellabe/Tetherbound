# OP-CREATURE-UX — Release ceremony, level-up feedback, and exploration cycling

## Goal
Make creature ownership/progression feel immediate and consequential without forcing the player through menus for basic party management.

## A. Release ceremony
Functional deletion/release is not complete unless the intended ceremony presentation runs.

Requirements:
- explicit confirmation before release;
- creature identity/nickname clearly shown;
- ceremony/presentation communicates breaking the bond rather than silently removing an array entry;
- after confirmation, creature leaves party exactly once;
- pending overflow-catch flow still resolves correctly;
- save state persists the result;
- cancel safely returns without changing ownership.

Reuse any existing ceremony screen/animation scaffolding. Do not replace the five-creature rule with storage.

## B. Level-up feedback
Whenever a creature gains a level through combat/training/progression, immediately notify the player.

At minimum show:
- creature name/nickname;
- new level;
- meaningful new move/trait/stat/unlock if one actually occurred.

Feedback should be visible but not block combat for an excessive duration. Queue multiple level-ups cleanly if several creatures gain XP together.

Do not invent fake unlocks merely to populate the message.

## C. Cycle creatures during exploration
The player must be able to select/cycle party creatures without opening the Creatures menu.

Requirements:
- dedicated controller-first previous/next creature controls using available InputMap space cleanly;
- HUD/party strip visibly updates current selection;
- if no creature is deployed, cycling changes which creature will deploy next;
- if a creature is active, cycling should use the existing recall/summon/swap contract to change active creature without a menu trip;
- resting/unavailable/fainted creatures obey current eligibility rules and are skipped or clearly refused as appropriate;
- update RG3's compact control legend/glyphs;
- keyboard/mouse parity.

Do not create a second party state; use the existing party/current-active systems.

## Preserve
- five-creature cap;
- no creature storage;
- existing bond/nickname/shiny individuality;
- resting creature unavailability from OP-BED;
- combat-specific switching controls remain coherent and must not conflict with exploration cycling.

## Testing
Cover release confirm/cancel/persistence; overflow release ceremony; single and multi-creature level-up notifications; cycle forward/back through 1–5 party slots; skip/handle resting/fainted slots; active creature swap; controller glyph accuracy; no menu required.

## Definition of done
The player feels creature progression as it happens, releasing a pal has meaningful presentation, and everyday party selection is fast enough to support an exploration-focused creature-training game.