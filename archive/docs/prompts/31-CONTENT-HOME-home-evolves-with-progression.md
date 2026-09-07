# CONTENT-HOME — Make home remain relevant throughout Meadows

## Goal
Ensure returning to Grandpa's village/home continues to produce meaningful gameplay and story feedback throughout the entire Meadows chapter instead of becoming an opening/tutorial location the player never needs again.

## Owner/backlog intent
Home should visibly and functionally evolve with progression through:
- Grandpa dialogue changing as the player advances;
- creature beds/recovery and the player's own bed/sleep loop;
- storage and crafting usefulness;
- villagers learning/reacting to what happened in later bands;
- rescued/encountered NPCs returning where canon calls for it;
- story check-ins after important milestones.

At any major chapter point, returning home should show **something that acknowledges where the player is now**.

## Inspect current systems first
Inventory current village/home content and progression flags:
- `data/dialogue/opening.json`, village/meadows-freed dialogue and band dialogue;
- Grandpa/village NPC greeting selection;
- quest/progression flags;
- player bed/camp/sleep and `creature_bed.gd` recovery;
- storage/crafting/building systems;
- tournament state from RG19;
- band milestones, relay/stronghold progression, rescued NPCs if any.

Do not create duplicate home services that already exist in player-buildable form. The point is relevance and response, not making Grandpa's house a mandatory universal hub.

## Progression beats
Author a small set of home-state milestones keyed to meaningful existing flags. Examples of the **shape**, not required new fiction:
- after first team-building/tutorial: Grandpa acknowledges progress;
- after tournament victory: home sends the player outward toward Team Tether;
- after major dungeon/relay discoveries: villagers/Grandpa react with new information or concern;
- after significant rescue/side activity: the relevant person may be visibly back home if canon supports it;
- before/after stronghold: home reflects the chapter's stakes and eventual change.

Prefer a few high-value changes over new dialogue after every minor flag.

## Functional reasons to return
Home/village should remain useful without becoming required after every trip:
- safe sleep / own bed;
- creature rest/recovery through creature beds;
- storage and crafting access already supported by the game;
- tournament and NPC services where appropriate;
- evolving dialogue/check-ins;
- optional regrouping before deeper bands.

If player-built versions of these systems are available anywhere, preserve that freedom. Home is a reliable anchor, not the only place a mechanic works.

## Visible evolution
Where low-cost and canon-consistent, use existing props/NPC placements/dialogue state to show progress. Examples: an NPC has returned, a small repaired/changed prop state, tournament aftermath, village reactions. Do not rebuild the village every band or add new art families.

Every visual state must persist through save/load and be derived from progression flags rather than temporary scene state.

## Dialogue
Keep Grandpa's established warm, brief voice. Do not make him recite a quest log. Villagers can carry localized reactions/knowledge. Use existing dialogue data/effects and reveal-ladder rules; do not have home NPCs explain mysteries earlier than the progression spec allows.

## Preserve
- player freedom to build/camp elsewhere;
- no forced fast travel or mandatory return after every band;
- current village asset family/NPC rigs;
- five-creature cap;
- existing save/progression store;
- main objective clarity.

## Acceptance criteria
1. Major Meadows progression milestones select visibly appropriate home/NPC states.
2. Grandpa and relevant villagers no longer repeat opening-era dialogue after major achievements.
3. Home provides useful recovery/crafting/storage/sleep functions through existing systems.
4. Creature care beds and player sleeping fit RG18/RG19 loops.
5. At least several chapter milestones produce a clear home-world or dialogue change.
6. Changes persist through save/load and do not regress to earlier states.
7. The player can still progress/explore without being forced home after every milestone.
8. No reveal-ladder/story spoilers are introduced.

## Testing / verification
Create progression-state tests for representative early/mid/late home responses and save/reload. Verify dialogue selection cannot repeat one-time gifts or duplicate rewards. Capture the village at representative milestone states if physical props/NPC placement changes and run visual review.

## Definition of done
Grandpa's village remains the player's emotional and practical anchor for the whole Meadows chapter: **returning home later feels different because the player and the world have changed**, while remaining optional enough to preserve exploration freedom.