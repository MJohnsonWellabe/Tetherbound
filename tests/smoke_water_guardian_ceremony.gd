extends SceneTree

## Real Guardian offer/roster/save/relic path. Explicit fixture: already freed
## Guardian, five ordinary level55 companions, and local proximity jumps. No
## claimed/settled/restored/earned/placed flags or captured Guardian injected.
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
## One synchronous refused journal write (the host refuses the decline).
class RefusingSaver extends RefCounted:
	func save_world(_game: Object, _id: String) -> bool: return false
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
	# Explicit refusal route: the first press shows the consequence and commits
	# nothing; inviting afterwards disarms it.
	var decline: Node3D = cave.get("_decline_prompt")
	check(decline != null and decline.enabled, "Chamber offers an explicit Decline the Deep Watcher interaction")
	game.take_pending_world_message()
	cave.request_guardian_decline()
	check(game.take_pending_world_message() == cave.DECLINE_CONSEQUENCE, "Decline shows its consequence before any commitment")
	check(cave.decline_armed() and str(decline.label).begins_with("Confirm"), "First decline press arms a confirmation")
	check(not game.world.flags.has(preload("res://scripts/world/water_guardian_reward.gd").offered_flag(game.local.character_id))
		and not game.world.flags.has("water_guardian_settled"), "Consequence step commits nothing")
	# A second press inside the 0.5 s guard is ignored (no accidental double tap).
	cave.request_guardian_decline()
	check(cave.decline_armed() and not game.world.flags.has(reward_offered(game)), "Immediate second press is ignored, still armed, nothing committed")
	# Leaving the prompt radius disarms.
	var near_at: Vector3 = player.global_position
	player.global_position = decline.global_position + Vector3(0, 0, -12)
	await _frames(4)
	check(not cave.decline_armed() and str(decline.label) == cave.DECLINE_LABEL, "Walking out of the prompt radius disarms the decline")
	player.global_position = near_at
	player.velocity = Vector3.ZERO
	await _frames(4)
	# The host REFUSES the confirmed decline (journal failure): nothing may be
	# remembered as declined, so the later Invite is still presented.
	cave.request_guardian_decline()
	await create_timer(0.6).timeout
	var real_saver: RefCounted = game.save_system
	game.save_system = RefusingSaver.new()
	game.take_pending_world_message()
	cave.request_guardian_decline()
	game.save_system = real_saver
	check(not game.world.flags.has(reward_offered(game)) and game.take_pending_world_message() != cave.DECLINE_DONE,
		"A decline the host refused commits nothing and does not claim success")
	prompt.interaction_activate()
	check(not cave.decline_armed(), "Inviting disarms a pending decline confirmation")
	deadline = Time.get_ticks_msec() + 10000
	while game.pending_catch == null and Time.get_ticks_msec() < deadline:
		await process_frame
	if not check(game.pending_catch != null and game.pending_catch.species_id == "water_abyssal_guardian", "Actual offer creates Guardian through durable claim service"):
		_finish()
		return
	var pending: RefCounted = game.pending_catch
	var claim_id := str(pending.get_meta("water_capture_claim", ""))
	check(not claim_id.is_empty() and game.world.water_capture_claims.has(claim_id), "Guardian claim waits on host before roster choice")
	var reward := preload("res://scripts/world/water_guardian_reward.gd")
	check(claim_id == reward.claim_id(reward.world_instance(game.world), game.local.character_id), "Solo offer is bound to this character's own per-participant claim id")
	check(str(game.world.water_capture_claims[claim_id].get("world_instance", "")) == reward.world_instance(game.world), "Claim names its world instance, not only the slot locator")
	check(game.world.flags.has(reward.offered_flag(game.local.character_id)), "Host journals this character's once-only offer marker")
	await _frames(2)
	check(not prompt.enabled, "Guardian prompt closes for a character that already holds its offer")
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
	# Second host character (solo world: the host's local character is the one
	# participant) answers through the real chamber refusal route.
	game.local.character_id = "guardian-ceremony-decliner"
	player.global_position = prompt.global_position + Vector3(0, -1.3, -1.8)
	await _frames(4)
	for i in 4: await process_frame
	var decline_prompt: Node3D = cave.get("_decline_prompt")
	check(decline_prompt.enabled and prompt.enabled, "A character that has not answered sees invite and decline")
	var party_before: int = game.local.party.size()
	cave.request_guardian_decline()
	await create_timer(0.6).timeout
	game.take_pending_world_message()
	cave.request_guardian_decline()
	check(game.take_pending_world_message() == cave.DECLINE_DONE, "Host-confirmed decline shows the done message")
	var decliner_flag: String = reward.offered_flag(game.local.character_id)
	check(game.world.flags.has(decliner_flag), "Confirmed decline journals this character's answer through the host")
	check(game.local.party.size() == party_before and game.pending_catch == null, "Decline grants no creature")
	check(game.save_system.get("_worlds").read(game.world.world_id).get("flags", {}).get("flags", []).has(decliner_flag), "Decline answer is in the world journal")
	for i in 4: await process_frame
	check(not decline_prompt.enabled and not prompt.enabled, "Answered character no longer sees the ceremony prompts")
	# Edda's real greet prompt is routed through the per-character gate: an
	# answered character hears no offer (currents restored: her post line).
	var cast: Node = world.get_node("WaterNPCs")
	var edda: Node3D = world.get_node("WaterChapter").npc_bodies.get("water_edda")
	player.global_position = edda.global_position + Vector3(0, 0, 1.5)
	player.velocity = Vector3.ZERO
	await _frames(2)
	edda.prompt_node().activated.emit()
	check(str(cast.get("_active_conversation")) == reward.EDDA_POST, "Answered character greeting Edda hears no Guardian offer")
	world.get_node("DialoguePanel").close()
	await _frames(2)
	game.local.character_id = "guardian-ceremony-unanswered"
	edda.prompt_node().activated.emit()
	check(str(cast.get("_active_conversation")) == reward.EDDA_OFFER, "A character that may still answer is offered by Edda")
	world.get_node("DialoguePanel").close()
	_finish()

func reward_offered(game: Node) -> String:
	return preload("res://scripts/world/water_guardian_reward.gd").offered_flag(game.local.character_id)

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
