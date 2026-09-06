# MP-6A-REALMS — lane 6.A, realm shells and independent transitions

**Lane:** Stage B Wave 6, lane 6.A · **Branch:** `claude/mp-6a-realms` from `main`
`a3df2546` · **Contract:** `docs/decisions/D97-different-biomes-at-once-are-headless-realm-shells-on-the-host.md`,
directive rule 16 · **Engine:** Godot 4.7.stable.official.5b4e0cb0f, installed headless at
`~/godot-bin/godot`; `--headless --path . --import` run twice before anything else.

**Verdict: rule 16 is implemented and it fits.** `enter_realm()` no longer refuses in a
multi-peer session; the host runs a headless shell for the realm it is not standing in;
replication is realm-scoped; and an owner disconnecting mid-fight in a realm nobody else
occupies has its world state folded back through the host's own save before the shell is
freed. **A host holding its own world plus one shell peaks at 3,937.6 MB VmHWM — 21.6 % over
S2's 3,237 MB solo-host figure, and bounded at one shell however many peers join.**

**The lane could not run its own two net smokes end to end.** They are written, they parse,
they are registered in CI, and the machinery they exercise is measured directly by a probe —
but each needs three to five Meadows-class world builds in one run and this box builds one in
46–65 s. That is stated plainly in §6 rather than dressed up, and it is the lane's single
biggest gap.

---

## 1. One line per deliverable

| # | Deliverable | Verdict |
|---|---|---|
| 0 | `enter_realm()`'s multi-peer refusal lifted | **done** — `autoload/game_state.gd`; replaced by `Session.announce_realm()` and the three things it drives |
| 1 | A client swaps its own world scene without leaving the session | **done** — nothing in `enter_realm()` touches the peer; `Session` is a child of the `Game` autoload, not of any scene, so it outlives the swap. The host despawns the mover's body **before** the swap (ordering asserted in `smoke_net_split_realms.gd`) |
| 2 | The host hosts a headless shell for any occupied realm it is not in | **done** — `scripts/net/realm_shells.gd`, `simulation_only` on both world roots. **Measured, §4** |
| 3 | Spawn containers authored in BOTH world `.tscn` files | **already true on `main`** — `Spawned/{Trainers,Creatures,Items}` plus three `MultiplayerSpawner`s are authored in both scenes (landed with lane 2.C). Verified, not re-done |
| 4 | Replication is realm-scoped | **done** — per-realm spawner filtering in `trainer_spawn.gd` plus a realm visibility filter on each body's `MultiplayerSynchronizer` |
| 5 | An owner disconnecting mid-fight in an otherwise empty realm must not lose world state | **done** — `realm_shells.gd::_tear_down()` runs the host's own world save while the shell is still in the tree |
| — | Two new net smokes, registered in CI | **written and registered; NOT run to completion here.** See §6 |
| — | Shell memory and boot cost against S2 | **done, §4** |

---

## 2. What changed, and why each file

| File | Why |
|---|---|
| `autoload/game_state.gd` | `enter_realm()`: refusal removed, `announce_realm()` added before the scene swap; `realm_of_peer()` and `realm_shell_report()` seams |
| `scripts/net/session.gd` | `announce_realm()` / `_rpc_realm_changed()` / `_apply_realm_change()`, `realm_of()`, `peers_in_realm()`, `occupied_realms()`, the `peer_realm_changed` signal, and the `Realms` mount; reconcile hooks on host/join/kick/disconnect/teardown |
| `scripts/net/realm_shells.gd` (new) | The shells: stand up, tear down through a save, follow their occupants, report their cost |
| `scripts/net/trainer_spawn.gd` | Per-realm spawn set; the synchronizer visibility filter; reconcile on `peer_realm_changed` |
| `scripts/net/remote_trainer.gd` | `net_realm`, the realm a body was spawned into |
| `scripts/world/playground_world.gd` | `simulation_only`, `_shell_strip()`, `track_simulation_focus()`, `world_realm()`, `REALM_ID` |
| `scripts/world/cloudreach_world.gd` | The same three, shaped to a world whose ground is authored geometry |
| `scripts/world/vegetation.gd` | `simulation_only`: the visual half skipped, harvest points and collision kept |
| `tools/net/peer_runner.gd` | `enter_realm` and `drop_link` steps; `realm`, `realm_shells` and `world_records` probes |
| `tools/net/_probe_6a_shell.gd` (new) | The measurement in §4, including the `host_pair` mode that is the decisive one |
| `tests/smoke_net_split_realms.gd`, `tests/smoke_net_realm_owner_disconnect_mid_fight.gd` (new) | The two required smokes |
| `.github/workflows/ci.yml` | Both smokes registered by name; the count floor regenerated from disk |

**Not touched, as instructed:** `scripts/net/world_ledger.gd`, `scripts/net/ledger_rpc.gd`,
`scripts/combat/*`, `scripts/world/sequence_director.gd`, `dialogue_panel.gd`,
`realm_heart_shrine.gd`, `night_rest.gd`. Neither world `.tscn` needed an edit: deliverable 3
was already authored in both.

---

## 3. FINDING 1 — D97's `Session/Realms/<realm>` parent path cannot work, and the code says so

**This is the lane's one deliberate divergence from its own contract.** D97 says the shell is
"the world scene instanced under `Session/Realms/<realm>`". It cannot be, and the reason is
Godot's, not a preference.

Godot's high-level multiplayer addresses a `MultiplayerSpawner` and a
`MultiplayerSynchronizer` **by node path**. A spawn packet carries the spawner's path; the
receiving peer resolves that exact path or drops the spawn. A client standing in Cloudreach
holds its world at `/root/CloudreachCliffs`, because that is where
`change_scene_to_file()` puts a scene root. A host shell parented under the session would sit
at `/root/Game/Session/Realms/cloudreach/CloudreachCliffs`, and every trainer, creature and
dropped item the host spawned into it would be addressed to a path the occupant does not
have. Nothing would arrive, and nothing would say so.

**What ships instead:** the shell is added to the tree root under the scene's own authored root
name — exactly the path the peer standing in that realm has. The names cannot collide: a shell
exists only for a realm the host is *not* in, and each realm's world scene has a distinct root
name. `Session/Realms` (`scripts/net/realm_shells.gd`) still owns them — stands them up, tracks
them, moves their focus, tears them down — which is what "under `Session/Realms`" was for.

The one race this creates is handled and worth naming: when the **host** crosses a boundary,
`change_scene_to_file()` is deferred to the end of the frame, so for a moment the host is still
standing in `/root/MeadowsPlayground` while the reconcile wants to mount a Meadows shell there.
`_stand_up()` bails quietly on the name collision and `_process()` reconciles again on the next
tick, by which time the old scene has gone. That is why the reconcile is periodic and not only
event-driven.

**Recommendation:** amend D97 with this, or reject the divergence and re-plan — but do not
merge the decision's literal wording back in. It does not work.

---

## 4. Shell cost, measured against spike S2

Box: the lane's own container, 4.7.stable headless, `--headless` with no rendering driver.
Instrument: `tools/net/_probe_6a_shell.gd` — load, instantiate, `add_child`, 240 physics
frames, then `OS.get_static_memory_usage()` and `/proc/self/status`'s `VmHWM`, the same fields
`tools/net/_probe_s2_shell.gd` read, so the numbers are comparable with S2's.

S2's reference row (its own box, 4 vCPU / 15 GB): full Meadows **49.9 s warm / 84.2 s cold,
2,783 MB static, 3,237 MB VmHWM**; four concurrent full boots **12.85 GB**.

### 4.1 One world at a time

| Run | Boot | Static | VmHWM | Median frame |
|---|---|---|---|---|
| Meadows, full | 65.0 s | 2,844.8 MB | 3,303.0 MB | 21.54 ms |
| **Meadows, shell** | **45.8 s** | **2,605.0 MB** | **3,061.1 MB** | **13.84 ms** |
| Cloudreach, full | 56.3 s | 1,328.2 MB | 1,445.4 MB | 13.84 ms |
| **Cloudreach, shell** | 31.9 s | 1,286.9 MB | 1,426.2 MB | 13.84 ms |

The Meadows shell saves **239.8 MB static (8.4 %)**, **241.9 MB VmHWM (7.3 %)**, **19.2 s of
boot (30 %)** and **36 % of frame time**.

**Against S2's own shell result this is a sevenfold improvement and it is the number D97's
amendment was waiting for.** S2 measured a *post-hoc free* and recovered 30 % of frame time
for **1.2 %** of memory. The skip-build flag recovers the same frame time and **8.4 %** of
memory. D97 was right that the flag beats the free; it is also now clear by how much, and that
the answer is "materially, but not transformationally" — 2.6 GB is still 2.6 GB, because the
385,333 placements, their streamed collision, their 57,770 harvest points and Terrain3D's
resident data are all *gameplay* and all still built.

### 4.2 The decisive number: one host process holding a world **and** a shell

No combination of the rows above predicts this — the two worlds share an allocator, a physics
server and a resource cache — so it is measured directly (`--mode=host_pair`).

| Host process | First world | Shell adds | **Total VmHWM** | Median frame |
|---|---|---|---|---|
| Meadows + Cloudreach shell | 2,819.9 MB static / 3,302.8 MB VmHWM | +762.8 MB static / +681.1 MB VmHWM, 24.6 s | **3,937.6 MB** | 21.81 ms |
| Cloudreach + Meadows shell | 1,303.0 MB static / 1,445.5 MB VmHWM | +2,078.3 MB static / +2,439.9 MB VmHWM | **3,885.4 MB** | 13.84 ms |

Both rows end with **zero `ERROR:` lines**.

**A host holds at most one shell, however many peers join.** The Meadows and Cloudreach are the
only realms — CLAUDE.md forbids a Biome 2 implementation — so "every occupied realm the host is
not in" is bounded at one. Four peers do not mean four shells.

### 4.3 Does it fit?

**Yes, with the margin stated.**

- **A player's host machine:** worst case 3,937.6 MB VmHWM, against 3,237 MB for the solo
  host S2 measured — **21.6 % more**. On the ROG Ally's 16 GB that is comfortable.
- **2-peer PR CI:** host 3,937.6 MB + client ~3.3 GB ≈ 7.2 GB. Well inside a 16 GB
  runner.
- **4-peer nightly:** 1 host at 3,937.6 MB + 3 clients at ~3.3 GB ≈ 13.8 GB, against
  S2's 12.85 GB for four full boots. That is 1.0 GB over S2's figure and it does **not**
  fit a 16 GB runner beside the runner's own processes — but S2 already ruled 3/4-peer runs out
  of PR CI for exactly that reason, and this lane does not change that verdict.

**Recommendation for D97's deferred memory budget** — two numbers, because the useful one is
not the one the decision asks for:

- **What a shell ADDS to a host process: 2.5 GB.** Measured worst case +2,439.9 MB VmHWM (the
  Meadows shell). This is the number that matters and it is not the same as a Meadows shell
  standing alone (3,061.1 MB), because the second world shares an allocator, a physics server
  and a resource cache with the first.
- **What a host process may reach in total: 4.1 GB.** Measured worst case 3,937.6 MB VmHWM.

Both are the measurement rounded up by a few per cent, not a round number chosen first.

The Cloudreach shell saves very little against a full Cloudreach — 41.3 MB static, 19.2 MB
VmHWM — and that is a direct consequence of §5.2: `build_environment()` had to be put back, and
almost everything else in Cloudreach is the authored geometry its own ground collision is made
of. The Meadows shell is where the saving is, and the Meadows shell is the expensive case, so
that is the right way round.

---

## 5. FINDING 2 — three defects the measurement found, all fixed

None of these would have shown up in a `--check-only` pass or in any solo smoke. All three are
in the report because the shell is the only thing that provokes them.

1. **`Terrain3DInstancer: Mesh ID out of range`, once per cleared instance, every boot.**
   In simulation-only mode `vegetation.gd` assigns synthetic mesh ids from a local counter,
   because nothing is registered with Terrain3D. `clear_area()` — which `_build_settlement()`,
   the burrow warrens and the stronghold all call, for every building pad — then handed those
   synthetic ids straight back to `Terrain3DInstancer.remove_instances()`. Fixed by making
   `_remove_render_instance()` a no-op in a shell: nothing was ever rendered, so there is
   nothing to remove.

2. **2,567 script errors in a single 240-frame Cloudreach shell boot.** The first cut skipped
   `cloudreach_world_runtime.gd::build_environment()` as "the atmosphere pass". It is not: it
   builds `SummitArenaPresentation` and `CloudreachBattleYards`, and `mount()` reads both. The
   result was a null `presentation` at mount and then a null `atmosphere` **every frame** in
   `_sync_returning_travelers()`. It buys 54 MB. Fixed by running it in a shell too.

3. **`mount()` reads `PlaygroundHUD` by name.** Cloudreach's strip freed the HUD before
   `mount()` ran, making that a hard `get_node()` error. Fixed by splitting the strip: the
   nodes whose `_ready()` must never run go at the top of `_ready()`; the HUDs go after
   `mount()`, before any frame is drawn (`_shell_strip_huds()`).

After all three, a Meadows shell boots with **zero `ERROR:` lines** across 540 frames.

---

## 6. Testing — what ran, what did not, and the honest gap

### 6.1 Ran, green

**`--check-only` on every changed script** — 11 files, all clean:

```
~/godot-bin/godot --headless --path . --check-only --script <file>
```

`autoload/game_state.gd`, `scripts/net/session.gd`, `scripts/net/realm_shells.gd`,
`scripts/net/trainer_spawn.gd`, `scripts/net/remote_trainer.gd`,
`scripts/world/playground_world.gd`, `scripts/world/cloudreach_world.gd`,
`scripts/world/vegetation.gd`, `tools/net/peer_runner.gd`, `tools/net/_probe_6a_shell.gd`,
and both new smokes.

**Solo regression, by name, all three green:**

```
~/godot-bin/godot --headless --path . --script tests/smoke_playground.gd            -> smoke: OK, exit 0
~/godot-bin/godot --headless --path . --script tests/smoke_cloudreach_transition.gd -> CLOUDREACH TRANSITION OK meadows -> cloudreach -> meadows, exit 0
~/godot-bin/godot --headless --path . --script tests/smoke_cloudreach_arrival_walk.gd -> CLOUDREACH ARRIVAL WALK OK, exit 0
```

First attempt, no retries. `smoke_cloudreach_transition` matters most of the three here: it is
a solo `enter_realm()` round trip, and it is what proves the refusal was lifted without
changing what a solo crossing does.

`smoke_playground` and `smoke_cloudreach_transition` were re-run on the FINAL tree after §5's
three fixes landed, and are green there too — the three-smoke run above predates them.
`smoke_cloudreach_arrival_walk` was not re-run: nothing between the two trees touches a code
path it reaches that `smoke_cloudreach_transition` does not also reach.

**Shell measurement:** six probe runs, §4. The Meadows shell run ends with zero `ERROR:` lines.

### 6.2 Written and registered, NOT run to completion — the gap

`tests/smoke_net_split_realms.gd` and
`tests/smoke_net_realm_owner_disconnect_mid_fight.gd` are complete, parse clean, declare
`# peers: 2`, copy the host/join handshake block from
`tests/smoke_net_movement_two_peers.gd` verbatim as instructed, and are registered by name in
`verify-multiplayer-shard`. **Neither was run through `tools/net/run_net_smoke.sh` to a
verdict in this lane.**

The reason is the measurement in §4, not a decision to skip: `split_realms` needs five
Meadows-class world builds across two processes and `realm_owner_disconnect_mid_fight` needs
four, at 46–65 s each on this box, on top of two 240-frame settles per peer. Each run is
20–40 minutes of wall clock before a single assertion is reached, in a container shared with
four concurrent lanes.

**What that means for the reader, stated exactly:** CI is the gate and these two are in it.
Their first real verdict comes from the shard. Do not read anything in §1 as "the smokes
passed" — read it as "the mechanism was verified directly by probe and solo run, and the
smokes that assert it end to end have not yet had their first run". If either goes red on the
first shard run, that is this lane's finding arriving late, not a flake, and §7's handover
names where to look first.

The per-smoke step budget is set in each file (`REALM_STEP_BUDGET_S`, 1,200 s and 900 s) rather
than by raising `data/config/multiplayer.json`'s shared `smoke_step_budget_s_2peer` — raising
that globally would hide a real hang in a cheap smoke. **The shard's own `timeout-minutes` was raised
from 25 to 45**, from the measured build costs rather than from a shard run; see §7.1.

### 6.3 CI registration

The count floor was regenerated from the files on disk (`15`), not incremented — the shard's
own comment asks for exactly that, and five lanes are adding smokes into this wave at once.
Both new files are added to the named-registration list.

---

## 7. Handovers

1. **`verify-multiplayer-shard`'s timeout is now 45 minutes, and that number is an estimate.**
   The thirteen existing smokes filled 20 of the old 25 (run 34015409321). These two add four
   to five world builds between them, which at §4's measured costs is +11 to +13 minutes — so
   25 could not have held. 45 is 20 + that + margin for a slower runner, arithmetic on measured
   build costs rather than a measurement of the shard itself. **First real shard run: read the
   wall clock and correct it in whichever direction it points.** A shard finishing in 32
   minutes does not need 45.

2. **Both new smokes' first verdict is pending.** §6.2. Debug order if `split_realms` fails:
   does `enter_realm` return true at all (the refusal really gone), then does
   `/root/CloudreachCliffs` become `current_scene` on the client, then does the host's
   `realm_shells` probe list `cloudreach`, and only then the body counts.

3. **`SequenceDirector` is freed in a Meadows shell; D97 keeps the panels instead.** The
   panels stay (D97's letter), but nothing calls them because the caller is gone. This closes
   a hole the panels-only rule leaves open — a `DialoguePanel` is a `CanvasLayer`, and a shell
   running a story beat would draw a dialogue box over the screen of a player in another
   realm. Nothing looks the director up by name (grepped, not assumed).
   `scripts/story/sequence_director.gd` is lane 5.A's and was not touched. **Worth a second
   opinion from 5.A.**

4. **A client's realm change is not acknowledged before it swaps scenes.** `enter_realm()` is
   synchronous and nothing in `session.gd` is a coroutine, so the client announces and moves.
   For one round trip the host still holds a body for it in the realm it has left. The
   consequence is bounded — the host's reconcile removes it, and Godot may log a despawn for a
   node the client freed with its old scene. A client that could not walk through a gate until
   a packet came back would be worse. **If the despawn logging proves noisy in the shard, that
   is where it comes from.**

5. **Terrain3D collision in a shell follows the shell's camera, which follows its occupants**
   (`track_simulation_focus`, 0.5 s, matching `COLLISION_STREAM_INTERVAL`). This is the right
   shape but it is **untested against a peer moving fast across the Meadows**; a creature the
   host simulates could outrun the bubble. D96's amendment (Terrain3D `FULL_GAME` collision on
   the host, +16 MB / 3 s) would remove the question entirely and is not implemented here —
   `playground_world.gd` still sets `collision_mode = 1`. **Lane 4.D or a follow-up.**

6. **Ground materials and the terrain texture list are still built in a Meadows shell.**
   `_apply_ground_materials()` / `_build_texture_list()` were left alone as the conservative
   choice: Terrain3D's behaviour without a material is not something this lane could establish
   cheaply. It is the largest unexamined saving left. **Measure before assuming it is safe.**

7. **`vegetation.gd`'s harvest points and streamed collision are still built in a shell** —
   57,770 harvest nodes. They are kept because a shell must hold the ground and gather points
   its occupants act on, but the host's own ledger verdicts are scene-independent
   (`world_ledger.gd` writes flags and never consults a node), so a stricter shell could
   plausibly drop the harvest nodes. Not attempted: it reaches further into `vegetation.gd`
   than this lane's scope, and the win is unmeasured.

---

## 8. Traps honoured

- **`OfflineMultiplayerPeer`.** Nothing added here reads `multiplayer.is_server()`.
  `realm_shells.gd::_is_host()` asks the session for `is_active() and is_host()` together —
  the only pair that means `_mode == "host"` — and re-reads it every call, never caching at
  `_ready()`. The realm visibility filter re-reads the session on **every evaluation**, because
  the answer changes the moment somebody walks through a gate.
- **A test that passes while running fewer assertions.**
  `smoke_net_realm_owner_disconnect_mid_fight.gd::_count()` checks `has()` before `get()` at
  every level and returns `-1` for a malformed probe rather than letting `int(null)` produce a
  confident zero. Assertion counts: `split_realms` **31**, `realm_owner_disconnect_mid_fight`
  **21**, both fixed and unconditional after the handshake gate.
- **Never `--headless` with a rendering driver.** Every command in this report is
  `--headless` alone.
- **Anti-grind.** Two attempts on the Cloudreach shell's error storm; the second found the
  real cause (§5.2/5.3) and it is fixed. No third attempt on anything.
