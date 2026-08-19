# Ralph Active Game Plan — Meadows to an enjoyable full chapter

**Status:** ACTIVE owner-directed execution plan.

This file controls the **order in which current Meadows work is selected**.

`ralph/BACKLOG.md` remains the complete project ledger and no task in it is deleted, invalidated, or forgotten by this plan. `docs/ralph-prompts/` remains the detailed prompt library. This file changes the execution model from a flat defect/content queue into gameplay gates and finished regional packages.

If an older instruction says simply “take the next item from the top of BACKLOG.md,” use this file to determine the active Meadows priority first. Then use BACKLOG/DONE/current `main` to determine whether the child task is still open, already shipped, blocked, or needs verification.

Read first:

1. `CLAUDE.md`
2. `docs/TETHERBOUND_GAME_VISION.md`
3. this file
4. `ralph/OWNER_PLAYTEST_2026-08-18.md`
5. `ralph/planning/MEADOWS_QUALITY_REBUILD_PLAN.md`
6. relevant detailed prompt(s)
7. current `main` + relevant BACKLOG/DONE history

---

# 0. Core execution rule

The unit of progress is no longer “one more feature exists.”

The unit of progress is:

> **a continuously playable segment of the Meadows now produces the intended Tetherbound experience.**

Existing tasks are children of gameplay packages. A child may ship independently, but the owning package is not complete until the whole segment plays correctly.

Do not delete or silently close child tasks because the package exists. Preserve the ledger. A child is closed only when its own acceptance criteria are actually satisfied on `main`.

Do not wait for owner approval between gates. The old owner-blocking play gates remain retired. These are **evidence gates** Ralph/Claude executes itself using real gameplay, tests, renders, capture tooling and target-hardware checks where available.

If a true unresolved design choice appears, ask. Otherwise make the current documented game real.

---

# 1. ACTIVE ORDER

## GATE A — Trustworthy core verbs

**Goal:** a 30-minute session can use the main verbs repeatedly without freezes, broken state, major control friction, or obviously unfinished interactions.

Finish/reconcile these before spending significant effort on distant content:

### Input / modal / save / UI stability
- `01-RG1-post-modal-freeze.md`
- `03-RG6-controller-ui-input-audit.md`
- `04-RG7-save-position-and-progression-persistence.md`
- `05-RG8-combat-camera-follow-and-control.md`
- `10-RG3-always-visible-exploration-control-legend.md`
- `13-RG14-verify-build-placement-control-strip.md`
- `20-EV9-title-screen-and-orb-count-mounts.md`
- `27-RG25-title-save-select-quit-and-boot-measurement.md`
- `32-PT17-test-rename-flow-trigger.md`
- `33-TEST2-close-false-positive-test-gaps.md`
- `34-CI-BOSS-fix-intermittent-boss-verification.md`
- `39-RG1-owner-playtest-modal-freeze-reopen.md`
- `54-RG25-owner-confirmed-title-screen-missing.md`

### Building must feel usable
- `02-RG4-build-placement-confirmation.md` — verify old confirm bug stays fixed
- `40-BUILD-valheim-repeat-placement.md`
- `41-BUILD-dismantle-full-refund.md`
- `42-BUILD-modular-snap-contract.md`

### Gathering / tool handling
- `44-GATHER-equipped-tool-swing-and-pickup-feedback.md`

### Creature handling / care / catching
- `43-CREATURE-BED-gradual-overnight-rest.md`
- `45-CATCH-over-shoulder-aim-and-throw.md`
- `48-PARTY-cycle-pals-in-world.md`

### World interaction reliability required for basic travel
- `09-RG23-world-collision-consistency.md`
- `14-RG15-minimap-movement-up-and-full-map-navigation.md` — verify orientation, preserve working behavior
- `50-WORLD-usable-building-doors.md`
- `51-TORCH-upright-hand-and-re-equip-light.md`
- `52-MAP-all-authored-trails-visible.md`

### Presentation that affects basic play readability
- `07-RG21-continuous-day-night-short-night.md`
- `08-RG22-verify-current-torch-lighting.md` — superseded where needed by 51
- `18-NIGHT-REJUDGE-verify-current-night-lighting.md`
- `49-POND-real-water.md`

### Representative opening environment baseline
- `71-GATEA-opening-environment-baseline.md`

Gate A does **not** own final whole-Meadows ecology or vegetation tuning. It does require the opening/village/pond area to be representative enough to judge the real game without debug spawning, teleporting, or a sterile test environment.

For Gate A:

- preserve the dense pond-side vegetation as an approved lush reference;
- preserve/create nearby broad open grassy stretches with long sightlines;
- do not use one global vegetation density;
- keep trails readable and ordinary traversal clear;
- ensure multiple wild creatures and useful early gatherables are naturally available during normal opening-area travel;
- do not carpet every field with creatures/resources merely to make testing convenient;
- defer final habitat composition, chapter-wide creature density, trainer/resource cadence, and region-specific world composition to Gate C and regional packages D1–D5.

### Gate A evidence
Run a continuous representative session that:

- launches through the title/front door;
- loads/starts correctly;
- travels through both a representative broad/open meadow stretch and the approved lush pond-side pocket;
- naturally encounters multiple wild creatures and useful early gatherables without debug spawning/teleporting;
- talks to NPCs and exits menus repeatedly;
- catches a wild creature;
- cycles creatures;
- gathers with an equipped tool and visible action;
- opens Build, places repeated pieces, constructs a simple 2x2 house with roof/door, dismantles a piece, exits Build and resumes play;
- uses player/creature rest interactions;
- draws/holsters/redraws the torch;
- travels using map/minimap;
- saves/reloads and resumes correctly.

For environment changes, capture both an open-field view and a lush pond-side view, run visual-judge, and verify no material target-performance regression from density changes.

Do not advance because every child has a commit. Advance when the session survives, the verbs are credible, and the environment is representative enough to judge the actual game.

---

## GATE B — Prove Tetherbound in the first session

**Owning prompt:** `56-OPENING-first-session-to-tournament.md`

**Goal:** waking at Grandpa’s house through winning the village tournament feels like a small complete game.

Children / dependencies:

- `17-RG18-guided-opening-core-loop-ladder.md`
- `15-RG16-tournament-first-objective-and-eastbound-progression.md`
- `25-RG19-spec-creature-condition-model.md`
- `26-RG19-build-village-tournament.md`
- `12-RG13-progressive-crafting-and-building-unlocks.md`
- `43-CREATURE-BED-gradual-overnight-rest.md`
- `44-GATHER-equipped-tool-swing-and-pickup-feedback.md`
- `45-CATCH-over-shoulder-aim-and-throw.md`
- `47-CREATURE-level-up-feedback.md`
- `48-PARTY-cycle-pals-in-world.md`
- `54-RG25-owner-confirmed-title-screen-missing.md`
- `68-CHAPTER-complete-objective-chain.md` for opening objectives
- `57-TEAM-progression-curve.md`
- `58-REWARD-resource-economy.md`
- `59-TRAINER-journey.md` for local trainers/tournament opponents
- `60-WILD-ecology-journey.md` for starting habitats
- `61-EXPEDITION-rest-rhythm.md` for first care/rest proof
- `67-FIVE-creature-pressure-and-bond.md` for attachment basics
- `71-GATEA-opening-environment-baseline.md` as the minimum representative starting-world baseline inherited by the first-session pass

### Gate B evidence
Fresh save, continuous play:

wake → Grandpa → starter → naming → first wild fight/catch → build a team → train → gather → build small home → creature bed → player bed/sleep → tournament readiness → tournament → win → objective to leave for South Bridge.

Pass only when:

- the player always understands the current goal;
- there are enough nearby creatures/fights to prepare naturally;
- at least one level-up is clearly communicated;
- building the tiny home is pleasant and fast enough;
- creature care has a visible purpose;
- the tournament feels like the payoff for learning the loop;
- no major system requires external instructions.

---

## GATE C — Build the progression/reward/ecology backbone

These are cross-chapter systems and content maps that every regional package inherits.

Owning prompts:

- `57-TEAM-progression-curve.md`
- `58-REWARD-resource-economy.md`
- `59-TRAINER-journey.md`
- `60-WILD-ecology-journey.md`
- `61-EXPEDITION-rest-rhythm.md`
- `67-FIVE-creature-pressure-and-bond.md`
- `68-CHAPTER-complete-objective-chain.md`

Existing children:

- `06-RG20-meadows-wild-creature-population.md`
- `11-RG12-tm-type-colored-orbs.md`
- `12-RG13-progressive-crafting-and-building-unlocks.md`
- `25-RG19-spec-creature-condition-model.md`
- `29-PW2-alpha-elder-wild-variants.md`
- `30-CONTENT-ACTIVITIES-meadows-optional-activities.md`
- `31-CONTENT-HOME-home-evolves-with-progression.md`
- `35-SH54-creature-credit-audit.md`
- `46-CREATURE-release-ceremony.md`
- `47-CREATURE-level-up-feedback.md`
- `53-MEADOWS-pokemon-first-core-loop-density.md` — integration standard, not one giant implementation item
- `71-GATEA-opening-environment-baseline.md` — minimum opening baseline only; Gate C owns the chapter-wide ecology expansion/tuning beyond it

Gate C does not need to be a single long serial block. These can run in parallel with regional authoring once Gate B proves the base game, but the chapter-wide maps/curves must exist before late-region tuning is called final.

---

## GATE D1 — Finished Lower Meadows

**Owning prompt:** `62-BAND1-finished-lower-meadows.md`

Children / related existing tasks:

- `06-RG20-meadows-wild-creature-population.md`
- `15-RG16-tournament-first-objective-and-eastbound-progression.md`
- `16-RG17-continuous-tether-pylon-navigation-spine.md` — post-tournament route continuity where applicable
- `19-STORM-GATE-two-grunts-guard-bridge.md` only if its physical crossing lies on the active route later; do not mis-site it into Lower Meadows
- `24-SPINE-LAYOUT-route-around-warrens-with-shortcut.md` for macro route coherence, as applicable
- `30-CONTENT-ACTIVITIES-meadows-optional-activities.md`
- `49-POND-real-water.md`
- `50-WORLD-usable-building-doors.md`
- `52-MAP-all-authored-trails-visible.md`
- `53-MEADOWS-pokemon-first-core-loop-density.md`
- `59-TRAINER-journey.md`
- `60-WILD-ecology-journey.md`
- `61-EXPEDITION-rest-rhythm.md`
- `68-CHAPTER-complete-objective-chain.md`
- `71-GATEA-opening-environment-baseline.md` as the protected opening composition baseline; D1 owns final Lower Meadows tuning beyond it

Evidence run:

tournament victory → explore Lower Meadows → meaningful wild/trainer/resource choices → optional detour → reach/earn/open South Bridge.

---

## GATE D2 — Finished Quarry / Warrens

**Owning prompt:** `63-BAND2-finished-quarry-warrens.md`

Children / related existing tasks:

- `06-RG20-meadows-wild-creature-population.md`
- `12-RG13-progressive-crafting-and-building-unlocks.md`
- `24-SPINE-LAYOUT-route-around-warrens-with-shortcut.md`
- `28-MQ3-decompose-and-author-bands-3-to-5.md` only for shared/decomposition infrastructure; Band 2 remains an explicit finished package here
- `29-PW2-alpha-elder-wild-variants.md`
- `30-CONTENT-ACTIVITIES-meadows-optional-activities.md`
- `53-MEADOWS-pokemon-first-core-loop-density.md`
- `57-TEAM-progression-curve.md`
- `58-REWARD-resource-economy.md`
- `60-WILD-ecology-journey.md`
- `61-EXPEDITION-rest-rhythm.md`
- `68-CHAPTER-complete-objective-chain.md`

Evidence run:

South Bridge → quarry → Rootstone discovery/use → Burrow Warrens → guardian → optional deep branch/special encounter → clear handoff toward river.

---

## GATE D3 — Finished River / Relay

**Owning prompt:** `64-BAND3-finished-river-relay.md`

Children / related existing tasks:

- `06-RG20-meadows-wild-creature-population.md`
- `19-STORM-GATE-two-grunts-guard-bridge.md` if this crossing’s canonical placement belongs in/near this regional package
- `23-BILLBOARD-WHITE-fix-storm-road-white-billboards.md`
- `28-MQ3-decompose-and-author-bands-3-to-5.md`
- `29-PW2-alpha-elder-wild-variants.md`
- `30-CONTENT-ACTIVITIES-meadows-optional-activities.md`
- `53-MEADOWS-pokemon-first-core-loop-density.md`
- `57-TEAM-progression-curve.md`
- `58-REWARD-resource-economy.md`
- `59-TRAINER-journey.md`
- `60-WILD-ecology-journey.md`
- `61-EXPEDITION-rest-rhythm.md`
- `68-CHAPTER-complete-objective-chain.md`

Evidence run:

Warrens exit → living river region → crossing problem → meaningful wild/resource/trainer cadence → Tether Relay escalation → Captain Vance → rescue captive → restore crossing.

---

## GATE D4 — Finished Upper Meadows

**Owning prompt:** `65-BAND4-finished-upper-meadows.md`

Children / related existing tasks:

- `06-RG20-meadows-wild-creature-population.md`
- `24-SPINE-LAYOUT-route-around-warrens-with-shortcut.md` for macro route/reconnects where still relevant
- `28-MQ3-decompose-and-author-bands-3-to-5.md`
- `29-PW2-alpha-elder-wild-variants.md`
- `30-CONTENT-ACTIVITIES-meadows-optional-activities.md`
- `31-CONTENT-HOME-home-evolves-with-progression.md`
- `53-MEADOWS-pokemon-first-core-loop-density.md`
- `57-TEAM-progression-curve.md`
- `58-REWARD-resource-economy.md`
- `59-TRAINER-journey.md`
- `60-WILD-ecology-journey.md`
- `61-EXPEDITION-rest-rhythm.md`
- `67-FIVE-creature-pressure-and-bond.md`
- `68-CHAPTER-complete-objective-chain.md`

Evidence run:

cross river → discover/use Ironwood tier → stronger ecology → Meadowhart/riding payoff → captain routes → 3 Sigils → open final approach.

---

## GATE D5 — Finished Stronghold Approach

**Owning prompt:** `66-BAND5-finished-stronghold-approach.md`

Children / related existing tasks:

- `16-RG17-continuous-tether-pylon-navigation-spine.md`
- `19-STORM-GATE-two-grunts-guard-bridge.md`
- `21-STRONGHOLD-MAT-verify-and-fix-stronghold-materials.md`
- `22-SKY-PLANES-remove-stronghold-sky-geometry-artifacts.md`
- `23-BILLBOARD-WHITE-fix-storm-road-white-billboards.md`
- `28-MQ3-decompose-and-author-bands-3-to-5.md`
- `29-PW2-alpha-elder-wild-variants.md`
- `53-MEADOWS-pokemon-first-core-loop-density.md`
- `57-TEAM-progression-curve.md`
- `59-TRAINER-journey.md`
- `60-WILD-ecology-journey.md`
- `61-EXPEDITION-rest-rhythm.md`
- `67-FIVE-creature-pressure-and-bond.md`
- `68-CHAPTER-complete-objective-chain.md`

Evidence run:

Sigil gate → final route → increasingly occupied/drained land → wild/trainer/resource pressure → clear final camp/preparation opportunity → enter Meadows Hall.

---

## GATE E — Stronghold chapter finale

**Owning prompt:** `69-STRONGHOLD-chapter-finale.md`

Children / related existing tasks:

- `21-STRONGHOLD-MAT-verify-and-fix-stronghold-materials.md`
- `22-SKY-PLANES-remove-stronghold-sky-geometry-artifacts.md`
- `34-CI-BOSS-fix-intermittent-boss-verification.md`
- `46-CREATURE-release-ceremony.md`
- `67-FIVE-creature-pressure-and-bond.md`
- `68-CHAPTER-complete-objective-chain.md`
- current Warden/legendary/tether/world-healing backlog items in `ralph/BACKLOG.md`, even if they predate the 54-prompt review library

Evidence run:

Hall entrance → trainer gauntlet → recovery opportunity → elite → Warden → tether reveal → free legendary → join offer → release ceremony if full → world healing/state change → post-win acknowledgment.

---

## GATE F — Full Meadows integration / pacing / performance

**Owning prompt:** `70-MEADOWS-full-chapter-integration-playthrough.md`

Children / related existing tasks:

- `36-R9.1-scope-input-combat-catch-camera-polish.md`
- `37-R9.2-scope-ally-controller-ui-readability.md`
- `38-R9.3-scope-target-hardware-performance.md`
- all remaining verify-first visual/reliability remainders from 1–54 and the Gate A baseline 71
- chapter-wide tuning from 55–69
- every still-open Meadows item in `ralph/BACKLOG.md`

This is the 3–4 hour end-to-end pass. Tune:

- XP curve;
- trainer difficulty;
- wild levels/population;
- resource availability;
- travel time;
- encounter density;
- camp/rest usefulness;
- objective clarity;
- reward economy;
- visual composition;
- target-hardware performance;
- remove dead walking.

Do not cut required chapter beats merely to hit the clock.

---

# 2. NEW OWNING PROMPTS

The following prompts convert the vision into finished-game packages:

- `55-MEADOWS-gameplay-assembly-master.md`
- `56-OPENING-first-session-to-tournament.md`
- `57-TEAM-progression-curve.md`
- `58-REWARD-resource-economy.md`
- `59-TRAINER-journey.md`
- `60-WILD-ecology-journey.md`
- `61-EXPEDITION-rest-rhythm.md`
- `62-BAND1-finished-lower-meadows.md`
- `63-BAND2-finished-quarry-warrens.md`
- `64-BAND3-finished-river-relay.md`
- `65-BAND4-finished-upper-meadows.md`
- `66-BAND5-finished-stronghold-approach.md`
- `67-FIVE-creature-pressure-and-bond.md`
- `68-CHAPTER-complete-objective-chain.md`
- `69-STRONGHOLD-chapter-finale.md`
- `70-MEADOWS-full-chapter-integration-playthrough.md`

`55` is the integration contract. `56`–`69` own concrete gameplay packages. `70` is the final end-to-end acceptance/tuning pass.

Supporting current prompt:

- `71-GATEA-opening-environment-baseline.md` — minimum representative opening-world baseline required before Gate A can be trusted; not a replacement for the later ecology/regional packages.

---

# 3. COMPLETE MAPPING OF CURRENT CHILD PROMPTS

Nothing from the existing prompt library is lost. This table names the primary new gate/package that owns or consumes the original `01`–`54` set plus current supporting prompt `71`.

| Existing prompt | Primary placement |
|---|---|
| 01 RG1 post-modal freeze | Gate A |
| 02 RG4 build placement confirmation | Gate A |
| 03 RG6 controller/UI audit | Gate A |
| 04 RG7 save position/progression | Gate A |
| 05 RG8 combat camera | Gate A |
| 06 RG20 wild creature population | Gate C + regional packages |
| 07 RG21 day/night | Gate A + regional verification |
| 08 RG22 torch verify | Gate A |
| 09 RG23 collision | Gate A |
| 10 RG3 control legend | Gate A |
| 11 RG12 TM orbs | Gate C reward/progression |
| 12 RG13 progressive unlocks | Gates B/C/D |
| 13 RG14 build control strip | Gate A |
| 14 RG15 minimap/full map | Gate A + regional navigation |
| 15 RG16 tournament-first objective | Gate B/D1 |
| 16 RG17 pylon navigation spine | D1/D5 as route fiction requires |
| 17 RG18 guided opening ladder | Gate B |
| 18 NIGHT-REJUDGE | Gate A visual verification |
| 19 STORM-GATE | canonical regional package, likely D3/D5; inspect placement |
| 20 EV9 title/HUD mounts | Gate A |
| 21 STRONGHOLD-MAT | D5/E |
| 22 SKY-PLANES | D5/E |
| 23 BILLBOARD-WHITE | D3/D5 visual cleanup |
| 24 SPINE-LAYOUT | regional world-layout packages |
| 25 RG19 creature condition | B/C/61 |
| 26 RG19 tournament | B |
| 27 RG25 boot/title/save/quit | A |
| 28 MQ3 Bands 3–5 content | D3/D4/D5 shared content infrastructure |
| 29 PW2 alpha/elder | C + D1–D5 |
| 30 CONTENT-ACTIVITIES | C + D1–D5 |
| 31 CONTENT-HOME | C/61/67 |
| 32 PT17 rename regression | A |
| 33 TEST2 false-positive gaps | A/F |
| 34 CI-BOSS | A/E/F |
| 35 SH54 creature-generation audit | C, preserve production constraints |
| 36 R9.1 input/combat/catch polish | F after concrete Gate A/B work |
| 37 R9.2 Ally UI polish | F |
| 38 R9.3 performance | F, with per-region checks earlier |
| 39 RG1 owner-play freeze reopen | A |
| 40 persistent repeat placement | A |
| 41 dismantle/full refund | A |
| 42 modular snap contract | A |
| 43 gradual overnight creature bed | A/B/61 |
| 44 equipped tool/swing/pickup feedback | A/B |
| 45 over-shoulder catch aim | A/B |
| 46 release ceremony | 67/E |
| 47 level-up feedback | B/C/57 |
| 48 party cycle in world | A/B |
| 49 pond water | A/D1 |
| 50 usable building doors | A/D1 world completeness |
| 51 torch hand/re-equip | A |
| 52 map trails | A + D regional navigation |
| 53 Meadows core-loop density | master integration standard under 55, consumed by every region |
| 54 title screen confirmed missing | A |
| 71 opening environment baseline | A/B; protected baseline inherited by D1, with final ecology/composition owned later |

Any legacy Meadows item in `ralph/BACKLOG.md` not represented in this table remains live in the ledger. When it touches one of the gameplay packages, execute it inside the relevant package; otherwise leave it in place for normal processing. **Never delete a task merely because this plan did not list its old ID.**

---

# 4. Parallelism rules

The gates define experience order, not one-thread-only implementation.

Within a gate, run parallel lanes when file ownership permits. Examples:

- modal/input freeze work can run beside build snapping if files do not conflict;
- trainer journey design/data can run beside wild ecology design/data;
- a regional environment lane can run beside its trainer lane if the coordinate contract is shared and file exclusions are explicit;
- visual verification can run while unrelated gameplay systems are implemented.

Do not parallelize two lanes that independently invent the same regional composition, reward curve, objective sequence, or coordinate plan. Owning prompts settle those contracts first.

A discovered prerequisite gets its own parallel lane when possible; it does not silently steal the owning package’s priority.

---

# 5. Evidence gate template

For each segment, record:

## Player purpose
- What is the player trying to accomplish?
- What visible challenge are they becoming ready for?

## Team progression
- Starting party composition/levels/condition.
- Ending party composition/levels/condition.
- Did a meaningful catch/switch/roster decision occur?

## World interaction
- Wild encounters.
- Trainers.
- resources/gathering.
- optional detours.
- camp/rest opportunities.
- objective transitions.

## Empty travel
- Longest interval of travel without a meaningful gameplay or visual pull.
- Whether that interval was intentional breathing room or dead traversal.

## Reliability
- freezes/input loss;
- broken gates;
- bad collision;
- save/load failures;
- controller failures.

## Presentation
- region identity;
- open vs lush composition;
- landmark readability;
- night/day usability;
- UI readability.

## Decision
PASS only if the segment produces the intended game experience. Otherwise fix the highest-impact cause and replay the segment.

---

# 6. Definition of Meadows completion

The active plan is complete only when a fresh end-to-end run demonstrates:

- a strong opening-to-tournament first session;
- a coherent team progression/reward economy;
- desirable wild creatures across every region;
- an authored trainer escalation ladder;
- useful resource progression;
- natural expedition/rest decisions;
- real five-creature roster pressure;
- distinct finished regional loops;
- clear objectives without a giant quest engine;
- a strong final approach and Warden climax;
- a meaningful legendary/release decision;
- visible post-Warden world healing;
- 3–4 hour focused pacing without cutting required beats;
- acceptable ROG Ally/Windows performance;
- no major core-verb reliability failures.

When this is true, the repository has not merely implemented the Meadows systems. It has built the Meadows game.