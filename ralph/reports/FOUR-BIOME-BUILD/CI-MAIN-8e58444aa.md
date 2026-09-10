# Main 8e58444aa CI audit — complete

Run34383202374 targets landed PR100 main `8e58444aa273430f435ae96a8663c7860850614e`. Attempt1 completed successfully2026-09-09 at17:56:51 UTC:29 jobs,27 successful and two known-red gates skipped. All27 full terminal executed logs,10,634,671 bytes, and metadata/comparison receipts are retained under `.artifacts/main-8e58444a-ci/`; immediate comparison baseline is exact PR100 head raw. No rerun or local engine used.

Four unit shards total3137 tests/487946 assertions/zero failures, with218 normalized diagnostic lines matching baseline. All38 network smokes passed their first1/1 invocation; no executed automatic retry or first-invocation failure was found. Regions102573901758 passed actualGame108 with its exact four expected negative errors, native81/77/82, finalized37, telemetry16 (917ms) and lightning24. The latter new steps have clean raw error scans.

No new runtime engine error class was found. Existing ordinary smoke shutdown resource counts vary. Night ecology emitted10ObjectDB/5resources after its PASS at17:41:58; this is absent from immediate PR100 but matches the same smoke, counts and engine locations in main1d6 job102553095661 at16:39:51. Water Alpha net5 returned to one ObjectDB warning and no resource ERROR; prior PR99/PR100 occurrences remain retained. Intentional peer-death and unit negative diagnostics remain, so this is not an all-logs-zero-error claim.

Export102579650832 passed with no native/script errors; uploaded artifact digest `9784af46a6cc417bf52c7dc9844357ba1bbb4fb2d18afda243e11becdc9b10ed`. No new main CI blocker. The separately verified release and existing skipped gates do not confer whole-biome or commercial visual acceptance.
