# Phase -1.7 — owner ROG playtest, 2026-08-18 evening

**ACTIVE OWNER PRIORITY OVERLAY. Read this before the older Phase -1.6 queue.**

This file records the owner's newest hands-on play feedback after the 38-item Meadows review-board prompts were authored. The newer owner word wins wherever it conflicts with older backlog wording or an older Ralph prompt. The detailed implementation prompts live in `docs/ralph-prompts/` and are linked below.

The owner explicitly asked for these findings to be worked into the backlog and converted into detailed Ralph work. Do not treat this as notes-only evidence.

## Design direction settled by this playtest

The Meadows' motivating loop is now explicit:

**Tetherbound is Pokémon-first in motivation, with Valheim/Palworld-style survival and world systems supporting that motivation.** The player keeps moving because they want to find, fight, catch and train a stronger five-creature team for increasingly important trainers, tournaments, Team Tether encounters, special wild creatures and bosses. Gathering, building, camping, beds, food and recovery create preparation, risk and pacing around that team progression.

World density is deliberately varied rather than uniform. The vegetation-heavy pond band is an **approved lush-area reference**. Preserve that kind of dense, attractive pocket. Other Meadows stretches should be broad open fields with long sightlines and sparse-to-moderate vegetation, in the visual/compositional spirit of Valheim meadows or Palworld open areas. Do not make the entire corridor look like the pond and do not thin the pond to make everything match.

## P0 — session-ending / core-verbs-broken

### OP17-RG1 — modal/input freeze is still alive and has more reproductions
Owner tonight:
- freezes talking to the innkeeper and coming off his menu;
- freezes after resting a pal;
- freezes after opening Build from the main/pause menu and exiting to place;
- in the last Build reproduction the failure was worse than the old RG1 report: the player could not move **and could not even reopen the main menu**.

This reopens RG1 despite the prior real-input smoke saying the two earlier cases did not reproduce. The new report proves the old test did not cover the whole failure family.

Detailed prompt: `docs/ralph-prompts/39-RG1-owner-playtest-modal-freeze-reopen.md`

### OP17-BUILD-FLOW — placement works; the build-mode interaction model is wrong
Owner tonight: structures now place. The original RG4 placement-confirm blocker is therefore **positive evidence / verify-only**. Do not regress it.

New locked behavior: Valheim-style persistent build mode. Select a floor once, place it, immediately retain another floor ghost and keep placing until cancel or another selection. This applies to **all buildables**, not only structural pieces.

Detailed prompt: `docs/ralph-prompts/40-BUILD-valheim-repeat-placement.md`

### OP17-BUILD-SNAP — modular building does not compose into a house
Owner tonight:
- roof cannot be placed on top of an already-built wall;
- floor pieces do not occupy/align to a full logical square;
- walls end up about half a square off instead of sitting on floor edges.

Treat as one systemic snap/module-contract defect, not three piece-specific offsets.

Detailed prompt: `docs/ralph-prompts/42-BUILD-modular-snap-contract.md`

### OP17-GATHER — tool/gather loop still does not read or feel correctly
Owner tonight:
- chopping must require the axe actually being equipped;
- the trainer must visibly swing the axe;
- current prompt says to chop but the action appears to do nothing;
- gathering a wood drop should visibly report `+X Wood`.

The earlier RG-GATHER landing is not sufficient acceptance; live play still fails the intended contract.

Detailed prompt: `docs/ralph-prompts/44-GATHER-equipped-tool-swing-and-pickup-feedback.md`

### OP17-TORCH — current live torch has two concrete defects
Owner tonight:
- the torch is held incorrectly; flame end should be upright like a real person holding a torch;
- the torch lights the world the first time it is drawn but not the second time it is pulled out.

This supersedes the previous RG22 verify-only conclusion. Do not retune brightness first; fix transform/orientation and re-equip lifecycle, then judge lighting.

Detailed prompt: `docs/ralph-prompts/51-TORCH-upright-hand-and-re-equip-light.md`

### OP17-TITLE — no front door exists in the played build
Owner tonight: there is still no launch menu. Required front door: `New Game`, `Load Game`, and normal exit behavior. This is current owner reproduction, not a historical note. RG25/EV9 remain open until the exported build actually starts here.

Detailed prompt: `docs/ralph-prompts/54-RG25-owner-confirmed-title-screen-missing.md`

## P1 — core-loop behavior / strong usability gaps

### OP17-BUILD-REMOVE — dismantle player-built structures
There must be a controller-friendly way to target and remove something the player built. Use build mode / construction targeting; clearly highlight the piece before destruction. **Full material refund** is locked for normal dismantling so experimentation and correcting snap mistakes are not punitive.

Detailed prompt: `docs/ralph-prompts/41-BUILD-dismantle-full-refund.md`

### OP17-PAL-REST — creature bed becomes real overnight recovery
Owner tonight: when a pal rests, the player should see it lying in the bed and it should have to stay there overnight to regain health; while resting it is not eligible to fight.

Owner clarification: **health regenerates gradually while it remains in bed.** If removed early, keep the partial health restored so far, but it does not receive the full overnight/rested benefit. A resting creature is unavailable for combat/tournament eligibility until removed or the rest completes. This must integrate with RG19's rested/fed/happy model rather than inventing parallel condition state.

Detailed prompt: `docs/ralph-prompts/43-CREATURE-BED-gradual-overnight-rest.md`

### OP17-CATCH — rework catch aiming/throw feel toward Palworld's interaction grammar
Owner tonight: current aiming/throw is bad.

Locked interaction target, without copying proprietary art/assets: hold aim -> camera tightens/offsets over shoulder -> visible reticle -> right stick freely aims -> readable trajectory/landing assistance -> throw from aim mode -> cancel returns cleanly. Mild target assistance is okay; hard lock-on is not the default.

Detailed prompt: `docs/ralph-prompts/45-CATCH-over-shoulder-aim-and-throw.md`

### OP17-RELEASE — mechanics work, ceremony is missing
Owner tonight: getting rid of a creature functionally works but there is no ceremony. Releasing one of the player's five creatures is an emotionally legible event, not an array-delete action.

Detailed prompt: `docs/ralph-prompts/46-CREATURE-release-ceremony.md`

### OP17-LEVELUP — creature progression needs immediate feedback
Owner tonight: when a creature levels up, the player wants to know. Show who leveled, the new level, and any relevant newly unlocked/changed result without requiring a menu hunt.

Detailed prompt: `docs/ralph-prompts/47-CREATURE-level-up-feedback.md`

### OP17-PAL-CYCLE — cycle creatures in exploration without opening menu
Owner tonight: player should be able to cycle pals without entering the creature menu. Controller-first previous/next selection should update the active/selected pal and the exploration control legend. Respect resting/unavailable/fainted eligibility rules.

Detailed prompt: `docs/ralph-prompts/48-PARTY-cycle-pals-in-world.md`

### OP17-MAP-TRAILS — movement-up appears to work; trail rendering is incomplete
Positive owner evidence: minimap now seems to keep travel pointing up. Treat RG15 movement-up as verify-only and do not rewrite it unless current reproduction fails.

Current defect: minimap does not show all authored trails. Shared map/minimap source must represent the meaningful traversal network consistently.

Detailed prompt: `docs/ralph-prompts/52-MAP-all-authored-trails-visible.md`

### OP17-POND-WATER — pond has no actual water
The pond area is visually strong in vegetation composition but the pond itself has no real water. Add the established Meadows water treatment and any required traversal/collision semantics through existing world/water systems; do not fake it with a flat opaque color card.

Detailed prompt: `docs/ralph-prompts/49-POND-real-water.md`

### OP17-BUILDING-DOORS — readable doors must behave as doors
Owner tonight: doors on the buildings at the pond are not openable. Broader rule: a Meadows building door that visually reads as usable must open/interact, unless it is intentionally locked and that lock is communicated in-world. Avoid one-off fixes to only the two observed meshes.

Detailed prompt: `docs/ralph-prompts/50-WORLD-usable-building-doors.md`

## P2 — Meadows purpose, encounter density, and visual composition

### OP17-CORE-LOOP — the long corridor is still a boring run because the preparation loop is too sparse
Owner tonight: the Meadows needs substantially more to do while progressing:
- more wild pals to fight/catch and level against;
- more NPC trainers on/near the path for XP and team testing;
- more useful mining/harvest opportunities;
- special stronger wild encounters that create reasons to detour;
- reasons to stop, build/camp and rest creatures before continuing.

This does **not** mean filling every metre with enemies or quests. The required cadence is repeated meaningful opportunities separated by scenic/travel breathing room. The player should regularly be making a team-building/preparation choice rather than simply holding forward through empty land.

The critical motivational spine is team progression: tournament -> stronger route trainers / wild encounters -> Team Tether -> special encounters -> stronghold/boss. Survival systems support that spine.

Detailed prompt: `docs/ralph-prompts/53-MEADOWS-pokemon-first-core-loop-density.md`

### OP17-VEG-COMPOSITION — preserve lush pond pocket AND broad open meadows
Owner positive feedback: the band near the pond with dense trees/plants looks great. Preserve it as an approved lush composition reference.

At the same time, the biome also needs large open areas with long views and lower clutter, like the openness/readability of Valheim meadows or Palworld open fields. Density must be authored by region; do not solve `VEG-CORRIDOR` with one global density.

This requirement is included in OP17-CORE-LOOP and should inform MQ3/vegetation authoring.

## Superseded / verification notes for older prompts

- `02-RG4-build-placement-confirmation.md`: original inability-to-place symptom appears fixed in this playtest. Preserve/regression-test placement; newer repeat-mode + snap tasks define the remaining owner ask.
- `08-RG22-verify-current-torch-lighting.md`: verify-only brightness conclusion is superseded by concrete current orientation/re-equip defects in OP17-TORCH.
- `14-RG15-minimap-movement-up-and-full-map-navigation.md`: movement-up is now positive owner evidence; keep as verify-only. Trail completeness remains open.
- `25-RG19-spec-creature-condition-model.md`: resting must now include physical bed occupancy, gradual HP recovery, combat ineligibility and overnight/full-rest completion.
- `27-RG25-title-save-select-quit-and-boot-measurement.md`: title-screen absence is currently reproduced by the owner; implementation is required, not optional verification.
- `36-R9.1-scope-input-combat-catch-camera-polish.md`: catch aiming is no longer an unspecified polish domain; OP17-CATCH is concrete near-term implementation work.
- `06-RG20-meadows-wild-creature-population.md`, `28-MQ3...`, `29-PW2...`, `30-CONTENT-ACTIVITIES...`: coordinate under OP17-CORE-LOOP so individual content tasks collectively create a purposeful team-progression cadence rather than isolated features.

## Positive findings — protect these

1. **Structure placement now works** in the played build. Do not regress it while changing build-mode persistence/snapping.
2. **Minimap movement-up appears to work.** Verify, then leave it alone if correct.
3. **Pond-band dense vegetation looks great.** Preserve that area as a lush reference while adding open-field contrast elsewhere.

## Execution order

Work P0 first. A content-rich corridor is not useful while menus freeze, construction cannot compose, tools do not communicate hits, or the executable lacks a title screen. P1 makes the core verbs coherent. P2 then fills the Meadows around the now-working preparation/team loop.

Every item above has a detailed prompt in `docs/ralph-prompts/`. Inspect current `main` before editing because several symptoms have changed between owner builds. Newer owner play evidence in this file outranks stale comments claiming an item is DONE.