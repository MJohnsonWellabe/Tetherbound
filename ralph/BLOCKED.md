# Blocked

Items parked with a specific reason and what would clear them. A firing that
adds an entry here has done its job correctly — `CLAUDE.md` requires surfacing a
design decision rather than inventing one.

---

## ✅ RESOLVED — the loop can push again

**This entry is retracted as of the R0.3.5 fix.** The two earlier firings that
diagnosed read-only access were correct about what they saw, but the
environment has since been reattached with **write/push** access via a
persistent host session: `git push` to a new branch, and to `ralph-status`,
both succeeded and were verified (`ralph/R0.3.5` merged through the normal
CI → `ralph-merge.yml` path).

One residual gap: `git push --delete` (and the GitHub API's branch-delete)
still returns HTTP 403 at the proxy level, even though creating and pushing
branches works. Probe branches from the reattachment check could not be
deleted and, being plain docs commits, one of them (`ralph/PUSH_TEST.md`) went
green on CI and got auto-merged into `main` before this was noticed — cleaned
up in the same commit as this entry. **Future firings: do not create
throwaway probe branches** unless you also plan to leave them merged; there is
currently no way to delete a remote branch from a fired session.

**What the wall cost while it stood:** the first firing to hit it solved
`R0.3.5` — three real bugs found and fixed, verified 10/10 green — and the
commits died with the container. The diagnosis was recovered into
`BACKLOG.md`; the code was not, and was redone from that diagnosis once push
access returned.

---

## Blocked on the owner

### `ASSET_LEDGER.md` licence claim is false
The ledger states "Everything currently in the build is CC0 1.0." It is not: the
Meshy-generated creatures and the Plumberry Plains pack are not CC0. The correct
wording depends on the owner's Meshy plan terms, which no agent can verify.

**Clears when:** the owner supplies the licence wording.

---

## Blocked on reference art — the new bottleneck

**Credits stopped being the constraint on 2026-08-11.** The owner topped the
Meshy account to **5000**, and in the same message set the rule that replaced
it: *"we should never render without me loading art first."* So a firing may
not generate anything the owner has not supplied a reference board for, the
way `docs/art/reference/12_NPC_Bases_Reusable.png` was supplied. In-engine
survey and screenshot renders are unaffected — they are how anything gets
verified at all.

The whole authorised programme is ~540 credits of 5000. Money is not what is
stopping the list below; a drawing is.

### Waiting on a reference board

- **Team Tether energy pylon**
- **Team Tether relay apparatus**
- **The legendary tether machine**

These are the three places `docs/ENVIRONMENT_AND_UI_BIBLE.md` §13 endorses
Meshy at all, and D24 confirms it: hero objects only. They are what make
modular kit architecture read as faction-specific rather than generic, and
they are needed from Band 3 onward. No board exists for any of them.

**Clears when:** the owner supplies a board, one per object, in
`docs/art/reference/`.

**Explicitly NOT on this list**, by the owner's decision: creatures, the
trainer, Grandpa and the Warden. D23 §20 forbids creature regeneration at any
balance — reaffirmed with 5000 credits available, so it was never a budget
rule — and D24 resolves the humans to rework as well. Those are
material-and-rework problems permanently.

Anything else a firing believes needs generating stops and adds a line here,
rather than spending.

---

## Resolved — the four bird species do not need `animate_bird.py`

**This entry is retracted.** The premise — "no `animate_bird.py` exists" —
was true but the conclusion drawn from it was wrong. `rig_bird.py`
(1546 lines) is not a bare rigging script the way
`rig_quadruped.py`/`rig_glider.py`/`rig_sitter.py` are: it authors all six
standard clips itself (`author_all()`), already proved end-to-end on
three winged test meshes per its own docstring, and its bone names
deliberately overlap `animate_quadruped.py`'s glider layout "so that
script still produces something sane if it is ever pointed at a bird."

The real bug was in `finish.py`'s `rig` subcommand: it called
`animate_quadruped.py` unconditionally after rigging, regardless of
`--kind`. For a bird this didn't just duplicate work — it would silently
re-detect the already-animated bird rig as a glider and overwrite
`rig_bird.py`'s bird-specific animation with generic glider animation,
including `animate_quadruped.py`'s documented faint-spin bug (root bone
yaw applied where the rig's local Y is world-up, so the creature spins on
the spot instead of toppling).

Fixed: `finish.py` now skips the `animate_quadruped.py` call when
`--kind` is `bird`, since `rig_bird.py` already produced the finished,
animated output. Proved on Galecrest, the first bird species shipped —
see `DONE.md`. **No further code work is needed for Duskhush, Pipwing, or
Reedwing** — the same `clean → texture → rig --kind bird → grade →
install` sequence used for every quadruped now works for birds too.

---

## Resolved — the key reaches a CRON firing, not a self-scheduled resume

The Meshy key is **carried in the cron Routine's own prompt**, so every
hourly-fired session has it without the owner doing anything. There is no
tool to set an environment variable on this environment, and the repository
is the one place the key must never go: GitHub history is permanent and
secret scanning would likely revoke the key on push. **A firing's own
`send_later` self-resume is not the cron Routine** — see the entry above,
found twice now — so do not expect the key there.

Use it by prefixing the one command that needs it. Never write it to a file,
never echo it, never put it in a commit message, a manifest or a report.

If `meshy.py check` fails to authenticate on a firing that SHOULD have the
key (i.e. a cron firing), the key has been rotated — say so here and stop the
art tasks rather than guessing.

---

## Play gates awaiting the owner — the loop does NOT wait here (D21)

The owner plays these whenever they can; their feedback comes back as new
backlog items. The loop keeps building past them.

- **R0.11** — play the NEW first day end to end (wake upstairs → Grandpa's
  gifts → choose and name a starter → the paths → harvest → a fight and a
  catch → camp before dark → day 2).
- **`SA0` / `SA1`** — the two P0 fixes shipped 2026-08-11 (`6dffa21`,
  `28af489`; Windows build published 13:09 UTC). Two questions only the
  owner's device can answer:
  1. **Can you talk to Grandpa now?** Walk off the bed *without* pressing it,
     then go downstairs. `tests/smoke_wake_softlock.gd` proves this headless
     and was verified to fail against the unfixed build first, but the report
     came from the device.
  2. **Is the choppiness gone?** CI cannot measure VRAM — the device is the
     instrument, exactly as with RB4. If it is better but not fixed, the next
     suspect is already written down: `vegetation.gd::_retint()` rebuilds an
     `ArrayMesh` and discards the importer's LOD chain, so every tree and tuft
     draws at LOD0 at every distance. That is `SA1-lod`, already queued.

---

## Design questions awaiting the owner

**Both entries below are closed as of 2026-08-11.** Nothing in this section is
waiting on anybody. They are kept rather than deleted because each one records
*why* the answer is what it is, and both answers are the kind a later firing
would otherwise be tempted to relitigate. The live list is "Blocked on
reference art" above.

### ✅ CLOSED — creature and human art-pipeline cohesion: rework, both halves

**Closed by `docs/decisions/D24` (2026-08-11).** The owner reaffirmed D23 §20
*with 5000 credits in the account*, which settles the one thing this entry was
still asking. §20 was never a budget rule, so a healthy balance does not lift
it — and D24 extends the same logic to the humans by reserving Meshy for Team
Tether hero objects only.

**The answer is rework, on both halves.** Paddlenewt, Pipwing and Ripplet get
`grade.py`'s palette path (`SA5`, `SA6` apply the same lever elsewhere). The
trainer and Grandpa get material work and `NP1`'s modular system, not a
replacement generation. Nothing below is waiting on the owner any more.

The budget arithmetic in the original entry is obsolete — it reasoned from 175
credits, and the balance is 5000. It is left in place only because the
*evidence* it cites is still the evidence.

The consequence is worth stating plainly, because it is permanent and someone
will want to reopen it: the fidelity gap a blind critic called *"the loudest
single problem in the whole review"* is now a material problem forever. That
is the accepted trade, not an oversight.

Original narrowing, kept for its reasoning:

**Narrowed by `docs/decisions/D23` (owner spec §20–§22, 2026-08-11).** This
entry used to ask one question about two things. It is now one question about
one thing.

- **Creatures — answered, by removing an option.** §20 forbids new creature
  meshes and Meshy generations for the Meadows outright. Replacement is off the
  table, so the only remaining answer for Paddlenewt, Pipwing and Ripplet is
  **rework in place**, through `grade.py`'s repair path (numpy and Pillow, no
  Blender, no credits). That is effectively the decision; no owner input is
  needed to proceed on it. `SA5` and `SA6` in `BACKLOG.md` are the same lever
  applied to Burrowback and the bird roster.
- **Humans — still open, and §21 raises the stakes.** §20 says *creature*; it
  does not touch the flat-shaded trainer and Grandpa standing next to the
  Warden's painted finish, which the blind review called "the loudest single
  problem in the whole review". §21 makes it worse rather than better by
  promoting those exact two rigs to base bodies for the entire NPC cast.
  §22's one-or-two optional generations are a partial lever but do not answer
  *which* assets get the treatment.
- **Not part of this question:** `R3.0`, re-running the three humanoid GLBs
  through the fixed `animate_humanoid.py`, is a pipeline re-run rather than a
  generation. It costs no credits and is compatible with §20 and §22.
- **Budget arithmetic the owner should see before deciding.** 175 credits
  remain at roughly 90 per species. "One or two" generations is realistically
  *one comfortably, two only if a human costs less than a creature*. Spending
  it on a Team Tether grunt base leaves nothing for the Warden's face, which is
  still painted rather than modelled (HANDOFF §6).

~~**Clears when:** the owner decides what happens to the trainer and Grandpa —
regrade in place, one §22 generation, or accept the gap for now.~~
Answered above: regrade in place, and accept the gap as the cost.

Original entry, kept because its evidence is still the evidence:

Raised by the 2026-08-09 site-frames critique for the three starters alone
("three assets from three different store packs"); **R0.8.5's full blind
review of the whole roster confirms it's bigger than the starters** and adds
a second axis the earlier pass never saw because it had no frame with the
Warden and the trainer together:

- **Creatures**: Paddlenewt, Pipwing and Ripplet render in a glossier,
  big-eyed toy/gacha finish that doesn't match the painted-matte naturalism
  the rest of the roster shares (the moss-and-stone material language on
  Burrowback, Mosshell, Tuskroot and Terrapup is, per the blind critic,
  "the single best piece of cohesive art direction anywhere in this set" —
  which makes the mismatch on the other three more visible, not less).
- **Humans**: the trainer and Grandpa are flat-shaded and low-detail next
  to the Warden's fully painted, richly textured finish — called out as
  "the loudest single problem in the whole review" because the trainer is
  who the player looks at for the entire game, unlike a boss seen once.

Full record: `docs/reviews/2026-08-09-r0.8.5-full-blind-review.md`. Whether
to rework the mismatched assets or replace them is an art-direction call
this evidence is for, not a call to make silently.

~~**Clears when:** the owner decides rework vs. replace (and for which
assets — the three creatures, the trainer/Grandpa pair, or both).~~
Superseded by the narrowed question above: §20 answers "rework" for the
creatures; only the trainer/Grandpa pair is still a live decision.

### ✅ CLOSED — the settlement's vernacular: Medieval Village MegaKit

**Closed by `docs/decisions/D24` (2026-08-11).** The critic asked the owner to
pick one tradition and not split the difference. The owner supplied
`docs/ENVIRONMENT_AND_UI_BIBLE.md`, which picks **the Medieval Village
MegaKit** as the Meadows civilian architecture — the Northern European branch
of the choice below, and the one the key art board's own thatch-plaster-timber
settlement panel already leaned toward.

So the answer is the critic's first option: *keep the mill and shift the whole
settlement toward a Northern European vernacular.* The red gambrel barn, the
barn-house, the shed and the coop are the assets that move; the windmill was
never the outlier once the family changed underneath it. `EV6` in
`BACKLOG.md` is that rebuild, and it is a rebuild on one kit rather than the
retint this entry assumed would be enough.

One thing the closure does **not** buy: the owner chose free Standard tiers
only, so the Source editions' Godot wind shaders and optimised collisions are
not available and `EV3` has to build that work itself.

The original question, kept because every later structure still has to join
whichever family was named:

Raised by R9.4's blind buildings critique (2026-08-11,
`docs/reviews/2026-08-11-r9.4-full-visual-pass.md`). The critic identified three
unrelated building families standing in one field and was explicit that this is
a decision rather than a defect:

- **North American farm vernacular** — the red gambrel barn, the barn-house, the
  small shed, the chicken coop. Red board-and-batten, white cased trim, X-braced
  doors. This is the majority and it is internally consistent.
- **Northern European tower mill** — the windmill. Grey stone drum, timber
  gallery, mullioned sashes, arched door. "A completely different building
  tradition, different material palette, different era… the clearest 'asset
  from a different pack' in the set."
- **The well** is a third outlier on materials specifically: a terracotta
  pantile roof, the only tiled roof in the build, over cold blue-grey stone
  against the barn's warm maroon.

The critic's own instruction: *"keep the mill and shift the whole settlement
toward a Northern European vernacular, or keep the American farm family and swap
the mill for a timber post-mill. **Do not split the difference.**"*

This matters beyond the Meadows: `MEADOWS_PROGRESSION_SPEC.md` adds a quarry, a
relay station, a mill crossing and a stronghold approach, all of which need
buildings, and whichever family is chosen now is the one every later structure
has to join. Retinting either way is cheap; choosing is not a firing's call.

~~**Clears when:** the owner names the vernacular. Note that the key art board's
own settlement panel leans European — thatch, plaster, timber framing — which
is an argument, not a decision.~~ Named: Medieval Village MegaKit, per D24.

---

Anything on `CLAUDE.md`'s flag list goes here rather than being decided:
dodge/block, party limit, weapons, type system, storage, story rewrites,
traversal philosophy, mandatory hunger/thirst, stronghold structure.
