extends SceneTree

## F07 / C2: WORLD §11 activity payoffs on the production Cloudreach scene.
##
##   godot --headless --path . --script tests/smoke_cloudreach_activity_rewards.gd
##
## packs_on_the_wrong_side: "one eligible personal small-potion x2 reward,
## once" -- per CHARACTER through the ledger's `reward_grant` delivery, never a
## first-come world cache. Disclosed fixture: the chain's first two step flags are seeded, the
## report step goes through the chapter's real dialogue-effect guard, and the
## trainer is placed beside Galefoot's fire. Collection is the ordinary
## interact press through the arbiter.
const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SAVE := preload("res://scripts/save/save_game.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const CLAIMED_FLAG := "cloudreach_payout:couriers_thanks"
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
			"causeway_survivors_reconnected", "side_courier_pack_recovered"]:
		flags.call("set_flag", flag)
	await _load_world()
	# A character arriving in Cloudreach has saved before; the save is what
	# gives this fresh test character its stable identity, which a personal
	# reward is delivered to.
	_check(bool(_game.call("save_game", SLOT)), "the arriving character has a saved identity")
	var physical := _physical()
	_check(not _offered(physical), "the couriers' thanks is not offered before the medicine reaches the shelter")
	# Coordinator ruling (a), #356 13:20: the thanks waits at the Windscar
	# ravine shelter once the medicine is delivered (fixture flag write for the
	# delivery step, disclosed).
	flags.call("set_flag", "side_courier_medicine_delivered")
	await _frames(10)
	var reward := physical.get_node_or_null(NodePath(REWARD_ID)) as Node3D
	_check(reward != null and _offered(physical), "the couriers' thanks is offered at the shelter once the medicine is delivered")
	if reward == null:
		_report()
		return
	var delivery := Vector3(-298.0, 460.0, 3103.0)
	var d := Vector2(reward.global_position.x - delivery.x, reward.global_position.z - delivery.z).length()
	var nearest := INF
	for npc: Vector3 in [Vector3(-297, 460, 3098), Vector3(-303, 460, 3100)]:
		nearest = minf(nearest, Vector2(reward.global_position.x - npc.x, reward.global_position.z - npc.z).length())
	_check(nearest >= 8.0 and d < 12.0, "it sits at the Windscar ravine shelter, clear of both couriers' talk prompts (nearest person %.1f m, delivery %.1f m, %s)" % [nearest, d, reward.global_position])
	var eye := delivery + Vector3.UP * 1.6
	var target := reward.global_position + Vector3.UP * 0.5
	var blocker := _world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(eye, target))
	_check(blocker.is_empty(), "the thanks is in plain sight from the delivery prompt (blocked by %s)" % [str((blocker["collider"] as Node).get_path()) if not blocker.is_empty() else "nothing"])
	_check(bool(physical.call("consume_dialogue_effect", REPORT_EFFECT)), "Neri's report line completes the chain through the dialogue guard")
	_check(bool(flags.call("has", "side_stranded_couriers_complete")), "the chain's completion flag is set")
	var inventory: RefCounted = _game.get("inventory")
	var before := int(inventory.call("count", "potion_small"))
	var player := _world.get_node(^"Player") as CharacterBody3D
	player.global_position = reward.global_position + Vector3(1.0, 0.3, 0.0)
	player.velocity = Vector3.ZERO
	await _frames(20)
	var arbiter := _world.get_node(^"InteractionArbiter")
	arbiter.call("_recompute")
	_check(str(arbiter.call("prompt")).contains("Take the couriers' thanks"),
		"the prompt beside it is the couriers' thanks, not a talk prompt ('%s')" % str(arbiter.call("prompt")))
	Input.action_press("interact")
	await _frames(2)
	Input.action_release("interact")
	await _frames(20)
	_check(int(inventory.call("count", "potion_small")) == before + 2, "the interact press gives two small potions (%d -> %d)" % [before, int(inventory.call("count", "potion_small"))])
	_check(_character_claimed(), "this character's own player-scoped receipt records the claim")
	_check(not bool((_game.get("progression") as RefCounted).call("has", "cache:cloudreach:" + REWARD_ID)),
		"no first-come world cache flag was written; another character's thanks is untouched")
	await _frames(10)
	_check(not _offered(physical), "the thanks is no longer offered to this character")
	Input.action_press("interact")
	await _frames(2)
	Input.action_release("interact")
	await _frames(20)
	_check(int(inventory.call("count", "potion_small")) == before + 2, "pressing again pays nothing more")

	_check(bool(_game.call("save_game", SLOT)), "save after collection")
	_world.queue_free()
	await _frames(4)
	_check(bool(_game.call("load_game", SLOT)), "load the saved game")
	await _load_world()
	_check(bool((_game.get("progression") as RefCounted).call("has", "side_stranded_couriers_complete")), "chain completion survives reload")
	_check(_character_claimed(), "the character's receipt survives reload")
	_check(not _offered(_physical()), "the collected thanks is not offered again after reload")
	_check(int((_game.get("inventory") as RefCounted).call("count", "potion_small")) == before + 2, "the potions survive reload exactly once")
	_report()


func _load_world() -> void:
	_world = SCENE.instantiate()
	root.add_child(_world)
	current_scene = _world
	await _frames(30)


func _offered(physical: Node) -> bool:
	var reward := physical.get_node_or_null(NodePath(REWARD_ID))
	return reward != null and bool(reward.call("offered")) and (reward as Node3D).visible


func _character_claimed() -> bool:
	var local: RefCounted = _game.get("local")
	return local != null and bool((local.get("flags") as RefCounted).call("has", CLAIMED_FLAG))


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
