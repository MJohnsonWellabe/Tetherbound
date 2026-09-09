# Main CI 77745ef03

Run [34366464128](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/34366464128), exact head `77745ef03421a3adceb6282d3e5abb71350e1197`, attempt 1: completed success. Final job inventory is 29: **27 successful, two known-red jobs skipped**. Export and solo regression both executed successfully.

All 27 executed jobs' complete decoded raw logs are retained under `.artifacts/main-77745ef03-ci/job-*.log`, totaling **10,411,796 bytes**. Export job `102525123033` was fetched only after terminal completion. `run.json` and `final-jobs.json` retain exact metadata. No rerun or GitHub mutation was performed.

## Raw review

Compared against PR98 head raw logs in `.artifacts/pr98-8f2c7c7-ci`, grouping identical job names and aggregating the four unit shards. `comparison.json` retains engine-error counts; only dynamic peer identifiers, trainer peer suffixes and process IDs were normalized. Full raw text remains unchanged. `compare.ps1` records the reproducible comparison and `attempts-units.json` records executed summary/attempt findings.

- Units: **3,078 tests / 487,638 assertions / zero failed**. Their 218 raw engine diagnostic lines match the PR98 aggregate exactly; a passing test summary is not a claim of zero engine diagnostics.
- All seven multiplayer shards passed their first executed smoke invocations. Existing shard 2 process-child diagnostic and shard 5 cached-node/invalid-packet/non-authority-delta classes remain present and match the normalized PR98 baseline. Shard 5 additionally prints one existing-class four-resource shutdown diagnostic.
- Other error-count changes are existing three/four-resource shutdown variations in combat, core verbs, regions and gate evidence, plus reductions elsewhere. No new normalized engine error class was found. Export has zero ERROR/SCRIPT ERROR lines.
- **No executed `failed on attempt` line or attempt 2+ group was found in this run.** Shell source echoes containing those words were excluded from execution findings. In particular this main run's opening passed its first invocation; that does not erase PR97 run 34365460024's separately retained opening failure followed by automatic retry success.

The existing native diagnostics remain limitations; this is a baseline comparison, not a clean-native claim. No new blocker relative to reviewed PR98 was found. This main tree predates the separate PR97 protocol repair and its hosted-settlement correction; no acceptance is transferred to those later heads.
