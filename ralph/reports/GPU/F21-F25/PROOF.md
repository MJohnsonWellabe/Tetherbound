# F21#5 / F25#4 four-creature frame time — resource blocked

- Target source: merged main `122682ad`; lane `tb/codex-gpu`.
- Prior four-peer attempt v166 exited 2 on native allocation errors mounting peer 2; no usable performance result.
- Idle available committed memory: about 5.3 GiB; one fresh Meadows Forward+ capture reached about 5.8 GiB private memory.
- Refreshed private copies of the existing coordinator/peer/profile under `D:/tetherbound/.artifacts/codex-service-gpu/four-peer-prep/`.
- Coordinator changes only world-seed serialization to integer text; peer/reducer unchanged.
- Original saves, preparation/join routes and outcomes retained; 13 current config pins and six original input files verified.
- Profile records disclosed mechanics L9 Terrapup inputs and Warden encounter; no earned campaign or victory claim.
- Main's mastery/cache changes may affect performance: earlier-source timings cannot be a matched baseline.
- Root preparation review: `preparation-review.json`; plan still unapproved for execution.
- Required next: enough measured memory headroom, review workload coverage, Medium run then identical Compatibility replay.
- No four-peer run started during this pass; no performance numbers, READY or criterion closure.
- Blocker posted on #572; single-process F26 matrices proceed serially.
## Host-first staged start (13 Oct 2026)

- Result: FAILED_SAFE_STOPPED before client launch; no four-creature timing sample and no PASS/READY.
- Source: `1f6d7e210888244d544ea4290770cb844ca21a66`; private staged fixture manifest: `D:/tetherbound/.artifacts/codex-service-gpu/four-creature-staged-start/manifest.json`.
- Run: `D:/tetherbound/.artifacts/codex-service-gpu/four-creature-staged-start/staged-runs/four-creature-staged-6339502fdb6240d7b9dde4c80a2120a8/`.
- Coordinator started the rendered production host first; at the last sample only coordinator PID 49436 and host PID 42272 existed. Neither client was launched and host readiness was not reached.
- At 18:05:52.1569260Z, available physical memory was 2,019,557,376 bytes, below the 2 GiB floor of 2,147,483,648. Commit headroom was 3,324,342,272 bytes, above its floor. The host's sampled private bytes were 4,993,695,744 and working set 3,128,295,424; these are observed process values, not an isolated causal allocation estimate.
- The supervisor then stopped only the exact owned process family. Disk remained above its configured floors. This confirms host-first staging alone still cannot reach client startup under current memory conditions; it does not establish full four-creature performance or visual acceptance.
- Preserve the 2 GiB guard. Do not retry the unchanged workload or infer that extra sequencing solves the host-startup footprint. The criterion remains open pending a materially lower-memory production-faithful path or suitable runtime capacity.
