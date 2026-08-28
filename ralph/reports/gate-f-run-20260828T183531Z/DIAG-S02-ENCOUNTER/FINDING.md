# DIAG-S02-ENCOUNTER — the opening's wild encounter is not broken

**Run:** `gate-f-run-20260828T183531Z`. **Date:** 2026-08-28.
**Candidate (the GAME):** `main@26f0db4`, unchanged. This probe reads the game
and writes nothing to it.
**Instrument:** `tools/gate_f/diag/probe_s02_encounter.gd` (rig).
**Transcripts:** `pass2.txt`, `pass3.txt`, `pass4.txt` beside this file.

## The question

Segment S02 recorded six FAILs with one root cause, already on the record: the
beat-6 wild encounter never engaged. There is no `combat_start` event anywhere
in `S02/telemetry/events.jsonl`, so the first catch never happened, the party
stayed at 1 of 2, the objective chain stuck on *"Catch your first wild
creature."*, and `road_gate_open` was never set.

Section 16.3's "covered by broader root cause" collapsed six FAILs into one.
What that one FAIL was **about** was left open, and the two candidates are
completely different findings:

- **GAME** — the encounter cannot be staged. A dead end in the opening, on the
  critical path, at the frozen candidate.
- **RIG** — the encounter stages fine and the harness never triggered it. More
  rig error, and no statement about the game at all.

## The answer: RIG

**The full production opening was driven end to end, and the encounter worked.**

`pass3.txt` boots a clean process, loads nothing, grants nothing, and drives the
real panels with synthetic input: Grandpa's briefing advanced by predicate (11
taps), the starter picker, the naming pad walked cell by cell to a letter and
then to Done, and `grandpa_named` advanced until nothing owned input. Then the
player stands at **the exact coordinates S02 pressed at**, read out of S02's own
telemetry — `(26.78, −38.32)` — and presses `interact` once:

```
[live] party size after the opening      = 1
[live] director.ally_body()              = AllyCreature
[live] nodes named AllyCreature in tree  = 1
[live] C. standing at S02's own press point: 26.78, -38.32  (5.99 m from the practice creature)
[live]    director.interaction_offer = {"actionable":true,"distance":5.990,"label":"Engage Bramblebun","priority":0}
[live]    arbiter.winning_provider() = res://scripts/combat/encounter_director.gd
[live]    pressed interact: is_fighting false -> true   >>> A FIGHT STARTED
```

Every element of the situation S02 was in works: the bramblebun is staged and
alive, the follower body is built by the naming beat, the interaction arbiter
awards the press to the encounter director, the offer is actionable at 5.99 m
against a 6.00 m reach, and one press starts the fight.

`pass4.txt` reaches the same place by a different route — the starter granted
through the game's own `adopt_starter()` rather than through the naming UI — and
adds the measurement the fixed-coordinate walk made worth taking: standing still
at that point for 30 play-seconds, the game offered *"Engage Bramblebun"* on
**30 of 30 samples**, nearest creature steady at 5.99 m. Distance from where S02
stood is not what stopped it.

**So the chapter's opening encounter is not a dead end, and no finding in this
run may be read as saying it is.**

## What actually gates a fight, and why it explains the rest of the run

`encounter_director.gd::_engageable()` returns null when no creature is
deployed — **before it measures any distance**:

```
if _ally == null or _manager == null or _ally.fainted:
    return null
```

With a party but no deployed body the game does exactly the right thing. It
shows a **non-actionable** line naming a different button:

```
[S02-exit] director.interaction_offer =
   {"actionable":false,"priority":-1,"label":"<RB glyph>   Call out Moss"}
[S02-exit] pressed interact: is_fighting false -> false   >>> NO FIGHT
```

`interact` is X. The verb the line names is `creature_recall`, RB. `interact`
doing nothing there is correct.

Three measured facts then close the rest of the run:

1. **A load restores the party and deploys nothing.** `pass2.txt`, S02's own exit
   save through `save_game.gd::load_slot()`: party 1, `ally_body()` null, zero
   `AllyCreature` nodes. `_sync_active_creature()` declines to summon when
   nothing is out, in its own words — *"Nothing out to swap; the new active
   creature comes out on next recall."*
2. **Every journey segment from S03 on begins with a load** (`seed_save` →
   `boot` → the title-screen Load path).
3. **No journey step-script ever presses `creature_recall`.** S01–S10 contain
   zero occurrences of the action. `X01`, `X02`, `X03`, `X03C` and `X06` contain it.

⇒ From S03 onward, **no press at any range could have started any fight**, and
the run's own census agrees: `combat_start` appears **zero** times in S01, S02,
S03, S04 and S05 — including a whole tournament. The harness does emit that type
(`operator_harness.gd:4748`, on an edge of `combat_running`), so the absence is
real and not an instrument blind spot.

That is the harness never pressing a button the game puts on screen. It is not a
game defect, and every combat, catch, party-size, gate-flag and objective
assertion downstream of it is a statement about the rig.

## What is still open, and the instrument that has to close it

**S02 itself is not fully explained, and this file does not pretend it is.**
S02 was live — it never loaded — and its own telemetry shows `adopt_starter()`
succeeded there: the party grew 0 → 1 carrying the name the pad typed, which
`sequence_director.gd::_adopt()` only reaches after that call returns true. So a
follower body existed at t=199.7, and the press failed at t=219.4, twenty
seconds and fifty-five metres later.

**Why it was not there at the press cannot be recovered from the artefacts**,
because `scripts/debug/gate_f_probe.gd` records neither of the two things that
would say: whether a creature is deployed, and what the interaction prompt
actually read at the moment of a press. Its `active_creature()` reads the
*party's* active member, not the deployed body, so S02's `"active_creature":
"Moss"` on every row is consistent with both answers. That gap is **RIG-8** in
`GATE_F_RUN_3_RIG_FINDINGS.md`, and closing it is what a re-run of S02 needs.

One candidate is named because S02's own notes already measured it and left it
in the script: `S02-28` advances `grandpa_named` with a **fixed count of four
taps**, and its own observation says *"`grandpa_named` is THREE lines … every
tap past the third can re-open the conversation the previous tap just closed. 4
taps is three lines plus one."* That is CD-3's forbidden shape — a guessed
repetition count for a state-changing UI — recorded as an observation and then
left in place. It is a candidate, not a conclusion, and it is written here as
one.

## Scope

This is a DIAG instrument (§0.1). It makes exactly one kind of claim — whether a
fight can be started, and from where — and it uses two shortcuts to make it: it
boots the world scene directly and it places the player at named coordinates.
Neither is a claim about how a player would reach that place, and **no pacing,
navigation, difficulty or economy claim may be sourced from this file.**
Section J's "record defects before any diagnostic rerun" is satisfied: S02's six
FAILs were on disk with their evidence before this probe was written.

Two honesty notes about the instrument itself:

- The first revision seeded S02-exit into **slot 4** — §B's handoff slot — while
  segment S05 was live in another process. S05 was unharmed (it had already
  loaded, and its own `save_out` rewrites that slot at its last step), but a
  diagnostic that can overwrite the run's handoff save is a hazard whether or
  not it did harm. The probe now uses slot 2 and never touches 4.
- `pass2.txt`, `pass3.txt` and `pass4.txt` were taken while segment S06 was
  running in another process on the same four-core box. Nothing in them is a
  timing measurement; every claim is about what the game offers and whether a
  press is accepted, neither of which contention can change.
