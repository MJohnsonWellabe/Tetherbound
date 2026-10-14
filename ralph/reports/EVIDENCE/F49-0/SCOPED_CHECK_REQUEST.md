# Routes scoped native checks - dispatch pending
Launcher: tools/earned_saves/run_routes_scoped_checks.ps1; default prints plan only. Root remains sole native writer; no launch performed here.
Source scope: integrate dd0c6b0cd6 plus the reviewed launcher commit; supply the actual full clean integrated HEAD, never a lane abbreviation or projection with a different HEAD. No staging/import performed by launcher.
Runtime scope: supply root's admitted Godot4.7 console executable and exact SHA256. The launcher verifies its hash before starting, rather than inferring runtime identity from a filename.
Two separate invocations, each capped at180seconds. No automatic successor or retry; root schedules around Meadows R5/b9 jobs.
```powershell
$params = @{ SourceCommit=$IntegratedSha; Project=$CleanStage; Godot=$Godot47; GodotSha256=$AdmittedEngineHash; MaxSeconds=180 }
./tools/earned_saves/run_routes_scoped_checks.ps1 @params -Batch training -Output "$EvidenceRoot/training"
./tools/earned_saves/run_routes_scoped_checks.ps1 @params -Batch loaner -Output "$EvidenceRoot/loaner"
```
Append -Execute only for the individually granted batch. Each output directory must be absent and outside tracked source. Placeholder variables require real admitted values; zero hashes used in plan-only checks are not runtime pins.
Training selectors: test_altar_training_piece.gd,test_chapter_homestead.gd,test_f49_training_prefix.gd,test_training_handoff.gd.
Training checks cover exact preparation predecessor/source, all five slots, prior Master/feast history, per-payment witness/debit, prefix refusal, saved training/ending projections and ordinary re-entry eligibility. They do not execute the complete paid home/Master/feast journey.
Loaner selector: test_cloudreach_fly_loaner_end.gd. Covers chapter-end removal, restricted Master route and whole-step corridor logic, including real-route gap and owned-flight cases. It does not prove physical perch arrival or terrain clearance.
Launcher refuses a dirty/different HEAD, runtime hash mismatch, occupied Godot/Blender slot, existing output or capacity below2GiB physical/commit, C10GiB/D20GiB. No reduced floors.
Independent managed deadline kills only the launched process tree even if resource polling stalls; cleanup/drain failures accumulate in FAIL evidence. Resource queries also use bounded operation timeouts.
PASS requires natural exit0, unchanged clean source, exact selected test-method multiset, one matching nonzero-assertion/zero-failure summary and no engine error/warning diagnostics. A clean exit alone cannot pass.
Evidence: stdout.log, stderr.log, supervisor.json and supervisor.sha256. Receipt records admitted command/source/runtime hash, selected test-file hashes, methods, capacities, timing and errors; log hashes retained.
CPU-only verification: tools/earned_saves/test_routes_scoped_checks.ps1 parses PowerShell, compiles the deadline C# class without starting it, and checks16 synthetic output verdicts. Both plan-only batches inspected; no output directory or engine process created.
Native tests, earned chain, actual UI payments/feed, physical route and reload proof remain OPEN. Existing frozen NEXT_HANDOFF.json and Systems/Fights packets are unchanged.
