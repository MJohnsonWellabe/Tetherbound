extends RefCounted

## Two policies over the actual combat manager, wild AI and CharacterBody3D.
## No duplicate damage, poise, wind, action-clock or collision simulation.
## The flat fixture isolates combat from world streaming; production-world
## smokes remain necessary for terrain, encounter transitions and input routing.
const MANAGER := preload("res://scripts/combat/combat_manager.gd")
const BODY := preload("res://scripts/creatures/creature_body.gd")
const WILD := preload("res://scripts/creatures/wild_creature.gd")
const SCENE := preload("res://scenes/creatures/creature.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const AI := preload("res://scripts/combat/combat_ai.gd")

var _manager: Node
var _ally: CharacterBody3D
var _wild: CharacterBody3D
var _tally: Dictionary
var _pressed: String = ""
var _frames := 0
var _incoming_windup := false
var _enemy_windup_before_tick := false
var _last_action: int = MANAGER.Action.READY
var _entry_maxima: Dictionary = {}


func fight(tree: SceneTree, party: Array[RefCounted], foes: Array,
		owned: bool, seed_value: int, policy: String) -> Dictionary:
	_tally = {"won": false, "seconds": 0.0, "faints": 0,
		"max_hit_frac": 0.0, "lead_lost_frac": 0.0, "party_lost_frac": 0.0,
		"stalled": false, "hits": 0, "incoming_hits": 0, "misses": 0,
		"player_windup_cancellations": 0, "charged_interrupts": 0,
		"stagger_events": 0, "exhausted_frames": 0, "events": [],
		"burst_uses": 0, "charged_uses": 0, "quick_uses": 0,
		"seed": seed_value, "pilot": policy, "physics_frames": 0}
	var party_max := 0.0
	for member in party:
		party_max += float(member.max_hp)
		_entry_maxima[member.get_instance_id()] = float(member.max_hp)
	var lead: RefCounted = party[0]
	var world := Node3D.new()
	world.name = "CombatDepthFixture"
	tree.root.add_child(world)
	var floor_body := StaticBody3D.new()
	var floor_collision := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(100.0, 1.0, 100.0)
	floor_collision.shape = floor_shape
	floor_body.add_child(floor_collision)
	world.add_child(floor_body)
	floor_body.position.y = -0.5
	var player := CharacterBody3D.new()
	world.add_child(player)
	player.position = Vector3(0.0, 0.0, 7.0)
	_ally = SCENE.instantiate()
	_ally.set_script(BODY)
	world.add_child(_ally)
	_manager = MANAGER.new()
	world.add_child(_manager)
	_manager.hit_landed.connect(_on_hit)
	_manager.state_changed.connect(_on_state_changed)
	_manager.attack_missed.connect(func(on_enemy: bool) -> void:
		if on_enemy: _tally.misses += 1)
	_manager.staggered.connect(func(_on_enemy: bool) -> void: _tally.stagger_events += 1)
	var all_won := true
	_frames = 0
	for foe_index in foes.size():
		var active := -1
		for i in party.size():
			if not party[i].fainted:
				active = i
				break
		if active < 0:
			all_won = false
			break
		var foe: RefCounted = foes[foe_index]
		_wild = SCENE.instantiate()
		_wild.set_script(WILD)
		world.add_child(_wild)
		_wild.setup(str(foe.species_id))
		_wild.instance = foe
		_wild.strike_ready.connect(func() -> void:
			_incoming_windup = int(_manager.get("_action")) == MANAGER.Action.WINDUP)
		_wild.telegraph_started.connect(func(seconds: float) -> void:
			_tally.events.append({"event": "telegraph", "frame": _frames,
				"enemy_config": _wild.combat_config(), "ally_radius": _ally.body_radius(), "enemy_radius": _wild.body_radius(),
				"seconds": seconds, "ally_position": _ally.global_position,
				"enemy_position": _wild.global_position}))
		_wild.trainer_owned = owned
		_wild.combat_override = foe.combat_override.duplicate(true)
		_wild.position = Vector3(0.0, 0.0, -4.0)
		_ally.setup(str(party[active].species_id))
		_ally.position = Vector3.ZERO
		_ally.velocity = Vector3.ZERO
		_ally.set("_impulse", Vector3.ZERO)
		# Real manager startup always uses party[0]. Preserve authored party order
		# and select the first surviving slot through its normal activation path.
		# A preceding round's fainted lead is temporarily not passed as slot 0;
		# the same survivors, in order, constitute the next deployment.
		var standing: Array[RefCounted] = []
		for member in party:
			if not member.fainted: standing.append(member)
		await tree.physics_frame
		(_manager.get("_rng") as RandomNumberGenerator).seed = seed_value + foe_index
		(_wild.get("_rng") as RandomNumberGenerator).seed = seed_value + foe_index
		if not _manager.begin(player, _wild, _ally, standing, null, null, owned):
			_tally["fixture_error"] = "manager refused encounter"
			all_won = false
			break
		var round_frames := 0
		while _manager.state == MANAGER.State.ACTIVE and round_frames < 14400:
			_release_attack()
			_release_move()
			_act(policy)
			_enemy_windup_before_tick = _wild.is_winding_up()
			if _manager.wind_exhausted(): _tally.exhausted_frames += 1
			await tree.physics_frame
			round_frames += 1
			_frames += 1
		_release_attack()
		_release_move()
		if _manager.state == MANAGER.State.ACTIVE:
			_tally.stalled = true
			all_won = false
			_manager.call("_begin_resolve", "fled")
		elif str(_manager.get("_outcome")) != "won":
			all_won = false
		while _manager.is_fighting():
			await tree.physics_frame
			_frames += 1
		_wild.queue_free()
		await tree.process_frame
		if not all_won: break
	_tally.won = all_won
	_tally.seconds = float(_frames) / Engine.physics_ticks_per_second
	_tally.physics_frames = _frames
	_tally.lead_lost_frac = 1.0 - lead.hp_fraction()
	var party_hp := 0.0
	for member in party:
		# Victory XP may raise max HP. Measure lost fractions against the
		# entry budget rather than letting growth manufacture negative damage.
		party_hp += member.hp_fraction() * float(_entry_maxima[member.get_instance_id()])
		if member.fainted: _tally.faints += 1
	_tally.party_lost_frac = 1.0 - party_hp / maxf(1.0, party_max)
	world.queue_free()
	await tree.process_frame
	return _tally.duplicate(true)


## Production-world adapter. The continuous harnesses already own engagement,
## victory/flag checks, faints and time limits; they call this once per physics
## frame (then await it) so the same READER policy decides the actual combat
## input against the live manager and bodies. Only controller-equivalent
## actions are pressed: movement through the camera the manager reads, and the
## ordinary attack buttons for exactly one frame.
func drive(manager: Node, ally: Node3D, enemy: Node3D, policy: String = "READER") -> void:
	release()
	_manager = manager
	_ally = ally
	_wild = enemy
	if _manager == null or not is_instance_valid(_ally) or not is_instance_valid(_wild):
		return
	_act(policy)


func release() -> void:
	_release_attack()
	_release_move()


func _on_hit(on_enemy: bool, damage: float) -> void:
	if on_enemy:
		_tally.hits += 1
		if _enemy_windup_before_tick and _wild.is_staggered() \
				and not bool((_manager.get("_pending_move") as Dictionary).get("is_quick", true)):
			_tally.charged_interrupts += 1
	else:
		_tally.incoming_hits += 1
		var creature: RefCounted = _manager.active_creature()
		if _incoming_windup and not creature.fainted: _tally.player_windup_cancellations += 1
		_tally.max_hit_frac = maxf(float(_tally.max_hit_frac), damage / maxf(1.0,
			float(_entry_maxima[creature.get_instance_id()])))
	_tally.events.append({"frame": _frames, "on_enemy": on_enemy, "damage": damage,
		"event": "hit", "ally_position": _ally.global_position, "enemy_position": _wild.global_position,
		"gap": _ally.global_position.distance_to(_wild.global_position),
		"wind": _manager.wind_value(), "enemy_staggered": _wild.is_staggered(),
		"player_action": int(_manager.get("_action"))})


func _on_state_changed() -> void:
	var action := int(_manager.get("_action"))
	if action == MANAGER.Action.WINDUP and _last_action != MANAGER.Action.WINDUP:
		var quick := bool((_manager.get("_pending_move") as Dictionary).get("is_quick", true))
		_tally["quick_uses" if quick else "charged_uses"] += 1
	_last_action = action


func _act(policy: String) -> void:
	if _manager.player_is_committed() or float(_manager.get("_hitstop_left")) > 0.0:
		return
	var delta := _wild.global_position - _ally.global_position
	delta.y = 0.0
	var distance := delta.length()
	var toward := delta.normalized()
	var reach: float = _manager.combat_move_reach("quick")
	var charged_reach: float = _manager.combat_move_reach("charged")
	var allow_charged := true
	if policy == "READER":
		var cost: float = _manager.wind_cost("quick")
		var reserve: float = _manager.wind_max() * 0.25
		if _manager.enemy_is_winding_up():
			var creature: RefCounted = _manager.active_creature()
			var charged: Dictionary = _manager.call("_move_profile", "player_charged", str(creature.move_charged))
			if _manager.charged_ready() and distance < charged_reach - 0.2 \
					and float(_wild.get("_beat_left")) > float(charged.get("windup", 0.55)) + 0.1 \
					and _manager.wind_value() >= _manager.wind_cost("charged") + reserve:
				_press("combat_charged")
				return
			# Stop once outside the observed strike's reach. Running away for
			# the whole tell wastes the recovery returning to attack distance.
			var enemy_reach := float(_wild.combat_config().get("range", 2.6))
			if distance < enemy_reach + 0.35:
				_retreat(toward)
			return
		if _manager.wind_value() < cost + reserve:
			_retreat(toward)
			return
		# Read actual recovery/stagger, not an oracle about future RNG.
		if not _manager.enemy_is_staggered() and int(_wild.intent()) != AI.Intent.RECOVER:
			if distance > reach - 0.4: _walk(toward)
			return
		var quick: Dictionary = _manager.call("_move_profile", "player_quick", str(_manager.active_creature().move_quick))
		var charged: Dictionary = _manager.call("_move_profile", "player_charged", str(_manager.active_creature().move_charged))
		var window := float(_wild.get("_beat_left"))
		allow_charged = window > float(charged.get("windup", 0.55)) + 0.1
		if window < float(quick.get("windup", 0.18)) + 0.05:
			if distance > reach - 0.25: _walk(toward)
			return
	if distance > reach - 0.25:
		_walk(toward)
		return
	if allow_charged and _manager.charged_ready() and distance < charged_reach - 0.15 \
			and (policy == "MASHER" or _manager.wind_value() >= _manager.wind_cost("charged") + _manager.wind_max() * 0.25):
		_press("combat_charged")
	elif _manager.quick_ready():
		_press("combat_quick")


func _walk(direction: Vector3) -> void:
	# The manager turns stick input into a world direction through the
	# exploration camera it was given. The flat fixture passes none (identity).
	var rig: Node = _manager.get("_camera_rig")
	if rig != null and is_instance_valid(rig) and rig.has_method("planar_basis"):
		direction = (rig.call("planar_basis") as Basis).inverse() * direction
		direction.y = 0.0
	if direction.x < 0.0: Input.action_press("move_left", -direction.x)
	if direction.x > 0.0: Input.action_press("move_right", direction.x)
	if direction.z < 0.0: Input.action_press("move_forward", -direction.z)
	if direction.z > 0.0: Input.action_press("move_back", direction.z)


func _retreat(toward: Vector3) -> void:
	var arena: Node3D = _manager.arena()
	# A shared world opponent (an Alpha) is not confined to a local arena.
	if arena == null or not is_instance_valid(arena):
		_walk(-toward)
		return
	var outward := _ally.global_position - arena.global_position
	outward.y = 0.0
	# At the boundary, walking straight back is no longer a dodge. Circle
	# along the actual arena instead of knowingly holding against its wall.
	if outward.length() > float(arena.get("radius")) - 2.5:
		var tangent := outward.normalized().cross(Vector3.UP)
		if tangent.dot(-toward) < 0.0: tangent = -tangent
		_walk(tangent)
	else:
		_walk(-toward)


func _press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	_pressed = action


func _release_attack() -> void:
	if _pressed.is_empty(): return
	var event := InputEventAction.new()
	event.action = _pressed
	event.pressed = false
	Input.parse_input_event(event)
	_pressed = ""


func _release_move() -> void:
	for action in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(action)
