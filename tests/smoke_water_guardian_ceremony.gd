extends SceneTree

## Real Guardian offer/roster/save/relic path. Explicit fixture: already freed
## Guardian, five ordinary level55 companions, and local proximity jumps. No
## claimed/settled/restored/earned/placed flags or captured Guardian injected.
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
var checks := 0
var failures := 0

func _init() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok: failures += 1
	print("PASS: " if ok else "FAIL: ", label)
	return ok

func _run() -> void:
	await process_frame
	var game := root.get_node("Game")
	game.current_realm = "water"
	game.local.character_id = "guardian-ceremony-smoke"
	game.world.world_id = "guardian-ceremony-world"
	game.save_system = SAVE.new("user://water_guardian_ceremony_%d/" % Time.get_ticks_usec())
	for i in 5:
		var keeper := SPECIES.spawn("water_mosshell")
		keeper.set_level(55, preload("res://scripts/creatures/progression.gd").config())
		game.local.party.add(keeper)
	var original: Array = game.local.party.members()
	game.world.flags.set_flag("water_guardian_freed")
	var world: Node3D = load("res://scenes/world/water_archipelago.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	var deadline := Time.get_ticks_msec() + 90000
	while not world.shell_build_complete() and Time.get_ticks_msec() < deadline:
		await process_frame
	if not check(world.shell_build_complete(), "Actual Water world builds with freed Guardian fixture"):
		_finish()
		return
	var cave: Node3D = world.get_node("WaterVeilfall")
	var player: Node3D = world.local_rig()
	var prompt: Node3D = cave.get("_guardian_prompt")
	player.global_position = prompt.global_position + Vector3(0, -1.3, -1.8)
	player.velocity = Vector3.ZERO
	await _frames(8)
	check(cave.get("_guardian").visible and not cave.get("_crystal").visible, "Freed Guardian stands outside hidden captive crystal")
	for flag: String in ["water_guardian_claimed", "water_guardian_settled", "water_currents_restored", "realm_relic_water_earned", "realm_relic_water_placed"]:
		check(not game.world.flags.has(flag), "No fixture awards " + flag)
	if not check(not prompt.interaction_offer(player.global_position).is_empty(), "Nearby freed Guardian offers actual companionship interaction"):
		_finish()
		return
	prompt.interaction_activate()
	deadline = Time.get_ticks_msec() + 10000
	while game.pending_catch == null and Time.get_ticks_msec() < deadline:
		await process_frame
	if not check(game.pending_catch != null and game.pending_catch.species_id == "water_abyssal_guardian", "Actual offer creates Guardian through durable claim service"):
		_finish()
		return
	var pending: RefCounted = game.pending_catch
	var claim_id := str(pending.get_meta("water_capture_claim", ""))
	check(not claim_id.is_empty() and game.world.water_capture_claims.has(claim_id), "Guardian claim waits on host before roster choice")
	check(not game.world.flags.has("water_guardian_settled") and not game.world.flags.has("realm_relic_water_earned"), "Pending choice cannot settle world or earn relic early")
	var disk: Dictionary = game.save_system.get("_worlds").read(game.world.world_id)
	check(disk.get("water_capture_claims", {}).has(claim_id), "Guardian reservation exists in actual world disk journal")
	var menu: Node = game.menu()
	var tab: Node
	for i in menu.get("_tabs").size():
		if str(menu.get("_tabs")[i].id) == "creatures": tab = menu.get("_bodies")[i]
	deadline = Time.get_ticks_msec() + 5000
	while (not menu.is_open() or tab.get("_release_stage") != "choose") and Time.get_ticks_msec() < deadline:
		await process_frame
	if not check(menu.is_open() and tab.get("_release_stage") == "choose", "Production five-holder roster ceremony opens for Guardian"):
		_finish()
		return
	tab.get("_rows")[1].pressed.emit()
	check(tab.get("_release_stage") == "confirm", "Actual holder choice presents release confirmation")
	tab.get("_farewell_release").pressed.emit()
	check(tab.get("_release_stage") == "done" and game.pending_catch == null, "Actual farewell completes Guardian handover")
	check(game.local.party.size() == 5 and game.local.party.at(1) == pending, "Guardian takes chosen holder with exactly five owned")
	for i in [0, 2, 3, 4]: check(game.local.party.at(i) == original[i], "Other companion identity retained at holder%d" % i)
	var character: Dictionary = game.save_system.get("_characters").read(game.local.character_id)
	check(character.get("flags", {}).get("flags", []).has("water_capture_receipt:" + claim_id), "Actual character file receipts Guardian handover")
	check(character.get("party", []).size() == 5 and character.party[1].species_id == "water_abyssal_guardian", "Same saved character file owns the chosen Guardian")
	check(not game.world.water_capture_claims.has(claim_id), "Host removes Guardian reservation after saved receipt acknowledgment")
	disk = game.save_system.get("_worlds").read(game.world.world_id)
	for flag: String in ["water_guardian_settled", "water_currents_restored", "realm_relic_water_earned"]:
		check(game.world.flags.has(flag), "Completed roster choice publishes " + flag)
		check(disk.get("flags", {}).get("flags", []).has(flag), "World journal persists " + flag)
	tab.get("_farewell_done").pressed.emit()
	menu.close()
	await _frames(4)
	check(not cave.get("_guardian").visible, "Settled Guardian no longer duplicates the owned companion in chamber")
	check(cave.get_node_or_null("TideglassCompassShrine") == null,
		"Water realm leaves relic placement to the Meadows shrine circle")
	check(game.realm_hearts.is_earned("water", game.progression) and
		not game.realm_hearts.is_placed("water", game.progression),
		"Earned Tideglass Compass waits for the Meadows home circle")
	_finish()

func _offer_at(world: Node3D, player: Node3D, prompt: Node3D) -> bool:
	for i in 8:
		var angle := TAU * float(i) / 8.0
		var at := prompt.global_position + Vector3(cos(angle), 0, sin(angle)) * 2.0
		at.y = world.ground_height_at(at.x, at.z) + 0.1
		player.global_position = at
		player.velocity = Vector3.ZERO
		await _frames(2)
		if not prompt.interaction_offer(player.global_position).is_empty(): return true
	return false

func _frames(count: int) -> void:
	for frame in count: await physics_frame

func _finish() -> void:
	print("Water Guardian ceremony smoke: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
