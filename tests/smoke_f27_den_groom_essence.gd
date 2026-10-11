extends "res://tests/smoke_f32_material_sites.gd"

## F27#1 actual-path witness for the capped daily care trickle: a paid Den is
## placed through build_place, reached by the physical controller driver,
## opened with `interact`, and a creature's Groom button is confirmed with
## `ui_accept` (craft_panel -> Session.homestead_submit_action("groom") ->
## foundation groom -> essence.stage_care). Every payout and refusal is read
## from the isolated owner/world saves on disk.
##
##   godot --headless --path . --script tests/smoke_f27_den_groom_essence.gd
##
## 1. Groom creature A: disk gains care_per_grooming of A's type essence, with
##    an accepted groom row and A's care receipt.
## 2. Groom A again the same day: refused, nothing paid.
## 3. Groom B: pays; today's care reaches care_daily_character_cap.
## 4. Groom C: refused daily_care_cap, nothing paid.
## 5. Game.advance_day() and a settle: groom C pays.
##
## Disclosed fixtures (as smoke_f27_essence_node / smoke_f32_forge_plates):
## isolated save dir, three owned creatures of different types, opening
## free-play, the Den's build cost added to the satchel, a stance beside the
## homestead yard. The five-creature rule leaves no sixth creature to reach
## the cap by grooming, so today's earlier care is SEEDED as receipts for
## creatures released earlier that day (cap - 2 of them), disclosed. Button
## focus is set on the Groom button; the confirm is a real ui_accept tap.
## Not claimed: two-peer, earned route, visuals.

const DELIVERY := preload("res://scripts/net/homestead_building_delivery.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const STANCE := Vector2(-6.0, 22.0)
const TEAM := ["terrapup", "ripplet", "sparkit"]
var _results: Array = []


func _run() -> void:
	_realm = "meadows"
	_output = "user://f27_den_groom_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	DirAccess.make_dir_recursive_absolute(_output)
	create_timer(900.0).timeout.connect(func() -> void:
		if not _finished:
			_check(false, "native watchdog expired")
			_finish())
	_game = root.get_node_or_null(^"Game")
	_saver = SAVE.new(_output.path_join("working"))
	_game.set("save_system", _saver)
	_game.call("reset_for_new_game")
	_game.set("current_realm", _realm)
	_game.get("local").set("character_id", "f27-den-owner")
	_game.get("world").set("world_id", "f27-den-world")
	for species: String in TEAM: _game.get("party").call("add", SPECIES.spawn(species))
	_game.get("progression").call("set_flag", "opening:beat:free_play")
	var cfg := ESSENCE.config()
	var day := int(_game.get("world").day)
	var personal: Dictionary = _game.get("local").get("redesign_character")
	for i in int(cfg.care_daily_character_cap) - 2:
		var released := "creature-" + ("f27-released-%d" % i).sha256_text().left(32)
		personal.transaction_receipts.append("care:%s:%d:%s:%d" % ["f27-den-owner", day, released, int(cfg.care_per_grooming)])
	_game.get("local").set("redesign_character", personal)
	if not _check(change_scene_to_file(SCENES[_realm]) == OK, "request actual Meadows scene"):
		_finish(); return
	for frame in 2400:
		await process_frame
		if current_scene != null and current_scene.has_method("shell_build_complete") \
			and current_scene.call("shell_build_complete") == true:
			_world = current_scene as Node3D
			break
	if not _check(_world != null, "Meadows procedural build completed"):
		_finish(); return
	_player = _game.call("find_player") as CharacterBody3D
	if not _check(_player != null and _world.get_node_or_null(^"BuildPlacer") != null, "player and BuildPlacer exist"):
		_finish(); return
	_game.get("session").connect("homestead_action_completed", func(op: String, intent: Dictionary, result: Dictionary) -> void:
		if op == "groom": _results.append({"intent": intent.duplicate(true), "result": result.duplicate(true)}))
	_driver = DRIVER.new()
	_driver.set("_tree", self)
	_driver.set("_world", _world)
	_driver.set("_game", _game)
	_driver.set("_player", _player)
	var rig := _world.get_node_or_null(^"CameraRig") as Node3D
	_driver.set("_rig", rig)
	_driver.set("_arbiter", get_first_node_in_group(&"interaction_arbiter"))
	if not _check(rig != null and _driver.get("_arbiter") != null and _driver.call("_resolve_move_bindings") == true,
		"physical controller driver resolves production camera and arbiter"):
		_finish(); return
	_driver.set("_nav", NAV.new(self, _player, rig, Callable(_driver, "_send_stick")))
	var ground := float(_world.call("ground_height_at", STANCE.x, STANCE.y))
	_player.global_position = Vector3(STANCE.x, (ground if is_finite(ground) else 0.9) + 0.4, STANCE.y)
	_player.velocity = Vector3.ZERO
	await _frames(30)
	var den := await _place_den()
	if den == null: _finish(); return
	var prompt: Node3D
	for child: Node in den.find_children("*", "", true, false):
		if child.has_method("interaction_offer"): prompt = child as Node3D
	if not _check(prompt != null, "the Den offers its Use prompt"): _finish(); return
	# Back off 5 m, then walk to the Den with the physical stick.
	var origin: Vector3 = den.call("interaction_origin") if den.has_method("interaction_origin") else den.global_position
	_player.global_position = Vector3(origin.x + 5.0, _player.global_position.y, origin.z)
	_player.velocity = Vector3.ZERO
	await _frames(20)
	var arrived: bool = await _driver.call("_walk_to", origin, 1.6, 600)
	if not _check(arrived, "controller walked to the Den"): _finish(); return
	_saver.call("finish_fallback")
	if not _check(_saver.call("save_world_prepared", _game, str(_game.get("world").world_id)) == true \
		and _saver.call("save_character_prepared", _game, str(_game.get("local").character_id)) == true,
		"pre-groom owner and world saved to isolated disk"): _finish(); return
	var uids: Array = _game.get("party").call("members").map(func(c: RefCounted) -> String: return str(c.uid))
	var paid := int(cfg.care_per_grooming)
	await _groom(prompt, uids[0], TEAM[0], paid, "", "1 groom A pays its type essence")
	await _groom(prompt, uids[0], TEAM[0], 0, "already_groomed", "2 same creature again the same day")
	await _groom(prompt, uids[1], TEAM[1], paid, "", "3 groom B pays; today's care reaches the cap")
	await _groom(prompt, uids[2], TEAM[2], 0, "daily_care_cap", "4 a third creature past the daily cap")
	_game.call("advance_day")
	await _frames(120)
	for frame in 1800:
		if _game.get("session").call("owns_input") != true: break
		await physics_frame
	await _groom(prompt, uids[2], TEAM[2], paid, "", "5 next host day the same creature pays")
	_finish()


func _place_den() -> Node3D:
	var cost := DELIVERY.cost("den")
	for need: Dictionary in cost: _game.get("inventory").call("add", need.id, int(need.n))
	var uid := "b%d" % int(_game.get("world").next_building_uid)
	_game.set("pending_build", "den")
	await _frames(30)
	Input.action_press("build_place")
	await _frames(2)
	Input.action_release("build_place")
	var node: Node3D = null
	for frame in 240:
		await physics_frame
		for candidate: Node in get_nodes_in_group("placed_building"):
			if candidate.get_meta("building_uid", "") == uid and _world.is_ancestor_of(candidate): node = candidate as Node3D
		if node != null: break
	if not _check(node != null, "paid Den placed through build_place (%s)" % uid): return null
	Input.action_press("build_cancel")
	await _frames(2)
	Input.action_release("build_cancel")
	await _frames(30)
	return node


func _groom(prompt: Node3D, uid: String, species: String, expect_paid: int, expect_code: String, label: String) -> void:
	if _failed: return
	var item := ESSENCE.essence_item(str(SPECIES.definition(species).get("type", "")))
	var before := _disk("before_" + label.left(1))
	var results_before := _results.size()
	if not _check(await _driver.call("_prompt_holds_the_line", prompt.get_instance_id()), label + ": the Den prompt wins interaction"): return
	await _driver.call("_tap_action", &"interact")
	var button: Button = null
	for frame in 120:
		for node: Node in root.find_children("*", "Button", true, false):
			if node.get_meta("station_focus_key", "") == "groom:" + uid and (node as Button).is_visible_in_tree(): button = node as Button
		if button != null: break
		await physics_frame
	if not _check(button != null and not button.disabled, label + ": the Den panel offers Groom for " + species):
		for panel: Node in root.find_children("*", "", true, false):
			if panel.get_script() == preload("res://scripts/ui/craft_panel.gd"):
				print("DEN PANEL DIAG open=%s intent=%s op=%s waiting=%s buttons=%s results=%s" % [str(panel.get("_open")),
					JSON.stringify(panel.get("_station_intent")), str(panel.get("_station_operation")), str(panel.get("_groom_waiting_release")),
					str((panel.get("_station_buttons") as Array).map(func(b: Button) -> String: return "%s%s" % [str(b.get_meta("station_focus_key", "")), "(off)" if b.disabled else ""]) if panel.get("_station_buttons") is Array else []),
					JSON.stringify(_results).left(600)])
		return
	button.grab_focus()
	await _frames(4)
	await _driver.call("_tap_action", &"ui_accept")
	var result: Dictionary = {}
	for frame in 1200:
		if _results.size() > results_before:
			result = _results.back().result
			if result.get("settled") == true or result.get("owner_saved") == true or result.get("ok") != true: break
		await physics_frame
	await _frames(30)
	var after := _disk("after_" + label.left(1))
	var gained := _count(after.character, item) - _count(before.character, item)
	_check(gained == expect_paid, "%s: disk %s delta %d (expected %d)" % [label, item, gained, expect_paid])
	if expect_paid > 0:
		var cid := str(_game.get("local").character_id)
		var receipt := "care:%s:%d:%s:%d" % [cid, int(_game.get("world").day), uid, expect_paid]
		var row: Dictionary = {}
		for value: Variant in after.world.get("reward_deliveries", {}).values():
			if value is Dictionary and value.get("action") == "groom" and value.get("intent", {}).get("creature_uid") == uid: row = value
		_check(row.get("status") == "accepted" and after.character.get("redesign_character", {}).get("transaction_receipts", []).has(receipt),
			"%s: accepted groom row and care receipt %s on disk" % [label, receipt])
	else:
		var code := str(result.get("code", result.get("reason", "")))
		_check(code == expect_code, "%s: refused %s (got '%s', %s)" % [label, expect_code, code, JSON.stringify(result).left(200)])
	# The panel closes itself for a groom; close it if a refusal left it open.
	for node: Node in root.find_children("*", "Button", true, false):
		if node.get_meta("station_focus_key", "") == "groom:" + uid and (node as Button).is_visible_in_tree():
			await _driver.call("_tap_action", &"menu_cancel")
			break
	await _frames(30)
