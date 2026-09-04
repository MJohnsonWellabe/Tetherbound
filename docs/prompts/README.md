# Ralph prompt library

This directory is a **detailed implementation library**, not the task-selection queue.

For current work, start at:

1. `CLAUDE.md`
2. `docs/00_START_HERE.md`
3. `docs/ROADMAP.md`
4. `docs/ROADMAP.md`

Then read only the prompt(s) assigned to the current gameplay gate/package.

## Current execution rule

Do **not** execute these files by numeric filename order.

The active plan decides which gameplay experience is being finished. Prompt files provide detailed child/package requirements underneath that plan.

`docs/ROADMAP.md` contains the complete primary mapping of the existing prompt library into gameplay gates, and `docs/prompts/COMPATIBILITY_MAP.md` resolves overlapping historical prompt files.

## Current owning gameplay prompts

These are the package-level layer that assembles child systems into the complete game:

- `55-MEADOWS-gameplay-assembly-master.md` — chapter-wide integration standard.
- `56-OPENING-first-session-to-tournament.md` — fresh start through village tournament.
- `57-TEAM-progression-curve.md` — natural strength/XP progression across major challenges.
- `58-REWARD-resource-economy.md` — rewards/resources must enable something the player wants.
- `59-TRAINER-journey.md` — authored trainer escalation from locals to Warden.
- `60-WILD-ecology-journey.md` — living creature ecology and team-choice pressure across all regions.
- `61-EXPEDITION-rest-rhythm.md` — injury/rest/camp/home as a real adventure rhythm.
- `62-BAND1-finished-lower-meadows.md` — finished Lower Meadows gameplay package.
- `63-BAND2-finished-quarry-warrens.md` — finished Quarry/Burrow Warrens package.
- `64-BAND3-finished-river-relay.md` — finished River/Tether Relay package.
- `65-BAND4-finished-upper-meadows.md` — finished Upper Meadows package.
- `66-BAND5-finished-stronghold-approach.md` — finished final approach package.
- `67-FIVE-creature-pressure-and-bond.md` — make five total slots emotionally/mechanically matter.
- `68-CHAPTER-complete-objective-chain.md` — player-facing chapter purpose/handoffs.
- `69-STRONGHOLD-chapter-finale.md` — Hall/Warden/legendary/world-healing payoff.
- `70-MEADOWS-full-chapter-integration-playthrough.md` — final 3–4 hour acceptance/tuning pass.

## Finish-the-Meadows contracts (2026-09-04)

Written against `docs/FINISH_THE_MEADOWS.md` and its addendum, from the owner's 2026-09-04
directives:

- `73-PROGRESSION-VISIBLE-bond-and-level-feedback.md` — the A1/A2 contract: one progression
  feed, three loudness levels, the Team screen answering "how bonded am I and what raises
  it", and the ordered-ladder decision. Supersedes `47` and owns the feedback lines of `67`.
- `74-ART-REFERENCE-owner-boards-for-meshy.md` — the three reference boards most likely to
  be needed (South Bridge checkpoint gate, ridge watchtower, riding saddle), the image
  prompts to produce them in board 13's format, the intake route, and when a credit may be
  spent per object.

## Current Gate A environment baseline

- `71-GATEA-opening-environment-baseline.md` — make the opening/village/pond area representative enough to judge the real game during Gate A: naturally available creatures/resources, approved lush pond pocket, nearby broad open sightlines, readable trails, and no global density sweep.

This is deliberately a **minimum test environment**, not the final ecology/world-composition pass. `60-WILD-ecology-journey.md` and regional prompts `62`–`66` still own chapter-wide habitat, creature density, trainer/resource cadence, and regional composition.

## Current owner-play child prompts

The newest detailed owner-play implementation pass includes:

- `39-RG1-owner-playtest-modal-freeze-reopen.md`
- `40-BUILD-valheim-repeat-placement.md`
- `41-BUILD-dismantle-full-refund.md`
- `42-BUILD-modular-snap-contract.md`
- `43-CREATURE-BED-gradual-overnight-rest.md`
- `44-GATHER-equipped-tool-swing-and-pickup-feedback.md`
- `45-CATCH-over-shoulder-aim-and-throw.md`
- `46-CREATURE-release-ceremony.md`
- `47-CREATURE-level-up-feedback.md`
- `48-PARTY-cycle-pals-in-world.md`
- `49-POND-real-water.md`
- `50-WORLD-usable-building-doors.md`
- `51-TORCH-upright-hand-and-re-equip-light.md`
- `52-MAP-all-authored-trails-visible.md`
- `53-MEADOWS-pokemon-first-core-loop-density.md`
- `54-RG25-owner-confirmed-title-screen-missing.md`

Newer owner evidence supersedes conflicting older assumptions.

## Original Meadows review prompts

Files `01`–`38` preserve the original 38-item Meadows review conversion. They remain live child/reference contracts where their work is not already shipped or superseded.

Their current primary placement is recorded in `docs/ROADMAP.md` rather than duplicated here.

Important examples:

- old base build-placement work is verify-first; newer repeat/snap/dismantle prompts own the current construction ask;
- old torch verify-only assumptions are superseded by the newer concrete re-equip/orientation defect where necessary;
- old minimap orientation work is verify-first while missing trail coverage remains current;
- old title-screen work is confirmed current by the newer owner-play prompt;
- old broad density/content prompts are consumed through the new regional/package owners rather than run as one isolated giant pass.

## Legacy overlapping `OP-*` prompts

There are seven older owner-play briefs with duplicate numeric prefixes (`39`–`45`). They are intentionally retained because they contain useful acceptance detail, but they are **not seven additional implementation projects**.

Use `docs/prompts/COMPATIBILITY_MAP.md` to merge their unique requirements into the current canonical prompts/packages and implement each issue once.

Never refer to prompts `39`–`45` by number alone; use the full filename.

## How to use a prompt

For any assigned prompt:

1. inspect current `main`;
2. reproduce/verify the player-facing state;
3. read the relevant current owner evidence and spec sections;
4. implement through existing systems where possible;
5. preserve all listed constraints/working behavior;
6. run required tests and real interaction paths;
7. render/visual-judge when visuals change;
8. verify the result on `main` after shipping;
9. remember that a child prompt passing does not automatically pass its owning gameplay package.

An evidence-backed “already fixed on current main” is a valid child outcome. A gameplay gate/package still requires its continuous evidence run.
