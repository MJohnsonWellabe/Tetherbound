extends SceneTree

## F07#3 diagnosis: do the aftermath summit pairs (`summit_overlook_loop_02/03`,
## table gated by `cloudreach_winds_restored`) spawn and offer Engage once the
## winds are restored? Boots the production scene with the post-finale flags,
## stands the trainer beside each site with a companion sent out, and prints
## what the director has there.
##
##   godot --headless --path . --script tests/probe_cloudreach_aftermath_pairs.gd

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const SITES := {"road_visibility_summit_overlook_loop_02": Vector3(-55.0, 1140.0, 5337.5),
	"road_visibility_summit_overlook_loop_03": Vector3(-365.0, 1100.0, 5312.5)}
const FLAGS: Array[String] = ["cloudreach_chapter_started", "fly_traversal_unlocked", "sky_shrine_reached",
	"cloudreach_upper_route_unlocked", "cloudreach_act_ii_complete", "captain_veyra_defeated",
	"storm_anchor_network_disabled", "cloudreach_winds_restored"]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node("Game")
	game.call("reset_for_new_game")
	for flag: String in FLAGS:
		game.progression.set_flag(flag)
	for species: String in ["sparkit", "mudsnout", "bramblebun", "terrapup", "brooktail"]:
		var member: RefCounted = SPECIES.spawn(species)
		member.set_level(32, PROGRESSION.config())
		game.party.add(member)
	game.set("current_realm", "cloudreach")
	var world := SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in 30:
		await physics_frame
	var player: CharacterBody3D = world.get_node("Player")
	var director: Node = world.get_node("CloudreachRuntime").director
	var out := {}
	for id: String in SITES:
		var at: Vector3 = SITES[id]
		var ground := float(world.call("ground_height_near", at))
		player.global_position = Vector3(at.x + 6.0, (ground if is_finite(ground) else at.y) + 1.2, at.z)
		player.velocity = Vector3.ZERO
		for _frame in 90:
			await physics_frame
		if director.call("ally_body") == null:
			Input.action_press("creature_recall")
			await physics_frame
			Input.action_release("creature_recall")
			for _frame in 30:
				await physics_frame
		var bodies: Array = []
		for wild: Variant in director.get("_wild_creatures"):
			if is_instance_valid(wild) and str((wild as Node).name).begins_with(id):
				bodies.append({"name": str((wild as Node).name), "at": str((wild as Node3D).global_position),
					"visible": (wild as Node3D).visible})
		var engageable: Variant = director.call("_engageable")
		out[id] = {"gate_holds": bool(director.call("_flags_hold", ["cloudreach_winds_restored"])),
			"spawned": (director.get("_site_spawned") as Dictionary).get(id, false),
			"failures": (director.get("_site_failures") as Dictionary).get(id, null),
			"bodies": bodies, "ally": director.call("ally_body") != null,
			"engageable": str((engageable as Node).name) if engageable != null else "",
			"offer": director.call("interaction_offer", player.global_position)}
	print("CLOUDREACH AFTERMATH PAIRS " + JSON.stringify(out))
	quit(0)
