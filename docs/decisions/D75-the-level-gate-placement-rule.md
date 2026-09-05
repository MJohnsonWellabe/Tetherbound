# D75 — A level gate sits only on a band's gatekeeper, at the next band's entry level minus one

**Date:** 2026-09-04 · **Decided by:** the W19-CONTRACTS lane, as the orchestrator's
recorded design call, implementing `docs/owner/OWNER_DIRECTIVES_2026-09-04-B.md`
D-0904B-4 and amendment A-4 (owner-directed; this record decides *placement and number*,
which the directive left open). Plan row CL-W4 in `docs/GATE2_GATE3_CLOSURE_PLAN.md` §2.G.

## What the owner decided, and what was left open

> you can't cross the bridge til you're level whatever plus you get the key. then it would
> prompt you to go back and fight more to get a level up.

> gate just make the fight not start unless you're a certain level. the guy can just say
> "you're too low level I'll crush you and send you crying to Grandpa"

So: **key and level; the level is the trainer refusing, in character; the fight does not
start.** Mechanically a fifth reason `encounter_director.gd::can_challenge()` (called from `trainer_npc.gd`) can be false
(today: already beaten, no usable ally, mid-battle, malformed spec), and — the dark-features
T1 note in that file — a too-low player must hear **the taunt**, never the already-defeated
line. `MEADOWS_PROGRESSION_SPEC.md` §3's "a physical key/mechanism, not a UI level lock"
survives: a trainer who sizes you up *is* the world creating the gate.

Left open: **which** trainers or crossings carry a level, and **what number** — the
brief's "the number for the South Bridge relative to the tournament exit level."

## The decision

### 1. Placement: only a band's gatekeeper carries `min_level`

A `min_level` goes on **exactly one trainer per band boundary**: the trainer whose defeat
is the critical path's way into the next band. Nobody else — not optional trainers, not
relay pickets, not the tournament rounds, not a captain's own patrol — carries one.
Crossings and gates (`gated_crossing.gd`, `road_gate.gd`, `item_gate.gd`) **never** check
a level; the key is theirs, the level is the trainer's.

| Boundary | Gatekeeper (`trainers.json` id) | What they hand over | `min_level` |
|---|---|---|---|
| Band 1 → 2 | `south_bridge_grunt` (Tether Grunt, the near landing) | `south_bridge_key` | **8** |
| Band 2 → 3 | none — the Warrens guardian is wild and the band's exit is a walk | — | — |
| Band 3 → 4 | `relay_captain` (Captain Vance) | `relay_captain_defeated` → Sela → `mill_bridge_gear` | **11** |
| Band 4 → 5 | the three Sigil captains, `captain_riverwatch`, `captain_field`, `captain_ridge` | one Sigil each; the Sigil gate wants all three | **14** each |
| Band 5 → the Hall | `stronghold_patrol` (Patrolman Verrick, the outer works) | the gauntlet's first rung | **16** |

Four gated boundaries, six trainers, because the Sigils are one lock with three keys (SF34,
`item_gate.gd`) and each key's holder refuses at the same number.

### 2. The number: the next band's `team.enter` minus one

`data/config/chapter_curve.json` `regions[].team.enter` is the **measured** level a lead
creature arrives at each band (`tools/_probe_pacing.py`, re-measured G3-ECONOMY-0903:
3 → 9 → 12 → 15 → 17 → 21). A gatekeeper's `min_level` is **the next region's `enter`
minus one**:

| Gate | next band `enter` | `min_level` |
|---|---|---|
| South Bridge | 9 | 8 |
| Relay Captain | 12 | 11 |
| Sigil captains | 15 | 14 |
| Hall patrol | 17 | 16 |

The minus one is slack: a player who has done the critical path arrives *at* `enter` and
is never refused; a player who has skipped what the path offers is refused by one level or
more and told to go and get it. **The rule is a formula, not four numbers**, so a retune
of the curve or the award moves every gate together and `tests/test_trainers_data.gd`
asserts the relationship rather than the constants.

**The South Bridge relative to the tournament exit level, as asked:** the tournament's
entry floor is `min_level 5` (`tournament.json`); its three rounds field 7/8, 9/9 and
10/10/11; `chapter_curve.json` measures the lead leaving Band 1 at **9** after the
tournament and the bridge fight. The bridge's **8 is one level under the tournament exit
level** — a champion crosses; a player who beelined from Tam's tools to the crossing at
5–6 is turned back and, per the directive, prompted.

### 3. What is checked: the party's highest level

`can_challenge()`'s new reason reads **the highest level in the party**, not the active
creature and not an average. The owner's line is about *you* ("you're too low level"),
and a team's ceiling is its strongest member; a player who has one creature at 8 and four
at 4 has done the levelling the gate asks for and will discover the bench at the fight,
which is the fight's job, not the gate's. `Party.members()` already exposes it.

### 4. The refusal is a conversation, and it names the remedy

Each gatekeeper gains a `too_low` conversation beside `challenge`/`defeated`, chosen when
the level reason is the *only* false reason (already-beaten and no-usable-ally keep their
own lines; ordering in `_on_challenged()`: beaten → no ally → **too low** → challenge).
Reference wording, tunable by the dialogue lane, in the owner's register:

- South Bridge grunt: *"Level what? I'd crush you and send you crying back to Grandpa.
  Go fight the fields for a while. Then we'll talk."*
- Captain Vance: *"Not yet. You'd make it through Hess and Orrin and you'd stop at me.
  Come back when your five have earned the river."*
- A Sigil captain: *"A Sigil isn't taken by someone at your level. The road behind you
  is full of things to fight."*
- The Hall patrol: *"The Warden doesn't waste his time. Neither will I. Grow, then
  knock."*

Every line names the remedy (fight more, come back) and none names a number on screen.
The level itself is shown in one place: **the trainer's `foe` pin tooltip on the full
map** (C2 T-3) reads "Refuses below level 8" once the player has been refused, so the
target is legible without the trainer saying it.

### 5. The prompt does not change

`trainer_npc.gd::_prompt_for()` still reads "Challenge %s" for an unbeaten trainer,
whatever the player's level: a gate that hides its own button is a wall; one that answers
the press in character is the owner's design. (A-2's *beaten* trainers lose the button —
that is CL-W5(a), unchanged by this.)

### 6. Dependencies, restated because they decide when this ships

- **Density first** (`FINISH_THE_MEADOWS.md`, "The dependency to state plainly"): no
  refight plus a level gate means wild encounters carry the regrind. The gates land
  **after** the density pass has landed at least the band the gate leads *out of*, or the
  gate is the wall the amendment says it must not be. The South Bridge gate therefore
  waits on Band 1's density (already the densest — it may ship first); Vance's waits on
  Bands 2–3; the captains' on Band 4; the patrol's on Band 5.
- **Progression visible** (CL-W6, prompt 73): a refusal that says "go level" to a player
  who cannot see a level is a taunt with no answer. Ships after or with prompt 73's
  level/XP feedback.
- **C4** (`C4_CAMPING_NECESSARY.md`): a turned-back player fights more and strains more;
  the nearest rest point is the camping chain's pin. No coupling in code.

## Why

- **One gate per boundary, on the gatekeeper.** A level check anywhere else — on an
  optional trainer, on a picket in the middle of a gauntlet — is a wall with no story,
  and a gate on a *crossing* is the UI lock the spec forbids. Putting it on the trainer
  who hands over the key keeps key-and-level as **one person's** refusal.
- **`enter − 1`, not a hand-typed number.** The chapter's levels have been mis-measured
  once already (`chapter_curve.json` `_comment_measurement`: the probe was wrong for
  twelve days and nobody re-ran it). A gate pinned to a formula over the measured curve is
  re-derived every time the probe runs; a gate pinned to "8" is stale the first time the
  award changes.
- **Highest level, not active.** The active creature is a combat choice made at the
  moment; the gate is about preparation. Checking the active creature would let a player
  swap to their strongest to pass and then fight with whoever, which is fine — but it
  makes the refusal about a menu, not about the team.
- **Six trainers, not one.** The owner's example was the bridge; the directive's
  sentence ("then it would prompt you to go back and fight more") is a shape, and it is
  wanted at every boundary where the next band's opposition outlevels a beeliner. The
  Band 2 → 3 boundary is the exception because its gate is a wild fight the player can
  also *catch* their way through, and a wild that refuses to fight is not a thing.

## What was rejected

- **A `min_level` on the crossing itself** (`gated_crossing.gd`). A UI lock by another
  name, the exact thing the spec and the amendment both refuse.
- **A level on every Team Tether trainer.** Turns the relay's four-fight ladder into four
  refusals and the Hall's gauntlet into a staircase of taunts; the amendment's "the fight
  does not start" is a gate, not a mood.
- **The average party level.** Punishes a player who caught a low-level temptation late
  (which the five-slot design wants them to do) and rewards benching it.
- **Showing the number in the taunt.** The owner's line has no number in it, and the
  spec's "levels are not UI locks" is about exactly that sentence. The map tooltip carries
  it, after a refusal, for a player who wants it.

## Where it is wired

`data/config/bands/*/trainers.json` (six `min_level` keys and six `too_low` conversation
ids); `scripts/world/trainer_npc.gd` (the fifth reason and its ordering);
`scripts/combat/encounter_director.gd::can_challenge()` (the `party` read);
`data/dialogue/bands/*` (six lines); `docs/specs/MEADOWS_PROGRESSION_SPEC.md` §3 Gate 1
(one added line: *"and the gatekeeper refuses, in character, a party below the next band's
entry level minus one — D75"*, leaving "not a UI level lock" standing);
`tests/test_trainers_data.gd` (every trainer with `min_level` is one of the six; each
equals the next region's `team.enter − 1` from `chapter_curve.json`; every one carries a
`too_low` conversation that exists); `tests/test_dialogue_runner.gd` or a new
`tests/test_level_gate.gd` (a party at `min_level − 1` gets `too_low`, at `min_level` gets
`challenge`, a beaten gatekeeper at any level gets `defeated`, a party with no usable ally
gets the no-ally line — the four reasons never collapse); `tests/smoke_gate_b_continuous.gd`
(the bridge fight still starts for a champion's team).
