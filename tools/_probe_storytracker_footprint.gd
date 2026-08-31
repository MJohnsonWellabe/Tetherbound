extends SceneTree

## BACKLOG-HUD-STORYTRACKER. Owner playtest item 21: "Move the main story or
## just shrink it. It takes up too much space." Measures the real wrapped
## height of every authored tracked-objective line (`data/progression/
## objectives.json` via `quest_log.gd::main_entries()`) at the block's current
## dimensions and at candidate shrink dimensions, so the shrink is sized
## against real content instead of a guess -- same method
## `tools/_probe_objective_hint_height.gd` used for the hint card.
##
##   "$GODOT" --headless --path . --script tools/_probe_storytracker_footprint.gd

const QUEST_LOG := preload("res://scripts/world/quest_log.gd")
const PROGRESSION := preload("res://autoload/progression_state.gd")
const HUD := preload("res://scripts/ui/playground_hud.gd")

## (inner width, font size, eyebrow row, inset) candidates.
const CASES := [
	[308.0, 32, 36.0, 20.0],  # today: OBJECTIVE_MAX_WIDTH 348 - 2x OBJECTIVE_INSET 20
	[268.0, 32, 36.0, 16.0],  # narrower block, tighter inset
	[308.0, 32, 26.0, 16.0],  # same width, shorter eyebrow row + tighter inset
	[268.0, 32, 26.0, 16.0],  # both
]


func _init() -> void:
	_run()


func _run() -> void:
	for i in 4:
		await process_frame
	var log_reader: RefCounted = QUEST_LOG.new()
	var progression: RefCounted = PROGRESSION.new()

	var holder := Control.new()
	holder.size = Vector2(2000, 2000)
	root.add_child(holder)

	print("BACKLOG-HUD-STORYTRACKER footprint probe")
	print("block today: %.0f wide, %.0f inset, %.0f eyebrow row, %.0f tall (floor), font %d" % [
		HUD.OBJECTIVE_MAX_WIDTH, HUD.OBJECTIVE_INSET, HUD.OBJECTIVE_EYEBROW_ROW,
		HUD.OBJECTIVE_BLOCK_HEIGHT, HUD.HUD_SENTENCE_FONT_SIZE,
	])
	print("")

	var entries: Array = log_reader.call("main_entries", progression)
	var labels: Array = []
	for raw: Variant in entries:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var text := str((raw as Dictionary).get("label", ""))
		if not text.is_empty():
			labels.append(text)

	print("%d authored tracked lines" % labels.size())
	print("")

	for case_raw: Variant in CASES:
		var case := case_raw as Array
		var width := float(case[0])
		var font_size := int(case[1])
		var eyebrow_row := float(case[2])
		var inset := float(case[3])
		var worst_h := 0.0
		var worst_label := ""
		var total_h := 0.0
		var one_line := 0
		var two_line := 0
		var more_line := 0
		for text_raw: Variant in labels:
			var text := str(text_raw)
			var h := _measure(holder, text, width, font_size)
			var n := _lines(holder, text, width, font_size)
			total_h += h
			if h > worst_h:
				worst_h = h
				worst_label = text
			if n <= 1:
				one_line += 1
			elif n == 2:
				two_line += 1
			else:
				more_line += 1
		var block_h_worst := eyebrow_row + inset + worst_h + inset
		var block_h_mean := eyebrow_row + inset + (total_h / float(max(1, labels.size()))) + inset
		var full_width := width + inset * 2.0
		print("inner %.0f font %d eyebrow %.0f inset %.0f -> block %.0fx%.0f (worst text), %.0fx%.0f (mean text)  [1-line %d, 2-line %d, 3+line %d]  worst=%s" % [
			width, font_size, eyebrow_row, inset,
			full_width, block_h_worst, full_width, block_h_mean,
			one_line, two_line, more_line, worst_label.substr(0, 40),
		])
	quit()


func _lines(holder: Control, text: String, width: float, font_size: int) -> int:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.text = text
	label.custom_minimum_size = Vector2(width, 0.0)
	label.size = Vector2(width, 0.0)
	holder.add_child(label)
	var n := label.get_line_count()
	holder.remove_child(label)
	label.queue_free()
	return n


func _measure(holder: Control, text: String, width: float, font_size: int) -> float:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.text = text
	label.custom_minimum_size = Vector2(width, 0.0)
	label.size = Vector2(width, 0.0)
	holder.add_child(label)
	var h := float(label.get_line_count()) * float(label.get_line_height())
	holder.remove_child(label)
	label.queue_free()
	return h
