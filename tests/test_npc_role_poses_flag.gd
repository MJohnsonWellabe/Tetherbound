extends "res://tests/test_case.gd"
## F38#35: npc_postures.json `role_poses_1114` maps Halda, Oskar and Lark
## onto authored readable silhouettes; OFF until judged.

const NPC := preload("res://scripts/npc/npc_body.gd")
const POSTURE := preload("res://scripts/npc/npc_posture.gd")

const CASES := {"Halda": "villager_ranger", "Oskar": "villager_keeper", "Lark": "courier"}


func _role_of(who: String, art: String) -> String:
	var body: Node3D = NPC.new()
	body.name = who
	var holder := Node3D.new()
	holder.add_child(body)
	body.call("setup", art, null)
	var clip := str(body.get("_clips")["idle"])
	var player: AnimationPlayer = body.call("animation_player")
	var name := ""
	if player != null and player.has_animation(clip):
		name = str(player.get_animation(clip).resource_name)
	holder.free()
	return name


func test_flag_ships_off() -> void:
	POSTURE._config = {}
	var cfg := POSTURE.config()
	assert_false(cfg["role_poses_1114"]["enabled"], "role_poses_1114 stays OFF until judged")
	for who: String in CASES:
		assert_eq(_role_of(who, CASES[who]), "npc_posture_" + str(cfg["by_name"][who]), "%s keeps the shipped role" % who)


func test_on_each_villager_takes_its_authored_pose_on_its_real_rig() -> void:
	POSTURE._config = {}
	var cfg: Dictionary = POSTURE.config().duplicate(true)
	cfg["role_poses_1114"]["enabled"] = true
	POSTURE._config = cfg
	var map: Dictionary = cfg["role_poses_1114"]["by_name"]
	for who: String in CASES:
		var role := str(map[who])
		assert_true(cfg["profiles"].has(role), role)
		# A bone missing from the rig's idle falls back to the neutral idle
		# with a warning; the posed clip's name proves every bone matched.
		assert_eq(_role_of(who, CASES[who]), "npc_posture_" + role, "%s takes %s" % [who, role])
	POSTURE._config = {}
