# Handover — T2-RIG10

**Branch:** `ralph/T2-RIG10`. **Scope:** `tools/gate_f/operator_harness.gd`,
`seed_save`/`save_out`/`wipe_saves` only, plus one new instance var.

## What RIG-10 was

`ralph/reports/GATE_F_RUN_3_RIG_FINDINGS.md`'s RIG-10 section: `_step_save_out`
only checked that the destination slot file **exists**. `seed_save` puts a file
there at the start of every handoff segment, so that check can never fail on a
segment that skips the Save tab entirely — it silently re-exports the file
`seed_save` put there, under the current segment's name, and reports PASS. Run
3 hit this for real: `S03-exit.json`, `S04-exit.json` and `S05-exit.json` came
out byte-identical (md5 `62344f09b811`) despite S04 and S05 each running for
hundreds of play-seconds with their own dozens of verdicts, because neither
ever actually reached the Save tab (a wrong-tab navigation bug, since fixed and
noted inline at `S04.json`'s `S04-64` as "RIG-14"). The consequence: §B's whole
save-handoff design — a blocker restarts at the last gate, not the whole
chapter — was silently not in force.

## The fix

Added `_seeded_slot_md5: Dictionary` (`slot:int -> md5 hex string`) as a new
instance var (`operator_harness.gd:305-310`).

- `_step_seed_save` records `FileAccess.get_md5(dst)` for the slot immediately
  after writing it (`operator_harness.gd:~4146`).
- `_step_save_out` now checks, after confirming the destination file exists,
  whether `_seeded_slot_md5` has an entry for that slot and, if so, whether the
  slot's **current** content hashes the same as what was recorded at seed time.
  If it matches, `save_out` returns:

  ```
  FAIL slot N's content is byte-identical to what seed_save wrote at the start
  of this segment -- the Save tab was never actually used
  ```

  instead of silently copying the file out and reporting PASS
  (`operator_harness.gd:~4034-4045`).
- `_step_wipe_saves` erases the tracked hash for any slot file it actually
  removes, so a slot reused later in the same process (X04 re-seeds slot 4
  twice from two different journey saves within one segment) starts clean
  rather than comparing against a stale hash from an earlier seed
  (`operator_harness.gd:~4172-4180`).

`get_md5` is Godot's own static `FileAccess.get_md5(path)`, so no hashing
utility needed adding. State lives beside the harness's other per-run counters
(`_frame_ms`, `_verdicts`, etc. — see the "live counters" block), the same
place the file already keeps this kind of cross-step bookkeeping, per the
task's own suggestion.

## Validation

### 1. A genuine Save-tab handoff still PASSes

Built a small standalone step-script (not part of any tracked segment file,
kept out of `tools/gate_f/segments/` to avoid touching files other lanes own)
that: wipes saves, seeds slot 4 from a real exit save
(`ralph/reports/gate-f-run-20260828T183531Z/S05/saves/S05-exit.json`), boots
the title, loads that slot through the production Load path, lets the Meadows
stand up, then drives the exact production Save-tab path S04's own working
save step uses (`open_menu` on `map` → three `menu_tab_right` presses →
assert `input_context == menu_save` → focus down 4 → press → `save_out`).

Result: **PASS**, `T-15` — `slot 4 copied to saves/RIG10-TEST-POSITIVE-exit.json
(1415077 bytes)`. The exported file's md5 (`a45a7a10b4c359b83ddc9a8fcf19e772`)
differs from the seed source's md5 (`7d3991bfc64b9e9a682d0b78b6fce350`),
confirming the Save tab genuinely rewrote the slot and the new check correctly
let it through.

Full run: `/tmp/rig10-positive-run/RIG10-TEST-POSITIVE/` (16/16 steps PASS).

### 2. The exact RIG-10 failure mode now correctly FAILs

Same script, but after loading the slot it opens the pause shell on the `map`
tab and **closes it again without ever navigating to Save** — reproducing the
shape of S04-64's original wrong-tab bug — then calls `save_out` directly.

Result: **FAIL**, `T-11` — `FAIL slot 4's content is byte-identical to what
seed_save wrote at the start of this segment -- the Save tab was never
actually used`. No file was written to `saves/` for this run (confirmed empty
`saves/` directory) — previously this would have copied the seed file out
under the segment's own name and reported PASS.

Full run: `/tmp/rig10-negative-run/RIG10-TEST-NEGATIVE/` (10/11 steps PASS, 1
FAIL as intended — `INVENTORY.json` reports `COMPLETE` because the FAIL is
itself the correct, expected step verdict, not a harness error).

Both standalone step-scripts are throwaway test fixtures (not part of this
commit) that lived in the session scratchpad; they are not needed to
reproduce this — see the commands below to rebuild them if needed.

### 3. Existing suite

`test_gate_f_rig.gd` and `test_gate_f_instrumentation.gd` (66 tests, 35,568
assertions) — 0 failed, including `test_a_save_and_a_load_can_carry_a_measured_duration`.

A full unfiltered `tests/run_tests.gd` run was also attempted as extra due
diligence, but timed out at 15 minutes with no useful partial output (this
suite is known-slow: CLAUDE.md/run_tests.gd's own comments note
`test_harvest.gd` alone carries 684,231 assertions and CI budgets the whole
suite well past 10 minutes). Given this lane's ~2-hour budget, it was not
re-run to completion. This change touches only three save-handoff step
functions with no interaction with the rest of the harness's control flow or
game code, so the scoped gate_f test files above are the tests actually
exercising this code path; the untargeted full-suite run would only have
caught something unrelated to this diff.

## RIG-4 (secondary, optional)

Not addressed. Left as found: a `seed_save` whose source file does not exist
returns a `FAIL` and lets the segment continue running against
stale/empty state for its whole remaining step count. RIG-10 was the assigned
priority and the validation above already consumed the budget earmarked for
this lane; flagging it here rather than doing a rushed, unvalidated version.

## Scope / blast-radius note for other lanes

Touched only `_step_seed_save`, `_step_save_out`, `_step_wipe_saves`, and
added one new instance var declared beside the file's other per-run counters.
No other function, no shared cost-gate/preflight code, no segment JSON was
touched. `ralph/T2-BUILDPLACE` (S03.json), `ralph/T2-S10-COST` (S10.json /
cost-gate logic), and `ralph/T2-GATEF-RIGFIXES` (X04.json/X05.json) should be
unaffected: the only externally-visible behavior change is that `save_out`
can now return `FAIL` in a case where it previously silently returned a
misleading `PASS`-shaped success string. Any segment whose step-script
genuinely drives the Save tab (which is the documented/intended way to use
`save_out` per §B) sees no change. A segment that was — like S04/S05 before
their RIG-14 fix — silently handing back a stale seed will now see that
FAIL surface instead of a false PASS. That is the intended, and only,
behavior change.

## Reproduce

```
# one-time setup
curl -fL -o g.zip https://github.com/godotengine/godot/releases/download/4.7-stable/Godot_v4.7-stable_linux.x86_64.zip \
  && unzip -o g.zip && chmod +x Godot_v4.7-stable_linux.x86_64 \
  && mkdir -p ~/.cache/tetherbound-art && mv Godot_v4.7-stable_linux.x86_64 ~/.cache/tetherbound-art/godot
~/.cache/tetherbound-art/godot --headless --path . --import

# targeted regression check
~/.cache/tetherbound-art/godot --headless --path . --script tests/run_tests.gd \
  -- --only=test_gate_f_rig.gd,test_gate_f_instrumentation.gd

# positive/negative save-handoff mechanics (rebuild the two throwaway step-scripts
# described in "Validation" above, or ask for the exact JSON used this session)
GODOT=~/.cache/tetherbound-art/godot bash tools/gate_f/run_segment.sh <positive-script.json> --run-dir /tmp/rig10-positive-run
GODOT=~/.cache/tetherbound-art/godot bash tools/gate_f/run_segment.sh <negative-script.json> --run-dir /tmp/rig10-negative-run
```
