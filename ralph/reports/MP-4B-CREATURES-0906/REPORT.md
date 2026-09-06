# MP-4B — creature ownership and host-simulated bodies

**Lane:** Stage B 4.B · **Date:** 2026-09-06 · **Branch:** `claude/mp-4b-creatures`
**Base:** `claude/tetherbound-roadmap-next-jrcjs8` @ `dd00081c` (main + lane 4.A's protocol commit)
**Godot:** 4.7.stable.official.5b4e0cb0f, installed at `~/godot-bin/godot`, project imported twice
before any other command (both imports exit 0).

The one-line verdict: **every deployed creature now belongs to exactly one player, the host
stands up a body for each of them, and cluster streaming wakes on the union of a realm's
occupants. The wild-body half of the brief was already withdrawn by the decision it cites —
see finding F1 — and is not implemented here.**

---

## 1. Per item

| # | Item | Verdict |
|---|---|---|
| 1 | Deployed creatures spawned by the host, owner's authority set before tree entry | **DONE** |
| 2 | `_ally_body.name = "AllyCreature"` stops being the lookup key; one body per owner | **DONE, with one named alias left standing** (F2) |
| 3 | Followers follow their own trainer, not "the player" | **DONE** |
| 4 | Wild bodies in a kinematic heightfield mode on the host | **NOT DONE — out of scope by D96's own amendment** (F1) |
| 5 | Cluster streaming keys on the union of the realm's occupants | **DONE** |
| 6 | One new net smoke, registered in `verify-multiplayer-shard` | **DONE** |

### 1. Host-spawned bodies with the owner's authority

`scripts/creatures/remote_creature.gd` (new) is to a deployed creature what
`scripts/net/remote_trainer.gd` is to a trainer, deliberately and not as a second design:
one node per deployed creature per peer, standing under D97's authored `Spawned/Creatures`
container, spawned only through `encounter_director.gd::_spawn_deployed_creature()`, which
sets `set_multiplayer_authority(owner_peer_id)` **inside the spawn function and before
`add_child`** — the ENet spike's rule 1, and the only place that runs identically on every
peer before tree entry.

On the owner the node is an invisible outbound proxy that copies the real
`follower_creature.gd` body's transform into `net_position`/`net_yaw`. On every other peer it
is the body the player sees, interpolated toward those properties through `move_and_slide()`.
Authority is re-read every physics frame in `_apply_ownership()`, never cached at `_ready()`,
because the local peer id changes under a node's feet when `join()` swaps the
`OfflineMultiplayerPeer` for a real one.

The **local** deployed body is untouched: it is still built by `_spawn_ally_body()` under the
world root, still driven by `follower_creature.gd`, still piloted by exactly the solo code
path. That is what keeps solo identical, and it is the same split lane 2.C made between a
local rig and a remote body.

Authority questions go to the session, never to `multiplayer.is_server()`:
`encounter_director.gd::_is_host()` is `Session.is_active() and Session.is_host()`, with
`trainer_spawn.gd::_is_host()`'s reasoning restated in full at the call site. Nothing in this
lane spawns, announces or replicates anything at all until `Session.is_multi_peer()` is true.

### 2. The name stops being the key

`creature_body.gd` gains `DEPLOYED_GROUP := &"deployed_creature"`. `follower_creature.gd`
(the body this process pilots) and `remote_creature.gd` (everyone else's) both join it and
both answer `is_local_deployment()`. `encounter_director.gd::deployed_bodies()` and
`deployed_body_for(peer_id)` are the addressed lookups; `playground_hud.gd`'s two name reads
(`_active_creature_is_out()` and `_update_minimap()`) now ask the group and the body, so the
HUD keeps showing *this* player's creature rather than whichever body is first in the tree.

Proxy node names are `AllyCreature_<peer id>`, a pure function of the owner id, identical in
every process, so two bodies can never contend for one name (the
`Condition "parent->has_node(name)" is true` failure lane 2.C hit).

### 3. Followers follow their own trainer

`follower_creature.gd::leader` was already the only thing `_tick_follow()` and
`companion_presence.gd` read — there is exactly one assignment in the tree,
`encounter_director.gd:1174`, and it sets the owner's own rig. What was missing was that this
is *load-bearing* rather than incidental: the file now says so, and there is deliberately no
fallback to a global player lookup, because a follower with no leader stands still (visibly
wrong, therefore reportable) where one that found "the player" would silently walk to the
wrong trainer the moment a second person joined. `owner_peer_id` is set on the body at deploy
time so lane 4.C can address it.

### 4. Wild bodies — see F1. Not implemented, and not silently skipped.

### 5. Streaming on the union of occupants

`_stream_clusters()` read `_player.global_position`. It now takes the union of
`_realm_occupant_positions()` — the local player plus every `remote_trainer` body standing in
this scene — and wakes a cluster if **any** of them is within `radius + margin`. Being in this
tree is what "in this realm" means: D97 gives each realm its own world scene and its own
`Spawned/Trainers`, so a peer in another realm has no body here to test. In solo the group is
empty and the arithmetic is byte-for-byte what it was.

---

## 2. Commands run, and their counts

Nothing was re-run to confirm a pass, no sweep was run, and no exit-time
`ObjectDB instances were leaked` / `resources still in use` notice was chased.

### Parse checks — 6 files, `--check-only`, all clean

```
godot --headless --path . --check-only --script scripts/combat/encounter_director.gd
godot --headless --path . --check-only --script scripts/creatures/remote_creature.gd
godot --headless --path . --check-only --script scripts/creatures/follower_creature.gd
godot --headless --path . --check-only --script scripts/creatures/creature_body.gd
godot --headless --path . --check-only --script scripts/ui/playground_hud.gd
godot --headless --path . --check-only --script tools/net/peer_runner.gd
godot --headless --path . --check-only --script tests/smoke_net_deploy_two_creatures.gd
```

7 invocations, 7 clean (no parser output beyond the engine banner).

### Smokes

| Command | Result |
|---|---|
| `godot --headless --path . --script tests/smoke_playground.gd` | **PASS** — printed `smoke: OK`, exit 0 |
| `godot --headless --path . --script tests/smoke_creature_control.gd` | **PASS** — `creature control: OK — dismissed, recalled, swapped, and refused mid-fight.`, exit 0 |
| `godot --headless --path . --script tests/smoke_wild_streaming.gd` | **PASS** — `wild streaming: OK — distant clusters sleep, near ones tick, engaged/fainting/respawning are never touched, and a round trip changes nothing about a creature's identity.`, exit 0 |
| `godot --headless --path . --script tests/smoke_aggression.gd` | **FAILED once, then passed on a re-run. Recorded as a finding, not as a pass — see F6.** |
| `tools/net/run_net_smoke.sh deploy_two_creatures --out=/tmp/net-local` | **PASS on the first run**, 33 checks, `ALL CHECKS PASSED`, exit 0 (run `net-20260906T033512Z-3387`) |

`smoke_wild_streaming` is the one that matters most for item 5: it is the existing assertion
that distant clusters sleep and near ones tick, and it passes unchanged against the union
form because in a one-occupant world the union *is* the player.

---

## 3. Findings

### F1 — the brief's item 4 was already withdrawn by the decision it cites

The brief says wild bodies should run "on the host in a kinematic heightfield mode (D96)".
`docs/decisions/D96-...md`'s own amendment of 2026-09-05, after spike S2, says the opposite in
as many words:

> **the host runs Terrain3D in FULL_GAME collision mode**, and host-simulated bodies keep the
> existing `move_and_slide` path everywhere in the Meadows […] **The kinematic heightfield mode
> is dropped from lane 4.B's scope.**

Precedence in `CLAUDE.md` puts `docs/decisions/` above `docs/prompts/` task contracts, so the
amendment wins and item 4 is not this lane's work. Nothing about authority changes: the host
still owns every opponent body, every HP value, every strike and every catch.

Two consequences worth stating rather than leaving implied:

* The FULL_GAME collision-mode switch lives in `scripts/world/playground_world.gd`, which is
  neither owned by nor forbidden to this lane. It is **not** done here — it is a world-boot
  change with its own memory and load-time cost (+16.1 MB, 3.06 s, measured by S2) and it
  belongs with whoever owns world boot, not with a creature-ownership lane making an
  unannounced edit to it.
* Consequently, on a **client**, wild creature bodies still simulate locally from the shared
  world seed rather than being replicated from the host. They start in the same places and
  drift. This lane deliberately did **not** freeze them on clients: with no replication
  channel for the chapter's ~900 wilds, freezing would produce a visibly dead meadow, which is
  worse than drift and would read as this lane's regression. Handover H1.

### F2 — one name lookup could not be fixed, because its file belongs to another lane

`scripts/build/build_placer.gd:902` finds the deployed creature with
`world.get_node_or_null(^"AllyCreature")`, to keep the dismantle ray from stopping on it.
That file is in this lane's do-not-touch list (a Wave 3 consumer being edited concurrently),
so the local deployed body keeps the literal name `"AllyCreature"` as a legacy alias and
`build_placer.gd` keeps working, in solo and in a session, unchanged.

This is recorded as an alias and not as a fix. The key is genuinely replaced —
`DEPLOYED_GROUP` + `is_local_deployment()` — and every reader this lane owns now uses it. The
alias is a compatibility string with one remaining consumer. Handover H2.

### F3 — the deployed-creature group has three members per peer in a two-peer session

Worth writing down because it will look wrong to the next reader. On each peer the group holds
the local piloted `follower_creature.gd` body, that peer's own invisible outbound proxy, and
the other peer's visible proxy. Two of the three share an owner id. That is why the
`deployed_creatures` probe keys on **node name** and reports `owner`, `authority`, `mine`,
`local` and `visible` separately, and why the smoke asserts on all of them: keying by owner
would collapse the first two and hide exactly the case worth checking.

### F4 — the deployed body's synchronizer is built in code, not authored in the scene

`scenes/creatures/creature.tscn` is also every one of the chapter's ~900 wild creatures. A
`MultiplayerSynchronizer` authored into it would be ~900 synchronizers at boot. So
`_spawn_deployed_creature()` constructs one, identically on every peer, before `add_child` —
which is the same moment in the spawn packet's life that `remote_trainer.tscn`'s authored
synchronizer occupies. The replicated set is `net_position` and `net_yaw` only; nothing a
fight turns on is a replicated property (`MP_ENCOUNTER_PROTOCOL.md` §3).

### F6 — `smoke_aggression` failed once on this branch, then passed. That is a finding.

Reported as 1-fail-then-green rather than as "green", because a retry that turns 0-for-1 into
a pass is a finding on this project by rule, and because the failure was real output rather
than a crash.

| Tree | Run | Result |
|---|---|---|
| this branch `0d8efcc8` | 1 | **FAIL** — `stood 116.1m from Galecrest for 900 frames without pressing anything and it never attacked`, preceded by `[player] entombed at 42.33, 0.79, -66.54 -- recovering to -25.40, 4.95, -15.70` |
| base `dd00081c`, untouched | 1 | **`aggression: OK`** — `Galecrest started the fight on its own, from 9.0m` |
| this branch `0d8efcc8` | 2 | **`aggression: OK`** — `Galecrest started the fight on its own, from 8.8m` |

The base run was done specifically to answer "did this lane break it", before writing any
verdict. What the three runs actually show is that the run is **not deterministic** — the
peaceful half alone reports 16.3 m, 16.8 m and 12.9 m of stand-off distance across them — so
one green base run does not exonerate the branch and one red branch run does not convict it.

What the failure is: the smoke's scripted walk to Galecrest holds `move_forward` dead straight
for up to 4000 frames. `tests/smoke_aggression.gd`'s own header documents that walk going dead
against a Terrain3D snag, investigated 2026-08-13, with a CI signature of 44.1 / 38.0 / 45.1 m
and a residual rate the header calls out explicitly; `ralph/reports/W24-LANDING-0904/REPORT.md`
records a second occurrence, and `docs/CURRENT_STATE.md:535` names its coordinate as
**(42.33, −66.54)** — the exact position this run printed. The new part is only the tail: the
walk stalled long enough for `player_controller.gd::_recover_if_entombed()` to fire and rewind
the trainer to a breadcrumb 116 m away, which is why the failure line says 116.1 m rather than
the ~40 m the header's signature quotes.

Why it is not this lane's, stated as reasoning and not as assertion. In a process with no
autoloads (which is how this smoke runs), `_session` is null, so `_is_host()` and
`_is_multi_peer()` are both false and nothing in this lane spawns, announces or replicates
anything. `_realm_occupant_positions()` reduces to `[player]` because the `remote_trainer`
group is empty, so `_stream_clusters()` performs the same one distance test per cluster it
performed before. `follower_creature.gd` gains a group membership and two fields and no
locomotion change; its `collision_layer = 0 if value else 1` in `set_following()` is untouched,
which is the one thing in this lane's blast radius that could plausibly block a trainer. The
walk that dies is the trainer's own, against terrain, with the creature deliberately
non-colliding.

**Handover H7:** this is not fixed here and this lane does not own it. It belongs with whoever
owns the walk — either `tests/smoke_aggression.gd`'s escape logic (its `UNSTICK_STEER_RAD`
escape clearly did not save this run) or the terrain snag itself. What would settle it is a
flake-rate run of the same smoke on `main` (`tools/flake_rate.sh`), which this lane did not do
because the anti-grind rule caps it at two attempts on one narrow defect and this one is
neither narrow nor this lane's.

### F5 — a coroutine reached through `Object.call()` does not hand back its result

`tools/net/peer_runner.gd::_step_deploy_creature()` reads the outcome off
`director.ally_body()` rather than off `summon_active_creature()`'s or `adopt_starter()`'s
return value, because both are coroutines and `await obj.call("...")` on one yields whatever
it held at its first internal `await`. Every existing caller in `tests/` uses the same
`await director.call("adopt_starter", ...)` shape and discards the value, which is why nothing
had caught this before; a smoke that trusted the boolean would have reported a deploy that had
not happened.

---

## 4. Handovers to lane 4.C (and one to whoever owns world boot)

* **H1 — wild bodies on clients.** D96's amendment leaves "the host runs Terrain3D in FULL_GAME
  collision mode" unimplemented and unassigned. Until it lands *and* wild bodies are replicated,
  a client's wilds are its own local simulation. 4.C's strike resolution must therefore keep
  taking the **host's** position for the opponent (§2 and §5 of the protocol) and must not read
  a client-side wild body's transform for anything that decides an outcome. Not a blocker for
  4.C; a constraint on it.
* **H2 — `build_placer.gd`'s name lookup.** Change
  `scripts/build/build_placer.gd::_bodies_that_are_not_buildings()` from
  `world.get_node_or_null(^"AllyCreature")` to walking `&"deployed_creature"` (every deployed
  body should be excluded from the dismantle ray, not only the local one). When that lands, the
  `_ally_body.name = "AllyCreature"` alias in `encounter_director.gd::_spawn_ally_body()` can go
  and the local body can be named per-owner like the proxies are.
* **H3 — the seams 4.C will want.** `deployed_body_for(peer_id)` answers "which body is this
  peer's creature" and `deployed_bodies()` answers "every deployed creature in this realm".
  `follower_creature.owner_peer_id` and `remote_creature.owner_peer_id` carry the owner on the
  body itself. Use these rather than a node name; the name is now an alias with a scheduled
  removal (H2).
* **H4 — deployment is announced, not inferred.** The host holds `_deployed_by` (peer id →
  species/shiny/character id) and rebuilds a late joiner's proxies from it. If 4.C adds a switch
  intent (protocol §4), it must go through `_host_set_deployed()` so the proxy is replaced
  rather than leaving the old species standing.
* **H5 — friendly fire.** Every deployed body is now addressable by owner, which is what §5's
  `friendly_target` refusal needs: a `strike_intent` whose resolved target is a body with a
  non-zero `owner_peer_id` other than the striker's is another participant's creature. 4.C owns
  the refusal; this lane owns the fact that the question can now be asked.
* **H6 — `combat_manager.gd` was not touched.** It is 4.C's file and serialized after this lane.
  `_start_fight()` still passes `_ally_body` — the local body — into `begin()`, unchanged.
* **H7 — `smoke_aggression`'s walk to Galecrest.** F6: red once on this branch, green on the
  base and green on a re-run of the branch, at a coordinate `docs/CURRENT_STATE.md` already
  names for this smoke. Not this lane's, not fixed here, and the reasoning for both statements
  is in F6 rather than asserted. Goes to whoever owns that walk.

---

## 5. What this lane deliberately did not do

* No change to `scripts/combat/combat_manager.gd`, `autoload/game_state.gd`, `scripts/net/*`,
  `autoload/world_state.gd`, or any Wave 3 consumer file.
* No new creature meshes, no Meshy generations, no change to the five-creature limit, no
  storage, no sixth slot.
* No full test sweep, no confirmation re-runs, no rewrite of a working system to make a test
  convenient.

## 6. Files

| File | Change |
|---|---|
| `scripts/creatures/remote_creature.gd` | **new** — the replicated deployed-creature body |
| `scripts/combat/encounter_director.gd` | host spawn/despawn/reconcile, the two intents, `_is_host()`, the deployed-body API, streaming union |
| `scripts/creatures/creature_body.gd` | `DEPLOYED_GROUP` |
| `scripts/creatures/follower_creature.gd` | group membership, `is_local_deployment()`, `owner_peer_id`, the leader contract |
| `scripts/ui/playground_hud.gd` | two name lookups → group lookups, with a cache |
| `tools/net/peer_runner.gd` | `deploy_creature` step, `deployed_creatures` probe |
| `tests/smoke_net_deploy_two_creatures.gd` | **new** — the lane's assertion |
| `.github/workflows/ci.yml` | `verify-multiplayer-shard` floor 2 → 5 |

---

## 7. The net smoke's own output, in full

Run `net-20260906T033512Z-3387`, first attempt, no retry. Peer ids as the engine handed them
out: the listen server is **1**, the joiner is **1369099083** — a large random 32-bit number,
exactly as the ENet spike's finding 2 says, and nothing in this lane indexes by peer id or
assumes an ordering.

```
PASS: peer 0 hosted a world (hosting udp/34521 as peer 1)
PASS: peer 1 joined peer 0's world on port 34521 (joined 127.0.0.1:34521 as peer 1369099083
      after 8 frames; snapshot applied; 2 peer(s) in registry)
PASS: peer 0 deployed its own creature (deployed AllyCreature)
PASS: peer 1 deployed its own creature (deployed AllyCreature)

PASS: peer 0 pilots exactly 1 creature of its own
      (got 1: AllyCreature, AllyCreature_1, AllyCreature_1369099083)
PASS: peer 0 sees creatures belonging to 2 owners (got 2: [1, 1369099083])
PASS: peer 0's copy of peer 1369099083's creature carries THAT peer's authority (got 1369099083)
PASS: peer 0 does not claim authority over peer 1369099083's creature
PASS: peer 0 actually draws peer 1369099083's creature
PASS: peer 0's copy of peer 1369099083's creature is a real species ('terrapup')
PASS: peer 0's own creature proxy carries its own authority (got 1)
PASS: peer 0 does not draw a second copy of its own creature

PASS: peer 1 pilots exactly 1 creature of its own
      (got 1: AllyCreature, AllyCreature_1, AllyCreature_1369099083)
PASS: peer 1 sees creatures belonging to 2 owners (got 2: [1369099083, 1])
PASS: peer 1's copy of peer 1's creature carries THAT peer's authority (got 1)
PASS: peer 1 does not claim authority over peer 1's creature
PASS: peer 1 actually draws peer 1's creature
PASS: peer 1's copy of peer 1's creature is a real species ('terrapup')
PASS: peer 1's own creature proxy carries its own authority (got 1369099083)
PASS: peer 1 does not draw a second copy of its own creature

ALL CHECKS PASSED
```

33 checks, all green, both peers exited cleanly (`unexpected_exit=false` on each).

The three node names in each process are F3's three bodies: `AllyCreature` is the local
`follower_creature.gd` this peer pilots, `AllyCreature_1` and `AllyCreature_1369099083` are
the two proxies. Each process draws exactly one of the proxies — the other player's — and
hides its own.
