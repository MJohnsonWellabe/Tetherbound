extends "res://scripts/combat/combat_manager.gd"

## A host-owned opponent simulation. It shares production damage and enemy AI,
## but owns no player's party, input, camera, or deployed-body movement.
signal telegraph(seconds: float)
signal swung()

func _physics_process(_delta: float) -> void:
	pass

func start_opponent(body: Node3D, target: Node3D, centre: Vector3,
		radius: float, link: Node, encounter_id: String) -> void:
	stop_opponent()
	_wild = body
	_enemy = body.get("instance")
	_ally_body = target
	_arena = ARENA.new()
	get_parent().add_child(_arena)
	_arena.visible = false
	var cfg: Dictionary = MATH.config().get("arena", {}).duplicate(true)
	cfg["radius"] = radius
	_arena.call("configure", centre, cfg)
	_wild.set("arena", _arena)
	bind_encounter(link, encounter_id, "trainer")
	_wild.connect("strike_ready", _on_enemy_strike)
	_wild.connect("telegraph_started", _on_enemy_telegraph)
	_wild.call("set_engaged", true, target)
	state = State.ACTIVE

func set_target_body(target: Node3D) -> void:
	if target == _ally_body or not is_instance_valid(_wild):
		return
	_ally_body = target
	# Retargeting must preserve a wind-up already underway. Restarting engagement
	# here lets two players alternate nearest position to suppress every attack.
	_wild.set("_opponent", target)

func _on_enemy_telegraph(seconds: float) -> void:
	telegraph.emit(seconds)

func _on_enemy_strike() -> void:
	if state != State.ACTIVE or not is_instance_valid(_wild) or _enemy == null:
		return
	var cfg: Dictionary = _wild.call("combat_config")
	var origin: Vector3 = _wild.call("centre")
	var facing: Vector3 = _wild.call("facing")
	_wild.call("add_impulse", facing, float(cfg.get("lunge", 3.4)))
	# The link reports local peer zero: every actual participant, including the
	# listen-server player, receives the same host damage delivery path.
	_host_resolve_enemy_strike_for_a_participant(cfg, origin, facing)
	swung.emit()

func stop_opponent() -> void:
	state = State.INACTIVE
	if is_instance_valid(_wild):
		if _wild.is_inside_tree():
			_wild.call("set_engaged", false)
		else:
			# Realm-shell teardown can detach the opponent before this engine's
			# `_exit_tree`. `wild_creature.set_engaged(false)` computes a new
			# local wander target from global_position, which is invalid once the
			# body has left SceneTree. The detached body cannot resume simulation;
			# clear only the two live-fight references without reading a transform.
			_wild.set("engaged", false)
			_wild.set("_opponent", null)
		_wild.set("arena", null)
		if _wild.is_connected("strike_ready", _on_enemy_strike):
			_wild.disconnect("strike_ready", _on_enemy_strike)
		if _wild.is_connected("telegraph_started", _on_enemy_telegraph):
			_wild.disconnect("telegraph_started", _on_enemy_telegraph)
	if is_instance_valid(_arena):
		_arena.queue_free()
	_arena = null
	_wild = null
	_enemy = null
	_ally_body = null
	unbind_encounter()

func _exit_tree() -> void:
	stop_opponent()
