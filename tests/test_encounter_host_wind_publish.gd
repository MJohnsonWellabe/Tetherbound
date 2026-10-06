extends "res://tests/test_case.gd"

## COMBAT-2. A participant who is waiting for Wind must see it return in every
## published record. The host's per-tick clock feed (`note_opponent_position`,
## which every hosted encounter calls before it snapshots/publishes a record)
## brings each participant row up to the host clock, so the absolute value a
## client syncs to is current rather than frozen at the last post-action pool.

const ENCOUNTER_HOST := preload("res://scripts/net/encounter_host.gd")

const MAX := 100.0
const REGEN := 18.0
const COST := 35.0
const RECOVERY := 0.2
const DELAY := 0.6


func _host_after_commit() -> Array:
	var host := ENCOUNTER_HOST.new(1)
	var record: Dictionary = host.open(2, "water", "boss", {
		"species_id": "aquaryn", "hp": 400.0, "hp_max": 400.0})
	var encounter_id := str(record.get("encounter_id", ""))
	host.join(encounter_id, 3)
	var profile := {"max": MAX, "regen_per_second": REGEN}
	var spent: Dictionary = host.commit_wind(encounter_id, 2, 1, profile, COST,
		1000, RECOVERY, DELAY)
	return [host, encounter_id, profile, float(spent.get("wind", -1.0))]


func _published_wind(host: RefCounted, encounter_id: String, peer_id: int) -> float:
	# Exactly what water_alpha/stormwood/director publish: the record itself.
	var rec: Dictionary = (host.call("record", encounter_id) as Dictionary).duplicate(true)
	return float(((rec.get("participants", {}) as Dictionary).get(peer_id, {}) as Dictionary)
		.get("wind", -1.0))


func test_published_record_carries_regenerated_wind_while_waiting() -> void:
	var setup := _host_after_commit()
	var host: RefCounted = setup[0]
	var encounter_id: String = setup[1]
	var after_commit: float = setup[3]
	assert_almost_eq(after_commit, MAX - COST, 0.001)
	var quiet_ms := int(1000.0 * (RECOVERY + DELAY))
	for elapsed: int in [300, quiet_ms, 1500, 2500, 6000]:
		host.call("note_opponent_position", encounter_id, Vector3.ZERO, 1000 + elapsed)
		var expected := minf(MAX, after_commit
			+ REGEN * maxf(0.0, float(elapsed - quiet_ms)) / 1000.0)
		assert_almost_eq(_published_wind(host, encounter_id, 2), expected, 0.001,
			"published wind after %d ms idle must be %.3f" % [elapsed, expected])


func test_tick_regeneration_does_not_double_count_with_a_later_commit() -> void:
	var setup := _host_after_commit()
	var host: RefCounted = setup[0]
	var encounter_id: String = setup[1]
	var profile: Dictionary = setup[2]
	var after_commit: float = setup[3]
	# Tick many times, then preview/commit at the same instant: one regen span.
	for t: int in range(1800, 3001, 16):
		host.call("note_opponent_position", encounter_id, Vector3.ZERO, t)
	host.call("note_opponent_position", encounter_id, Vector3.ZERO, 3000)
	var expected := after_commit + REGEN * (3000 - 1800) / 1000.0
	var preview: Dictionary = host.call("preview_wind", encounter_id, 2, profile, COST, 3000)
	assert_almost_eq(float(preview.get("wind", -1.0)), expected, 0.001)
	var spent: Dictionary = host.call("commit_wind", encounter_id, 2, 2, profile, COST,
		3000, RECOVERY, DELAY)
	assert_almost_eq(float(spent.get("wind", -1.0)), expected - COST, 0.001)


func test_duplicate_action_still_cannot_double_drain_after_ticks() -> void:
	var setup := _host_after_commit()
	var host: RefCounted = setup[0]
	var encounter_id: String = setup[1]
	var profile: Dictionary = setup[2]
	host.call("note_opponent_position", encounter_id, Vector3.ZERO, 2000)
	var expected := MAX - COST + REGEN * (2000 - 1800) / 1000.0
	var duplicate: Dictionary = host.call("commit_wind", encounter_id, 2, 1, profile,
		COST, 2000, RECOVERY, DELAY)
	assert_true(bool(duplicate.get("wind_duplicate", false)))
	assert_almost_eq(float(duplicate.get("wind", -1.0)), expected, 0.001,
		"replaying action 1 returns the current pool and spends nothing")
	assert_almost_eq(_published_wind(host, encounter_id, 2), expected, 0.001)


func test_participant_who_never_spent_has_no_fabricated_pool() -> void:
	var setup := _host_after_commit()
	var host: RefCounted = setup[0]
	var encounter_id: String = setup[1]
	host.call("note_opponent_position", encounter_id, Vector3.ZERO, 5000)
	var row: Dictionary = ((host.call("record", encounter_id) as Dictionary)
		.get("participants", {}) as Dictionary).get(3, {})
	assert_false(row.has("wind"), "a row without a host pool keeps the client's local pool")


func test_profile_changes_regenerate_the_previous_interval_before_installing_the_new_profile() -> void:
	var setup := _host_after_commit()
	var host: RefCounted = setup[0]
	var encounter_id: String = setup[1]
	var baseline: Dictionary = setup[2]
	host.call("commit_wind", encounter_id, 2, 2, baseline, MAX - COST,
		1000, RECOVERY, DELAY)
	var boosted := {"max": MAX, "regen_per_second": REGEN * 2.0}
	var applied: Dictionary = host.call("preview_wind", encounter_id, 2, boosted, 0.0, 2300)
	assert_almost_eq(float(applied.wind), 9.0, 0.001,
		"the new rate must not boost the half-second before it was applied")
	host.call("note_opponent_position", encounter_id, Vector3.ZERO, 3300)
	assert_almost_eq(_published_wind(host, encounter_id, 2), 45.0, 0.001,
		"idle publications use the installed boost without requiring another action")
	var emptied: Dictionary = host.call("commit_wind", encounter_id, 2, 3, boosted,
		MAX, 3300, 0.0, 0.0)
	assert_almost_eq(float(emptied.wind), 0.0, 0.001)
	var expired: Dictionary = host.call("preview_wind", encounter_id, 2, baseline, 0.0, 3800)
	assert_almost_eq(float(expired.wind), 18.0, 0.001,
		"expiry preserves the final half-second earned under the boost")
	host.call("note_opponent_position", encounter_id, Vector3.ZERO, 4800)
	assert_almost_eq(_published_wind(host, encounter_id, 2), 36.0, 0.001)
	var larger := {"max": 200.0, "regen_per_second": REGEN}
	var resized: Dictionary = host.call("preview_wind", encounter_id, 2, larger, 0.0, 8800)
	assert_almost_eq(float(resized.wind), MAX, 0.001,
		"capacity growth cannot regenerate above the old cap before its boundary")
	assert_almost_eq(float(resized.wind_max), 200.0, 0.001)
	host.call("note_opponent_position", encounter_id, Vector3.ZERO, 9800)
	assert_almost_eq(_published_wind(host, encounter_id, 2), 118.0, 0.001)
	var duplicate: Dictionary = host.call("commit_wind", encounter_id, 2, 3, larger,
		MAX, 9800, RECOVERY, DELAY)
	assert_true(bool(duplicate.get("wind_duplicate", false)))
	assert_almost_eq(float(duplicate.wind), 118.0, 0.001,
		"a profile transition never reopens an accepted action for spending")
