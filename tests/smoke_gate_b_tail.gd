extends SceneTree

## Gate B's TAIL, driven on its own from a synthesized post-village state.
##
##   godot --headless --path . --script tests/smoke_gate_b_tail.gd
##
## **Headless, never under xvfb** (docs/HANDOFF.md §10).
##
## `tests/smoke_gate_b_continuous.gd` is Gate B's evidence and plays the whole
## chapter opening in one pass. It has never got past the village -- so every
## beat AFTER the village had never executed inside it at all, and a defect in
## any of them would only ever have surfaced one per thirty-minute run.
##
## This file is the same tail, entered directly. It grants the state the
## village would have left behind -- a team, the tools, the materials
## `gate_a_material_route.gd`'s own TARGET_STOCK says that route supplies, and
## the player standing at the Village Square route entry -- and then plays
## `tests/helpers/gate_b_tail_segment.gd` for real from there.
##
## What is GRANTED is the walk and the gathering, both of which have their own
## harnesses. What is PLAYED is everything the tail is about: the house, the
## creature bed, the camp, the nights that put a team into condition, the
## marshal's entry gate reading that condition, the three fought rounds, and
## the objective that ends the chapter pointing at the South Bridge.

const WORLD_SCENE := "res://scenes/world/meadows_playground.tscn"
const TAIL := preload("res://tests/helpers/gate_b_tail_segment.gd")
const TOURNAMENT := preload("res://scripts/world/tournament.gd")
const CREATURE_PROGRESSION := preload("res://scripts/creatures/progression.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")

## Exactly what `tests/helpers/gate_a_material_route.gd` gathers. Granting more
## than the authored route supplies would hide a budget that does not cover the
## house, the bed and the camp.
const GRANTED_STOCK := {"wood": 57, "stone": 42, "fiber": 18}
## Tam's three tools and the Foreman's hammer (`camp_hammer_given`), on the
## quick bar. The hammer is not decoration: CONTROLLER-MAP retired
## `build_open`'s pad button, so hammer-in-hand plus Interact is the only way a
## controller opens the build catalogue at all.
const TOOLS := {"axe": &"hotbar_1", "pickaxe": &"hotbar_2", "knife": &"hotbar_3",
	"hammer": &"hotbar_4"}
## `gate_a_build_segment.gd` insists the paid segment begins at the Village
## Square route entry, reached by ordinary exploration. The walk is granted
## here; the road from there to the build patch is still walked.
const VILLAGE_SQUARE := Vector2(10.0, -10.0)
## Metres above the terrain the staged player is dropped from. See the drop
## itself for why they are dropped rather than placed.
const DROP_HEIGHT := 6.0
const SETTLE_FRAMES := 300
## The species the granted team is built from, same list the bracket smoke uses.
const TEAM_SPECIES: PackedStringArray = ["terrapup", "bramblebun", "mudsnout"]

var _failures: Array[String] = []
var _started_ms := 0
var _world: Node = null
var _game: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _progression: RefCounted = null


func _init() -> void:
	_run()


func _run() -> void:
	_started_ms = Time.get_ticks_msec()
	_world = (load(WORLD_SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for _i in SETTLE_FRAMES:
		await physics_frame
	if not _collect():
		_finish()
		return
	var skip_house := not OS.get_environment("GATEB_TAIL_SKIP_HOUSE").is_empty()
	if not await _stage_the_post_village_state(skip_house):
		_finish()
		return
	if skip_house:
		_note("ITERATION MODE (GATEB_TAIL_SKIP_HOUSE): the controller house is granted, "
			+ "not raised. This run is NOT tail evidence.")
	var result: Dictionary = await TAIL.new().run(self, _world, _game, _player, _rig,
		true, skip_house)
	for line: Variant in (result.get("transcript", []) as Array):
		_note("tail | %s" % str(line))
	for line: Variant in (result.get("failures", []) as Array):
		_fail(str(line))
	_finish()


func _collect() -> bool:
	_game = root.get_node_or_null(^"/root/Game")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	if _game == null or _player == null or _rig == null:
		_fail("the world booted without a Game autoload, a player or a camera rig")
		return false
	_progression = _game.get("progression")
	if _progression == null:
		_fail("the Game autoload has no progression store")
		return false
	return true


## Everything the village would have left behind, and nothing past it.
func _stage_the_post_village_state(skip_house: bool) -> bool:
	# A clean flag store, then only the beats the head of the run really writes.
	_progression.call("load_data", {})
	for flag: String in ["opening:beat:road", "opening:starter_granted", "road_gate_open",
			"home_materials_gathered", "tam_tools_given", "camp_hammer_given"]:
		_progression.call("set_flag", flag)

	# Out of the scripted opening, so its own prompts are not driving.
	var director := _world.get_node_or_null(^"EncounterDirector")
	var sequence := _world.find_child("SequenceDirector", true, false)
	if sequence != null and sequence.has_method("_set_beat"):
		sequence.call("_set_beat", "free_play")
	# And close whatever the opening left on screen. `sequence_director.gd::
	# _refresh_lockout()` turns the player's own locomotion off while a dialogue
	# box, the naming prompt or the starter picker is open, so a boot that stops
	# inside the wake conversation hands this file a player who cannot walk --
	# which is exactly what the first run of it reported, as "the controller
	# could not walk to the Practice Meadow road waypoint".
	for panel_name: String in ["DialoguePanel", "NamePrompt", "StarterPicker"]:
		var panel := _world.find_child(panel_name, true, false)
		if panel != null and panel.has_method("is_open") and bool(panel.call("is_open")) \
				and panel.has_method("close"):
			panel.call("close")
	for _i in 30:
		await physics_frame

	# The team: the director's own adopted starter plus enough bodies to field
	# the authored entry size, raised to the authored level.
	var party: RefCounted = _game.get("party")
	if director != null and director.call("ally_instance") == null:
		await director.call("adopt_starter", TEAM_SPECIES[0])
	var guard := 0
	while int(party.call("size")) < TOURNAMENT.required_party_size() and guard < 16:
		var made: RefCounted = _game.call("make_creature", TEAM_SPECIES[guard % TEAM_SPECIES.size()])
		if made != null:
			party.call("add", made)
		guard += 1
	if int(party.call("size")) < TOURNAMENT.required_party_size():
		_fail("could not field a team of %d; the party stopped at %d"
			% [TOURNAMENT.required_party_size(), int(party.call("size"))])
		return false
	var cfg: Dictionary = CREATURE_PROGRESSION.config()
	for i in int(party.call("size")):
		var creature: RefCounted = party.call("at", i)
		if creature != null:
			creature.call("set_level", TOURNAMENT.required_level(), cfg)
			creature.call("heal_fully")
	party.set("revision", int(party.get("revision")) + 1)

	# Tam's tools, on the quick bar where the gather route leaves them.
	var inventory: RefCounted = _game.get("inventory")
	var slot := 0
	for tool_id: String in TOOLS.keys():
		if int(inventory.call("count", tool_id)) <= 0:
			inventory.call("add", tool_id, 1)
		_game.call("assign_hotbar", slot, tool_id)
		slot += 1

	# The route's own stock, to the unit.
	for id: String in GRANTED_STOCK.keys():
		var have := int(inventory.call("count", id))
		var want := int(GRANTED_STOCK[id])
		if have > want:
			inventory.call("remove", id, have - want)
		elif have < want:
			inventory.call("add", id, want - have)

	_game.set("free_build", false)
	_game.set("pending_build", "")
	_game.set("equipped_tool", "")

	# ITERATION MODE never goes to the square at all: the tail segment stands
	# the player on the Practice Meadow build patch itself, and the square only
	# exists here because `gate_a_build_segment.gd` insists its paid run begins
	# at the route entry.
	if skip_house:
		_note("staged (iteration mode): team of %d at level %d, tools on the bar, %s"
			% [int(party.call("size")), TOURNAMENT.required_level(), _stock()])
		return true

	# Standing where the village walk would have left them.
	# DROPPED in, not placed. `ground_height_at()` answers for the TERRAIN, and
	# the Village Square has fourteen structures standing on it: a player put at
	# terrain+1 there can end up wedged inside a wall or under a floor, on_floor
	# and unable to move a centimetre in any direction -- measured, eight
	# headings, 0.00m each. Coming down from above lands them on whatever
	# surface is actually at the square, the way an arriving player would be.
	var y := float(_world.call("ground_height_at", VILLAGE_SQUARE.x, VILLAGE_SQUARE.y)) + DROP_HEIGHT
	_player.global_position = Vector3(VILLAGE_SQUARE.x, y, VILLAGE_SQUARE.y)
	_player.velocity = Vector3.ZERO
	_rig.set("yaw", 0.0)
	for _i in 180:
		await physics_frame
		if _player.is_on_floor():
			break
	for _i in 30:
		await physics_frame
	if not _player.is_on_floor():
		_fail("the staged player never landed at the Village Square route entry")
		return false
	# Does the staged player actually have the world? A run that stages a
	# position inside collision, or one still inside the opening's input
	# lockout, fails downstream as "the controller could not walk to X" and says
	# nothing about which.
	# Which way can the staged player actually go? The Village Square has
	# buildings in it, and a spot that is legal ground is not automatically a
	# spot with somewhere to walk: the first run of this file pushed the stick
	# forward, went nowhere, and could not say whether that was a lockout or a
	# wall. Sweeping the eight compass directions separates the two, and the
	# best of them is the direction the road out of the square is on.
	var moved := 0.0
	var report := ""
	for step in 8:
		var yaw := TAU * float(step) / 8.0
		_rig.set("yaw", yaw)
		for _i in 6:
			await physics_frame
		var before := _player.global_position
		if _motion_for(&"move_forward") == null:
			_fail("move_forward has no joypad axis; the controller map has lost the left stick")
			return false
		# Polled, like `player_controller.gd` reads it. See
		# `gate_a_build_segment.gd::_parse_move_stick()` for why a parsed
		# `InputEventJoypadMotion` is not enough here.
		Input.action_press(&"move_forward", 1.0)
		for _i in 30:
			await physics_frame
		if step == 0:
			var owner_node := INPUT_OWNER.current(self)
			var vitals: RefCounted = _player.get("vitals")
			_note(("with the stick held: get_vector=%s owner=%s velocity=%s carried=%s "
				+ "rig_basis=%s speed_scale=%s") % [
				str(Input.get_vector("move_left", "move_right", "move_forward", "move_back")),
				str(owner_node.name) if owner_node != null else "<none>",
				str(_player.velocity),
				str(_player.call("is_carried")) if _player.has_method("is_carried") else "?",
				str(_rig.call("planar_basis")) if _rig.has_method("planar_basis") else "<no planar_basis>",
				str(vitals.call("move_speed_scale")) if vitals != null and vitals.has_method("move_speed_scale") else "?"])
		Input.action_release(&"move_forward")
		for _i in 6:
			await physics_frame
		var delta := Vector2(_player.global_position.x - before.x,
			_player.global_position.z - before.z).length()
		report += " %d:%.2f" % [int(round(rad_to_deg(yaw))), delta]
		moved = maxf(moved, delta)
	_note("staged player displacement by heading (deg:m):%s; on_floor=%s at %s"
		% [report, str(_player.is_on_floor()), str(_player.global_position.round())])
	if moved < 0.5:
		var why := "locomotion_enabled=%s" % str(_player.call("locomotion_enabled")) \
			if _player.has_method("locomotion_enabled") else "locomotion state unknown"
		var modal := ""
		for panel_name: String in ["DialoguePanel", "NamePrompt", "StarterPicker", "BuildMenu"]:
			var panel := _world.find_child(panel_name, true, false)
			if panel != null and panel.has_method("is_open") and bool(panel.call("is_open")):
				modal += " %s open;" % panel_name
		_fail("the staged player cannot walk in ANY direction (best %.2fm) at %s (%s;%s paused=%s)"
			% [moved, str(_player.global_position.round()), why,
			modal if not modal.is_empty() else " no modal open;", str(paused)])
		return false
	# Back to the route entry the build segment insists on, on the ground the
	# sweep just proved is walkable.
	_player.global_position = Vector3(VILLAGE_SQUARE.x,
		_player.global_position.y + DROP_HEIGHT, VILLAGE_SQUARE.y)
	_player.velocity = Vector3.ZERO
	_rig.set("yaw", 0.0)
	for _i in 180:
		await physics_frame
		if _player.is_on_floor():
			break
	for _i in 20:
		await physics_frame

	_note("staged: team of %d at level %d, tools on the bar, wood %d / stone %d / fiber %d, at the Village Square"
		% [int(party.call("size")), TOURNAMENT.required_level(),
		int(inventory.call("count", "wood")), int(inventory.call("count", "stone")),
		int(inventory.call("count", "fiber"))])
	return true


func _stock() -> String:
	var inventory: RefCounted = _game.get("inventory")
	return "wood %d / stone %d / fiber %d" % [int(inventory.call("count", "wood")),
		int(inventory.call("count", "stone")), int(inventory.call("count", "fiber"))]


func _motion_for(action: StringName) -> InputEventJoypadMotion:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion:
			return event as InputEventJoypadMotion
	return null


func _note(line: String) -> void:
	print("GATE B TAIL +%.2fs — %s" % [(Time.get_ticks_msec() - _started_ms) / 1000.0, line])


func _fail(line: String) -> void:
	_failures.append(line)
	push_error(line)


func _finish() -> void:
	print("")
	if _failures.is_empty():
		print("gate B tail: OK — house, creature bed, camp, the nights, the entry gate, "
			+ "three fought rounds, and the objective pointing at the South Bridge")
		quit(0)
		return
	for line: String in _failures:
		print("gate B tail FAIL: %s" % line)
	quit(1)
