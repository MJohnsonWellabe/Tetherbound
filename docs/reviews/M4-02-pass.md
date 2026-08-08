# M4 gate, round 2: PASS

**Date:** August 2026
**Judge:** blind sub-agent, `.claude/skills/systems-judge`
**Shown:** the ten M4 acceptance bullets, `shots/session_party.log`, three frames.
**Not shown:** source, diffs, commits, the round-1 refusal, or any description of
the design. It did not know a previous round existed.

> **PASS** — every bullet is MET.

All ten. The two that were refused in round 1 are now evidenced:

- **Catch pal:** *"The full arc is in the transcript, not just an outcome flag"* —
  `party size before the catch: 0` → `fight outcome: caught` → `caught creature
  is now party member 0: Meadow Hopper (wild_rabbit)`, plus both guard
  conditions.
- **Nickname:** the rename, the refusal that *"did not clobber the existing
  value"*, and `Thistle` surviving the reload and rendering while unnamed pals
  fall back to species names.

It checked the trait arithmetic itself again — `95.0 × 0.98 = 93.1` — and
verified the star thresholds are *"computed rather than decorative"*. On
persistence it noted the frames were captured **after** the reload, so the party
screen is *"a second, independent consumer"* of the restored state.

## Four findings it raised anyway, and what each is

**1. A fight started with an empty party.** *"`party size before the catch: 0`
immediately followed by `fight started: true`... Something is either fighting on
the player's behalf or the fight-start guard is missing."*

Real, and the most valuable thing in this review. The deployed ally is still
M3's separately-spawned `STARTER_SPECIES` instance, which is not a party member
and never was. The party now exists and combat does not read from it. That is a
seam M4 was supposed to close and did not.

**2. Levelling heals.** *"levelling from 1 to 26 silently healed the pal from 2%
to 70%."*

Correct observation, deliberate design, and worth the owner's opinion rather
than a silent fix. Absolute damage is preserved — 91.24 missing before and
after — and the reasoning recorded when it was written is that *"a pal that
levels at half health getting half its reward reads as the game taking something
back."* The judge is right that the FRACTION jumps; the author is right that the
DAMAGE does not. Flagged, not changed.

**3. The rename screen bleeds through.** *"Two superimposed hint rows is exactly
the case where a player cannot tell which buttons are live."* Unambiguous defect.

**4. No player input in this session ever mutated party state.** *"the
controller-to-model wire is proven for navigation and unproven for every state
change in this milestone."*

The sharpest of the four. Every state change — the catch aside — went through a
direct API call. The rename screen was opened and abandoned at `0 / 12` with
nothing typed. This is the same class of gap as round 1's refusals, caught
before it became one.

It also found a harness bug: `other members are still unnamed: Bramblit, Meadow
Hopper` omitted Thornback, and *"a summary line that does not match the party it
just described is a line to fix before it is trusted on something less
checkable."*

## What happens to these

1, 3 and 4 become work now. 2 goes to the owner as a design question.
