extends "res://tools/catalogue_survey.gd"

## Native matched candidate/control for HUD-LANDSCAPE-SPACE01. At each time the
## ordinary catalogue frame is the empty-party candidate, followed by its
## labelled prior-HUD control. A second candidate/control pair uses two healthy
## installed party members with the ally stowed. Between each candidate/control
## pair the same player/camera/clock and party state are retained; both records
## retain exact camera transforms.
##
## Before capture, a disclosed two-member party fixture drives the production
## EncounterDirector with the authored LB/RB actions. It proves the labels that
## appear can actually cycle, call out and put away a creature. The ally is put
## away before visual frames. Empty-party and common two-party fixtures are
## disclosed separately in every record.
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/probe_hud_landscape_space.gd -- \
##     --biome=water --subset=gull_rest_beach --times=day,night \
##     --output=res://shots/diagnostics/hud-landscape-space01

const TOOL_PATH := "res://tools/probe_hud_landscape_space.gd"
const HUD_PATH := "res://scripts/ui/playground_hud.gd"
const UI_TOKENS := preload("res://scripts/ui/ui_tokens.gd")
## Shortest current authored main objective by source length. Its actual
## engine wrap count is deliberately measured and recorded, not assumed.
const SHORT_AUTHORED_OBJECTIVE := "Make camp for your team."
const CONTROL_MIN_LINES := 2
const INPUT_SETTLE_FRAMES := 8
const CONTROL_SETTLE_FRAMES := 3
const ALLY_TIMEOUT_FRAMES := 180

var _hud: CanvasLayer = null
var _control_records: Array[Dictionary] = []
var _two_party_candidate_records: Array[Dictionary] = []
var _control_audit: Dictionary = {}
var _controls_audited := false
var _fixture_first: RefCounted = null
var _fixture_second: RefCounted = null


func _load_plan() -> bool:
	if not super._load_plan():
		return false
	if _planned.size() != 2:
		push_error("HUD landscape probe requires one destination at day and night")
		return false
	if str(_planned[0].get("identity", "")) != str(_planned[1].get("identity", "")):
		push_error("HUD landscape probe requires both times at the same destination")
		return false
	var observed_times := [str(_planned[0].get("time", "")), str(_planned[1].get("time", ""))]
	observed_times.sort()
	if observed_times != ["day", "night"]:
		push_error("HUD landscape probe requires --times=day,night")
		return false
	return true


func _prepare_capture_shell() -> bool:
	if not super._prepare_capture_shell():
		return false
	_hud = _world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if _hud == null:
		_failures.append("production PlaygroundHUD is missing")
		return false
	return true


func _capture_row(row: Dictionary) -> void:
	if not _controls_audited:
		_controls_audited = true
		await _audit_actual_party_controls()
		if not _failures.is_empty():
			_write_manifest()
			return
	await super._capture_row(row)
	if _records.is_empty() or not _failures.is_empty():
		return
	var candidate_record := _records[-1] as Dictionary
	var candidate_metrics := _hud_metrics("candidate")
	candidate_record["hud_layout"] = candidate_metrics
	_validate_candidate_layout(candidate_metrics, true)
	_hud.set_process(false)
	_apply_prior_hud_control()
	for _frame in CONTROL_SETTLE_FRAMES:
		await process_frame
	await _capture_prior_control(row, "empty_party")
	_restore_candidate_hud()
	if not _add_two_party_fixture():
		_write_manifest()
		return
	for _frame in INPUT_SETTLE_FRAMES:
		await process_frame
	await _capture_two_party_candidate(row)
	_hud.set_process(false)
	_apply_prior_hud_control()
	for _frame in CONTROL_SETTLE_FRAMES:
		await process_frame
	await _capture_prior_control(row, "two_party")
	_restore_candidate_hud()
	var game := root.get_node_or_null(^"Game")
	if game != null and game.get("party") != null:
		(game.get("party") as RefCounted).call("clear")
	_write_manifest()


func _finish(complete: bool) -> void:
	var expected_times := _planned.size()
	var all_frames_complete := complete \
			and _two_party_candidate_records.size() == expected_times \
			and _control_records.size() == expected_times * 2
	if complete and not all_frames_complete:
		_failures.append("HUD probe did not produce the expected %d candidate and %d control frames" % [
			expected_times * 2,
			expected_times * 2,
		])
	super._finish(all_frames_complete)


func _audit_actual_party_controls() -> void:
	var game := root.get_node_or_null(^"Game")
	var director := _world.get_node_or_null(^"EncounterDirector")
	var party: RefCounted = game.get("party") if game != null else null
	if game == null or director == null or party == null:
		_failures.append("actual-control audit is missing Game, party or EncounterDirector")
		return
	party.call("clear")
	_fixture_first = game.call("make_creature", "terrapup", "Biscuit") as RefCounted
	_fixture_second = game.call("make_creature", "bramblebun", "Moss") as RefCounted
	if not _add_two_party_fixture():
		_failures.append("could not build the disclosed two-member control fixture")
		return
	for _frame in INPUT_SETTLE_FRAMES:
		await process_frame
	var label := _hud.get_node_or_null(^"Root/BottomDock/ExplorationLegend/Margin/Label") as RichTextLabel
	var prompt := _hud.get_node_or_null(^"Root/BottomDock/Prompt") as RichTextLabel
	var start_index := int(party.call("active_index"))
	var before_text := label.text if label != null else ""
	var prompt_before := prompt.text if prompt != null else ""
	if label == null or not before_text.contains("Change Creature"):
		_failures.append("two-member fixture did not expose actionable LB in the legend")
	var call_out_source := _require_single_recall_presentation(label, prompt, false)
	await _tap_pad(JOY_BUTTON_LEFT_SHOULDER)
	var cycled_index := int(party.call("active_index"))
	if cycled_index == start_index:
		_failures.append("authored LB did not cycle the production party")
	await _tap_pad(JOY_BUTTON_RIGHT_SHOULDER)
	var ally: Node3D = null
	for _frame in ALLY_TIMEOUT_FRAMES:
		ally = director.call("ally_body") as Node3D
		if ally != null and is_instance_valid(ally):
			break
		await process_frame
	if ally == null or not is_instance_valid(ally):
		_failures.append("authored RB did not call out the selected creature")
	else:
		for _frame in INPUT_SETTLE_FRAMES:
			await process_frame
		_require_single_recall_presentation(label, prompt, true)
		await _tap_pad(JOY_BUTTON_RIGHT_SHOULDER)
		for _frame in ALLY_TIMEOUT_FRAMES:
			ally = director.call("ally_body") as Node3D
			if ally == null or not is_instance_valid(ally):
				break
			await process_frame
		if ally != null and is_instance_valid(ally):
			_failures.append("second authored RB did not put the creature away")
		else:
			for _frame in INPUT_SETTLE_FRAMES:
				await process_frame
			_require_single_recall_presentation(label, prompt, false)
	_control_audit = {
		"fixture": "Two installed creatures added through Game.make_creature and Party.add only for input audit; ally dismissed and party cleared before visual frames.",
		"party_cycle_button": JOY_BUTTON_LEFT_SHOULDER,
		"creature_recall_button": JOY_BUTTON_RIGHT_SHOULDER,
		"start_active_index": start_index,
		"cycled_active_index": cycled_index,
		"legend_before_inputs": before_text,
		"prompt_before_inputs": prompt_before,
		"call_out_presentation_source": call_out_source,
		"legend_after_inputs": label.text if label != null else "",
		"prompt_after_inputs": prompt.text if prompt != null else "",
		"ally_absent_after_second_recall": ally == null or not is_instance_valid(ally),
	}
	party.call("clear")
	game.set("objective_text", SHORT_AUTHORED_OBJECTIVE)
	for _frame in INPUT_SETTLE_FRAMES:
		await process_frame
	if label == null or label.text.contains("Call Out") or label.text.contains("Change Creature"):
		_failures.append("empty-party candidate did not remove unavailable creature actions before capture")


func _add_two_party_fixture() -> bool:
	var game := root.get_node_or_null(^"Game")
	var party: RefCounted = game.get("party") if game != null else null
	if party == null or _fixture_first == null or _fixture_second == null:
		return false
	party.call("clear")
	return bool(party.call("add", _fixture_first)) \
			and bool(party.call("add", _fixture_second))


## Recall can live in exactly one of two existing homes. The low-priority
## contextual offer wins when nothing nearby is more specific; otherwise the
## persistent legend is its fallback. Requiring the legend unconditionally
## would reject the intended prompt-ownership rule, while allowing both would
## reintroduce the duplicate this HUD already removed.
func _require_single_recall_presentation(label: RichTextLabel,
		prompt: RichTextLabel, creature_is_out: bool) -> String:
	var legend_has := label != null and label.text.contains(
		"Put Away" if creature_is_out else "Call Out")
	var playground_has := prompt != null and (
		prompt.text.contains(" away") if creature_is_out else prompt.text.contains("Call out"))
	var combat_prompt := _combat_prompt_text()
	var combat_has := combat_prompt.contains(" away") \
			if creature_is_out else combat_prompt.contains("Call out")
	var prompt_has := playground_has or combat_has
	if playground_has and combat_has:
		_failures.append("recall prompt is duplicated across PlaygroundHUD and CombatHUD")
	if legend_has == prompt_has:
		_failures.append("%s is present in %s recall surfaces; expected exactly one" % [
			"Put Away" if creature_is_out else "Call Out",
			"both" if legend_has else "zero",
		])
		return "invalid"
	return "legend" if legend_has else (
		"combat_prompt" if combat_has else "playground_prompt")


func _combat_prompt_text() -> String:
	var combat := _world.get_node_or_null(^"CombatHUD")
	var prompt := combat.get_node_or_null(^"Root/Prompt") as RichTextLabel \
			if combat != null else null
	return prompt.text if prompt != null and prompt.is_visible_in_tree() else ""


func _tap_pad(button: JoyButton) -> void:
	var down := InputEventJoypadButton.new()
	down.device = 0
	down.button_index = button
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	var up := InputEventJoypadButton.new()
	up.device = 0
	up.button_index = button
	up.pressed = false
	Input.parse_input_event(up)
	for _frame in INPUT_SETTLE_FRAMES:
		await process_frame


func _apply_prior_hud_control() -> void:
	var legend := _hud.get_node(^"Root/BottomDock/ExplorationLegend") as PanelContainer
	var legend_label := _hud.get_node(^"Root/BottomDock/ExplorationLegend/Margin/Label") as RichTextLabel
	var prompt_label := _hud.get_node(^"Root/BottomDock/Prompt") as RichTextLabel
	var normal: Color = UI_TOKENS.TEXT_PRIMARY
	var entries: Array[String] = [
		str(_hud.call("_legend_entry", "map", "Map", normal)),
		str(_hud.call("_legend_entry", "inventory", "Satchel", normal)),
		str(_hud.call("_legend_entry", "build_shortcut", "Build", normal)),
	]
	var prompt_owns_recall := prompt_label.text.contains("Call out") \
			or prompt_label.text.contains(" away")
	if not prompt_owns_recall:
		entries.append(str(_hud.call("_legend_entry", "creature_recall", "Call Out", normal)))
	var usable_count := 0
	var game := root.get_node_or_null(^"Game")
	var party: RefCounted = game.get("party") if game != null else null
	if party != null:
		for member: Variant in party.call("members"):
			var creature := member as RefCounted
			if creature != null and not bool(creature.get("fainted")) \
					and not bool(creature.get("resting")):
				usable_count += 1
	var change_tint: Color = normal if usable_count > 1 else UI_TOKENS.TEXT_MUTED
	entries.append(str(_hud.call("_legend_entry", "party_cycle", "Change Creature", change_tint)))
	legend_label.text = "     ".join(entries)
	var constants: Dictionary = (_hud.get_script() as Script).get_script_constant_map()
	var legend_size: Vector2 = constants.get("LEGEND_SIZE", Vector2(940.0, 76.0))
	legend.custom_minimum_size = legend_size

	var block := _hud.get(&"_objective_block") as Control
	var backing := _hud.get(&"_objective_backing") as PanelContainer
	var objective_label := _hud.get(&"_objective_text_label") as Label
	var eyebrow_row := float(constants.get("OBJECTIVE_EYEBROW_ROW", 36.0))
	var inset := float(constants.get("OBJECTIVE_INSET", 20.0))
	var sentence_font := float(constants.get("HUD_SENTENCE_FONT_SIZE", 32.0))
	var line_ratio := float(constants.get("SENTENCE_LINE_RATIO", 1.45))
	var max_width := float(constants.get("OBJECTIVE_MAX_WIDTH", 348.0))
	var max_lines := int(constants.get("OBJECTIVE_LINES", 4))
	var old_floor := eyebrow_row + inset * 2.0 \
			+ float(CONTROL_MIN_LINES) * sentence_font * line_ratio
	var shown_lines := mini(objective_label.get_line_count(), max_lines)
	var text_floor := float(CONTROL_MIN_LINES) * sentence_font * line_ratio
	var text_height := maxf(text_floor, float(shown_lines) * float(objective_label.get_line_height()))
	objective_label.size = Vector2(max_width - inset * 2.0, text_height)
	var old_height := maxf(old_floor, eyebrow_row + inset + text_height + inset)
	block.size = Vector2(max_width, old_height)
	backing.size = block.size


func _restore_candidate_hud() -> void:
	_hud.set_process(true)
	_hud.set("_legend_was_drawn", false)
	_hud.call("_update_exploration_legend")
	_hud.call("_layout_objective_block")


func _capture_prior_control(row: Dictionary, state_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var frame_id := "%s__%s__prior_hud_control" % [str(row.frame_id), state_name]
	var path := "%s/%s.png" % [_output_dir, frame_id]
	var record := row.duplicate(true)
	record["frame_id"] = frame_id
	record["file"] = path
	record["player_position"] = _vec3(_player.global_position)
	record["camera_position"] = _vec3(_camera.global_position)
	record["camera_transform"] = _transform(_camera.global_transform)
	var control_metrics := _hud_metrics("prior_control")
	control_metrics["party_state"] = state_name
	record["hud_layout"] = control_metrics
	_validate_prior_control_layout(control_metrics)
	if image == null or image.is_empty() or image.get_width() != root.size.x \
			or image.get_height() != root.size.y:
		_failures.append("%s: viewport image is empty or wrong-sized" % frame_id)
	elif FileAccess.file_exists(path):
		_failures.append("%s: refusing to overwrite retained control frame" % frame_id)
	elif image.save_png(path) != OK:
		_failures.append("%s: save_png failed" % frame_id)
	else:
		record["bytes"] = FileAccess.get_file_as_bytes(path).size()
		_control_records.append(record)
		print("HUD CONTROL CAPTURE %s -> %s" % [frame_id, path])


func _capture_two_party_candidate(row: Dictionary) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var frame_id := "%s__two_party_candidate" % str(row.frame_id)
	var path := "%s/%s.png" % [_output_dir, frame_id]
	var record := row.duplicate(true)
	record["frame_id"] = frame_id
	record["file"] = path
	record["player_position"] = _vec3(_player.global_position)
	record["camera_position"] = _vec3(_camera.global_position)
	record["camera_transform"] = _transform(_camera.global_transform)
	var metrics := _hud_metrics("candidate")
	metrics["party_state"] = "two_party"
	record["hud_layout"] = metrics
	_validate_candidate_layout(metrics, false)
	if image == null or image.is_empty() or image.get_width() != root.size.x \
			or image.get_height() != root.size.y:
		_failures.append("%s: viewport image is empty or wrong-sized" % frame_id)
	elif FileAccess.file_exists(path):
		_failures.append("%s: refusing to overwrite retained candidate frame" % frame_id)
	elif image.save_png(path) != OK:
		_failures.append("%s: save_png failed" % frame_id)
	else:
		record["bytes"] = FileAccess.get_file_as_bytes(path).size()
		_two_party_candidate_records.append(record)
		print("HUD TWO-PARTY CAPTURE %s -> %s" % [frame_id, path])


func _validate_candidate_layout(metrics: Dictionary, empty_party: bool) -> void:
	var legend_text := str(metrics.get("legend_text", ""))
	var legend_rect := metrics.get("legend_rect", {}) as Dictionary
	var objective_rect := metrics.get("objective_rect", {}) as Dictionary
	var legend_size := legend_rect.get("size", []) as Array
	var objective_size := objective_rect.get("size", []) as Array
	var constants: Dictionary = (_hud.get_script() as Script).get_script_constant_map()
	var prior_legend: Vector2 = constants.get("LEGEND_SIZE", Vector2(940.0, 76.0))
	var full_width := prior_legend.x
	var floor_height := float(constants.get("OBJECTIVE_BLOCK_HEIGHT", -1.0))
	if empty_party and (legend_text.contains("Call Out") \
			or legend_text.contains("Change Creature")):
		_failures.append("empty-party candidate frame retained an unavailable creature action")
	if not empty_party and not legend_text.contains("Change Creature"):
		_failures.append("two-party candidate frame omitted actionable Change Creature")
	if not empty_party:
		var prompt_text := str(metrics.get("prompt_text", "")) \
				+ str(metrics.get("combat_prompt_text", ""))
		var legend_has_recall := legend_text.contains("Call Out")
		var prompt_has_recall := prompt_text.contains("Call out")
		if legend_has_recall == prompt_has_recall:
			_failures.append("two-party candidate has recall in %s surfaces; expected exactly one" % [
				"both" if legend_has_recall else "zero",
			])
	if legend_size.size() != 2 or (empty_party and float(legend_size[0]) >= full_width - 0.5) \
			or (not empty_party and float(legend_size[0]) > full_width + 0.5):
		_failures.append("candidate legend did not settle within its expected content-fit width")
	var objective_label := _hud.get(&"_objective_text_label") as Label
	var shown_lines := mini(int(metrics.get("objective_line_count", 0)),
		int(constants.get("OBJECTIVE_LINES", 4)))
	var eyebrow := float(constants.get("OBJECTIVE_EYEBROW_ROW", 36.0))
	var inset := float(constants.get("OBJECTIVE_INSET", 20.0))
	var text_floor := floor_height - eyebrow - inset * 2.0
	var text_height := maxf(text_floor,
		float(shown_lines) * float(objective_label.get_line_height()))
	var expected_height := maxf(floor_height, eyebrow + inset + text_height + inset)
	metrics["one_line_floor_exercised"] = shown_lines == 1
	metrics["expected_objective_height"] = expected_height
	if shown_lines <= 0 or objective_size.size() != 2 \
			or absf(float(objective_size[1]) - expected_height) > 0.5:
		_failures.append("candidate objective did not settle to its measured %d-line height" % shown_lines)


func _validate_prior_control_layout(metrics: Dictionary) -> void:
	var legend_text := str(metrics.get("legend_text", ""))
	for required in ["Map", "Satchel", "Build", "Change Creature"]:
		if not legend_text.contains(required):
			_failures.append("prior control is missing baseline action '%s'" % required)
	var prompt_text := str(metrics.get("prompt_text", ""))
	var prompt_owns_recall := prompt_text.contains("Call out") \
			or prompt_text.contains(" away")
	if legend_text.contains("Call Out") == prompt_owns_recall:
		_failures.append("prior control did not restore baseline contextual recall suppression")
	var legend_rect := metrics.get("legend_rect", {}) as Dictionary
	var objective_rect := metrics.get("objective_rect", {}) as Dictionary
	var legend_size := legend_rect.get("size", []) as Array
	var objective_size := objective_rect.get("size", []) as Array
	var constants: Dictionary = (_hud.get_script() as Script).get_script_constant_map()
	var prior_legend: Vector2 = constants.get("LEGEND_SIZE", Vector2(940.0, 76.0))
	var prior_objective_floor := float(constants.get("OBJECTIVE_EYEBROW_ROW", 36.0)) \
			+ float(constants.get("OBJECTIVE_INSET", 20.0)) * 2.0 \
			+ float(CONTROL_MIN_LINES) * float(constants.get("HUD_SENTENCE_FONT_SIZE", 32.0)) \
				* float(constants.get("SENTENCE_LINE_RATIO", 1.45))
	var objective_label := _hud.get(&"_objective_text_label") as Label
	var shown_lines := mini(int(metrics.get("objective_line_count", 0)),
		int(constants.get("OBJECTIVE_LINES", 4)))
	var text_floor := float(CONTROL_MIN_LINES) \
			* float(constants.get("HUD_SENTENCE_FONT_SIZE", 32.0)) \
			* float(constants.get("SENTENCE_LINE_RATIO", 1.45))
	var prior_objective_height := maxf(prior_objective_floor,
		float(constants.get("OBJECTIVE_EYEBROW_ROW", 36.0))
			+ float(constants.get("OBJECTIVE_INSET", 20.0))
			+ maxf(text_floor, float(shown_lines) * float(objective_label.get_line_height()))
			+ float(constants.get("OBJECTIVE_INSET", 20.0)))
	if legend_size.size() != 2 or absf(float(legend_size[0]) - prior_legend.x) > 0.5 \
			or absf(float(legend_size[1]) - prior_legend.y) > 0.5:
		_failures.append("prior control did not restore the full %.1fx%.1f legend footprint" % [prior_legend.x, prior_legend.y])
	if objective_size.size() != 2 \
			or absf(float(objective_size[1]) - prior_objective_height) > 0.5:
		_failures.append("prior control did not restore the %.1fpx two-line objective floor" % prior_objective_height)


func _hud_metrics(mode: String) -> Dictionary:
	var legend := _hud.get_node(^"Root/BottomDock/ExplorationLegend") as Control
	var legend_label := _hud.get_node(^"Root/BottomDock/ExplorationLegend/Margin/Label") as RichTextLabel
	var block := _hud.get(&"_objective_block") as Control
	var objective_label := _hud.get(&"_objective_text_label") as Label
	return {
		"mode": mode,
		"legend_rect": _rect(legend.get_global_rect()),
		"legend_minimum_size": [legend.custom_minimum_size.x, legend.custom_minimum_size.y],
		"legend_text": legend_label.text,
		"legend_content_width": legend_label.get_content_width(),
		"prompt_text": (_hud.get_node(^"Root/BottomDock/Prompt") as RichTextLabel).text,
		"combat_prompt_text": _combat_prompt_text(),
		"objective_rect": _rect(block.get_global_rect()),
		"objective_text": objective_label.text,
		"objective_line_count": objective_label.get_line_count(),
		"objective_font_size": objective_label.get_theme_font_size("font_size"),
	}


func _rect(value: Rect2) -> Dictionary:
	return {"position": [value.position.x, value.position.y], "size": [value.size.x, value.size.y]}


func _write_manifest() -> void:
	_manifest["capture_tool"] = {
		"path": TOOL_PATH,
		"sha256": FileAccess.get_file_as_string(TOOL_PATH).sha256_text(),
	}
	_manifest["production_hud_sha256"] = FileAccess.get_file_as_string(HUD_PATH).sha256_text()
	_manifest["actual_control_audit"] = _control_audit
	_manifest["two_party_candidate_frames"] = _two_party_candidate_records
	_manifest["prior_hud_control_frames"] = _control_records
	_manifest["visual_frame_counts"] = {
		"empty_party_candidate": _records.size(),
		"two_party_candidate": _two_party_candidate_records.size(),
		"prior_hud_control": _control_records.size(),
		"actual_total": _records.size() + _two_party_candidate_records.size() \
				+ _control_records.size(),
		"expected_total": _planned.size() * 4,
	}
	_manifest["control_contract"] = (
		"Each time has an empty-party and a two-healthy-party candidate, and one prior-HUD control for each state. Each control freezes HUD polling and restores the prior fixed 940px legend, including the prior contextual-recall suppression rule, plus the prior two-line objective floor on the same settled production view, player, camera, frozen clock and party state. The shortest current authored objective is a disclosed visual fixture; its actual engine wrap count is recorded rather than assumed. No progression or save claim.")
	super._write_manifest()
