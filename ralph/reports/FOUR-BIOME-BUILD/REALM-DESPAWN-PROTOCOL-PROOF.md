# Native three-peer protocol proof — corrected candidate passes

2026-09-09. **The corrected three-peer candidate passes its bounded departure/admission protocol with zero native errors.** The first authorized candidate failed before quiescence; it is retained below. After root reviewed that failure and authorized exact fixture corrections plus one new candidate, the changed source passed29 checks across three actual ENet peers. No production change or CI rerun.

## Corrected candidate: actual runtime protocol evidence

Root authorized explicit typed-array construction, teardown guards, parse preflight, and a fail-fast wrapper. The only typed Array literal conditional was replaced by explicit `append` calls; live-body lookups now validate the Variant before casting; actual transport loss stops processing, and success/failure stops the physics callback before shutdown. No engine error was hidden or accepted as benign.

Native `--headless --path C:/Projects/Tetherbound --check-only --script tools/probe_realm_despawn_protocol.gd` exited0 with no errors. One changed-source three-process execution used the same engine, port39674, and a new isolated directory `.artifacts/realm-despawn-protocol-20260909-v2/`. Profiles are separate per role; parent APPDATA/LOCALAPPDATA restored. The wrapper polled all role logs every100ms and would terminate the complete candidate set on any ERROR/SCRIPT ERROR, or at the common30s deadline. No stop trigger occurred. Total wrapper duration2.85s; host PID18808, departing PID10508, staying PID13128 all exit0. All six complete stdout/stderr logs were inspected: **zero ERROR, SCRIPT ERROR, or WARNING**; all three stderr files are empty.

**29 passing checks: host9, departing12, staying8.** They establish:

- Both clients actually received all three host-spawned, peer-owned bodies and changing continuous/on-change host state before crossing.
- Each owner applied an outgoing recipient gate and the host collected four matching same-channel reliable sender/receiver fences: H→D, S→D, D→H, D→S.
- The host-owned empty-property admission synchronizers caused actual engine visibility despawns. Departing D received three spawner despawn signals; continuing S received only D's despawn and retained H/S bodies.
- D required the host reliable despawn fence plus actual empty received inventory, then verified the old parent has no remaining bodies before freeing old realm and spawner.
- The destination receiver did not exist during drain, contained no premature body after construction, and received its actual host spawn only after authenticated readiness.
- S continued receiving H motion through departure; H continued receiving S's peer-owned motion. Recipient gating did not stop those continuing viewers globally.

The existing-source hypothesis about the host needing a separate authoritative admission synchronizer is now supported by actual candidate behavior. The engine's synchronous visibility handler calls `_send_raw` for resulting despawns before returning; the host fence follows those calls on reliable channel0. Each owner's fence likewise follows its own outgoing gate. Continuous unreliable packets are not claimed ordered by those reliable fences; no native error occurred in their actual concurrent traffic here.

Corrected-run stdout SHA256: host `F56E256405D821BA16A4059DC02CA2C552BF0E600E62F015252228AABDE297DB`; departing `C9A97D60BFE4AE6BFBF8FB001166511A2CCB34B94E6D82FA9F7CE70A023C0469`; staying `312EB1738BF9D4FD48F4949C928AB59BB5CD75B08D1073F6E6BDB31BE8A8C9A3`.

This remains a tiny local ENet proof. It does not establish real-realm integration, adverse network reordering/loss, host scene replacement, multi-spawner content, stale/forged-token rejection, rollback, or disconnect cleanup. Those are not silently credited by the happy-path29 checks. The protocol fixture presently uses one transition token and one successful admission; negative token/duplicate cases are future coverage.

## Retained first candidate failure

## Fixture and source finding

Files: `tools/probe_realm_despawn_protocol.gd`, `tools/probe_realm_despawn_protocol_peer.gd`. The candidate implements the [approved brief](REALM-DESPAWN-PROTOCOL-BRIEF.md) with host, departing client, and continuing client; three host-spawned bodies each have a peer-owned state synchronizer (continuous position, reliable on-change rotation) plus a host-owned admission synchronizer with an empty property configuration.

The split was explicitly approved after reading the installed Godot revision `5b4e0cb0f`:

- `MultiplayerSynchronizer::update_visibility` emits its visibility signal only for the synchronizer's local authority.
- `SceneReplicationInterface::_update_spawn_visibility` evaluates only synchronizers owned by the spawner authority, and combines those synchronizers' visibility with OR.
- Thus a peer-owned trainer state synchronizer alone does not provide the host a usable per-observer spawn/despawn visibility gate. This is material to the existing `trainer_spawn.gd` comment claiming that one peer-owned filter scopes both host spawn and owner deltas.
- In the candidate the empty-property host synchronizer controls admission, while each state owner controls its outgoing recipients. **The first failed run did not reach a visibility withdrawal; the later corrected candidate above supplies that missing runtime evidence.**

Source URLs: https://raw.githubusercontent.com/godotengine/godot/5b4e0cb0f/modules/multiplayer/multiplayer_synchronizer.cpp and https://raw.githubusercontent.com/godotengine/godot/5b4e0cb0f/modules/multiplayer/scene_replication_interface.cpp.

## One candidate execution

Engine `Godot_v4.7-stable_win64_console.exe`, `--headless --path C:/Projects/Tetherbound --script tools/probe_realm_despawn_protocol.gd -- <host|departing|staying> 39673`.

Separate APPDATA/LOCALAPPDATA profiles and raw stdout/stderr under `.artifacts/realm-despawn-protocol-20260909/`. No full world or rendering. Internal deadline20s; common wrapper deadline30s. PIDs host10612, departing12020, staying14836; all terminated exit1. The parent environment was restored and no candidate processes remain.

Observed before failure: host authored its closed-admission destination body; each client received all three old-realm bodies and observed changing continuous and on-change host state. Passing setup checks: host1, departing4, staying4. This is setup evidence only.

First error on all three roles:

```text
SCRIPT ERROR: Trying to assign an array of type "Array" to a variable of type "Array[int]".
   at: _quiesce_local (res://tools/probe_realm_despawn_protocol_peer.gd:173)
```

The conditional expression returns an untyped Array; assigning it to `Array[int]` is rejected at runtime. This occurs before outgoing gates or sender fences execute. The fixture's explicit failure flag did not catch a native GDScript runtime error, so the processes remained until their20s internal deadlines. The first raw-log inspection observed that error near the deadline; the wrapper had only process deadlines, not fail-fast log monitoring. It therefore did not immediately terminate all roles on the first script error. That shortcoming is retained rather than represented as successful fail-fast behavior.

After the host's deadline exit, both clients additionally reported inactive-multiplayer `get_unique_id` errors and stale typed-body assignments from their physics loops. Their own internal deadlines then ended them. These are fixture error/cleanup defects; they are not evidence against or for the proposed quiescence protocol.

## Unproven and next bounded correction

No recipient-only suspension, same-channel sender barrier, actual visibility-driven drain, destination admission, or continuing-viewer preservation assertion was reached. The exact original unauthorized-despawn class was not exercised by this failed candidate.

Before any separately authorized second run, correct the typed conditional array, validate body Variants before casting, stop frame processing on actual transport loss, and make the wrapper terminate the candidate process set when any unexpected ERROR/SCRIPT ERROR appears. These corrections must not mask logs or allow cleanup errors as an accepted success set. Preserve this first-run directory. No disconnect/rollback scenario or production implementation is authorized by this result.

All candidate source/report files are uncommitted for root review. The earlier simple negative/control proof remains unchanged and valid for its narrower receive-map ordering mechanism.
