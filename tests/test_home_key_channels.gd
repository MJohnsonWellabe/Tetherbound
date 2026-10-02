extends "res://tests/test_case.gd"

const CHANNELS := preload("res://scripts/net/home_key_channels.gd")
const POLICY := preload("res://scripts/net/portal_action_policy.gd")
const DATA := preload("res://scripts/data/redesign_data.gd")
const WORLD := preload("res://autoload/world_state.gd")

class KeyDouble extends Node:
	var ended: Array[String] = []
	func end_remote_raise(id: String) -> void: ended.append(id)
	func clear_remote_raises() -> void: ended.clear()

class GameDouble extends Node:
	var world := WORLD.new()
	var current_realm := "meadows"

class SessionDouble extends Node:
	var game := GameDouble.new()
	var _portal_policy := POLICY.new()
	var context := {"world_instance_id": "channel-world", "character_id": "guest", "peer_id": 2,
		"realm": "meadows", "position": Vector3.ZERO, "damage_revision": 0, "combat": false,
		"dialogue": false, "cutscene": false, "swimming": false, "flying": false, "downed": false,
		"home_key_owned": true}
	func is_host() -> bool: return true
	func is_active() -> bool: return false
	func portal_runtime_ready() -> bool: return true
	func local_peer_id() -> int: return 1
	func _game() -> Node: return game
	func _altar_current_epoch() -> String: return "channel-epoch"
	func _authority_character(peer: int) -> String: return "guest" if peer == 2 else "host"
	func _host_portal_context(_peer: int) -> Dictionary: return context

func test_observer_packet_requires_current_world_session_character_and_bounded_fields() -> void:
	var event := {"peer_id": 2, "character_id": "guest", "world_instance_id": "world",
		"session_epoch": "epoch", "realm": "meadows", "use_id": "immutable-use", "active": true}
	assert_true(CHANNELS.valid(event, "guest", "world", "epoch"))
	for field: String in ["character_id", "world_instance_id", "session_epoch", "realm"]:
		var forged := event.duplicate(true)
		forged[field] = "forged"
		assert_false(CHANNELS.valid(forged, "guest", "world", "epoch"), field)
	event.position = Vector3.ZERO
	assert_false(CHANNELS.valid(event, "guest", "world", "epoch"))

func test_production_tick_expires_orphaned_guest_channel_and_damage_cancels_without_cooldown() -> void:
	var owner := SessionDouble.new()
	owner.game.world.reward_delivery_namespace = "channel-world"
	var key := KeyDouble.new()
	key.name = "HomeKey"
	owner.game.add_child(key)
	var composition := Node.new()
	owner.add_child(composition)
	var channels := CHANNELS.new()
	composition.add_child(channels)
	owner._portal_policy.bind_world("channel-world")
	var cfg: Dictionary = DATA.json("res://data/config/portals.json")
	var stones: Dictionary = DATA.json("res://data/config/waystones.json")
	var begin := owner._portal_policy.evaluate({"kind": "home_key_begin"}, owner.context, cfg, stones,
		Time.get_ticks_msec() - 20000)
	assert_true(begin.ok)
	channels._process(1.0)
	assert_false(owner._portal_policy.has_open_channels())
	assert_eq(key.ended, [begin.prepared.use_id])
	begin = owner._portal_policy.evaluate({"kind": "home_key_begin"}, owner.context, cfg, stones, Time.get_ticks_msec())
	assert_true(begin.ok, "retry is free immediately after expiry")
	var frozen := owner._portal_policy.open_channels()
	frozen[0].character_id = "forged"
	assert_eq(owner._portal_policy.open_channels()[0].character_id, "guest", "read view is detached")
	owner.context.damage_revision = 1
	channels._process(1.0)
	assert_false(owner._portal_policy.has_open_channels())
	assert_eq(key.ended[-1], begin.prepared.use_id)
	begin = owner._portal_policy.evaluate({"kind": "home_key_begin"}, owner.context, cfg, stones, Time.get_ticks_msec())
	assert_true(begin.ok)
	channels._peer_left(2)
	assert_false(owner._portal_policy.has_open_channels())
	assert_eq(key.ended[-1], begin.prepared.use_id)
	owner.game.free()
	owner.free()
