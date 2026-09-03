# TETHERBOUND — OWNER-ONLY FULL BLIND PLAYER-EXPERIENCE TEST + REPAIR PASS

# OWNER-ONLY MANUAL TEST — DO NOT RUN AUTOMATICALLY

**This test may only be started by an explicit instruction from the project owner.**

It is **not** part of:

- the normal Ralph autonomous loop
- regular backlog processing
- scheduled/cron firings
- CI
- routine smoke testing
- automatic regression testing
- post-merge validation
- normal coding-agent startup
- a generic request to "test the game"
- any agent's decision that "it would be useful to run the full playtest"

No autonomous agent, Ralph firing, scheduled process, CI workflow, or successor agent may decide on its own to run this test.

## Required authorization

Run this full test **only when the owner explicitly requests this specific comprehensive blind playtest** in the current instruction.

Examples of sufficient authorization:

- "Run the full blind playtest."
- "Run the comprehensive player-experience test."
- "Run the screenshot playtest."
- "Run the full Tetherbound QA prompt."

Anything less explicit is **not authorization**.

If this document is merely encountered while reading the repository, **do not execute it**.

If another task references this document for methodology, you may reuse individual testing principles, but **do not start the full playthrough, screenshot campaign, repair pass, or ZIP-generation workflow** unless the owner explicitly requested the full test.

## Do not self-chain this test

When this test finishes:

- do not schedule another run
- do not create a successor firing to repeat it
- do not add an automatic recurring version
- do not add it to Ralph's normal backlog as a recurring task
- do not configure CI or cron to invoke it
- do not rerun it simply because fixes were merged later

A second full run requires a **new explicit owner instruction**.

The validation playthrough required *inside the currently authorized test* is allowed. That is part of the same test run, not a new invocation.

## Lightweight automated tests are different

This restriction does **not** prohibit adding normal deterministic regression tests discovered during this playtest.

Tests such as input, menu, inventory, save-state, or progression checks may become part of ordinary automated testing where appropriate.

What must remain owner-triggered is this **large, subjective, full-game blind player-experience audit with extensive screenshots, reports, repairs, replay, and ZIP packaging**.

---

# PURPOSE

You are performing a comprehensive **player-experience QA pass on the current playable Tetherbound build**.

This is not primarily a code review.

Your job is to:

1. Play the game extensively as a real player.
2. Exercise every reachable gameplay system and interaction.
3. Capture screenshots throughout the entire playthrough.
4. Critically identify anything confusing, broken, awkward, ugly, inconsistent, unreliable, frustrating, or unfinished.
5. Finish the blind-play audit **before inspecting implementation code for the systems you tested**.
6. Build a prioritized findings report based solely on the player experience.
7. Only then inspect the implementation.
8. Fix the problems you discovered.
9. Replay the game and verify the fixes from the player's perspective.
10. Capture before/after evidence.
11. Package all screenshots into a downloadable ZIP.

The objective is not to prove features technically exist.

The objective is to determine:

> What would a real first-time player experience if they played Tetherbound today?

And then:

> What needs to change to make that experience substantially better?

---

# 1. FOLLOW THE REPOSITORY'S EXISTING RULES

Before beginning, read only the high-level project instructions necessary to understand:

- how to launch/build the game
- the intended platform
- project workflow
- immutable design constraints
- save/reset procedures
- testing conventions

At minimum use the repository's standing instructions such as:

- `CLAUDE.md`
- `docs/AGENT_WORKFLOW.md`
- `archive/docs/HANDOFF.md`
- relevant settled design decisions

Do **not** read gameplay implementation files, UI scripts, combat scripts, camera scripts, inventory scripts, quest scripts, or similar implementation code before the blind test.

Do **not** search the backlog or completed-work history for known bugs before the blind test.

Do **not** use existing bug reports to tell yourself what to look for.

The point is independent discovery.

You may read design documentation only as needed to understand what the game is supposed to let the player do.

---

# 2. HARD BLIND-TEST RULE

During the first playthrough:

**YOU ARE A PLAYER, NOT A PROGRAMMER.**

Do not investigate why something happened.

Do not open the relevant script.

Do not inspect scene-node wiring.

Do not search for the implementation.

Do not fix things while playing.

Instead:

1. encounter the experience naturally
2. attempt to understand it from what the game communicates
3. document what happened
4. capture evidence
5. continue playing

Maintain a running player-experience log.

Only after completing the full blind playthrough may you begin root-cause investigation.

This separation is mandatory.

---

# 3. START FROM A TRUE FRESH-PLAYER STATE

Whenever practical:

- use a new save
- reset progression
- clear prior test state
- start at the intended beginning of the game
- do not use developer shortcuts during the primary playthrough
- do not spawn items
- do not teleport
- do not manually advance quests
- do not give yourself resources
- do not manipulate internal state

If a bug makes normal progression impossible, document it as a blocker.

Only then may you use the minimum necessary workaround to continue testing later systems.

Any workaround must be explicitly logged.

---

# 4. SCREENSHOT EVERYTHING IMPORTANT

Create a dedicated evidence directory for this run.

Example:

`playtest_evidence/YYYY-MM-DD_full_blind_test/`

Capture screenshots throughout the entire playthrough.

Do not capture only bugs.

Capture both:

- normal successful states
- problematic states

This allows the owner to understand the whole experience.

At minimum capture screenshots of:

- initial game state
- starting environment
- first movement
- every major tutorial/instruction
- each significant dialogue sequence
- every major NPC encountered
- every major menu/tab
- inventory
- party/pal management
- crafting
- building interface
- hotbar
- map
- minimap in multiple locations
- combat beginning
- combat HUD
- each combat action type
- taking damage
- defeating an enemy
- catching flow
- catch aiming
- successful catch
- failed catch if encountered
- resource gathering
- item pickup
- item use
- feeding/healing
- building placement
- completed construction
- daytime exploration
- dusk
- nighttime
- lighting tools
- settlements/landmarks
- environmental transitions
- camera obstruction cases
- unusual animation cases
- UI failures
- control inconsistencies
- visual glitches
- anything confusing
- anything particularly good
- any progression blocker
- any moment that feels clearly unfinished

Capture additional screenshots whenever words alone would inadequately communicate the issue.

---

# 5. SCREENSHOT NAMING

Use filenames that can be understood without opening every image.

Use this pattern:

`NNN_CATEGORY_short-description.png`

Examples:

- `001_START_fresh-game.png`
- `012_DIALOGUE_first-conversation.png`
- `027_UI_inventory-main-tab.png`
- `041_COMBAT_first-wild-fight.png`
- `054_BUG_camera-obscured-by-tree.png`
- `071_NIGHT_exploring-after-dark.png`
- `083_BUILD_completed-first-structure.png`

Keep screenshots chronologically numbered.

When an issue needs multiple views:

- `054a_...`
- `054b_...`
- `054c_...`

---

# 6. MAINTAIN A SCREENSHOT INDEX

Create:

`SCREENSHOT_INDEX.md`

For every screenshot record:

- filename
- approximate playthrough point
- what the player was doing
- what the screenshot demonstrates
- whether it represents:
  - normal state
  - positive experience
  - potential issue
  - confirmed issue
  - blocker
  - before-fix
  - after-fix

This index should make the screenshot archive understandable without guessing.

---

# 7. PLAY WITH THE PRIMARY TARGET CONTROLS FIRST

Tetherbound is controller-first.

Perform the main blind playthrough using a standard Xbox-style controller configuration representative of the intended primary platform.

Exercise every available input:

- left stick
- right stick
- D-pad up
- D-pad down
- D-pad left
- D-pad right
- A
- B
- X
- Y
- LB
- RB
- LT
- RT
- Start/Menu
- View/Back where applicable
- stick clicks where applicable

Do not merely tap each button once.

Use controls naturally throughout play.

Later perform a keyboard/mouse compatibility pass for all supported PC functionality.

---

# 8. TEST THE GAME AS A PLAYER WOULD

Do not follow a narrow scripted route.

Explore.

Experiment.

Make reasonable mistakes.

Try things in different orders.

Test obvious affordances.

When the interface implies something can be done, attempt it.

When you acquire an item, try to use it.

When a menu shows a selectable object, select it.

When an instruction displays a control, press that control.

When the world presents an apparent path, follow it.

When something looks interactive, attempt to interact with it.

When you receive a new capability, test it immediately and later in another context.

The agent should behave like a curious player, not an automated regression script.

---

# 9. COMPLETE THE FULL CURRENT PLAYABLE PROGRESSION

Play through as much of the currently intended playable game as reasonably possible.

Do not stop after proving the beginning works.

Continue until you reach:

- the current legitimate end of playable progression
- a true progression blocker
- or a clearly documented vertical-slice endpoint

Exercise all systems available along the way.

If the current build supports multiple in-game days, continue beyond the first day where necessary to reach or test functionality.

---

# 10. SYSTEM COVERAGE CHECKLIST

During the playthrough, attempt to exercise **every reachable player-facing system**.

This checklist is a minimum, not a maximum.

## Character movement

Test:

- idle
- walking
- running/sprinting
- changing direction
- starting
- stopping
- sharp turns
- gradual turns
- forward movement
- backward movement
- strafing if supported
- jumping
- landing
- slopes
- uneven terrain
- falling
- fall damage
- stamina
- movement while low on stamina
- movement around obstacles
- collision against structures
- collision against vegetation
- narrow spaces
- movement during combat
- movement while interacting
- movement near water if available

Critically assess animation quality and responsiveness.

---

# 11. CAMERA

Stress-test the third-person camera.

Test:

- normal travel
- sprinting
- rapid direction changes
- fast camera rotation
- slow camera rotation
- camera pitch extremes
- close walls
- buildings
- doors
- trees
- foliage
- cliffs/slopes
- rocks
- large creatures
- small creatures
- NPC crowds if present
- combat
- catching
- gathering
- building
- dialogue transitions
- tight spaces
- uneven terrain

Evaluate:

- obstruction
- clipping
- snapping
- jitter
- unwanted zoom
- disorientation
- target visibility
- player visibility
- comfort
- responsiveness

---

# 12. WORLD AND ENVIRONMENT

Explore broadly rather than staying on the critical path.

Assess:

- terrain appearance
- terrain variation
- ground materials
- paths
- vegetation
- grass
- rocks
- trees
- environmental clutter
- landmarks
- settlements
- buildings
- props
- distant scenery
- lighting
- shadows
- color harmony
- repeated assets
- object placement
- floating objects
- buried objects
- seams
- LOD transitions if visible
- pop-in
- collision
- invisible barriers
- world boundaries
- navigational readability

Ask constantly:

> Does this feel like a deliberate world, or a collection of game assets placed into a level?

---

# 13. TIME OF DAY

Experience as many lighting conditions as the build supports.

Test:

- morning
- daytime
- dusk
- night
- dawn if practical

At each stage test:

- movement
- resource gathering
- NPC readability
- navigation
- combat
- catching
- building
- interaction prompts
- minimap
- landmarks
- artificial/player-carried lighting

Assess atmosphere separately from practical visibility.

---

# 14. NAVIGATION

Attempt to navigate using the tools the game gives you rather than memorizing coordinates.

Test:

- minimap
- any full map
- compass if present
- quest markers
- landmarks
- paths
- signs
- environmental cues

Perform intentional navigation tasks:

1. leave the starting area
2. travel to a meaningful destination
3. move far enough away to lose immediate visual reference
4. attempt to return
5. navigate at night
6. navigate while following an objective
7. find a previously visited location
8. determine facing direction
9. distinguish nearby routes

Assess whether the navigation UI is actually useful rather than merely rendered.

---

# 15. NPCS

Interact with every reachable NPC or representative NPC type.

Test:

- approaching from different directions
- interaction range
- interaction prompts
- initiating dialogue
- advancing dialogue
- cancelling where supported
- repeating conversations
- talking after quest/state changes
- visual differentiation
- animation
- facing behavior
- idle behavior
- collision
- dialogue camera
- pacing
- clarity

Judge dialogue as a player.

Record where it:

- drags
- repeats itself
- gives too much information
- gives too little information
- fails to explain an objective
- interrupts play unnecessarily
- is charming or effective

---

# 16. TUTORIALIZATION

Treat every tutorial as untrusted until proven useful.

For each tutorial or control hint:

1. read it as a new player
2. follow exactly what it says
3. verify the described input
4. verify the described result
5. test whether it appears at the right time
6. test whether it disappears appropriately
7. determine whether the player could reasonably understand it

Look for:

- incorrect buttons
- stale controls
- duplicate bindings
- contradictory instructions
- instructions appearing too late
- instructions disappearing too quickly
- walls of text
- unexplained mechanics
- terminology the player has not learned

---

# 17. RESOURCE GATHERING

Gather every reachable resource type or representative category.

Test:

- discovering the resource
- recognizing it visually
- approaching it
- interaction prompt
- harvesting
- animation
- sound
- feedback
- inventory gain
- respawn behavior if relevant
- depleted state
- tool requirement if relevant

Try gathering repeatedly and in different environments.

---

# 18. INVENTORY

Perform more than a visual inspection.

Actually use the inventory extensively.

Test:

- opening
- closing
- first-focus behavior
- navigation
- changing tabs
- selecting every visible item category
- inspecting items
- using items
- stack counts
- item descriptions
- unavailable actions
- scrolling
- empty states
- full or near-full inventory if practical
- controller
- keyboard/mouse
- repeated rapid inputs
- returning from submenus
- focus persistence

Attempt every displayed action.

---

# 19. PARTY / PAL MANAGEMENT

Exercise every reachable pal-management action.

Test:

- viewing the party
- selecting each pal
- inspecting stats
- inspecting moves
- changing active pal if supported
- healing
- feeding
- using consumables
- viewing status effects
- changing order if supported
- adding newly caught pals
- reaching capacity if practical
- attempting invalid actions
- backing out
- reopening the menu
- controller navigation throughout

Check whether every action communicates:

- what can be done
- who it affects
- why it cannot be done
- whether it succeeded

---

# 20. ITEMS AND CONSUMABLES

For every usable item type encountered:

1. acquire it normally
2. inspect it
3. select it
4. attempt to use it from every obvious context
5. choose a target where required
6. observe feedback
7. verify quantity changes
8. test invalid targets
9. test use during different game states where appropriate

Do not assume an item is functional because it exists in inventory.

---

# 21. CRAFTING

Craft every practical early-game recipe or representative recipe category.

Test:

- discovering recipes
- understanding costs
- available/unavailable states
- ingredient counts
- selecting recipes
- crafting once
- crafting repeatedly
- receiving output
- inventory updates
- controller focus
- backing out
- reopening

Judge clarity and pacing.

---

# 22. BUILDING

Use the actual building system extensively.

Test:

- entering build mode
- finding available recipes
- switching build choices
- understanding resource costs
- preview placement
- valid placement
- invalid placement
- rotation
- placement near terrain variation
- placement near structures
- placement near vegetation
- placement on slopes
- confirming construction
- cancelling
- repeated construction
- collision
- interaction with built objects
- visual grounding
- controller controls
- keyboard controls

Try to make sensible mistakes and observe how the game responds.

---

# 23. COMBAT

Fight multiple encounters, not just one.

Test against different available enemy/pal types where practical.

Exercise every combat action presented by the UI.

Test:

- initiating combat
- target identification
- attack controls
- multiple moves
- cooldowns
- positioning
- enemy attacks
- taking damage
- pal damage
- fainting or low health
- switching if supported
- retreating if supported
- catching during combat
- environmental obstruction
- camera
- HUD readability
- combat prompts
- sound
- VFX
- hit feedback
- damage readability
- victory
- defeat if practical
- post-combat state
- repeated combats

For every control instruction shown during combat, press exactly what it tells you to press.

---

# 24. CATCHING

Perform multiple catch attempts.

Test:

- entering catch mode
- aiming
- camera behavior
- trajectory/readability
- target movement
- close target
- medium target
- longer practical target
- elevated target
- lower target
- partially obstructed target
- different backgrounds
- daylight
- nighttime if possible
- successful catch
- failed catch
- repeated throws
- resource consumption
- party integration afterward

Judge catching as a mechanic, not just whether the catch probability resolves.

Ask:

> Do I understand where my throw will go before I commit to it?

---

# 25. HOTBAR / QUICK ACCESS

Exercise every slot repeatedly.

Test:

- selecting each slot
- changing slots rapidly
- using the selected item/action
- switching during movement
- switching during combat if allowed
- switching near interactables
- visual active-state feedback
- controller bindings
- keyboard bindings
- invalid/empty slots
- menu transitions

---

# 26. QUESTS AND PROGRESSION

For every reachable objective:

- read what the game tells you
- try to determine what to do without reading code
- follow the objective
- deliberately leave and return
- perform some steps in unexpected order
- talk to relevant NPCs before/after progression
- inspect quest UI
- verify objective updates
- verify completion feedback
- verify rewards
- verify next-step clarity

Look for soft locks and state mismatches.

---

# 27. HEALTH, STAMINA, SATIETY, STATUS, AND SURVIVAL SYSTEMS

Exercise every currently implemented player/pal status system.

Test:

- health loss
- healing
- stamina depletion
- stamina recovery
- satiety loss if present
- food consumption
- buffs/debuffs
- low-state feedback
- death
- respawn
- death satchel/recovery if reachable
- pal health
- pal recovery
- status effects

Judge whether changes are noticeable and understandable.

---

# 28. DEATH AND FAILURE

Where practical, intentionally fail.

Test:

- player death
- combat loss
- pal defeat
- failed catch
- insufficient resources
- invalid building placement
- unavailable item use
- full party/inventory edge cases
- attempting locked progression
- running out of a needed consumable

A game must communicate failure as clearly as success.

---

# 29. SAVE / LOAD / RESTART

Test persistence.

At suitable points:

1. save or trigger normal autosave behavior
2. exit cleanly
3. relaunch
4. verify player position/state where appropriate
5. verify inventory
6. verify party
7. verify built objects
8. verify progression
9. verify world state
10. continue playing

Also test a second save/load later in the run if practical.

---

# 30. AUDIO AND FEEDBACK

Listen critically.

Evaluate:

- footsteps
- gathering
- UI navigation
- button confirmation
- combat
- hits
- catches
- crafting
- building
- item use
- dialogue
- ambience
- nighttime
- music transitions

Look for actions that visually occur but feel dead because they lack sound or feedback.

---

# 31. UI CONSISTENCY

Audit behavior by using the UI, not by reading its implementation.

For every menu test:

- opening
- closing
- back/cancel
- confirm
- tab switching
- directional navigation
- focus indication
- first input
- rapid input
- scrolling
- mouse interaction
- controller interaction
- input immediately after opening
- input immediately after closing
- returning from nested menus

Record any case where:

- an input is ignored
- focus disappears
- focus is invisible
- a hidden control receives input
- multiple presses are required
- a controller requires mouse intervention
- button meanings change unexpectedly
- back/cancel does not behave predictably

---

# 32. KEYBOARD / MOUSE SECONDARY PASS

After the primary controller playthrough, perform a focused PC input pass.

Test all reachable actions with keyboard/mouse.

Do not replay the entire game unless necessary, but exercise each interaction category.

Verify:

- movement
- camera
- interaction
- menus
- hotbar
- combat
- catching
- building
- inventory
- map
- pause
- item use

Check that on-screen prompts update appropriately if dynamic prompts are intended.

---

# 33. TRY TO BREAK THINGS NATURALLY

Without using developer tools, perform adversarial player behavior.

Examples:

- mash buttons
- switch menus quickly
- open/close menus repeatedly
- rotate camera during transitions
- interact while moving
- interact from odd angles
- switch hotbar rapidly
- press multiple buttons near-simultaneously
- leave an objective area
- return later
- interact with NPCs out of order
- attempt actions with insufficient resources
- use items on invalid targets
- build in strange but plausible locations
- fight near geometry
- catch near geometry
- save after unusual states
- reopen menus immediately after combat
- enter combat after menu use

The goal is not malicious fuzzing.

The goal is discovering things ordinary enthusiastic players will eventually do.

---

# 34. EVALUATE GAME FEEL, NOT JUST FUNCTION

For every major system rate:

### Discoverability
Can a first-time player figure out that the feature exists?

### Understandability
Can they understand what to do?

### Input Reliability
Does a valid input work on the first attempt?

### Responsiveness
Does the game react quickly enough?

### Feedback
Does the player know what happened?

### Readability
Can the player understand the screen and world state?

### Consistency
Do controls and UI behave predictably?

### Comfort
Are movement and camera comfortable?

### Friction
Are there unnecessary steps?

### Visual Quality
Does it look intentional and cohesive?

### Audio Quality
Does it sound responsive and complete?

### Pacing
Does the game keep the player playing rather than waiting?

### Enjoyment
Did the interaction make you want to continue?

Use a 1–5 score for each relevant dimension.

Do not inflate scores.

---

# 35. RECORD POSITIVE FINDINGS TOO

This is not only a bug hunt.

Record:

- moments that feel especially good
- visuals that work well
- mechanics that are intuitive
- satisfying feedback
- effective dialogue
- fun combat moments
- good exploration
- strong atmosphere
- clever UI
- anything worth preserving

Fixes should not accidentally destroy the strongest parts of the experience.

---

# 36. CREATE THE BLIND FINDINGS REPORT BEFORE READING CODE

At the end of the blind playthrough, stop.

Do not inspect code yet.

Create:

`BLIND_PLAYTEST_FINDINGS.md`

Include:

## Executive Summary

Describe the overall experience as a player.

## Playthrough Narrative

Brief chronological summary of what you did and how it felt.

## Coverage

List every system exercised.

Mark:

- fully tested
- partially tested
- unreachable
- blocked

## Findings by Severity

### P0 — Blocker / broken core functionality
Progression blockers, unusable systems, severe input failures, crashes, save loss, etc.

### P1 — Major player-experience problem
Problems that materially damage play.

### P2 — Noticeable quality/friction issue
Things that hurt polish or usability.

### P3 — Minor polish
Smaller improvements.

For each finding include:

- ID
- severity
- system
- player action
- expected behavior
- observed behavior
- reproduction steps
- frequency
- screenshot filenames
- player impact
- whether it blocked further testing

## Positive Findings

What should be preserved.

## Top 10 Player-Experience Problems

Rank the ten issues that most damage the game.

## Player Verdict

Answer:

- Would you voluntarily keep playing?
- When was the game most fun?
- When was it most frustrating?
- What felt unfinished?
- What felt surprisingly polished?
- What confused you?
- What did you have to guess?
- Which controls did you stop trusting?
- Which UI did you stop trusting?
- Which mechanic most needs another design/polish pass?
- What are the three most important changes?

Only after this report is saved may you inspect gameplay implementation.

---

# 37. FREEZE THE ORIGINAL BLIND REPORT

Do not rewrite the blind report after learning what the code does.

The original report represents what the player experienced without developer knowledge.

Preserve it.

If later investigation changes your understanding, explain that separately.

---

# 38. NOW INVESTIGATE ROOT CAUSES

After the blind report is complete:

1. inspect relevant implementation
2. trace root causes
3. check existing tests
4. check related systems
5. determine whether each problem is isolated or systemic

Do not immediately patch the visible symptom.

Prefer root-cause fixes.

Examples:

If several menus lose the first input:
- investigate shared focus/input architecture.

If several prompts disagree with controls:
- investigate how bindings and prompts are sourced.

If several terrain surfaces render incorrectly:
- investigate shared materials/layers.

If several camera cases fail:
- improve camera collision/occlusion behavior systemically.

---

# 39. BUILD A REPAIR PLAN

Create:

`PLAYTEST_REPAIR_PLAN.md`

For every issue selected for repair include:

- finding ID
- severity
- suspected root cause
- affected systems
- proposed fix
- regression risk
- test method
- required before/after screenshots

Prioritize player impact over implementation convenience.

---

# 40. FIX IN PRIORITY ORDER

Default order:

1. crashes/data loss
2. progression blockers
3. unreliable controls
4. unusable menus/interactions
5. misleading instructions
6. combat/catching/building functionality
7. navigation
8. camera
9. readability
10. movement/animation feel
11. pacing
12. world presentation
13. minor visual polish

Do not spend most of the pass polishing scenery while major interactions remain unreliable.

---

# 41. ADD REGRESSION TESTS

For deterministic problems, add automated coverage where practical.

Good automated candidates include:

- menu focus
- first-press input
- tab navigation
- item selection
- item consumption
- hotbar changes
- input mappings
- displayed binding correctness
- progression state
- crafting costs
- build state
- save persistence
- minimap coordinate transforms
- catch-mode state
- inventory changes
- party changes

Do not pretend automated tests can certify subjective quality such as:

- camera comfort
- movement animation quality
- visual cohesion
- terrain beauty
- atmospheric lighting
- minimap usefulness
- combat readability
- catching feel

Those require replay and screenshots.

---

# 42. SECOND PLAYTHROUGH — VALIDATION

After repairs, start another clean playthrough.

Do not merely load a debug scene containing the repaired feature.

Repeat the broad player journey.

At minimum re-test:

- onboarding
- movement
- camera
- exploration
- navigation
- gathering
- inventory
- party management
- consumables
- crafting
- building
- combat
- catching
- hotbar
- NPC interactions
- progression
- day/night
- save/load
- all repaired systems

Capture **after** screenshots matching significant **before** screenshots.

Use matching filenames when useful:

- `BEFORE_054_camera-tree.png`
- `AFTER_054_camera-tree.png`

---

# 43. VERIFY EXPERIENCE, NOT CODE

A problem is not fixed because:

- the project compiles
- the signal is connected
- a value changed
- a test passed
- a node exists
- a shader parameter changed
- the implementation looks correct

It is fixed only when replay demonstrates that the player-facing problem is gone or materially improved.

---

# 44. SCREENSHOT PACKAGE

At the end of the entire pass, assemble all visual evidence into one ZIP archive.

Suggested structure:

```text
Tetherbound_Playtest_Evidence/
    README.md
    SCREENSHOT_INDEX.md

    01_blind_playthrough/
        001_START_...
        002_...
        ...

    02_blind_issues/
        ...

    03_before_fix/
        ...

    04_after_fix/
        ...

    05_final_validation/
        ...

    reports/
        BLIND_PLAYTEST_FINDINGS.md
        PLAYTEST_REPAIR_PLAN.md
        FINAL_PLAYTEST_REPORT.md
```

Create:

`Tetherbound_Playtest_Evidence_<date>.zip`

The final response must provide the path/link to the ZIP as a downloadable artifact where the execution environment supports attachments/artifacts.

Do not merely say screenshots were taken.

Verify the ZIP exists and contains the expected files.

---

# 45. FINAL REPORT

Create:

`FINAL_PLAYTEST_REPORT.md`

Use this structure:

## 1. Final Verdict

Brief assessment of the current game.

## 2. What Was Tested

List all systems and progression covered.

## 3. Blind Findings

Reference the original frozen blind report.

## 4. Problems Fixed

For each:

- finding ID
- player-visible problem
- root cause
- repair
- validation result
- before screenshot
- after screenshot

## 5. Problems Improved but Not Fully Solved

Be explicit.

## 6. Problems Still Open

Include severity and recommended next action.

## 7. New Problems Discovered During Re-Test

Do not hide regressions.

## 8. Positive Findings

What is currently working particularly well.

## 9. Coverage Gaps

Anything that could not be meaningfully tested.

Explain why.

## 10. Player-Experience Scorecard

Give 1–5 scores for:

- onboarding
- controls
- movement
- camera
- UI
- inventory
- pal management
- gathering
- crafting
- building
- combat
- catching
- navigation
- world readability
- visual cohesion
- audio/feedback
- progression clarity
- night gameplay
- controller experience
- overall fun

Include one sentence explaining every score of 3 or below.

## 11. Final Player Questions

Answer directly:

- Would you voluntarily keep playing after this build?
- Would you trust the controls?
- Would you trust the UI?
- Can a new player understand the game without developer knowledge?
- Can the player reliably navigate?
- Is combat readable?
- Is catching satisfying?
- Does building feel usable?
- Does the world feel intentional?
- What still screams "prototype"?
- What is currently the strongest part of the game?
- What are the next five highest-value improvements?

---

# 46. CREATE A REUSABLE PLAYER-JOURNEY TEST

Update or create a repeatable full-game player-journey smoke test.

Its purpose is to catch broad regressions in future builds.

The journey should cover:

**Fresh Game  
→ Onboarding  
→ NPC Interaction  
→ Exploration  
→ Navigation  
→ Resource Gathering  
→ Inventory  
→ Crafting  
→ Wild Encounter  
→ Combat  
→ Catching  
→ Party Management  
→ Consumable Use  
→ Building  
→ More Exploration  
→ Additional Combat  
→ Day/Night  
→ Navigation Back to Known Area  
→ Save  
→ Reload  
→ Continue Playing**

Where possible automate deterministic checks.

Where judgment is required, explicitly require screenshots and player-experience review.

**Important:** this reusable smoke test does not authorize future execution of the full owner-only audit described by this document. Any future comprehensive blind playtest still requires a new explicit owner instruction.

---

# 47. DO NOT DECLARE SUCCESS TOO EARLY

Continue testing after the first obvious problems are fixed.

A full pass is not complete because one critical system works.

The game consists of interconnected systems, and repairs can introduce regressions elsewhere.

Do at least one meaningful post-fix playthrough.

---

# 48. CORE PRINCIPLE

Never ask:

> "Does the code appear to support this?"

Ask:

> "Can a player actually do this comfortably, reliably, and understand what happened?"

Never ask:

> "Does the UI technically render?"

Ask:

> "Can I successfully use it with a controller without fighting it?"

Never ask:

> "Does the minimap update?"

Ask:

> "Can I navigate using it?"

Never ask:

> "Does an animation play?"

Ask:

> "Does this movement look believable and feel good?"

Never ask:

> "Is there a tutorial?"

Ask:

> "Did it successfully teach me?"

Never ask:

> "Was a screenshot taken?"

Ask:

> "Would this screenshot let the owner understand what I experienced?"

---

# 49. THE STANDARD

The standard is:

> A first-time player should be able to start Tetherbound, learn how to play, explore confidently, understand the world, interact with NPCs, gather resources, manage inventory, use items, craft, build, fight, catch pals, manage their party, navigate through day and night, save their progress, return later, and continue playing without needing knowledge of the implementation.

Test the game like a player.

Document everything.

Do not inspect the implementation until the blind test is complete.

Find problems independently.

Preserve the original blind findings.

Fix root causes.

Replay the game.

Capture evidence.

Package the screenshots and reports into a downloadable ZIP.

Then give an unvarnished assessment of whether the build is actually fun and trustworthy to play.

**This full test ends when this authorized run is complete. Do not schedule, self-chain, or automatically repeat it. A future full run requires a new explicit instruction from the project owner.**
