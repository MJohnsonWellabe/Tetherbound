extends SceneTree

## Focused production-node proof, not a campaign/co-op or visual acceptance.
## Fixtures: one admitted level-5 Bramblebun with prior mastery, a static named
## opponent with 600 HP, a flat capture stage, and no autonomous AI/movement.
## Real physical taps drive CombatManager -> Director -> AcceptedActionHost;
## the real host timer writes HP and Session journals that exact original.
## --enable-ultimate-visual and --prove-library-arrival are process-local
## presentation overrides. --capture-dir=<path>
## saves rendered frames of the same accepted action for independent judging.
## --with-vfx-units runs the existing move-effects unit selector first, in a
## separate headless process, before this smoke mounts any gameplay nodes.
## --with-combat-units batches the existing files naming combat_hud.gd and
## the changed peer/harness preload guard in that same sequential child.
const SAVE := preload("res://tests/test_foundation_resource_save.gd")
const DATA := preload("res://tests/test_foundation_resources.gd")
const AUTHORITY := preload("res://scripts/net/character_authority.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const OWNER := preload("res://scripts/net/character_action_owner.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const MASTERY := preload("res://scripts/creatures/move_mastery.gd")
const BODY := preload("res://scenes/creatures/creature.tscn")
const FOLLOWER := preload("res://scripts/creatures/follower_creature.gd")
const WILD := preload("res://scripts/creatures/wild_creature.gd")
const DIRECTOR := preload("res://scripts/combat/encounter_director.gd")
const MANAGER := preload("res://scripts/combat/combat_manager.gd")
const HUD := preload("res://scenes/combat/combat_hud.tscn")
const ULTIMATES := preload("res://scripts/vfx/ultimates/ultimate_library.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const MOVE_LIBRARY := preload("res://scripts/vfx/move_effect_library.gd")

class FixtureGame extends SAVE.FixtureGame:
	var party: RefCounted:
		get: return local.party
	var realm_hearts: RefCounted
	var progression: RefCounted
	var current_realm := "meadows"
	var messages: Array[String] = []
	func push_world_message(message: String) -> void: messages.append(message)
	func is_multi_peer() -> bool: return session != null and bool(session.call("is_multi_peer"))

class FixtureSession extends SAVE.FixtureSession:
	func _ready() -> void: pass # Canonical admission below replaces only transport bootstrap.
	func _process(_delta: float) -> void: pass # Retry timing is controlled explicitly.
	func is_active() -> bool: return true
	func is_multi_peer() -> bool: return false
	func _authority_character(peer: int) -> String: return DATA.CHARACTER if peer == 1 else ""
	func _local_character_id() -> String: return DATA.CHARACTER
	func admitted_character_state(peer: int) -> Dictionary:
		return _character_authority.state(DATA.CHARACTER) if peer == 1 else {}
	func training_actor_baseline_ready(peer: int, training: Dictionary) -> bool:
		return _training_actor_baseline_proposals(peer, training).get("ok") == true

class FixtureRpc extends SAVE.FixtureRpc:
	func _ready() -> void: pass
	func _process(_delta: float) -> void: pass
	func _registered_character(peer: int) -> String: return DATA.CHARACTER if peer == 1 else ""

var _checks := 0
var _errors: Array[String] = []
var _world: Node3D
var _game: FixtureGame
var _session: FixtureSession
var _rpc: FixtureRpc
var _writer: RefCounted
var _authority: RefCounted
var _director: Node
var _manager: Node
var _hud: Node
var _ally: Node3D
var _wild: Node3D
var _creature: RefCounted
var _enemy: RefCounted
var _host: RefCounted
var _id := ""
var _directory := ""
var _capture_dir := ""
var _ultimate_prior_uses := 150
var _prove_mastery_transition := false
var _launches: Array[Dictionary] = []
var _impacts: Array[Dictionary] = []
var _captures: Array[String] = []
var _saved_visual_config: Dictionary
var _saved_library_enabled := false
var _prove_library_arrival := false
var _arrival_records: Dictionary = {}
var _captured_library_slots: Dictionary = {}
var _pending_library_captures := 0

func _init() -> void:
	_run.call_deferred()

func _check(value: bool, reason: String) -> void:
	_checks += 1
	if not value: _errors.append(reason)

func _body(script: Script, species: String, at: Vector3) -> Node3D:
	var body := BODY.instantiate() as Node3D
	body.set_script(script)
	_world.add_child(body)
	body.call("setup", species)
	body.position = at
	body.set_physics_process(false)
	return body

func _run() -> void:
	_saved_library_enabled = bool(MOVE_LIBRARY.config().get("enabled", false))
	_prove_library_arrival = OS.get_cmdline_user_args().has("--prove-library-arrival")
	if _prove_library_arrival: MOVE_LIBRARY.config()["enabled"] = true
	_prove_mastery_transition = OS.get_cmdline_user_args().has("--prove-mastery-transition")
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): _capture_dir = arg.trim_prefix("--capture-dir=")
		if arg.begins_with("--ultimate-prior-uses="):
			var prior := arg.trim_prefix("--ultimate-prior-uses=")
			var allowed: Array = [24, 74, 149, 299] if _prove_mastery_transition else [0, 25, 75, 150, 300]
			_check(prior.is_valid_int() and allowed.has(int(prior)), "prior mastery fixture selects a canonical threshold or its preceding use")
			if prior.is_valid_int(): _ultimate_prior_uses = int(prior)
	_saved_visual_config = ULTIMATES.config()
	var visual_override := OS.get_cmdline_user_args().has("--enable-ultimate-visual")
	var slot_inputs := OS.get_cmdline_user_args().has("--prove-slot-inputs")
	_check(not _prove_mastery_transition or (visual_override and [24, 74, 149, 299].has(_ultimate_prior_uses)),
		"earned mastery transition requires the actual signature and disclosed prethreshold history")
	if visual_override:
		var candidate := _saved_visual_config.duplicate(true)
		candidate.enabled = true
		ULTIMATES._config = candidate
	_check(MATH.config().get("actor_vitals", {}).get("runtime_enabled") == false, "actor_vitals gate must remain off")
	_check(_capture_dir.is_empty() or DisplayServer.get_name() != "headless", "render capture requires an actual display")
	if not _errors.is_empty():
		_finish()
		return
	var selectors: Array[String] = []
	if OS.get_cmdline_user_args().has("--with-vfx-units"):
		selectors.append("test_move_effects.gd")
	if OS.get_cmdline_user_args().has("--with-combat-units"):
		selectors.append_array(["test_combat_hud_handheld_floors.gd", "test_combat_wind.gd",
			"test_f23_live_moves.gd", "test_f24_host_commands.gd", "test_harness_max_hp.gd",
			"test_hud_presentation_lifecycle.gd", "test_hud_widgets.gd", "test_level_up_announcement.gd",
			"test_motion_prefs.gd", "test_move_commit_runtime.gd", "test_world_verb_input_owner_enforcement.gd",
			"test_net_harness_heartbeat_allowance.gd"])
	if not selectors.is_empty():
		var output: Array = []
		var exit_code := OS.execute(OS.get_executable_path(), PackedStringArray([
			"--headless", "--path", ProjectSettings.globalize_path("res://"),
			"--audio-driver", "Dummy", "--script", "res://tests/run_tests.gd", "--",
			"--only=" + ",".join(selectors)]), output, true)
		for chunk: Variant in output: print(str(chunk))
		_check(exit_code == 0, "existing named unit selectors pass before the live smoke: " + ",".join(selectors))
		if exit_code != 0:
			_finish()
			return
	_setup()
	await process_frame
	if not _errors.is_empty():
		_finish()
		return
	await process_frame
	var shown_meter: ProgressBar = _hud.get("_ultimate_meter")
	var shown_readout: RichTextLabel = _hud.get("_ultimate_readout")
	_check(shown_meter != null and shown_readout != null, "mounted actual CombatHUD creates its Ultimate controls")
	if shown_meter == null or shown_readout == null:
		_finish()
		return
	_check(is_equal_approx(shown_meter.value, 0.0), "mounted actual CombatHUD starts with an empty Ultimate meter")
	if visual_override:
		await _button(JOY_BUTTON_RIGHT_SHOULDER, true)
		await _button(JOY_BUTTON_RIGHT_SHOULDER, false)
		_check(not bool(_manager.call("ultimate_armed")) and _launches.is_empty() and _impacts.is_empty(),
			"physical RB tap at zero meter cannot arm or launch an ultimate")
		var empty_resources: Dictionary = _host.record(_id).participants[1].move_resources.duplicate(true)
		var empty_commit: Dictionary = _host.move_commit(_id, 1, 99).duplicate(true)
		var empty_refusal: Dictionary = _director.call("_host_move_start", {"encounter_id": _id, "slot": "ultimate", "action": 99}, 1)
		_check(empty_refusal.get("code") == "ultimate_not_ready", "host refuses an actual equipped ultimate below full meter")
		_check(_host.record(_id).participants[1].move_resources == empty_resources
			and _host.move_commit(_id, 1, 99) == empty_commit,
			"below-full ultimate refusal leaves canonical resources and accepted original unchanged")
		if not _capture_dir.is_empty():
			DirAccess.make_dir_recursive_absolute(_capture_dir)
			await RenderingServer.frame_post_draw
			var empty_path := _capture_dir.path_join("ultimate-empty.png")
			var empty_image := root.get_texture().get_image()
			_check(empty_image != null and empty_image.save_png(empty_path) == OK, "rendered actual empty-meter CombatHUD capture " + empty_path)
			_captures.append(empty_path)
	var prior_ultimate_history: Array = _creature.move_mastery_receipts.get("ultimate_ground_current", []).duplicate()
	var maximum_mastery := int(MASTERY.config().rank_thresholds[4])
	var old_world := FileAccess.get_file_as_bytes(_writer.world_store.path_for("resource-slot"))
	if slot_inputs:
		var before_burst: Dictionary = _host.strike_authority_state(_id, 1).duplicate(true)
		var before_wind: float = _manager.wind_value()
		await _button(JOY_BUTTON_A, true)
		var burst: Dictionary = _host.strike_authority_state(_id, 1).duplicate(true)
		_check(int(burst.get("last_action", 0)) > int(before_burst.get("last_action", 0))
			and int(_manager.get("_action")) == MANAGER.Action.BURST and _ally.call("combat_burst_active") == true,
			"physical A starts the real host-authorized dodge state")
		_check(is_equal_approx(_manager.wind_value(), maxf(0.0, before_wind - _manager.wind_cost("burst"))),
			"physical A spends the canonical dodge Wind cost once")
		await _wait_ready()
		while Time.get_ticks_msec() < int(burst.get("deadline_ms", 0)): await process_frame
		await physics_frame
		await process_frame
		_check(_host.strike_authority_state(_id, 1) == burst, "holding A after the dodge deadline creates no repeated accepted action")
		await _button(JOY_BUTTON_A, false)
	_writer.refuse_world = true
	var snare := await _tap_move(JOY_BUTTON_B, "utility")
	_check(not snare.is_empty(), "B must start and land admitted Snare")
	if snare.is_empty():
		_finish()
		return
	var pending: Dictionary = _host.move_mastery_outcome(_id, 1, int(snare.action))
	_check(not pending.is_empty() and pending.outcome.action_id == snare.action_id, "failed writer retains exact Snare original")
	_check(_host.pending_move_mastery().size() == 1, "exactly one original waits for the failed writer")
	_check(FileAccess.get_file_as_bytes(_writer.world_store.path_for("resource-slot")) == old_world, "failed first journal leaves old disk bytes")
	_check(float(_wild.call("utility_movement_multiplier")) == 0.0, "landed Snare installs the actual movement root")
	_check(bool(_wild.call("protected_heavy_committed")), "Snare preserves the committed protected tell")
	_check(float(_host.move_resource_snapshot(_id, 1, _creature.uid).energy) == 0.0, "Snare never grants charged Energy")
	# The owner HUD snapshot contains a remaining cooldown computed from the
	# current clock. Compare the full canonical resource row/deadlines instead
	# so elapsed milliseconds cannot masquerade as a duplicate resource write.
	var energy_before: Dictionary = _host.record(_id).participants[1].move_resources[_creature.uid].duplicate(true)
	var original_before: Dictionary = _host.move_commit(_id, 1, int(snare.action)).duplicate(true)
	var hp_before := float(_enemy.hp)
	var duplicate: Dictionary = _director.call("_host_strike", {"encounter_id": _id,
		"action": snare.action, "slot": "utility", "move_id": "snare", "facing": Vector3.RIGHT}, 1)
	_check(duplicate.get("ok") == false, "same accepted strike cannot land twice")
	_check(_host.record(_id).participants[1].move_resources[_creature.uid] == energy_before, "replayed arrival cannot credit resources")
	_check(_host.move_commit(_id, 1, int(snare.action)) == original_before, "replayed arrival cannot change its original commit")
	_check(float(_enemy.hp) == hp_before, "replayed arrival cannot debit target HP")
	_writer.refuse_world = false
	var retained: Dictionary = _session.foundation_combat_mastery(_director, _id, 1, int(snare.action))
	_check(retained.get("durable") == true and _host.pending_move_mastery().is_empty(), "same original retries into a durable world row")
	var snare_event: Dictionary = _game.world.reward_deliveries.get(retained.get("delivery_id", ""), {}).duplicate(true)
	_check(snare_event.get("duties", []).size() == 1 and snare_event.duties[0].context.outcome.action_id == snare.action_id,
		"saved duty is bound to the original Snare action")
	# Build the meter by real accepted HP debits. No private meter/resource edit.
	for hit: int in 17:
		var quick := await _tap_move(JOY_BUTTON_X, "quick")
		_check(not quick.is_empty(), "physical quick %d did not land" % hit)
		if quick.is_empty(): break
		if slot_inputs and hit == 4:
			var charged := await _tap_move(JOY_BUTTON_Y, "charged")
			_check(not charged.is_empty(), "ordinary physical Y tap completes its charged move after release")
	if slot_inputs:
		await _wait_ready()
		var before_charged := _impacts.size()
		await _button(JOY_BUTTON_Y, true)
		var held_charged: Dictionary = _host.move_commit(_id, 1)
		_check(held_charged.get("slot") == "charged", "one fresh ordinary Y edge starts a charged move while held")
		var until_charged := Time.get_ticks_msec() + 5000
		while _impacts.size() == before_charged and Time.get_ticks_msec() < until_charged: await process_frame
		_check(_impacts.size() == before_charged + 1 and _impacts.back().slot == "charged"
			and float(_impacts.back().damage) > 0.0, "held Y completes one actual charged HP debit")
		for refill in 4:
			var quick := await _tap_move(JOY_BUTTON_X, "quick")
			_check(not quick.is_empty(), "real quick %d refills charged Energy while Y remains held" % refill)
		await _wait_ready()
		await physics_frame
		await process_frame
		var charged_launches := 0
		for launch: Dictionary in _launches:
			if launch.slot == "charged": charged_launches += 1
		_check(_manager.charged_ready() and is_equal_approx(float(_host.move_resource_snapshot(_id, 1, _creature.uid).energy), 100.0)
			and charged_launches == 2, "held Y never repeats even after actual hits restore full Energy and charged readiness")
		await _button(JOY_BUTTON_Y, false)
	_check(is_equal_approx(float(_host.move_resource_snapshot(_id, 1, _creature.uid).ultimate_meter), 100.0), "real landed hits fill the host Ultimate meter")
	_check(is_equal_approx(float(_manager.call("ultimate_fraction")), 1.0), "Manager snapshot mirrors the host's full meter")
	await process_frame
	await process_frame
	_check(shown_meter.is_visible_in_tree() and is_equal_approx(shown_meter.value, 100.0),
		"mounted actual CombatHUD shows the full landed-hit Ultimate meter")
	_check(shown_readout.is_visible_in_tree() and shown_readout.get_parsed_text().contains("Tap, then a move"),
		"mounted actual CombatHUD displays the full-meter ready instruction")
	if not _capture_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(_capture_dir)
		await RenderingServer.frame_post_draw
		var ready_path := _capture_dir.path_join("ultimate-ready.png")
		var ready_image := root.get_texture().get_image()
		_check(ready_image != null and ready_image.save_png(ready_path) == OK, "rendered actual full-meter CombatHUD capture " + ready_path)
		_captures.append(ready_path)
	var ultimate_event: Dictionary = {}
	if visual_override:
		await _wait_ready()
		await _button(JOY_BUTTON_RIGHT_SHOULDER, true)
		_check(not bool(_manager.call("ultimate_armed")), "RB hold cannot arm an ultimate")
		await _button(JOY_BUTTON_RIGHT_SHOULDER, false)
		_check(bool(_manager.call("ultimate_armed")), "RB release arms the next fresh face tap")
		var ultimate := await _tap_move(JOY_BUTTON_Y, "ultimate")
		_check(not ultimate.is_empty(), "released RB then Y must land the frozen signature")
		if not ultimate.is_empty():
			var latest: Dictionary = _impacts.back()
			_check(float(latest.damage) <= float(_enemy.max_hp) * 0.2 + 0.001, "ultimate respects the named-target HP cap")
			_check(is_equal_approx(float(_host.move_resource_snapshot(_id, 1, _creature.uid).ultimate_meter), 0.0), "ultimate spends the full per-UID meter once")
			await process_frame
			_check(shown_meter.is_visible_in_tree() and is_equal_approx(shown_meter.value, 0.0)
				and shown_readout.get_parsed_text().contains("0%"), "mounted actual CombatHUD redraws the spent Ultimate meter")
			var admitted_rank := MASTERY.rank_from_uses(_ultimate_prior_uses)
			_check(_launches.back().move.mastery_rank == admitted_rank and _launches.back().mastery_rank == admitted_rank,
				"launch and frozen move retain admitted mastery rank")
			_check(_launches.back().get("presentation_mounted") == true, "accepted Ground Current must create its actual ultimate presentation")
			for row: Variant in _game.world.reward_deliveries.values():
				if row is Dictionary and row.get("kind") == "foundation_event" and row.get("duties", []).size() == 1 \
					and row.duties[0].get("action") == "combat_mastery" and row.duties[0].intent.action_id == ultimate.action_id:
					ultimate_event = row.duplicate(true)
			if _ultimate_prior_uses < maximum_mastery:
				_check(not ultimate_event.is_empty(), "actual Ground Current arrival has its durable original")
			else:
				var original: Dictionary = _host.move_commit(_id, 1, int(ultimate.action))
				_check(original.get("resolved") == true and original.get("credited") == true
					and original.get("action_id") == ultimate.action_id and int(original.move.mastery_rank) == 5,
					"saturated rank-five hit retains its resolved and credited host original")
				_check(ultimate_event.is_empty() and _host.move_mastery_outcome(_id, 1, int(ultimate.action)).is_empty(),
					"saturated rank-five hit creates no further mastery award")
			await create_timer(2.6).timeout
	else:
		var before: Dictionary = _host.record(_id).participants[1].move_resources[_creature.uid].duplicate(true)
		var prior_commit: Dictionary = _host.move_commit(_id, 1, 99).duplicate(true)
		var refusal: Dictionary = _director.call("_host_move_start", {"encounter_id": _id, "slot": "ultimate", "action": 99}, 1)
		_check(refusal.get("code") == "move_not_mounted", "production visual gate refuses the ultimate at host ingress")
		_check(_host.record(_id).participants[1].move_resources[_creature.uid] == before, "gated ultimate leaves the entire canonical resource row unchanged")
		_check(_host.move_commit(_id, 1, 99) == prior_commit, "gated ultimate creates no original action commit")
	# End the disclosed fixture fight before the existing full-character carrier
	# is allowed to apply. This is not an authored victory/reward claim.
	_manager.set("state", MANAGER.State.INACTIVE)
	_manager.set_physics_process(false)
	_host.set_phase(_id, "done")
	_apply_saved_mastery(snare_event, "snare", 75)
	if not ultimate_event.is_empty(): _apply_saved_mastery(ultimate_event, "ultimate_ground_current", _ultimate_prior_uses)
	if _ultimate_prior_uses == maximum_mastery:
		_check(int(_creature.move_mastery_uses.get("ultimate_ground_current", 0)) == maximum_mastery
			and _creature.move_mastery_receipts.get("ultimate_ground_current", []) == prior_ultimate_history,
			"rank-five live mastery retains the exact capped history")
		var disk: Dictionary = _writer.character_store.read(DATA.CHARACTER)
		var saved_owned := {}
		for card: Dictionary in disk.get("party", []):
			if card.get("uid") == _creature.uid: saved_owned = card
		_check(saved_owned.get("uid") == _creature.uid
			and int(saved_owned.get("move_mastery_uses", {}).get("ultimate_ground_current", 0)) == maximum_mastery
			and saved_owned.get("move_mastery_receipts", {}).get("ultimate_ground_current", []) == prior_ultimate_history,
			"actual owner disk retains the same rank-five UID and exact capped history")
	if _prove_mastery_transition and not ultimate_event.is_empty():
		var previous_launch: Dictionary = _launches.back().duplicate(true)
		var learned_rank := MASTERY.rank_from_uses(_ultimate_prior_uses + 1)
		var learned_history: Array = prior_ultimate_history.duplicate()
		learned_history.append(ultimate_event.duties[0].intent.action_id)
		var saved_owned := {}
		for card: Dictionary in _writer.character_store.read(DATA.CHARACTER).get("party", []):
			if card.get("uid") == _creature.uid: saved_owned = card
		_check(saved_owned.get("uid") == _creature.uid
			and int(saved_owned.get("move_mastery_uses", {}).get("ultimate_ground_current", 0)) == _ultimate_prior_uses + 1
			and saved_owned.get("move_mastery_receipts", {}).get("ultimate_ground_current", []) == learned_history,
			"actual owner disk contains the earned threshold use and its exact original history")
		_check(learned_rank == int(previous_launch.mastery_rank) + 1,
			"the original positive Ultimate debit earns exactly the next mastery rank")
		# Reuse the admitted owner and existing production nodes for the next
		# disclosed fixture encounter. Target HP and all actor histories survive;
		# new encounter resources come only from the ordinary host opener.
		var target: Vector3 = _wild.call("centre")
		var rec: Dictionary = _host.open(1, "meadows", "trainer", {"species_id": "staticub",
			"creature_uid": _enemy.uid, "hp": _enemy.hp, "hp_max": _enemy.max_hp,
			"position": [target.x, target.y, target.z]}, str(_creature.uid), DATA.CHARACTER)
		_id = rec.encounter_id
		_director.set("_encounter", rec)
		_manager.call("bind_encounter", _director, _id, "trainer")
		_manager.set("state", MANAGER.State.ACTIVE)
		_manager.set_physics_process(true)
		_check(_host.move_resource_snapshot(_id, 1, _creature.uid).is_empty(),
			"next encounter retains no previous actor resource pool or Ultimate meter")
		for hit in 17:
			var quick := await _tap_move(JOY_BUTTON_X, "quick")
			_check(not quick.is_empty(), "real quick %d fills the next encounter meter after earned rank advancement" % hit)
			if quick.is_empty(): break
		_check(is_equal_approx(float(_host.move_resource_snapshot(_id, 1, _creature.uid).ultimate_meter), 100.0),
			"only actual landed hits refill the new encounter Ultimate meter")
		await _wait_ready()
		await _button(JOY_BUTTON_RIGHT_SHOULDER, true)
		await _button(JOY_BUTTON_RIGHT_SHOULDER, false)
		var upgraded := await _tap_move(JOY_BUTTON_Y, "ultimate")
		_check(not upgraded.is_empty(), "fresh RB release then Y lands the newly earned rank signature")
		if not upgraded.is_empty():
			var launch: Dictionary = _launches.back()
			_check(int(launch.mastery_rank) == learned_rank and int(launch.move.mastery_rank) == learned_rank,
				"new accepted action freezes the rank earned by the saved original")
			_check(is_equal_approx(float(launch.move.base_power), float(previous_launch.move.base_power))
				and float(launch.move.power) > float(previous_launch.move.power)
				and float(launch.move.power_multiplier) > float(previous_launch.move.power_multiplier),
				"the same live move has a strictly higher frozen damage profile after earned rank advancement")
			_check(int(launch.move.vfx.effect_tier) == learned_rank
				and int(launch.move.vfx.effect_tier) > int(previous_launch.move.vfx.effect_tier)
				and launch.get("presentation_mounted") == true,
				"the newly ranked actual presentation uses the upgraded frozen effect tier")
			_check(float(_impacts.back().damage) > 0.0 and float(_impacts.back().damage) <= float(_enemy.max_hp) * 0.2 + 0.001,
				"the upgraded signature commits a real positive HP debit within the unchanged named cap")
			await create_timer(2.6).timeout
	_check(MATH.config().get("actor_vitals", {}).get("runtime_enabled") == false, "proof must not activate actor_vitals")
	while _pending_library_captures > 0: await process_frame
	_finish()

func _setup() -> void:
	_directory = "user://f23_live_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	_world = Node3D.new()
	_world.name = "F23LiveStage"
	root.add_child(_world)
	current_scene = _world
	var fixture := DATA.new()
	_game = FixtureGame.new()
	_game.name = "Game"
	_game.local = fixture._player()
	_game.local.party.clear()
	_creature = SPECIES.spawn("bramblebun")
	_creature.set_level(5, PROGRESSION.config())
	_seed_prior_mastery("snare", 75)
	_seed_prior_mastery("ultimate_ground_current", _ultimate_prior_uses)
	_game.local.party.add(_creature)
	_game.world = fixture._world()
	root.add_child(_game)
	_session = FixtureSession.new()
	_session.name = "Session"
	_session.fixture = _game
	_game.session = _session
	_authority = AUTHORITY.new()
	_session.set("_character_authority", _authority)
	root.add_child(_session)
	_writer = SAVE.BoolWriter.new()
	_writer.world_store = preload("res://scripts/save/world_save.gd").new(_directory.path_join("worlds"))
	_writer.character_store = preload("res://scripts/save/character_save.gd").new(_directory.path_join("characters"))
	_game.save_system = _writer
	_rpc = FixtureRpc.new()
	_rpc.name = "LedgerRpc"
	_rpc.fixture = _game
	_rpc.ledger = preload("res://scripts/net/world_ledger.gd").new(_game.world)
	_session.add_child(_rpc)
	var before := RECORD.portable_projection(_game.local.save_data())
	_check(_authority.bind_world("resource-namespace"), "authority binds the actual fixture world")
	var admission: Dictionary = _authority.seed_admitted_character(before, DATA.CHARACTER)
	_check(admission.get("ok") == true, "canonical Bramblebun admission: " + str(admission))
	_check(_writer.save_world_prepared(_game, "resource-slot"), "initial world disk write")
	_check(_writer.save_character_prepared(_game, DATA.CHARACTER), "initial owner disk write")
	_ally = _body(FOLLOWER, "bramblebun", Vector3(-2.0, 0, 0))
	_ally.set("owner_peer_id", 1)
	_wild = _body(WILD, "staticub", Vector3(2.0, 0, 0))
	_enemy = SPECIES.spawn("staticub")
	_enemy.max_hp = 600.0 # Disclosed long-lived named target; no in-flight HP edits.
	_enemy.hp = 600.0
	_wild.set("instance", _enemy)
	_wild.set("trainer_owned", true)
	_wild.call("set_engaged", true, _ally)
	_wild.set("_intent", preload("res://scripts/combat/combat_ai.gd").Intent.TELEGRAPH)
	_wild.set("_selected_attack", {"heavy": true, "telegraph": 1.1})
	_ally.call("face_towards", _wild.global_position)
	_wild.call("face_towards", _ally.global_position)
	var player := CharacterBody3D.new()
	player.position = Vector3(-4.0, 0, -3.0)
	_world.add_child(player)
	_manager = MANAGER.new()
	_manager.name = "CombatManager"
	_world.add_child(_manager)
	_manager.set("_player", player)
	_manager.set("_wild", _wild)
	_manager.set("_ally_body", _ally)
	_manager.set("_enemy", _enemy)
	var party: Array[RefCounted] = [_creature]
	_manager.set("_party", party)
	_manager.call("_initialize_wind")
	_manager.set("state", MANAGER.State.ACTIVE)
	# Attach the exact production script after the bare node is ready, avoiding
	# the unrelated whole-biome population bootstrap. All called methods are real.
	_director = Node.new()
	_director.name = "EncounterDirector"
	_world.add_child(_director)
	_director.set_script(DIRECTOR)
	_director.call("_enter_tree") # Existing real source index; script attached after entry.
	_director.set_process(false)
	_director.set_physics_process(false)
	_director.set("_session", _session)
	_director.set("_manager", _manager)
	_director.set("_player", player)
	_director.set("_ally", _creature)
	_director.set("_ally_body", _ally)
	_director.set("_engaged_with", _wild)
	_director.call("_note_deployment_identity", 1, DATA.CHARACTER, str(_creature.uid))
	_director.call("_ensure_encounter_arbiters")
	_host = _director.get("_encounter_host")
	var target: Vector3 = _wild.call("centre")
	var rec: Dictionary = _host.open(1, "meadows", "trainer", {"species_id": "staticub",
		"creature_uid": _enemy.uid, "hp": _enemy.hp, "hp_max": _enemy.max_hp,
		"position": [target.x, target.y, target.z]}, str(_creature.uid), DATA.CHARACTER)
	_id = rec.encounter_id
	_director.set("_encounter", rec)
	_manager.call("bind_encounter", _director, _id, "trainer")
	_manager.connect("attack_launched", _on_launch)
	_manager.connect("impact_confirmed", _on_impact)
	_capture_stage()
	_hud = HUD.instantiate()
	_hud.set("manager_path", NodePath("../CombatManager"))
	_hud.set("director_path", NodePath("../EncounterDirector"))
	_world.add_child(_hud)

func _seed_prior_mastery(move_id: String, count: int) -> void:
	# Disclosed prior-history fixture: use the real staging helper to build a
	# complete canonical document, rather than claiming uses without receipts.
	for index: int in count:
		var staged := MASTERY.stage_landed_use(_creature, {
			"action_id": "fixture-prior:%s:%d" % [move_id, index],
			"move_id": move_id, "attacker_uid": _creature.uid,
			"target_uid": "fixture-prior-opponent", "target_hp_before": 1.0,
			"applied_damage": 1.0})
		if staged.get("ok") != true:
			_check(false, "prior mastery fixture refused %s at %d: %s" % [move_id, index, staged])
			return
		_creature.move_mastery_uses = staged.uses
		_creature.move_mastery_receipts = staged.receipts
	_check(MASTERY.valid_document(_creature.known_moves, _creature.move_mastery_uses,
		_creature.move_mastery_receipts, _creature.known_moves), "canonical prior mastery for " + move_id)

func _tap_move(button: JoyButton, slot: String) -> Dictionary:
	await _wait_ready()
	var previous := _impacts.size()
	await _button(button, true)
	var accepted: Dictionary = _host.move_commit(_id, 1)
	await _button(button, false)
	if accepted.get("slot") != slot:
		_check(false, "physical tap did not freeze expected %s: %s" % [slot, accepted])
		return {}
	var until := Time.get_ticks_msec() + 5000
	while _impacts.size() == previous and Time.get_ticks_msec() < until: await process_frame
	if _impacts.size() != previous + 1: return {}
	_check(_impacts.back().slot == slot, "arrival receipt retains %s" % slot)
	_check(float(_impacts.back().damage) > 0.0, "arrival has actual positive HP debit")
	if _prove_library_arrival:
		# Director keys presentation/HP feedback by encounter:peer:action.
		# The durable mastery original has its own identity; keep both intact.
		var presentation_id := "%s:%d:%d" % [_id, 1, int(accepted.action)]
		_check(str(_impacts.back().action_id) == presentation_id,
			"arrival receipt belongs to the accepted host action")
		var found := false
		for number: Label in _hud.get("_damage_numbers"):
			if is_instance_valid(number) and str(number.get_meta("receipt", {}).get("action_id", "")) == presentation_id:
				found = true
		_check(found, "actual CombatHUD creates the landed action's number after contact")
	return accepted

func _wait_ready() -> void:
	var until := Time.get_ticks_msec() + 6000
	while Time.get_ticks_msec() < until:
		if int(_manager.get("_action")) == MANAGER.Action.READY \
			and float(_manager.get("_hitstop_left")) <= 0.0 and float(_manager.get("_quick_cooldown")) <= 0.0:
			return
		await process_frame
	_check(false, "move recovery exceeded six seconds")

func _button(button: JoyButton, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await physics_frame
	await process_frame
	await physics_frame
	await process_frame

func _on_launch(_on_enemy: bool, launch: Dictionary, presentation: Node3D) -> void:
	var observed := launch.duplicate(true)
	observed["presentation_mounted"] = is_instance_valid(presentation)
	_launches.append(observed)
	if _prove_library_arrival and str(launch.slot) != "ultimate":
		var action_id := str(launch.action_id)
		_check(is_instance_valid(presentation), "library mounts the actual accepted action " + action_id)
		if is_instance_valid(presentation):
			var before := float(_enemy.hp)
			presentation.connect("arrived", func() -> void:
				_check(presentation.get("_impact") != null, "contact geometry exists before arrival " + action_id)
				_check(is_equal_approx(float(_enemy.hp), before), "target HP remains unchanged until visible contact " + action_id)
				for number: Label in _hud.get("_damage_numbers"):
					_check(str(number.get_meta("receipt", {}).get("action_id", "")) != action_id,
						"no actual HUD number precedes visible contact " + action_id)
				_arrival_records[action_id] = {"move_id": str(launch.move_id),
					"contact_frame": Engine.get_process_frames(), "hp_at_contact": float(_enemy.hp)}
				if not _capture_dir.is_empty() and not _captured_library_slots.has(str(launch.slot)):
					_captured_library_slots[str(launch.slot)] = true
					_capture_library_contact(action_id)
			, CONNECT_ONE_SHOT)
	if launch.slot == "ultimate" and not _capture_dir.is_empty(): _capture_ultimate(launch)

func _on_impact(on_enemy: bool, receipt: Dictionary, _where: Vector3) -> void:
	if not on_enemy: return
	_impacts.append(receipt.duplicate(true))
	if not _prove_library_arrival or str(receipt.slot) == "ultimate": return
	var action_id := str(receipt.action_id)
	_check(_arrival_records.has(action_id), "host impact follows the same action's visible contact " + action_id)
	if _arrival_records.has(action_id):
		_arrival_records[action_id]["impact_frame"] = Engine.get_process_frames()
		_arrival_records[action_id]["hp_after_impact"] = float(_enemy.hp)
		_check(float(_enemy.hp) < float(_arrival_records[action_id].hp_at_contact),
			"host applies positive HP debit after contact " + action_id)

func _capture_library_contact(action_id: String) -> void:
	_pending_library_captures += 1
	var sequence := _captured_library_slots.size() - 1
	DirAccess.make_dir_recursive_absolute(_capture_dir)
	await RenderingServer.frame_post_draw
	var path := _capture_dir.path_join("library-contact-%02d.png" % sequence)
	var rendered := root.get_texture().get_image()
	_check(rendered != null and rendered.save_png(path) == OK, "rendered library contact from the accepted action " + action_id)
	_captures.append(path)
	_arrival_records[action_id]["capture"] = path
	_arrival_records[action_id]["draw_frame"] = Engine.get_process_frames()
	_pending_library_captures -= 1

func _capture_ultimate(launch: Dictionary) -> void:
	var capture_directory := _capture_dir.path_join("rank-%d" % int(launch.mastery_rank)) if _prove_mastery_transition else _capture_dir
	DirAccess.make_dir_recursive_absolute(capture_directory)
	var previous := 0.0
	for at: float in [0.1, 0.35, 0.7, 1.2, 1.8, 2.25]:
		await create_timer(at - previous).timeout
		previous = at
		await RenderingServer.frame_post_draw
		var path := capture_directory.path_join("ground-current-%04d.png" % int(at * 1000.0))
		var rendered := root.get_texture().get_image()
		_check(rendered != null and rendered.save_png(path) == OK, "rendered accepted-action capture " + path)
		_captures.append(path)
	var file := FileAccess.open(capture_directory.path_join("accepted-action.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"launch": launch, "fixtures": "admitted level-5 Bramblebun; 600 HP static named target; visual gate enabled only for capture; no actor_vitals override", "captures": _captures}, "  "))

func _capture_stage() -> void:
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(35, 35)
	floor.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#586344")
	material.roughness = 1.0
	floor.material_override = material
	_world.add_child(floor)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -25, 0)
	light.light_energy = 1.8
	_world.add_child(light)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("#718292")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("#cad3de")
	environment.environment.ambient_light_energy = 0.7
	_world.add_child(environment)
	var camera := Camera3D.new()
	camera.position = Vector3(11, 8, 13)
	_world.add_child(camera)
	camera.look_at(Vector3(0, 1.4, 0))
	camera.current = true

func _apply_saved_mastery(event: Dictionary, move_id: String, initial: int) -> void:
	if event.is_empty(): return
	var duty: Dictionary = event.duties[0]
	var expected_receipts: Array = _creature.move_mastery_receipts.get(move_id, []).duplicate()
	_check(expected_receipts.size() == initial, "prior mastery history is complete for " + move_id)
	var maximum := int(MASTERY.config().rank_thresholds[4])
	if initial < maximum: expected_receipts.append(duty.intent.action_id)
	var context: Dictionary = duty.context.duplicate(true)
	var revision: int = _authority.revision(DATA.CHARACTER)
	context.merge({"character_id": DATA.CHARACTER, "expected_revision": revision,
		"in_range": true, "in_combat": false, "foundation_runtime_authorized": true,
		"retained_event": event.delivery_id})
	var token: Dictionary = _authority.stage_character_action(DATA.CHARACTER, revision, "combat_mastery", duty.intent, context)
	_check(token.get("ok") == true, "durable original stages " + move_id + ": " + str(token))
	if token.get("ok") != true: return
	var journal: Dictionary = _rpc.journal_creature_training_prepared(1, DATA.CHARACTER, _authority.staged_creature_training(token))
	_check(journal.get("durable") == true, "personal journal saved for " + move_id + ": " + str(journal))
	_authority.finish_creature_training(token, journal.get("durable") == true)
	if journal.get("durable") != true: return
	var row: Dictionary = _game.world.reward_deliveries[journal.delivery_id]
	var old_owner := FileAccess.get_file_as_bytes(_writer.character_store.path_for(DATA.CHARACTER))
	_writer.refuse_owner = true
	var failed := OWNER.apply_owner(_game, row)
	_check(failed.get("code") == "owner_action_save_failed", "actual owner save refusal for " + move_id)
	_check(FileAccess.get_file_as_bytes(_writer.character_store.path_for(DATA.CHARACTER)) == old_owner, "refused owner save preserves disk")
	_writer.refuse_owner = false
	var saved := OWNER.apply_owner(_game, row)
	_check(saved.get("saved") == true and saved.get("duplicate") == true, "owner retry saves without a second award")
	_check(int(_creature.move_mastery_uses.get(move_id, 0)) == mini(initial + 1, maximum), "one mastery use below cap or exact saturated count for " + move_id)
	_check(_creature.move_mastery_receipts.get(move_id, []) == expected_receipts,
		"exact canonical mastery receipt history for " + move_id)
	_check(_rpc._accept_creature_training(str(row.delivery_id), int(row.journal_revision), str(row.receipt), 1), "existing host ACK commits " + move_id)

func _finish() -> void:
	ULTIMATES._config = _saved_visual_config
	MOVE_LIBRARY.config()["enabled"] = _saved_library_enabled
	for button: JoyButton in [JOY_BUTTON_X, JOY_BUTTON_Y, JOY_BUTTON_B, JOY_BUTTON_A, JOY_BUTTON_RIGHT_SHOULDER]:
		var event := InputEventJoypadButton.new()
		event.button_index = button
		event.pressed = false
		Input.parse_input_event(event)
	print("F23_LIVE_MOVES " + JSON.stringify({"checks": _checks, "errors": _errors,
		"launches": _launches.size(), "impacts": _impacts.size(), "captures": _captures,
		"visual_gate_override": OS.get_cmdline_user_args().has("--enable-ultimate-visual"),
		"library_arrival_override": _prove_library_arrival, "arrival_records": _arrival_records,
		"claim": "focused fixture; no campaign, co-op, device or visual acceptance"}))
	if is_instance_valid(_world): _world.free()
	if is_instance_valid(_session): _session.free()
	if is_instance_valid(_game): _game.free()
	if not _directory.is_empty(): preload("res://tests/helpers/split_save_fixture.gd").wipe(_directory)
	quit(0 if _errors.is_empty() else 1)
