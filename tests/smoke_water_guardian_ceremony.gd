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
	# The chamber view refreshes in `_process`; physics frames can pass before
	# an idle frame in a headless run, so wait on process frames here.
	for _frame in 4: await process_frame
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
	await _frames(2)
	# A character HOLDING its claim declines through the real chamber route.
	# A full belt would put the roster ceremony on screen at once, so the claim
	# is held the way a fight holds it: received and queued, not yet presented
	# (the claim service's poll is paused for this step only). The host's first
	# journal write fails: the chamber must say "Declining..." and never claim
	# success until the host journals the refusal.
	var claim_service: Node = game.ledger.get_node("WaterCaptureClaims")
	player.global_position = prompt.global_position + Vector3(0, -1.3, -1.8)
	player.velocity = Vector3.ZERO
	await _frames(4)
	claim_service.set("_poll", 1000.0)
	prompt.interaction_activate()
	var held_id: String = reward.claim_id(reward.world_instance(game.world), game.local.character_id)
	if not check(game.world.water_capture_claims.has(held_id), "Third character's own Guardian claim is journaled"):
		_finish()
		return
	claim_service.receive_claim(game.world.water_capture_claims[held_id])
	check(claim_service.pending_guardian_id() == held_id and game.pending_catch == null, "The claim is held locally, not yet presented")
	cave.request_guardian_decline()
	# Real-clock pause past the double-tap guard (scene timers follow time scale).
	var armed_at := Time.get_ticks_msec()
	while Time.get_ticks_msec() - armed_at < cave.DECLINE_MIN_CONFIRM_MSEC + 150:
		await process_frame
	game.save_system = RefusingSaver.new()
	game.take_pending_world_message()
	cave.request_guardian_decline()
	game.save_system = real_saver
	check(game.take_pending_world_message() == cave.DECLINE_PENDING, "Held-claim decline shows a pending wording before the host journals it")
	check(game.world.water_capture_claims.has(held_id) and not cave.get("_decline_done_shown"), "No done message while the host still holds the claim")
	check(game.pending_catch == null and game.local.party.size() == party_before, "Declining the held claim grants nothing")
	claim_service.set("_poll", 0.0)
	deadline = Time.get_ticks_msec() + 6000
	while (game.world.water_capture_claims.has(held_id) or not cave.get("_decline_done_shown")) and Time.get_ticks_msec() < deadline:
		await process_frame
	check(not game.world.water_capture_claims.has(held_id), "The claim resend retries the refusal until the host journals it")
	check(cave.get("_decline_done_shown") and str(cave.get("_decline_claim_id")).is_empty(), "Done message follows the host's confirmation")
	check(game.local.party.size() == party_before and game.pending_catch == null, "Journaled decline still grants nothing")
	# --- A free holder: the Guardian still ASKS (ACCEPTANCE F14) -------------
	# Fixture (disclosed): one ordinary companion is set aside so the next
	# characters have a free holder. The offer must be answered through the
	# real Creatures tab's Accept/Decline, never auto-accepted.
	var hud: Node = world.get_node("PlaygroundHUD")
	game.local.character_id = "guardian-ceremony-room-accept"
	game.local.party.remove_at(4)
	if not await _invite_with_room(game, menu, tab, prompt, player):
		_finish()
		return
	var room_id: String = reward.claim_id(reward.world_instance(game.world), game.local.character_id)
	var room_pending: RefCounted = game.pending_catch
	check(room_pending != null and room_pending.species_id == "water_abyssal_guardian" and game.local.party.size() == 4
		and game.world.water_capture_claims.has(room_id) and not game.local.flags.has("water_capture_receipt:" + room_id),
		"A free holder does not auto-accept: nothing granted or receipted before the answer")
	check(root.gui_get_focus_owner() == tab.get("_guardian_accept"), "Controller focus lands on Accept")
	check(bool(menu.get("_deaf")) and tab.get("_farewell_panel").visible, "The confirm holds the shell's input in the farewell panel")
	check(str(tab.get("_farewell_title").text) == "The Deep Watcher offers to join you", "The confirm names the volunteer's offer as the chamber does")
	check(str(tab.get("_guardian_subtitle").text) == "Abyssal Guardian · Lv %d" % int(room_pending.level), "Subtitle names the species and level")
	check(str(tab.get("_guardian_final").text) == "This choice is final." and tab.get("_guardian_final").visible,
		"'This choice is final.' stands on its own line")
	check(not str(tab.get("_farewell_body").text).contains("holder") and str(tab.get("_farewell_body").text).contains("free slot"),
		"The body says it plainly: joins your party in the free slot")
	check((tab.get("_guardian_accept") as Button).icon != null and (tab.get("_guardian_decline") as Button).icon == null,
		"The A glyph rides on the focused answer (Accept)")
	check(str(tab.get("_farewell_hint").text).ends_with("Decide later") and str(tab.get("_farewell_hint").text).contains("[img"),
		"'Decide later' carries the B glyph")
	await _frames(20)
	check(game.local.party.size() == 4 and game.pending_catch == room_pending, "Waiting never answers the offer")
	# B puts it off: back to the ordinary Creatures tab, the offer still pending.
	game.take_pending_world_message()
	await _press("menu_cancel")
	check(menu.is_open() and str(tab.get("_release_stage")) == "" and game.pending_catch == null and not bool(menu.get("_deaf")),
		"Decide later returns to the ordinary Creatures tab with the shell's input free")
	check(tab.get("_rows").has(root.gui_get_focus_owner()), "Focus returns to the belt rows")
	check(claim_service.pending_guardian_id() == room_id and not claim_service.is_declined(room_id)
		and game.world.water_capture_claims.has(room_id) and game.local.party.size() == 4,
		"Backing out leaves the offer pending: neither granted nor declined")
	var told: String = game.take_pending_world_message()
	if told.is_empty(): told = str((hud.get("_hotbar_message") as Label).text)
	check(told.contains("Edda") and told.contains("chamber"), "A world message tells the player where to answer: Edda or the chamber")
	check(str(menu.get("_status").text) == told, "The tab says the same where-to-answer line, once")
	# M1: the ordinary tab is usable -- no confirm comes back by itself, by
	# staying on the tab, cycling away and back, or closing and reopening it.
	await create_timer(1.5).timeout
	check(str(tab.get("_release_stage")) == "" and game.pending_catch == null, "Staying on the Creatures tab does not re-present the offer")
	var row_before: Control = root.gui_get_focus_owner()
	await _press("ui_down")
	check(root.gui_get_focus_owner() != row_before and tab.get("_rows").has(root.gui_get_focus_owner()), "The belt rows take the stick again")
	menu.next_tab()
	await _frames(2)
	menu.previous_tab()
	await _frames(4)
	check(tab.visible and str(tab.get("_release_stage")) == "" and not bool(menu.get("_deaf")), "Cycling away and back onto Creatures does not trap the player")
	menu.close()
	await _frames(4)
	check(menu.open("creatures"), "Player reopens the menu on Creatures")
	await _frames(4)
	check(str(tab.get("_release_stage")) == "" and game.pending_catch == null and claim_service.has_deferred(),
		"Reopening the Creatures tab does not re-present it either; the offer still waits")
	menu.close()
	await _frames(4)
	# The deliberate answer path: the chamber's prompt now asks to answer it.
	player.global_position = prompt.global_position + Vector3(0, -1.3, -1.8)
	player.velocity = Vector3.ZERO
	await _frames(4)
	check(prompt.enabled and str(prompt.label) == cave.ANSWER_LABEL, "The chamber offers 'Answer the Deep Watcher' for a put-off offer")
	prompt.interaction_activate()
	deadline = Time.get_ticks_msec() + 5000
	while (not menu.is_open() or str(tab.get("_release_stage")) != "guardian") and Time.get_ticks_msec() < deadline:
		await process_frame
	await _frames(2)
	if not check(str(tab.get("_release_stage")) == "guardian" and root.gui_get_focus_owner() == tab.get("_guardian_accept")
			and game.pending_catch != null and claim_service.pending_guardian_id() == room_id,
			"Answering at the chamber asks again on the Creatures tab, focus on Accept"):
		_finish()
		return
	await _press("ui_accept")
	check(game.local.party.size() == 5
		and str(game.local.party.at(4).species_id) == "water_abyssal_guardian" and game.pending_catch == null,
		"Pressing the real Accept button adds the Guardian to the free holder")
	character = game.save_system.get("_characters").read(game.local.character_id)
	check(character.get("flags", {}).get("flags", []).has("water_capture_receipt:" + room_id), "Accept saves the receipt to the character file")
	check(not game.world.water_capture_claims.has(room_id), "Host settles this character's own claim after Accept")
	check(str(tab.get("_release_stage")) == "" and not bool(menu.get("_deaf")), "Accept ends the confirm and frees the shell")
	await _press("ui_accept")
	check(game.local.party.size() == 5 and claim_service.pending_guardian_id().is_empty(), "A second press grants nothing more")
	menu.close()
	await _frames(4)
	# Decline through the real tab (controller: down to Decline, then A).
	game.local.character_id = "guardian-ceremony-room-decline"
	game.local.party.remove_at(4)
	party_before = game.local.party.size()
	if not await _invite_with_room(game, menu, tab, prompt, player):
		_finish()
		return
	var decline_id: String = reward.claim_id(reward.world_instance(game.world), game.local.character_id)
	await _press("ui_down")
	check(root.gui_get_focus_owner() == tab.get("_guardian_decline"), "Down moves focus from Accept to Decline")
	await _press("ui_up")
	check(root.gui_get_focus_owner() == tab.get("_guardian_accept"), "Focus is fenced to the two answers")
	await _press("ui_down")
	await _press("ui_accept")
	# Decline asks once more (two presses, no held input); Back returns.
	check(str(tab.get("_release_stage")) == "guardian_decline" and root.gui_get_focus_owner() == tab.get("_guardian_back"),
		"Decline first asks to confirm, focus on Back")
	check(str(tab.get("_farewell_title").text) == "Let the Deep Watcher go?" and str(tab.get("_guardian_final").text) == "This is final.",
		"The decline step says: Let the Deep Watcher go? This is final.")
	check(game.pending_catch != null and game.world.water_capture_claims.has(decline_id) and not claim_service.is_declined(decline_id),
		"The decline step commits nothing")
	await _press("ui_accept")
	check(str(tab.get("_release_stage")) == "guardian" and root.gui_get_focus_owner() == tab.get("_guardian_accept"),
		"Back returns to the offer with focus on Accept")
	await _press("ui_down")
	await _press("ui_accept")
	await _press("menu_cancel")
	check(str(tab.get("_release_stage")) == "guardian" and root.gui_get_focus_owner() == tab.get("_guardian_accept")
		and menu.is_open() and game.pending_catch != null, "B on the decline step is Back too, never Decide later")
	await _press("ui_down")
	await _press("ui_accept")
	await _press("ui_down")
	check(root.gui_get_focus_owner() == tab.get("_guardian_confirm_decline"), "Down moves from Back to Confirm")
	# Clear the HUD's last line (the earlier chamber decline's) so any repeat
	# of the answer after this press is visible to the "said once" check.
	game.take_pending_world_message()
	(hud.get("_hotbar_message") as Label).text = ""
	await _press("ui_accept")
	check(game.local.party.size() == party_before and game.pending_catch == null, "Pressing the real Decline button grants nothing")
	check(not game.world.water_capture_claims.has(decline_id) and claim_service.is_declined(decline_id)
		and game.world.flags.has(reward.offered_flag(game.local.character_id)), "Decline is the host-journaled refusal")
	check(str(menu.get("_status").text) == cave.DECLINE_RESULT and not str(menu.get("_status").text).contains("..."),
		"The tab says the host-confirmed result, no ellipsis: The Deep Watcher stays free.")
	check(str(tab.get("_release_stage")) == "" and not bool(menu.get("_deaf")), "Decline ends the confirm")
	menu.close()
	await _frames(4)
	check(game.take_pending_world_message().is_empty() and str((hud.get("_hotbar_message") as Label).text) != cave.DECLINE_DONE,
		"The tab's decline is said once: no second world message from the chamber")
	# Decline whose first host journal write fails: pending wording, then done.
	game.local.character_id = "guardian-ceremony-room-decline-pending"
	if not await _invite_with_room(game, menu, tab, prompt, player):
		_finish()
		return
	var pending_id: String = reward.claim_id(reward.world_instance(game.world), game.local.character_id)
	(tab.get("_guardian_decline") as Button).pressed.emit()
	game.save_system = RefusingSaver.new()
	(tab.get("_guardian_confirm_decline") as Button).pressed.emit()
	game.save_system = real_saver
	check(str(menu.get("_status").text) == cave.DECLINE_PENDING, "Decline shows the pending wording until the host journals it")
	check(game.world.water_capture_claims.has(pending_id) and game.pending_catch == null
		and game.local.party.size() == party_before, "Unjournaled decline grants nothing and presents nothing")
	menu.close()
	deadline = Time.get_ticks_msec() + 6000
	while (game.world.water_capture_claims.has(pending_id) or not cave.get("_decline_done_shown")) and Time.get_ticks_msec() < deadline:
		await process_frame
	check(not game.world.water_capture_claims.has(pending_id) and cave.get("_decline_done_shown"),
		"The resend journals the tab's refusal and the done message follows")
	check(game.local.party.size() == party_before and game.pending_catch == null, "Journaled tab decline still grants nothing")
	# The same pending decline with the tab still on screen: "Declining..."
	# only while the host has not journaled it, then the result line in its
	# place -- and the chamber does not announce it a second time.
	game.local.character_id = "guardian-ceremony-room-decline-open"
	if not await _invite_with_room(game, menu, tab, prompt, player):
		_finish()
		return
	var open_id: String = reward.claim_id(reward.world_instance(game.world), game.local.character_id)
	await _press("ui_down")
	await _press("ui_accept")
	await _press("ui_down")
	game.take_pending_world_message()
	(hud.get("_hotbar_message") as Label).text = ""
	game.save_system = RefusingSaver.new()
	await _press("ui_accept")
	game.save_system = real_saver
	check(str(menu.get("_status").text) == cave.DECLINE_PENDING and game.world.water_capture_claims.has(open_id),
		"Declining... while the host has not journaled the refusal")
	deadline = Time.get_ticks_msec() + 6000
	while str(menu.get("_status").text) != cave.DECLINE_RESULT and Time.get_ticks_msec() < deadline:
		await process_frame
	check(str(menu.get("_status").text) == cave.DECLINE_RESULT and not game.world.water_capture_claims.has(open_id),
		"Once the host journals it the tab replaces Declining... with: The Deep Watcher stays free.")
	menu.close()
	await _frames(6)
	check(game.take_pending_world_message().is_empty() and str((hud.get("_hotbar_message") as Label).text) != cave.DECLINE_DONE,
		"Said once: the chamber does not repeat the tab's result")
	# Edda is the other deliberate answer path for a put-off offer.
	game.local.character_id = "guardian-ceremony-edda-answer"
	if not await _invite_with_room(game, menu, tab, prompt, player):
		_finish()
		return
	var edda_id: String = reward.claim_id(reward.world_instance(game.world), game.local.character_id)
	await _press("menu_cancel")
	menu.close()
	await _frames(4)
	player.global_position = edda.global_position + Vector3(0, 0, 1.5)
	player.velocity = Vector3.ZERO
	await _frames(4)
	edda.prompt_node().activated.emit()
	check(str(cast.get("_active_conversation")) == reward.EDDA_OFFER, "Edda offers the conversation to a character holding a put-off offer")
	world.get_node("DialoguePanel").close()
	await _frames(2)
	world.get_node("WaterChapter")._on_dialogue_request("water:water_guardian_offer_requested", "water_edda", int(game.session.local_peer_id()))
	deadline = Time.get_ticks_msec() + 5000
	while (not menu.is_open() or str(tab.get("_release_stage")) != "guardian") and Time.get_ticks_msec() < deadline:
		await process_frame
	await _frames(2)
	check(str(tab.get("_release_stage")) == "guardian" and root.gui_get_focus_owner() == tab.get("_guardian_accept")
		and claim_service.pending_guardian_id() == edda_id, "Edda's offer request re-presents the same put-off offer")
	await _press("ui_accept")
	check(game.local.party.size() == party_before + 1 and game.pending_catch == null
		and not game.world.water_capture_claims.has(edda_id), "Accepting after Edda grants it once")
	menu.close()
	_finish()

## Invite as the current character (belt has room) and wait for the real
## Creatures tab to put the Accept/Decline confirm on screen.
func _invite_with_room(game: Node, menu: Node, tab: Node, prompt: Node3D, player: Node3D) -> bool:
	player.global_position = prompt.global_position + Vector3(0, -1.3, -1.8)
	player.velocity = Vector3.ZERO
	await _frames(4)
	for i in 4: await process_frame
	if not check(prompt.enabled and not game.local.party.is_full(), "%s has a free holder and sees the invite" % game.local.character_id):
		return false
	prompt.interaction_activate()
	var deadline := Time.get_ticks_msec() + 10000
	while (not menu.is_open() or str(tab.get("_release_stage")) != "guardian") and Time.get_ticks_msec() < deadline:
		await process_frame
	await _frames(2)
	return check(menu.is_open() and str(tab.get("_release_stage")) == "guardian" and game.pending_catch != null,
		"With a free holder Game opens the real Creatures tab on the Accept/Decline confirm")

func _press(action: String) -> void:
	Input.action_press(action)
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	await process_frame
	Input.action_release(action)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	for i in 4:
		await process_frame

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
