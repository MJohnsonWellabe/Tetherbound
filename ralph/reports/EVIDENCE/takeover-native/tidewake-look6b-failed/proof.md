# Tidewake 6b failed capture: independent raw review

Source `6b4be44e52d573c6e264e48dc2d4d384e0c773b9`. Original run `D:/tetherbound/.artifacts/s/run-twlook6b-r1`. Original receipt remains **FAILED**, byte-identical SHA256 `c41167819377ac80ac9c9bc77249f8ce886a90eed562058cfba52340ed422ed1`.

The capture and settings parser processes exited0 with empty stderr in16.122s and9.111s. This proves parsing only, not settings runtime behavior.

OFF wrote both JPEGs and complete metadata, then emitted `TIDEWAKE FIXED CAPTURE OK views=2`. Both JPEGs decode successfully and their raw hashes equal metadata. Exact source, camera-set hash, Medium/Forward+, GTX1060, candidate/current/ecology OFF, clear-weather fixture and view parameters match the request. **This is capture-output completion, not capture-process success.**

Three independent blockers remain:

1. OFF did not exit naturally. The supervisor reached its180s wall cap and terminated its owned process; recorded exit is-1. ON was never started. Last image write was10:56:49PM Central on October13, roughly133s before terminal observation, so output completion was well before the cap.
2. Both decoded JPEGs and metadata are **1920×1061**, not the required1920×1080. Even a clean exit would not satisfy the viewport contract.
3. Stderr contains the Terrain3D physics-interpolation deprecation (`water_world.gd:65`, at native node insertion) and a grass-field camera-follow warning (`grass_field.gd:1804`). Both violate the unchanged strict diagnostics gate; neither was waived.

Source inspection: `_run` awaits `_fixed_views` then returns. `_fixed_views` flushes/closes metadata, prints the completion marker at376–377, and immediately calls `quit(0)` at378. There is no missing success-quit call. The logs have no teardown timestamps or native stack, so a teardown/driver/extension stall remains a hypothesis; its cause is not proven by this run. Do not claim the warnings themselves caused the hang.

Resource minima remained above all stop floors: physical2,491,113,472 bytes; commit2,495,258,624; C14,476,546,048; D23,416,901,632. Receipt/log/packet/supervisor/image hashes and45 exact-source Git blob/SHA bindings were independently checked. `raw-bundle.json` embeds byte-exact copies of both diagnostic images, all process logs, isolated graphics profiles, metadata, source snapshots, the review and unchanged receipt. Every entry was decoded and checked against its original byte count and SHA256 before duplicate durable files were removed; original .artifacts files are untouched. Stage was not read or modified during this review.

Engine SHA matches the pinned executable. Parser homes h0/h1 retain byte-identical provisioned graphics overrides. Capture home h2 has a different raw hash because serialization added blank lines; all nonblank configuration lines remain identical (Medium/Forward+/unchanged options). Its actual raw bytes/hash are preserved rather than relabeled as the provisioning bytes.

Next action: repair/instrument source to demonstrate natural teardown and exact viewport; fix the native API deprecation and capture-camera warning at their source. Preserve both parser checks and strict diagnostic/resource caps. No unchanged retry or cap increase; a new exact pin must complete both OFF and ON before any matched visual judgment.

No engine launch, stage write, commit, visual score or acceptance closure occurred. Root's shore-day inspection was diagnostic only.
