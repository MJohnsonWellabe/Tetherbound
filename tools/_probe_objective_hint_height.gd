extends SceneTree

## HIST-036 / OBJECTIVE-HINT-ON-HUD. The register's own instruction to whoever
## takes this item is "Measure the wrapped height first" -- it is the whole
## reason the item was left open rather than done, and the 170px -> "nearly
## 300" figure in the backlog is an estimate ("about twenty characters to a
## line"), not a measurement. This probe replaces the estimate.
##
##   "$GODOT" --headless --path . --script tools/_probe_objective_hint_height.gd
##
## Headless is correct here: nothing is rasterised. Label text metrics come
## from the font's own shaping, which does not need a rendering driver, and
## `get_content_height()` on a Label with a real size and `AUTOWRAP_WORD_SMART`
## is the same number the HUD would lay out.
##
## Measures every authored `how` string in `data/progression/objectives.json`,
## resolved through `quest_log.gd::hint_text()` so the `{action}` placeholders
## are the real bound button names and not the raw braces.

const QUEST_LOG := preload("res://scripts/world/quest_log.gd")
const PROGRESSION := preload("res://autoload/progression_state.gd")
const HUD := preload("res://scripts/ui/playground_hud.gd")

## (inner width, font size) pairs. The first is what the block is today:
## `OBJECTIVE_MAX_WIDTH` (420) less two `OBJECTIVE_INSET` (20). The rest are
## the only two levers that exist -- more width or a smaller font -- with 35
## the floor `smoke_hud_handheld_legibility.gd` allows
## (16.0 / (1280.0/1920.0) / 0.7 = 34.3).
const CASES := [
	# The objective block as it stands: `OBJECTIVE_MAX_WIDTH` (420) less two
	# `OBJECTIVE_INSET` (20), at the HUD's readable size.
	[380.0, 38],
	# The two levers the block itself has -- drop to the legibility floor
	# (16.0 / (1280.0/1920.0) / 0.7 = 34.3, so 35), or widen left as far as the
	# central third of the canvas allows (x 1280 to x 1864, less the insets).
	[380.0, 35],
	[544.0, 38],
	[544.0, 35],
	# A CENTRED card instead, the shape `_build_region_banner()` already uses
	# for a timed announcement -- 800 is that banner's own authored width, and
	# 1100/1400 are what the 56px safe inset would still allow.
	[800.0, 38],
	[1100.0, 38],
	[1400.0, 38],
	# The centre gutter: the card cannot be full width, because the left and
	# right HUD columns both run the height of the screen. These are the
	# candidate inner widths inside that gutter.
	[850.0, 38],
	[898.0, 38],
	[950.0, 38],
	[860.0, 38],
	[860.0, 35],
	[860.0, 36],
]

## What the shipped card uses -- kept here so the probe measures the real
## thing rather than a nearby one. Mirrors `playground_hud.gd`'s own
## `OBJECTIVE_HINT_*` constants.
const CARD_INNER := 1100.0
const CARD_FONT := 38
const CARD_GAP := 10.0
const CARD_INSET := 20.0


func _init() -> void:
	# `_run()` is a coroutine and this is not awaited, the same shape every
	# smoke test in `tests/` uses: `_init()` cannot await, so it starts the
	# run and returns, and the tree drives the rest.
	_run()


func _run() -> void:
	# Settle before touching the tree at all. Adding a Control to `root` from
	# inside `_init()` (before the headless window has finished its own setup)
	# hangs this script with no output -- paid for once already on this probe.
	for i in 4:
		await process_frame
	var log_reader: RefCounted = QUEST_LOG.new()
	var progression: RefCounted = PROGRESSION.new()

	var holder := Control.new()
	holder.size = Vector2(2000, 2000)
	root.add_child(holder)

	print("HIST-036 objective-hint wrapped-height probe")
	print("block today: %.0f wide, %.0f inset, %.0f tall, font %d" % [
		HUD.OBJECTIVE_MAX_WIDTH, HUD.OBJECTIVE_INSET,
		HUD.OBJECTIVE_BLOCK_HEIGHT, HUD.HUD_READABLE_FONT_SIZE,
	])
	print("")

	# `main_entries()` returns the presentation shape -- `{label, done, how}` --
	# with `how` already run through `hint_text()`, so this measures exactly
	# the strings a caller would draw.
	var entries: Array = log_reader.call("main_entries", progression)
	var rows: Array = []
	for raw: Variant in entries:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var entry := raw as Dictionary
		var hint := str(entry.get("how", ""))
		if hint.is_empty():
			continue
		rows.append({"label": str(entry.get("label", "?")), "hint": hint})

	print("%d authored hints" % rows.size())
	print("")

	for case_raw: Variant in CASES:
		var case := case_raw as Array
		var width := float(case[0])
		var font_size := int(case[1])
		var worst := 0.0
		var worst_flag := ""
		var total := 0.0
		for row_raw: Variant in rows:
			var row := row_raw as Dictionary
			var h := _measure(holder, str(row["hint"]), width, font_size)
			total += h
			if h > worst:
				worst = h
				worst_flag = str(row["label"])
		print("inner width %.0f, font %d: worst hint %.0f px (%s), mean %.0f px" % [
			width, font_size, worst, worst_flag, total / float(max(1, rows.size())),
		])
	print("")

	# Per-hint detail at the block as it stands today, so the report names
	# which rungs are the expensive ones rather than only the worst.
	print("per-hint at inner width 380, font 38:")
	for row_raw: Variant in rows:
		var row := row_raw as Dictionary
		var h := _measure(holder, str(row["hint"]), 380.0, 38)
		var n := _lines(holder, str(row["hint"]), 380.0, 38)
		print("  %6.0f px  %d lines  %-38s  %s" % [h, n, str(row["label"]).substr(0, 38), str(row["hint"]).substr(0, 50)])

	# And the tracked LINE's own height, which the hint stacks under.
	print("")
	print("tracked lines at inner width 380, font 38:")
	var worst_line := 0.0
	var worst_line_text := ""
	for raw2: Variant in entries:
		if typeof(raw2) != TYPE_DICTIONARY:
			continue
		var label_text := str((raw2 as Dictionary).get("label", ""))
		if label_text.is_empty():
			continue
		var h2 := _measure(holder, label_text, 380.0, 38)
		if h2 > worst_line:
			worst_line = h2
			worst_line_text = label_text
	print("  worst tracked line %.0f px  (%s)" % [worst_line, worst_line_text])

	# The number the shipped card is actually sized against: the tracked line
	# and its hint stacked, at the centred card's inner width, plus the card's
	# own insets and the gap between the two.
	print("")
	print("centred card at inner width %.0f, font %d (line + gap %.0f + hint + 2x inset %.0f):" % [
		CARD_INNER, CARD_FONT, CARD_GAP, CARD_INSET,
	])
	var worst_card := 0.0
	var worst_card_label := ""
	for raw3: Variant in entries:
		if typeof(raw3) != TYPE_DICTIONARY:
			continue
		var e := raw3 as Dictionary
		var line_text := str(e.get("label", ""))
		var hint := str(e.get("how", ""))
		if line_text.is_empty() or hint.is_empty():
			continue
		var total := CARD_INSET * 2.0 + CARD_GAP \
				+ _measure(holder, line_text, CARD_INNER, CARD_FONT) \
				+ _measure(holder, hint, CARD_INNER, CARD_FONT)
		if total > worst_card:
			worst_card = total
			worst_card_label = line_text
	print("  worst card %.0f px tall  (%s)" % [worst_card, worst_card_label])

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
	# `Label` has no `get_content_height()` in Godot 4.7 -- verified on a bare
	# Label, the method does not exist; `RichTextLabel` is the one that has it.
	# Lines x line height is the number.
	var h := float(label.get_line_count()) * float(label.get_line_height())
	holder.remove_child(label)
	label.queue_free()
	return h
