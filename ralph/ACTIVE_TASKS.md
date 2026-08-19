# Active Tasks — compact Meadows manifest

**Current gate:** Gate A — Trustworthy core verbs.

This is a compact manifest, not a replacement for `ralph/ACTIVE_GAME_PLAN.md` or `ralph/BACKLOG.md`.

On every coordinator restart, reconcile these entries against current `main`, current owner evidence, `DONE.md`, and CI before launching work. `RECONCILE` means “determine whether this is already fixed, still broken, or partly complete.”

## Gate A — canonical current work

| Area | Canonical prompt(s) | State on restart | Gate-A proof |
|---|---|---|---|
| Modal/input freezes | `39-RG1-owner-playtest-modal-freeze-reopen.md` + older `01-RG1-post-modal-freeze.md` | RECONCILE | Repeated Innkeeper, bed, Build, menus return to world control; no freeze/input loss |
| Controller UI | `03-RG6-controller-ui-input-audit.md` | RECONCILE | All reachable menus/dialogue/settings work by controller |
| Save/load | `04-RG7-save-position-and-progression-persistence.md` | RECONCILE | Exact position/facing/story state survive save/load |
| Combat camera | `05-RG8-combat-camera-follow-and-control.md` | RECONCILE | Camera follows active creature with normal orbit control and returns correctly |
| Exploration control legend | `10-RG3-always-visible-exploration-control-legend.md` | RECONCILE | Major verbs readable without opening another screen |
| Build placement base regression | `02-RG4-build-placement-confirmation.md` | VERIFY | Base placement still works; do not regress it |
| Build repeat placement | `40-BUILD-valheim-repeat-placement.md` | RECONCILE | Selected piece remains active until cancel/change |
| Build dismantle | `41-BUILD-dismantle-full-refund.md` | RECONCILE | Player-built structures can be targeted/dismantled with full refund |
| Build modular snapping | `42-BUILD-modular-snap-contract.md` | RECONCILE | 2×2 floor + aligned walls + doorway + roof can be built cleanly |
| Build HUD controls | `13-RG14-verify-build-placement-control-strip.md` | VERIFY | Place/rotate/snap/cancel readable during placement |
| Gathering/tool feel | `44-GATHER-equipped-tool-swing-and-pickup-feedback.md` | RECONCILE | Correct tool equipped, visible swing/hit, drops, `+X` pickup feedback |
| Creature bed/recovery | `43-CREATURE-BED-gradual-overnight-rest.md` | RECONCILE | Creature visibly rests, gradually heals, unavailable while resting, overnight completion matters |
| Catch aiming/throw | `45-CATCH-over-shoulder-aim-and-throw.md` | RECONCILE | Hold aim → controlled camera/reticle/trajectory → physical throw/cancel |
| Party cycling | `48-PARTY-cycle-pals-in-world.md` | RECONCILE | Previous/next creature works in exploration without menu trip |
| Collision | `09-RG23-world-collision-consistency.md` | RECONCILE | Solid-looking major geometry collides; empty-looking space does not |
| Minimap/full map | `14-RG15-minimap-movement-up-and-full-map-navigation.md` | VERIFY/FIX | Preserve movement-up; full map works |
| Map trails | `52-MAP-all-authored-trails-visible.md` | RECONCILE | Meaningful authored trails appear consistently |
| Usable building doors | `50-WORLD-usable-building-doors.md` | RECONCILE | Normal usable-looking doors open or clearly communicate lock state |
| Torch reliability | `51-TORCH-upright-hand-and-re-equip-light.md` | RECONCILE | Torch held flame-up; holster/redraw repeatedly restores light |
| Day/night | `07-RG21-continuous-day-night-short-night.md` | VERIFY/FIX | Continuous 10-minute cycle with short real night remains correct |
| Night readability | `18-NIGHT-REJUDGE-verify-current-night-lighting.md` + `08-RG22-verify-current-torch-lighting.md` | VERIFY | Night reads as night and remains playable with genuinely equipped torch |
| Pond water | `49-POND-real-water.md` | RECONCILE | Pond is actual readable water; preserve approved lush vegetation pocket |
| Opening environment baseline | `71-GATEA-opening-environment-baseline.md` | RECONCILE | Opening/village/pond area naturally supplies multiple wild encounters and early resources; preserves lush pond pocket plus broad open sightline areas without global densification |
| Title/front door | `54-RG25-owner-confirmed-title-screen-missing.md` + `27-RG25-title-save-select-quit-and-boot-measurement.md` + `20-EV9-title-screen-and-orb-count-mounts.md` | RECONCILE | Launch presents New Game / Load / Quit and branded front door |
| Rename regression | `32-PT17-test-rename-flow-trigger.md` | RECONCILE | Rename flow triggers and accepts input correctly |
| False-positive tests | `33-TEST2-close-false-positive-test-gaps.md` | RECONCILE | Tests exercise real input/state paths |
| Boss verification stability | `34-CI-BOSS-fix-intermittent-boss-verification.md` | RECONCILE | Boss verification is deterministic enough to trust |

## Gate A environment baseline — scope guard

Gate A does **not** own final whole-Meadows vegetation/ecology tuning. It only requires the real opening environment to be representative enough to judge the game honestly.

Protect these rules:

- preserve the dense pond-side vegetation as an approved lush reference;
- preserve/create nearby broad open grassy stretches with long sightlines;
- do not set one global vegetation density for the biome;
- ensure meaningful trails remain visually readable and ordinary travel is not an obstacle course;
- ensure multiple wild creatures and useful early gatherables are naturally available in the opening/village/pond area without developer spawning or unreasonable travel;
- do not solve testability by carpeting every field with creatures/resources;
- defer final habitat population, region-by-region creature density, trainer/resource cadence, and complete world composition to Gate C and regional packages D1–D5.

## Gate A evidence run

Do not advance because the table is green individually. Run one continuous representative session that:

1. launches through the title/front door;
2. starts/loads correctly;
3. travels through both a representative open meadow stretch and the approved lush pond-side pocket, with readable trails and no vegetation obstacle-course behavior;
4. naturally encounters multiple wild creatures and useful early gatherables without debug spawning/teleporting;
5. talks to NPCs and exits menus repeatedly;
6. catches a wild creature;
7. cycles creatures;
8. gathers with the equipped tool and visible action;
9. opens Build, repeat-places pieces, builds a simple 2×2 roofed house with a door, dismantles a piece, exits Build and resumes play;
10. uses creature and player rest interactions;
11. draws/holsters/redraws the torch;
12. navigates with minimap/full map;
13. saves/reloads and resumes correctly.

For environment changes, capture at least one open-field view and one lush pond-side view and run the repo visual-judge workflow. Verify that any density changes do not materially regress target performance.

**Gate A passes only when that session is reliable, the verbs are credible, and the tested environment is representative enough to judge the real game.**

## Next package after Gate A

**Gate B owner:** `docs/ralph-prompts/56-OPENING-first-session-to-tournament.md`

Fresh-save evidence path:

Grandpa → starter → naming → first wild fight/catch → build team → train → gather → small home → creature bed → player bed/sleep → tournament readiness → tournament win → clear South Bridge objective.

Do not work distant region polish ahead of Gate A/B unless it can run safely in parallel without taking resources from higher-impact active work.
