extends "res://tests/test_case.gd"

## OP23-15 (owner playtest 2026-08-23): "Traits need explanations next to
## them" in the UI. `data/traits/traits.json` already carries a `description`
## per trait and `trait_db.gd::description()` already exposes it -- nothing
## called it. This is a pure UI-wiring gap, so the test asserts the wiring
## exists rather than duplicating trait_db's own data test.

func _traits_data() -> Dictionary:
	var file := FileAccess.open("res://data/traits/traits.json", FileAccess.READ)
	assert_true(file != null, "data/traits/traits.json is missing")
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func test_every_trait_has_a_non_empty_description() -> void:
	var data := _traits_data()
	var entries: Dictionary = data.get("traits", {})
	assert_true(entries.size() > 0, "traits.json has no trait entries")
	for id: String in entries.keys():
		var entry: Dictionary = entries[id]
		var description := str(entry.get("description", ""))
		assert_true(description.length() > 0,
			"trait '%s' has no description; OP23-15 needs one to show in the UI" % id)


func test_the_creature_detail_panel_builds_a_trait_description_label() -> void:
	var file := FileAccess.open("res://scripts/ui/tab_creatures.gd", FileAccess.READ)
	assert_true(file != null, "tab_creatures.gd is missing")
	if file == null:
		return
	var source := file.get_as_text()
	assert_true(source.contains("_detail_trait_desc"),
		"tab_creatures.gd has no _detail_trait_desc label; the trait name is "
		+ "still shown with nothing explaining what it does")


func test_the_trait_description_label_is_actually_filled_from_the_trait_rows() -> void:
	var file := FileAccess.open("res://scripts/ui/tab_creatures.gd", FileAccess.READ)
	if file == null:
		return
	var source := file.get_as_text()
	var start := source.find("func _describe(")
	assert_true(start >= 0, "tab_creatures.gd has no _describe")
	if start < 0:
		return
	var end := source.find("\nfunc ", start + 1)
	var body := source.substr(start, (end - start) if end > start else -1)
	assert_true(body.contains("_detail_trait_desc.text"),
		"_describe never assigns _detail_trait_desc.text; the label exists but "
		+ "stays blank")
	# F30#1 (ACCEPTANCE §6.2): inspect names the creature's active traits from
	# the one F30 pool (traits.gd rows, which carry each config description),
	# replacing the legacy trait_db primary/secondary lookup.
	assert_true(body.contains("TRAIT_RULES.rows(creature)") and body.contains("row.get(\"description\""),
		"_describe does not pull descriptions from the F30 trait rows, so "
		+ "the label would need its own (drifting) copy of the trait text")


func test_the_empty_slot_state_clears_the_trait_description() -> void:
	var file := FileAccess.open("res://scripts/ui/tab_creatures.gd", FileAccess.READ)
	if file == null:
		return
	var source := file.get_as_text()
	var start := source.find("func _describe(")
	var null_branch := source.find("if creature == null:", start)
	assert_true(null_branch >= 0, "_describe has no empty-slot branch")
	if null_branch < 0:
		return
	var end := source.find("\n\tvar species_id", null_branch)
	var body := source.substr(null_branch, (end - null_branch) if end > null_branch else -1)
	assert_true(body.contains("_detail_trait_desc.text = \"\""),
		"an empty slot leaves the previous creature's trait description on "
		+ "screen instead of clearing it")


## F30#1: the catch readout names the caught creature's active F30 traits
## (rolled, never a hidden bond secondary) and says so when it rolled none.
func test_the_catch_readout_names_rolled_traits_and_a_zero_roll() -> void:
	var readout := preload("res://scripts/ui/creature_trait_readout.gd")
	var rolled := preload("res://scripts/creatures/creature_species.gd").spawn("terrapup")
	rolled.set("trait_secondary", "hardy")
	rolled.set("traits_initialized", true)
	rolled.set("rolled_traits", ["bold", "hardy"])
	assert_eq(readout.summary(rolled), "Traits: Bold (Common), Hardy (Common)")
	var none := preload("res://scripts/creatures/creature_species.gd").spawn("terrapup")
	none.set("traits_initialized", true)
	none.set("rolled_traits", [])
	none.set("trait_secondary", "bold")
	assert_eq(readout.summary(none), "No traits", "an unrevealed bond secondary stays hidden")
