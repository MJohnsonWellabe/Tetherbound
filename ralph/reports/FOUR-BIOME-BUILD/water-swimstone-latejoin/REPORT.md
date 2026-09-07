# Water late-join Swim Stone

## Base and ownership

- Branch: `codex/water-swimstone-latejoin`
- Base: `89b1861bca84af371f707e9dcbd43c0d13971686`
- Earlier integrated roster commit `e39d4034e` is an ancestor of the base.
- Worktree: `C:\Projects\Tetherbound-water-swimstone-latejoin`
- Scope is the Aquaryn reward/authority path, Iona's guarded interaction,
  focused fixtures/tests, and this report.
- No session, shared save, shared ledger, Stormwood, Water route/entry/finale,
  encounter placement, creature presentation, `.import`, or `.gdignore` file
  was changed. ROAD-VISUAL's Water encounter files were not touched.

## Outcome

Aquaryn remains one shared, non-repeatable encounter. Once its durable resolved
flag exists, a newly arrived stable character can speak to the production Iona
body at Tidal Cradle and request attunement. The request carries only the typed
`attune` kind. Existing Water Alpha transport reconstructs peer, stable
character id, realm, and trainer position on the host.

The host validates the shared victory, Water realm, stable identity, and
distance to the actual Iona body. It then journals one hashed per-character
Alpha entitlement and creates one addressed `water_swim_stone_earned` player
operation. Nothing is published if the journal write fails. A character that
already owns the entitlement can receive the same idempotent boolean flag again
for reconnect/lost-packet recovery, but cannot create another entitlement,
world save, inventory item, capture claim, or Alpha fight.

Iona's normal greeting selects the attunement conversation only while the
shared Alpha is resolved and the local character lacks the personal Stone.
Dialogue emits a guarded authority request and cannot grant the Stone itself.
After delivery, the attunement guard closes and Iona's existing saddle-recipe
conversation becomes reachable.

## Evidence authored

- `tests/test_water_alpha_rewards.gd` covers a fresh late character, one hashed
  entitlement plus one addressed player operation, idempotent redelivery,
  original-winner duplication refusal, wrong peer/realm/distance, non-finite
  position, unresolved Alpha, client-side execution, and save-failure rollback.
- `tests/smoke_water_scene_npcs.gd` proves normal Iona selection, the
  speech-only boundary, post-reward recipe selection, and the closed explicit
  attunement guard.
- `tests/smoke_net_water_swim_stone_late_join.gd` is a discoverable `peers: 2`
  production fixture. The host supplies an explicit named-world fixture in its
  isolated test home, then resolves the shared Alpha before the fresh client
  joins. It checks a remote request is refused away from host-observed Iona,
  normal dialogue grants beside Iona, both peers observe exactly one stable
  entitlement, capture claims stay empty, a direct duplicate reaches only
  idempotent recovery, attunement dialogue cannot replay, and the resolved
  encounter cannot be engaged.
- `tests/fixtures/water_alpha_peer.gd` exposes only production transport,
  dialogue, movement, and read-only probes for that two-process proof.

## Validation

Static validation completed:

```text
ConvertFrom-Json:
  data/config/water_alpha.json
  data/config/water_authority.json
  data/config/water_characters.json
  data/config/water_objectives.json
  data/dialogue/water.json
PASS

peers:2 smoke discovery count: 35
git diff --check: PASS
```

Runtime acceptance results:

```text
godot --headless --path . --script tests/run_tests.gd -- --only=test_water_alpha_rewards.gd
PASS — 6 tests, 102 assertions, 0 failed

godot --headless --path . --script tests/smoke_water_scene_npcs.gd
PASS — 60 checks, 0 failures

godot --headless --path . --script tests/smoke_net_water_swim_stone_late_join.gd
PASS — ALL CHECKS PASSED; failures=0

godot --headless --path . --script tests/smoke_net_water_alpha.gd -- --water-only
PASS — ALL CHECKS PASSED
```

The coordinator and every peer log from all four passing commands contain no
`SCRIPT ERROR` or `ERROR:` lines. The final late-join run is
`net-run-local-1517565`; the Water-only Alpha regression is
`net-run-local-1548475`.

The first focused unit launch stopped before assertions with two new test-only
type-inference parse errors at `tests/test_water_alpha_rewards.gd:107` and
`:167`; both declarations were explicitly typed. That fresh-worktree run also
lacked the generated global-class cache and therefore reported unrelated
`UITokens` lookups in `game_menu.gd`. A single explicit import completed with
exit code 0 and no errors. All generated tracked `.import` changes and 121
untracked `.uid` files were removed afterward.

The first late-join launch then found four further test-fixture inference
errors; those dynamic nodes are now explicitly typed. The first executable
late-join run correctly refused with `not_host_or_ready`: the network harness's
fresh in-memory world had no `world_id`, and production reward code must not
journal into an unnamed save. The fixture now names only its isolated test
world before setting the resolved flag. The resulting final run received
`not_near_iona` away from Iona, then passed the full path beside her.

The default existing Alpha command (without `--water-only`) was also attempted.
It booted and connected after the fixture type fix, but its unchanged
Meadows-to-Water transition exceeded that smoke's 15-second heartbeat detector
and emitted its pre-existing scene replication errors. The supported direct
Water mode above avoids that unrelated transition and proves the existing
Alpha transport/combat regression cleanly; this lane did not edit the baseline
smoke or weaken its checks.

## Boundary

This lane proves the personal Swim Stone recovery seam after shared Aquaryn
resolution. It does not claim Water chapter, route, finale, performance, or
four-biome acceptance.
