# PR101 bba0cb79f CI audit — complete

Run 34381325980 targets exact isolated socket-support head `bba0cb79f13fefa4efba44d02bdc313a16f164cb`, stacked on PR100. Attempt 1 completed successfully at 2026-09-09 17:36:40 UTC: 29 jobs, 26 successful and three skipped (two known-red gates and PR export). Every executed full raw log is retained under `.artifacts/pr101-bba0cb79-ci/`: 26 files, 9,420,599 bytes, with run/job metadata, comparison and assertion receipts. No rerun or local engine invocation was used.

Regions job102567254844 explicitly executed the initialized socket geometry probe: 23 assertions, zero failures; inherited lightning24/0 and telemetry16/0 (914ms) also passed with no native/script errors in these steps. Finalized death37 and native adapter81/77/82 passed cleanly. Actual Game108 retains exactly its four declared negative-path errors, not a raw-zero claim.

All four unit shards passed: 3137 tests, 487946 assertions, zero failures. Their 218 normalized engine diagnostic lines match the retained baseline exactly. Every one of 38 network smokes ran on its first 1/1 invocation; no executed automatic retry or first-invocation failure was found across all raw jobs. Gate A opening selected actionable Bramblebun at 5.73m and passed its first invocation.

Compared all executed logs against retained PR99 combined-head raw (and the PR100 audit). No new runtime engine error class was found. Existing intentional peer-death errors remain in net3; ordinary smoke resource-shutdown counts vary among existing 2/3/4-resource classes. Water Alpha net5 job102568603121 returned to the previously observed one ObjectDB warning and no resource ERROR; this does not erase PR99/PR100's retained nine-ObjectDB/four-resource shutdown occurrences. Existing unrelated unscoped-flag and expected-negative diagnostics remain explicitly outside the new clean-step claims.

Disposition: no new CI blocker to the reviewed six-path socket-support delta after PR100. This accepts the bounded attachment/geometry change and exact combined source validation, not the held gate presentation, commercial visual finish or whole-biome gameplay. The skipped known-red gates remain open.
