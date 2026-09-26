extends SceneTree

## F10 Raise a Road: travel along a player-built road lands on the far footing
## in BOTH directions. The two optional road footings the player can choose,
## Verge Road and Hollows Road, each get a Stormglass Arch through the
## production ledger (free build: footing, twin and recipe rules still apply),
## and the host's own `travel_for_peer` carries the local trainer each way.
##
## Regression: arrival used the terrain height 3.5 m in front of the arch. The
## Verge Road footing's level 9 m slab stands above its sloping terrain there,
## so the arrival capsule sat inside the slab and every trip TO Verge Road was
## refused with "Clear the far footing before travelling" (F10 two-peer proof,
## run 1). Negative control: the refusal is reproduced by the same clearance
## query at the old terrain height.
##
## Disclosed fixture: the recipe fact comes from the host ledger, the arches are
## placed through the ledger, and the trainer is stood beside each arch
## (debug travel, outside its passage) before `travel_for_peer` is asked.

const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const STORMWOOD_SCENE := preload("res://scenes/world/stormwood.tscn")
const TEST_SAVE_DIR := "user://stormwood_road_arrival_smoke"

var _failures: Array[String] = []
var _passes := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(600.0).timeout.connect(func() -> void:
		_expect(false, "600 second watchdog expired")
		_finish())
	var game := root.get_node_or_null(^"Game")
	await process_frame
	game.call("reset_for_new_game")
	game.set("save_system", SAVE_GAME.new(TEST_SAVE_DIR))
	game.set("current_realm", "stormwood")
	game.call("bind_realm_map")
	var world := STORMWOOD_SCENE.instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	while not bool(world.call("shell_build_complete")):
		await process_frame
	var ledger: Node = game.get("ledger")
	_expect(bool(ledger.call("submit", {"kind": "set_world_flag", "realm": "stormwood",
		"id": "stormwood:arch_recipe_known", "value": true}).get("ok", false)), "arch recipe fact committed")
	var uids: Dictionary = {}
	for footing: Array in [["verge_road", Vector2(-630, 800)], ["hollows_road", Vector2(-1050, 1750)]]:
		var at: Vector2 = footing[1]
		var placed: Dictionary = ledger.call("submit", {"kind": "place_building", "realm": "stormwood",
			"id": "stormglass_arch", "position": [at.x, float(world.call("ground_height_at", at.x, at.y)), at.y + 2.0],
			"yaw_deg": 0.0, "paid": false})
		_expect(bool(placed.get("ok", false)), "a Stormglass Arch placed on the %s footing" % footing[0])
	for _i in 60:
		await physics_frame
	for row: Dictionary in game.get("placed_buildings"):
		if str(row.get("id", "")) == "stormglass_arch":
			uids[str(row.get("arch_footing", ""))] = str(row.get("uid", ""))
	_expect(uids.has("verge_road") and uids.has("hollows_road"), "both arches bound to their footings: %s" % str(uids))
	var runtime := world.get_node("StormglassArches")
	var session: Node = game.get_node("Session")
	var peer := int(session.call("local_peer_id"))
	var player := world.get_node("Player") as CharacterBody3D
	for leg: Array in [["hollows_road", "verge_road"], ["verge_road", "hollows_road"]]:
		var source: Node3D = (runtime.get("_arches")[uids.get(leg[0], "")] as Dictionary).node
		var target: Node3D = (runtime.get("_arches")[uids.get(leg[1], "")] as Dictionary).node
		# Beside the arch, outside its passage (which would travel on entry).
		player.global_position = source.global_position + Vector3(2.5, 1.0, -2.0)
		player.velocity = Vector3.ZERO
		runtime.set("_arrival_until", {})
		for _i in 5:
			await physics_frame
		var verdict: Dictionary = runtime.call("travel_for_peer", peer, uids.get(leg[0], ""))
		print("ROAD TRAVEL %s -> %s: %s" % [leg[0], leg[1], str(verdict)])
		_expect(bool(verdict.get("ok", false)), "travel %s -> %s is accepted (%s)" % [leg[0], leg[1], str(verdict.get("reason", ""))])
		if bool(verdict.get("ok", false)):
			_expect((verdict.at as Vector3).distance_to(target.to_global(Vector3(0, 0, 3.5))) < 2.0,
				"the trainer lands 3.5 m in front of the %s twin at %s" % [leg[1], str(verdict.at)])
		for _i in 30:
			await physics_frame
	# Negative control: the pre-fix arrival height, terrain + 0.6 m, in front
	# of the Verge Road arch is inside its footing slab.
	var verge: Node3D = (runtime.get("_arches")[uids.get("verge_road", "")] as Dictionary).node
	var old_at := verge.to_global(Vector3(0, 0, 3.5))
	old_at.y = float(world.call("ground_height_near", old_at)) + 0.6
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.8
	capsule.radius = 0.35
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	query.exclude = [player.get_rid()]
	query.transform = Transform3D(Basis.IDENTITY, old_at + Vector3(0, 0.9, 0))
	var hits: Array = runtime.get_world_3d().direct_space_state.intersect_shape(query, 4)
	var names: Array = hits.map(func(hit: Dictionary) -> String: return str((hit.collider as Node).name) if hit.collider is Node else "?")
	_expect(names.has("Footing_verge_road"),
		"negative control: at the old terrain height the arrival capsule overlaps the Verge Road footing slab (%s)" % str(names))
	_finish()


func _expect(condition: bool, message: String) -> void:
	if condition:
		_passes += 1
		print("  PASS: ", message)
	else:
		_failures.append(message)
		print("  FAIL: ", message)


var _done := false


func _finish() -> void:
	if _done:
		return
	_done = true
	var absolute := ProjectSettings.globalize_path(TEST_SAVE_DIR)
	if DirAccess.dir_exists_absolute(absolute):
		for file: String in DirAccess.get_files_at(absolute):
			DirAccess.remove_absolute(absolute.path_join(file))
		DirAccess.remove_absolute(absolute)
	print("STORMWOOD ROAD ARRIVAL %s: %d passed, %d failed" % [
		"OK" if _failures.is_empty() else "FAILED", _passes, _failures.size()])
	quit(0 if _failures.is_empty() else 1)
