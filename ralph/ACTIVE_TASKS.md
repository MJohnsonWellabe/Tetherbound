# Active Tasks — compact Meadows manifest

**Current gate:** Gate A — Trustworthy core verbs.

**Active execution overlay:** `ralph/WEEKEND_MEADOWS_SPRINT_2026-08-21.md` — full playable Meadows by Sunday night. This overlay changes priority/parallelization/checkpoint cadence only; it does not remove any requirement below.

This is a compact manifest, not a replacement for `ralph/ACTIVE_GAME_PLAN.md` or `ralph/BACKLOG.md`.

On every coordinator restart, reconcile these entries against current `main`, current owner evidence, `DONE.md`, and CI before launching work. `RECONCILE` means “determine whether this is already fixed, still broken, or partly complete.”

## Newest owner playtest — 2026-08-21 ROG Ally

**Read first:** `ralph/OWNER_PLAYTEST_2026-08-21.md`.

This is newer than the 2026-08-18 owner playtest and reopens Gate A wherever current owner evidence conflicts with an older green test or prior completion claim. **Do not pass Gate A until every Gate-A-class item in this owner playtest is fixed or explicitly re-verified on the real player/ROG path.**

Fresh owner blockers include:

- severe ROG Ally lag / target-hardware performance;
- Satchel input leaking into hotbar actions;
- Build shortcut failing to transfer controller ownership, causing creature cycling instead of Build navigation;
- Settings and teleport-destination lists not scrolling by controller;
- first village trainer battle losing camera control when combat starts;
- overlapping controller bindings between companion cycling, hotbar and modal contexts;
- Load Game reaching the home/menu screen but failing to transition into a playable loaded world;
- map unreadability plus zoom not focusing usefully around the player;
- major shortcut prompts (Build/Map/etc.) needing larger, clearer placement under the hotbar;
- opening objective/direction clarity still insufficient for normal first-session play;
- village layout/spatial logic needing correction;
- building rotate not working;
- door/build/roof modular sizing and usable doors still wrong;
- free-build/free-crafting rule inconsistency;
- equipped axe hold/grip and visible chopping swing still not reading correctly in normal play;
- confusing party-cycle presentation and remaining `Pal` terminology;
- team count showing `2/5` after three creatures are caught;
- roadside signs placed in travel lanes;
- trees/houses/bushes/props incorrectly occupying pond water;
- unsafe full submersion lacking intended damage/hazard behavior;
- washed-out/grey lighting state appearing after several minutes of play;
- Stronghold and Burrow Warrens fights sometimes phasing participants outside reachable arena bounds and becoming effectively impossible;
- pond-to-village travel currently feeling long, bare and boring; retain this as Gate B/C/D1 route-content work even after Gate A's representative baseline passes;
- website/story front door needing a Team Tether / draining-the-land /
  Grandpa-too-old / player-must-step-up rewrite — **the rewrite has shipped**
  (`site/index.html`); the four frames it still wants need a Godot capture
  run and are recorded as `SITE-SHOTS` in `ralph/BACKLOG.md`.

A current owner reproduction outranks an older smoke/unit result. If a regression still passes while the owner path fails, fix the false-positive coverage gap as part of the defect.

## Gate A — canonical current work

| Area | Canonical prompt(s) | State on restart | Gate-A proof |
|---|---|---|---|
| Modal/input freezes | `39-RG1-owner-playtest-modal-freeze-reopen.md` + older `01-RG1-post-modal-freeze.md` | RECONCILE | Repeated Innkeeper, bed, Build, menus return to world control; no freeze/input loss |
| Controller UI | `03-RG6-controller-ui-input-audit.md` | RECONCILE | All reachable menus/dialogue/settings work by controller |
| Save/load | `04-RG7-save-position-and-progression-persistence.md` | RECONCILE | Title/load flow enters world; exact position/facing/story state survive save/load |
| Combat camera | `05-RG8-combat-camera-follow-and-control.md` | RECONCILE | Camera follows active creature with normal orbit control and returns correctly |
| Combat arena containment | current owner playtest + regional combat smokes | RECONCILE | Stronghold/Warrens and representative fights keep participants inside reachable legal arena bounds |
| Exploration control legend | `10-RG3-always-visible-exploration-control-legend.md` | RECONCILE | Major verbs readable without opening another screen |
| Build placement base regression | `02-RG4-build-placement-confirmation.md` | VERIFY | Base placement still works; do not regress it |
| Build repeat placement | `40-BUILD-valheim-repeat-placement.md` | RECONCILE | Selected piece remains active until cancel/change |
| Build dismantle | `41-BUILD-dismantle-full-refund.md` | RECONCILE | Player-built structures can be targeted/dismantled with full refund |
| Build modular snapping | `42-BUILD-modular-snap-contract.md` | RECONCILE | 2×2 floor + aligned walls + doorway + roof can be built cleanly |
| Build HUD controls | `13-RG14-verify-build-placement-control-strip.md` | VERIFY | Place/rotate/snap/cancel readable during placement |
| Gathering/tool feel | `44-GATHER-equipped-tool-swing-and-pickup-feedback.md` | RECONCILE | Correct tool visibly held; believable swing/hit; drops; `+X` pickup feedback |
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

After the 2026-08-21 owner playtest, Gate A evidence must also include the target-hardware/controller/map/build/camera/party-count/village/pond/lighting/submersion/load-game/gathering-presentation/combat-containment checks defined in `ralph/OWNER_PLAYTEST_2026-08-21.md`.

## Gate D — D3, D4 and D5 landed 2026-08-23

`ralph/GATE_D_REMAINDERS.md` is the current record of what is still open in
those three regions, and what is closed so nobody re-investigates it. Read it
before picking up any Gate D work.

The three regions' content is on `main` via `ralph/integration-D`, together with
the engine work they were all blocked behind: distance activation for wild
creatures, and the fix for every creature in the chapter falling through the
terrain. D1 (Lower Meadows) and D2 (Quarry/Warrens) are still in their own
sessions and are not covered by that file.

The one item to read first is the capture tooling. Five defects this run were
reported as problems with the game and traced to the capture path, across three
lanes that could not see each other's work. Until it gets a pass of its own, a
defect seen only in a survey frame has to be reproduced through a second path
before anyone acts on it.

## Gate C — backbone recorded 2026-08-22

`ralph/GATE_C_EVIDENCE.md` records Gate C's owning prompts (57, 58, 59, 60, 61,
67, 68) against their own acceptance lists, on branch
`claude/gatec-progression-curves-ep2j4x`.

The chapter-wide maps and curves Gate C exists to produce now exist:
`chapter_curve.json` (57/67, from `GATEC-CURVE`), `chapter_rewards.json` (58),
`objectives.json`'s twelve-beat chain (68), and the counted content map behind
`tools/_probe_chapter_map.py` (59/60).

Read the evidence file for the caveats, which matter: that lane had no Godot, so
the GDScript suite has NOT been run against those changes and the branch is
`claude/**`, which CI does not watch. Two acceptance items are deferred by the
prompts themselves to regional packages D1-D5 — PW2's special encounters and
prompt 61's camp siting — and one, prompt 61's attrition tuning, cannot be
settled without play.

Gate C being backbone-complete does not move the current gate. **Gate A is still
the current gate** and the 2026-08-21 owner blockers above are untouched by it.

---

## Gate B — current state, 2026-08-22

**Read `ralph/GATEB_TOURNAMENT_EVIDENCE_2026-08-22.md` before touching Gate B.**
It is the full status record: what is built and verified, what was found, and
what is left with an owner against each item.

Short version. The village tournament is BUILT and fought end to end
(`ralph/TOURNAMENT-1`, verified and extended on `ralph/TOURNAMENT-2`): eight-slot
bracket, three fought rounds, lose-and-retry, coins, the saddle prize, the
board rebuilt to the owner's 2026-08-22 ruling that a bracket must look like a
bracket and fill in only after events. RG19-spec's creature-condition gate
(rested/fed/happy, D68) is built and earned in the real player path. Save/load
across the bracket is covered. Unit suite 1234 tests, 0 failed.

Gate B is NOT passable yet, and the reason is not the tournament:

1. **the chapter's first catch fails deterministically** -- three clean-save
   runs, three throws the game itself judged eligible, no catch. Gate A's
   catching beat owns it; every Gate B beat is downstream of it;
2. **nothing is on `main`** -- TOURNAMENT-1, integration-3 and TOURNAMENT-2 are
   three unmerged branches, and the Gate B objective chain is split across two
   of them. Nothing lands without a dispatched consolidation run;
3. `opening:beat:road` is named by `objectives.json` and set by no code;
4. nobody has shown a player can reach the tournament's entry threshold through
   ordinary play in the opening area -- a named Gate B pass criterion;
5. both blind visual passes answered no to both bar questions, for reasons that
   are no longer about the tournament board.

## Next package after Gate A

**Gate B owner:** `docs/ralph-prompts/56-OPENING-first-session-to-tournament.md`

Fresh-save evidence path:

Grandpa → starter → naming → first wild fight/catch → build team → train → gather → small home → creature bed → player bed/sleep → tournament readiness → tournament win → clear South Bridge objective.

The pond-to-village route-content complaint from the 2026-08-21 owner playtest remains a required Gate B/C/D1 follow-through item: post-tournament travel must not be a long empty walk.

During the weekend sprint, safe Gate B/C/D implementation may begin in parallel with remaining Gate A work when it does not consume the same files/worker/CI capacity needed for Gate A SHIP BLOCKERS. Gate completion still requires canonical evidence.

Do not work distant region polish ahead of Gate A/B unless it can run safely in parallel without taking resources from higher-impact active work.