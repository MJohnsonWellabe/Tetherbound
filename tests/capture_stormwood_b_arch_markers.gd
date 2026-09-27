extends SceneTree

## F10#0 `stormwood_dark_arches` payoff capture: "Those physical routes become
## reusable and visible on known map" (WORLD, six Stormwood chains). Renders the
## production Stormwood HUD minimap and the full map tab after dark pair C is
## relit, so a code-blind judge can say whether the reopened road reads.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script res://tests/capture_stormwood_b_arch_markers.gd \
##     -- --out=res://shots/sw_b_f10_0

##
## Nothing places a marker by hand: the markers are written by the production
## StormwoodArchRuntime (`sync_dark_arch_map`) from the world's lit flags.
## Disclosed fixtures: the Rootgate and pair C lit facts are set directly in
## progression (the ledger's relight would set the same world flags after its
## cost), fog is revealed along the Rodline -> Lantern Hollow route a player
## walks to relight them, and the player body is placed by debug travel.
## Frames: `before_*` with pair C dark, `after_*` with it lit, each as a HUD
## minimap view near the Rodline arch and as the full map tab.

const GAME := preload("res://autoload/game_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const STORMWOOD_SCENE := preload("res://scenes/world/stormwood.tscn")
const FIELD := preload("res://scripts/world/stormwood_heightfield.gd")
const RULES := preload("res://scripts/world/stormwood_arch_rules.gd")
const TEST_SAVE_DIR := "user://stormwood_b_arch_marker_capture"
## A few metres south-east of the Rodline arch (c_rodline at [-720, 2260]) so
## the minimap shows the arch marker beside, not under, the player marker.
const STAND := Vector2(-690.0, 2300.0)
const ROUTE := [Vector2(-700.0, 2300.0), Vector2(-620.0, 2700.0), Vector2(-500.0, 3200.0),
	Vector2(-450.0, 3700.0), Vector2(-420.0, 4010.0)]

var _game: Node
var _world: Node3D
var _out := "res://ralph/reports/STORMWOOD/b/f10_0/frames"


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("needs a rendering display (xvfb-run)")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		_game = GAME.new()
		_game.name = "Game"
		root.add_child(_game)
	await process_frame
	_game.call("reset_for_new_game")
	_game.set("save_system", SAVE_GAME.new(TEST_SAVE_DIR))
	_game.get("local").set("character_id", "stormwood-b-arch-markers")
	_game.get("world").set("world_id", "stormwood-b-arch-markers-world")
	_game.set("current_realm", "stormwood")
	_game.call("bind_realm_map")
	_game.call("announce_realm", "meadows", "stormwood")
	var flags: RefCounted = _game.get("progression")
	for flag: String in ["stormwood:chapter_started", "stormwood:crown_reached", "stormwood:rootgate_released"]:
		flags.call("set_flag", flag)
	_world = STORMWOOD_SCENE.instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	var deadline := Time.get_ticks_msec() + 900000
	while not bool(_world.call("shell_build_complete")) and Time.get_ticks_msec() < deadline:
		await process_frame
	if not bool(_world.call("shell_build_complete")):
		push_error("Stormwood never finished building")
		quit(1)
		return
	var field := FIELD.new()
	var player := _world.get_node(^"Player") as Node3D
	var map: RefCounted = _game.call("bind_realm_map", "stormwood")
	for i in ROUTE.size() - 1:
		for step in 40:
			var p: Vector2 = (ROUTE[i] as Vector2).lerp(ROUTE[i + 1], float(step) / 40.0)
			map.call("mark_visited", Vector3(p.x, 0.0, p.y))
			map.call("reveal_circle", Vector3(p.x, 0.0, p.y), 110.0)
	player.global_position = Vector3(STAND.x, field.height_at(STAND.x, STAND.y) + 1.0, STAND.y)
	await _settle(180)
	print("markers before: %s" % str(_arch_markers(map)))
	await _save("before_minimap")
	await _save_map_tab("before_map")
	for id: String in ["c_rodline", "c_lantern"]:
		flags.call("set_flag", RULES.lit_flag(id))
	await _settle(180)
	var markers := _arch_markers(map)
	print("markers after: %s" % str(markers))
	if markers.size() != 2:
		push_error("expected two road markers after relighting pair C, got %d" % markers.size())
	await _save("after_minimap")
	await _save_map_tab("after_map")
	quit(0 if markers.size() == 2 else 1)


func _arch_markers(map: RefCounted) -> Array:
	var out: Array = []
	for entry: Dictionary in map.call("landmarks"):
		if str(entry.get("id", "")).begins_with("stormwood_arch_road_"):
			out.append("%s '%s' icon=%s" % [entry.id, entry.get("display_name", entry.get("name", "")), entry.get("icon", "")])
	return out


func _settle(frames: int) -> void:
	for i in frames:
		await process_frame


func _save(tag: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "%s/%s.png" % [_out, tag]
	root.get_texture().get_image().save_png(path)
	print("frame %s" % path)


func _save_map_tab(tag: String) -> void:
	var menu: CanvasLayer = _game.call("menu")
	menu.call("open", "map")
	# tab_map.gd's software-renderer texture upload race: give it time.
	await _settle(120)
	await _save(tag)
	menu.call("close")
	await _settle(30)
