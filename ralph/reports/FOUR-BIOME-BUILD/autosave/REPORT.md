# Fallback autosave scheduling

Date: 2026-09-07
Branch: `codex/autosave-hitch-0907`
Base: `c359c1c15` (SAVE recovery hardening included)

## Scope and established baseline

STAB's `second-bed-freeze-2026-09-07.md` measured a 536.7 ms post-warmup
frame at the 180-second fallback autosave reset. The bed recursion was already
fixed. This lane changes fallback scheduling and preserves SAVE's durability
repair; it does not rederive prompt 77 section 4.

## Implementation

- `GameState` synchronizes live scene state on the main thread and submits a
  copied request for the 180-second fallback. Rest and realm-entry callers keep
  their synchronous save API.
- `SaveGame` captures both partitions, IDs and display names before dispatch.
  Recursive arrays/dictionaries are independently copied and read-only; requests
  containing Objects, Callables or Signals are refused. Worker code has a
  separate saver and never receives `Game`, a Node, or a live gameplay object.
- One worker writes one complete slot/world/character transaction at a time.
  Requests during a write replace one pending snapshot with the newest one.
  JSON serialization, staged byte write/flush/reopen verification, replacement,
  rollback and recovery cleanup all execute on that worker.
- A shared recursive IO mutex protects the atomic validity cache and holds
  competing saver instances outside the whole split transaction.
- Explicit save, character/world save, load/delete, character restore access and
  Game exit drain accepted worker requests. A newer manual generation is written
  only after prior fallback generations finish. Completion and failures are
  delivered on the main thread.

The pre-existing bounded durability guarantee is unchanged: per-file recovery
and rollback after synchronous split-write refusal. This is not an OS fsync or
cross-file crash-atomicity guarantee. No commits are spread across main-thread
frames. The worker does not make manual/exit durability boundaries nonblocking.

Godot's documented recursive Mutex and thread/container ownership rules support
this arrangement: [Mutex](https://docs.godotengine.org/en/latest/classes/class_mutex.html),
[thread-safe APIs](https://docs.godotengine.org/en/stable/tutorials/performance/thread_safe_apis.html).

## Validation status

Fresh-worktree import started only after ROAD released the exclusive Godot lock:
1,235 assets, exit 0, no ERROR/SCRIPT ERROR/Parse Error lines.

Focused results so far:

- Existing atomic recovery suite: 18 tests, 114 assertions, 0 failed.
- Worker and fallback suite: 13 tests, 72 assertions, 0 failed; clean log.
- Save matrix (11 file selectors including the worker): 157 tests, 926
  assertions, 0 failed; clean error log.
- Expected-red coalescing mutation: retaining the oldest queued request instead
  of replacing it produced `[2, 3]` rather than `[2, 4]` and day 3 on disk rather
  than day 4. One test, 13 assertions, one failed method / three assertion
  messages, exit 1. Restored immediately before the green matrix run.

The first worker run had green assertions but emitted a real PREDELETE script
error: a zero-refcount helper cannot call its own `finish()` method during
destruction. The repair joins its owned Thread directly there and commits any
accepted tail through the separate writer. Normal shutdown drains through
`GameState._exit_tree()` while both objects are alive. The subsequent clean run
and save matrix emitted no script errors. The initial run is not claimed green.

## Production timing

```text
Godot_v4.7-stable_win64_console.exe --headless --path . \
  --log-file autosave-soak-180.log \
  --script res://tests/smoke_build_two_creature_beds.gd -- --soak-seconds=180

two-bed run 1/10 ... 10/10 settled with 4 total deltas
warmup max:       139.6 ms at soak 21.7 s
post-warmup max:  107.6 ms at soak 177.0 s; autosave 180.0 -> 0.0 s
fallback:        1 request, 1 successful completion; trigger-frame max 107.6 ms
TWO CREATURE BED FREEZE SMOKE: PASS; exit 0
```

The same post-warmup boundary drops from STAB's 536.7 ms to 107.6 ms (about 80%
reduction), below the unchanged 250 ms threshold. No ERROR/SCRIPT ERROR/Parse
Error lines appeared. The headless Windows result does not establish ROG Ally
rendered frame rate or remove its separate first-hour shipped-build evidence.

Persistence smoke: **PASS**, exit 0, no ERROR/SCRIPT ERROR/Parse Error lines:
exact pose, opening/starter, Tam gift, TM/key one-shots and controls survived a
real Meadows save/load and world rebuild.

## Reproduction commands

Executable: `C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe`.
All commands run in `C:/Projects/Tetherbound-autosave-hitch`.

```text
godot --headless --path . --import --log-file autosave-import.log
godot --headless --path . --log-file autosave-focused.log --script res://tests/run_tests.gd -- --only=test_atomic_save_file
godot --headless --path . --log-file autosave-worker-clean.log --script res://tests/run_tests.gd -- --only=test_fallback_save_worker,test_autosave_fallback
godot --headless --path . --log-file autosave-save-matrix.log --script res://tests/run_tests.gd -- --only=test_fallback_save_worker,test_autosave_fallback,test_atomic_save_file,test_save_format,test_world_save_format,test_character_save_format,test_split_key_coverage_equals_v22,test_legacy_slot_split_never_touches_the_original,test_meadows_realm_save_repair,test_water_traversal_save,test_stormwood_environment_save
godot --headless --path . --log-file autosave-mutation-coalescing.log --script res://tests/run_tests.gd -- --only=test_fallback_save_worker::test_single_flight
godot --headless --path . --log-file autosave-persistence.log --script res://tests/smoke_save_persistence.gd
godot --headless --path . --log-file autosave-full-suite.log --script res://tests/run_tests.gd
```

The mutation command applies only while the deliberate oldest-request mutation
is present; the committed implementation must pass it. The final snapshot test
additionally exercises actual request refusal (two additional assertions beyond
the earlier focused matrix), not only the recursive type predicate.

## Full-suite comparison and final verdict

**Focused autosave repair: PASS. Repository-wide suite: unchanged known RED.**

```text
2,877 tests, 3,835,113 assertions, 2 failed methods; exit 1
```

Both failed methods and all five assertion messages match the previous clean
SAVE run:

- `test_gate_f_harness_predicates.gd::test_the_route_row_thresholds_leave_headroom_below_the_shortest_run`:
  S04 requires 420 rows against a shortest healthy 363; S05 requires 970 against
  500. Both exceed that test's 85% ceiling.
- `test_gate_f_rig.gd::test_the_runner_declares_its_own_logic_lane_so_a_run_can_start`:
  Windows cannot launch `bash .../run_segment.sh --write-lane-declaration` (return
  -1); consequently no freeze record exists and it is not a JSON object.

Compared the complete raw log with
`C:/Projects/Tetherbound-save-proof/save-full-suite-clean.log`: the distinct
`ERROR:` and `SCRIPT ERROR:` sets are identical after normalizing only worktree
paths. Existing detached-node, invalid fixture arguments and exit-leak diagnostics
remain visible; none is attributed to or hidden by this repair.

The older run counted 2,871 methods. This base already includes three debug
teleport tests and removes six compass/quest-destination tests relative to that
older worktree; this lane adds nine worker tests. Those inherited files are
unchanged from `c359c1c15`. All nine new tests passed in the full run, including
actual rejection of a live object before any thread starts.

Cleanup restored 1,077 tracked `.import` side effects and removed 118 generated,
untracked `.uid` files after validating every target was a file inside this lane's
worktree. Godot regenerates those UIDs on import. No source/texture/asset changes
outside the eight owned code/test/report files remain, and no Godot process is
left running. Root integration and owner-hardware validation remain outside this
lane's completion claim.
