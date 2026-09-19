extends RefCounted

## Repeat the shipped care instruction: one physical bed, several real nights.
## All mutations belong to production UI/input. Driver callbacks return {ok,why}:
## walk_to_bed(), open_bed() -> also panel, press(control), sleep_at_bedroll().
## The sleep callback must physically reach/use the placed sheltered bedroll and
## await its fade. Optional read_focus()/settle() callbacks support unit fixtures;
## production defaults read the actual viewport and await three process frames.
static func execute(game: Node, bed: Node, driver: Dictionary,
		interrupted: Callable = Callable()) -> Dictionary:
	var result := {"ok": false, "why": "", "nights": 0, "skipped": [], "rested_rows": []}
	var party: RefCounted = game.get("party") if game != null else null
	if party == null or int(party.call("size")) != 5:
		return _fail(result, "one-bed team care requires the complete five-creature party")
	if bed == null or not bed.has_method("build_index") or int(bed.call("build_index")) < 0:
		return _fail(result, "one-bed team care requires a player-placed Creature Bed")
	for key: String in ["walk_to_bed", "open_bed", "press", "sleep_at_bedroll"]:
		if not driver.get(key, Callable()).is_valid():
			return _fail(result, "missing physical care callback: " + key)
	var members: Array = []
	for row in 5:
		members.append(party.call("at", row))
	for row in 5:
		if _interrupted(interrupted):
			return _fail(result, "one-bed team care interrupted by cost gate")
		var creature: RefCounted = members[row]
		if creature == null or party.call("at", row) != creature:
			return _fail(result, "party identity changed during one-bed team care")
		if bool(creature.get("rested")) and not bool(creature.get("resting")):
			result.skipped.append(row)
			continue
		if int(bed.call("occupant_index")) != -1 or bool(creature.get("resting")):
			return _fail(result, "bed or selected creature is already assigned; refusing early wake")
		var moved: Dictionary = await driver.walk_to_bed.call()
		if not bool(moved.get("ok", false)):
			return _fail(result, "Creature Bed approach failed: " + str(moved.get("why", "")))
		var opened: Dictionary = await driver.open_bed.call()
		var panel: Node = opened.get("panel")
		if not bool(opened.get("ok", false)) or not _owns_bed(panel, bed):
			return _fail(result, "physical interaction did not open the selected Creature Bed")
		var prefix := "%d." % (row + 1)
		var reached := false
		for attempt in 6:
			if _interrupted(interrupted) or not _owns_bed(panel, bed):
				return _fail(result, "rest picker lost ownership or cost gate interrupted")
			var focused := _focus_text(game, driver).strip_edges()
			if focused.begins_with(prefix):
				reached = true
				break
			if attempt == 5:
				break
			var down: Dictionary = await driver.press.call("ui_down")
			if not bool(down.get("ok", false)):
				return _fail(result, "physical rest-row navigation refused")
			await _settle(game, driver)
		if not reached:
			return _fail(result, "physical rest picker never reached row " + prefix)
		var accepted: Dictionary = await driver.press.call("ui_accept")
		await _settle(game, driver)
		if not bool(accepted.get("ok", false)) or party.call("at", row) != creature \
				or not bool(creature.get("resting")) \
				or int(creature.get("rest_bed_index")) != int(bed.call("build_index")) \
				or int(bed.call("occupant_index")) != row:
			return _fail(result, "physical rest-row acceptance did not assign the selected creature")
		var closed: Dictionary = await driver.press.call("menu_cancel")
		await _settle(game, driver)
		if not bool(closed.get("ok", false)) or bool(panel.call("is_open")):
			return _fail(result, "rest picker did not close through controller input")
		if _interrupted(interrupted):
			return _fail(result, "one-bed team care interrupted before player sleep")
		var before_day := int(game.get("day"))
		var slept: Dictionary = await driver.sleep_at_bedroll.call()
		if not bool(slept.get("ok", false)):
			return _fail(result, "physical Bedroll sleep failed: " + str(slept.get("why", "")))
		if int(game.get("day")) <= before_day or party.call("at", row) != creature \
				or not bool(creature.get("rested")) or bool(creature.get("resting")) \
				or int(creature.get("rest_bed_index")) != -1 \
				or int(bed.call("occupant_index")) != -1 or bool(creature.get("fainted")):
			return _fail(result, "night did not complete the assigned creature rest and free its bed")
		result.nights += 1
		result.rested_rows.append(row)
	for row in 5:
		if party.call("at", row) != members[row] or not bool(members[row].get("rested")):
			return _fail(result, "whole-team rested readback failed after the last night")
	result.ok = true
	result.why = "all five rested through physical bed care or existing rested state"
	return result


static func _owns_bed(panel: Node, bed: Node) -> bool:
	return is_instance_valid(panel) and panel.has_method("is_open") \
		and bool(panel.call("is_open")) and panel.get("_bed") == bed


static func _focus_text(game: Node, driver: Dictionary) -> String:
	if driver.get("read_focus", Callable()).is_valid():
		return str(driver.read_focus.call())
	var focus := game.get_viewport().gui_get_focus_owner()
	return focus.text if focus is Button else ""


static func _settle(game: Node, driver: Dictionary) -> void:
	if driver.get("settle", Callable()).is_valid():
		await driver.settle.call()
	else:
		for frame in 3:
			await game.get_tree().process_frame


static func _interrupted(callback: Callable) -> bool:
	return callback.is_valid() and bool(callback.call())


static func _fail(result: Dictionary, why: String) -> Dictionary:
	result.why = why
	return result
