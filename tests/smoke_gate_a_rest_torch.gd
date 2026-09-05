extends SceneTree

## Gate A checkpoints 10-11: one production world, real controller edges.
##
##   godot --headless --path . --script tests/smoke_gate_a_rest_torch.gd
##
## Fixture setup directly arms free-build pieces so this smoke can stay focused;
## placement, creature-bed UI, player-bed interaction, and torch draw/stow all
## travel through their live InputMap-backed joypad paths.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const TORCH_CYCLES := 6

var _failures: Array[String] = []
var _world: Node
var _game: Node
var _player: CharacterBody3D
var _arbiter: Node
## CAMP-SHELTER-0903. `Game.take_pending_world_message()` is a one-shot,
## read-and-clear queue -- `playground_hud.gd::_update_world_message()`
## already polls it every frame in a real booted world (this one), so this
## test's own call reads whatever the HUD has not already drained on some
## earlier physics frame, usually "". Read off the HUD's own message Label
## instead, the same fix `smoke_combat.gd`'s own header comment already
## explains for the identical race.
var _message: Label


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame
	_game = root.get_node_or_null(^"Game")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_arbiter = get_first_node_in_group("interaction_arbiter")
	var hud := _world.get_node_or_null(^"PlaygroundHUD")
	_message = hud.find_child("Message", true, false) as Label if hud != null else null
	if _game == null or _player == null or _arbiter == null:
		_fail("Meadows did not stand up Game, Player, and InteractionArbiter")
		_report()
		return

	var director := _world.find_child("SequenceDirector", true, false)
	if director != null and director.has_method("_set_beat"):
		director.call("_set_beat", "free_play")
	var party: RefCounted = _game.get("party")
	if party == null:
		_fail("Game has no party")
		_report()
		return
	while int(party.call("size")) < 2:
		var creature: RefCounted = _game.call("make_creature", "terrapup" if int(party.call("size")) == 0 else "bramblebun")
		if creature == null or not bool(party.call("add", creature)):
			break
	if int(party.call("size")) < 2:
		_fail("could not prepare two real party creatures")
		_report()
		return

	_game.set("free_build", true)
	# Known clear-meadow coordinates also used by the modal/build regressions.
	var bed := await _place_fixture("creature_bed", Vector3(70.0, 0.0, 70.0))
	# OWNER-0902-CAMP-SPLIT: the "Rest until morning" prompt now lives on the
	# standalone bedroll, not a bundled camp. CAMP-SHELTER-0903: a bedroll can
	# no longer be PLACED anywhere but inside a tent's own footprint, so the
	# tent goes down first, at the exact same aim spot -- the player has not
	# moved or turned between the two fixture placements, so both ghosts
	# resolve to the same grid cell and the bedroll lands dead centre in the
	# tent it was just aimed at, same as a player pitching camp for real.
	var tent := await _place_fixture("tent", Vector3(100.0, 0.0, 80.0))
	var bedroll := await _place_fixture("bedroll", Vector3(100.0, 0.0, 80.0))
	if bed == null or tent == null or bedroll == null:
		_report()
		return

	await _exercise_creature_bed(bed, party)
	await _exercise_repeated_torch()
	await _exercise_player_rest(bedroll, bed, party)
	await _exercise_bedroll_without_tent_overhead()
	await _walk_up_the_loft_stair_and_sleep()
	_report()


func _place_fixture(id: String, at: Vector3) -> Node3D:
	await _teleport_to(at)
	_game.set("pending_build", id)
	for i in 18:
		await physics_frame
	var before: Array[Node] = get_nodes_in_group("placed_building")
	await _tap("build_place")
	for i in 24:
		await physics_frame
	await _tap("build_cancel")
	for node: Node in get_nodes_in_group("placed_building"):
		if before.has(node):
			continue
		if str(node.get_meta("building_id", "")) == id:
			print("fixture placed through controller: %s" % id)
			return node as Node3D
	_fail("controller placement produced no '%s' fixture" % id)
	return null


func _exercise_creature_bed(bed: Node3D, party: RefCounted) -> void:
	var creature: RefCounted = party.call("at", 0)
	var max_hp := float(creature.get("max_hp"))
	var damaged_hp := maxf(1.0, max_hp * 0.25)
	creature.set("hp", damaged_hp)
	creature.set("fainted", false)
	var prompt := bed.get_node_or_null(^"Interactable") as Node3D
	if prompt == null:
		_fail("placed creature bed has no interaction prompt")
		return
	await _teleport_near(prompt)
	if not await _wait_provider(prompt):
		_fail("creature-bed prompt never won arbitration")
		return
	await _tap("interact")
	var panel := await _wait_open_script("creature_bed_panel.gd")
	if panel == null:
		_fail("controller interact did not open the creature-bed panel")
		return
	await _tap("ui_accept")
	if not bool(creature.get("resting")) or int(bed.call("occupant_index")) != 0:
		_fail("focused controller A did not assign the creature to this bed")
	if bool(party.call("set_active", 0)):
		_fail("a resting creature could still be selected active")
	var rest_body := bed.get_node_or_null(^"RestingCreature") as Node3D
	if rest_body == null or not rest_body.visible:
		_fail("assigned creature has no visible resting body at the bed")
	await _tap("menu_cancel")
	if bool(panel.call("is_open")) or paused:
		_fail("creature-bed panel did not release pause on controller B")
	# Recovery uses elapsed live game time and correctly stands still while the
	# assignment modal pauses the world. Measure only after returning to play.
	for i in 35:
		await physics_frame
	var partial_hp := float(creature.get("hp"))
	if partial_hp <= damaged_hp or partial_hp >= max_hp:
		_fail("bed recovery was not gradual (%.2f -> %.2f / %.2f)" % [damaged_hp, partial_hp, max_hp])
	else:
		print("creature bed: visible body, gradual HP %.2f -> %.2f, active selection refused" % [damaged_hp, partial_hp])


func _exercise_repeated_torch() -> void:
	var inventory: RefCounted = _game.get("inventory")
	if inventory == null:
		_fail("Game has no inventory for the torch")
		return
	if int(inventory.call("find_slot", "torch")) < 0:
		inventory.call("add", "torch", 1)
	_game.set("equipped_tool", "")
	var look := get_first_node_in_group("day_cycle")
	if look == null or not look.has_method("apply_time"):
		_fail("world has no controllable day/night look")
		return
	look.call("apply_time", "night")
	for i in 5:
		await physics_frame
	var torch: Node = _player.get("torch")
	var hold: Node = _player.get("tool_hold")
	if torch == null or hold == null:
		_fail("Player has no production torch/tool-hold nodes")
		return

	# CONTROLLER-MAP, docs/owner/OWNER_DIRECTIVES_2026-08-22.md section 1: "Torch is
	# a tool that lives in the bar ('torch doesn't need a button')."
	# `torch_place` kept its keyboard key and lost its pad binding, so tapping
	# it here failed the InputMap lookup outright and every torch assertion
	# below fell over behind it. The torch is drawn and stowed the way every
	# other tool is: assigned to a quick slot and toggled with that slot's
	# button (`playground_hud.gd::_use_hotbar_slot`).
	if not bool(_game.call("assign_hotbar", 0, "torch")):
		_fail("could not put the torch on the quick bar, which is how it is drawn now")
		return

	for cycle in TORCH_CYCLES:
		await _tap("hotbar_1")
		for i in 8:
			await physics_frame
		var prop := torch.call("prop_node") as Node3D
		if str(_game.get("equipped_tool")) != "torch" or str(hold.call("equipped")) != "torch":
			_fail("torch cycle %d: controller draw did not equip torch" % (cycle + 1))
		elif prop == null or not prop.visible:
			_fail("torch cycle %d: draw produced no visible hand prop" % (cycle + 1))
		elif not bool(torch.call("is_on")):
			_fail("torch cycle %d: night draw did not restore light" % (cycle + 1))
		else:
			var flame_local: Vector3 = prop.call("flame_local_position") if prop.has_method("flame_local_position") else Vector3.ZERO
			var flame_world: Vector3 = prop.global_transform * flame_local
			if flame_world.y <= prop.global_position.y:
				_fail("torch cycle %d: flame anchor is not above its held prop origin" % (cycle + 1))
		var spot := torch.get_node_or_null(^"TorchLight") as Light3D
		var omni := torch.get_node_or_null(^"TorchOmni") as Light3D
		if spot == null or omni == null or not spot.visible or not omni.visible:
			_fail("torch cycle %d: both production light nodes were not active" % (cycle + 1))
		if torch.get_children().filter(func(child: Node) -> bool: return child.name == &"TorchLight").size() != 1 \
				or torch.get_children().filter(func(child: Node) -> bool: return child.name == &"TorchOmni").size() != 1:
			_fail("torch cycle %d: duplicate light nodes accumulated" % (cycle + 1))

		await _tap("hotbar_1")
		for i in 8:
			await physics_frame
		if not str(_game.get("equipped_tool")).is_empty() or not str(hold.call("equipped")).is_empty():
			_fail("torch cycle %d: controller stow left torch equipped" % (cycle + 1))
		if bool(torch.call("is_on")):
			_fail("torch cycle %d: stowed torch stayed lit" % (cycle + 1))
		if (torch.get_node(^"TorchLight") as Light3D).visible or (torch.get_node(^"TorchOmni") as Light3D).visible:
			_fail("torch cycle %d: stow left an invisible-source light active" % (cycle + 1))
	if _failures.is_empty():
		print("torch: %d physical draw/stow cycles restored prop and lights without duplicates" % TORCH_CYCLES)


func _exercise_player_rest(bedroll: Node3D, bed: Node3D, party: RefCounted) -> void:
	var creature: RefCounted = party.call("at", 0)
	var vitals: RefCounted = _player.get("vitals")
	var day_before := int(_game.get("day"))
	if vitals == null:
		_fail("Player has no vitals for rest verification")
		return
	vitals.set("health", 40.0)
	var prompt := bedroll.get_node_or_null(^"Interactable") as Node3D
	if prompt == null:
		_fail("placed bedroll has no Rest interaction")
		return
	await _teleport_near(prompt, Vector3.ZERO)
	if not await _wait_provider(prompt):
		_fail("camp Rest prompt never won arbitration")
		return
	await _tap("interact")
	for i in 150:
		await physics_frame
	if int(_game.get("day")) != day_before + 1:
		_fail("player-bed interaction did not advance to the next day")
	if float(vitals.get("health")) < float(vitals.get("max_health")):
		_fail("player-bed interaction did not restore player health")
	if bool(creature.get("resting")) or not bool(creature.get("rested")):
		_fail("overnight boundary did not complete the assigned creature rest")
	if float(creature.get("hp")) < float(creature.get("max_hp")):
		_fail("completed overnight creature rest did not fully heal")
	if not bool(party.call("set_active", 0)):
		_fail("completed rest did not return the creature to active eligibility")
	for i in 4:
		await process_frame
	if bed.get_node_or_null(^"RestingCreature") != null:
		_fail("completed rest left a duplicate resting body in the bed")
	else:
		print("player rest: day advanced, trainer healed, creature completed rest and returned active")


const PLAYER_BED := preload("res://scripts/build/player_bed.gd")
const CAMP_TENT := preload("res://scripts/build/camp_tent.gd")

## CAMP-SHELTER-0903: "you should have to have the tent over your head to
## sleep" is a LIVE footprint check (`player_bed.gd::_tent_overhead`), not a
## flag written once at placement -- and now that a bedroll can no longer be
## PLACED anywhere but inside a tent's own footprint, the only way left to
## reach "no tent overhead" is a bedroll that predates the rule (an existing
## save, or a tent dismantled out from under one already standing). Built
## directly rather than through the controller/menu, the same way
## `tools/gate_f/probe_bed_rest_sequence.gd` builds a standalone `creature_bed`
## to probe its own interaction without re-driving the whole placement flow --
## `restore_from_game` would do the identical direct `build_real()` call for a
## save like this, with nothing to check the loaded position against.
func _exercise_bedroll_without_tent_overhead() -> void:
	# Ground height, not a hard-coded 0.0 -- every other fixture in this file
	# reaches its actual Y through `_teleport_to`'s own `ground_height_at`
	# sample (or the live build placer's own ground-clamped resolve()). A
	# bedroll built directly, off by even a metre from the real terrain
	# height here, sits far enough from the player's own ground-sampled
	# teleport that its 2.6m Interactable range never reaches them -- the
	# root cause of this helper's own first failed run.
	var orphan_x := 106.0
	var orphan_z := 80.0
	var orphan_y := float(_world.call("ground_height_at", orphan_x, orphan_z)) \
		if _world.has_method("ground_height_at") else 0.0
	var orphan := PLAYER_BED.new()
	orphan.name = "OrphanBedroll"
	_world.add_child(orphan)
	orphan.global_position = Vector3(orphan_x, orphan_y, orphan_z)
	orphan.call("build_real")
	for i in 10:
		await physics_frame

	var vitals: RefCounted = _player.get("vitals")
	if vitals == null:
		_fail("Player has no vitals for the no-tent rest check")
		return
	vitals.set("health", 40.0)
	var day_before := int(_game.get("day"))

	var prompt := orphan.get_node_or_null(^"Interactable") as Node3D
	if prompt == null:
		_fail("a bedroll with no tent still needs its own Rest interaction (for a legacy save to load into)")
		return
	await _teleport_near(prompt, Vector3.ZERO)
	if not await _wait_provider(prompt):
		_fail("orphan bedroll's Rest prompt never won arbitration")
		return
	if _message != null:
		_message.text = ""
		_message.visible = false
	await _tap("interact")
	for i in 40:
		await physics_frame

	if int(_game.get("day")) != day_before:
		_fail("resting on a bedroll with no tent overhead advanced the day anyway")
	if float(vitals.get("health")) >= float(vitals.get("max_health")):
		_fail("resting on a bedroll with no tent overhead healed the trainer anyway")
	if _message == null:
		_fail("no HUD message strip found; cannot confirm the refusal reason reached the screen")
	else:
		var refusal := str(_message.text) if _message.visible else ""
		if not refusal.to_lower().contains("tent"):
			_fail("no on-screen reason named the missing tent (got '%s')" % refusal)
		else:
			print("bedroll with no tent overhead: rest refused, on-screen reason shown ('%s')" % refusal)

	# Same bedroll, no re-placement -- a tent pitched over it after the fact
	# (the live-check half of the same rule) must make it sleepable with no
	# migration step. Built directly at the orphan's own exact position
	# rather than through `_place_fixture` (which aims `PLACE_AHEAD` in front
	# of wherever the player is currently FACING, not at the literal
	# coordinate passed in) -- this is the live-check half of the rule under
	# test, not the placement flow, which the tent+bedroll placed together at
	# the top of this file already proves through the real controller path.
	var tent := CAMP_TENT.new()
	tent.name = "TentOverOrphan"
	_world.add_child(tent)
	tent.global_position = orphan.global_position
	tent.call("build_real")
	# `player_bed.gd::_tent_overhead` finds a tent by walking `PLACED_GROUP`
	# for `BUILDING_ID_META` -- both stamped by `build_placer.gd::
	# _spawn_building` on a real placement, neither of which this direct
	# construction goes through, so both are set by hand (same fix
	# `smoke_gateb_flags.gd`'s own equivalent direct-build needed).
	tent.add_to_group("placed_building")
	tent.set_meta("building_id", "tent")
	for i in 10:
		await physics_frame

	await _teleport_near(prompt, Vector3.ZERO)
	if not await _wait_provider(prompt):
		_fail("orphan bedroll's Rest prompt never re-won arbitration after a tent went up over it")
		return
	await _tap("interact")
	for i in 150:
		await physics_frame
	if int(_game.get("day")) != day_before + 1:
		_fail("a tent pitched after the fact did not make the same bedroll sleepable")
	elif float(vitals.get("health")) < float(vitals.get("max_health")):
		_fail("the now-sheltered bedroll advanced the day but did not heal the trainer")
	else:
		print("bedroll gained a tent overhead after the fact and rest now succeeds, unchanged")


func _tap(action: String) -> void:
	var mapped: InputEvent = _joy_event_for(action, true)
	if mapped == null:
		_fail("InputMap action '%s' has no joypad button or axis" % action)
		return
	Input.parse_input_event(mapped)
	await process_frame
	await process_frame
	Input.parse_input_event(_joy_event_for(action, false))
	for i in 5:
		await process_frame


func _joy_event_for(action: String, pressed: bool) -> InputEvent:
	if not InputMap.has_action(action):
		return null
	for event in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if button != null:
			var out := InputEventJoypadButton.new()
			out.device = 0
			out.button_index = button.button_index
			out.pressed = pressed
			return out
		var motion := event as InputEventJoypadMotion
		if motion != null:
			var out := InputEventJoypadMotion.new()
			out.device = 0
			out.axis = motion.axis
			out.axis_value = motion.axis_value if pressed else 0.0
			return out
	return null


## CL-G12, the owner: *"I've never been able to sleep in the loft bed."*
##
## Every existing check on that bed TELEPORTS onto the loft —
## `smoke_home_sleep.gd::_stand_beside()` sets `global_position` to the bed
## marker plus 1.5 m and lets it drop, and `smoke_gate_b_continuous`'s sleep
## beat does the same — so the passing tests were the finding, not a
## contradiction: the harness reached the bed by a path the player does not
## have. Driven up the stair instead, a real body froze on the top tread for
## 700 consecutive frames (`tools/gate_f/probe_loft_bed_climb.gd`).
##
## So this leg uses no teleport at all after the one that puts the body on
## the house's own ground floor: from there it holds the stick at the stair
## foot, at the stair head, and at the bed, exactly as a player does, and
## then presses the real interact button on whatever the arbiter is actually
## offering. It fails if the body cannot climb, if the bed is not what wins
## the prompt when it gets there, or if pressing it does not pass the night.
const LOFT_WALK_FRAMES := 900


func _walk_up_the_loft_stair_and_sleep() -> void:
	var house: Node3D = _world.get_node_or_null(^"GrandpaHouse") as Node3D
	if house == null:
		_fail("the Meadows stood up no GrandpaHouse; the loft bed cannot be reached")
		return
	# `set_sleep_enabled` shares the front door's own beat gate, and the
	# director was put in `free_play` at the top of this run — but a beat set
	# directly does not re-run `_refresh_door_gate()` until its next frame, so
	# read the prompt's state rather than assuming it.
	var prompt: Node3D = house.get_node_or_null(^"SleepPrompt") as Node3D
	if prompt == null:
		_fail("the loft bed carries no Sleep interactable at all")
		return
	for i in 10:
		await physics_frame
	if not bool(prompt.get("enabled")):
		_fail("the loft bed's Sleep prompt is disabled in free play")
		return

	# The only teleport: onto the ground floor, where the opening leaves the
	# player. Everything after this is stick input.
	var start: Vector3 = house.global_transform * Vector3(1.4, 0.4, 1.2)
	_player.global_position = start
	_player.velocity = Vector3.ZERO
	for i in 20:
		await physics_frame

	var reached_foot := await _hold_stick_at(house.call("marker", "stairs_bottom"), 0.45)
	if not reached_foot:
		_fail("a body on the ground floor holding the stick at the stair foot never arrived")
		return
	var reached_loft := await _hold_stick_at(house.call("marker", "stairs_top"), 0.9)
	var loft_top: float = float(house.get_script().get_script_constant_map()["LOFT_TOP"])
	var local: Vector3 = house.global_transform.affine_inverse() * _player.global_position
	if not reached_loft or local.y < loft_top - 0.15:
		_fail("a body holding the stick at the stair head could not climb onto the loft "
			+ "(ended at house-local %s, loft floor is y=%.2f)"
			% [str(local.snapped(Vector3.ONE * 0.01)), loft_top])
		return
	print("climbed the loft stair on stick input alone: house-local %s"
		% str(local.snapped(Vector3.ONE * 0.01)))

	if not await _hold_stick_at(house.call("marker", "bed"), 1.6):
		_fail("a body on the loft holding the stick at the bed never got within 1.6m of it")
		return
	if not await _wait_provider(prompt):
		_fail("standing at the loft bed after walking there, the game offers '%s', not the bed"
			% str(_arbiter.call("prompt")))
		return

	var progression: RefCounted = _game.get("progression")
	progression.call("set_flag", "player_slept_at_home", false)
	var day_before := int(_game.get("day"))
	await _tap("interact")
	# night_rest.gd's fade is 1.2s and the night passes at its midpoint.
	for i in 150:
		await physics_frame
	var day_after := int(_game.get("day"))
	if day_after <= day_before:
		_fail("pressing interact at the loft bed, walked to on foot, did not pass the night "
			+ "(day %d -> %d)" % [day_before, day_after])
	else:
		print("slept in Grandpa's loft bed after walking up the stair: day %d -> %d"
			% [day_before, day_after])


## Hold the stick straight at a world point until the body is within
## `close_enough` metres of it horizontally. No navigator, no detours: the
## question is whether the route is walkable at all, which is exactly the
## question `tools/gate_f/probe_fence_corner_trailgate_0903.gd` settled for
## the TrailGate corner.
func _hold_stick_at(point: Vector3, close_enough: float) -> bool:
	var rig := _world.get_node_or_null(^"CameraRig") as Node3D
	for i in LOFT_WALK_FRAMES:
		var to := point - _player.global_position
		if Vector2(to.x, to.z).length() <= close_enough:
			_release_stick()
			for j in 6:
				await physics_frame
			return true
		to.y = 0.0
		var direction := to.normalized()
		if rig != null:
			var basis: Basis = rig.call("planar_basis")
			direction = basis.inverse() * direction
		_push_stick(Vector2(clampf(direction.x, -1.0, 1.0), clampf(direction.z, -1.0, 1.0)))
		await physics_frame
	_release_stick()
	for j in 6:
		await physics_frame
	return Vector2(point.x - _player.global_position.x,
		point.z - _player.global_position.z).length() <= close_enough


func _push_stick(stick: Vector2) -> void:
	_axis("move_right", clampf(stick.x, 0.0, 1.0))
	_axis("move_left", clampf(-stick.x, 0.0, 1.0))
	_axis("move_back", clampf(stick.y, 0.0, 1.0))
	_axis("move_forward", clampf(-stick.y, 0.0, 1.0))


func _release_stick() -> void:
	_push_stick(Vector2.ZERO)


func _axis(action: String, strength: float) -> void:
	var name_key := StringName(action)
	if not InputMap.has_action(name_key):
		return
	if strength <= 0.001:
		Input.action_release(name_key)
	else:
		Input.action_press(name_key, strength)
	for event in InputMap.action_get_events(name_key):
		var motion := event as InputEventJoypadMotion
		if motion == null:
			continue
		var out := InputEventJoypadMotion.new()
		out.device = 0
		out.axis = motion.axis
		out.axis_value = signf(motion.axis_value) * strength
		Input.parse_input_event(out)
		return


func _teleport_to(at: Vector3) -> void:
	var y := float(_world.call("ground_height_at", at.x, at.z)) if _world.has_method("ground_height_at") else _player.global_position.y
	_player.global_position = Vector3(at.x, y + 0.2, at.z)
	_player.velocity = Vector3.ZERO
	for i in 14:
		await physics_frame


func _teleport_near(prompt: Node3D, offset: Vector3 = Vector3(0.25, 0.0, 0.25)) -> void:
	var at := prompt.global_position + offset
	var y := float(_world.call("ground_height_at", at.x, at.z)) if _world.has_method("ground_height_at") else at.y
	_player.global_position = Vector3(at.x, y + 0.2, at.z)
	_player.velocity = Vector3.ZERO
	for i in 18:
		await physics_frame


func _wait_provider(provider: Node) -> bool:
	for i in 45:
		await physics_frame
		if _arbiter.call("winning_provider") == provider:
			return true
	return false


func _wait_open_script(suffix: String) -> Node:
	for i in 45:
		await process_frame
		for node: Node in root.get_children():
			var script := node.get_script() as Script
			if script != null and str(script.resource_path).ends_with(suffix) \
					and node.has_method("is_open") and bool(node.call("is_open")):
				return node
	return null


func _fail(message: String) -> void:
	_failures.append(message)
	print("FAIL: %s" % message)


func _report() -> void:
	if _game != null:
		_game.set("free_build", false)
		_game.set("pending_build", "")
	if paused:
		paused = false
	print("")
	if _failures.is_empty():
		print("Gate A rest/torch smoke passed")
		quit(0)
		return
	for failure in _failures:
		print("  FAIL: %s" % failure)
	quit(1)
