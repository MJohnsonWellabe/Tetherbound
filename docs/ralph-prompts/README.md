# Meadows Ralph Prompt Library — execution index

## Latest owner playtest overrides — read first

Before executing any prompt below, read `ralph/OWNER_PLAYTEST_2026-08-18.md`.

That file records the owner's newest live ROG play feedback and **supersedes older prompt assumptions where they conflict**. In particular it reopens/expands modal freezes and torch reliability, changes creature-bed recovery to gradual overnight physical rest, changes building to persistent Valheim-style placement plus dismantling/modular snapping, makes catching aim a concrete near-term problem, confirms the title screen is still absent, records minimap movement-up as verify-first while trail coverage remains broken, and locks Meadows world composition to a mix of lush dense pockets and broad open fields.

P0 items in that playtest overlay take priority over lower-priority content/polish work in this index.

This folder contains one implementation/scoping prompt for every one of the 38 items on the owner's Meadows review board.

**Important:** numeric filename prefixes record the order these prompts were authored in ChatGPT, not the original review-board priority. Execute/reference them using the board-order index below.

| Board # | Board item | Prompt file |
|---:|---|---|
| 1 | RG1 | `01-RG1-post-modal-freeze.md` |
| 2 | RG4 | `02-RG4-build-placement-confirmation.md` |
| 3 | RG6 | `03-RG6-controller-ui-input-audit.md` |
| 4 | RG7 | `04-RG7-save-position-and-progression-persistence.md` |
| 5 | RG8 | `05-RG8-combat-camera-follow-and-control.md` |
| 6 | RG20 | `06-RG20-meadows-wild-creature-population.md` |
| 7 | RG23 | `09-RG23-world-collision-consistency.md` |
| 8 | RG3 | `10-RG3-always-visible-exploration-control-legend.md` |
| 9 | RG12 | `11-RG12-tm-type-colored-orbs.md` |
| 10 | RG13 | `12-RG13-progressive-crafting-and-building-unlocks.md` |
| 11 | RG14 | `13-RG14-verify-build-placement-control-strip.md` |
| 12 | RG15 | `14-RG15-minimap-movement-up-and-full-map-navigation.md` |
| 13 | EV9 | `20-EV9-title-screen-and-orb-count-mounts.md` |
| 14 | RG16 | `15-RG16-tournament-first-objective-and-eastbound-progression.md` |
| 15 | RG17 | `16-RG17-continuous-tether-pylon-navigation-spine.md` |
| 16 | RG18 | `17-RG18-guided-opening-core-loop-ladder.md` |
| 17 | NIGHT-REJUDGE | `18-NIGHT-REJUDGE-verify-current-night-lighting.md` |
| 18 | RG21 | `07-RG21-continuous-day-night-short-night.md` |
| 19 | RG22-bright | `08-RG22-verify-current-torch-lighting.md` |
| 20 | STORM-GATE | `19-STORM-GATE-two-grunts-guard-bridge.md` |
| 21 | STRONGHOLD-MAT | `21-STRONGHOLD-MAT-verify-and-fix-stronghold-materials.md` |
| 22 | SKY-PLANES | `22-SKY-PLANES-remove-stronghold-sky-geometry-artifacts.md` |
| 23 | BILLBOARD-WHITE | `23-BILLBOARD-WHITE-fix-storm-road-white-billboards.md` |
| 24 | SPINE-LAYOUT | `24-SPINE-LAYOUT-route-around-warrens-with-shortcut.md` |
| 25 | RG19-spec | `25-RG19-spec-creature-condition-model.md` |
| 26 | RG19-build | `26-RG19-build-village-tournament.md` |
| 27 | RG25-perf | `27-RG25-title-save-select-quit-and-boot-measurement.md` |
| 28 | MQ3 | `28-MQ3-decompose-and-author-bands-3-to-5.md` |
| 29 | PW2 | `29-PW2-alpha-elder-wild-variants.md` |
| 30 | CONTENT-ACTIVITIES | `30-CONTENT-ACTIVITIES-meadows-optional-activities.md` |
| 31 | CONTENT-HOME | `31-CONTENT-HOME-home-evolves-with-progression.md` |
| 32 | PT-17-test | `32-PT17-test-rename-flow-trigger.md` |
| 33 | TEST2 | `33-TEST2-close-false-positive-test-gaps.md` |
| 34 | CI-BOSS | `34-CI-BOSS-fix-intermittent-boss-verification.md` |
| 35 | SH54 | `35-SH54-creature-credit-audit.md` |
| 36 | R9.1 | `36-R9.1-scope-input-combat-catch-camera-polish.md` |
| 37 | R9.2 | `37-R9.2-scope-ally-controller-ui-readability.md` |
| 38 | R9.3 | `38-R9.3-scope-target-hardware-performance.md` |

## Important dependency/order notes

- **RG19-spec must precede RG19-build.** The build prompt deliberately refuses to invent rested/fed/happy semantics.
- **EV9 and RG25 share the title/save-select front door.** Reuse one implementation; EV9 owns branded presentation/HUD remainder, RG25 owns current performance measurement and exit/session behavior.
- **NIGHT-REJUDGE is verification.** RG21 owns continuous cycle/timing; RG22 owns torch verification after final night.
- **STRONGHOLD-MAT, SKY-PLANES and BILLBOARD-WHITE are reproduce-first.** Current `main` may already contain partial/full fixes; evidence of an already-correct build is a valid result.
- **MQ3 is an umbrella/decomposition prompt.** It should create/execute concrete Band 3–5 work rather than land one giant content blob.
- **PW2 and CONTENT-ACTIVITIES should be sited as MQ3 fills later bands**, without duplicating band work.
- **R9.1/R9.2/R9.3 are deliberately scoping/measurement passes.** The original board entries are placeholders, so these prompts turn them into evidence-based final polish queues rather than inventing unspecified features.

## Execution rule

For every prompt, inspect current `main` before changing code. Where the prompt says verify-first, an evidence-backed "already fixed" is a successful outcome. Preserve newer owner decisions over older backlog wording, and follow `CLAUDE.md`, `ralph/conventions.md`, and current canonical decision/spec docs.