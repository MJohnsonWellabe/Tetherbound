# D15 — Systems are gated by a blind judge

**Status:** accepted
**Decided by:** owner, before System 1
**Sibling of:** `D06-the-screenshot-critic-under-godot.md`

## The decision

No system moves on until an adversarial reviewer, working **blind**, agrees the
milestone's acceptance criteria are met by the running game.

Blind means it sees two things and nothing else:

1. the milestone's acceptance bullets, verbatim
2. the evidence — a transcript the game printed, plus rendered frames

It does not see the code, the commits, the plan, the design docs, or anything
the author says about what was built. Its default is refusal. Its verdict is
committed to `docs/reviews/` **pass or fail**, in its own words.

`.claude/skills/systems-judge/SKILL.md` is that reviewer, the sibling of the
existing `visual-judge`. Look questions go to the visual judge; behaviour
questions go to this one.

## Why the evidence has to be emitted by the game

This is the part that makes the gate real, and it is the part that is easy to
lose.

A transcript the author composes is the author marking their own homework. It
will describe the system as the author understands it, which is exactly the
thing under review. So the evidence is produced by `tools/play_session.gd`: it
boots the real world scene, drives it through the real input actions the way a
smoke test does, and writes down what the game did.

**Its one rule is: log facts, never conclusions.**

`party is full, refused: "you can only keep five"` is a fact. `the five-pal cap
works correctly` is a conclusion, and writing it hands the judge the answer
instead of the evidence — which is the entire thing the gate exists to prevent.
If a line could be wrong while the game is right, or right while the game is
wrong, it does not belong in the transcript.

## NOT SHOWN counts as a failure

The uncomfortable corollary, and it is deliberate. A bullet the session does not
exercise comes back NOT SHOWN, and the rubric treats that as not met — not as
an omission to be excused.

Without it, the cheapest way to pass is a harness that quietly skips the hard
part, and the transcript fills up with silences that read as success. The rubric
is written to refuse on silences.

## Why the acceptance criteria go to the judge and not the code

The judge is given the bullets because a reviewer with no criteria produces
taste, not a verdict. It is denied the code because a reviewer who has read the
implementation reviews whether the implementation does what it says, which is a
different and much easier question than whether the game does what the milestone
asked for.

The same discipline applies one layer down: the evidence session for a system is
**written from the acceptance bullets before the implementation exists**, by
someone who has not seen it. A session written against the implementation proves
only that the implementation agrees with itself.

## Why a passing test is not the acceptance

Already proven repeatedly on this project, which is why it is written down:

- A build preview put a roof **six metres in the air**. Every assertion passed.
- The trainer's sword and shield floated beside the model, found only by
  rendering a frame.
- Grass measured in band and stood taller than the player.
- The traversal check reported "the ground is not continuous" — a conclusion.
  The fact was that the player was embedded 0.5–0.7m *inside* a collider that
  was present the whole time.

The general form, which has now cost enough time to earn a place in a decision
record: **when a check and the thing it checks use different mechanisms, the
check is testing the mechanism.** So anything with a UI is accepted on a
rendered frame, and measurements landing in band are never the acceptance for
something a person looks at.

Absence of a `FAIL` line is not a pass either. Four smoke tests once exited 124
— timeouts — under a grep that only looked for failures.

## The verification a system passes through

1. Its own unit tests, plus a smoke in `tools/run_smokes.sh`, run headless.
2. `tools/verify_export.sh` green — it runs the *exported binary*.
3. Rendered frames of anything with a UI.
4. The blind judge's verdict, recorded either way.

A refusal is not a setback to be argued down. `docs/reviews/M4-01-refused.md`
found three defects across two bullets, and both were failures of the
**evidence** rather than of the system — which is information the author could
not have produced alone.
