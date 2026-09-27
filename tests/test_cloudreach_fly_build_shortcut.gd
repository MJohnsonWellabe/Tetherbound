extends "res://tests/test_case.gd"

## X03 (F06#2 flight path): LT is both `fly_descend` (fly_controller.gd) and
## `build_shortcut` (project.godot). Pulling LT to descend mid-flight used to
## open the build catalogue too. Flight and carries now own the shared trigger
## through `input_owner.gd::TRAVERSAL_GROUP`, and the HUD's `build_shortcut`
## poll asks `INPUT_OWNER.traversal()` before opening the catalogue.

const FLY := preload("res://scripts/player/fly_controller.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const HUD_PATH := "res://scripts/ui/playground_hud.gd"


func _stub_player() -> CharacterBody3D:
	var script := GDScript.new()
	script.source_code = "extends CharacterBody3D\nvar carried := false\nfunc is_carried() -> bool:\n\treturn carried\n"
	script.reload()
	var player := CharacterBody3D.new()
	player.set_script(script)
	return player


## The runner calls tests before any SceneTree exists, so the owner answer is
## asked of the controller directly and the group join is read from `setup()`.
func test_flight_and_carry_own_the_shared_trigger() -> void:
	var player := _stub_player()
	var fly: Node = FLY.new()
	fly.set("_player", player)
	fly.set("state", "grounded")
	assert_false(bool(fly.call("owns_traversal_input")), "on foot, LT is free for build_shortcut")
	for flying: String in ["glide", "climb", "descent", "exhausted"]:
		fly.set("state", flying)
		assert_true(bool(fly.call("owns_traversal_input")), "%s owns the shared trigger" % flying)
	fly.set("state", "grounded")
	player.set("carried", true)
	assert_true(bool(fly.call("owns_traversal_input")), "a carried trainer's LT is not a world verb")
	player.set("carried", false)
	assert_false(bool(fly.call("owns_traversal_input")))
	assert_eq(INPUT_OWNER.traversal(null), null, "no tree, no owner")
	fly.free()
	player.free()


func test_the_fly_controller_joins_the_traversal_group_not_the_panel_group() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/player/fly_controller.gd")
	var setup := source.substr(source.find("func setup("), 200)
	assert_true(setup.contains("add_to_group(INPUT_OWNER.TRAVERSAL_GROUP)"), "setup() joins the traversal owner group")
	assert_false(source.contains("add_to_group(INPUT_OWNER.GROUP)"),
		"flight never joins the panel group: player_controller.gd would freeze its steering")


func test_hud_build_shortcut_asks_the_traversal_owner() -> void:
	var source := FileAccess.get_file_as_string(HUD_PATH)
	var at := source.find("Input.is_action_just_pressed(&\"build_shortcut\")")
	assert_true(at >= 0, "the HUD polls build_shortcut")
	var branch := source.substr(at, source.find("BUILD_MENU.get_or_make", at) - at)
	assert_true(branch.contains("INPUT_OWNER.traversal(get_tree()) == null"),
		"the build_shortcut branch refuses while flight or a carry owns LT: " + branch)
