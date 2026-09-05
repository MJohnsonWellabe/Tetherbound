# START HERE — Tetherbound

> **Start here, 2026-09-04: [`docs/FINISH_THE_MEADOWS.md`](FINISH_THE_MEADOWS.md)** — the
> whole remaining plan to finish the chapter, in order, written to be picked up cold. It
> supersedes older prose about what is next. `docs/GATE2_GATE3_CLOSURE_PLAN.md` is the
> detail behind it, with a *fails if* on every open item.
>
> **Then read [`docs/FINISH_THE_MEADOWS_ADDENDUM_2026-09-04.md`](FINISH_THE_MEADOWS_ADDENDUM_2026-09-04.md).**
> It adds the newest owner-directed chapter requirements: visible bond/level progression,
> Good/Great/Rare Candy, denser useful world findables, and visible companion personality.
> The source directive is `docs/owner/OWNER_DIRECTIVES_2026-09-04-C.md` and outranks older
> planning where it overlaps.

**Read this first. It is the only routing document.** Rewritten 2026-09-02 at the
repository reset; it replaces `ralph/START_HERE.md`, the coordinator handovers and the
dated backlogs, which are now under `archive/`.

## What Tetherbound is

A third-person open-world creature-training adventure in Godot 4.7 for Windows and the
ROG Ally, controller-first, solo. The player owns **five creatures, total**, pilots them
directly in real-time combat, and supports the team with gathering, crafting, building,
care and rest. The first and only chapter in scope is **the Meadows**: wake at Grandpa's
farmhouse, win the village tournament, travel south through five increasingly demanding
bands, break Team Tether's relay, take the three Sigils, defeat the Warden in Meadows
Hall, free the legendary, and choose the final five. Target: a 3–4 hour focused first
clear. `docs/GAME_VISION.md` is the experience contract.

## Current stage

**Gate 1 is nearly proven and Gate 2 is open** (`docs/ROADMAP.md`). All chapter systems
exist in code and data — `docs/CURRENT_STATE.md` is the evidence-backed status of each and
outranks this summary.

Updated 2026-09-03. The three failures this section used to name are resolved, and two of
them were not what they claimed:

- The opening-segment orb floor is **fixed** (gate on the beat, not the species).
- The Gate B objective chain was **never stalling** — two assertions were pinned to label
  strings that had never existed in `objectives.json`, behind a job that did not gate. The
  gather-route half was real, and is now **fixed**: the corner past TrailGate was a
  harness defect, not a world defect — a real body clears it on a plain stick-hold; only
  `stick_navigator.gd`'s stall/flip logic could not round it (FENCE-CORNER-0903).
- The South Bridge `smoke_traversal` failure was **a harness defect, not a world hole**: a
  teleport outran Terrain3D's camera-following collision, so the body fell before the
  ground existed under it. The crossing's geometry was never changed and never needed to be.

`smoke_gate_b_continuous` now drives ~25 minutes of continuous play, and its reliable
prefix gates in CI.

**If you are picking up an in-flight orchestration session, read
`docs/HANDOFF_2026-09-03.md` first** — it carries the live lane state, the open PR, and the
traps that have already cost this project time.

**If you are starting Gate 3, read `docs/GATE3_COORDINATOR_BRIEF.md` first.** Gate 3 may
begin before Gate 2 is called done — the Gate 1 precedent covers this — but Gate 3's
acceptance is defined by reference to the Gate 2 standard, and task 2.8 is currently
empowered to revise that standard. The brief says which Gate 3 work is safe to start now
and which must wait for 2.8's verdict.

## What is authoritative

| Question | Read |
|---|---|
| Hard rules for any change | `CLAUDE.md` |
| What the finished chapter should feel like | `docs/GAME_VISION.md` |
| What is true right now (status, known issues, evidence) | `docs/CURRENT_STATE.md` |
| What to do next, in what order, with what acceptance | `docs/ROADMAP.md` |
| How agents work here (tiers, briefs, CI, testing, renders, done) | `docs/AGENT_WORKFLOW.md` |
| How a system works, where its code/data/tests are | `docs/GAMEPLAY_SYSTEMS.md` |
| Where things are in the world and how much content exists | `docs/WORLD_AND_CONTENT.md` |
| Creatures: roster, rules, scale, art constraints | `docs/CREATURE_DESIGN.md` |
| Visual target, judging rubric, current visual gap list | `docs/VISUAL_BIBLE.md`, `.claude/skills/visual-judge/SKILL.md` |
| Engine, architecture, directory map, pipelines, CI | `docs/TECHNICAL_ARCHITECTURE.md` |
| Owner playtests and directives (verbatim; outrank everything) | `docs/owner/` |
| Settled design decisions (append-only) | `docs/decisions/` |
| Detailed implementation contracts per task | `docs/prompts/` |
| Long-form owner-supplied specs (progression, macro layout, design) | `docs/specs/` |
| The Phase 2 design contracts (rideable roster / fly / teleport, the task feed, the village replan, camping made necessary) — the implementation briefs for the 2026-09-04 directives | `docs/specs/C*.md` (`C1_RIDEABLE_ROSTER_FLY_TELEPORT.md`, `C2_TASK_FEED.md`, `C3_VILLAGE_REPLAN.md`, `C4_CAMPING_NECESSARY.md`) |
| Chapter acceptance and the Gate F full-playtest protocol | `docs/acceptance/` |
| Reference art (key art, Palworld bar) | `docs/reference/` |
| What was moved/archived/removed in the reset and why | `docs/CLEANUP_MANIFEST.md` |

Precedence when documents disagree: newest owner directive or playtest in `docs/owner/`
→ `CLAUDE.md` → `docs/decisions/` → `docs/specs/MEADOWS_PROGRESSION_SPEC.md` →
`docs/GAME_VISION.md` → the rest of `docs/` → `docs/prompts/` → anything in `archive/`.

## What to read for different kinds of work

- **Gameplay bug or feature:** this file → `CURRENT_STATE.md` → `ROADMAP.md` (find the
  task) → `GAMEPLAY_SYSTEMS.md` (the system section) → the named prompt in `docs/prompts/`
  → the code and its tests. Then `AGENT_WORKFLOW.md` §4–6 before you push.
- **World or visual work:** add `VISUAL_BIBLE.md`, `WORLD_AND_CONTENT.md`, the render
  rules in `AGENT_WORKFLOW.md` §7, and the visual-judge skill. Never judge your own
  frames.
- **Creature work:** add `CREATURE_DESIGN.md` and `docs/art/HUMANOID_ASSET_INVENTORY.md`
  for humans. No new meshes.
- **Process, CI, tooling:** `TECHNICAL_ARCHITECTURE.md` and `AGENT_WORKFLOW.md`.
- **Coordinating several agents:** `AGENT_WORKFLOW.md` §1–3 and §11, then `ROADMAP.md`.

## Known issues right now

See `docs/CURRENT_STATE.md` §3 for the ranked list — it is authoritative and this
summary is not. Updated 2026-09-03; the four items this section used to head with
(opening orb floor, the Gate B objective chain, South Bridge entombment, the truncated
objective label) are all closed, two of them as harness defects rather than game
defects. See "Current stage" above.

Headline items still open:

- The tutorial catch is unstable across knockout / re-engage rounds.
- Bramblebun reads as a self-lit glow at night: `field_emission` was raised to 2.5 for
  daytime grass separation and the multiply is not time-of-day scaled.
- Gate B's tail stalls placing creature beds (3 of 5), and the objective does not advance
  off "Make camp for your team". Found only after the gather-route fix let the run get
  that far.
- Gate B's walk back to the Practice Meadow clearing stalls ~27–32 m short. Same reason:
  newly reachable, not newly broken.
- Bram's shop exit clips furniture.
- Gate 2's task list (2.1–2.7) is complete while its blind-judge bar is not met; task
  2.8 decides what that means. See `docs/GATE3_COORDINATOR_BRIEF.md` §2.
- Four items only the owner's ROG Ally can close: interact reliability, frame rate with
  grass on, player sleep, day/night advancing.

## How evidence is produced (D73)

No gate waits on a human. The owner's only act is double-clicking
`tools/owner/KICKOFF.cmd` on a Windows machine with a GPU (the ROG Ally). That
produces the GPU route strip the visual bars are answered on, a real frame-rate
file, the shipped-build verdict and the Gate F chain with video, and pushes it
as `owner-run/<stamp>`. `docs/acceptance/KICKOFF_RUN.md` says what agents do with
a run. Open design questions are decided by the orchestrator and recorded in
`docs/decisions/`; they are not queued for the owner.

## Validation expectations

- Unit: `godot --headless --path . --script tests/run_tests.gd` (≈28 min; use
  `-- --only=file.gd::test` for one).
- Smoke: `godot --headless --path . --script tests/smoke_<name>.gd`.
- Visual: render with `tools/survey.sh` (xvfb, Compatibility renderer) and run the blind
  judge. Never `--headless` with a rendering driver.
- CI: a run under five minutes verified nothing. A full run is 35–45 minutes.
- Import: `godot --headless --path . --import` on a fresh checkout; CI fails on script or
  resource errors.

## Branch rules

Branch from current `main`. `ralph/<TASK>` runs CI and is the shipping prefix;
`claude/<task>` for orchestrator sessions; `scratch/<x>` for throwaways. Never push to
`main`. Land through a pull request whose head commit is code. Confirm with
`git merge-base --is-ancestor`. Full rules: `AGENT_WORKFLOW.md` §5.

## Definition of done

A child task is done when its player-facing acceptance criterion holds on `main`, its
tests pass on first attempt, its visual evidence passes if visual, and the orchestrator
verified it. A gate is done when the continuous player path in `ROADMAP.md` passes with
the evidence template filled in. Code existing is not done.

## Directories

```
autoload/ scenes/ scripts/ shaders/ data/ assets/ addons/   the game (see TECHNICAL_ARCHITECTURE.md)
tests/                                                    unit + smoke suites, fixtures, helpers
tools/                                                    capture, art pipeline, Gate F harness, CI scripts
docs/                                                     this source of truth
ralph/                                                    evidence output root only (ralph/reports/, payload ignored)
archive/                                                  history: old control-plane docs, handovers, report summaries
site/                                                     the download page
```
