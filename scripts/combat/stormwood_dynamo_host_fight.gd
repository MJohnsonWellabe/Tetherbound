extends "res://scripts/combat/cloudreach_combat_manager.gd"

## The Dynamo host drives the installed enemy AI and shared damage resolver.
## A separate local CombatManager owns each participant's input and camera.
## This simulation must never read the host's keyboard while the host is in
## another realm, reposition a remote creature, or claim its private party.

func _physics_process(_delta: float) -> void:
	# WildCreature owns enemy movement/telegraphs and emits strike_ready to the
	# inherited handler. Participant attacks arrive through host_roll_damage.
	pass

func _place_fighters() -> void:
	pass

func _take_camera() -> void:
	pass

func _refuse_combat_input() -> void:
	pass

func stop_round() -> void:
	state = State.INACTIVE
	if is_instance_valid(_wild):
		_wild.call("set_engaged", false)
		if _wild.is_connected("strike_ready", _on_enemy_strike):
			_wild.disconnect("strike_ready", _on_enemy_strike)
		if _wild.is_connected("telegraph_started", _on_enemy_telegraph):
			_wild.disconnect("telegraph_started", _on_enemy_telegraph)
	if is_instance_valid(_arena):
		_arena.queue_free()
	_arena = null
	_encounter_link = null
	_encounter_id = ""
