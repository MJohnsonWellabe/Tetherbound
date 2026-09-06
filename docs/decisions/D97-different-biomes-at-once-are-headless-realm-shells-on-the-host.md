# D97 — Different biomes at once are headless realm shells on the host

**Date:** 2026-09-05 · **Decided by:** Fable, Stage B lane 0.A, from `docs/MULTIPLAYER_DIRECTIVE.md` and the codebase facts in `docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md` §1. Adversarially reviewed before approval.

## Decision

The host runs one **realm shell** per occupied realm it is not itself in: the world scene
instanced under `Session/Realms/<realm>` in simulation-only mode (heightfield, encounter director,
world records, pickups/gates/NPC triggers, spawn containers; no grass, water rendering, VFX, HUD or
audio). Spawn containers (`Spawned/Trainers`, `Spawned/Creatures`, `Spawned/Items`) are authored
in both world `.tscn` files so a spawn arriving during a peer's procedural build has a path.
Replication is realm-scoped through synchronizer visibility and per-realm spawners. Every ledger
intent and world record carries an explicit `realm`; nothing authoritative reads
`Game.current_realm`. Until Wave 6 lands this, `enter_realm()` is refused in a multi-peer session
with a message (directive rule 16 permits the interim limitation only during development).

## Why

The first draft delegated an unhosted realm's simulation to its first occupant. Review showed two
things that sink it: a `MultiplayerSpawner` spawns under a `spawn_path` that must exist on the
host, so a host with no Cloudreach scene cannot spawn Cloudreach trainers for a second client; and
a delegating client's disconnect mid-fight loses encounter state nothing else holds. A headless
shell keeps the host authoritative with a bounded cost that spike S2 measures.

## Amended 2026-09-05, after spike S2

A shell is a **skip-build flag** threaded through `playground_world.gd`'s `_dress_the_meadow()`,
`_stand_up_the_grass_field()` and `_build_water()` (and the visual half of vegetation), never a
post-hoc free: freeing after `_ready()` recovered 30 % of frame time but only 1.2 % of memory,
because the 385,333-prop scatter and Terrain3D's resident data were already built. The three
story panels (`DialoguePanel`, `NamePrompt`, `StarterPicker`) stay in a shell —
`sequence_director.gd` calls them every frame. The shell's memory budget is set in Wave 6 only
after a spike measures the skip-build variant; the interim same-realm limitation stands until then.


## Built, measured, and held — 2026-09-06

Lane 6.A built all of this: the registry learns where each peer stands, the realm being left
despawns that peer's body while its world is still up, `scripts/net/realm_shells.gd` stands a
headless shell for any occupied realm the host is not in and folds one down through the host's own
world save when a realm empties, and `game_state.gd::enter_realm()` announces the crossing before
`change_scene_to_file()` so nobody is left drawing a trainer who has gone. That machinery is sound
and is left in the tree.

**The interim refusal is re-instated anyway, because of what the shell costs.**

`realm_shells.gd` does `packed.instantiate()` and then a synchronous `tree.root.add_child(node)`.
`add_child` is what runs the world root's `_ready()`, and that `_ready()` is the entire world
build. `simulation_only` is set before the call, exactly as intended, and still does not bring it
under the net harness's 15-second heartbeat window. Both of the lane's own smokes die at that one
call:

```
split_realms                        PASS: the host holds no realm shell while everybody is in one realm
                                    PASS: the Cloudreach route is open before anyone tries to walk it
                                    FAIL: peer 1 crossed into Cloudreach (peer 0, no heartbeat for >15 s)
realm_owner_disconnect_mid_fight    PASS: the Cloudreach route is open before the host tries to walk it
                                    FAIL: the host crossed into Cloudreach (peer 0, no heartbeat for >15 s)
```

Every other assertion in both smokes passes. The failure is isolated to standing the shell up, and
it happens whether the **client** crosses (host shells the realm being entered) or the **host**
crosses (host shells the realm being left occupied).

**Why that is a hold and not a test problem.** In a smoke it is a timeout. In a real session it is
the host freezing for tens of seconds the moment a friend walks into Cloudreach — every other
player stalled, mid-fight, on a machine they do not control. That is worse for everyone than not
having realm transitions at all, which is what the refusal restores.

**The retry does not start over.** `realm_shells.gd` already instruments `boot_ms` and the
static-memory delta around the `add_child` site; nobody has yet seen those numbers, because the
lane left both smokes to CI and never ran them. Spike S2's figures are the budget to come in under
(~85 s cold, 2,783 MB). The shape of the fix is standing the shell up **across frames** rather than
inside one, and the two smokes are held with their `# peers: 2` headers removed rather than
deleted — restoring them is two edits that belong together, both named in
`can_enter_realm()`'s comment.

**Not a quarantine.** The smokes are not failing while the feature ships; the feature is withdrawn
and its tests are withdrawn with it.


## The measurement the hold was waiting for — 2026-09-06

Taken after the hold, with `tools/net/_probe_6a_shell.gd` (lane 6.A's own probe, which had never
been run) and a three-phase timing probe. **The first diagnosis in the section above was wrong
about the mechanism**, and the correction changes what the fix has to be.

**Shell cost, Cloudreach, skip-build mode:**

```
boot (load+instantiate+add_child+240 physics frames)   24.0 s
static                                               1,289 MB  (world alone 1,264 MB)
median frame 13.8 ms, p95 20.7 ms
full Meadows boot for comparison                       43.0 s, 2,800 MB
```

**Where those 24 seconds actually go:**

```
load_ms=3387   instantiate_ms=6   add_child_ms=0
```

`add_child` returns in **zero** milliseconds. The world root's `_ready()` reaches its first
`await` immediately, so Godot runs it as a coroutine and the build really does spread across
frames — the section above assumed `add_child` ran the whole build synchronously, and it does not.

So there is exactly **one** hard synchronous block, `load()` at 3.4 s, and the remaining ~20 s is
the host building the shell a slice at a time while trying to stay responsive. The net harness's
15 s heartbeat window dies somewhere in that spread, which means the host's frames get heavy
enough during the build to starve a heartbeat that only needs to go out every 60 frames.

**What the fix therefore is, and is not.** It is not "make `add_child` asynchronous" — that is
already true. It is:

1. `ResourceLoader.load_threaded_request()` / `load_threaded_get()` for the 3.4 s `load()`, which
   is the only true freeze and the only part a player would feel as a hang;
2. then find the heavy slices between the world root's existing awaits and break them up, because
   a host that stutters for twenty seconds when a friend crosses is still bad even though it is
   not frozen. The p95 of 20.7 ms is the *settled* frame time and says nothing about the build
   itself — that is the number the retry has to capture.

**Budget to come in under:** the shell is 1,289 MB beside a host already holding a full world, and
S2 put four concurrent boots at 12.85 GB. Two realms on one host is affordable; the question the
retry answers is whether it is affordable *while staying responsive*.


## Reopened — 2026-09-06, lane MP-REALM-REOPEN

Directive rule 16 is open. `can_enter_realm()`'s multi-peer refusal is gone and both net
smokes pass locally: `smoke_net_split_realms` 40 checks, and
`smoke_net_realm_owner_disconnect_mid_fight` 23. Two players stand in two biomes, gather
and fight in both at once, swap realms, and a realm's world state survives its last
occupant vanishing mid-fight.

**The section above is wrong about the mechanism, and the section above THAT was right.**
`add_child_ms=0` is an artifact of where it was measured: `tools/net/_probe_6a_shell.gd`
calls `root.add_child()` from `SceneTree._init()`, before the root window is inside the
tree, and Godot does not propagate `_ready()` into a node whose parent is not in the tree.
The build was deferred one frame, not spread across frames — which is exactly why the
same probe then reads a 21.9 s **single frame**. Called from a live tree, the way
`realm_shells.gd` calls it, `add_child()` blocks for 21 s
(`tools/net/_probe_addchild_live.gd`). So the shell build did have to be made
asynchronous, and now is.

### What the freeze actually was, in three parts

| | before | after |
|---|---|---|
| Cloudreach shell, worst held frame | 21.9 s | 1.1 s |
| Cloudreach shell, worst 60-physics-frame window | 22.8 s | 4.4 s |
| Meadows shell, worst held frame | 30.5 s | 7.4 s |
| Meadows shell, worst 60-physics-frame window | 41.2 s | 9.9 s |
| freeing the outgoing Meadows on the crossing peer | 43.0 s | 1.9 s |
| `load()` of a shell's scene, on the host's main thread | 3.5–5.6 s | off-thread |

The 60-frame window is the number that decides the feature: `peer_runner.gd` heartbeats
every 60 physics frames and the harness calls a peer silent at 15 s. Spreading a build
over a handful of frames does not help — sixty consecutive frames span about a second, so
fourteen one-and-a-half-second steps all land inside one window. The build is time-sliced
instead (`scripts/world/shell_build_budget.gd`), and a slice too long to divide is
followed by a whole window of cheap frames so it never has to share one.

**The largest single cost was not the shell at all.** It was
`interaction_arbiter.gd::unregister()` — an `Array.erase()` over 24,461 registered
providers, O(n) each, so tearing a world down was O(n²): 43 seconds in one engine call
that no slicing can break up, paid by whichever peer walks through the gate. PERF-2 had
fixed the same O(n²) on the registration side and left this one, because until Wave 6
nothing tore a world down mid-session. `_providers` had already stopped being iterated
when the spatial index landed, so it is now a derived view of the O(1) membership
dictionary. Every realm crossing in single-player got 41 seconds faster too.

### What it costs, stated plainly

A shell now takes **longer in wall-clock** than the freeze did — 42.7 s for a Meadows
shell in the smoke, against ~30 s of held frames before — because the host is deliberately
spending most of each frame on the players who are already in the session. During that
window the host is authoritative for a realm it cannot yet fully answer for, so
`realm_shells.gd::report()` carries a `ready` flag per shell and things that need the
realm to answer wait on it rather than racing it. The remaining 7.4 s single frame in a
Meadows shell is one indivisible Terrain3D region-data load; it is isolated so it never
shares a heartbeat window, and reducing it needs Terrain3D streaming, not GDScript.

Budgets live in `data/config/performance.json` (`shell_build_budget_ms`,
`crossing_build_budget_ms`). Solo play is never sliced: the slicer asks the session first
and does nothing without one.
