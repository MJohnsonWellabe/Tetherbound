# Cloudreach finishing-memory discriminator

Prepared source change only; native execution and capture admission remain outstanding.

The independently verified R3 comparison supports a retained-cache discriminator: within the bulk run, the scalar getter increases engine static allocation by 6,481,604 bytes; within the setters run, the same transition adds 1,044 bytes. Both have a 6,480,744-byte GPU-buffer delta from baseline. These observations are consistent with the reviewed engine mechanism. The separate-run callers-released difference is not a forecast of world savings. Process medians also move differently from engine static counters, so neither metric substitutes for the supervisor's physical/commit floors.

The failed full-world run completed base generation, then stopped after the moorings marker inside synchronous cover finishing. Its exact failing subphase and live finishing counts were not observed. The justified next discriminator is therefore attribution on the existing path, not another aggregate-array benchmark or a density reduction.

`scripts/world/cloudreach_look.gd` now emits `CLOUDREACH_COVER_MEMORY` JSON records under the existing `--profile-realm-load` opt-in. It records engine static allocation, cumulative engine peak, elapsed/absolute monotonic milliseconds, sequence, existing instance counters and phase-specific scalar sizes. It neither reads MultiMesh buffers/transforms nor queries GPU counters, and does not retain snapshots or scene arrays.

Boundaries identify: look start, rails completed, cover start, ellipse uploads completed, fill collection start/end, eligible cells ready, packed buffers ready, each of the four uploads after caller release, return from fill, alpine generation/uploads, and cover return. Periodic progress is checked sparsely inside ellipse, triangle, fill and alpine loops; it is capped at 64 records with at least 10 seconds between periodic records. Boundary records have a separate finite call set (at most 23 per normal dress invocation, including six alpine buckets), so progress cannot suppress the final markers. There is no added await, GPU synchronization, manual collection or array release.

`packed_payload_bytes` is the sum of the four live fill arrays' logical lengths times four. It excludes capacity, dictionary/array headers, renderer copies and allocator overhead. `-1` means not supplied for that phase. `progress` and `total` are: ellipse/alpine generation patch index and patch count; collection-progress accepted triangles and turf surfaces encountered; collection-done triangle count; eligible/fill generation cell count and total input triangles or cells; alpine buckets instance count and bucket count; alpine uploaded bucket instance count and total alpine instances. Existing main/far/fill/alpine counters are always emitted. These are synchronous snapshots with small serialization overhead, not settled rendering measurements or exact peak attribution.

Interpretation on a future admitted run:

- Growth before `ellipse_done` isolates the main/far generation and individual uploads.
- Growth between collection markers isolates mesh array extraction and triangle records.
- Growth through `fill_buffers_ready` identifies eligible geometry plus packed transform staging; release markers distinguish caller payload from memory still retained after upload.
- Growth after `alpine_begin` isolates alpine buckets and individual setter uploads.
- A terminal marker never proves the phase was the sole cause of a later stop. Correlate timestamps with supervisor private/working-set/physical/commit samples. Missing terminal markers narrow the active phase only.

Validation: GDScript parser PASS, `git diff --check` PASS, and exact insertion reversal restores the entire original source text. All existing placement/RNG, exclusion/geometry, allocation/upload/clear order, density/caps, camera and resource-floor settings are unchanged. No full suite or engine run was performed. `insertions.json`, original source and `source-checks.json` support independent review.

The frozen 645 base-storage production-equivalence packet remains the next native correctness gate (placement, roles, sliced and GPU buffer checks); R3 does not substitute for it. Root may incorporate this telemetry in a subsequently reviewed exact capture source after those checks and resource admission. This change does not authorize a full-world retry, alter a frozen packet, or claim recovered headroom. R1/R2 failures and the verified R3 evidence are preserved.
