extends "res://tests/helpers/combat_depth_pilot.gd"

## Actual manager/body input pilot, extending the established C2 fixture.
## No HP/damage/authority simulator. This sees the displayed committed shape
## and past action state. Flat collider fixture does not prove world C3/co-op.
const TYPE_GRAPH := preload("res://scripts/combat/type_chart.gd")
const MOVE_DB := preload("res://scripts/creatures/move_db.gd")
const LIVE_FIXTURE := preload("res://tests/smoke_f23_live_moves.gd")
const OWNER_SAVE := preload("res://tests/test_foundation_resource_save.gd")
const OWNER_DATA := preload("res://tests/test_foundation_resources.gd")
const OWNER_RECORD := preload("res://scripts/net/character_record_rules.gd")
const OWNER_DIRECTOR := preload("res://scripts/combat/encounter_director.gd")
var context: Dictionary = {}
var _prepared_body := 0
var _combo_hooked_manager := 0
var _tell_seen_frame := -1
var _opening_seen_frame := -1
const INTERRUPT_MARGIN_S := 0.15
var _moves: RefCounted = MOVE_DB.new()
var _escape_dir := Vector3.ZERO
var _last_shape: Array = []
var _fields: Array[Dictionary] = []
var _pending_field: Dictionary = {}
var _owner_tree: SceneTree
var _owner_game: Node
var _owner_session: Node
var _owner_writer: RefCounted
var _owner_director: Node
var _saved_game: Node
var _saved_scene: Node
var _owner_error := ""
var _owner_binding: Dictionary = {}
var _owner_launches := 0
var _owner_impacts := 0


## Opt-in admission witness on the existing flat fixture. The first supported
## source is the actual single-creature Meadows trainer; other sources refuse.
## No global gates, combat state or live resources are manufactured here.
func fight(tree: SceneTree, party: Array[RefCounted], foes: Array,
		owned: bool, seed_value: int, policy: String) -> Dictionary:
	if context.get("canonical_owner") != true:
		return await super.fight(tree, party, foes, owned, seed_value, policy)
	_owner_tree = tree
	_saved_scene = tree.current_scene
	var spec: Dictionary = context.get("trainer_spec", {})
	if not owned or context.get("chapter") != "meadows" or party.size() != 5 \
		or foes.size() != 1 or spec.get("team", []).size() != 1 \
		or preload("res://scripts/world/trainer_npc.gd").trainer(str(spec.get("id", ""))) != spec:
		return {"won":false, "fixture_error":"canonical floor-owner witness requires five owned cards and one authored Meadows trainer opponent"}
	if not _prepare_owner(party):
		_release_owner()
		return {"won":false, "fixture_error":_owner_error}
	var result: Dictionary = await super.fight(tree, party, foes, owned, seed_value, policy)
	result["canonical_owner"] = not _owner_binding.is_empty() and _owner_error.is_empty()
	result["owner_binding"] = _owner_binding.duplicate(true)
	result["accepted_launches"] = _owner_launches
	result["accepted_impacts"] = _owner_impacts
	var disk: Dictionary = _owner_writer.get("character_store").call("read", OWNER_DATA.CHARACTER)
	result["owner_disk_party_count"] = disk.get("party", []).size()
	var saved_uses := 0
	for card: Dictionary in disk.get("party", []):
		for receipts: Variant in card.get("move_mastery_receipts", {}).values():
			if receipts is Array: saved_uses += receipts.size()
	result["saved_move_receipts"] = saved_uses
	if not _owner_error.is_empty(): result["fixture_error"] = _owner_error
	_release_owner()
	return result


func _prepare_owner(party: Array[RefCounted]) -> bool:
	var fixture := OWNER_DATA.new()
	_owner_game = LIVE_FIXTURE.FixtureGame.new()
	_owner_game.name = "Game"
	var local: RefCounted = fixture._player()
	local.party.clear()
	for creature: RefCounted in party:
		if local.party.add(creature) != true:
			_owner_error = "canonical five-card party admission refused"
			return false
	_owner_game.set("local", local)
	_owner_game.set("world", fixture._world())
	_saved_game = _owner_tree.root.get_node_or_null(^"Game")
	if _saved_game != null: _owner_tree.root.remove_child(_saved_game)
	_owner_tree.root.add_child(_owner_game)
	_owner_session = LIVE_FIXTURE.FixtureSession.new()
	_owner_session.name = "Session"
	_owner_session.set("fixture", _owner_game)
	_owner_game.set("session", _owner_session)
	var authority := preload("res://scripts/net/character_authority.gd").new()
	_owner_session.set("_character_authority", authority)
	_owner_tree.root.add_child(_owner_session)
	var directory := "user://f22_owner_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	_owner_writer = OWNER_SAVE.BoolWriter.new()
	_owner_writer.set("world_store", preload("res://scripts/save/world_save.gd").new(directory.path_join("worlds")))
	_owner_writer.set("character_store", preload("res://scripts/save/character_save.gd").new(directory.path_join("characters")))
	_owner_game.set("save_system", _owner_writer)
	var rpc := LIVE_FIXTURE.FixtureRpc.new()
	rpc.name = "LedgerRpc"
	rpc.fixture = _owner_game
	rpc.ledger = preload("res://scripts/net/world_ledger.gd").new(_owner_game.get("world"))
	_owner_session.add_child(rpc)
	var before := OWNER_RECORD.portable_projection(local.save_data())
	if not authority.bind_world("resource-namespace") \
		or authority.seed_admitted_character(before, OWNER_DATA.CHARACTER).get("ok") != true \
		or _owner_writer.call("save_world_prepared", _owner_game, "resource-slot") != true \
		or _owner_writer.call("save_character_prepared", _owner_game, OWNER_DATA.CHARACTER) != true:
		_owner_error = "real authority or initial BOOL disk writes refused"
		return false
	return true


func _mount_owner() -> bool:
	var world := _manager.get_parent()
	_owner_tree.current_scene = world
	_owner_director = Node.new()
	_owner_director.name = "EncounterDirector"
	world.add_child(_owner_director)
	_owner_director.set_script(OWNER_DIRECTOR)
	_owner_director.call("_enter_tree") # Same installed source-index entry as the existing live-moves fixture.
	_owner_director.set_process(false)
	_owner_director.set_physics_process(false)
	_owner_director.set("_session", _owner_session)
	_owner_director.set("_manager", _manager)
	_owner_director.set("_player", _manager.get("_player"))
	_owner_director.set("_ally", _manager.active_creature())
	_owner_director.set("_ally_body", _ally)
	_owner_director.set("_engaged_with", _wild)
	_owner_director.set("_trainer_body", _wild)
	_owner_director.set("_trainer_spec", context.trainer_spec.duplicate(true))
	_owner_director.call("_note_deployment_identity", 1, OWNER_DATA.CHARACTER, str(_manager.active_creature().uid))
	_owner_director.call("_ensure_encounter_arbiters")
	var host: RefCounted = _owner_director.get("_encounter_host")
	var enemy: RefCounted = _wild.get("instance")
	var target: Vector3 = _wild.call("centre")
	var opponent := {"species_id":str(enemy.species_id), "creature_uid":str(enemy.uid),
		"hp":enemy.hp, "hp_max":enemy.max_hp, "position":[target.x,target.y,target.z],
		"owner_npc":str(context.trainer_spec.id), "round":1, "body_generation":1,
		"card":preload("res://scripts/save/water_capture_codec.gd").encode(enemy)}
	var record: Dictionary = host.open(1, "meadows", "trainer", opponent,
		str(_manager.active_creature().uid), OWNER_DATA.CHARACTER)
	var id := str(record.get("encounter_id", ""))
	_owner_director.set("_encounter", record)
	_manager.bind_encounter(_owner_director, id, "trainer")
	if id.is_empty() or _owner_director.call("_install_ordinary_combat_reward_owner", id) != true \
		or _owner_director.call("uses_durable_trainer_rewards", id) != true:
		_owner_error = "real authored trainer owner installer refused"
		return false
	_owner_binding = _owner_director.call("_ordinary_actor_binding", id, 1, _ally)
	if _owner_binding.is_empty():
		_owner_error = "real current owned actor/body binding refused"
		return false
	_manager.bind_encounter(_owner_director, id, "trainer")
	_manager.creature_switched.connect(_owner_director._on_combat_creature_switched)
	_manager.attack_launched.connect(func(on_enemy: bool, launch: Dictionary, _presentation: Node3D) -> void:
		var original: Dictionary = host.move_commit(id, 1)
		if on_enemy and not original.is_empty() and original.get("slot") == launch.get("slot"): _owner_launches += 1)
	_manager.impact_confirmed.connect(func(on_enemy: bool, receipt: Dictionary, _where: Vector3) -> void:
		if on_enemy and float(receipt.get("damage", 0.0)) > 0.0 and str(receipt.get("action_id", "")).begins_with(id + ":1:"):
			_owner_impacts += 1)
	print("F22_CANONICAL_OWNER " + JSON.stringify({"binding":_owner_binding, "encounter_id":id,
		"trainer_id":context.trainer_spec.id, "party_count":_owner_session.call("admitted_character_state", 1).get("party", []).size(),
		"actor_vitals":MATH.config().actor_vitals, "acceptance":false}))
	return true


func _release_owner() -> void:
	if is_instance_valid(_owner_session): _owner_session.free()
	if is_instance_valid(_owner_game): _owner_game.free()
	if is_instance_valid(_saved_game) and not _saved_game.is_inside_tree(): _owner_tree.root.add_child(_saved_game)
	if is_instance_valid(_saved_scene): _owner_tree.current_scene = _saved_scene



func _act(policy: String) -> void:
	if context.get("canonical_owner") == true and not is_instance_valid(_owner_director):
		if not _mount_owner():
			_tally["fixture_error"] = _owner_error
			_manager.call("_begin_resolve", "fled")
			return
	if policy == "SWITCH_READER":
		var commands := preload("res://scripts/combat/tether_commands.gd")
		var snapshot: Dictionary = _manager.tether_command_snapshot()
		var mounted := false
		for child: Node in _manager.get_children():
			if child.get_script() == preload("res://scripts/ui/tether_command_input.gd"):
				mounted = true
				break
		_tally["tag_combo_available"] = commands.enabled() and mounted \
			and snapshot.get("unlocked_commands", []).has("tag_combo")
		if bool(_tally.tag_combo_available) and snapshot.get("active") == true and _manager.can_switch() \
			and not _manager.player_is_committed() and float(_manager.get("_hitstop_left")) <= 0.0 \
			and not bool(_manager.get("_ultimate_waiting_release")) and not _manager.ultimate_armed() \
			and int(_manager.call("_next_switchable_index", 1)) >= 0 \
			and float(snapshot.get("meter", 0.0)) >= float(commands.config().get("commands", {}).get("tag_combo", {}).get("cost", INF)) \
			and float(snapshot.get("combo_remaining_s", 0.0)) > 0.0:
			_press(commands.input_action("tag_combo"))
			return
	if is_instance_valid(_wild) and _prepared_body != _wild.get_instance_id():
		_prepared_body = _wild.get_instance_id()
		_tell_seen_frame = -1
		_opening_seen_frame = -1
		var patterns: Dictionary = MATH.config().get("patterns", {})
		if patterns.get("runtime_enabled") != true or not _wild.has_method("configure_patterns"):
			_tally["fixture_error"] = "actual F22 pattern consumer is disabled or absent"
			_manager.call("_begin_resolve", "fled")
			return
		var enemy: RefCounted = _wild.get("instance")
		var current := context.duplicate(true)
		current.merge({"species_id": str(enemy.get("species_id")),
			"role": str(context.get("role", AI.species_role(str(enemy.get("species_id")), patterns))),
			"trainer_owned": bool(_wild.get("trainer_owned")),
			"move_quick": str(enemy.get("move_quick")),
			"move_charged": str(enemy.get("move_charged"))}, true)
		current["sendout_index"] = int(_tally.get("f22_sendouts", 0))
		_tally["f22_sendouts"] = int(current.sendout_index) + 1
		_wild.call("configure_patterns", patterns, current, _visible_observation)
	if policy == "SWITCH_READER" and _manager.can_switch():
		_switch_for_matchup()
	_read(policy)


## COMBAT §7 reader: presses in neutral while keeping a wind reserve for one
## escape, reacts to a tell only after it has been visible for the declared
## observation delay, leaves the DISPLAYED strike geometry (walking when time
## allows, bursting when it does not) and spends its charged on recoveries.
## COMBAT §4's declared interrupt (coordinator ruling 2026-10-05): when the
## read tell still has longer to run than the charged windup plus
## INTERRUPT_MARGIN_S and the opponent is inside charged reach, it throws the
## charged INTO the tell instead of stepping out, as a reading player does.
## The margin is 0.15 s: about nine 60 Hz frames, covering the strike-reaim
## turn, one hitstop (charged 70 ms) and input-to-commit latency, so a charge
## that starts is one that lands before the opponent's strike.
## It reads the displayed committed shape and the recovery/stagger state, and
## times tells as a player who knows each pattern's authored length would
## (exact, via the body's beat clock; the base C2 pilot does the same). It
## never reads RNG or future input.
func _read(_policy: String) -> void:
	var telling := bool(_manager.enemy_is_winding_up())
	if not telling:
		_tell_seen_frame = -1
	elif _tell_seen_frame < 0:
		_tell_seen_frame = _frames
	var opening: bool = _manager.enemy_is_staggered() or int(_wild.intent()) == AI.Intent.RECOVER
	if not opening:
		_opening_seen_frame = -1
	elif _opening_seen_frame < 0:
		_opening_seen_frame = _frames
	if _manager.player_is_committed() or float(_manager.get("_hitstop_left")) > 0.0:
		return
	var delta := _wild.global_position - _ally.global_position
	delta.y = 0.0
	var distance := delta.length()
	var toward := delta.normalized()
	var reach: float = _manager.combat_move_reach("quick")
	var reserve: float = _manager.wind_cost("burst") + _manager.wind_cost("quick")
	var observed := float(MATH.config().get("patterns", {}).get("reactions", {}).get("observation_s", 0.25))
	var seen := float(_frames - _tell_seen_frame) / Engine.physics_ticks_per_second if telling else 0.0
	var masher := _policy == "MASHER"
	var waiting := bool(_manager.get("_ultimate_waiting_release"))
	var armed: bool = _manager.ultimate_armed()
	var latched := waiting or armed
	if not masher: _note_fields(telling)
	var ultimate_creature: RefCounted = _manager.active_creature()
	if ultimate_creature != null and not waiting and not bool(_manager.get("_ultimate_face_release")) \
		and not bool(_manager.get("_move_awaiting_host")) and _manager.ultimate_fraction() >= 1.0 \
		and _manager.combat_input_available() and _manager.call("_uses_host_move_start") == true:
		var ultimate_id := str(ultimate_creature.get("move_ultimate"))
		var ultimate_row: Dictionary = _moves.move(ultimate_id)
		if ultimate_row.get("slot") == "ultimate" and ultimate_creature.get("known_moves").has(ultimate_id) \
			and MANAGER.live_move_supported("ultimate", ultimate_id) \
			and _manager.wind_value() >= float(ultimate_row.get("wind_cost", INF)):
			var profile: Dictionary = _manager.call("_with_reach_for_the_bodies", _manager.call("_move_profile", "player_ultimate", ultimate_id))
			var read_opening: bool = not telling and opening \
				and float(_frames - _opening_seen_frame) / Engine.physics_ticks_per_second >= observed
			var fits: bool = read_opening and float(_wild.get("_beat_left")) > float(profile.get("windup", INF)) + (0.0 if armed else 2.0 / Engine.physics_ticks_per_second) \
				and MATH.move_connects(profile, _ally.call("centre"), _ally.call("facing"), _wild.call("centre")) \
				and _field_exit() == Vector3.ZERO and _manager.wind_value() >= float(ultimate_row.get("wind_cost", INF)) + _manager.wind_cost("burst")
			if masher or fits:
				_press("combat_quick" if armed else "combat_ultimate_arm")
				return
	if masher:
		if not latched:
			# COMBAT §7: spend an available utility without reading the foe.
			if _manager.utility_ready() and not bool(_manager.get("_move_awaiting_host")):
				var creature: RefCounted = _manager.active_creature()
				var move_id := str(creature.get("move_utility"))
				if _moves.move(move_id).get("slot") == "utility" and creature.get("known_moves").has(move_id):
					_press("combat_utility")
					return
			super._act("MASHER")
		return
	if not latched and telling and seen >= observed and _manager.charged_ready() \
			and not bool(_wild.call("protected_heavy_committed") if _wild.has_method("protected_heavy_committed") else false) \
			and distance < _manager.combat_move_reach("charged") - 0.15 \
			and _manager.wind_value() >= _manager.wind_cost("charged"):
		var charged_profile: Dictionary = _manager.call("_move_profile", "player_charged", str(_manager.active_creature().move_charged))
		var windup := float(charged_profile.get("windup", 0.55)) * float(MATH.config().get("player_pace", {}).get("windup_scale", 1.0))
		if float(_wild.get("_beat_left")) > windup + INTERRUPT_MARGIN_S:
			_press("combat_charged")
			_tally["read_interrupts"] = int(_tally.get("read_interrupts", 0)) + 1
			return
	if telling and seen >= observed:
		var escape := _escape_from_tell()
		if not escape.is_empty():
			# A tracking marker or heading follows whoever moves: spending the
			# burst before it visibly stops is wasted. Walk the chosen exit
			# and keep it while it still leads out, so the stick does not
			# jitter between equal exits.
			var locked := _shape_locked()
			if _escape_dir != Vector3.ZERO and float(escape.get("own_distance", INF)) <= float(escape.distance) + 0.75:
				escape.direction = _escape_dir
				escape.distance = escape.own_distance
				escape.walk_s = float(escape.distance) / maxf(0.1, _speed())
			_escape_dir = escape.direction
			_walk(_escape_dir)
			# The burst is a fixed hop that nothing follows up: walk first and
			# spend it to finish the exit, or as the last chance before release.
			var hop := float(MATH.config().get("burst", {}).get("distance", 3.0)) - 0.2
			var finishes := float(escape.distance) <= hop and float(escape.walk_s) > float(escape.time_left) - 0.05
			var last_chance := float(escape.time_left) <= 0.35 and float(escape.walk_s) > float(escape.time_left) - 0.05
			if locked and (finishes or last_chance) \
					and _manager.wind_value() >= _manager.wind_cost("burst"):
				_press("jump")
				_tally.burst_uses += 1
			_tally["read_escapes"] = int(_tally.get("read_escapes", 0)) + 1
			return
		# Outside the shown shape: strike if a quick lands first, else hold,
		# never spending the burst the next exit may need.
		if not latched and distance <= reach - 0.25 and _manager.quick_ready() \
				and _manager.wind_value() >= reserve:
			_press("combat_quick")
		return
	if telling:
		# The tell is visible but not yet read: keep moving as before and
		# start no new commitment; the reaction itself waits the full delay.
		if not _manager.player_is_committed() and distance > reach - 0.25: _walk(_around_fields(toward))
		return
	_escape_dir = Vector3.ZERO
	var field_exit := _field_exit()
	if field_exit != Vector3.ZERO:
		_walk(field_exit)
		# A released fan is still in the air: finish the exit with the burst.
		if _fan_in_flight() and _manager.wind_value() >= _manager.wind_cost("burst"):
			_press("jump")
			_tally.burst_uses += 1
		return
	if latched: return
	if opening:
		# Read the opening before committing; released field/fan evasion above still wins.
		if float(_frames - _opening_seen_frame) / Engine.physics_ticks_per_second < observed:
			return
		var window := float(_wild.get("_beat_left"))
		if _manager.utility_ready() and not bool(_manager.get("_move_awaiting_host")):
			var active: RefCounted = _manager.active_creature()
			var utility_id := str(active.get("move_utility"))
			var row: Dictionary = _moves.move(utility_id)
			var effect: Dictionary = row.get("utility", {})
			var utility: Dictionary = _manager.call("_with_reach_for_the_bodies", _manager.call("_move_profile", "player_utility", utility_id))
			var heal: bool = effect.get("kind") == "heal" and effect.get("scope") == "self" \
				and float(active.call("hp_fraction")) <= 1.0 - float(effect.get("max_hp_fraction", 1.0))
			var root_setup: bool = effect.get("kind") == "root" and effect.get("scope") == "target" \
				and MATH.move_connects(utility, _ally.call("centre"), _ally.call("facing"), _wild.call("centre"))
			if row.get("slot") == "utility" and active.get("known_moves").has(utility_id) and (heal or root_setup) \
				and window >= float(utility.get("windup", INF)) + float(utility.get("recovery", INF)) \
				and _manager.wind_value() >= float(row.get("wind_cost", INF)) + _manager.wind_cost("burst"):
				_press("combat_utility")
				return
		var charged: Dictionary = _manager.call("_move_profile", "player_charged", str(_manager.active_creature().move_charged))
		if distance > reach - 0.25:
			_walk(_around_fields(toward))
			return
		if _manager.charged_ready() and distance < _manager.combat_move_reach("charged") - 0.15 \
				and window > float(charged.get("windup", 0.55)) * float(MATH.config().get("player_pace", {}).get("windup_scale", 1.0)) + 0.1 \
				and _manager.wind_value() >= _manager.wind_cost("charged") + _manager.wind_cost("burst"):
			_press("combat_charged")
		elif _manager.quick_ready() and (_manager.enemy_is_staggered() or _manager.wind_value() >= reserve):
			_press("combat_quick")
		return
	if _manager.wind_value() < reserve:
		# Keep the escape affordable: hold just outside the opponent's reach.
		var enemy_reach := float(_wild.combat_config().get("range", 2.6))
		if distance < enemy_reach + 0.5: _retreat(toward)
		return
	if distance > reach - 0.25:
		_walk(_around_fields(toward))
	elif _manager.quick_ready():
		_press("combat_quick")


func _speed() -> float:
	return float(MATH.config().get("creature_movement", {}).get("speed", 5.6))


## The visible shape has stopped following: marker and heading unchanged
## since the previous physics frame.
func _shape_locked() -> bool:
	var geometry: Dictionary = _wild.call("pattern_geometry") if _wild.has_method("pattern_geometry") else {}
	var now := [geometry.get("marker", Vector3.ZERO), geometry.get("heading", Vector3.ZERO)]
	# Only a shape that stayed put while this body moved has visibly locked;
	# standing still would make a still-tracking shape look locked.
	var here: Vector3 = _ally.global_position
	var moved := _last_shape.size() == 3 and Vector2(here.x - (_last_shape[2] as Vector3).x,
		here.z - (_last_shape[2] as Vector3).z).length() > 0.03
	var locked := moved and (now[0] as Vector3).is_equal_approx(_last_shape[0]) \
		and (now[1] as Vector3).is_equal_approx(_last_shape[1])
	now.append(here)
	_last_shape = now
	if geometry.is_empty():
		return bool(_wild.get("_selected_heading_locked"))
	return locked


## Released fans stay dangerous for their visible flight and fields for
## their drawn lifetime. Remember each shape this reader saw committed, with
## its frozen geometry, and stay out of it until it expires.
func _note_fields(telling: bool) -> void:
	if telling and _wild.has_method("pattern_geometry"):
		var geometry: Dictionary = _wild.call("pattern_geometry")
		var profile: Dictionary = geometry.get("profile", {})
		var shape := str(profile.get("telegraph_shape", ""))
		var after := 0.0
		if shape == "field": after = float(profile.get("field_duration_s", 3.0))
		elif shape == "fan": after = float(MATH.config().get("patterns", {}).get("casts", {}).get("fan_travel_s", 0.3)) + 0.05
		_pending_field = {} if after <= 0.0 else {"profile": profile, "origin": geometry.origin,
			"heading": geometry.heading, "marker": geometry.marker,
			"until": _frames + int((float(_wild.get("_beat_left")) + after) * Engine.physics_ticks_per_second)}
	elif not _pending_field.is_empty():
		_fields.append(_pending_field)
		_pending_field = {}
	var live: Array[Dictionary] = []
	for row: Dictionary in _fields:
		if int(row.until) > _frames: live.append(row)
	_fields = live


func _in_field(point: Vector3, margin: float) -> Dictionary:
	for row: Dictionary in _fields:
		if AI.pattern_contains(row.profile, row.origin, row.heading, row.marker, point, margin):
			return row
	return {}


func _fan_in_flight() -> bool:
	var radius := float(_ally.call("body_radius")) + 0.2
	var row := _in_field(_ally.global_position, radius)
	return not row.is_empty() and str((row.profile as Dictionary).get("telegraph_shape", "")) == "fan"


func _field_exit() -> Vector3:
	var radius := float(_ally.call("body_radius")) + 0.2
	if _in_field(_ally.global_position, radius).is_empty(): return Vector3.ZERO
	var best := Vector3.ZERO
	var best_step := INF
	for index: int in 8:
		var direction := Vector3.FORWARD.rotated(Vector3.UP, TAU * index / 8.0)
		var step := 0.25
		while step <= 6.0 and step < best_step:
			if _in_field(_ally.global_position + direction * step, radius).is_empty():
				best = direction
				best_step = step
				break
			step += 0.25
	return best if best != Vector3.ZERO else Vector3.RIGHT


func _around_fields(toward: Vector3) -> Vector3:
	var margin := float(_ally.call("body_radius")) + 0.3
	if _in_field(_ally.global_position + toward * 0.6, margin).is_empty(): return toward
	var tangent := toward.cross(Vector3.UP)
	for side: Vector3 in [tangent, -tangent]:
		if _in_field(_ally.global_position + side * 0.6, margin).is_empty(): return side
	return Vector3.ZERO


## The shortest exit from the committed tell, searched over eight headings in
## the actual arena. Empty when the reader is already outside the shape.
func _escape_from_tell() -> Dictionary:
	var profile := {}
	var origin := _wild.global_position
	var heading: Vector3 = _wild.call("facing") if _wild.has_method("facing") else Vector3.FORWARD
	var marker := origin
	if _wild.has_method("pattern_geometry"):
		var geometry: Dictionary = _wild.call("pattern_geometry")
		if not (geometry.get("profile", {}) as Dictionary).is_empty():
			profile = geometry.profile
			origin = geometry.origin
			heading = geometry.heading
			marker = geometry.marker
	if profile.is_empty():
		var cfg: Dictionary = _wild.combat_config()
		if _wild.has_method("lunge_travels") and bool(_wild.call("lunge_travels")):
			var scale := float(MATH.config().get("charger_lunge", {}).get("contact_scale", 1.2))
			profile = {"telegraph_shape": "lane", "lunge": float(cfg.get("lunge", 0.0)),
				"lane_half_width_m": (_ally.body_radius() + _wild.body_radius()) * scale}
		else:
			profile = {"telegraph_shape": "cone", "range": float(cfg.get("range", 2.6)) + 0.35,
				"cone_degrees": float(cfg.get("cone_degrees", 90.0))}
	var radius := float(_ally.call("body_radius")) + 0.3
	var here: Vector3 = _ally.global_position
	if not AI.pattern_contains(profile, origin, heading, marker, here, radius):
		return {}
	var arena: Node3D = _manager.arena()
	var limit := float(arena.get("radius")) - radius - 0.5
	var speed := float(MATH.config().get("creature_movement", {}).get("speed", 5.6))
	var outward := here - arena.global_position
	outward.y = 0.0
	outward = outward.normalized() if outward.length() > 0.05 else Vector3.ZERO
	var best := {}
	var best_cost := INF
	for index: int in 16:
		var direction := Vector3.FORWARD.rotated(Vector3.UP, TAU * index / 16.0)
		var step := 0.25
		while step <= 6.0:
			var point := here + direction * step
			var flat := Vector2(point.x - arena.global_position.x, point.z - arena.global_position.z)
			if flat.length() > limit: break
			if not AI.pattern_contains(profile, origin, heading, marker, point, radius):
				# Prefer exits that do not run toward the arena edge, where the
				# body slides and the next tell has no room.
				var cost := step + maxf(0.0, direction.dot(outward)) * 0.75
				if cost < best_cost:
					best_cost = cost
					best = {"direction": direction, "distance": step}
				break
			step += 0.25
	if best.is_empty():
		best = {"direction": -(_wild.global_position - here).normalized(), "distance": 6.0}
	if _escape_dir != Vector3.ZERO:
		var step := 0.25
		while step <= 6.0:
			if not AI.pattern_contains(profile, origin, heading, marker, here + _escape_dir * step, radius):
				best["own_distance"] = step
				break
			step += 0.25
	best["walk_s"] = float(best.distance) / maxf(0.1, speed)
	var travel := float(MATH.config().get("patterns", {}).get("casts", {}).get("fan_travel_s", 0.3)) \
		if str(profile.get("telegraph_shape", "")) == "fan" else 0.0
	best["time_left"] = float(_wild.get("_beat_left")) + travel
	return best


func _visible_observation() -> Dictionary:
	var action := int(_manager.get("_action"))
	var move: Dictionary = _manager.get("_pending_move") as Dictionary
	var label := "ready"
	if action == MANAGER.Action.WINDUP:
		label = "quick_windup" if bool(move.get("is_quick", true)) else "charged_windup"
	elif action == MANAGER.Action.RECOVERY:
		label = "recovery"
	var towards := _ally.global_position - _wild.global_position
	towards.y = 0.0
	var step := towards.normalized().cross(Vector3.UP) * 3.0
	var end := _wild.global_position + step
	var arena: Node3D = _wild.get("arena") as Node3D
	var safe: bool = arena != null and Vector2(end.x - arena.global_position.x,
		end.z - arena.global_position.z).length() + _wild.body_radius() <= float(arena.get("radius")) \
		and not _wild.test_move(_wild.global_transform, step)
	return {"action": label, "creature_uid": str(_manager.active_creature().get("uid")),
		"distance": towards.length(), "quick_range": float(_wild.combat_config().get("range", 0.0)),
		"safe_dodge_lane": safe, "side_sign": 1.0}


func _switch_for_matchup() -> void:
	var party: Array = _manager.get("_party")
	var enemy: RefCounted = _wild.get("instance")
	var active := int(_manager.get("_active_index"))
	var best := active
	var best_value := -INF
	var candidates: Array[int] = [active]
	candidates.append_array(_manager.switchable_indices())
	# A benched creature keeps its own health (COMBAT §12.3, per-identity
	# resources): a reader pulls a nearly spent lead before it falls, and
	# among healthy candidates chooses by visible type matchup.
	var spent: bool = float((party[active] as RefCounted).call("hp_fraction")) < 0.3
	for index: int in candidates:
		var creature: RefCounted = party[index]
		if index != active and float(creature.call("hp_fraction")) < (0.6 if spent else 0.3): continue
		var outgoing := TYPE_GRAPH.multiplier_dual(_moves.call("type_of", str(creature.get("move_quick"))),
			str(enemy.get("creature_type")), str(enemy.get("secondary_type")))
		var incoming := TYPE_GRAPH.multiplier_dual(_moves.call("type_of", str(enemy.get("move_quick"))),
			str(creature.get("creature_type")), str(creature.get("secondary_type")))
		var value := outgoing / maxf(0.01, incoming)
		if spent and index == active: value = -1.0
		if value > best_value:
			best_value = value
			best = index
	if best == active:
		return
	var caller := "request_tag_switch" if _manager.has_method("request_tag_switch") else "request_switch"
	if bool(_manager.call(caller, best)):
		_tally["switches"] = int(_tally.get("switches", 0)) + 1


func _on_tag_combo_resolved(result: Dictionary) -> void:
	var strikes: Array = result.get("strikes", [])
	if strikes.size() != 2 or str(result.get("switched_to_uid", "")).is_empty(): return
	var parts := {}
	for row: Dictionary in strikes:
		if str(row.get("attacker_uid", "")).is_empty() or int(row.get("generation", 0)) < 1 \
				or str(row.get("action_id", "")).is_empty() or row.get("landed") != true \
				or float(row.get("actual_hp_debit", 0.0)) <= 0.0: return
		parts[str(row.get("part", ""))] = row
	if not parts.has("incoming") or not parts.has("outgoing") \
			or parts.incoming.attacker_uid != result.switched_to_uid \
			or parts.outgoing.attacker_uid == parts.incoming.attacker_uid: return
	_tally["tag_combos"] = int(_tally.get("tag_combos", 0)) + 1
	(_tally.events as Array).append({"event": "accepted_tag_combo", "result": result.duplicate(true)})
