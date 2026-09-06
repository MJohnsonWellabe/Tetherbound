# MP encounter protocol — Stage B lane 4.A

**Status:** contract. Lanes 4.B (creature ownership and host bodies), 4.C (encounter core and
catch arbitration) and 4.D (trainers, bosses, tournament, per-participant rewards) implement
from this file. **Date:** 2026-09-06. **Binds:** D96 (the host simulates every non-player body),
D103 (host transactions with versions), the multiplayer directive §4 and rules 4–8, 15, 20.

Everything in §1 was read off the code on `main` at `3cc5b209`, with line numbers, because the
whole protocol turns on where the existing seams already are. If a line number has moved, the
seam is the named function, not the number.

---

## 1. The seams that already exist

| Seam | Where | Why it matters here |
|---|---|---|
| One entry to a fight | `combat_manager.gd::begin(player, wild, ally_body, party, camera_rig, best_creature, opponent_owned)` :330, called only from `encounter_director.gd::_start_fight(wild, opponent_owned)` :1872 | There is exactly one door. The protocol does not add a second; it adds an authority check behind this one. |
| Wild vs trainer vs boss | the single `opponent_owned` bool — the director's own comment at :1870 calls it "the whole of what a trainer's creature is" | One encounter record covers all three. A boss is data, not a code path. |
| Player strike | `_resolve_player_strike()` :833 → `MATH.move_connects(_pending_move, origin, facing, target)` :842 → damage with one `_rng.randf()` :863 | The connect test and the damage roll are already separated by twenty lines. The host takes both; the peer keeps neither. |
| Enemy strike | `move_connects` :1251 → `_rng.randf()` :1275, aimed at `_ally_body.centre()` | Already host-shaped: one opponent striking one target. In a session the target is chosen among participants (§5). |
| Catch | `_on_orb_struck(target, offset)` :1401 → `CATCH.resolve(catch_rate, hp_fraction, thrown_orb_id, offset, radius, _rng.randf())` :1430 | A pure function of six values, five of which the host can hold or re-derive. This is why catch arbitration is cheap. |
| Catch → party | `encounter_director.gd::_resolve_catch(kept)` :1991 | One place a caught creature becomes someone's. In a session it becomes the winner's, and only the winner's. |
| Ballistics, pure | `throw_aim.gd::ballistic_direction` :812, `predict_launch_point` :837, `within_ballistic_reach` :870, `launch_target_velocity` :882; `orb.gd::closest_approach(from, to, point)` :555, `closest_approach_ahead(from, direction, point)` :583 | The host can re-derive an orb's closest approach from launch parameters alone. No peer has to be trusted with the number that decides a catch. |
| The deployed body | `_ally_body.name = "AllyCreature"` :1037, one per director | Becomes one per owner in 4.B. The name is a lookup key today; that is the thing to fix, not to work around. |
| Trainer resolution | `_finish_trainer_battle(won)` :2307 | Where the world's defeat flag and the per-participant rewards part company (§7). |

---

## 2. The one rule the whole protocol exists to enforce

**No peer may author both a hit and the position it landed on.**

An earlier draft of this design let the engaging peer simulate its own opponent and report
outcomes; adversarial review killed it, because the same process would then supply both the
strike and the target it was tested against, leaving the host a counter rather than an
authority. So:

- The **host simulates every non-player body** — wild creatures, trainer creatures, bosses
  (D96).
- A **peer simulates only its own trainer and its own deployed creature**, and replicates
  their transforms continuously.
- At strike time the host therefore already holds an **independent** position for both the
  attacker and the target, and tests the intent against its own copy.

A peer that lies about its position gets a strike that misses, not a strike that hits.

---

## 3. The encounter record

Host-owned, one per live fight, addressed by `encounter_id`. Replicated to participants; a
non-participant in the same realm receives only enough to draw the bodies.

```
{
  "encounter_id": String,     # host-minted, unique for the session
  "realm":        String,     # explicit, never Game.current_realm (D97)
  "kind":         String,     # "wild" | "trainer" | "boss"
  "opponent":     { "species_id", "level", "hp", "hp_max", "moves", "owner_npc" },
  "participants": { peer_id: { "character_id", "creature_uid", "joined_seq" } },
  "phase":        String,     # "engaging" | "active" | "catching" | "resolving" | "done"
  "seq":          int,        # host commit counter, so a peer can spot a gap
}
```

`hp` on this record is **the** hit points. A participant's HUD renders it; nothing else is
authoritative, and a client never decrements it locally "for responsiveness" — a bar that
un-drops is worse than a bar that lags.

---

## 4. Intents

All reliable, on the ledger channel (`CHANNEL_LEDGER`, D95). Each is answered with
`world_ledger.gd`'s verdict shape, so no caller branches on the type of the answer.

| Intent | Payload | Host validates |
|---|---|---|
| `engage` | `encounter_id?`, `realm`, `target_uid`, `creature_uid` | The target exists in that realm, is not already `done`, the creature is this peer's and is alive. Absent `encounter_id`, mints one. Joining a live fight is the same intent (§6). |
| `strike_intent` | `encounter_id`, `move`, `origin`, `facing` | §5. |
| `catch_attempt` | `encounter_id`, `launch_point`, `direction`, `orb_id`, `spent_seq` | §8. |
| `switch` | `encounter_id`, `creature_uid` | The creature is this peer's, alive, and not already out. |
| `disengage` | `encounter_id` | Always accepted; removes the participant (§9). |

**`strike_intent` carries no damage number and no target.** It carries what the player did —
the move, where they were, which way they faced — and nothing about what happened. That
asymmetry is the protocol.

---

## 5. Resolving a strike

On `strike_intent` the host:

1. Rejects it if the peer is not a participant, the phase is not `active`, or the move is off
   cooldown-by-the-host's-clock.
2. Takes the **host's own** position for the striking creature — not the `origin` in the
   intent. `origin` is used only for the latency tolerance in step 3.
3. Runs `MATH.move_connects(move_cfg, host_origin, facing, host_target)` exactly as
   `_resolve_player_strike()` :842 does today, with one addition: the test also passes if it
   connects against the target's position as of any host tick within
   `strike_latency_tolerance_ms` (a `multiplayer.json` number, §11). A player on a 60 ms link
   who swung at where the creature visibly was must land it.
4. Rolls damage with the **host's** `_rng`, the same `_rng.randf()` at :863.
5. Applies it to the record's `hp` and broadcasts the delta.

**Friendly fire does not exist and is not a damage number of zero.** A `strike_intent` whose
resolved target is another participant's creature or trainer is **refused** with code
`friendly_target`, before any roll. `smoke_net_friendly_fire_is_zero` asserts the target's HP
is untouched *and* that the refusal was issued — a silent no-op would pass a weaker test while
hiding a targeting bug.

---

## 6. Joining a fight in progress

Directive rule 8. A second player sends `engage` naming the live `encounter_id`; the host adds
them to `participants` with the current `seq` as `joined_seq` and re-derives scaling (§10). No
phase change, no reset, no re-intro camera for anyone already fighting. A participant who
joined at `joined_seq` is eligible for rewards (§7) — arriving late costs nothing, because
directive rule 15 pays each participant, and the alternative is teammates racing to tag in.

---

## 7. Rewards

**The world fact happens once. The personal reward happens per participant.**

- `_finish_trainer_battle(won)` :2307 commits **one** `set_world_flag` for the trainer's
  `defeat_flag` (D99 world scope). A second peer arriving later finds the trainer already
  beaten, because that is what the world says.
- Every participant receives a `reward_grant` addressed to their peer: XP, items, and any
  player-scoped flag the encounter grants. `world_ledger.gd::reward_flag(source, peer_id)`
  already exists for the replay guard, so a reward pays once per participant per source.

No mechanism for this exists today — Cloudreach's "receipts" are HUD banner events, not
grants — so 4.C/4.D build it. XP is **not** divided by participant count: a fight that pays
half as much for having a friend along teaches players to fight alone.

---

## 8. Catch arbitration

Catching is available in wild combat only; a trainer-owned creature cannot be caught
(`CLAUDE.md`, hard rule) — the host refuses `catch_attempt` on `kind != "wild"` with
`not_catchable`, and 4.C must not rely on the UI never offering it.

On `catch_attempt` the host:

1. Refuses if the phase is `resolving` or `done`, or if another attempt is already `catching`.
   **First committed attempt owns the outcome**; a second gets `already_resolving`.
2. Re-derives the closest approach with `orb.gd::closest_approach_ahead(launch_point,
   direction, host_target_position)` — the host's own position for the creature, never the
   thrower's.
3. Rolls `CATCH.resolve(SPECIES.catch_rate(species), record.hp_fraction, orb_id, offset,
   radius, host_rng.randf())`, the same six arguments as :1430.
4. On success: the record goes `resolving`, `_resolve_catch` runs **for the winner only**, and
   every other participant is told `caught_by(peer)` so their HUD says who got it rather than
   silently ending their fight.
5. On failure: back to `active`, and the orb is spent either way.

**`orb_id` is the orb the thrower actually spent**, carried in the intent, for the reason the
comment at :1425 already gives: the satchel has lost that orb by the time the strike resolves,
and re-querying "best available" can price a greater-orb throw at the basic multiplier. The
host validates that the peer held that orb, then debits it.

A caught creature entering a full party obeys the five-creature limit unchanged. There is no
storage, no sixth slot, and no "held for you" queue — that is a hard rule, and a race for the
last slot resolves the same way every other race does: first commit wins, loser is told why.

---

## 9. A participant leaving

`disengage`, a disconnect, and a downed trainer (4.E) are the same event to the encounter:
remove the participant, keep the encounter alive if anyone remains, and **do not reset it**.
The last participant leaving ends it — the opponent returns to its wild behaviour with the HP
it has, because a creature that heals instantly because everyone walked away is an exploit.

One player going down never resets the fight, and `smoke_net_death_does_not_reset_encounter`
is the assertion.

---

## 10. Scaling (D-MP12)

Composition first, health second. Per participant count, from `multiplayer.json`:

- extra opponents or roles where the encounter defines them, and targeting spread across
  participants (§5) rather than one player tanking by standing still;
- a **modest** stat multiplier;
- **never HP × players.** A boss with four times the health is four times as long, not four
  times as interesting.

Re-derived when `participants` changes, including a mid-fight join or leave. 4.F measures the
result at 1, 2 and 4 participants and records the numbers the way W23 did.

---

## 11. Numbers, and where they live

All in `data/config/multiplayer.json` under a new `encounter` block, none in code:
`strike_latency_tolerance_ms`, `catch_arbitration_window_ms`, `scaling` (per-count opponent
composition and stat multiplier), `reward` (XP and item policy per participant).

Tolerances are fixed in each lane's brief **before** implementation, so no lane discovers its
own bar by running until something passes.

---

## 12. What proves it

| Claim | Test |
|---|---|
| Two players fight one wild together | `smoke_net_shared_wild_fight` |
| A peer cannot damage a teammate, and is told so | `smoke_net_friendly_fire_is_zero` (HP untouched **and** refusal issued) |
| Two simultaneous catches → exactly one owner | `test_catch_arbitration` (deterministic, pure), `smoke_net_catch_race` |
| A strike is tested against the host's target position | `test_encounter_host_rejects_friendly_strike`, plus a unit case feeding a lying `origin` |
| Both players get their reward from one trainer | `smoke_net_boss_rewards_each_participant` |
| A death does not reset the fight | `smoke_net_death_does_not_reset_encounter` |
| **Solo combat is unchanged** | `smoke_combat`, `smoke_combat_camera`, `smoke_arena_contain`, `smoke_catching`, `smoke_catch_retry`, `smoke_party_count_after_catches`, and `smoke_combat_baseline` within a stated tolerance of its pre-wave numbers |

That last row is the one that matters most. Every other row can pass in a game that has stopped
being fun to play alone.
