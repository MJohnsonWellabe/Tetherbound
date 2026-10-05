# F27 lane handoff (`tb/f27`)

The lane was wound down on 2026-10-05 by owner direction. Its remaining work moves to Codex, one task at a time.

- **Branch:** `tb/f27`. The head is the commit that adds this file. This file is the only change after `f00fea41`.
- **Base:** origin/main `e2fa5e4e` (#542) is merged in. `combat.json actor_vitals.runtime_enabled` is **false** on this branch, as it is on main.

## Already landed (in #536 or #542)

- F27 essence and chosen leveling, plus guest wild wins (flag-off ship). F27 is DONE except criteria #1 and #2 on the shipped path, which need the flip.
- F30#1: the catch readout and Team inspect name the active F30 traits (`5dbf0662`).
- Three flag-on combat fixes, each with a failing-first test:
  - `4bcd1edb`: the host trainer round re-seat lost its bound creature;
  - `ed83bd92`: the first attack of every trainer/boss fight was `move_start_required`;
  - `26959092`: guests were re-seated without their character.
- Groom leave-save data loss (`975ce1f0` and `a6de29e6`). Independent review: PASS WITH ISSUES, all suggestions applied.

## On the branch, not landed yet (ready with the flip)

| SHA | What | Checks |
|---|---|---|
| `658ff0dd` | The move-commit, f23, process-exit and mastery fixtures bind actors through a test-local tracking override (before_each/after_each switch the cached `combat_math.config()`). | 34/0 with the shipped flag off and 34/0 with it on. |
| `98a9ba08` | Net smokes deploy with `owned:true`. This is real ownership: `party_seam.add` → `Game.party.add`, the same add the opening uses. | split_realms flag-on PASS (failed without it). |
| `f00fea41` | `smoke_net_deploy_two_creatures` keeps main's unowned deploys. `owned:true` broke it flag-off. | PASS flag-off. |
| `40b228cf`, `e2985e27` | `accepted_action_host.exclude_from_actor_tracking(id)`. It is host-only state and is cleared on forget. The Stormwood hosted trainer excludes its own record. Unit test: a tracked record refuses an unbound strike, a record cannot carry the exclusion in, and an excluded record accepts the strike. | smoke_net_stormwood_hosted_trainers flag-on: FAIL before, ALL CHECKS PASSED after. **Open item:** Stormwood hosted trainers don't use durable actor vitals yet. |
| `81b9ee10` | F30#0 WIP parked. Its two commits are reverted; the patches are kept in `ralph/reports/TRAINING/f30/wip/`. | n/a |

## Not done (each with its next step)

### 1. Guest-opened wild fights blocked with the flag on

This is a **product bug: found, not yet fixed.**

- `encounter_director._canonical_wild_start_state` (~line 8413) calls `session._host_wild_training_context()`, which is host-only.
- On a guest it returns `{enabled: true, ready: false}`, so `_start_fight` silently returns. A guest can never start its own wild fight. This is what makes `smoke_net_riding` (guest engage) and `smoke_net_realm_owner_disconnect_mid_fight` fail flag-on. Both pass flag-off.
- **Fix:** at the top of `_canonical_wild_start_state`, add `if _is_guest(): return disabled`. Guest-opened fights stay on the legacy local path, as already declared.
- **Proof:**
  - a two-peer regression where the guest engages a wild flag-on;
  - riding and realm_owner_disconnect flag-on and flag-off.

### 2. Remaining flag-on sweep failures

The flag-on sweep at `e2985e27` (with F30 WIP still in) ran the 21 net smokes that fight:

- **14 PASS:** client_trainer_rewards, cloudreach_riding, f22_forced_break, fly, gate_opens_for_both, hearts, host_exit_saves, shared_boss, shared_wild_fight, split_realms, stormwood_finalized_death, stormwood_hosted_trainers, stormwood_livewire, veridian_relic_key.
- **FAIL:**
  - riding, realm_owner_disconnect_mid_fight: see item 1.
  - veridian_choices: "both peers felled the Warden (no verdict)". It passes flag-off. Not investigated: check `win_trainer_battle` under the flag, especially pending_vitals between rounds (item 3).
  - catch_race: the guest grant identity mismatch was most likely the F30 WIP, which is now parked. Re-run flag-on.
  - f27_guest_wild_win: the host's last row was `combat_mastery`, not the guest's `wild_defeat_share`. The assertion probably needs to find the share row by action instead of taking "the latest row". Check this before calling it product.
  - deploy_two_creatures: now restored to unowned deploys. Re-run flag-on.
  - boss_rewards_each_participant: "peer 0 beat Bryn's whole team (no verdict)". It **also fails flag-off with main's exact file**, so it is main debt, not the flip.
- **Flag-off check of the owned:true smokes** (interrupted by this wind-down):
  - PASS: client_trainer_rewards, cloudreach_riding, f22_forced_break, fly, gate_opens_for_both, hearts.
  - PASS earlier in a separate run: catch_race, realm_owner_disconnect_mid_fight, riding, veridian_choices.
  - **Not yet run flag-off:** host_exit_saves, shared_boss, shared_wild_fight, split_realms, stormwood_finalized_death, stormwood_hosted_trainers, stormwood_livewire, veridian_relic_key.

### 3. Pending vitals must not outlive a round (from F01#6b)

- In tournament runs, actor_vitals stayed pending into the semi-final, so both peers' move_start and strike_intent were refused with `pending_vitals`.
- **Next:** find where a tournament round ends (`_resume_trainer_encounter` / the tournament bracket) and settle or release that round's pending actor vitals before the next round opens.
- **Proof:** the tournament bracket net smoke flag-on.

### 4. The flip itself

The coordinator's conditions:

- all two-peer combat smokes pass with the flag on;
- every fixture passes with the flag on and with it off.

Then send the flip as ONE commit: `combat.json actor_vitals.runtime_enabled` true, and `tests/smoke_net_f27_guest_wild_win.gd`'s header set to exactly `# peers: 2`.

The 55 CI SMOKE jobs passed flag-on before; see `proof/flip/README.md`. Re-check them after items 1–3.

### 5. F30#0: ordinary wild traits

Patches: `ralph/reports/TRAINING/f30/wip/`.

**Design (coordinator-approved):**
- The host rolls `Traits.roll_spawn` at registration from (namespace, realm+body name+epoch, generation), with the alpha/night/weather profiles. Guests never roll.
- Canonical catches journal a `capture_offer` through a new `session.foundation_wild_capture_offer`.
- `foundation_capture` no longer requires `alpha_respawns`.

**Bugs found in that path** (they also affect alpha catches when F44 enables them):
- the capture roster guard compared raw cards against the energy-free owner projection (since `187a3f24`);
- the staged newcomer card kept `energy`;
- a catch with a free slot opened the release-ceremony screen and left GameMenu owning input.

**Next:**
- Merge F18 `9032d90e` (codec energy restore) and tb/f01-fixes (portable-card helper, the `starter_choice` branch in `_capture_roster_allowed`, and the `merge_owner_passive` float fix).
- Re-apply the patches onto ONE shared energy/portable-card helper. Don't add a third inline copy.

**Proof:**
- the roll distribution, and that night/weather/alpha roll better;
- catch → `redesign_character.creatures[uid]` holds {traits_initialized, rolled_traits, taught_traits, captured_from};
- a two-peer guest catch with a reconnect mid-offer;
- the catch smokes flag-on.

Note that F30#0 only takes effect with the flag on, so it lands after the flip.

### 6. F30#2–#4

Not started beyond the audit:
- #2 (Altar distil) needs `captured_from`, which only F30#0 gives ordinary catches;
- #3 and #4 have unit coverage (`test_f30_traits`). The bond secondary already matches TRAINING §6's mapping.

### 7. Owner-passive rejoin replay gap (task from 2026-10-05)

On rejoin admission, replay the guest's escrowed reward deliveries exactly once by receipt key before the inventory comparison. Ruling: the world's record wins, and the guest file counts only where the world holds no record.

- **First:** merge tb/f18 `ea685537`. It changes `owner_passive_sync._reset_matches`.
- **Proof:** a two-peer test where the guest drops before the host applies a delivery, or rejoins with a stale/rolled-back file. There must be no overwrite and no double pay.

## Known traps

- **Running smokes:**
  - Never run net smokes in parallel on this 4-core box. The peers miss the 180 s hello and the runs are invalid.
  - Don't run veridian_offer_choice groups concurrently: they share save slot 3.
  - Local veridian needs CI's 46-minute budget, or run it group by group with `TB_VERIDIAN_CASE_GROUP`.
- **Tree hygiene:**
  - Flip the flag only in the working tree, and restore it with `git checkout data/config/combat.json`.
  - Never `pkill -f` a pattern that matches your own shell command line.
- **Fixtures:** many fixtures were written for flag-off. With the flag on, production needs:
  - an OWNED fighter;
  - `current_scene` set;
  - host-side HP/catch decisions (use `encounter_host.set_opponent_hp` and the actor rows);
  - a live world named after the save slot when rows are journaled.
- **Session signatures:** when you change a `session.gd` signature, grep `tests/` for subclass overrides. `test_training_guard_lifetime` broke on `_owner_training_mutation_blocked`.
- **Disk:** the per-session disk allowance is small. Don't copy `.godot` into a worktree.
- **Pre-existing main failures, not the flip:**
  - smoke_catch_retry and smoke_controller_catching fail flag-off on their original versions; neither is in CI;
  - boss_rewards_each_participant fails flag-off on main's file.
