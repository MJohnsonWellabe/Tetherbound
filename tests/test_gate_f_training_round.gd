extends TestCase
const GUARD := preload("res://tools/gate_f/training_round.gd")
class Member extends RefCounted:
	var level := 5
class Roster extends RefCounted:
	var members: Array = []
	func size() -> int: return members.size()
	func at(index: int) -> RefCounted: return members[index]

func roster(level: int) -> Roster:
	var result := Roster.new()
	for i in 5:
		var member := Member.new()
		member.level = level
		result.members.append(member)
	return result

func test_started_round_finishes_recovery_after_winning_final_level() -> void:
	var party := roster(4)
	var guard := GUARD.new()
	assert_false(guard.decide({"id": "one", "start": true}, party).omit)
	for member in party.members: member.level = 5
	assert_false(guard.decide({"id": "one"}, party).omit,
		"The winning round's post-fight recovery still executes")
	assert_true(guard.decide({"id": "two", "start": true}, party).omit)
	assert_true(guard.decide({"id": "two"}, party).omit)

func test_reads_every_live_member_and_rejects_missing_round_state() -> void:
	var party := roster(6)
	party.members[4].level = 4
	var guard := GUARD.new()
	assert_false(guard.decide({"id": "one", "start": true}, party).omit)
	assert_false(guard.decide({"id": "absent"}, party).ok)
	assert_false(guard.decide({"id": "one", "start": true}, party).ok)
	assert_false(guard.decide({"id": "two", "start": true}, null).ok)
	party.members.pop_back()
	assert_false(guard.decide({"id": "short", "start": true}, party).omit)

func test_all_authored_rounds_keep_original_budgets_and_strict_victories() -> void:
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/gate_f/segments/S03.json"))
	var starts := 0
	var approaches := 0
	var wins := 0
	var guard := GUARD.new()
	var party := roster(4)
	for step: Dictionary in doc.steps:
		if not step.has("training_round"): continue
		assert_true(guard.decide(step.training_round, party).ok,
			"Every authored continuation must follow its own unique start: " + str(step.id))
		if step.training_round.start: starts += 1
		if step.action == "move_to_entity":
			approaches += 1
			assert_eq(step.args.entity, "poi:wild")
			assert_eq(int(step.args.budget_frames), 2000)
			assert_true(step.args.require_alive and step.args.require_engage_prompt)
		if step.action == "fight_until_resolved":
			wins += 1
			assert_true(step.args.require_victory)
	assert_eq(starts, 20)
	assert_eq(approaches, 20)
	assert_eq(wins, 20)
