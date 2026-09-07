extends SceneTree

## GATE3-HUD-0904: a lightweight HUD capture for the blind visual judge, built
## because `tools/capture_exploration_hud.gd` loads the full Meadows world
## (terrain, scatter, Burrow Warrens, the Hall) before it ever screenshots
## anything, and under this session's constrained sandbox that took over 45
## minutes and never finished. This tool skips the world build entirely --
## the same bare `Node3D` + `CharacterBody3D` scaffold
## `tests/smoke_hud_handheld_legibility.gd` already uses to exercise the real
## HUD scene -- so the frames are real rendered output from the actual
## `playground_hud.tscn`/`playground_hud.gd`, just over a plain grey world
## instead of real Meadows terrain. That is a fair trade for THIS review:
## every finding this lane is checking (safe-area margin, objective/action/
## interact hierarchy, health-text contrast, the interact pill's own size)
## is about the HUD's own geometry and colour, not about how it composites
## against grass.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/capture_hud_lightweight_0904.gd
##
## Frames, written to ralph/reports/G3-HUD-0904/shots/:
##   hud_full     - full HP/satiety, a five-slot party with one KO'd member
##   hud_lowhp    - health forced to 18% (danger lerp + pulse) and food to 22%
##   hud_interact - a short contextual prompt up ("Try the bridge gate")

const HUD_SCENE := preload("res://scenes/ui/playground_hud.tscn")
const PLAYER_VITALS := preload("res://scripts/player/player_vitals.gd")
const OUT_DIR := "res://ralph/reports/G3-HUD-0904/shots"
const SETTLE_FRAMES := 20

var _world: Node3D = null
var _hud: CanvasLayer = null
var _player: CharacterBody3D = null
var _vitals: RefCounted = null
var _written: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	await process_frame

	var game := root.get_node_or_null(^"Game")
	if game == null:
		push_error("Game autoload missing")
		quit(1)
		return
	var party: RefCounted = game.get("party")
	party.call("clear")
	var names := ["Biscuit", "Moss", "Ridge", "Pip", "Kite"]
	var species := ["terrapup", "bramblebun", "terrapup", "bramblebun", "terrapup"]
	for i in 5:
		var c: RefCounted = game.call("make_creature", species[i], names[i])
		if c != null:
			party.call("add", c)
	# One fainted member, matching the Gate 2 evidence route's own roster
	# shape (three KO'd of five) closely enough to judge the same defect.
	var members: Array = party.call("members")
	if members.size() >= 4:
		var m: RefCounted = members[3]
		m.take_damage(float(m.get("max_hp")) * 10.0)

	_world = Node3D.new()
	_world.name = "LightweightWorld"
	root.add_child(_world)
	current_scene = _world
	_player = CharacterBody3D.new()
	_player.name = "Player"
	_vitals = PLAYER_VITALS.new()
	_player.set("vitals", _vitals)
	_world.add_child(_player)
	_hud = HUD_SCENE.instantiate() as CanvasLayer
	_world.add_child(_hud)

	for i in 10:
		await process_frame
	root.size = Vector2i(1280, 800)
	for i in SETTLE_FRAMES:
		await process_frame

	# `_player.get("vitals")` (what `_process()` reads every frame) is a
	# no-op on a bare `CharacterBody3D` with no script attached -- there is
	# no such property to set, so the vitals cluster never saw real data via
	# that path. Driving `_update_vitals_cluster()` directly is the same call
	# `_process()` makes and exercises the same code (including this lane's
	# new `_fit_meter_value_chip()` calls), without needing a full player
	# controller script in this lightweight harness.
	_hud.call("_update_vitals_cluster", _vitals, 0.016)
	for i in SETTLE_FRAMES:
		await process_frame
	await _shoot("hud_full")

	_vitals.health = _vitals.max_health * 0.18
	_vitals.satiety = _vitals.max_satiety * 0.22
	# One real call registers the drop and starts the T_DAMAGE_FLASH white
	# flash; several more small-delta calls let that flash decay back to the
	# real HP_GREEN->DANGER lerp, the same way real per-frame `_process()`
	# ticks would -- a single call caught it still white, which is a capture
	# artefact of this harness, not the HUD's real sustained low-HP look.
	for i in 20:
		_hud.call("_update_vitals_cluster", _vitals, 0.02)
		await process_frame
	await _shoot("hud_lowhp")

	_vitals.health = _vitals.max_health
	_vitals.satiety = _vitals.max_satiety
	_hud.call("_update_vitals_cluster", _vitals, 0.016)
	if _hud.has_method("_on_prompt_changed"):
		_hud.call(
			"_on_prompt_changed",
			"[img=36x36]res://assets/ui/input_prompts/keyboard_r.png[/img]   Try the bridge gate"
		)
	# `objective_text` lives on the Game autoload, not the HUD -- the HUD
	# reads `_game.get("objective_text")` every frame (see
	# `playground_hud.gd`'s own `_process`).
	game.set("objective_text", "Reach South Bridge -- Team Tether holds the crossing.")
	for i in SETTLE_FRAMES:
		await process_frame
	await _shoot("hud_interact")

	print("wrote %d frame(s): %s" % [_written.size(), ", ".join(_written)])
	quit(0)


func _shoot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var path := "%s/%s.png" % [OUT_DIR, name]
	var err := img.save_png(path)
	if err == OK:
		_written.append(path)
	else:
		push_error("failed to save %s: %s" % [path, err])
