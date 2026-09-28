# P2-021 capture-wrapper code review

Reviewed `tools/phase2_capture_cloudreach_frame_matrix.gd` against its parent, `tools/capture_cloudreach_frame_matrix.gd`, in `D:\tetherbound\x04-cloudreach`. Inspected `tools/capture_cloudreach_lane_common.gd` and the receipt consumer, `tools/phase2_compact_evidence.py`, for context.

## Actionable finding

**P2 — Fail the capture when its JSON receipt cannot be written.** At wrapper lines 38–42, a failed `FileAccess.open(..., WRITE)` is silently ignored and execution reaches `super._finish(written)`. The parent exits successfully whenever at least one PNG was written. An unwritable or locked `manifest.json` therefore leaves the wrapper reporting success without its promised receipt; a previous receipt can remain readable when opening the replacement fails. Check the open and write/flush result, report the error, and exit nonzero instead of taking the parent's success path.

## Other conclusions

- The inherited deferred `_run` dispatch reaches the override, which seeds the global RNG before the parent boots the world. The parent does not reseed it. The recorded seed matches the value passed to `seed`; this alone is not proof of identical pixels or deterministic simulation timing.
- The exact `--motion` flag is rejected before calling the parent, matching the parent's recognized motion switch and preventing its separate motion-frame array from being represented as a still receipt.
- Frame records derive from the parent's successfully saved PNG entries, using the same output directory and filename convention as `LANE.save_frame`. The `frame_id` and `file` fields match the compact evidence consumer.
- Skipped rows are retained as failures, and `complete` becomes false when a selected row is skipped or no frames were written. Completion refers to the requested selection, including `--only`, rather than necessarily the full matrix; the reproduction command must retain that selection.
- The fixture disclosure correctly identifies seeded setup/progression, teleported stands, production camera aiming, pinned time, and hidden HUD. It makes no earned-route or combat claim.
- `git diff --check -- tools/phase2_capture_cloudreach_frame_matrix.gd` passed.

## Limits

Static review only. No Godot process or full world boot was run, no game code was edited, and no screenshots or image acceptance were evaluated. The parent reported that check-only had passed; this review did not independently rerun that check. The receipt I/O failure finding was established from control flow rather than an injected runtime failure.

## Resolution verification

The P2 receipt failure finding is resolved by the narrow correction reviewed in the current wrapper. A null file now reports `FileAccess.get_open_error()`, exits with code 1, and returns. After writing, the wrapper flushes, records `get_error()`, and closes the file; a non-OK result reports the failure, exits with code 1, and returns. Only the successful receipt path reaches `super._finish(written)`.

No actionable findings remain from this bounded review. The wrapper diff check passed again. The parent reported a successful check-only rerun (exit 0); this resolution verification remained static and did not run Godot, inject an I/O failure, or evaluate visual acceptance.
