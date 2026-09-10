extends SceneTree

## A pre-reward-change tournament save already spent its one final payout but
## lacks recipe_saddle. Loading that state must make Riding Saddle visible in
## the production Craft panel without granting the item or any ingredients.
const SAVE := preload("res://scripts/save/save_game.gd")
const CRAFT_PANEL := preload("res://scripts/ui/craft_panel.gd")

var failures: Array[String] = []


func _init() -> void:
	run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		print("FAIL: ", message)


func run() -> void:
	var game := root.get_node("Game")
	game.reset_for_new_game()
	var saver := SAVE.new("user://legacy_saddle_recipe_%d/" % Time.get_ticks_usec())
	game.progression.set_flag("tournament_won")
	check(not game.progression.has("recipe_saddle"),
		"fixture must reproduce a tournament win written before the pattern reward")
	check(saver.save(game, 0), "legacy tournament state saved")

	game.reset_for_new_game()
	check(saver.load_slot(game, 0), "legacy tournament state loaded")
	check(game.progression.has("recipe_saddle"),
		"load did not reconcile the earned Riding Saddle pattern")
	check(game.inventory.count("saddle") == 0 and game.inventory.count("saddle_frame") == 0,
		"load granted crafted saddle parts instead of only their earned pattern")

	var panel := CRAFT_PANEL.new()
	root.add_child(panel)
	await process_frame
	panel.open()
	await process_frame
	var ids: Array = panel.get("_recipe_ids")
	check(ids.has("saddle"), "production Craft panel still hides Riding Saddle")
	check(ids.has("saddle_frame"), "production Craft panel hides the required Saddle Frame")
	var saddle_index := ids.find("saddle")
	var rows: Array = panel.get("_rows")
	check(saddle_index >= 0 and saddle_index < rows.size(),
		"Riding Saddle has no navigable production recipe row")
	panel.close()
	panel.queue_free()

	print("Legacy saddle recipe repair: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)
