# MP-REALM-REOPEN — realm transitions are open

**Lane:** MP-REALM-REOPEN · **Date:** 2026-09-06 · **Branch:** `claude/mp-realm-reopen`
**Base:** `claude/tetherbound-roadmap-next-jrcjs8` @ `d0a4cf33533c9551c87e86995a2d4b86dc4be516`
**Godot:** 4.7-stable (official), installed at `~/godot-bin/godot`, project imported twice.
**Box:** 4 vCPU, 15 GB. Every number below is from this box.

## Verdict

**The door is OPEN.** `game_state.gd::can_enter_realm()`'s `is_multi_peer()` refusal is gone,
both held smokes carry their `# peers: 2` headers again, and both pass locally:

```
smoke_net_split_realms                     40 checks, 0 failed, exit 0
smoke_net_realm_owner_disconnect_mid_fight 23 checks, 0 failed, exit 0
```

Two players stand in two biomes at once, gather and fight in both simultaneously, swap
realms, and a realm's world state reaches disk when its last occupant vanishes mid-fight.

## The profile, as numbers

| | before | after |
|---|---:|---:|
| Cloudreach shell, worst held frame | 21,947 ms | **1,099 ms** |
| Cloudreach shell, worst 60-physics-frame window | 22.8 s | **4.4 s** |
| Cloudreach shell, `load()` on the main thread | 4,751–5,639 ms | **off-thread** |
| Meadows shell, worst held frame | 30,547 ms | **7,443 ms** |
| Meadows shell, worst 60-physics-frame window | 41.2 s | **9.9 s** |
| Meadows shell, `load()` on the main thread | 3,499 ms | **off-thread** |
| freeing the outgoing Meadows on the crossing peer | 43,049 ms | **1,931 ms** |
| Meadows shell, static memory | 2,610 MB | 2,603 MB (unchanged) |
| Cloudreach shell, static memory | 1,290 MB | 1,292 MB (unchanged) |

The **60-physics-frame window** is the number the feature turns on, not `boot_ms`.
`tools/net/peer_runner.gd` heartbeats every 60 physics frames and
`tests/helpers/net_harness.gd` declares a peer silent after 15 s without one — and a real
host that needs 22 s to get through 60 frames is a host every other player has already
lost. `tools/net/_probe_6a_shell.gd` now reports it directly (`6A-SHELL-PHASES` line).

Reproduce:

```
~/godot-bin/godot --headless --path . --script tools/net/_probe_6a_shell.gd -- --mode=shell --realm=cloudreach
~/godot-bin/godot --headless --path . --script tools/net/_probe_6a_shell.gd -- --mode=shell --realm=meadows
~/godot-bin/godot --headless --path . --script tools/net/_probe_realm_crossing.gd
~/godot-bin/godot --headless --path . --script tools/net/_probe_addchild_live.gd
```

## F1 — D97's correction was itself wrong, and the reproduction is committed

D97's "The measurement the hold was waiting for" reports `add_child_ms=0` and concludes the
shell already builds across frames, so the fix must not be "make the boot asynchronous".
That is an artifact of **where** the measurement was taken. `_probe_6a_shell.gd` calls
`root.add_child()` from `SceneTree._init()`, before the root window has entered the tree,
and Godot does not propagate `_ready()` into a node whose parent is not in the tree yet.
The build was deferred by one frame, not spread over frames — which is exactly why the same
probe reads a **21.9 s single frame** immediately afterwards.

`realm_shells.gd` calls `add_child()` from a live tree. `tools/net/_probe_addchild_live.gd`
does the same and measures `LIVE add_child_ms=21037`. D97's *first* diagnosis was right
about the mechanism. The shell build did have to be made asynchronous, and now is.

## F2 — the biggest cost was not the shell: `interaction_arbiter.gd::unregister()` is O(n)

Once the host-side shell freeze was fixed, `smoke_net_split_realms` failed again on **peer 1**
— the client — going heartbeat-silent on its own ordinary `change_scene_to_file()`.
`tools/net/_probe_realm_crossing.gd` split that into the free of the outgoing world and the
build of the incoming one:

```
FREE of the outgoing world: 43049 ms   (one synchronous engine call)
```

Freeing the same world's children one at a time instead cost **1,790 ms**. The difference is
ordering: the arbiter is an early child, so freeing forward frees it first and the other
24,461 interactables then skip `unregister()` entirely, while `~Node()` frees children back
to front and every one of them pays.

`interaction_arbiter.gd::unregister()` was `_providers.erase(provider)` — a linear
scan-and-shift over an array of 24,461 providers. Tearing a world down unregisters all of
them at once: O(n²), 43 seconds, in one engine call no slicing can break up. PERF-2 had
already fixed the identical O(n²) on the *registration* side and left this one, because
until Wave 6 nothing tore a world down mid-session.

`_providers` had stopped being iterated when the spatial index (`_cells`/`_loose`) landed —
`_recompute()` walks `_candidates()`, not it — and its only remaining readers are tests and
probes asking for a census. It is now a derived view of the O(1) `_provider_set`, so
unregistering is a dictionary erase. `test_interaction_arbiter_register_perf.gd`: 2 tests,
6 assertions, 0 failed.

**This is a single-player fix too.** Every realm crossing and every quit-to-menu paid those
43 seconds.

## What was broken up, and how

`scripts/world/shell_build_budget.gd` (new) is a **time slice**, not a step counter, and the
distinction is the whole design. Sixty consecutive physics frames span about a second on an
idle server, so cutting a 21 s build into fourteen 1.5 s steps still puts every step inside
one heartbeat window — the same 22 s, still no heartbeat. What the window needs is for sixty
frames to keep *happening*, which means bounding the work in each individual frame.

- `breathe()` yields the moment this frame has spent its budget (8 ms for a shell). Called
  inside the build's own loops, not only between them.
- `step(label)` does that and records a named slice, so a shell prints its own profile once.
- A slice at or above 250 ms is treated as **indivisible** and is followed by a whole
  heartbeat window (65 physics frames) of cheap frames, so it never has to share a window
  with anything else. This is what took the Meadows from 13.8 s to 9.9 s.
- `begin()` decides whether to slice at all: finest for a shell; coarse (100 ms) for a peer
  building a real world for itself during a live session; **not at all** otherwise. Solo
  play is byte-for-byte the build it always was — the slicer asks the session first.

Sliced, by file:

| file | where |
|---|---|
| `cloudreach_world.gd` | 12 named `_ready()` steps; `breathe()` inside `_build_regions`, `_build_routes` (per route, per ledge point, per ground section), `_build_route_shoulders` (per section), `_build_landmarks` (three per landmark), `_build_authored_route_details` (per pocket, per item), `_build_resource_patches` |
| `playground_world.gd` | 7 named `_ready()` steps, with the Terrain3D **node** build split from the **data-directory** assignment so the indivisible ~7.4 s region load never shares a window; `breathe()` after each of 29 settlement sub-builds |
| `vegetation.gd` | `build()` takes the slicer; `breathe()` per model batch and every 512 placements inside `_build_batch` |
| `realm_shells.gd` | `ResourceLoader.load_threaded_request()`/`load_threaded_get()`, polled every frame while a read is outstanding |

Measured shell profiles, printed by the world itself:

```
[cloudreach] shell build 20.4 s wall, 124 yields at 8 ms/frame, worst held slice 1709 ms;
  steps (ms): materials=186 regions=658 ledges=25 routes=16259 gates=1 bridges=26
              landmarks=2625 return_gate=1 route_details=6 resource_patches=25
              environment=85 mount=149
[playground] shell build 42.6 s wall, 897 yields at 8 ms/frame, 11 indivisible slices given
  a heartbeat window each, worst held slice 5323 ms;
  steps (ms): terrain_node=28 terrain_data=5323 terrain_collision=484 ground_materials=306
              player_placed=1 vegetation=11274 settlement=18727
```

## What is still slow, honestly

- **A Meadows shell holds one 7.4 s frame** (5.3 s in the smoke's own run). It is a single
  Terrain3D region-data load — one engine call, not script. It is isolated so it never
  shares a heartbeat window, which is what keeps the worst window at 9.9 s against a 15 s
  limit. Reducing it needs Terrain3D streaming, not more GDScript slicing. **Margin note:**
  9.9 s of 15 s is real but not generous; a CI runner ~50 % slower than this box would be at
  the limit. If the shard ever reports `peer silent` again, this frame is the first suspect
  and `shell_build_budget_ms` in `data/config/performance.json` is the lever.
- **A shell takes longer in wall-clock than the freeze did** — 42.7 s for a Meadows shell
  against ~30 s of held frames. That is the deliberate trade: the host spends most of each
  frame on the players already in the session. `realm_shells.gd::report()` now carries a
  `ready` flag per shell, and `build_ms` (the whole sliced build) alongside `attach_ms` (the
  walk to the world root's first yield), because `boot_ms` no longer means anything.
- **The host cannot answer for a realm until its shell is ready.** In
  `smoke_net_realm_owner_disconnect_mid_fight` that is ~43 s after the crossing. The smoke
  now waits on `ready` rather than racing it, and that is the feature's real ordering, not a
  tolerance.

## F3 — the drawing check counted bodies nobody draws

`smoke_net_split_realms` failed with "peer 0 draws no trainer body for a player in another
realm (drew 1)" while the despawn it protects was working perfectly. `_not_mine()` counted
the whole `remote_trainer` group, which includes the body the host stands up **inside its
headless shell** — that is D97's design, it is how the host simulates a realm nobody here
can see, and the shell is not drawn by anyone.

Scoped to bodies under `current_scene` (`peer_runner.gd`'s `remote_trainers` probe now
reports `in_current_scene`), and the positive half added rather than lost: the Cloudreach
shell must **hold** the body of the peer who crossed. Net one more assertion, not one fewer.

## F4 — `_step_drop_link` hid the disconnect from the dropping peer

"the dropped peer is genuinely out of the session, not merely silent" failed because
`_step_drop_link` did `api.multiplayer_peer = null` after `close()`. Assigning null installs
an `OfflineMultiplayerPeer`, for which Godot emits no `server_disconnected`, so that
process's own `Session` never learned its link had died and went on reporting
`is_active()` true. The detach is gone; the step now polls for its own session to notice and
returns a **setup-worded** FAIL if it does not.

## F5 — a client's wild fight has never been host-arbitrated (4.C H1)

`smoke_net_realm_owner_disconnect_mid_fight` asserted that a client engaging a wild gets
bound to a host encounter record. It cannot:
`encounter_director.gd::_open_encounter_if_networked()` is host-only **by design** — lane
4.C's handover H1, because wild creatures are not replicated, so the host has never heard of
the wild a client is standing in front of and has nothing to mint a record about. The smoke
was written asserting a binding `main` has never produced, and never run.

The step takes `require_encounter_record: false` (default stays true, so every other smoke is
unchanged) and the smoke passes it with the limitation named at the call site. It does not
weaken what the smoke is for: the sharp assertion is the one on **disk**, and it passes.

**Handover:** when wild replication lands, drop that argument.

## F6 — `encounter_director.gd::_encounter_realm()` read `Game.current_realm`

Its own doc comment forbids exactly that ("a record stamped with whichever one the host
happens to be in files a Cloudreach fight in the Meadows") and the body did it anyway.
Harmless only while the host could not be standing anywhere else — it can now. It walks up
to the world root and asks `world_realm()`, which both world roots answer and which in a
shell answers the shell's realm.

## The two edits that belong together

1. `can_enter_realm()`: the `is_multi_peer()` refusal deleted, its comment rewritten to the
   measured reopening.
2. `# peers: 2` restored on both smokes, with the HELD notes replaced by RESTORED notes.

Both were made **after** both smokes passed locally, not before.

`verify-multiplayer-shard` count floor and named roster **regenerated from the files on
disk**, never incremented: 22 → 24, and checked both directions (24 discovered, 24 named,
no file in one set and not the other). `bash -n` run over both `run:` blocks in the shard —
both OK. `yaml.safe_load` clean.

## Tests run

| what | result |
|---|---|
| `--check-only` on every changed script | clean |
| `smoke_net_split_realms` | 40 checks, 0 failed |
| `smoke_net_realm_owner_disconnect_mid_fight` | 23 checks, 0 failed |
| `smoke_net_shared_wild_fight` | see below |
| `smoke_cloudreach_transition` | OK |
| `smoke_cloudreach_arrival_walk` | OK |
| `smoke_playground` | `smoke: OK` |
| `test_interaction_arbiter_register_perf.gd` | 2 tests, 6 assertions, 0 failed |

Assertion counts went **up**, not down: both net smokes previously died after 13 and 8
checks respectively.

## Files not touched

`scripts/save/*`, `riding_controller.gd`, `fly_controller.gd`, the six modal panels,
`tests/helpers/net_harness.gd`. No defect found in any of them.

## Handovers

1. **Terrain3D region data is a 7.4 s indivisible frame.** The only remaining held frame of
   any size. Needs Terrain3D-side streaming or a smaller shell heightfield.
2. **Wild replication** (4.C H1) — see F5. Restores the strict binding assertion.
3. **`verify-multiplayer-shard` timeout is an estimate.** It is 45 minutes for an estimated
   +11–13 min; these two smokes are now real and each stands up two to three worlds. The
   first real run should correct it in whichever direction it needs.
4. **`_providers` is a derived view now.** Anything that wants a cheap census should read
   `_provider_set` directly rather than materialising the keys.
