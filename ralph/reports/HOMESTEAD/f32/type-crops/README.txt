F32 criterion #3 -- "Eight type crops grow on homestead plots; the Greenhouse
(a Farm buildable, not an attachment) grows off-biome crops; every harvest is
by hand."

Files: tests/test_f32_type_crops.gd, tests/smoke_f32_type_crop_harvest.gd (+ .uid)
Engine: Godot v4.7.stable.official.5b4e0cb0f, headless, existing import (no re-import).
Fixtures are disclosed in each file's header comment.

== 1. Unit suite ==
$ godot --headless --path . --script tests/run_tests.gd -- --only=test_f32_type_crops
  ok    test_f32_type_crops.gd :: test_all_eight_type_crops_are_defined_with_registered_seeds_and_outputs
  ok    test_f32_type_crops.gd :: test_each_type_crop_grows_through_the_host_transaction_on_the_authored_plot
  ok    test_f32_type_crops.gd :: test_each_type_crop_ripens_only_on_its_host_day
  ok    test_f32_type_crops.gd :: test_greenhouse_is_a_farm_buildable_in_the_real_catalogue_not_an_attachment
  ok    test_f32_type_crops.gd :: test_harvest_is_manual_and_days_never_move_produce_into_inventory
  ok    test_f32_type_crops.gd :: test_native_types_grow_outdoors_and_off_biome_types_need_the_greenhouse
6 tests, 423 assertions, 0 failed

Covers: all eight crops in crop_order with valid host definitions, registered
seed_<type> items and registered outputs; each crop ripens exactly on
planted day + grow_days (host day counter); each of the eight sows, grows and
is picked through foundation_actions.stage -> f32_source_actions._farm ->
WorldLedger resource commit -> owner_plan on authored:0 (exact seed debit,
exact output gain, receipt); native_types (ground, air) sow outdoors, the six
off-biome types are refused outdoors (crop_locked_or_plot_busy, plot unchanged)
and accepted with greenhouse_built=true; missing greenhouse context refused;
Greenhouse is ItemDB buildable station_id=farm, home_only, cost == farm.json
cost, stations.json auxiliary_buildables, no attachment row (no farm
attachment track), places without a parent, refuses a parent_uid
(attachment_parent_invalid) and a second copy (greenhouse_already_built);
automatic_harvest=false / manual_taps_only=true / offline_production=false;
20 host days + JSON world reload leave the durable plot byte-identical and the
owner inventory unchanged; only a harvest intent pays; client-named crop and
green crop refused.

== 2. Engine smoke (real Meadows scene) ==
$ godot --headless --path . --script tests/smoke_f32_type_crop_harvest.gd -- --output=/tmp/claude-0/crops/smoke1
PASS: production Game exists
PASS: ground is a native type crop
PASS: request actual Meadows scene
PASS: Meadows procedural build completed
PASS: production player and resource adapter mounted
PASS: controller driver resolves production camera and arbiter
PASS: fixture start resolves baked ground
PASS: mount_authored_farm placed the typed plot for authored:0
PASS: plot interact prompt exists
PASS: controller walked 5.1m to the plot
PASS: live host context: no Greenhouse built -> outdoors only
PASS: live host context derives Greenhouse from paid world record
PASS: pre-farming owner and world saved to isolated disk
PASS: before decodes world save document
PASS: before decodes character save document
PASS: plot prompt wins interaction (till)
PASS: till reaches owner save and ACK (ok)
PASS: tilled decodes world save document
PASS: tilled decodes character save document
PASS: disk: plot tilled
PASS: plot prompt wins interaction (sow)
PASS: seed picker opened from interact
PASS: sow reaches owner save and ACK (ok)
PASS: sown decodes world save document
PASS: sown decodes character save document
PASS: disk: ground sown on host day 1, ripe on 3 ({ "crop_id": "ground", "planted_on_day": 1, "revision": 2, "ripe_on_day": 3, "state": "sown" })
PASS: disk: exactly one seed_ground debited
PASS: disk: sowing paid no attuned_ground
PASS: disk: sowing paid no essence_ground
PASS: disk: sow journal row accepted
PASS: day 1: crop still growing
PASS: day 2: crop still growing
PASS: ripe-day owner and world saved
PASS: ripe decodes world save document
PASS: ripe decodes character save document
PASS: disk: host day advanced to ripe day
PASS: disk: ripe crop stays on the plot
PASS: disk: day advance paid no attuned_ground
PASS: disk: day advance paid no essence_ground
PASS: plot prompt wins interaction (harvest)
PASS: harvest reaches owner save and ACK (ok)
PASS: harvested decodes world save document
PASS: harvested decodes character save document
PASS: disk: harvest journal row accepted
PASS: disk: harvest paid exactly 2 attuned_ground
PASS: disk: harvest paid exactly 3 essence_ground
PASS: disk: net seed debit is exactly one
PASS: disk: owner record holds the harvest receipt
PASS: disk: picked bed returns to tilled
exit code: 0 (49 PASS, 0 FAIL)

Path: mount_authored_farm typed plot authored:0 -> controller walk 5.1m ->
interact (till, hoe) -> interact opens seed picker -> ui_accept (A) sows
seed_ground -> Game.advance_day() x2 -> interact harvest. Each verb settled
through FoundationResources with owner_saved+owner_acknowledged; saves decoded
with save_document.parse. Disk deltas: seed_ground -1, attuned_ground +2,
essence_ground +3, accepted harvest journal row, receipt in owner record,
plot back to tilled. Live host_context derives greenhouse_built false, then
true from a transient paid {id:greenhouse} world record (removed before save).

== Not claimed ==
ENet/two-peer; off-biome sowing under a really placed+paid Greenhouse in
engine (unit-proven at the transaction layer; adapter derivation proven in
engine); day advance by night rest rather than Game.advance_day(); visuals
(crop_presentation_candidate stays flag-off).

== Production notes (no gap for this criterion) ==
- scripts/world/farm_logic.gd:316 greenhouse_buildable_proposal() still
  requires enabled==false and status "authored_proposal_not_runtime_registered";
  farm.json now ships enabled=true / "production_gameplay_enabled_validation_pending",
  so it returns {}. No callers; stale accessor.
- Greenhouse presence is world-wide (any paid meadows greenhouse record unlocks
  every authored plot; foundation_resources.gd host_context), not plot-local.
  Matches HOMESTEAD.md §5.3 "the Greenhouse lets plots grow the other types".
- scripts/world/type_crop_plot.gd _greenhouse_built() (presentation) checks
  id+realm but not paid; the host check (paid==true) is authoritative.
- scripts/build/station_next_upgrade.gd:24 uses a UI key "attachment_id":"greenhouse";
  placement policy treats it as a non-attachment.

VERDICT: PASS -- criterion #3 proven by 6/6 unit tests (423 assertions) and
49/49 engine smoke checks.
