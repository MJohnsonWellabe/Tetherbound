# Aster Master loop: source candidate, native proof pending
Owner decision: 13 Oct, issue #572 comment 6152935182 retains Maela's carrier only for Master-perch transport after Cloudreach.
The prior 29660cee3 witness failed at first Fly deployment from cloudreach_06_veyra_relay; it remains a FAIL, not superseded by source.
Candidate: fly_traversal.json allowlists master_t4_perch; fly_controller checks fly_only Master/realm, authored launch proximity and in-flight corridor.
The carrier remains ephemeral and outside the five; owned healthy active carriers take precedence. Combat and other launch locations are refused.
WORLD §4.2 and SYSTEMS Flight record the rule. No new durable flags or save schema.
Regression additions retain every existing loaner-ending assertion; add approach/route/elsewhere/combat/realm/unlock/destination and owned-carrier checks.
Aster now calls master_visit for physical travel, production 1v1 selection and recipe chest; it no longer stops with only the duel win.
CPU: JSON/destination/route-shape checks and git diff --check pass. This is not Godot compile or runtime evidence.
Native slot requested through coordinator's normal read of this lane; no engine launched here.
First bounded job (5 minute ceiling, stop on parse/error):
`godot --headless --path C:/CodexTemp/tetherbound-native-service --script tests/run_tests.gd -- --only=test_cloudreach_fly_loaner_end.gd,test_fly_traversal.gd`
Then separate route job (10 minute ceiling, retain logs and failed state; do not count supervisor kill as PASS):
`godot --headless --path C:/CodexTemp/tetherbound-native-service --script tools/earned_saves/cloudreach_chain_runner.gd -- --segment=06k_return_cliffhold --from=tests/fixtures/earned_saves/cloudreach_06_veyra_relay --out=D:/CodexTemp/routes-aster-cliffhold --accelerated`
The output path must be absent; root pins this branch's exact commit before either job and does not commit while it runs.
CPU lower bound for the inherited summit glide was 112.6 stamina. Removed that route. After 06k, run separate 06l_return_aerie from routes-aster-cliffhold into routes-aster-aerie, then 06m_aster_duel from routes-aster-aerie into routes-aster-proof. Each job has its own 10-minute ceiling; no free refill.
Open: the chest's approximately 18-stack kit needs Fights' storage-trip helper, still absent on this branch. Chest failure remains failure.
Open: no Kitchen/feast proof, no generated-to-earned seam conversion, no F28/F49 closure claim.
Follow-on source: 06n_aster_departure loads the duel/chest output and flies back to the aerie, requiring the saved Master win and feast_t4 recipe. Run it as a separate bounded piece.
Grammar-only validation: gdtoolkit parsed fly_controller, loaner tests, master_visit and all changed chain runners. Godot semantic compile and runtime remain pending; add test_training_handoff.gd to the first focused job.
Seam audit: Cloudreach now checks predecessor PASS, rejects malformed after-state, and compares Tidewake items to inventory without relying on dictionary key order; realm is included. New negatives cover changed/missing inventory and wrong realm. Grammar-only check passes.
Storage fallback audit: chest prompts are reacquired after return; geometry is never guessed as a prompt. Realm/site checks and an explicit rebind callback fence replaced caller scenes. Storage receipts are retained. New test_master_visit.gd is grammar-checked, native UNRUN; Fights currently supports Meadows storage return only.
