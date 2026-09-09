# Retained material/camp stage diagnostic — 2026-09-09

This is diagnostic evidence from a copied autosave at clean-main `d3cdb57ca38acc2691c014663419389037b5209c`. It is not fresh-save or earned-continuity acceptance evidence and did not retry the full campaign.

## Inputs and preservation

The stopped run's original test-owned files were copied before analysis to `.artifacts/opening-prefix-d3cdb57-0909/rest/retained-before-diagnostics/`:

- `slot_0.json`: SHA-256 `13AA103C3323B46DCF9C43027EB518659C6E7563A49A68877289B5EC3FC6F913`
- `four_biome_coverage_12656_2716.jsonl`: SHA-256 `F61B668B2EBC2BCE0F68E05A2D0CB323DF690F4DD6403EE0D1B5A7CCEF2FCCC9`

The source slot retained the same hash after the diagnostic. The isolated profile copy also had that hash before launch. The autosave predates the stopped process's terminal in-memory state: it has player x/z `(-125.971, 51.362)`, wood 19, fiber 16, stone 4, no placed-building records, and no persisted pending-build/action field.

## Diagnostic and validation

`tools/diagnose_retained_material_camp_stage.gd` adds local observational subclasses only. They print material return, camp entry/return, and every walk's phase, purpose, target, tolerance, physics frame, pose and result. Within 10m they sample every ten frames, capped at 500 records per leg, including distance, input owner, navigator detour state and contacts. Navigation behavior, progress, inventory and budgets are unchanged.

The first `--check-only` invocation was retained in `check-only.log` and failed because `TraceCamp._walk_to` initially omitted the parent method's fourth `direct` parameter. The signature was corrected and forwarded unchanged. `check-only-2.log` then passed. There was no retry-to-green claim for the failed first check.

The one native diagnostic used an isolated APPDATA profile and the established 600-second/90%-commit/400-process guard. It exited 0 after 149.2 seconds without a guard stop. Peak system commit was 60.2%; peak process count was 249; terminal Godot census was zero.

## Actual receipts

The copied autosave gathered its remaining fiber and stone, followed the PondGate return waypoints, and reached the material build-patch target `(30, -40)` with tolerance 1.65. `MATERIALS RETURN` passed at physics frame 3328 and player `(29.023, 0.223, -38.733)`. `CAMP ENTRY` printed on the same frame.

Camp then completed these labeled walks:

- tent stance: target `(35.770, -37.101)`, tolerance 0.35
- campfire stance: target `(35.770, -34.101)`, tolerance 0.35
- bedroll stance: target `(36, -37)`, tolerance 0.35
- clear of Craft prompt: target `(36.030, -40.553)`, tolerance 0.8
- armed bedroll stance: target `(36, -37)`, tolerance 0.35
- creature-bed stance: target `(25.033, -37.000)`, tolerance 0.35

`CAMP RETURN` passed at frame 4685 with no failures.

The stopped fresh run's coverage positions overlap several camp walks. Its early x=38–40 samples overlap the clear/armed-bedroll detours, while its later dominant x=22–29, z=-33–-41 loop is spatially closer to the creature-bed stance than the material target. This makes camp-stage movement the stronger explanation for the previously quiet interval. It does not identify the exact original await: that run had no stage labels, and this copied-save replay completed rather than reproducing the loop.

## Artifacts

- `console.log`: SHA-256 `C0B2322CA3D2CDAE865C645B1416C17EE86B1BD86D0F4F44C264FAC6B27FCB0E`
- `result.json`: SHA-256 `AFDF08888328F4524203658F832A6B19A800662AFC77CF1C7B23A7D3A64B046C`
- `resources.csv`: SHA-256 `4D20EC20A03A5FB49445B4B6D6F03FDCD29F526C272FA53D51145C46034105B2`
- `tools/diagnose_retained_material_camp_stage.gd`: SHA-256 `2F24FB6BE0E781DB6454BC150EFCE5095710257AEC15254F90C8F72BD6CE547C`

All run artifacts are under `.artifacts/opening-prefix-d3cdb57-0909/retained-stage-diagnostic/`.

## Recommended next evidence

Do not change navigator behavior from this result. Material legs already have a per-call budget of `240 + distance_m * 60` physics frames, shared across boundary waypoints. Camp/tail walks use at least 3600 frames or the same distance formula; the older build helper can retry a walk up to three times. The fresh proof's 600-second external limit can therefore expire while an individually valid leg is still active, before that leg emits its failure receipt.

Before any root-reviewed changed-mechanism fresh `--through-rest` run, add minimal read-only stdout receipts at composition boundaries (`MATERIALS entry/return`, `CAMP entry/return`, `REST entry/return`) and at the shared material and camp/tail `_walk_to` boundaries. Each receipt needs phase/purpose, target, tolerance, allocated budget, start/end physics frame, start/end pose, result and distance. Add the already-approved assignment-3 rest snapshot only at its existing boundary. These labels would distinguish:

1. external wall deadline during an active, still-progressing leg;
2. an internal leg budget returning false with its existing navigation/contact failure telemetry; and
3. successful camp completion followed by the historical third-rest assignment boundary.

This instrumentation changes the evidence mechanism without changing play, movement, progress or budgets. A new native run still requires a separate stop-rule review and world lease; this diagnostic alone is not grounds for an unchanged replay.
