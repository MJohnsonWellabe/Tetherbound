# MP-5B-HEARTS-0906 — realm Hearts (5.B) and presentation on remote bodies (6.D)

Branch: `claude/mp-5b-hearts`. Base: `main` @ `a3df2546` (session, ledger, creature
ownership 4.B, encounter core 4.C). No pull request, as briefed.

Godot **4.7-stable** (`4.7.stable.official.5b4e0cb0f`) installed headless at
`~/godot-bin/godot`; `--headless --path . --import` run twice on a clean checkout
before any work.

---

## 1. What shipped

### Part 1 — Realm Hearts (5.B)

**Earned and placed are world facts and now go through the ledger. Which Heart is
active stays personal and deliberately does not.**

- `scripts/world/realm_heart_shrine.gd` gained `submit_place(game)`: the Place
  press is a `set_world_flag` INTENT submitted to `Game.ledger`, quoting the
  Heart's own `placed_flag`. It returns `world_ledger.gd`'s verdict shape
  unchanged, so a caller never branches on the type of the answer. On the host
  and solo the delta lands inside `submit()` and the shrine repaints in the same
  call; on a client the verdict is `pending`, **nothing local moves**, and the
  shrine repaints when `ledger_rpc.gd` sweeps the `progression_restore` group —
  which this node already joined in `_ready()`.
- The shrine now stamps its own `realm` (D97) off a new `realm_id` export,
  defaulting to the Heart's id. It never reads `Game.current_realm`.
- A process with **no ledger mounted at all** (every unit fixture) falls back to
  the direct `RealmHeartState.place()` write. That is the pre-Wave-3 path, kept
  on purpose: the alternative is a shrine that silently does nothing in every
  headless test.
- `autoload/realm_heart_state.gd` gained `earned_flag(id)` / `placed_flag(id)`
  so the flag names have one source, and `place()`'s header now says loudly that
  shipping code submits the intent instead of calling it.
- `realm_hearts._active_id` was **not touched**. It already lives on the player
  half of the split (`PlayerState.save_data()` carries `realm_hearts`) and
  nothing replicates it — which is why two peers can wear different powers.

### Part 2 — presentation on remote bodies (6.D)

- New `scripts/net/remote_presentation.gd`: pure, static, no node and no session.
  `sample()` reads the numbers a body's owner may publish, `diff()` turns two
  samples into events, `play()` draws one on a body this process does not own
  (hit spark + flash, KO puff, catch sparkle, level-up flourish), asks that
  body's own `Presence` for a reaction, and asks `world_audio.gd` for a cue.
- `scripts/creatures/remote_creature.gd` and `scripts/net/remote_trainer.gd`
  each gained a presentation channel: `broadcast_presentation()` (owner only),
  an `@rpc("authority", "call_remote", "reliable")` receiver, and
  `play_presentation()`, which bumps `presentation_plays`, records
  `last_presentation` / `last_effect` and emits `presentation_played`.
- The creature proxy's owner side samples the director's `ally_instance()` every
  physics frame — beside the position it already samples — and publishes the
  difference: a drop in `hp` is a hit, `fainted` turning true is a knockout, a
  rise in `level` is a flourish. The trainer proxy's owner side publishes the
  catch off `catch_resolved`, and the creature proxy publishes the victory off
  `exited`.
- `scripts/creatures/companion_presence.gd` gained a `remote` mode. A remote
  creature body now carries its own `Presence`; in that mode the guards that
  describe the **local player's screen** (their combat manager, riding, the
  interact arbiter, an open panel, an armed build ghost) do not apply, `_creature()`
  is null rather than the local player's active creature, and the node stays
  **out of** `GROUP` — otherwise `call_group(GROUP, "on_event", "victory")` from
  the local fight would make a friend's creature celebrate our win.
- `scripts/audio/world_audio.gd` gained one public entry, `on_remote_event(kind, at)`,
  and joins a `world_audio` group so `remote_presentation.gd` can find it without
  knowing the world node's name.

**It never decides an outcome.** Nothing in the 6.D path writes a number. Every
payload is produced by the OWNER, off numbers the host had already written there
(`apply_host_enemy_hit`, `apply_host_catch_verdict`, the record that ends the
fight), and is carried to viewers as a picture to draw. Delete
`remote_presentation.gd` and the project loses pictures and nothing else.

**Why the owner publishes rather than each viewer working it out:** a viewer has
nothing to work it out from. A remote body has no combat manager, no party and no
encounter record of its own — the record only reaches the participants of that
fight, so a bystander watching two friends fight would still see silence. The
owner is the one process where the host's answer has already landed.

---

## 2. Evidence

All runs on this branch with the locked engine. First-attempt results unless the
line says otherwise.

| Check | Result |
|---|---|
| `--check-only` on every changed script (8 files) | clean |
| `tests/smoke_vfx_lifecycle.gd` | `VFX lifecycle: 9/9 passed` |
| `tests/smoke_playground.gd` | `smoke: OK` |
| `tools/net/run_net_smoke.sh hearts` | see §3 |

`.github/workflows/ci.yml`'s `verify-multiplayer-shard` was updated: the floor was
**regenerated from the files on disk** (14 `# peers: 2` smokes at the time of
writing, not the previous 13 incremented by one), and the named-registration list
was rebuilt from the same enumeration rather than edited by hand — four other
lanes are adding smokes concurrently and a bumped guess reconciles to the wrong
number. YAML re-parsed after the edit.

---

## 3. The net smoke, and the two defects its first run found

`tests/smoke_net_hearts.gd` (`# peers: 2`, handshake block copied verbatim from
`tests/smoke_net_movement_two_peers.gd`).

**Assertion counts.** Run 1: 54 assertions, 49 PASS / 5 FAIL (the 5 failures were
4 distinct claims, one of them re-reported in the run summary). Run 2, after the
two fixes below: **50 assertions, 50 PASS, 0 FAIL, `ALL CHECKS PASSED`**, both
peers `unexpected_exit=false`.

Run 2 is not a retry of run 1's code — run 1 found two real defects, both fixed
below, and run 2 is the first run of the fixed tree. Nothing here passed only on
a second attempt.

### Run 1 — the 5.B half passed in full, first attempt

Every Heart assertion passed on the first run, including the discriminating ones:

- `peer 1 pressed Place at the shrine (submitted; the host has still to answer)`
  — the press really was a client press that got `pending`.
- `peer 0's WORLD says the Heart is placed -- one player put it in, both see it`
  and the same for peer 1. Read off `Game.world.flags` **directly**, not through
  the merged progression view: a placement written to the presser's own player
  store would answer `true` through the merged view on the peer that made it and
  `false` on its friend, which looks exactly like success from inside the process
  that did it.
- `the two peers hold DIFFERENT active Hearts at the same time`, and
  `peer 1's Heart power is actually in effect and peer 0's is not (2.00 vs 1.00)`
  — the power is a real number in one world at one moment, not just a string.
- Then the reverse: peer 0 puts it on, peer 1 takes it off, and the pair reads
  the other way round while the world fact does not move.

### Defect 1 (real, in this lane's code) — the sampler was pointed at the wrong object

`FAIL: peer 1's creature took a blow (this peer has no active creature to hurt)`

The creature proxy sampled `Game.party.active()`. Measured, not assumed:
`encounter_director.gd::adopt_starter()` builds an instance and stands a body on
it **without ever putting it in the party**, so `active()` is null for the whole
opening and for every harness deploy — and the sampler published nothing at all.
Fixed by reading the director's `ally_instance()` (the instance the body was
built around, and the same source `combat_vfx.gd::_body_for()` already uses),
with `party.active()` kept only as the fallback. The position half of
`remote_creature.gd` still reads the `deployed_creature` group rather than the
director, and the comment now says why the two differ: a body's position is a
fact about the body; which instance it stands for is not.

### Defect 2 (in the smoke, not the code) — looking for a spark after it had gone

`FAIL: the hit left a real effect node on peer 0's screen ([])`
`FAIL: the catch left a real effect node on peer 0's screen ([])`

The probe scanned the live scene for effect nodes 60 frames after the publish.
Every one of these effects is a fraction of a second long and frees itself, so
the scan found an empty parent and reported "the hook never fired" — while
`plays` and `last` on the same body said it plainly had. Fixed by recording
`last_effect`, the NAME of the node the draw actually built, at draw time. The
weaker live scan is kept in the probe as `effects`, labelled as a debugging aid:
an empty `effects` beside a non-empty `effect` means the picture played and
finished.

Note that the catch's `plays` **did** reach peer 0 on run 1
(`peer 1's catch drew a sparkle on peer 0's copy of peer 1 (1 plays)`), as did
the knockout — so the RPC path, the counter and the signal were proven on the
first run and only the node-existence assertion was wrong.

### Run 2

```
PASS: peer 1 pressed Place at the shrine (submitted; the host has still to answer)
PASS: peer 0's WORLD says the Heart is placed -- one player put it in, both see it
PASS: peer 0's shrine repainted off the placement (state 'placed_inactive')
PASS: peer 1's WORLD says the Heart is placed -- one player put it in, both see it
PASS: peer 1's shrine repainted off the placement (state 'placed_inactive')
PASS: the two peers hold DIFFERENT active Hearts at the same time
PASS: peer 1's Heart power is actually in effect and peer 0's is not (2.00 vs 1.00)
PASS: peer 0 is now wearing the Heart (got 'meadows')
PASS: peer 1 is now wearing none (got '')
PASS: peer 0's world still holds the placed Heart after both selections moved

PASS: the friend's creature carries a companion layer of its own
PASS: peer 1's creature took a blow (hp 134.4 -> 94.1)
PASS: a hit on peer 1's creature drew something on peer 0's copy of it (1 plays)
PASS: the picture peer 0 drew was the hit (got 'hit')
PASS: the hit built a real effect node on peer 0's screen ('HitSpark')
PASS: the knockout drew again on peer 0 (2 plays, was 1)
PASS: peer 1's catch drew a sparkle on peer 0's copy of peer 1 (1 plays)
PASS: the catch built a real effect node on peer 0's screen ('CatchBurst')
PASS: peer 1 drew nothing on its own copy of peer 0's creature from its own publishes

ALL CHECKS PASSED
```

The `hp 134.4 -> 94.1` line is the sampler working end to end: hit points came off
peer 1's creature through `take_damage()`, peer 1's outbound proxy noticed on its
next physics tick and published the difference, and peer 0 drew a `HitSpark` on
the body it holds for peer 1's creature — with no combat manager on peer 0
driving that creature and no local signal anywhere in the path.

### A pre-existing defect on the base, observed but NOT fixed here

Both runs log, on every trainer spawn:

```
SCRIPT ERROR: Invalid call. Nonexistent 'bool' constructor.
   at: _apply_nameplate (res://scripts/net/remote_trainer.gd)
```

`_ready()` calls `_apply_nameplate()` **before** `_apply_ownership()`, so
`plate.visible = not bool(_owned_here)` runs while `_owned_here` is still `null`,
and `bool(null)` is an error in Godot 4.7. It is harmless in effect —
`_apply_ownership()` calls `_apply_nameplate()` again a line later with a real
bool — but it is a script error on every spawn. Confirmed present in
`git show HEAD:scripts/net/remote_trainer.gd`, i.e. on the untouched base, and it
is not caused by this lane.

Left alone deliberately: it is one line, but it is in the lane 2.C spawn/ordering
path rather than in this lane's presentation channel, and a drive-by edit there
during a five-lane wave buys a merge conflict for no behaviour change. Whoever
owns trainer spawn should swap the two calls (or make the read
`_owned_here == true`). This lane's own ownership reads are all downstream of
`_apply_ownership()` and are never null.

---

## 4. Traps the brief named, and what was done about each

- **`OfflineMultiplayerPeer`.** Both `broadcast_presentation()` implementations
  go through `_can_present()`, which requires `multiplayer.has_multiplayer_peer()`
  **and** `Game.is_multi_peer()` before any `rpc()`. With no session
  `is_multiplayer_authority()` is true for every node and `rpc()` on the offline
  peer is an error; solo is a silent no-op with nobody to tell. Authority itself
  is still re-read every frame by the existing `_apply_ownership()`, untouched.
- **`ledger_rpc` sweeps `progression_restore` BEFORE emitting `delta_applied`.**
  The shrine is driven entirely by the sweep (`restore_progression_from_game` →
  `_refresh`) and reads no `delta_applied` guard at all, so there is nothing here
  for that ordering to skip. The smoke asserts the client's shrine repainted
  (`state 'placed_inactive'`), which is exactly the case that would have broken.
- **A test can pass while running fewer assertions than it should.** Every probe
  in the smoke is fetched through a helper that turns a null probe into `{}`, and
  every check is `row.has(key) and <test>` — so a peer that died or timed out
  FAILS rather than having `int(null)` answer 0. Assertion counts are reported
  above rather than only pass/fail.

---

## 5. Files touched

Owned by this lane and changed:

```
scripts/world/realm_heart_shrine.gd      the Place path -> set_world_flag intent
autoload/realm_heart_state.gd            earned_flag()/placed_flag(); place() documented
scripts/creatures/companion_presence.gd  remote mode
scripts/audio/world_audio.gd             on_remote_event(); world_audio group
scripts/net/remote_presentation.gd       NEW: the one door for a remote body's pictures
scripts/creatures/remote_creature.gd     presentation channel + sampler + Presence
scripts/net/remote_trainer.gd            presentation channel + the catch
tools/net/peer_runner.gd                 6 arms, 2 probes
tests/smoke_net_hearts.gd                NEW
.github/workflows/ci.yml                 shard floor + named registration
```

Not touched, as briefed: `autoload/game_state.gd`, `autoload/world_state.gd`,
`scripts/net/world_ledger.gd`, `scripts/net/ledger_rpc.gd`, `scripts/net/session.gd`,
`scripts/combat/encounter_director.gd`, `scripts/combat/combat_manager.gd`,
`sequence_director.gd`, `dialogue_panel.gd`, `enter_realm` / world roots / world
`.tscn`.

---

## 6. Handover

1. **"Different active Hearts" is proved as `meadows` vs `""`.**
   `data/config/realm_hearts.json` ships exactly one Heart. Inventing a second
   would be inventing a game decision, so the smoke asserts what the shipped data
   honestly supports — the selections differ, each moves without disturbing the
   other, and the power is measurably in effect on one peer and not the other.
   When Cloudreach's Heart lands in that config the strengthening is one line:
   both peers active, on different ids.
2. **The knockout is published directly in the smoke rather than by emptying the
   bar.** A creature that actually faints is a creature `encounter_director.gd`
   may put away, and a body recalled mid-assertion reads as "the picture never
   arrived". The sampler's `fainted` branch is one line beside the `hp` branch
   the smoke proves end to end. A lane that owns the director could tighten this.
3. **`level_up` has no audio cue.** `data/config/audio.json` has none and this
   lane did not invent one; the flourish is the whole picture.
4. **A failed catch draws nothing on a remote trainer.** Breaking out is a picture
   on the CREATURE, not on the thrower, and there is no such effect today.
5. **The 6.D half rides in `smoke_net_hearts.gd`.** It needs exactly what that
   smoke has already built by its halfway point, and CI's net shard runs every
   `peers: 2` file in full — a second file would pay for a second handshake to
   assert five more lines. It is fenced in its own function and lifts out cleanly.
6. **No renders, no visual judge, no capture sheet**, per the brief. What is
   asserted is that the hooks fire on a remote body: a counter, a signal-driven
   kind, and the name of a node that was really built. Whether it looks right is
   Stage C's bar.
