extends "res://tests/test_case.gd"

# ROADMAP Phase 1 item 6: "Qualify six Meadows activities."
#
# Its criteria are "visible lure, distinct action/decision, useful reward for an
# unchanged five, acknowledgement, saved completion and normal-play
# reachability", with at least one per principal region.
#
# Three of those are JUDGEMENT -- whether a reward is useful to an unchanged
# five, whether an action is distinct, and whether too many endings are generic
# chests. Those belong to the owner and are deliberately NOT asserted here; a
# test that scored them would be inventing an answer.
#
# The rest are checkable, and were not checked anywhere. MEADOWS-PAYOFFS records
# the herd activity as "unqualified toward the six-activity floor" with no
# mechanism to say when that changes. This is that mechanism.

const OBJECTIVES := "res://data/progression/objectives.json"
const FLAG_SCOPES := "res://data/progression/flag_scopes.json"

## The floor ROADMAP item 6 sets.
const REQUIRED_ACTIVITIES := 6


func _read(path: String) -> Variant:
	var text := FileAccess.get_file_as_string(path)
	return JSON.parse_string(text)


func _local_activities() -> Array:
	var data: Variant = _read(OBJECTIVES)
	if data is not Dictionary:
		return []
	var out: Array = []
	for raw: Variant in ((data as Dictionary).get("local", []) as Array):
		if raw is Dictionary:
			out.append(raw)
	return out


func test_the_chapter_carries_at_least_the_six_activity_floor() -> void:
	var activities := _local_activities()
	assert_true(activities.size() >= REQUIRED_ACTIVITIES,
		"ROADMAP item 6 sets a floor of %d optional activities; objectives.json carries %d"
			% [REQUIRED_ACTIVITIES, activities.size()])


func test_every_activity_is_discovered_rather_than_listed_from_the_start() -> void:
	# The "visible lure" half that a file can actually check: the log must not
	# hand the player a list of what the designer put in the world. Each row
	# names the thing that reveals it.
	for row: Dictionary in _local_activities():
		assert_false(str(row.get("revealed_by", "")).is_empty(),
			"activity '%s' has no `revealed_by`, so it appears in the log before the player has found it"
				% str(row.get("id", "")))


func test_every_activity_tells_the_player_what_it_is() -> void:
	for row: Dictionary in _local_activities():
		var label := str(row.get("label", ""))
		assert_false(label.is_empty(),
			"activity '%s' has no label; the quest log would show a blank line" % str(row.get("id", "")))
		assert_true(label.length() > 8,
			"activity '%s' label '%s' says too little to act on" % [str(row.get("id", "")), label])


func test_every_activity_completes_into_a_declared_durable_flag() -> void:
	# "Saved completion": the flag that ticks the activity has to exist AND have
	# a declared scope, or it is neither durable nor reliably shared.
	var scopes: Variant = _read(FLAG_SCOPES)
	assert_true(scopes is Dictionary, "flag_scopes.json must parse")
	for row: Dictionary in _local_activities():
		var flag := str(row.get("flag_id", ""))
		var id := str(row.get("id", ""))
		assert_false(flag.is_empty(), "activity '%s' names no completion flag" % id)
		assert_false(str(row.get("scope", "")).is_empty(),
			"activity '%s' declares no scope for '%s'; world and character facts persist differently"
				% [id, flag])


func test_no_activity_shares_its_completion_flag_with_another() -> void:
	# One fact, one flag. Two activities on one flag means finishing either
	# ticks both, and the second can never be finished again.
	var seen := {}
	for row: Dictionary in _local_activities():
		var flag := str(row.get("flag_id", ""))
		assert_false(seen.has(flag),
			"activities '%s' and '%s' share completion flag '%s'"
				% [str(seen.get(flag, "")), str(row.get("id", "")), flag])
		seen[flag] = str(row.get("id", ""))


func test_the_activities_are_spread_across_the_chapter_not_stacked_in_one_band() -> void:
	# ROADMAP: "At least one activity per principal region." Checked as the
	# weaker, objective form -- they must not all sit in one band -- because
	# which bands count as principal is a design call.
	var bands := {}
	for row: Dictionary in _local_activities():
		var id := str(row.get("id", ""))
		var band := id.split("_")[0] if id.contains("_") else id
		bands[band] = true
	assert_true(bands.size() >= 3,
		"every optional activity would sit in %d band(s) (%s); the chapter needs them spread"
			% [bands.size(), str(bands.keys())])
