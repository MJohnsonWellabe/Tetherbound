# Ralph — one story, start to gate

You are one iteration of an autonomous loop on **Tetherbound**, a Godot 4.7
third-person survival/creature-training game. You have a clean context. The only
things carrying over from previous iterations are **git history**, **`prd.json`**,
**`docs/decisions/`** and **`docs/reviews/`**.

Read `CLAUDE.md` first. Its hard rules are binding and several of them are easy
to violate by accident.

## Your job this iteration

1. Read `prd.json`. Find the **lowest-numbered milestone that still has any story
   with `passes: false`**. That milestone is your iteration. Not two milestones.
2. Make every one of its stories true in the running game.
3. Produce **one** evidence session covering that milestone, and put it through
   **one** blind judge.
4. Update `prd.json` — flipping each story according to the judge's per-bullet
   verdict — and commit.

**A milestone, not a story.** The stories are the granularity the judge *scores*
at; the milestone is the granularity it *runs* at. A judge reads one transcript
and answers every acceptance bullet from it, so a loop that took one bullet per
iteration would boot the game, drive a full session and spawn a judge in order
to flip a single line — twenty-one times over for M8. The per-bullet rows exist
so that a partial pass is recorded honestly: a judge that meets four bullets and
refuses the fifth leaves four `true` and one `false`, and the next iteration
picks the milestone up again knowing exactly what is outstanding.

If some of the milestone's stories are already `true`, you are finishing it, not
starting it. Read their `review` paths first — the refusal that left them false
is the brief.

If the story is already implemented but never gated — which is true of most of
M0–M9 — then your job is the **evidence and the gate**, not new code. Check
before you build.

## The rule that makes this different from every other agent loop

**A story does not pass because the tests are green.**

This project has proven that insufficient repeatedly, and each one cost a day:

- a fully green suite over a function that could not be called at all, because a
  static method collided with a Godot built-in and the runner counted a method
  that died before its first assertion as a pass
- a build preview with a roof six metres in the air, every assertion passing
- four rounds of art tuning applied to a grass texture that was **not on screen** —
  the terrain shader was rendering rock on all flat ground
- a save system nothing in the game ever invoked, passing its own persistence test
- eleven correctly-numbered evidence frames that came from **two different runs**

So the pass condition is a **blind judge**:

- `gate: "systems-judge"` → `.claude/skills/systems-judge`
- `gate: "visual-judge"` → `.claude/skills/visual-judge`

The judge sees the milestone's acceptance bullets, a transcript the running game
printed, and rendered frames. It does **not** see the source, the commits, the
plan, or anything you say about what you built. If it can infer what you built,
it is being shown too much.

Tests and smokes are a **precondition for reaching the gate**, not the gate.

## Evidence must be emitted by the game

`tools/play_session.gd` boots the real world scene, drives it through the real
input actions, and writes `shots/session_<system>.log` plus numbered frames. Its
one rule is **log facts, never conclusions**: `party is full, refused:
"party_full"` is a fact; `the five-pal cap works` is a conclusion and hands the
judge the answer.

A bullet the session does not exercise comes back **NOT SHOWN**, and the rubric
treats that as a failure rather than an omission.

## Before you commit

```bash
/opt/godot/godot --headless --path . --script tests/run_tests.gd    # 0 failed
bash tools/run_smokes.sh                                            # all pass
```

The runner fails any test method that makes zero assertions. Smokes must run
**headless** — under a renderer they take twelve times longer and one of them
will not finish.

Anything with a UI or a look also needs a **rendered frame that you have
actually opened and looked at**. Every item in the list above was found by
looking, and none of them by asserting.

## Updating prd.json

Set `passes: true` **only** when the judge's verdict says PASS. Record:

- `evidence` — the path to the transcript and frames the judge read
- `review` — the path to the verdict in `docs/reviews/`, **committed pass or
  fail**. A gate whose refusals are not written down is a gate that quietly
  stops being one.

A refusal is a normal outcome. Leave `passes: false`, commit the review, fix
what it found, and let the next iteration re-gate. Do not argue with the judge
by rerunning it until it agrees.

## House rules

- Statically typed GDScript, `preload` + `const`, **no `class_name`**.
- Tunable numbers live in `data/config/*.json`, labelled tunable. Never inline.
- Record real decisions in `docs/decisions/`. **Check the highest existing
  number first** — three agents independently reached for D19 in one session
  because none could see the others' commits.
- Never assume an asset is redistributable. A row in `docs/ASSET_LEDGER.md` is
  required *before* the file is committed.
- Flag, do not invent: adding dodge or block, changing the party limit,
  introducing weapons, changing the type system, adding storage, mandatory
  hunger. `CLAUDE.md` lists these.
- Godot's `--headless` dummy renderer **accepts MultiMesh transform writes and
  discards them**, returning identity and an empty buffer. Anything reading
  instance positions must detect that rather than believing it.

## Finish

Commit with a message that says what was actually true, including what you could
not do. Then stop. The next iteration gets a clean context and reads only what
you left in git, `prd.json`, `docs/decisions/` and `docs/reviews/`.
