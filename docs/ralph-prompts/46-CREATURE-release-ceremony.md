# CREATURE-RELEASE — Add the missing release ceremony around the working release mechanic

## Owner reproduction
The owner confirmed that getting rid of/releasing a creature **functionally works**, but there is no ceremony/presentation around it.

Do not rewrite the underlying party-removal mechanic if it is correct. This item exists because releasing one of only five creatures should feel deliberate, understandable and emotionally legible rather than like deleting a row.

## Goal
Wrap the existing release action in a controller-first ceremony that:
- makes it unmistakable which creature is leaving;
- gives the player a deliberate confirmation opportunity;
- shows the creature and trainer saying goodbye in a short, skippable/non-dragging presentation;
- removes the creature only at the committed point;
- returns cleanly to the Creatures screen/world with the party state correct.

## Inspect first
- `scripts/ui/tab_creatures.gd`
- current release button/action and party removal API
- `autoload/party.gd`
- creature visual/model instancing used by menus/ceremonies
- any evolution ceremony or existing presentation flow that can be reused
- nickname/label helpers
- pending-catch overflow/release logic if it has its own flow
- save format / party persistence
- input owner and paused-menu behavior

Reuse existing ceremony/presentation infrastructure where possible. Do not build a cinematic framework just for this.

## Flow
### 1. Select
From the Creatures screen, player deliberately chooses Release for one specific owned creature.

### 2. Confirm
Show:
- creature portrait/model;
- nickname/species label;
- level and a small amount of identifying info useful to prevent releasing the wrong one;
- clear warning that release is permanent;
- Confirm Release / Cancel with dynamic controller glyphs.

Do not use an easy one-button action with no confirmation.

### 3. Ceremony
On confirm:
- transition to a clean presentation using the actual creature model;
- trainer and creature remain readable;
- creature gives a short goodbye/acknowledgment animation if current animation set supports it;
- short text such as a contextual farewell is acceptable, but do not invent extensive personality dialogue per species;
- keep duration brief and allow a sensible skip/advance path after the committed release point.

The visual should communicate **release into the world / goodbye**, not death, destruction or storage transfer.

### 4. Commit
Remove the creature through the existing authoritative party API exactly once.

Do not remove it before the user confirms. Once the ceremony reaches the committed point, save/party state must be unambiguous.

### 5. Return
Return to the correct UI state:
- party rows refreshed;
- focus on a sensible surviving row/action;
- no stale model/preview;
- menu can close normally;
- world control returns correctly.

## Pending-catch/five-creature interaction
If the existing `pending_catch` overflow flow requires releasing one of five before accepting a sixth catch, inspect whether this ceremony should be shared.

Ideal: one release presentation/confirmation contract reused by both voluntary release and forced choose-one-to-release situations, with context-specific messaging.

Do not create storage as an escape from the five-creature rule.

## Edge cases
- cannot release a null/empty slot;
- handle only-one-creature party according to current game rules; if release would leave zero when that is disallowed, refuse clearly;
- resting creature: inspect new bed-rest state. A creature physically assigned to a bed should not vanish while its bed assignment remains; require removal from bed first or cleanly clear assignment as one transaction;
- active world creature: recall/remove its world body cleanly before party deletion;
- save during/after ceremony cannot resurrect or duplicate creature;
- repeated Confirm input cannot release two creatures.

## Tests
Add state tests for:
- cancel leaves party unchanged;
- confirm removes exactly selected creature;
- nickname/species identity stays correct;
- save/load after release preserves removal;
- overflow/pending-catch integration if shared;
- resting/active creature guard;
- double-confirm cannot double-remove.

Use live controller input for the actual confirmation flow where practical.

## Visual verification
Because the entire point is missing presentation, capture the ceremony and run the normal visual-judge requirement for scene/UI changes. Judge at ROG handheld scale.

## Acceptance criteria
1. Release still functionally removes the selected creature.
2. Player gets a clear permanent-action confirmation first.
3. Actual selected creature is shown in a short goodbye ceremony.
4. Presentation reads as release/goodbye, not death or silent deletion.
5. Cancel is safe.
6. Commit happens exactly once.
7. Party/menu/world state returns cleanly after ceremony.
8. Save/load preserves the release.
9. Five-creature/pending-catch path reuses the same release grammar where appropriate.

## Definition of done
Releasing a pal is mechanically reliable but also feels like a meaningful team decision—the player sees who is leaving, confirms it, says goodbye, and then continues with the correct remaining team.