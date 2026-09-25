extends SceneTree

## F07 / C2: WORLD §11 activity payoffs on the production Cloudreach scene.
##
##   godot --headless --path . --script tests/smoke_cloudreach_activity_rewards.gd
##
## packs_on_the_wrong_side: "one eligible personal small-potion x2 reward,
## once". Disclosed fixture: the chain's first two step flags are seeded, the
## report step goes through the chapter's real dialogue-effect guard, and the
## trainer is placed beside Galefoot's fire. Collection is the ordinary
## interact press through the arbiter.
const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SAVE := preload("res://scripts/save/save_game.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const CACHE := preload("res://scripts/world/item_cache_pickup.gd")
const REWARD_ID := "cr_reward_couriers_potions"
const REPORT_EFFECT := "cloudreach:side:packs_on_the_wrong_side:report_to_neri"
const SLOT := 0

var _failures: Array[String] = []
var _checks := 0
var _game: Node
var _world: Node3D


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_game = root.get_node(^"Game")
	_game.call("reset_for_new_game")
	_game.set("save_system", SAVE.new("user://cloudreach_activity_rewards_smoke/"))
	_game.set("current_realm", "cloudreach")
	(_game.get("party") as RefCounted).call("add", SPECIES.spawn("terrapup"))
	var flags: RefCounted = _game.get("progression")
	for flag: String in ["realm_key_cloudreach", "cloudreach_chapter_started", "cloudreach_crisis_learned",
			"causeway_survivors_reconnected", "side_courier_pack_recovered", "side_courier_medicine_delivered"]:
		flags.call("set_flag", flag)
	await _load_world()
	var physical := _physical()
	_check(physical.get_node_or_null(NodePath(REWARD_ID)) == null, "the couriers' thanks is not placed before Neri hears the report")

	_check(bool(physical.call("consume_dialogue_effect", REPORT_EFFECT)), "Neri's report line completes the chain through the dialogue guard")
	_check(bool(flags.call("has", "side_stranded_couriers_complete")), "the chain's completion flag is set")
	await _frames(10)
	var reward := physical.get_node_or_null(NodePath(REWARD_ID)) as Node3D
	_check(reward != null, "the couriers' thanks appears once the chain completes")
	if reward == null:
		_report()
		return
	var neri := Vector3(-296.0, 180.0, 534.0)
	_check(Vector2(reward.global_position.x - neri.x, reward.global_position.z - neri.z).length() < 6.0,
		"it sits by Neri at Galefoot (%s)" % reward.global_position)

	var inventory: RefCounted = _game.get("inventory")
	var before := int(inventory.call("count", "potion_small"))
	var player := _world.get_node(^"Player") as CharacterBody3D
	player.global_position = reward.global_position + Vector3(1.0, 0.3, 0.0)
	player.velocity = Vector3.ZERO
	await _frames(20)
	var arbiter := _world.get_node(^"InteractionArbiter")
	arbiter.call("_recompute")
	print("prompt beside the thanks: '%s'" % str(arbiter.call("prompt")))
	Input.action_press("interact")
	await _frames(2)
	Input.action_release("interact")
	await _frames(20)
	_check(int(inventory.call("count", "potion_small")) == before + 2, "the interact press gives two small potions (%d -> %d)" % [before, int(inventory.call("count", "potion_small"))])
	_check(CACHE.was_taken(_game, "potion_small", REWARD_ID, "cloudreach"), "the per-character receipt records it taken")
	await _frames(10)
	_check(physical.get_node_or_null(NodePath(REWARD_ID)) == null or not (physical.get_node(NodePath(REWARD_ID)) as Node3D).visible,
		"the thanks is gone after collection")

	_check(bool(_game.call("save_game", SLOT)), "save after collection")
	_world.queue_free()
	await _frames(4)
	_check(bool(_game.call("load_game", SLOT)), "load the saved game")
	await _load_world()
	_check(bool((_game.get("progression") as RefCounted).call("has", "side_stranded_couriers_complete")), "chain completion survives reload")
	_check(_physical().get_node_or_null(NodePath(REWARD_ID)) == null, "the collected thanks does not return after reload")
	_check(int((_game.get("inventory") as RefCounted).call("count", "potion_small")) == before + 2, "the potions survive reload exactly once")
	_report()


func _load_world() -> void:
	_world = SCENE.instantiate()
	root.add_child(_world)
	current_scene = _world
	await _frames(30)


func _physical() -> Node:
	return _world.get_node(^"CloudreachChapter").get("_physical")


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _check(ok: bool, message: String) -> void:
	_checks += 1
	if ok:
		print("PASS %s" % message)
	else:
		_failures.append(message)
		print("FAIL %s" % message)


func _report() -> void:
	print("CLOUDREACH ACTIVITY REWARDS %s checks=%d failures=%d" % ["OK" if _failures.is_empty() else "FAIL", _checks, _failures.size()])
	quit(0 if _failures.is_empty() else 1)
