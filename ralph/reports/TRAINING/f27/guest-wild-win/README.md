# F27 guest wild wins: where it stands (`tb/f27`)

Not landed. Guest wild wins stay unpaid by the canonical path. `wip.patch` holds the attempted implementation for the next lane. It applies to `tb/f27` and is not in the branch's source.

## What the patch does

1. **Host side.** `session._journal_guest_wild_defeats` is called from `_commit_host_wild_victory`.
   - It retains one `wild_defeat` FoundationEvent duty per guest participant.
   - Each duty is staged once from the same frozen capture, through `essence.stage_captured_host_victory`.
   - Duties are committed by the retry scan through the owner-passive gate. `owner_passive_sync` already lists `wild_defeat` (commit 66475937).
2. **Action.** A new `wild_defeat` character action restages the frozen event with `essence.stage_core_defeat`. `foundation_event` validates the duty, and `owner_passive_preparation` admits it.
3. **Guest XP.** The host stamps `host_owns_xp` on the guest's verdict and record copies. The guest's director then answers `canonical_wild_encounter`, so its combat manager skips the legacy local award.
4. **Joining.** `_host_engage` no longer refuses guests from canonical fights. The `canonical_training_solo_scope` refusal is removed.

## Evidence

- `test_f27_guest_wild_share.gd.txt`: 3 tests, 17 assertions, all passing. They cover the duty codec, the action, and receipt agreement.
- `smoke_net_f27_guest_wild_win.gd.txt` with `net-run-projection-conflict.txt`:
  - the guest joins the host's canonical wild fight;
  - its real strikes kill the opponent;
  - the stamp suppresses the guest's legacy award (the guest equals the host).
- **Blocker.** The guest's first retained duty for that fight (its `research_event`) holds with `owner_passive_exact_projection_conflict`. The `wild_defeat` share is queued behind it. The diagnostic diff of the owner projection against the host cursor shows three drifts:
  - `party[0].hp`: owner 166.3, host 177.6. The guest's combat damage never reaches the host's admitted record in a canonical wild fight.
  - `party[0].battles_fought`: owner 1, host 0. This is the guest's local `_award_victory` credit.
  - `party[0].happiness`: owner +5. This is the guest's local victory mood.

## What a finished version needs

1. **Settle the guest's HP.** Trainer rounds do this with `combat_round_reward.settled_before`. A wild share needs the same thing:
   - freeze the guest participant's actor vitals in the duty context;
   - settle them in `owner_passive_sync._prepare_host` and `owner_passive_preparation.valid`/`valid_host`, as `combat_round_reward` does.

   This is more than an additive list change to `owner_passive_sync.gd`.
2. **No local member mutation on a guest.** When the host owns the award, the guest must not mutate members locally. This branch's `combat_manager` fix (the battle double-credit commit) already skips the whole member loop when `host_owns_xp`.
3. **Use a guest test that also covers solo.** The patch's guest branch in `canonical_wild_encounter` tests `not _is_host()`. That is also true in solo play, because the session is inactive, so it broke the solo path. A finished version must test "active session and not host".
4. **Guest-opened fights.** Wild fights a guest opens never receive `canonical_wild_context` and stay on the legacy award. That is out of this scope.

## Consequence for the `actor_vitals.runtime_enabled` flip

Not flipped. With the flag on, `encounter_director._host_engage` refuses every guest join to a host's canonical wild fight (`canonical_training_solo_scope`). Shipping it would break co-op wild fights. The guest path above has to land first.

## Root cause of the HP drift (follow-up investigation)

In a canonical wild fight the host resolves each enemy hit on a guest's creature (`encounter_director.host_resolve_enemy_hit`). It then only *delivers* it (`host_deliver_enemy_hit`, non-trainer branch). The guest applies the damage locally, and the host's admitted record never changes.

Trainer and boss fights do it differently. They route the same hits through the durable actor-vitals pipeline:
- `_stage_ordinary_enemy_hit`;
- `encounter_host.stage_actor_vitals`;
- `session.ordinary_actor_vitals_commit`.

That pipeline is what feeds `combat_round_reward.settled_before`.

The pipeline is trainer-scoped:
- `foundation_ordinary_combat_scopes` requires a `trainer_id` equal to `opponent.owner_npc`;
- `uses_durable_trainer_rewards` also enables trainer round rewards, which would double the wild XP.

A settled_before-style settlement for wild shares therefore needs the host to hold authoritative guest actor vitals in wild fights first. The plan is a wild-scoped actor-vitals pipeline:
1. a scope keyed by the encounter, not a trainer;
2. no round rewards;
3. guest hits staged and committed like trainer hits.

The `wild_defeat` share then freezes the settled vitals and settles them in `owner_passive_sync._prepare_host` and `owner_passive_preparation.valid`/`valid_host`. That is a design-level change across `encounter_director`, `session` and `encounter_host`, not a list change.

`wip.patch` now includes the `_is_guest()` fix, so solo stays host-side.
