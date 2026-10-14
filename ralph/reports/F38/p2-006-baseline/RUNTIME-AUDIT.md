# Meadows packet runtime-contract audit

CPU-only audit of the P2-005 and P2-006 supervisors and the P2-005 rebind helper. No capture, engine launch, import, or C: checkout access occurred.

## Contracts checked

- Output ownership is consistent: each supervisor builds one fresh `$OutputDir`, passes that same path to the fixture, checks the manifest and frame files beneath it, and claims that same path in the native owner lease and receipt.
- Both supervisors previously leaked `System.Threading.Tasks.VoidTaskResult` from the stdout/stderr `CopyToAsync(...).GetAwaiter().GetResult()` calls. They now assign both results to `$null`. A MemoryStream fixture confirmed the old expression emitted one `VoidTaskResult`; the corrected pattern emitted zero pipeline objects and copied the bytes.
- PowerShell's `catch { ...; throw }` pattern returned exit code 1 in a child PowerShell probe after a nested cleanup failure. The supervisors record `primary_exception` separately from `cleanup_failure` and `lease_cleanup_failure` before rethrowing.
- A CRLF JSON receipt fixture parsed with `ConvertFrom-Json`; the supervisors use `Get-Content -Raw`, not LF-only summary-line parsing.
- The P2-005 rebind helper checks exact HEAD, clean worktree, every `HEAD:<path>` blob, and every filtered worktree `git hash-object --path` against the canonical blob before computing raw-byte hashes. It writes only a separate rebound packet and retains an input snapshot.
- Neither supervisor nor the rebind helper uses `[IO.File]::Replace`. A D: scratch probe reproduced the null-backup `File.Replace` exception and confirmed same-directory `File.Move(temp, target, $true)` replacement. No change to these runners was needed for that API issue.

## Evidence and status limits

Both packets remain `PREPARED_ONLY_NOT_EXECUTED`, and both root admission files remain false. P2-005 still needs its authorized four-condition native capture and matched blind review. P2-006 still needs its exact four-site High/Medium baseline, a later matched candidate matrix, and independent blind review. The retained broad-survey reviews are context-only and do not satisfy those exact sightings. No READY, PASS, score, impact, or catalog-status claim follows from this audit.

The native queue remains the dependency for any capture: root owns the writer while D5 runs, and the packet launchers require their own exact source commits and a positive root admission after the writer is released.
