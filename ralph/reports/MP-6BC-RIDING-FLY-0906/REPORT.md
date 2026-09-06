# Lane 6.B + 6.C — riding and Fly replication

**Directive item 17: one player rides or flies while the others carry on playing.**

Base: `claude/tetherbound-roadmap-next-jrcjs8` at **`6c5189fb`** (main plus every Stage B
lane). Not rebased mid-run. Branch: `claude/mp-6bc-riding-fly`.
Godot **4.7-stable** installed at `~/godot-bin/godot`; `--headless --path . --import` run
twice, zero errors on the second pass.

---

## 1. What the lane delivers

### Half one — a rider is on their mount, and a flier is in the air, on everybody's screen

Both halves are replicated off the **owner's trainer proxy**
(`scripts/net/remote_trainer.gd`), which is the one node that already exists once per peer,
on every peer, with a path the host can address. Six new replicated properties, authored
into `scenes/player/remote_trainer.tscn`'s `SceneReplicationConfig` with `spawn = true` so a
peer that joins mid-ride sees a rider rather than the transition it missed:

| property | what it is for |
|---|---|
| `net_riding` | this trainer is on their own creature — the mount is resolved locally by owner id, never sent |
| `net_mount_offset` | the seat, so a viewer draws the rider where the owner is actually sitting |
| `net_creature_saddled` | the saddle the owner **built** is worn on every peer's copy of the animal |
| `net_flying` | this trainer is gliding, not falling |
| `net_fly_state` | the controller's own word: `glide` / `climb` / `descent` / `exhausted` |
| `net_fly_species` | which carrier, so every viewer builds the same bird from the same capability block |

The five things that were actually broken, and are not now:

1. **The rider drifted off the animal.** Rider and mount were two independently
   interpolated bodies, so the gap between them moved whenever the mount did.
   `_follow()` now reads the rider's transform *off the mount* — the same
   `carrier.to_global(offset)` the owner's own `player_controller._ride()` uses. Measured
   in `smoke_net_riding`: **0.00 m** from the authored seat, in motion and at rest.
2. **The rider stood bolt upright on the creature's back.** `trainer_model.set_riding()` is
   called on a remote body from the replicated flag. This is OP-0904-3, the owner's own
   riding bug, which had been reopened on everybody else's screen.
3. **The saddle never crossed the wire.** "Fitted" is a flag in the *owner's* progression
   store, unreadable anywhere else, so a friend's Meadowhart was always bare. The owner
   publishes the answer; viewers apply it through `riding_controller.set_worn_saddle()` —
   the same attach the local mount uses, gated by the same `saddle_belongs_on()` so the
   legendary still wears nothing. It stays on after dismount, per OP-0904-3.
4. **A flier replicated as a trainer falling.** `_state_of()` reads "off the floor, not
   moving up" as `fall`, and the viewer drove its copy toward that position with
   `move_and_slide()` — a ground capsule pushed through whatever it clipped on the way.
   Flight now shares the `carried` branch: position-assigned, no floor fight.
5. **The friend had no bird.** The carrier art lived only on the local rig.
   `fly_controller.gd` grew three statics — `make_carrier_art()`, `pose_carrier_wings()`,
   `align_carrier_grip()` — and `_build_visual()` now calls the first of them. One builder,
   two callers, so a friend's carrier cannot be a different size or rhythm from the one its
   owner is hanging off.

One ordering fix, measured rather than reasoned: the remote trainer runs at
`process_physics_priority = 1` so it ticks *after* the creature bodies. Before it, the
rider read where the animal was last frame and sat 0.23–0.33 m out of the saddle while
moving and 0.00 m the instant it stopped — the signature of tree order, not interpolation.

### Half two — the other players never stop

This is the half the brief says gets missed, and it is asserted in both smokes with
`race()`, which puts both peers' steps in flight in the same coordinator frame:

* `smoke_net_riding`: peer 0 rides for five rounds while **peer 1 builds a floor that lands
  in the world, drops a stack, picks it back up, drives its own stick, and starts its own
  fight** — and peer 0 is still on the animal at the end of all of it.
* `smoke_net_fly`: peer 1 is airborne for four rounds while **peer 0 builds, drops, picks
  up and engages a wild**, ending in `combat`.

### Landing-anchor validation — the host decides

`docs/specs/MP_ENCOUNTER_PROTOCOL.md` §2 is "no peer may author both an action and the
position it was measured against". A Fly anchor is that shape wearing different clothes:
`recover_to_anchor()` teleports the trainer to it, so an anchor a client writes alone is a
client-authored teleport destination good for the rest of the session.

* `scripts/net/fly_anchor_arbiter.gd` (new) holds the rule as a pure function of numbers —
  `catch_arbiter.gd`'s shape, and for its reason. Refusal codes: `not_yours`,
  `wrong_realm`, `no_ground`, `not_floor`, `too_high`, `too_far`, `sealed`, `malformed`.
* Transport is two explicitly sender-checked RPCs on the trainer proxy. Neither leans on
  node authority: authority there belongs to the *client*, so an `authority` reply from the
  host would be refused at the far end, and a trusting `any_peer` would let any peer answer
  for the host.
* The host tests the claim against **`global_position`** — the result of its own
  `move_and_slide()` in `_follow()` — never against `net_position`, which is what the client
  said. It raycasts for ground in its own world and hands back an anchor built from the
  claim's X/Z and **the host's** ground height. A claim that passes every other test still
  does not choose its own Y.
* Solo and the host commit directly, unchanged. There is no second process with an opinion,
  and validating the host against itself only adds a way to fail.
* `can_launch()` refuses while a landing is unanswered. **`pending` is not a refusal** and
  is not treated as one: the previous granted anchor stands, and the wording says waiting.

`smoke_net_fly` forges a claim 500 m from where the host has peer 1 and asserts the
refusal, the code, that it was not also counted as an accept, and that the committed anchor
is byte-identical afterwards. Measured: `too_far`, anchor unchanged.

---

## 2. Test results — every one run locally

| test | result |
|---|---|
| `--check-only` on every changed script | clean |
| `smoke_riding` | `riding: OK` |
| `smoke_riding_saddle` | `riding saddle: OK` |
| `smoke_fly_traversal` | `FLY CORE: 30 assertions, 0 failures` |
| `smoke_environment_velocity` | `ENVIRONMENT VELOCITY PASS` |
| `smoke_playground` | `smoke: OK` |
| **`smoke_net_riding`** (new) | **43 assertions, 0 failures**, first-attempt green |
| **`smoke_net_fly`** (new) | **46 assertions, 0 failures**, first-attempt green |

Assertion counts are printed by both smokes, and every `check` goes through a counting
wrapper, because a test can pass while running fewer assertions than it should.

Neither new smoke was left to CI. Both were driven to green on this box —
`smoke_net_fly` took six local runs to get there, and each failure was a real fixture or
ordering fact recorded below rather than a retry.

### CI registration

`.github/workflows/ci.yml`'s `verify-multiplayer-shard`: both files added to the named
roster, the count floor **regenerated from the files on disk** (`22`, not `20 + 2`), and
the shard timeout raised 45 → 60 with the measured per-smoke costs written down.

---

## 3. Findings — reproductions, not fixes

### F1 (blocking, on the untouched base) — `verify-multiplayer-shard` could not run at all

`ci.yml`'s "Discover peers:2 net smokes" step carried **two** `if [ "$count" -lt 20 ]; then`
openings and **one** `fi`. Extracting the step's script and running `bash -n` on it at
`6c5189fb`:

```
/tmp/discover.sh: line 97: syntax error: unexpected end of file
```

The step is a bash syntax error, so the shard fails at Discover and no net smoke runs —
on a branch whose whole wave is net smokes. It is exactly the accumulation the block's own
comment warns about, one conflict resolution later. **Fixed here**, because this lane had to
edit the same block to register its smokes; the duplicate opening was deleted and the
regeneration rule restated.

### F2 (real, not this lane's) — a peer's locomotion is switched off by the opening's dialogue

Every peer in a net smoke boots into the opening's `house` beat, and Grandpa's dialogue box
opens (and re-opens) while the trainer is inside the farmhouse.
`sequence_director._refresh_lockout()` reads an open box as a modal panel every frame and
calls `set_locomotion_enabled(false)` — so for as long as it is open the peer **cannot walk
or jump at all**. The probe row that pinned it, off the joining peer:

```
locomotion=false carried=false on_floor=true
lockout={"beat":"house","dialogue":true,"adopting":false,"fading":false,
         "picker":false,"name_prompt":false,"fighting":false,"downed":false}
```

Two consequences that had already cost time elsewhere:

* `can_launch()` reports it as **"Fly is unavailable while riding or in combat"** — a
  sentence about the feature for a problem that is entirely the opening's. Three runs of
  `smoke_net_fly` reported "the second airborne Jump did not launch" before the probe was
  taught to name the lockout.
* It is the likeliest explanation for the divergence
  `tests/smoke_net_movement_two_peers.gd`'s own constant block records and calls "not
  understood" — host 14.52 m, client 2.71 m over the same 300 frames. On this lane's runs a
  peer held full stick forward for 150 frames and travelled **0.00 m**. The client is not
  slow; its locomotion is off.

Not fixed: it is the opening sequence on a session peer, which belongs to the Wave 2/5
lanes, and this is a five-lane wave. Both smokes press through the box the way a player
does (`dismiss_dialogue`, the production `interact` advance), next to the steps that need
it — clearing it once after the handshake is not enough, because the box opens partway
through the beat.

### F3 (real, not this lane's) — a **client's** engage starts a fight with no encounter record

`engage_wild` on peer 1 starts a local fight (`input_context` goes to `combat`) but
`combat_manager.encounter_id()` is still empty after **240 settle frames (4 s)**; measured
at 30 and at 240. `_step_strike` then refuses with "this peer is not in a networked fight".
`tests/smoke_net_shared_wild_fight.gd` only ever engages on the **host**, so no net smoke
had exercised the client side of `MP_ENCOUNTER_PROTOCOL.md` §4 before. Lane 4.C's contract,
not riding's. `_step_engage_wild` grew `require_record` (**default true**, so every existing
smoke is unchanged); `smoke_net_riding` passes false, asserts the claim item 17 actually
makes — peer 1 is *in* a fight while peer 0 is on an animal — and reports the missing
binding rather than going red on another lane's protocol.

### F4 (cosmetic, not fixed) — a mounted viewer suppresses everyone's companion flourishes

`companion_presence.gd::blocked_reason()` returns `"riding"` from the **local**
`RidingController`, so a player who is themself mounted suppresses the idle flourishes of
every *remote* creature in their process too. Presentation only; the same wrong-body class
lane 6.D fixed elsewhere. Another lane's file, cosmetic, left alone.

---

## 4. Divergences from the brief, and why

* **The carrier-creature sync lives on the trainer proxy, not on the creature.** The brief
  names "the carrier-creature sync" as this lane's. The creature proxy's replicated set is
  authored by `encounter_director.gd::_creature_replication_config()`, and `scripts/combat/*`
  is on this lane's do-not-touch list — so a new replicated property on the creature was not
  available. `scripts/creatures/remote_creature.gd` is therefore **untouched**: the saddle
  and the ride are published from the owner's trainer body and applied to the creature body
  the viewer already resolves by owner id. Same picture, no forbidden edit.
* **The host does not check no-fly volumes when validating a landing.** Restriction AABBs are
  the occupant realm's authoring and the trainer proxy has no reader for them; the client
  already enforces them on itself every frame of the glide. The arbiter takes `restricted`
  as an input and the caller passes `""` with a comment saying so, rather than implying a
  check that is not happening.
* **`smoke_net_fly` launches from 45 m of harness-placed altitude.** The Meadows has no cliff
  and no authored updraft — Fly's home is Cloudreach — so a launch off flat ground is a
  two-metre hop against a 2 m/s sink: measured at `flying (glide) at y=2.86`, and over
  before the watching peer had drawn a frame of it. The height is placement, exactly as
  `_step_teleport` is; the launch is still the production second airborne Jump and
  `can_launch()` still refuses it for every real reason.

## 5. Files

**New:** `scripts/net/fly_anchor_arbiter.gd`, `tests/smoke_net_riding.gd`,
`tests/smoke_net_fly.gd`.

**Changed:** `scripts/net/remote_trainer.gd`, `scenes/player/remote_trainer.tscn`,
`scripts/player/fly_controller.gd`, `scripts/player/player_controller.gd` (one accessor,
`carry_offset()`), `scripts/world/riding_controller.gd` (two saddle helpers made static,
one public door), `data/config/fly_traversal.json` (a `landing_anchor` block, all TUNABLE),
`tools/net/peer_runner.gd` (eight steps, two probes), `.github/workflows/ci.yml`.

**Untouched, as required:** `autoload/game_state.gd`, `autoload/world_state.gd`,
`scripts/net/world_ledger.gd`, `scripts/net/ledger_rpc.gd`, `scripts/net/session.gd`,
`scripts/combat/*`, `scripts/ui/*`, `tests/helpers/net_harness.gd`.
