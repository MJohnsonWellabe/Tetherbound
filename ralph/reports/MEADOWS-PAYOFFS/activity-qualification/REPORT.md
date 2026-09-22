# Meadows activity qualification — the checkable half

ROADMAP Phase 1 item 6: *"Qualify six Meadows activities."*

MEADOWS-PAYOFFS recorded the herd activity as *"unqualified toward the
six-activity floor until those relevant experience criteria are met"* — with no
mechanism to say when that changed. This adds one.

## What item 6 asks, split by who can answer it

| Criterion | Who decides |
|---|---|
| Visible lure | **Partly checkable** — is it discovered rather than pre-listed? |
| Distinct action/decision | **Owner.** Judgement. |
| Useful reward for an unchanged five | **Owner.** Judgement, and the point of the five-creature rule. |
| Acknowledgement | **Owner** in substance; see the gap below. |
| Saved completion | **Checkable.** |
| Normal-play reachability | **Owner**, at the controller. |
| One per principal region | **Partly checkable** — which bands are "principal" is a design call. |

A test that scored the judgement rows would be inventing an answer, so it does
not. `tests/test_meadows_activity_qualification.gd` asserts only the rest.

## Result: the checkable half passes

**6 tests, 45 assertions, 0 failed**, over the seven `local` rows in
`data/progression/objectives.json`:

- `band1_old_champion` — `defeated_old_bram`
- `band1_meadowhart_herd` — `band1_meadowhart_herd_found`
- `band1_broken_cart` — `band1_broken_cart_repaired`
- `band2_night_watch` — `defeated_night_watch_farro`
- `band3_river_nest` — `river_nest_doss_cleared`
- `band4_first_ironwood` — `defeated_captain_field`
- `band4_lost_creature` — `defeated_lost_creature_rue`

Seven rows against a floor of six. Each is **discovered rather than listed**
(every row names a `revealed_by`, so the log records what the player knows
rather than what the designer placed); each **tells the player what it is**;
each **completes into a durable flag with a declared scope**; **no two share a
completion flag** (one fact, one flag — sharing would tick both and leave the
second unfinishable); and they are **spread across four bands**, not stacked in
one.

## A gap found on the way, which belongs to item 8

**None of the seven optional activities appear in
`data/config/chapter_rewards.json`.** That file carries 24 reward rows, and
every one of them is a trainer, a store, a world TM pickup or ordinary wild
fights.

The activities do pay — the herd grants three Orbs, the trainer-backed ones
carry ordinary trainer rewards in `trainers.json` — but the chapter's own
reward ledger does not account for them. ROADMAP item 8 asks for a
"source-backed XP/material/recovery ledger" and solvency proof; an optional
strand that pays real materials while sitting outside the ledger is exactly
what that item would have to reconcile.

Recorded here rather than fixed: adding reward rows means choosing numbers,
which is a design decision and not a mechanical repair.

## What this does NOT claim

- It does not qualify the six. It qualifies the half a file can check, and
  names the half that needs the owner.
- No activity was played. Reachability, pacing and whether a reward is worth
  the detour are untouched.
- Four of the seven complete on a trainer defeat flag. Whether a trainer fight
  is a "distinct action" versus the chapter's many other trainer fights is
  precisely the judgement call left open.
