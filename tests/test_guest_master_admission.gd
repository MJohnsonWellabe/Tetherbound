extends "res://tests/test_case.gd"

## Detached admission and retained-source controls. These do not prove a real
## enemy channel, transport, disk write, owner ACK or an earned Master victory.
const SITE := preload("res://scripts/masters/master_site.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SERVICE := preload("res://scripts/masters/breakthrough_service.gd")
const DIRECTOR := preload("res://scripts/combat/encounter_director.gd")
const REMOTE := preload("res://scripts/creatures/remote_creature.gd")

class OfferDirector extends "res://scripts/combat/encounter_director.gd":
	var presented: Array[RefCounted] = []
	var can_present: bool = true
	func _is_host() -> bool: return false
	func _local_peer_id() -> int: return 7
	func _local_character_id() -> String: return "guest_character"
	func _begin_shared_guest_from_record(_record: Dictionary) -> bool:
		presented = _fight_party()
		return can_present

class MasterWorldDouble extends RefCounted:
	var world_id: String = "host_world"
	var reward_delivery_namespace: String = "host_namespace"

class MasterGameDouble extends Node:
	var world: RefCounted = MasterWorldDouble.new()

class MasterSessionDouble extends Node:
	var game: Node = MasterGameDouble.new()
	var saves: int = 0
	var allow_save: bool = false
	func _game() -> Node: return game
	func _altar_current_epoch() -> String: return "current_epoch"
	func foundation_guest_master_outcome(director: Node, source: Dictionary) -> Dictionary:
		if source != director.call("retained_guest_master_win", source.get("encounter_id", "")): return {}
		saves += 1
		return {"ok": allow_save, "durable": allow_save}

class TerminalRuntimeDouble extends Node:
	var terminal_outcome: String = "won"
	var opponent: Node3D
	func body() -> Node3D: return opponent

class OpponentBodyDouble extends Node3D:
	var instance: RefCounted = OpponentCardDouble.new()

class OpponentCardDouble extends RefCounted:
	var hp: float = 0.0

func _record() -> Dictionary:
	return {"encounter_id": "1:original", "kind": "trainer", "phase": "active",
		"opponent": {"owner_npc": "master_t1"},
		"participants": {7: {"character_id": "guest_character", "creature_uid": "selected_uid"}}}

func test_actual_remote_body_uses_admitted_deployment_identity_without_an_owned_instance() -> void:
	# The real remote script intentionally has no CreatureInstance carrier.
	var body: Node3D = REMOTE.new()
	body.set_multiplayer_authority(7)
	body.set("owner_peer_id", 7)
	body.set("owner_character_id", "guest_character")
	body.set("deploy_species", "terrapup")
	body.set("species_id", "terrapup")
	var owned := {"uid": "selected_uid", "species_id": "terrapup"}
	var deployed := {"creature_uid": "selected_uid", "species_id": "terrapup"}
	assert_true(DIRECTOR.guest_master_actor_matches(body, 7, "guest_character", "selected_uid", owned, deployed))
	assert_false(DIRECTOR.guest_master_actor_matches(body, 8, "guest_character", "selected_uid", owned, deployed))
	assert_false(DIRECTOR.guest_master_actor_matches(body, 7, "foreign_character", "selected_uid", owned, deployed))
	assert_false(DIRECTOR.guest_master_actor_matches(body, 7, "guest_character", "replacement_uid", owned, deployed))
	body.set("deploy_species", "ripplet")
	assert_false(DIRECTOR.guest_master_actor_matches(body, 7, "guest_character", "selected_uid", owned, deployed))
	body.set("deploy_species", "terrapup")
	body.set_multiplayer_authority(8)
	assert_false(DIRECTOR.guest_master_actor_matches(body, 7, "guest_character", "selected_uid", owned, deployed))
	body.free()

func test_guest_offer_refuses_foreign_character_uid_extra_participants_and_wrong_encounter() -> void:
	var world := Node3D.new()
	var site: Node3D = SITE.new()
	site.set("master_id", "master_t1")
	world.add_child(site)
	var director: Node = OfferDirector.new()
	world.add_child(director)
	var session: Node = Node.new()
	director.set("_session", session)
	var selected: RefCounted = SPECIES.spawn("terrapup")
	selected.set("uid", "selected_uid")
	director.set("_ally", selected)
	var intent := {"master_id": "master_t1", "creature_uid": "selected_uid"}
	for invalid: String in ["character", "uid", "spectator", "encounter", "master", "phase"]:
		var rec := _record()
		match invalid:
			"character": rec.participants[7].character_id = "host_character"
			"uid": rec.participants[7].creature_uid = "replacement_uid"
			"spectator": rec.participants[1] = {"character_id": "host_character", "creature_uid": "host_uid"}
			"encounter": rec.encounter_id = "1:replacement"
			"master": rec.opponent.owner_npc = "master_t2"
			"phase": rec.phase = "done"
		assert_false(director.call("accept_guest_master_offer", site, intent, {"encounter_id": "1:original", "record": rec}), invalid)
		assert_true(director.get("_master_duel").is_empty())
	assert_true(director.call("accept_guest_master_offer", site, intent, {"encounter_id": "1:original", "record": _record()}))
	assert_eq(director.get("presented"), [selected], "the guest's actual selected instance is the only fighter")
	assert_false(director.call("accept_guest_master_offer", site, intent, {"encounter_id": "1:original", "record": _record()}), "duplicate offer never starts another fight")
	world.free()
	session.free()

func test_failed_guest_presentation_keeps_no_duel_or_party_lock() -> void:
	var world := Node3D.new()
	var site: Node3D = SITE.new()
	site.set("master_id", "master_t1")
	world.add_child(site)
	var director: Node = OfferDirector.new()
	world.add_child(director)
	var session := Node.new()
	director.set("_session", session)
	var selected: RefCounted = SPECIES.spawn("terrapup")
	selected.set("uid", "selected_uid")
	director.set("_ally", selected)
	director.set("can_present", false)
	assert_false(director.call("accept_guest_master_offer", site, {"master_id": "master_t1", "creature_uid": "selected_uid"}, {"encounter_id": "1:original", "record": _record()}))
	assert_true(director.get("_master_duel").is_empty())
	world.free()
	session.free()

func test_retained_master_site_is_unique_owned_and_survives_other_world_lookup() -> void:
	var service: Node = SERVICE.new()
	var world := Node3D.new()
	var other_world := Node3D.new()
	assert_eq(service.call("retained_site", world, "master_t1").status, "absent")
	var site: Node3D = SITE.new()
	site.set("master_id", "master_t1")
	site.set("_mounted", true)
	site.set_meta("breakthrough_service", service)
	world.add_child(site)
	assert_eq(service.call("retained_site", world, "master_t1").site, site)
	assert_eq(service.call("retained_site", other_world, "master_t1").status, "absent")
	assert_eq(service.call("retained_site", world, "master_t1").site, site, "revisiting a retained world finds the original actual site")
	site.set_meta("breakthrough_service", null)
	assert_eq(service.call("retained_site", world, "master_t1").status, "foreign_or_unready")
	site.set_meta("breakthrough_service", service)
	site.set("_mounted", false)
	assert_eq(service.call("retained_site", world, "master_t1").status, "foreign_or_unready")
	site.set("_mounted", true)
	var duplicate: Node3D = SITE.new()
	duplicate.set("master_id", "master_t1")
	world.add_child(duplicate)
	assert_eq(service.call("retained_site", world, "master_t1").status, "ambiguous", "no duplicate site can be hidden or adopted")
	assert_eq(world.get_child_count(), 2, "the ownership lookup does not mutate either site")
	world.free()
	other_world.free()
	service.free()

func test_world_write_refusal_retains_original_guest_win_and_epoch_fences_retry() -> void:
	var director: Node = OfferDirector.new()
	var session: Node = MasterSessionDouble.new()
	director.set("_session", session)
	var runtime: Node = TerminalRuntimeDouble.new()
	var opponent: Node3D = OpponentBodyDouble.new()
	runtime.set("opponent", opponent)
	var site := Node3D.new()
	var trainer := Node3D.new()
	var actor := Node3D.new()
	var world: RefCounted = session.get("game").get("world")
	var retained := {"peer": 7, "character_id": "guest_character", "creature_uid": "selected_uid", "master_id": "master_t1",
		"encounter_id": "1:original", "world_namespace": "host_namespace", "session_id": "host_world",
		"world": weakref(world), "epoch": "current_epoch", "site": weakref(site), "trainer": weakref(trainer),
		"actor": weakref(actor), "binding": {"body_instance_id": actor.get_instance_id()},
		"participants": _record().participants, "won": true, "durable": false}
	retained.terminal_witness = {"binding": retained.binding.duplicate(true), "action_id": "original_host_action",
		"verdict": {"delta": {"killed": true, "hp": 0.0}}}
	director.get("_guest_master_duels")["1:original"] = retained
	director.get("_shared_host_fights")["1:original"] = runtime
	var original: Dictionary = director.call("retained_guest_master_win", "1:original")
	assert_eq(original.encounter_id, "1:original")
	retained.terminal_witness.verdict.delta.killed = false
	assert_true(director.call("retained_guest_master_win", "1:original").is_empty(), "a won Boolean cannot substitute for accepted killing verdict")
	retained.terminal_witness.verdict.delta.killed = true
	opponent.get("instance").set("hp", 1.0)
	assert_true(director.call("retained_guest_master_win", "1:original").is_empty(), "actual opponent must be defeated")
	opponent.get("instance").set("hp", 0.0)
	director.call("_retry_guest_master_win", "1:original")
	assert_false(retained.durable)
	assert_eq(session.get("saves"), 1)
	assert_eq(director.call("retained_guest_master_win", "1:original"), original)
	director.call("_dispose_shared_host_fight", "1:original", false)
	assert_true(retained.dispose_requested)
	assert_eq(director.get("_shared_host_fights")["1:original"], runtime)
	retained.epoch = "retired_epoch"
	assert_true(director.call("retained_guest_master_win", "1:original").is_empty())
	retained.epoch = "current_epoch"
	retained.erase("dispose_requested")
	session.set("allow_save", true)
	director.call("_retry_guest_master_win", "1:original")
	assert_true(retained.durable)
	assert_eq(session.get("saves"), 2)
	director.call("_retry_guest_master_win", "1:original")
	assert_eq(session.get("saves"), 2, "a saved original witness cannot append another event")
	director.get("_guest_master_duels").clear()
	director.get("_shared_host_fights").clear()
	director.free()
	session.get("game").free()
	session.free()
	runtime.free()
	opponent.free()
	site.free()
	trainer.free()
	actor.free()
