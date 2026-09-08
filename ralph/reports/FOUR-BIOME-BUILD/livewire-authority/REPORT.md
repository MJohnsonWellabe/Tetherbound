# Livewire authority report

**Lane:** Stormwood Spark / Livewire cooldown authority

**Branch:** integrated working tree after `296f7aa1`
**Status:** implementation and focused proof complete; full hosted proof remains bounded by local cold-build startup

## Player-visible outcome

The active Spark of the Stormwood applies its authored `cooldown_multiplier: 0.75`
to the piloted creature's move cooldowns in solo combat and in host-owned Stormwood
trainer combat. Releasing the Spark or choosing another single active relic restores
the authored cooldown.

## Authority design

- The deployment combat card carries only `active_relic_id`. It never carries a
  client-selected numeric multiplier. Shared-wild strike intents now also carry the
  monotonic action id required by the host replay/cooldown ledger; no intent carries
  a trusted numeric multiplier.
- The host resolves that id through its own `realm_hearts.json`, verifies the relic's
  placed world flag through the merged progression view, and clamps the resulting
  host-owned value to `0.1..1.0` before it can reach a timer.
- Missing, unknown, unplaced, and non-cooldown relic identities resolve to `1.0`.
  A forged `cooldown_multiplier` field is ignored.
- `RealmHeartState.revision` refreshes the card once after a shrine selection change
  while the same creature remains deployed. The update preserves the existing proxy,
  so choosing Livewire does not despawn or flash the companion.
- Stormwood's existing monotonic action-id replay guard and host-clock cooldown guard
  are unchanged. Livewire changes only the host-rebuilt move profile supplied to that
  existing guard.

No change to `scripts/net/session.gd` was required.

## Evidence

Focused runtime suites are green:

- Livewire, riding, route-strip, and Stormwood catalogue: 33 tests, 5,690 assertions,
  0 failures.
- Scale-sensitive gameplay: 3 tests, 11 assertions, 0 failures.
- Combat, AI, riding, throw aim, and hosted-combat units: 72 tests, 141 assertions,
  0 failures.

The full-world Warden Arena smoke passed with 22 assertions. It proved that the
selected axis holds the full 7.60 m formation and both enlarged body footprints, and
that all three bodies remain contained and on the floor both at fight-open and after
120 frames. The retained log is
`C:\Projects\Tetherbound\.artifacts\livewire-smoke-arena-contain.log`.

The hosted readiness contract now distinguishes three semantic checks: the settled
client actor is within Tamsin's 12 m production challenge radius, the host replica is
within 1.5 m of that settled position, and the host actor is independently within
12 m of its trainer. This replaces the former single 5 m check that conflated
replication tolerance with challenge distance. Position and distance evidence is
included in every failure.

The full local two-peer hosted smoke is **not a pass**. It reached its own 300-second
cold-build step deadline before the host Stormwood shell and client combat runtime
became ready, so none of the new semantic actor checks ran. The coordinator log is
`C:\Projects\Tetherbound\.artifacts\livewire-smoke-net-stormwood-hosted-trainers.log`;
the run directory is
`C:\Users\mattj\AppData\Roaming\Godot\app_userdata\Tetherbound\net-runs\net-run-local-1528182`.
All spawned Godot processes were subsequently confirmed exited.

## Final authority correction

The shared-wild path now enforces the profile it already rebuilt. Every ordinary
strike receives a locally monotonic action id, while `EncounterHost` owns a separate
accepted-action/deadline ledger for each encounter participant. Replayed ids are
refused even after the deadline; fresh ids are refused before the deadline; neither
refusal consumes the id or changes the deadline. The lock is derived from the host's
resolved profile as the greater of cooldown and windup plus recovery. It resets when
a participant leaves/rejoins, the opponent changes, the phase changes, the encounter
closes, or its record is forgotten. Client-supplied damage and cooldown fields remain
unused.

The legacy encounter-host suite plus Livewire units passed after action ids became
mandatory: **21 tests, 82 assertions, 0 failures**. This includes focused proof of
per-peer isolation, replay refusal after elapsed time, rapid fresh-id refusal, exact
host deadline acceptance, malformed unstamped intent refusal, and lifecycle reset.
The retained focused log is
`C:\Projects\Tetherbound\.artifacts\livewire-authority-focused.log`.

The shared-wild two-peer smoke now also submits forged zero-cooldown/high-damage
fields, replays the accepted id, and submits a fresh id before the host deadline. It
requires the host authority probe to retain the authored move lock and leave the last
accepted action/deadline unchanged across both refusals.

Livewire timing no longer starts a local 900 ms wait after coordinator polling. The
host probe exposes its current clock, last accepted action, current deadline, deployed
card relic id, and host-resolved multiplier. The smoke waits for a safe pre-deadline
host window when proving refusal and for a positive post-deadline margin when proving
acceptance. It separately requires inactive/released state to resolve to `1.0` and
the active Spark identity to resolve to `0.75`.

No new full-world or two-peer runtime was attempted for this correction. Both changed
network smokes and their production/harness dependencies passed Godot 4.7 static
`--check-only`; the earlier 300-second cold-build result remains the honest full
hosted boundary.

## CI prepared-position serialization correction

CI run `34177060785`, multiplayer shard-4 job `101909010326`, artifact
`10037848400` reached the real Stormwood runtime and returned a PASS from the
`prepare_only` step, but the coordinator received neither settled position. Its sole
failure was therefore the intended semantic assertion reporting actor and trainer as
`(inf, inf, inf)`. The artifact is retained locally at
`C:\Projects\Tetherbound\.artifacts\ci-10037848400-extracted`.

The exact cause was the peer control protocol, not Stormwood placement or vector JSON
encoding. `_step_stormwood_hosted_start()` returned `client_actor_pos`,
`client_trainer_pos`, and `client_body_pos` as siblings of `verdict` and `detail`,
while `_handle_message()` deliberately transmits structured step results only through
the `data` dictionary. Those sibling keys were silently omitted before
`net_harness.gd::step()` returned to the smoke. The peer now places all three arrays
inside `data`, and both hosted and Livewire consumers read the established `data`
payload. The 12 m client challenge, 1.5 m replication, and independent 12 m host
challenge assertions are unchanged.

No timeout was raised and no full local cold-world rerun was needed: the artifact
fully isolates a deterministic response-envelope defect after the production step
had already passed. The hosted smoke, Livewire smoke, and peer runner pass Godot 4.7
static `--check-only` after the repair.

Focused post-repair units (`test_net_state_hash_scope.gd` plus
`test_livewire_cooldowns.gd`) passed **9 tests, 46 assertions, 0 failures**. Their log
is `C:\Projects\Tetherbound\.artifacts\livewire-serialization-focused.log`.

`tests/smoke_net_stormwood_livewire.gd` uses the same prepared-position readiness
contract before starting the remote hosted fight. Once a two-peer environment clears
world startup, it places the Spark through the real shrine/ledger path and compares
the same Arc Lash action under three personal selections: inactive and released use
the authored `1.0` multiplier, while active Livewire uses `0.75`. Every refusal and
acceptance is now measured against the host-reported deadline with delivery margins;
fresh action ids distinguish cooldown refusal from the separate replay guard.
