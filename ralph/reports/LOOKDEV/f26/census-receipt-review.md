# F26 census receipt recovery review

Verdict: **PASS, scoped implementation and CPU failure propagation only**.
Independent read-only reviewer `/root/f26_lookbar_review`, 2026-10-04.

The earlier interrupted native census retained 24 PNGs but truncated its
manifest. The new writer serializes and stages a snapshot, verifies closed
staging bytes in bounded chunks, then retains the prior generation before
promotion. Ordinary promotion failure restores the previous canonical receipt.
An interrupted promotion may require manual recovery from `.previous`; pending
bytes remain unpublished. This is a recoverable single-writer transaction,
without an atomic replacement or power-loss guarantee.

Pinned [Godot Windows file implementation](https://raw.githubusercontent.com/godotengine/godot/5b4e0cb0f/drivers/windows/file_access_windows.cpp)
does not propagate `fflush` into the cached FileAccess error. The closed-file
byte comparison addresses that ordinary validation gap.
[Windows directory implementation](https://raw.githubusercontent.com/godotengine/godot/5b4e0cb0f/drivers/windows/dir_access_windows.cpp)
removes an existing rename destination before moving; keeping `.previous`
preserves recoverable receipt bytes.

Review also caught inherited finalization overwriting a publication failure
with exit 0. The census now retains failure state and computes the final result
after publication, so an earlier or final failure cannot print success or exit 0.

[CPU receipt](census-receipt-preflight.json), raw artifacts:
`D:/tetherbound/.artifacts/f26-census-receipts-20261004T184122Z/`.

- Six real filesystem tests / 40 assertions / zero failures or native errors.
  Covers repeated replacement, partial staging, staging-open failure, backup
  failure, promotion failure, and real Windows locked-file rollback after a
  successful backup. POSIX handles have a separate expected-success branch.
- Actual census-subclass final success: exit 0, zero errors, `complete:true`.
- Actual forced final staging-open failure: exit 1, `FAILED`, two exact expected
  publication errors, prior `complete:false` baseline preserved. These errors
  are deliberately produced by the failure fixture; no native capture PASS.

Reviewer inspected the current source, probe, receipt, logs and manifests and
confirmed their recorded hashes match. Initial numeric test fixtures failed
because nested JSON numbers parse as floats; fixtures now use string frame IDs.
That failed test attempt remains locally retained, separate from this PASS.

No production-world, renderer, owner launcher or immutable Ally package change.
This does not recover the old empty manifest or certify F26 materials/visuals,
native frame times, floor contact or owner Ally performance.
