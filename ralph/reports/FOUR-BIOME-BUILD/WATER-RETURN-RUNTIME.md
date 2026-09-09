# Water return runtime evidence

Date: 2026-09-08
Branch: `codex/four-biome-audit-resume-0908`
Production connection commit: `d769a93c5`
Generated scatter repair commit: `f227816f8`

## Evidence boundary

This is focused fixture evidence for the ordinary Water-to-Stormwood return
connection. It is not earned campaign evidence and does not close the Water
campaign or four-biome audit.

No earned save carrying the durable Water gate unlock was available in the
retained artifacts. The fixture therefore submits exactly these two
prerequisites through the production host-ledger authority before it mounts the
real Water scene:

- `realm_key_stormwood = true`, so the existing destination realm remains
  authorized by its established key rule.
- `realm_gate_water_unlocked = true`, the durable shared unlock earned by the
  forward Water gate.

The fixture does not add `realm_key_water`, inventory, HP, party members,
chapter completion, or any other campaign progress. The saved fixture profile
is retained under
`.artifacts/water-return-runtime-profile-02/Godot/app_userdata/Tetherbound/`.

## Probe contract

`tests/smoke_water_return_runtime.gd` instantiates the production
`water_archipelago.tscn` and waits within the shipping 120-second realm-ready
budget. It then:

1. checks the mounted `StormwoodReturnRealmGate`, its empty `key_flag`, durable
   WORLD unlock state, and its existing
   `stormwood_departure_to_water` destination;
2. walks the real player from First Shore to the physical gate through parsed
   stick input;
3. requires the gate's real Interactable to be the live InteractionArbiter
   winner and sends a parsed `interact` action (it never calls `try_enter`);
4. observes the command-associated `current_realm` and
   `pending_realm_entry` request separately from destination completion;
5. waits for a different, fully built production Stormwood scene and cleared
   pending entry;
6. verifies the resolved authored return position, grounded player state, and a
   physics ray hit on the real `StormheartTree/DynamoCore` collision;
7. compares route facts and complete WORLD/player flag fingerprints before and
   after travel.

The probe also captures the reached gate from Water's normal gameplay camera.
It records the current look, applies `day` and `night` through the production
`WorldLook.apply_time` authority, captures each distinct frame, and restores the
prior preset before interaction.

## Invalid first invocation

Run 01 used `--headless`, which selected Godot's dummy renderer. The first
failure was therefore the required live viewport capture:

```text
ERROR: Parameter "t" is null.
WATER RETURN RUNTIME FAIL: live Water gate viewport capture returned no image
```

Artifacts are preserved at `.artifacts/water-return-runtime-run-01/`; the full
Godot log is
`.artifacts/water-return-runtime-profile-01/Godot/app_userdata/Tetherbound/logs/godot.log`.
That probe revision also failed to return immediately after the capture error,
so its later transition observations are explicitly invalid and receive no
runtime credit.

The same invalid run exposed one related integration prerequisite before the
changed invocation: `stormwood_scatter.gd` hashes the whole
`stormwood_world.json`, so adding the approved `arrival_height_policy` field
made the existing generated manifest stale. The existing baker was run once:

```text
Godot --headless --path . --script res://scripts/world/bake_stormwood_scatter.gd
STORMWOOD SCATTER { "regions": 108, "bytes": 1244185, "kept": 33773, "drained": 0 }
```

A SHA-256 comparison of every generated file before and after the bake showed
all 108 placement binaries byte-identical. Only the generated manifest source
fingerprint changed, from `2915883326895985` to `2886891493113183`; placement
count, drained count, and payload bytes remained unchanged. The generated-only
repair is commit `f227816f8`.

The probe was then changed to stop immediately on any capture failure, and the
single authorized verification used the actual OpenGL renderer with no
`--headless` flag.

## Successful run 02

Invocation shape:

```text
Godot --path . --rendering-driver opengl3 --resolution 1280x720 \
  --script res://tests/smoke_water_return_runtime.gd -- \
  --capture=res://.artifacts/water-return-runtime-run-02/gate-normal-view.png
```

The process used an isolated APPDATA profile, a hidden native window, and an
active watcher that stopped above 90 percent system commit or 400 processes.
It exited 0 without reaching either threshold. The renderer receipt was OpenGL
3.3 Compatibility on an NVIDIA GeForce RTX 3050 6GB Laptop GPU.

The terminal result was:

```text
WATER RETURN FINGERPRINTS: world_before=3731753825 world_after=3731753825 player_before=4226899299 player_after=4226899299 world_id=slot-0 character_id=slot-0
WATER RETURN RUNTIME OK: ordinary gate input -> completed Stormwood deck arrival; fixture prerequisites only
```

The successful run proves, within the fixture boundary:

- the production Water scene mounted the real return gate and its Interactable;
- ordinary stick input reached it and ordinary Interact activated the exact
  arbiter winner once;
- the router request named `stormwood` and the existing
  `stormwood_departure_to_water` entry;
- asynchronous travel completed in a fully built Stormwood scene;
- the player retained the authored X/Z and elevated authored Y, was on floor,
  and stood on actual Stormheart DynamoCore collision;
- `realm_key_stormwood`, absent `realm_key_water`, and
  `realm_gate_water_unlocked` were unchanged;
- the shared unlock remained in WORLD authority and was absent from player
  authority; and
- complete WORLD and player flag fingerprints were unchanged by return travel.

Godot loaded 108 current Stormwood scatter regions with 33,773 placements in
this successful destination build. Distinct scans of the Godot log and stderr
found no `ERROR`, `SCRIPT ERROR`, or Water return failure lines. Expected
texture mipmap and interpolation deprecation warnings remain warnings.

Resource watch: 26 samples, peak private bytes `3352391680`, peak working set
bytes `1218510848`, peak system commit `65.49%`, and peak process count `253`.

Artifacts:

- `.artifacts/water-return-runtime-run-02/stdout.log`
- `.artifacts/water-return-runtime-run-02/stderr.log`
- `.artifacts/water-return-runtime-run-02/memory-watch.csv`
- `.artifacts/water-return-runtime-profile-02/Godot/app_userdata/Tetherbound/logs/godot.log`
- `.artifacts/water-return-runtime-run-02/gate-normal-view.png` — 1280x720,
  SHA-256 `3D8F63473CCE5D747B62EC59BA5671794E29E2ED09915831FACD9D8FEAF0DD75`
- `.artifacts/water-return-runtime-run-02/gate-day-view.png` — 1280x720,
  SHA-256 `0AEE6289055DF59C10A94B0778EA8D8C3D7BC5B930824413B9A01F6A94FEE2D0`
- `.artifacts/water-return-runtime-run-02/gate-night-view.png` — 1280x720,
  SHA-256 `A91050F482E955344823612B6770151F6F491A6EB327C30468215E1A9D071671`

The images are capture artifacts for a separate fresh visual judgment; this
report does not treat their existence as visual acceptance.

## Workflow and remaining boundary

The required `tests/smoke_playground.gd` run initially failed only its late chop
durability observation while its synchronous production impact was within the
unchanged timing band. A separately owned correction moved that observation to
the native durable callback, and root reported the required corrected
`smoke_playground` recheck exiting 0 before run 02 was launched.

No two-peer world was launched. Run 02's measured 3.35 GB peak private memory
made a two-full-client estimate material, and root reserved the next full-world
lease for another lane. Peer route behavior therefore remains pending a later
headless, guarded fixture run and is not claimed here. There were no production
changes in this runtime-evidence step beyond the mechanically regenerated
scatter manifest already committed separately.
