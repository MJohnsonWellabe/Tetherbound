# Stormwood full run: continuous earned chapter with checkpoint saves

**Command** (game code = main b4201ee9; harness = `tb/stormwood` 249b4b74):

```
godot --headless --path . --script tests/smoke_stormwood_continuous.gd -- \
  --through-aftermath --witness-dir=user://swrun_a --checkpoint-dir=user://swcp_a
godot --headless --path . --script tests/smoke_stormwood_continuous.gd -- \
  --witness-dir=user://swrun_a --verify-reload
```

**Results**
- `run_a.txt`: EXIT 0 with 0 SCRIPT ERROR. The last line is "chapter-entry through the Stormheart kept and Waterward aftermath passed without Stormwood flag or position fixtures".
- `reload_a.txt`: a fresh process presses the title's Load on the witness save. EXIT 0 with 0 SCRIPT ERROR. The same character, party, Stormheart receipt, aftermath, Spark and Dynamo `released` all come back, and nothing is re-offered.

| Step | Result | Wall time | Checkpoint |
|---|---|---|---|
| Prefix: arrival through Ondra's arch recipe | PASS | 1237 s | `checkpoints/1_prefix.tgz` |
| Capacitor Alpha, Crown gathering, two frames, paid Crown arch | PASS | 2078 s | `2_crown_arch.tgz` |
| Crown arrival, guardian, Wen, Rootgate | PASS | 145 s | `3_rootgate.tgz` |
| Deepwood, rods, Kestrel, core ascent | PASS | 1818 s | `4_core.tgz` |
| Marrow's five rounds and the real four-conduit Break | PASS | 343 s | `5_marrow.tgz` |
| Stormheart offer kept at five, Waterward aftermath | PASS | 9.5 s | `6_aftermath.tgz` |

**Checkpoints.** Each `.tgz` is the complete split-save tree (`slot_0.json`, `worlds/`, `characters/`) autosaved right after its step passed, plus `checkpoint.json`.
- Unpack a checkpoint under Godot's `user://` and pass `--from-save=user://<dir>` to `smoke_stormwood_pocket_walks.gd`, or press the title's Load with that directory bound as the save root.
- `6_aftermath` is an earned post-Stormwood save: the Long Storm is ended, the Stormheart is kept and the Waterward is revealed.

**Shortcuts** (disclosed, as in `f09_0/README.md`):
- The start is the Cloudreach-boundary fixture: an in-memory completed-Cloudreach party and entitlement, then the production realm router.
- The party is five fresh creatures at L44.
- The knife, axe and pickaxe are granted.
- The clock runs 8× accelerated (fights and presses at 1×).
- Input and fights are driven by the harness.
- Helper routing covers blockers B1–B8.
- There are no Stormwood flag, position or party writes.
- The pocket-lure presentation config changed on disk while this run was in flight. The run's scene had already loaded main's config, and no movement, flag or fight data changed.
