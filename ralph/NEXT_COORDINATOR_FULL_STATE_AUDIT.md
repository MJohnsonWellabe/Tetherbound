# Next coordinator: the full-state audit

**Written:** 2026-08-30, by the outgoing coordinator, at the owner's direction.
**Status:** This is your instruction. Read `CLAUDE.md` first — its hard rules bind
you and everything below. Then read this file completely before you spawn anything.

---

## What the owner asked for, in his words

> "spawn a lane for each exit criteria check. then a lane for a full gate f play
> through. then a lane that takes pictures of everything in game. creatures,
> characters, locations, terrain, gatherables, harvestables, etc. everything. no
> coding to the game should be done. just to the rigs or tests then just
> documentation of current state of everything. then fable will evaluate
> everything to come up with a new plan to completing the game. so the lanes need
> to give it enough information for that."

That last sentence is the whole job. **Every lane you run exists to feed one
downstream reader who was not here and saw none of this.** You are not producing
progress. You are producing a description of the present state accurate enough
that someone can plan from it without re-deriving it.

---

## The one rule that governs every lane

**No game code changes. None.**

Lanes may write and fix:

- test files under `tests/`
- capture tools, harnesses and rigs under `tools/`
- documentation under `ralph/` and `docs/`

Lanes may **not** touch `scripts/`, `scenes/`, `data/config/`, `data/progression/`,
assets, or anything else that changes what the game does or how it looks. If a lane
finds a defect, the defect is **written down**, not fixed. If a lane finds itself
one line from a tempting fix, it writes the line into its report as a proposal and
moves on.

This will feel wrong to a competent lane. Say so up front in every brief, and say
why: the project has spent days accumulating individually-successful changes whose
combined effect nobody has ever observed. This audit is the observation. A lane
that fixes as it goes destroys the measurement it was sent to take.

The single exception: a lane may fix its **own instrument** — a harness that
crashes, a capture script that produces frames of the wrong thing, a test that
asserts something other than what it claims. Fixing the instrument is the job.
Fixing the subject is not.

---

## The evidence rule, which is not negotiable

`ralph/MEADOWS_EXIT_CRITERION.md` carries this, learned the hard way:

> **Evidence that does not show the shipping game is worse than no evidence.**

The blind judge found the capture harness producing frames with **no grass
geometry** and haze the build does not have, which means an unknown share of
previously "verified" visual work was judged against a game that is not the one
shipping. The owner said the same in his own words: *"some of those renders are
just a bad shot not actual game."*

So: **no frame counts until it has been sanity-checked for real grass, real
lighting and real geometry**, and every lane must say, in its report, how it
checked. A lane that cannot get a true frame reports that it could not, and that
is a finding — arguably the most important one available.

The gameplay half of the same rule: a config-level assertion and a passing test are
not evidence that a player can reach a thing. A played path is. Expect to find
items recorded as done that do not survive this. Finding them is the point, and
nobody will be annoyed.

---

## Lane 1..11 — one per exit criterion

Spawn **one lane per section** of `ralph/MEADOWS_EXIT_CRITERION.md`:

| Lane | Section | Subject |
|---|---|---|
| `AUDIT-A` | A | Player-voice acceptance, A1–A11 |
| `AUDIT-B` | B | Beautiful creatures, B1–B6 |
| `AUDIT-C` | C | NPCs and human cast, C1–C4 |
| `AUDIT-D` | D | Terrain and world, D1–D8 |
| `AUDIT-E` | E | Locations, E1–E5 |
| `AUDIT-F` | F | Story and its delivery, F1–F6 |
| `AUDIT-G` | G | Things to do / reason to keep going, G1–G10 |
| `AUDIT-H` | H | Building, survival and care, H1–H6 |
| `AUDIT-I` | I | Systems, I1–I9 |
| `AUDIT-J` | J | One deliberate game, J1–J4 |
| `AUDIT-K` | K | Works end to end, K1–K4 |

Each lane's deliverable is `ralph/reports/audit/<SECTION>-2026-08-31.md` containing,
**per numbered item**:

1. **The test that decides it.** A named test file, a capture script plus the stand
   it shoots from, a played segment, or a measured number with its threshold. If a
   test exists, run it and give the result. If none exists and one is cheap, write
   it. If none exists and writing one is not cheap, specify it precisely enough that
   someone else could write it without a conversation.
2. **The current verdict** — passes, fails, or cannot be determined — and *cannot be
   determined* is a legitimate and useful answer. Do not guess to fill a cell.
3. **The evidence, with repo paths.** Frames, logs, numbers, save files. A verdict
   with no path behind it is prose, and prose is what this audit exists to replace.
4. **What it would take to close it**, in a form a planner can cost: an hour of
   config, a played segment, a capture-and-judge round, owner-supplied reference
   art, or an owner decision.

A lane covering a section whose items are mostly visual should get its verdicts from
the `visual-judge` skill and must honour its separation rule: **the judge gets no
design context and answers the two bar questions, never a score.** A lane must not
judge its own framing.

Note for section A specifically: A1–A11 are statements about a *player's experience*,
and no test file can settle them. That lane's real job is to say which of the eleven
the Gate F lane's run could evidence, which need a human at the controls, and which
nobody currently has any way to measure at all. That third list is valuable.

---

## Lane 12 — `GATE-F-FULL`, the complete playthrough

One lane, running the instrumented full-chapter playthrough per
`ralph/GATE_F_MASTER_PROTOCOL.md`, segments S01–S10 and X01–X08.

Where it starts from: run 7 produced **S01 at 13/14 PASS, 0 FAIL** and a complete
**S02 — 90 steps, 79 PASS** — with the fight staged, the starter winning at 67.9 of
117.6 HP, the catch landing, the key taken, the road gate opened, and an exit save
carrying Ripplet L3 and Bramblebun L2 with `road_gate_open` set. Six previous runs
could not produce that save. Its handover is
`ralph/reports/handover-GATE-F-RUN7-2026-08-30.md`; read it before starting, and
read the T5-PLAY S03 work, since S03 had to be fixed before anything downstream
produced meaningful results.

The rig is fair game — that is what "just to the rigs or tests" means. Seven runs
have died on rig bugs rather than game bugs, and this lane is expected to fix the
harness as often as it advances. The game is not fair game. If S05 is blocked by a
real game defect, the run stops there, the defect is written down, and the lane
reports how far the chain got. **A blocked chain honestly reported is a better
result than a green chain obtained by editing the game underneath it.**

Deliverables: the run directory with its `INVENTORY.json`, the per-segment PASS/FAIL
detail, the exit save from the furthest segment reached, and
`ralph/reports/audit/GATE-F-FULL-2026-08-31.md` stating plainly how far the chapter
runs today, what stopped it, and — if the data supports it — the **wall-clock time
for a first clear** against the 3–4 hour target. If the data does not support a
number, say that instead of producing one.

---

## Lane 13 — `PHOTO-EVERYTHING`, the visual census

One lane, whose job is a photograph of every visible thing in the game. The owner's
list: creatures, characters, locations, terrain, gatherables, harvestables,
**everything**. Read that as exhaustive rather than illustrative:

- **Creatures** — every species in data, every Aspect variant, every rarity tier
  including alpha, in habitat and at gameplay distance, not only in close crop.
- **Characters** — all six installed humanoid rigs and every variant configured on
  them: trainer, Grandpa, the Warden, villager male, villager female, Team Tether
  grunt, plus each named NPC and each rank presentation.
- **Locations** — every band, every landmark, the village, Meadows Hall, the
  Warrens interior, the stronghold approach, every camp.
- **Terrain** — each band's ground, the river and its banks, paths, seams, the
  transitions between bands.
- **Gatherables and harvestables** — every node type, in place, at the distance a
  player actually sees it from.
- **Props, UI, weather and time of day** — the campsite kit, every HUD state, day,
  night, golden hour, and whatever weather exists.

Two hard requirements. First, the **evidence rule above applies to every single
frame**, and the lane must state its sanity check. A census of frames that do not
show the shipping game is worse than no census, and this lane is the one most
exposed to that failure. Second, the output must be **navigable**: an index keyed to
what the reader is looking for, thumbnails or a contact sheet where the count is
large, and a caption on each frame saying what it is, where it was shot from, and
under what light. An undifferentiated directory of nine hundred PNGs is not a
deliverable.

Where a thing exists in data but **cannot be photographed because it is unreachable
in play**, that is a first-class finding and goes in the index. The owner's standing
directive is that built is not done.

Deliverable: `ralph/reports/audit/VISUAL-CENSUS-2026-08-31.md` plus the frames.
No verdicts — this lane documents, it does not judge. Judging is section J's.

---

## What every lane brief must contain

Copy these into each brief; they are the mechanics that have actually cost this
project time:

- **`create_session` must be given `source_url: "https://github.com/MJohnsonWellabe/Tetherbound"`
  and a `source_revision`.** Without `source_url` the container gets **no repository
  at all**, and the lane will spend hours diagnosing it as a permissions problem. Two
  lanes died this way.
- **`create_trigger` does not deliver a message. You must then call `fire_trigger`.**
- **The skip-ci marker matches anywhere in a commit message, body included.** A commit
  that *documents* the marker in prose silently skips its own CI run. Never write the
  two words out; refer to it as "the marker".
- **Branch and push discipline** per `ralph/conventions.md`. Never push `main`.
  Lanes push `ralph/<LANE-ID>`.
- **Never reformat a JSON file to change one value.** Use a surgical string edit and
  validate with `json.load`. A `json.dump` round-trip rewrote 62 lines of unrelated
  inline arrays and buried the actual change.
- Lanes should push a checkpoint early and often. Work that exists only inside a
  container does not exist.

---

## What the state of the repo is, as of this writing

- `main` is `24fc81cb`.
- **`ralph/LAND-0830J` is the real state of the project** — roughly 896 files and
  +55,013 lines of unlanded work from about twenty lanes. Audit against it, not
  against `main`, and have every lane state which branch its finding is true on.
  If it has landed by the time you read this, audit `main`.
- Three failures were blocking that consolidation: the band_content fixture mirror
  drift, a stale scatter bake, and `party_count_after_catches`. Check whether they
  are resolved before assuming a clean base.
- Handovers from the stood-down board are in `ralph/reports/handover-*-2026-08-30.md`.
  They are the freshest truth in the repo and several contradict older `DONE.md`
  prose. Have lanes read the ones touching their section.

Known open findings that lanes should verify rather than inherit:

- **Section E is in the worst shape.** JUDGE-6's blind pass on the rebuilt fortress
  answered **NO to both bar questions** — *"it is finished, as the wrong building"* —
  measuring the fortress at 137.6 luminance against a bald hill at 162.5, where the
  keyart runs 72 against 104 with the fortress dark. Its verdict: *"the climax
  location of the chapter loses a silhouette contest to a tree."*
- **The scatter defect is open.** T1-WORLD retracted its own fix: the problem is the
  placement **rule**, not its parameters, and its cover-tier tuning was reverted as
  aimed at the wrong system.
- **Section H got its first evidence** from T5-CARE: placement, satiety and bed rest
  pass; build mode was unreachable near any harvestable node and the satchel could
  not feed the player. Three fixes shipped. Verify them; do not take them on trust.
- Two humanoids are **unrecoverable** — geometry gone — and need owner-supplied
  reference art. The audit should confirm which two and what exactly is needed.
- 73 synthesised audio files exist that **no one has listened to**.

---

## The handoff to Fable

When the lanes are done, Fable evaluates everything and writes the plan for
completing the game. Fable was not here. Fable has none of this context. Everything
it needs must be in the reports.

So your final act is not a summary — it is **assembling the package**. Write
`ralph/reports/audit/INDEX-2026-08-31.md` that gives Fable, in one place:

1. Where every lane report is, and what question each one answers.
2. **The consolidated state of the game** — what works, what does not, and what
   nobody knows. Keep those three categories separate and do not let the third
   quietly collapse into either of the others; "unknown" is the category most likely
   to be lost in aggregation, and it is the one that most changes a plan.
3. **Every open defect**, with its evidence path and what it would cost to close.
4. **Everything that needs the owner personally** — reference art to source, a
   ROG Ally playtest, audio to listen to, decisions only he can make. He asked for
   this list explicitly and more than once.
5. **What the audit could not determine, and why.** Be specific. "We never got a
   true frame of X because the capture harness does Y" is worth more to a planner
   than any number of confident verdicts.

Do not write the plan yourself. Do not rank the work by what you would do next.
Fable's job is to decide; yours is to make deciding possible.

One last thing, and it is the reason this audit exists at all: this project has
repeatedly mistaken *implemented* for *done*, and then mistaken *documented as done*
for *done*. The binding principle in `CLAUDE.md` is that a system is finished when
the complete player path produces the intended experience — not when the code
exists. Every verdict you pass to Fable should be defensible against that standard,
and where it is not, say so plainly rather than rounding it up.
