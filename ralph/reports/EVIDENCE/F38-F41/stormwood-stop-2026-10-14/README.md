# Stormwood scoped native successors — prepared, not admitted

Source: `868a7b5c8c4d89483a85f2ce0f6c7c7bb2c558ee`.
Exact predecessor: `b9d7edeb7f18d7ca2192f018016d4126f1910f91`.
Required predecessor index SHA-256: `8564bb8b52f74c58803830eb8562798a00af80804039c1be217eea885cf096f4`.

No native stage, index, owner, or lock access was performed to prepare this packet. No engine was launched. The native tests, memory diagnostic, import readiness, screenshots, and visual judgments are UNRUN. The full Stormwood look task is not complete. Look flags remain OFF.

## Four independent pieces

| Folder / job | Scope | Wall limit |
| --- | --- | --- |
| shared / sw868t-r3 | All 8 named methods in test_vegetation_shared_retint.gd | 120 seconds |
| visibility / sw868v-r3 | All 3 named methods in test_foliage_camera_visibility.gd | 120 seconds |
| palette / sw868p-r3 | All 3 named methods in test_stormwood_vegetation_palette.gd | 120 seconds |
| memory / sw868mem-r3 | Medium OFF, Forward+, 1920×1080, unchanged full production density | 180 seconds |

Every job has one step, a distinct fresh output directory and isolated user home, and its own admission. There is no automatic sequence. No captures, density reductions, scene substitutions, creature scaling changes, or floor/cap relaxations are included.

## Root-only use

1. Review `manifest.json`, both independent packet reviews, source review, and the conditional closure below. Confirm this exact predecessor still owns the idle native lease. A different source/index requires a new reviewed successor; do not rebind this packet silently.
2. While all four jobs remain PREPARED/NOT_ADMITTED, root may invoke `swap_stage.ps1 -RootAuthorized`. It performs preservation, source transition and the shared CPU source preflight only. It does not start an engine. The Python entry point independently holds the actual root lock.
3. Root establishes required native imports/DLL readiness under its lease. This packet does not claim those prerequisites are ready.
4. Admit only the chosen piece: change that job's status to ROOT_ADMITTED and launch_allowed to true, compute its new SHA-256, fill that piece's `root-review.template.json` with the exact admitted job hash and truthful review attestations, and save the completed review separately. Change its admission to ROOT_ADMITTED/true, bind the admitted job hash and completed review path/hash. Preserve the preparation manifest and original bytes as provenance when doing this.
5. Invoke that piece's `run_validation.ps1` in a separate root decision. Inspect its strict receipt and cleanup before considering any further piece. Running one piece authorizes no successor.

The root-review template is not an approval. All attestations start false. Memory additionally requires external_memory_sampling_reviewed. The executable requires source, request, profile, binding and code hashes; exact named methods or ordered memory boundaries; natural exit; zero stderr/warnings/errors; no remaining process; terminal resource availability; and bounded elapsed time/log drains.

Unchanged guards: C admission 10.5 GiB / stop 10 GiB; D admission 21 GiB / stop 20 GiB; physical free and commit headroom each at least 2 GiB; combined logs 20 MiB; output plus isolated homes 50 MiB; packet 16 MiB. Each focused step also caps its output/home growth at 10 MiB. Exact PID, parent, command line, creation time and lease identity govern child ownership and cleanup.

## Source closure and preservation

The transport is an exact 72-object delta (505,556 bytes), conditional on the reviewed b9 base closure. `cpu-pack-membership.json` proves the pack/index object set equals the independently reconstructed target-minus-base set; extra objects in the local proof store cannot hide a missing transported object. It does not freshly prove native object availability.

Target: 49,369 full index entries, at least 12,888 materialized files, 794 raw source bindings. Transition: 89 changed paths, 803 planned writes. Before and after audits use the unchanged reviewed full-index/raw-blob batch oracle with its 40-second internal / 45-second outer budget. No broad status or per-file Git source scan is used.

The transition retains the predecessor's resource-budgeted preservation, verified raw backups, path/reparse checks, repeated source/lease snapshots, and protected final owner compare-and-swap. Failed transitions preserve backups and intermediate state for review. No automatic rollback or stale lease overwrite is provided. Git I/O now covers blocked Windows stdin with a caller-owned monotonic 45-second deadline and up to 5 seconds of cleanup. This changes only the subprocess wrapper; preservation/budget/CAS functions remain unchanged.

The proof store alternates to `D:/tetherbound/.artifacts/codex-look-meadows/medium-off-b9d7edeb7f-from-5650c507e6-r4/offline-native.git/objects`, whose reviewed closure and contract hashes are in `cpu-source-closure.json`. Root's actual full stage audits remain mandatory.

## Memory evidence interpretation

`memory-samples.jsonl` records a prelaunch baseline and external observations of the owned process's private bytes, working set, physical free memory and commit headroom. Failed resource samples are written before the floor check throws. Samples are observations, not continuous peaks; allocations between samples can be missed. Terminal values can be post-exit/post-kill and must not be reported as process peaks.

Stdout `STORMWOOD_LOAD_MEMORY` rows bind source/PID/sequence, monotonic ticks, counters, unique ordered boundaries, and completion after quit_scheduled. Node-entry boundaries occur during mounting and can follow constructor/loading work. Probe logging, allocations and system calls perturb timing. Neither named boundaries nor counters prove allocation ownership or causation. The inherited mount timeout is 900 seconds; the external 180-second limit is mandatory. No image or visual acceptance is produced by this diagnostic.

The original failed Medium OFF capture `D:/tetherbound/.artifacts/s/run-sw287m0-r1` remains preserved; it is not retried by this packet. Preparation attempts r1 and r2 retain their failure JSONs. r3 also preserves the LF-alternates correction. These failures are not native evidence.

## CPU verification

- Source oracle: 15 fixture cases; bounded source helper: 6 cases. The helper is byte-identical across all four jobs and to the reviewed predecessor.
- Actual successor functions: 8 positive / 56 negative cases, including stale counts, early/duplicate completion, entry ordering, counter/PID/source errors, terminal telemetry and floors.
- Launch gates: 32 cases, including real unadmitted invocations and paired job/admission tampering. The admitted baseline is evaluated only through the gate prefix, cut before engine/stage access.
- Supervisor deadline/drain guards: 24 positive / 64 negative cases across four supervisors.
- Transition preservation/locking guards: 14 positive / 59 negative cases, confined to fixture files.
- Git I/O: 6 cases, including blocked large stdin and completed-event observation after the deadline.
- Pack membership: exact 72-object set plus pack/index checksums.

These CPU checks and independent reviews establish packet readiness for root review only. They do not substitute for the 14 native methods, diagnostic completion, or later matched captures and visual judges.
