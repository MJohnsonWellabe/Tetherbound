---
name: systems-judge
description: Judge whether a Tetherbound gameplay system actually meets its milestone's acceptance criteria, from a transcript the running game emitted plus rendered frames. Load before declaring any milestone done, and before starting work on the next system. Produces a per-bullet verdict and an overall pass or refusal, never a score.
---

# Judging a Tetherbound system

The sibling of `visual-judge`. That one asks "does this look right"; this one
asks "does this system do what its milestone said it would".

A blind sub-agent reads evidence and says which acceptance bullets are actually
met. It never sees the source, the commits, the plan, or anything the author
says about what they built. **That separation is the whole mechanism.** An
author's account of their own system is the least reliable evidence available
about it, and this project has the receipts: a roster shot that was blank for
five hours while being described as working, four smoke tests reported green
while timing out, and a ground fix reported complete off a commit message rather
than a picture.

## The two rules that make this different from a code review

**1. The judge sees results, never intent.** No source files. No diffs. No
commit messages. No description of the design. It gets the milestone's
acceptance bullets — which are the *specification*, not the intent — and the
evidence. If it can infer what was built, it is being shown too much.

**2. The evidence is emitted by the game.** A transcript the author composes is
the author marking their own homework. `tools/play_session.gd` drives the real
world scene through injected input and prints what the game did — counts,
refusal strings, screen names, positions, what survived a reload. The judge is
reading testimony from the running program.

## Running it

```bash
# Drive the system and capture what it did.
godot --headless --path . --script tools/play_session.gd -- <system>
# UI frames need a renderer:
xvfb-run -a -s "-screen 0 1600x900x24" godot --path . \
  --rendering-driver opengl3 --resolution 1600x900 \
  --script tools/play_session.gd -- <system>
```

Produces `shots/session_<system>.log` and `shots/session_<system>_*.png`.

Then spawn a sub-agent and hand it exactly three things:

- the acceptance bullets for that milestone, copied verbatim from
  `docs/MEADOWS_VERTICAL_SLICE.md`
- `shots/session_<system>.log`
- the frames

And nothing else.

## The rubric

**Score nothing.** Produce a verdict per bullet and specific, addressable
failures.

For **each** acceptance bullet, one of exactly three verdicts:

- **MET** — the evidence positively shows it. Quote the line or name the frame.
- **NOT MET** — the evidence shows it failing, or shows something else.
- **NOT SHOWN** — the evidence cannot speak to it.

**NOT SHOWN counts as a failure, not as an omission.** This is the rule that
does the work. A bullet the session did not exercise is a bullet nobody has
seen working, and "the harness did not test it" is indistinguishable from "it
does not work" to everyone except the person who wrote both. If the evidence is
silent, say so and refuse.

Then the questions that a bullet list cannot ask:

1. **Does the refusal path exist?** Most of these bullets have a limit in them —
   five pals, a full inventory, a fainted pal that cannot fight. A system that
   does the happy path and silently allows the sixth is worse than one that does
   neither, because it looks finished. Look for the refusal *in the transcript*,
   with its message.
2. **Does it survive a reload?** State that exists only in memory is a demo. If
   the transcript does not show a save, a reload, and the same state afterwards,
   persistence is NOT SHOWN.
3. **Is the state real or reported?** A count printed by the system that owns it
   proves less than a count read back after a reload. Prefer the latter and say
   when you only have the former.
4. **Did anything regress?** The session boots the whole game. If the transcript
   shows errors, warnings, or a step that had to be skipped, that is a finding
   even if it belongs to another system.
5. **Is what the player sees legible?** For any frame: can you tell what screen
   you are on, what is selected, and what the buttons do, without being told?

## The verdict

Finish with both.

**1. Per-bullet table** — every acceptance bullet, its verdict, and one line of
evidence.

**2. One of these two sentences**, exactly:

> **PASS** — every bullet is MET.

> **REFUSED** — *n* bullets are not met or not shown, listed above.

**A single NOT SHOWN is a refusal.** There is no partial credit and no "close
enough": the point of the gate is that work does not move on to the next system
while a bullet is unevidenced. If that feels harsh for a bullet that is
obviously fine, the fix is to make the session show it, not to waive it.

Do not soften the rubric to obtain a pass, and do not soften it to be kind. A
refusal with three specific reasons is worth more than a pass with none.

## Honest limits

- **A transcript cannot judge feel.** "Repeated combat is enjoyable" and
  "building a home feels useful" are exit criteria for a human on the Ally, and
  no log line settles them. Judge what the bullets *say*, and where a bullet is
  about feel, say that it is met structurally and cannot be met evidentially
  here.
- **Injected input is not a player.** The session presses actions directly, so
  it proves the system responds, not that the control scheme is discoverable.
- **Frames are static.** Animation, transitions and responsiveness are invisible.
- **The session is written by the same person as the system.** That is the
  weakness this rubric's NOT SHOWN rule exists to counter: a harness that only
  exercises what happens to work will produce a transcript full of silences, and
  silences are failures here.

## After judging

Every accepted criticism becomes work, and the verdict is committed to
`docs/reviews/` **pass or fail** — a gate whose refusals are not written down is
a gate that quietly stops being one.
