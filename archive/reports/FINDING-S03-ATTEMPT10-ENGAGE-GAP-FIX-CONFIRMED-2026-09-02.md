# S03 attempt 10 finding: the ally-species engage-gap fix works; two narrower gaps remain

**Author:** operator agent, `ralph/GATE-F-S03-CATCH-LOOP`, attempt 10.
**Candidate:** `39d4fa20` (this branch, carrying `operator_harness.gd::_find_entity`'s
species/`_poi_kind` fix, on top of `main`'s merged-in 2->10 Revive grant).
**Run directory:** `ralph/reports/gate-f-run-20260902T053310Z-s03enginefix/S03`,
seeded from the same confirmed-fresh `S02-exit.json` attempt 9 used
(`gate-f-run-20260901T220548Z-s03fix/S02`) — S02 itself is untouched by this
fix, so it was copied rather than re-run.
**Segment:** S03 catch loop, all 10 numbered attempts. 410P/30F/4SKIP/7 captures
delegated to S03C (not run this pass — logic lane only, no display server in
this session's container).

## 0. What changed and why (recap)

Attempt 7's and attempt 9's own findings (`FINDING-S03-ATTEMPT7-TRACKAIM-
REVIVE-WALL-2026-09-02.md` §4, `FINDING-S03-ATTEMPT9-REVIVE-GRANT-CONFIRMED-
2026-09-02.md` §2.2) both recorded the same secondary defect: several of the
ladder's 10 numbered attempts never reached a fight at all, `interact_with`
FAILing on "Put Bramblebun away" / "Bramblebun is out of the fight" instead
of "Engage Bramblebun". Root cause, found this session by reading
`operator_harness.gd::_find_entity` against `encounter_director.gd`: a
species_id match had no way to tell a **wild** creature (`wild_creature.gd`)
from the player's own **deployed ally** (`follower_creature.gd`, node name
"AllyCreature") — both carry the same `species_id`, and the ally follows
close behind the trainer, so it kept winning the ladder's `move_to_entity
('bramblebun', rank: N)` resolution the instant the first Bramblebun was
caught and summoned. Fixed by restricting the species_id bucket to nodes
`_poi_kind` classifies as `"wild"` (the same classification `poi:wild`
already uses) — a species match can now only ever resolve a genuine wild
creature. Committed `39d4fa20`.

## 1. The fix works, measured directly

Engage success across the 10 numbered attempts, this run vs. attempt 9
(pre-fix, same starting save shape):

| | attempt 9 (pre-fix) | attempt 10 (post-fix) |
|---|---|---|
| numbered attempts that reached "Engage Bramblebun" | 6 of 10 (a,c,e,f,h,i partial) | **8 of 10** (a,b,c,d,e,f,i,j — j reached the prompt but then lost aim to a fence, see §3) |
| attempts that never got past `move_to_entity`/`interact_with` on an ally-match | 4 (b,d,g,j) | **0** — no ally-match FAIL anywhere in this run's notes |
| party size at S03-39 (`min: 5`) | 3 | **4** |

No `"Put Bramblebun away"` / `"is out of the fight"` FAIL anywhere in this
run's `notes/S03.md`, across all 10 attempts and every recovery block. The
ally-match defect is gone. The two remaining engage-side losses this run
(attempts g and h) are a **different, newly-surfaced** defect — see §2 — not
a recurrence of the fixed one.

Real throws landed: 5 `catch_throw` events, 7 `catch_result` events (some
throws that failed to physically commit — see §4 — still resolve a result).
One catch succeeded (`"party grew" 0->3` at the S02 carryover, then `3->4`
mid-ladder). Party ended the segment at 4 of 5, still short of `S03-39`'s
`min: 5` bar — **S03 has not converged.**

## 2. New finding: an NPC (Lark) overlaps the practice-meadow wild cluster

Attempts g and h both failed to engage, but not on the ally: attempt g's
`interact_with` (`S03-32g2`) found the live prompt was **"Greet Lark"**,
not "Engage Bramblebun" — a villager NPC's greet prompt won the interaction
arbiter's priority-then-nearest tie-break over the wild creature the walk
had just arrived at. That triggered `narrative_modal` (presumably Lark's own
proximity greeting), which then held locomotion for the rest of attempt g's
recovery block and all of attempt h (`S03-32g2w`/`S03-32gr1`/`S03-32gr9`/
`S03-32h`/`S03-32h2` all FAIL on `input_context=narrative_modal`), burning
roughly 174 seconds of segment budget and two whole numbered attempts before
`S03-32h2w` finally found the world again.

Measured, not guessed:

- `data/config/bands/band1_lower_meadows/spawns.json` order 0: the practice
  Bramblebun cluster is centred at **(30, -40)**, radius **15.0m** (`_why_ow5d`/
  `_why_game_11` — this is the deliberately-pinned "chapter's designated
  teaching fight").
- `data/config/village_npcs.json`: Lark (the courier) stands at **(19.6,
  -35.3)** — moved there 2026-09-01 (`OWNER-0901-VILLAGE-POPULATION`, commit
  `8edfcf58`) specifically "down the Practice Meadow road ... toward the
  South Bridge crossing", to thin the village square.
- Distance from Lark to the cluster centre: **11.41m** — *inside* the
  cluster's own 15m radius disc.
- `npc_body.gd::add_prompt()`'s default greet radius is **3.8m**;
  `data/config/combat.json`'s `wild.wander_radius` is **7.0m** from each
  creature's own home (which can itself be anywhere in the 15m disc). Worst
  case, a wild Bramblebun can be engaged as far as 15+7=22m from the cluster
  centre — so full, unconditional clearance for Lark's greet prompt needs
  centre-distance >= 22 + 3.8 = **25.8m**. Lark is at 11.41m: not a rare
  edge case, a structural overlap.

**Attempted and deliberately not landed.** Wrote `tools/_probe_lark_clearance.gd`
(reuses `tools/_probe_civilian_placement.gd`'s own terrain/clearance method)
and checked moving Lark further along the same Practice Meadow road, in the
same direction his 2026-09-01 move already went. It does not resolve cleanly:
`terrain_playground.json`'s "Practice Meadow" road (`[10,-10]->[18,-24]->
[30,-40]`) **terminates at the cluster's own centre** — there is no
"further down the same road, away from the cluster" that stays on that road,
and every candidate probed on it (up to (32,-62), 22m out) still fails the
25.8m clearance check. The only direction that clears is back toward the
village square end of the road, which fights the exact reason he was moved
out here in the first place (`OWNER-0901-VILLAGE-POPULATION` / repeated
`OWNER-*-VILLAGE-POPULATION-REGRESSION` complaints, landed and reopened
twice already in three days). Deciding where a villager stands is a real
trade-off between two already-owner-visited concerns (village crowding vs.
this new collision), not a mechanical bug fix with one obviously-correct
answer, so it is reported here rather than landed. The probe script is kept
(`tools/_probe_lark_clearance.gd`) so the next pass does not re-derive the
same numbers.

## 3. Attempt j: a fence blocks line of sight

`S03-36j2` (track the reticle) FAILed after the full 240-frame budget:
`"reticle never confirmed on body ... last saw line_of_sight_blocked"`. The
`catch launch` debug log for this attempt reads `first_hit=FenceCornerGuard_15
los=false reason=line_of_sight_blocked` — the throw's own line-of-sight ray
hit a fence corner collider before it reached the target. This is a single
specific stance (attempt j's own rank-cycled target and the player's
resulting standing position), not reproduced elsewhere in this run. Recorded
as a candidate for a future pass; not investigated further here since it
cost one attempt, not several, and (unlike §2) has no quantifiable structural
cause found yet.

## 4. Secondary observation: not every "eligible" aim survives to commit

The real per-attempt `catch launch: commit eligible=...` log (`throw_aim.gd`'s
own `_commit_launch_assist()`, the same live `aim_report()` `track_aim`
reads) recorded 11 commit evaluations this run: 7 `eligible=true`, and 4
`eligible=false` — one `line_of_sight_blocked` (attempt j, §3 above), one
`reason=behind` at `reticle=65.86` from a no-op press with no live fight
(attempts g/h's own downstream steps, harmless), and **two**
`reason=reticle_outside_body` against a real, visible Bramblebun
(`reticle=1.480` and `5.280`, against a `0.552` eligible threshold). The
7 `eligible=true` commits match exactly attempts a,b,c,d,e,f,i's 7 `track_aim`
PASSes, so the two `reticle_outside_body` misses are NOT a case of the
harness declaring success on an attempt that then silently failed — they sit
outside the numbered ladder's own accounted-for throws. Not chased further
this pass (budget); flagged as a loose thread — if the numbers below need
re-measuring, check whether these two commits correspond to a later part of
S03 (e.g. the tournament-training fight) reusing the same `throw_aim.gd`
path, or to a same-frame double-evaluation, before assuming it is target
drift in the track_aim-to-press handoff.

## 5. Catch-rate math: real, working, and not (by itself) a bug

`data/config/catching.json`: Bramblebun's `catch_rate` is 0.6
(`data/creatures/species.json`), `hp_factor_full=0.10`, `hp_factor_empty=1.0`,
`hp_curve=1.2`. The ladder's own script chips each target with exactly 3
quick attacks before throwing, which measured across this run's real fights
leaves targets at roughly 50-65% HP. At that band, `hp_factor` computes to
roughly 0.36-0.49, so with a basic orb (`multiplier: 1.0`) and an
`accuracy_bonus` between `edge_bonus` (0.80) and `centre_bonus` (1.45), a
single throw's catch chance lands roughly in the **17%-43%** range — this
run's 1-for-5 (with 7 real commits, closer to 1-for-7) is squarely inside
that band's ordinary variance, not evidence of a broken roll. `min: 5` needs
3 more catches beyond the 2 the segment starts with; at a representative
p~0.25-0.35 per real commit, reaching 3 successes in 7-8 real attempts is
roughly a coin flip to somewhat favourable, not a near-certainty — so a
single scripted run landing short is expected outcome variance from a
deliberately steep, TUNABLE-by-design catch curve (`catching.json`'s own
header), not a defect. No change made here; recorded so the next
convergence attempt does not re-derive this arithmetic from scratch.

## 6. Where this leaves S03

Not converged: party ended at 4 of 5, `S03-39` (`min: 5`) still FAILs.
Compared with attempt 9, the segment moved from a hard, structural block
(4 of 10 attempts eaten by a harness bug) to expected statistical variance on
a small number of real throws, plus two narrower, now precisely diagnosed
gaps (§2 Lark/cluster overlap costing 1-2 attempts, §3 one fence LOS block
costing 1 attempt). Recovering either of those would raise the effective
throw count from 7 toward 9-10, meaningfully improving the odds of reaching
5. §2 is reported rather than landed because it is a real placement
trade-off already visited twice by the owner this week, not because it is
unclear as a bug. §3 needs another data point before it is understood well
enough to fix. Recommended next step: another attempt (11) as-is to get a
second, independent read on how often §2/§3 recur versus pure catch-RNG
variance, and/or an owner call on where Lark should actually stand.

## Appendix: infrastructure note

This session downloaded Godot 4.7-stable (linux x86_64, official release)
directly and built a fresh `.godot/imported` cache, since no cached binary
was present in this container (`ralph/conventions.md`'s documented
`$HOME/.cache/tetherbound-art/godot` path was empty here). Both are ordinary,
reproducible setup, not part of the candidate diff.
