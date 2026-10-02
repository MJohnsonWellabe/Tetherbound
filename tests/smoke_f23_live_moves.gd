extends SceneTree

## Focused production-node proof, not a campaign/co-op or visual acceptance.
## Fixtures: one admitted level-5 Bramblebun with prior mastery, a static named
## opponent with 600 HP, a flat capture stage, and no autonomous AI/movement.
## Real physical taps drive CombatManager -> Director -> AcceptedActionHost;
## the real host timer writes HP and Session journals that exact original.
## --enable-ultimate-visual is the ONLY feature override. --capture-dir=<path>
## saves rendered frames of the same accepted action for independent judging.
const SAVE := preload("res://tests/test_foundation_resource_save.gd")
const DATA := preload("res://tests/test_foundation_resources.gd")
const AUTHORITY := preload("res://scripts/net/character_authority.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const OWNER := preload("res://scripts/net/character_action_owner.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const BODY := preload("res://scenes/creatures/creature.tscn")
const FOLLOWER := preload("res://scripts/creatures/follower_creature.gd")
const WILD := preload("res://scripts/creatures/wild_creature.gd")
const DIRECTOR := preload("res://scripts/combat/encounter_director.gd")
const MANAGER := preload("res://scripts/combat/combat_manager.gd")
const ULTIMATES := preload("res://scripts/vfx/ultimates/ultimate_library.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")

class FixtureGame extends SAVE.FixtureGame:
	var party: RefCounted:
		get: return local.party
	var realm_hearts: RefCounted
	var progression: RefCounted
	var current_realm := "meadows"
	var messages: Array[String] = []
	func push_world_message(message: String) -> void: messages.append(message)

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
var _ally: Node3D
var _wild: Node3D
var _creature: RefCounted
var _enemy: RefCounted
var _host: RefCounted
var _id := ""
var _directory := ""
var _capture_dir := ""
var _launches: Array[Dictionary] = []
var _impacts: Array[Dictionary] = []
var _captures: Array[String] = []
var _saved_visual_config: Dictionary

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
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): _capture_dir = arg.trim_prefix("--capture-dir=")
	_saved_visual_config = ULTIMATES.config()
	var visual_override := OS.get_cmdline_user_args().has("--enable-ultimate-visual")
	if visual_override:
		var candidate := _saved_visual_config.duplicate(true)
		candidate.enabled = true
		ULTIMATES._config = candidate
	_check(MATH.config().get("actor_vitals", {}).get("runtime_enabled") == false, "actor_vitals gate must remain off")
	_check(_capture_dir.is_empty() or DisplayServer.get_name() != "headless", "render capture requires an actual display")
	if not _errors.is_empty():
		_finish()
		return
	_setup()
	await process_frame
	if not _errors.is_empty():
		_finish()
		return
	var old_world := FileAccess.get_file_as_bytes(_writer.world_store.path_for("resource-slot"))
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
	var energy_before: Dictionary = _host.move_resource_snapshot(_id, 1, _creature.uid)
	var duplicate: Dictionary = _director.call("_host_strike", {"encounter_id": _id,
		"action": snare.action, "slot": "utility", "move_id": "snare", "facing": Vector3.RIGHT}, 1)
	_check(duplicate.get("ok") == false, "same accepted strike cannot land twice")
	_check(_host.move_resource_snapshot(_id, 1, _creature.uid) == energy_before, "replayed arrival cannot credit resources")
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
	_check(is_equal_approx(float(_host.move_resource_snapshot(_id, 1, _creature.uid).ultimate_meter), 100.0), "real landed hits fill the host Ultimate meter")
	_check(is_equal_approx(float(_manager.call("ultimate_fraction")), 1.0), "HUD meter mirrors the host's full meter")
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
			_check(_launches.back().move.mastery_rank == 4 and _launches.back().mastery_rank == 4, "launch and frozen move retain admitted mastery rank")
			_check(_launches.back().get("presentation_mounted") == true, "accepted Ground Current must create its actual ultimate presentation")
			for row: Variant in _game.world.reward_deliveries.values():
				if row is Dictionary and row.get("kind") == "foundation_event" and row.get("duties", []).size() == 1 \
					and row.duties[0].get("action") == "combat_mastery" and row.duties[0].intent.action_id == ultimate.action_id:
					ultimate_event = row.duplicate(true)
			_check(not ultimate_event.is_empty(), "actual Ground Current arrival has its durable original")
			await create_timer(2.6).timeout
	else:
		var before: Dictionary = _host.move_resource_snapshot(_id, 1, _creature.uid)
		var refusal: Dictionary = _director.call("_host_move_start", {"encounter_id": _id, "slot": "ultimate", "action": 99}, 1)
		_check(refusal.get("code") == "move_not_mounted", "production visual gate refuses the ultimate at host ingress")
		_check(_host.move_resource_snapshot(_id, 1, _creature.uid) == before, "gated ultimate does not spend a full meter")
	# End the disclosed fixture fight before the existing full-character carrier
	# is allowed to apply. This is not an authored victory/reward claim.
	_manager.set("state", MANAGER.State.INACTIVE)
	_manager.set_physics_process(false)
	_host.set_phase(_id, "done")
	_apply_saved_mastery(snare_event, "snare", 75)
	if not ultimate_event.is_empty(): _apply_saved_mastery(ultimate_event, "ultimate_ground_current", 150)
	_check(MATH.config().get("actor_vitals", {}).get("runtime_enabled") == false, "proof must not activate actor_vitals")
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
	_creature.move_mastery_uses = {"snare": 75, "ultimate_ground_current": 150}
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
	_world.add_child(_director)
	_director.set_script(DIRECTOR)
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
	_manager.connect("impact_confirmed", func(on_enemy: bool, receipt: Dictionary, _where: Vector3) -> void:
		if on_enemy: _impacts.append(receipt.duplicate(true)))
	_capture_stage()

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
	if launch.slot == "ultimate" and not _capture_dir.is_empty(): _capture_ultimate(launch)

func _capture_ultimate(launch: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(_capture_dir)
	var previous := 0.0
	for at: float in [0.1, 0.35, 0.7, 1.2, 1.8, 2.25]:
		await create_timer(at - previous).timeout
		previous = at
		await RenderingServer.frame_post_draw
		var path := _capture_dir.path_join("ground-current-%04d.png" % int(at * 1000.0))
		var rendered := root.get_texture().get_image()
		_check(rendered != null and rendered.save_png(path) == OK, "rendered accepted-action capture " + path)
		_captures.append(path)
	var file := FileAccess.open(_capture_dir.path_join("accepted-action.json"), FileAccess.WRITE)
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
	var context: Dictionary = duty.context.duplicate(true)
	var revision: int = _authority.revision(DATA.CHARACTER)
	context.merge({"character_id": DATA.CHARACTER, "expected_revision": revision,
		"in_range": true, "in_combat": false, "foundation_runtime_authorized": true,
		"retained_event": event.delivery_id})
	var token: Dictionary = _authority.stage_character_action(DATA.CHARACTER, revision, "combat_mastery", duty.intent, context)
	_check(token.get("ok") == true, "durable original stages " + move_id + ": " + str(token))
	if token.get("ok") != true: return
	var journal: Dictionary = _rpc.journal_creature_training_prepared(1, DATA.CHARACTER, _authority.staged_creature_training(token))
	_check(journal.get("durable") == true, "personal journal saved for " + move_id)
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
	_check(int(_creature.move_mastery_uses.get(move_id, 0)) == initial + 1, "one mastery use for " + move_id)
	_check(_creature.move_mastery_receipts.get(move_id, []) == [duty.intent.action_id], "one exact accepted-action receipt for " + move_id)
	_check(_rpc._accept_creature_training(str(row.delivery_id), int(row.journal_revision), str(row.receipt), 1), "existing host ACK commits " + move_id)

func _finish() -> void:
	ULTIMATES._config = _saved_visual_config
	for button: JoyButton in [JOY_BUTTON_X, JOY_BUTTON_Y, JOY_BUTTON_B, JOY_BUTTON_RIGHT_SHOULDER]:
		var event := InputEventJoypadButton.new()
		event.button_index = button
		event.pressed = false
		Input.parse_input_event(event)
	print("F23_LIVE_MOVES " + JSON.stringify({"checks": _checks, "errors": _errors,
		"launches": _launches.size(), "impacts": _impacts.size(), "captures": _captures,
		"visual_gate_override": OS.get_cmdline_user_args().has("--enable-ultimate-visual"),
		"claim": "focused fixture; no campaign, co-op, device or visual acceptance"}))
	if is_instance_valid(_world): _world.free()
	if is_instance_valid(_session): _session.free()
	if is_instance_valid(_game): _game.free()
	if not _directory.is_empty(): preload("res://tests/helpers/split_save_fixture.gd").wipe(_directory)
	quit(0 if _errors.is_empty() else 1)
