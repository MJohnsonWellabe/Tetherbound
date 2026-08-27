# Gate F rig self-check evidence — 2026-08-27

Produced by the `ralph/GATE-F-RIG` lane against `main`, with
`tools/gate_f/run_segment.sh`. **These are self-check segments, not protocol
segments.** No Gate F journey or study segment was re-run by this lane —
operator/developer separation (§13) still applies, and the candidate must be
re-frozen before the next authoritative run (§1.5).

They are here because a rig fix that is only described is a rig fix nobody can
check, and because two of the three exist to demonstrate a defect closing.

## `selfcheck_capture/` — GF-B-003 (CD-1 + CD-2)

Run **twice**, both ways, from the same step-script:

```
$ tools/gate_f/run_segment.sh --capture selfcheck_capture
run_segment: capture smoke at 1920x1080...
capture smoke: display_server=X11 adapter=llvmpipe (LLVM 20.1.2, 256 bits) viewport=(1920.0, 1080.0)
capture smoke: OK — wrote 1920x1080 to .../capture_smoke.png
run_segment: capture mode at 1920x1080 -> .../selfcheck_capture
run_segment: INVENTORY.json says selfcheck_capture is COMPLETE.

$ tools/gate_f/run_segment.sh selfcheck_capture          # logic mode
run_segment: selfcheck_capture declares planned captures and this is LOGIC mode.
run_segment: logic mode has no display server, so every one of those captures would
             be written as file:null while the steps reported PASS. That is coverage
             defect CD-1 and it is how a whole Gate F run produced no screenshots.
run_segment: use --capture, or --allow-no-capture to run it for its logic knowing
             the segment CANNOT be marked complete.
exit=2
```

`shots/SC-C-title.png` is 1920×1080 and shows the real title screen with Start
New Game focused. `INVENTORY.json` reports `"complete": true` with 4 planned, 4
present, each row carrying the byte count read **off disk**.

Before this lane the second invocation was the one every segment of the
2026-08-27 run actually used, and it reported PASS for every capture step.

`shots/` is committable here at all only because `.gitignore`'s `shots/`
pattern was unanchored and matched at every depth, swallowing every Gate F
segment's own captures since the harness was written. That — not a broken
capture path — is what CD-2 actually was: the 2026-08-27 run's X07 took **79
real 1920×1080 PNGs** and git carried none of them, while `git add <dir>` exited
0 and said nothing. See the lane log's Finding 2.

### What the pre-flight measured

```json
"preflight": {
  "display_server": "X11", "verdict": "PASS",
  "smoke_bytes": 10616,
  "self_test": { "ok": true, "file": "shots/_preflight.png", "size": [1920, 1080] },
  "measured_frame_cost_s":          0.006235,   // before step 1, empty tree
  "measured_frame_cost_s_in_scene": 0.034020,   // after boot: title screen
  "boot_cost_s": 0.76,
  "predicted_segment_cost_s":          0.7,
  "predicted_segment_cost_s_in_scene": 4.6
}
```

Those two frame costs are why CD-7's fix has to measure **twice**. A 5.5×
error on the *title screen*; on the Meadows under xvfb the gap is far wider,
and a prediction built on the empty-tree number would clear a ceiling the real
segment cannot. See the lane log's Finding 4.

## `selfcheck_reach/` — CD-5, and the dialogue predicate end to end

The regression `COVERAGE_DEFECTS.md` asks for by name: *"walk to Grandpa, to a
harvest node and to a wild creature, asserting the prompt each time."*

`SC-R-03` and `SC-R-04` are **EXPECTED FAILs** — negative controls for
`_find_entity` and for `interact_with`'s provider check. `SC-R-15` carries
`expect_change: false`, written down in advance, because the player boots with
nothing equipped and `harvest_node.gd` refuses a bare-handed press.

Everything else runs on foot, and `SC-R-12` is CD-3:

> `advanced 5 line(s) over 5 press(es) of interact; DialoguePanel closed,
> context 'narrative_modal' -> 'world'`

Five lines, five presses, no guess — and the loop stopped the instant
`is_open()` went false, so nothing pressed past the close into the interaction
arbiter that would have re-opened the conversation.

The segment carries a DIAG teleport out of Grandpa's house and says why in its
own `_comment_why_diag`. Its first two runs found where the chapter actually
starts, and that the walker cannot leave a building: lane log Findings 5 and 5b.

## `selfcheck_context/` — GF-B-002's first primitive

Opens the pause shell through the production path, then asks a step declaring
`require_context: "world"` to press a world control at it:

```
SC-X-05  FAIL  BLOCKER step SC-X-05 (press) requires context "world" and input
               is owned by 'menu_backpack' (owner=GameMenu, focus=,
               tree_paused=true). The step did NOT run.
SC-X-06  SKIP  SKIPPED: the segment derailed at step SC-X-05 …
SC-X-07  SKIP  SKIPPED: the segment derailed at step SC-X-05 …
SC-X-08  PASS  resync at SC-X-08: the segment is back on rails
SC-X-09  PASS  menu_cancel closed the shell: context menu_backpack -> world
SC-X-11  PASS  input_context is 'world'
```

`INVENTORY.json` carries the derail with its skip count and resync point, so a
segment that lost the thread and found it again cannot close looking clean:

```json
"derails": [ { "at": "SC-X-05", "action": "press", "context": "menu_backpack",
               "why": "required context \"world\", input_context was 'menu_backpack'",
               "skipped": 2, "resynced_at": "SC-X-08" } ]
```

`SC-X-10` (§E.4's mouse-capture restoration check) is a **SKIP** in logic mode
and a real verdict under `--capture`. Its first run reported
`mouse_mode=visible (wanted captured)` as a FAIL — against a build that
restores the mouse fine, from a process that has no mouse to capture. An
assertion that cannot be *evaluated* is not a verdict on the game, and that
distinction is now in the harness. It is the same class as three of the four
loudest findings in the run this lane exists because of.

## Reading these

Every segment directory holds what §M asks for: `RUN_METADATA.json`,
`INVENTORY.json`, `telemetry/events.jsonl`, `telemetry/route.csv`,
`notes/<segment>.md`, `shots/manifest.json` and `frames/manifest.json`.
`INCOMPLETE.md` is present exactly when `INVENTORY.json` says `complete` is
false. As run here:

| segment | complete | pass | fail | refused | skipped | captures | `git_check` |
|---|---|---|---|---|---|---|---|
| `selfcheck_capture` | **true** | 6 | 0 | 0 | 0 | 4 / 4 | clean: git will carry all 4 |
| `selfcheck_reach`   | **true** | 14 | 2 | 0 | 0 | — | not run (no captures) |
| `selfcheck_context` | false | 8 | 1 | 1 | 3 | — | not run (no captures) |

`git_check` is the last question the inventory asks, and it is CD-2's actual
mechanism: *will git carry what was written?* Proven both ways by temporarily
restoring the bare `shots/` pattern and re-running `selfcheck_capture` inside
the repository — with it, all four captures are flagged
`ignored by .gitignore:45:shots/` and the segment is INCOMPLETE; without it,
`clean: git will carry all 4 capture(s)`.

`selfcheck_reach` is **complete with two failures**, and that pair of facts is
the distinction this lane is built on: a FAIL is a verdict on the **game** and
is the evidence Gate F collects, while `complete` is about whether the segment
executed and produced its artefacts. Its two failures are its negative
controls, and both are expected.

`selfcheck_context` is incomplete *by design* — it derails on purpose, and a
segment that skipped three steps did not fully execute whatever the reason.
Anything less would let a real derail close looking clean.
