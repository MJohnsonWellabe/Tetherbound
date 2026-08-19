# Meadows Ralph Prompt Library — execution index

## ACTIVE EXECUTION — start here

The Meadows prompt library is no longer a flat queue.

Before selecting or executing current Meadows work, read:

1. `../TETHERBOUND_GAME_VISION.md`
2. `../../ralph/ACTIVE_GAME_PLAN.md`
3. `../../ralph/PROMPT_COMPATIBILITY_MAP.md`
4. `../../ralph/OWNER_PLAYTEST_2026-08-18.md`
5. the detailed prompt(s) for the active gate/package.

`ralph/ACTIVE_GAME_PLAN.md` controls current Meadows execution order. `ralph/BACKLOG.md` remains the complete task ledger, so no historical or current task is discarded merely because the active plan groups it under a gameplay package.

Prompts `55`–`70` are the new **owning gameplay-package prompts**. They do not replace prompts `01`–`54`; they assemble those child tasks into finished player experiences and require continuous evidence runs before a gameplay gate passes.

### New owning prompts

| Prompt | Ownership |
|---|---|
| `55-MEADOWS-gameplay-assembly-master.md` | Full chapter experience/integration contract |
| `56-OPENING-first-session-to-tournament.md` | Fresh launch through village tournament |
| `57-TEAM-progression-curve.md` | XP/levels/moves/traits/bond/evolution readiness curve |
| `58-REWARD-resource-economy.md` | Rewards, materials, coins, TMs, Orb/build economy |
| `59-TRAINER-journey.md` | Local trainer → Team Tether → Warden escalation ladder |
| `60-WILD-ecology-journey.md` | Wild habitats/populations/team-choice ecology across all bands |
| `61-EXPEDITION-rest-rhythm.md` | Injury, creature beds, sleep, camps and expedition pacing |
| `62-BAND1-finished-lower-meadows.md` | Tournament → South Bridge finished regional loop |
| `63-BAND2-finished-quarry-warrens.md` | Quarry/Rootstone/Warrens finished regional loop |
| `64-BAND3-finished-river-relay.md` | River/Relay/Vance/rescue finished regional loop |
| `65-BAND4-finished-upper-meadows.md` | Ironwood/riding/three captains finished regional loop |
| `66-BAND5-finished-stronghold-approach.md` | Final approach/occupation/preparation finished regional loop |
| `67-FIVE-creature-pressure-and-bond.md` | Make five total slots emotionally/mechanically real |
| `68-CHAPTER-complete-objective-chain.md` | Complete concise main objective chain + selective local requests |
| `69-STRONGHOLD-chapter-finale.md` | Hall → Warden → legendary → release → healing finale |
| `70-MEADOWS-full-chapter-integration-playthrough.md` | Final 3–4 hour end-to-end pacing/quality pass |

### Duplicate-prefix compatibility

Seven earlier `OP-*` owner-play briefs also remain in this folder with prefixes `39`–`45`. They are **preserved, not deleted**, but overlap newer canonical Phase -1.7 prompts. Use `ralph/PROMPT_COMPATIBILITY_MAP.md` to consume their unique acceptance details without executing duplicate branches/systems. Always identify these files by full filename, not number alone.

### Evidence gates, not owner waits

The gameplay gates in `ralph/ACTIVE_GAME_PLAN.md` are not the retired owner-only play gates. Ralph/Claude should run the segment itself, gather gameplay/render/test evidence, fix failures, and continue automatically when the written criteria pass. Ask the owner only for a genuinely unresolved design decision.

---

## Latest owner playtest overrides

Before executing any relevant child prompt, read `ralph/OWNER_PLAYTEST_2026-08-18.md`.

That file records the owner's newest live ROG play feedback and **supersedes older prompt assumptions where they conflict**. In particular it reopens/expands modal freezes and torch reliability, changes creature-bed recovery to gradual overnight physical rest, changes building to persistent repeat placement plus dismantling/modular snapping, makes catching aim a concrete near-term problem, confirms the title screen is still absent, records minimap movement-up as verify-first while trail coverage remains broken, and locks Meadows world composition to a mix of lush dense pockets and broad open fields.

Gate A items in the active plan take priority over lower-priority content/polish because additional content cannot compensate for broken core verbs.

## Phase -1.7 owner-play prompts

These are newer owner-play items/addenda written after the original 38-item review board. They are detailed child implementation prompts consumed by the active gameplay gates.

### P0 — correctness / blockers

| Owner item | Prompt |
|---|---|
| RG1 modal freeze reopened: innkeeper, creature bed, Build-from-main-menu | `39-RG1-owner-playtest-modal-freeze-reopen.md` |
| Build modular geometry/snap contract | `42-BUILD-modular-snap-contract.md` |
| Equipped tool + visible swing + pickup feedback | `44-GATHER-equipped-tool-swing-and-pickup-feedback.md` |
| Torch upright hand + repeated re-equip lighting | `51-TORCH-upright-hand-and-re-equip-light.md` |
| RG25/EV9 title/front door confirmed missing | `54-RG25-owner-confirmed-title-screen-missing.md` |

### P1 — build/care/catch/team experience

| Owner item | Prompt |
|---|---|
| Persistent repeat placement for every buildable | `40-BUILD-valheim-repeat-placement.md` |
| Dismantle player builds, full refund | `41-BUILD-dismantle-full-refund.md` |
| Creature bed: visible, gradual overnight rest, unavailable for combat | `43-CREATURE-BED-gradual-overnight-rest.md` |
| Over-shoulder physical catch aiming/throw | `45-CATCH-over-shoulder-aim-and-throw.md` |
| Creature release ceremony | `46-CREATURE-release-ceremony.md` |
| Creature level-up feedback | `47-CREATURE-level-up-feedback.md` |
| In-world previous/next creature cycling | `48-PARTY-cycle-pals-in-world.md` |

### P2 — world/navigation/content purpose

| Owner item | Prompt |
|---|---|
| Pond gets real water; preserve approved lush vegetation | `49-POND-real-water.md` |
| Normal-looking Meadows building doors must work | `50-WORLD-usable-building-doors.md` |
| Preserve movement-up minimap; show all meaningful authored trails | `52-MAP-all-authored-trails-visible.md` |
| Five-creature-team-first Meadows core-loop/encounter/resource/camp density | `53-MEADOWS-pokemon-first-core-loop-density.md` |

### Positive findings to protect

- **Basic structure placement now works** in the owner's current play. Do not reintroduce the old `place does nothing` defect while adding repeat placement/snapping.
- **Minimap movement-up appears to work.** Verify before touching that orientation math.
- **The dense pond-side trees/plants look great.** Preserve that lush pocket. Meadows should deliberately alternate such dense areas with broad open fields and long sightlines; do not apply one global vegetation density.

### Explicit supersessions of older prompts

- `02-RG4-build-placement-confirmation.md`: base placement is now positive evidence; `40` + `42` define the remaining owner build ask.
- `08-RG22-verify-current-torch-lighting.md`: verify-only assumption is superseded by `51`'s concrete current defects.
- `14-RG15-minimap-movement-up-and-full-map-navigation.md`: movement-up is verify-first; `52` owns current missing-trails defect.
- `25-RG19-spec-creature-condition-model.md`: `43` adds physical bed occupancy, gradual HP recovery, combat ineligibility and overnight completion to rested condition.
- `27-RG25-title-save-select-quit-and-boot-measurement.md`: `54` records that the title screen is currently missing in owner play and must actually be implemented.
- `36-R9.1-scope-input-combat-catch-camera-polish.md`: catch aim is no longer vague polish; `45` is concrete implementation work.
- `06`, `28`, `29`, `30`, `31`: coordinate through `55`–`66` so wilds, bands, alphas, activities and home/camp systems create one purposeful team-progression cadence rather than isolated content islands.

---

## Original 38-item Meadows review board

This folder also contains one implementation/scoping prompt for every one of the 38 items on the owner's earlier Meadows review board.

**Important:** numeric filename prefixes record the order these prompts were authored in ChatGPT, not current gameplay priority. Current execution priority comes from `ralph/ACTIVE_GAME_PLAN.md`.

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

- **RG19-spec must precede RG19-build.** The build prompt deliberately refuses to invent rested/fed/happy semantics. Phase -1.7 prompt `43` is part of that condition implementation and must be reconciled before tournament eligibility is considered complete.
- **EV9 and RG25 share the title/save-select front door.** Reuse one implementation; EV9 owns branded presentation/HUD remainder, RG25 owns current performance measurement and exit/session behavior. Phase -1.7 `54` confirms this is still missing.
- **NIGHT-REJUDGE is verification.** RG21 owns continuous cycle/timing. Torch brightness verification comes only after `51` fixes current equip/orientation reliability.
- **STRONGHOLD-MAT, SKY-PLANES and BILLBOARD-WHITE are reproduce-first.** Current `main` may already contain partial/full fixes; evidence of an already-correct build is a valid result.
- **MQ3 is an umbrella/decomposition prompt.** It should create/execute concrete Band 3–5 child work within the new regional packages rather than land one giant content blob.
- **PW2 and CONTENT-ACTIVITIES are consumed by regional packages**, without duplicating band work.
- **R9.1/R9.2/R9.3 remain evidence-based final polish/measurement**, with concrete current failures handled earlier by their dedicated prompts.

## Execution rule

For every prompt, inspect current `main` before changing code. Where a child prompt says verify-first, an evidence-backed `already fixed` is a successful child outcome. A gameplay package passes only when its complete evidence segment passes. Preserve newer owner decisions over older backlog wording, and follow `CLAUDE.md`, `ralph/ACTIVE_GAME_PLAN.md`, `ralph/PROMPT_COMPATIBILITY_MAP.md`, `ralph/OWNER_PLAYTEST_2026-08-18.md`, `ralph/conventions.md`, and current canonical decision/spec docs.