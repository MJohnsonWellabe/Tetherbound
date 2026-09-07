# CREATURE-LEVELUP — Tell the player immediately when a pal levels up

## Owner decision
When one of the player's creatures levels up, the player wants to know. The current progression can change level/stats without enough immediate player-facing feedback.

## Goal
Every real level increase should produce concise, readable feedback that says:
- **which creature** leveled;
- **the new level**;
- any genuinely important new unlock/change caused by that level (new move availability, evolution eligibility, etc.) when those systems actually exist.

The player should not need to notice a stat number changed later in the Creatures menu.

## Inspect first
- creature XP/level progression code
- all XP award sources: wild combat, trainer combat, tournament, rest bonus, quests if any
- `creature_instance.gd` and progression helpers
- combat end/result UI
- HUD/world toast/notification systems
- creature menu rows/details
- move/evolution unlock plumbing
- save format

Find the single authoritative place where a level transition can be detected. Avoid every XP source inventing its own level-up message.

## Event contract
The progression layer should expose enough information when XP application causes level(s) to increase:
- creature identity/reference;
- old level;
- new level;
- count of levels gained if more than one;
- any unlock events already produced by progression.

A large XP reward may jump multiple levels. Report the final new level clearly rather than firing five overlapping toasts unless the game has a deliberate multi-step celebration.

## Presentation by context
### During/after combat
Do not cover active combat controls with a modal mid-attack. Queue the level-up presentation to the battle result/end beat unless existing design safely celebrates at the moment XP is granted.

Good minimal presentation:
- `Bramblebun reached Lv. 4!`
- a small creature icon/model accent;
- optional second line for a real unlock: `Can now evolve` or `Learned <move>` only when true.

### Exploration/noncombat XP
Use a short HUD toast/notification that does not pause the world unnecessarily.

### Multiple creatures
If several party creatures level from one reward, present a readable compact sequence/list instead of stacking overlapping banners.

## Sound/animation
If the project already has a general success sting/particle treatment, reuse it. Do not create a large bespoke audiovisual system. A subtle creature-facing flourish is enough.

## Accuracy requirements
- message level must equal actual saved creature level;
- do not announce a level if XP was capped/refused;
- do not announce evolution/move unlocks that are not actually available;
- nickname should be used through the canonical `label()` helper;
- a creature that levels while resting still needs the feedback at an appropriate time, but avoid spawning it as active merely to show the message.

## Save/reload
The notification itself does not need to persist as unread mail, but level state must. Do not replay old level-up banners every time a save loads.

If XP/level-up occurs during a transition followed immediately by save, ensure the level is committed before the UI reports success.

## Tests
- XP below threshold -> no level-up event;
- exact threshold -> one event with correct old/new;
- multi-level jump -> coherent one result or controlled sequence;
- nickname used correctly;
- several creatures leveling -> no dropped events;
- save/load does not replay stale event;
- unlock text only when corresponding unlock is real.

## Acceptance criteria
1. Every real creature level gain is visible to the player.
2. Feedback names the correct creature and new level.
3. Multi-level and multi-creature rewards remain readable.
4. Combat feedback appears at a non-disruptive moment.
5. Important real unlocks can be included; false unlock claims never appear.
6. No duplicate level-up message is emitted by multiple XP award layers.
7. Save/load preserves progression without replaying historical notifications.

## Definition of done
A player training a team can feel progression moment by moment: when a pal gets stronger, the game clearly tells them who advanced and to what level.