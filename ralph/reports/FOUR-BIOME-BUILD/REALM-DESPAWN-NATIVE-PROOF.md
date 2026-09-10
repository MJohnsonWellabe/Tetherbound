# Native ENet late-despawn ordering proof

2026-09-09. **The proposed receive-map ordering mechanism is reproduced with actual native ENet replication.** One negative case produces the exact CI error; a control waiting for the actual host despawn before removing the receiving realm produces no native error. This proves the bounded mechanism, not a complete production realm-transition fix or attribution of a particular CI packet.

## Approved scope and fixture

The root approved a tiny two-process negative/control test after the new PR94 native error in [REALM-DESPAWN-CI-FINDING.md](REALM-DESPAWN-CI-FINDING.md). Files are `tools/probe_realm_despawn.gd` and `tools/probe_realm_despawn_peer.gd`. No production files, engine patch, error suppression, full-world run, or CI rerun.

Each process constructs a persistent RPC hub, a realm subtree with an Actors parent, and a MultiplayerSpawner whose spawn path points into that subtree. The host creates one real replicated Node3D. The client receives the actual spawner `spawned` signal. The spawner remains persistent specifically to isolate the received-body map lifecycle; actual game scenes have more teardown and replication behavior than this fixture.

Negative ordering: the client frees its realm subtree and verifies the received body is gone, then sends a reliable acknowledgment. Only after that acknowledgment does the host free its still-live authoritative body. This forces the remote-body receive-map removal to precede the host despawn packet. The client never receives a valid `despawned` signal afterward.

Control ordering: the client requests host despawn while keeping its realm live. It waits for the actual MultiplayerSpawner `despawned` signal, then verifies the body is gone before freeing the realm. A timer is used only to finish transport observation and process shutdown; it does not substitute for the control's actual despawn event or the negative case's acknowledged ordering.

## Execution and observed result

Native engine: `C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe`, version `4.7.stable.official.5b4e0cb0f`.

Each role ran:

```text
Godot_v4.7-stable_win64_console.exe --headless --path C:/Projects/Tetherbound --script tools/probe_realm_despawn.gd -- <host|client> <negative|control> <port>
```

Ports 39671/39672 for negative/control. APPDATA and LOCALAPPDATA were isolated separately for every role under `.artifacts/realm-despawn-native-20260909/`; parent environment was restored afterward. Host started before client. Each script had a 15-second internal deadline and a 30-second process wrapper limit. Both pairs completed sequentially in approximately five seconds total. Exactly one execution of each case; no setup failure or retry.

| Case | Host PID / exit | Client PID / exit | State checks | Raw native errors |
|---|---|---|---|---|
| Negative: local subtree removed first | 17248 / 0 | 15708 / 0 | 3 host + 3 client pass | Exactly one expected error, client only |
| Control: actual host despawn consumed first | 5472 / 0 | 13276 / 0 | 2 host + 4 client pass | None |

Negative client stderr is exactly:

```text
ERROR: Condition "!pinfo.recv_nodes.has(net_id)" is true. Returning: ERR_UNAUTHORIZED
   at: on_despawn_receive (modules/multiplayer/scene_replication_interface.cpp:663)
```

Its SHA256 is `38EBF1FA52D93DDE2168B740EB1AC79F4FDC60C0C224B24BF7A49378A4A8AFB0` (172 bytes). Negative host stderr and both control stderr files are empty. No other ERROR, SCRIPT ERROR, or WARNING appears in the eight inspected raw stdout/stderr files. Exit0 alone is deliberately insufficient for the negative case: the exact expected native rejection is part of the proof and was inspected separately.

Control client stdout records, in order: real body received; actual host despawn signal consumed; remote body gone before teardown; realm removed only after actual host despawn. Its SHA256 is `4DA82FD5F0603743717C54249B4A580B696B7D46954DE9695B09C3C098A65C06`. Negative client stdout hash is `2F307CCECD182E4AAFA47AD5C10BC8148EED9E6B22158F0B5BB4A73DC9667A98`.

## Implication and limits

Keeping the receiver subtree alive until an actual host-driven despawn is consumed prevents this error in the proven fixture. A reliable realm announcement alone does not establish that ordering. Production work must additionally handle the real scene's spawner lifetime, per-peer visibility, cross-channel ordering, arrival readiness, rollback, solo, and disconnect paths. No such production repair or full-realm acceptance is claimed here.

The scripts and this report remain uncommitted for root review. Raw payloads stay in ignored `.artifacts`; no screenshots or owner saves were touched.
