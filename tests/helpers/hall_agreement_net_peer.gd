extends "res://tools/net/peer_runner.gd"

## F17#5 peer for tests/smoke_net_crossing_hall_agreement.gd: read-only
## village/Hall producers and an ordinary host title Load continuation. No
## fixtures. Producer trees are digested on the peer (SHA-256 of the full
## structural record) so the control channel carries a compact row.
var _hall_pin: Dictionary = {}

func _execute_step(msg: Dictionary) -> Dictionary:
	var action := str(msg.get("action", ""))
	var args: Dictionary = msg.get("args", {})
	if action == "production_host":
		var started: Dictionary = await _step_production_host(args)
		if str(started.get("verdict", "")) != "PASS": return started
		return await _hall_wait_host_ready(started)
	if action == "hall_capture":
		return await _hall_capture(args)
	if action == "hall_reload_host":
		return await _hall_reload_host(args)
	if action == "hall_leave_guest":
		return await _hall_leave_guest()
	if action == "home_bed_rest":
		return await _home_bed_rest(args)
	if action == "home_bed_status":
		return _home_bed_status()
	return await super._execute_step(msg)

func _hall_guard(expected_peers: int = 2) -> Dictionary:
	var game := root.get_node_or_null("Game")
	var sess := _session()
	if game == null or sess == null or current_scene == null:
		return {}
	if not current_scene.has_method("shell_build_complete") or not bool(current_scene.call("shell_build_complete")) or bool(current_scene.get("simulation_only")):
		return {}
	if not bool(sess.call("is_active")) or not bool(sess.call("snapshot_ready")):
		return {}
	var hosting := bool(sess.call("is_host"))
	if str(sess.call("mode")) != ("host" if hosting else "client"):
		return {}
	if not hosting and not bool(sess.call("handshake_snapshot_applied")):
		return {}
	if bool(sess.get("_bootstrap_boundary")):
		return {}
	var registry: RefCounted = sess.call("registry")
	var me := int(sess.call("local_peer_id"))
	var row: Dictionary = registry.call("row", me)
	var local: RefCounted = game.get("local")
	var world: RefCounted = game.get("world")
	var character_id := str(local.get("character_id"))
	if character_id.is_empty() or str(row.get("character_id", "")) != character_id:
		return {}
	if str(row.get("realm", "")) != "meadows" or str(game.get("current_realm")) != "meadows":
		return {}
	if int(sess.call("peer_count")) != expected_peers or (expected_peers == 1 and not hosting):
		return {}
	var transition := sess.get_node_or_null("RealmTransition")
	if transition == null or not (transition.get("transactions") as Dictionary).is_empty():
		return {}
	if not (transition.get("_joining_local") as Dictionary).is_empty():
		return {}
	if not (transition.get("_joining") as Dictionary).is_empty():
		return {}
	var halls := _hall_scene_group("crossing_halls")
	if halls.size() != 1:
		return {}
	var hall: Node = halls[0]
	var display: Dictionary = world.get("redesign_world")
	if (hall.call("display_snapshot") as Dictionary) != display:
		return {}
	var world_id := str(world.get("world_id"))
	if world_id.is_empty():
		return {}
	var ledger_rpc := sess.get_node_or_null("LedgerRpc")
	var ledger: RefCounted = ledger_rpc.get("ledger") if ledger_rpc != null else null
	var saver: RefCounted = game.get("save_system")
	var character_store: RefCounted = saver.call("characters")
	return {"scene_instance": current_scene.get_instance_id(), "hall_instance": hall.get_instance_id(),
		"world_instance": world.get_instance_id(), "world_id": world_id,
		"local_peer_id": me, "character_id": character_id, "hosting": hosting,
		"session_epoch": int(transition.get("epoch")), "map_revision": int(registry.get("revision")),
		"world_revision": int(world.get("revision")), "ledger_seq": int(ledger.get("seq")) if ledger != null else -1,
		"registry_rows": registry.call("rows"), "display": display.duplicate(true),
		"character_load_result": character_store.get("last_load_result").duplicate(true)}

func _hall_wait_host_ready(started: Dictionary) -> Dictionary:
	# Keep SAME production_host in flight through real construction/release.
	# No clock reset or synthetic liveness; a real peer heartbeat follows readiness.
	var deadline: int = Time.get_ticks_msec() + 150000
	var stable: int = 0
	var prior: Dictionary = {}
	while Time.get_ticks_msec() < deadline:
		await physics_frame
		var guard: Dictionary = _hall_guard(1)
		stable = stable + 1 if not guard.is_empty() and guard == prior else 0
		prior = guard
		if stable >= 30:
			_send_heartbeat()
			var result: Dictionary = started.duplicate(true)
			result["host_ready_pin"] = guard.duplicate(true)
			result["detail"] = str(started.get("detail", "")) + "; real mounted world released and admitted host stable30 frames"
			return result
	return {"verdict": "FAIL", "detail": "production host world/admission did not finish real build in150s", "last_ready_guard": prior}

func _hall_scene_group(group: String) -> Array[Node]:
	var out: Array[Node] = []
	for node: Node in get_nodes_in_group(group):
		if current_scene != null and current_scene.is_ancestor_of(node):
			out.append(node)
	return out

func _hall_capture(args: Dictionary) -> Dictionary:
	# Each process earns readiness independently. Host expectations are never inputs.
	var deadline := Time.get_ticks_msec() + 20000
	var stable := 0
	var prior := {}
	while Time.get_ticks_msec() < deadline:
		await physics_frame
		var guard := _hall_guard()
		stable = stable + 1 if not guard.is_empty() and guard == prior else 0
		prior = guard
		if stable >= 30:
			_hall_pin = guard.duplicate(true)
			var data := _hall_producers()
			if data.is_empty() or _hall_guard() != _hall_pin:
				return {"verdict": "FAIL", "detail": "producer snapshot invalidated its own readiness/revision pin"}
			data = _hall_compact(data)
			data["pin"] = _hall_pin.duplicate(true)
			data["phase"] = str(args.get("phase", ""))
			data["peer_runtime_path"] = get_script().resource_path
			return {"verdict": "PASS", "detail": "30 independently stable admitted frames; captured real scene producers", "data": data}
	return {"verdict": "FAIL", "detail": "admitted identity/receiver/map/display readiness did not stabilize in 20 s"}

func _hall_producers() -> Dictionary:
	var villages: Array[Node] = []
	_hall_find_village(current_scene, villages)
	var halls := _hall_scene_group("crossing_halls")
	var arches := _hall_scene_group("crossing_hall_arches")
	var pedestals := _hall_scene_group("crossing_hall_pedestals")
	var houses := _hall_scene_group("village_road_houses")
	if villages.size() != 1 or halls.size() != 1 or arches.size() != 8 or pedestals.size() != 8 or houses.size() < 8 or houses.size() > 10:
		return {}
	var layout: Array = []
	_hall_tree(villages[0], "village", layout)
	var arch_rows: Array = []
	for node: Node in arches:
		var sign := node.get_node_or_null("BiomeSign") as Label3D
		var state := node.get_node_or_null("StateSign") as Label3D
		var surface := node.get_node_or_null("PortalSurface") as MeshInstance3D
		if sign == null or state == null or surface == null or surface.mesh == null or surface.material_override == null:
			return {}
		var meshes: Array = []
		_hall_tree(node, "arch", meshes)
		arch_rows.append({"id": str(node.name).trim_prefix("Arch_"), "biome": node.get_meta("biome", ""),
			"state": node.get_meta("arch_state", ""), "sign": sign.text, "state_sign": state.text,
			"sign_visible": sign.is_visible_in_tree(), "state_sign_visible": state.is_visible_in_tree(),
			"surface_visible": surface.is_visible_in_tree(), "material": _hall_material(surface.material_override),
			"nodes": meshes})
	var shrine_rows: Array = []
	for node: Node in pedestals:
		var nodes: Array = []
		_hall_tree(node, "pedestal", nodes)
		shrine_rows.append({"biome": node.get_meta("biome", ""), "relic_displayed": node.get_meta("relic_displayed", null), "nodes": nodes})
	var hall_nodes: Array = []
	_hall_tree(halls[0], "hall", hall_nodes)
	return {"producers": {"village_nodes": layout, "hall_nodes": hall_nodes, "arches": arch_rows, "shrines": shrine_rows},
		"counts": {"villages": villages.size(), "halls": halls.size(), "road_houses": houses.size(), "arches": arches.size(), "pedestals": pedestals.size()}}

func _hall_compact(data: Dictionary) -> Dictionary:
	var producers: Dictionary = data.producers
	var arches: Array = []
	for row: Dictionary in producers.arches:
		var summary := row.duplicate(true)
		summary["nodes_sha256"] = JSON.stringify(summary.nodes).sha256_text()
		summary.erase("nodes")
		arches.append(summary)
	var shrines: Array = []
	for row: Dictionary in producers.shrines:
		var visible_mesh := false
		var visible_label := false
		for node_row: Dictionary in row.nodes:
			visible_mesh = visible_mesh or (node_row.get("class", "") == "MeshInstance3D" and bool(node_row.get("visible_in_tree", false)))
			visible_label = visible_label or (node_row.get("class", "") == "Label3D" and bool(node_row.get("visible_in_tree", false)) and not str(node_row.get("text", "")).is_empty())
		shrines.append({"biome": row.biome, "relic_displayed": row.relic_displayed, "visible_mesh": visible_mesh,
			"visible_label": visible_label, "nodes_sha256": JSON.stringify(row.nodes).sha256_text()})
	return {"counts": data.counts, "arches": arches, "shrines": shrines,
		"digests": {"all": JSON.stringify(producers).sha256_text(),
			"village": JSON.stringify(producers.village_nodes).sha256_text(),
			"hall": JSON.stringify(producers.hall_nodes).sha256_text()},
		"node_counts": {"village": (producers.village_nodes as Array).size(), "hall": (producers.hall_nodes as Array).size()}}

func _hall_find_village(node: Node, out: Array[Node]) -> void:
	var script: Script = node.get_script()
	if script != null and script.resource_path == "res://scripts/world/village.gd":
		out.append(node)
	for child: Node in node.get_children():
		_hall_find_village(child, out)

func _hall_tree(node: Node, path: String, out: Array) -> void:
	# Structural paths avoid autogenerated @Node3D instance numbers across peers.
	var row := {"path": path, "class": node.get_class()}
	for key: String in ["village_role", "house_name", "biome", "arch_state", "relic_displayed"]:
		if node.has_meta(key):
			row[key] = node.get_meta(key)
	if node is Node3D:
		row["local_transform"] = _hall_transform(node.transform)
		row["global_transform"] = _hall_transform(node.global_transform)
		row["visible"] = node.visible
		row["visible_in_tree"] = node.is_visible_in_tree()
	if node is Label3D:
		row["text"] = node.text
		row["modulate"] = _hall_color(node.modulate)
		row["font_size"] = node.font_size
	if node is MeshInstance3D and node.mesh != null:
		row["mesh_class"] = node.mesh.get_class()
		row["mesh_resource"] = node.mesh.resource_path
		row["aabb"] = [_hall_vec(node.get_aabb().position), _hall_vec(node.get_aabb().size)]
		row["surface_count"] = node.mesh.get_surface_count()
		row["override"] = _hall_material(node.material_override)
		var materials: Array = []
		for index: int in node.mesh.get_surface_count():
			materials.append(_hall_material(node.get_active_material(index)))
		row["materials"] = materials
	if node is CollisionShape3D and node.shape != null:
		row["shape_class"] = node.shape.get_class()
		row["shape_resource"] = node.shape.resource_path
		row["disabled"] = node.disabled
		if node.shape is BoxShape3D:
			row["size"] = _hall_vec(node.shape.size)
	if node is Light3D:
		row["light_color"] = _hall_color(node.light_color)
		row["energy"] = node.light_energy
		row["shadow"] = node.shadow_enabled
	out.append(row)
	var index := 0
	for child: Node in node.get_children():
		_hall_tree(child, path + "/" + str(index), out)
		index += 1

func _hall_transform(value: Transform3D) -> Array:
	return [_hall_vec(value.basis.x), _hall_vec(value.basis.y), _hall_vec(value.basis.z), _hall_vec(value.origin)]

func _hall_vec(value: Vector3) -> Array:
	return [snappedf(value.x, 0.00001), snappedf(value.y, 0.00001), snappedf(value.z, 0.00001)]

func _hall_color(value: Color) -> Array:
	return [value.r, value.g, value.b, value.a]

func _hall_material(value: Material) -> Dictionary:
	if value == null:
		return {}
	var out := {"class": value.get_class(), "resource": value.resource_path}
	if value is BaseMaterial3D:
		out["albedo"] = _hall_color(value.albedo_color)
		out["emission_enabled"] = value.emission_enabled
		out["emission"] = _hall_color(value.emission)
		out["emission_energy"] = value.emission_energy_multiplier
		out["roughness"] = value.roughness
		out["transparency"] = value.transparency
		out["cull_mode"] = value.cull_mode
		out["albedo_texture"] = value.albedo_texture.resource_path if value.albedo_texture != null else ""
	return out

func _hall_reload_host(args: Dictionary) -> Dictionary:
	var game := root.get_node_or_null("Game")
	var sess := _session()
	if game == null or sess == null or not bool(sess.call("is_host")) or int(sess.call("peer_count")) != 1:
		return {"verdict": "FAIL", "detail": "reload requires the actual host with guest cleanly departed"}
	var old_scene := current_scene.get_instance_id()
	var old_halls := _hall_scene_group("crossing_halls")
	if old_halls.size() != 1:
		return {"verdict": "FAIL", "detail": "missing old Hall before reload"}
	var old_hall := old_halls[0].get_instance_id()
	var old_world_id := str(game.get("world").get("world_id"))
	var slot := int(game.call("autosave_slot"))
	if not bool(game.call("autosave_here")):
		return {"verdict": "FAIL", "detail": "production host autosave_here refused"}
	var saver: RefCounted = game.get("save_system")
	var world_store: RefCounted = saver.call("worlds")
	var disk := str(world_store.call("path_for", old_world_id))
	var before_disk := FileAccess.get_sha256(disk)
	if before_disk.is_empty():
		return {"verdict": "FAIL", "detail": "production split world file absent"}
	var left: Dictionary = await _step_leave({})
	if str(left.get("verdict", "")) != "PASS":
		return left
	before_disk = FileAccess.get_sha256(disk)
	# Production reader: decodes the typed save document and validates it.
	var saved: Dictionary = world_store.call("read", old_world_id)
	if saved.is_empty() or not saved.get("redesign_world") is Dictionary:
		return {"verdict": "FAIL", "detail": "production world reader found no redesign display payload: %s" % str(world_store.get("last_load_result"))}
	var saved_display: Dictionary = saved.get("redesign_world")
	# Real Load button continuation reads disk and rebuilds the ordinary scene.
	if change_scene_to_file(TITLE_SCENE) != OK:
		return {"verdict": "FAIL", "detail": "could not return host to title"}
	for frame in 120:
		await physics_frame
		if current_scene != null and current_scene.is_in_group("title_screen"):
			break
	if current_scene == null or not current_scene.is_in_group("title_screen"):
		return {"verdict": "FAIL", "detail": "host title did not become current"}
	current_scene.set("_host_port", int(args.get("port", _enet_port)))
	current_scene.call("_load_slot", slot)
	var deadline := Time.get_ticks_msec() + 150000
	while Time.get_ticks_msec() < deadline:
		await physics_frame
		var new_halls := _hall_scene_group("crossing_halls")
		if not _hall_guard(1).is_empty() and new_halls.size() == 1:
			var rebuilt := current_scene.get_instance_id() != old_scene and new_halls[0].get_instance_id() != old_hall
			var same_world := str(game.get("world").get("world_id")) == old_world_id
			var loaded: Dictionary = saver.get("last_load_result")
			var disk_display_matches: bool = saved_display == game.get("world").get("redesign_world")
			if rebuilt and same_world and bool(loaded.get("ok", false)) and disk_display_matches:
				_send_heartbeat()
			return {"verdict": "PASS" if rebuilt and same_world and bool(loaded.get("ok", false)) and disk_display_matches else "FAIL", "detail": "production autosave + title Load; scene and Hall rebuilt from host save", "data": {
				"old_scene_instance": old_scene, "new_scene_instance": current_scene.get_instance_id(),
				"old_hall_instance": old_hall, "new_hall_instance": new_halls[0].get_instance_id(),
				"world_id": old_world_id, "world_disk_sha256": before_disk, "world_disk_path": disk,
				"slot": slot, "rebuilt": rebuilt, "same_world": same_world, "load_result": loaded,
				"saved_display": saved_display, "disk_display_matches": disk_display_matches}}
	return {"verdict": "FAIL", "detail": "production title Load did not rebuild an active Hall in 150 s"}

func _hall_leave_guest() -> Dictionary:
	var game := root.get_node_or_null("Game")
	var sess := _session()
	if game == null or sess == null or bool(sess.call("is_host")) or not bool(sess.call("is_active")):
		return {"verdict": "FAIL", "detail": "guest leave requires the admitted active client"}
	var character_id := str(game.get("local").get("character_id"))
	var left: Dictionary = await _step_leave({})
	if str(left.get("verdict", "")) != "PASS":
		return left
	var saver: RefCounted = game.get("save_system")
	var store: RefCounted = saver.call("characters")
	var path := str(store.call("path_for", character_id))
	var saved: Dictionary = store.call("read", character_id)
	var load_result: Dictionary = store.get("last_load_result")
	var valid: bool = not saved.is_empty() and bool(load_result.get("ok", false)) and str(saved.get("character_id", "")) == character_id
	return {"verdict": "PASS" if valid else "FAIL", "detail": "production client leave saved its own portable character; production reader confirmed disk payload", "data": {
		"character_id": character_id, "character_disk_path": path, "character_disk_sha256": FileAccess.get_sha256(path), "load_result": load_result}}


## Home creature bed, two peers (owner ruling 2026-10-04; coordinator co-op
## rule: one two-peer occupancy case). Each peer rests ITS OWN portable party
## creature in the same world bed through the bed's own assign_creature and
## heals through Game's own bed-recovery tick. Disclosed fixtures: a starter is
## added only when the fresh character's party is empty, its HP is set to 10%,
## and the 120 s recovery is stepped through `_tick_creature_bed_recovery` (the
## same seam smoke_home_creature_bed.gd uses) rather than waited in real time.
func _home_bed() -> Node:
	return current_scene.get_node_or_null("GrandpaHouse/HomeCreatureBed") if current_scene != null else null

func _home_bed_rest(args: Dictionary) -> Dictionary:
	if _hall_guard(2).is_empty():
		return {"verdict": "FAIL", "detail": "home bed rest requires the admitted two-peer meadows session"}
	var game := root.get_node_or_null("Game")
	var bed := _home_bed()
	if bed == null:
		return {"verdict": "FAIL", "detail": "GrandpaHouse/HomeCreatureBed missing on this peer"}
	var party: RefCounted = game.get("party")
	var added := false
	if int(party.call("size")) == 0:
		added = bool(party.call("add", game.call("make_creature", str(args.get("species", "terrapup")))))
	var creature: RefCounted = party.call("at", 0)
	if creature == null:
		return {"verdict": "FAIL", "detail": "no party creature to rest"}
	var max_hp := float(creature.get("max_hp"))
	creature.set("hp", max_hp * 0.1)
	var occupied_before := bool(bed.call("is_occupied"))
	var assigned := bool(bed.call("assign_creature", 0))
	var resting := bool(creature.get("resting")) and int(creature.get("rest_bed_index")) == int(bed.call("build_index"))
	var seconds := float(preload("res://scripts/creatures/progression.gd").creature_bed_full_heal_seconds(preload("res://scripts/creatures/progression.gd").config()))
	for _i in 60:
		game.call("_tick_creature_bed_recovery", seconds / 60.0)
	await physics_frame
	var healed := is_equal_approx(float(creature.get("hp")), max_hp)
	var ok := assigned and resting and healed and not occupied_before
	return {"verdict": "PASS" if ok else "FAIL", "detail": "own creature rested in the shared home bed and healed to full", "data": {
		"character_id": str(game.get("local").get("character_id")), "hosting": bool(_session().call("is_host")),
		"starter_added_fixture": added, "occupied_by_own_party_before": occupied_before, "assigned": assigned,
		"resting": resting, "bed_index": int(bed.call("build_index")), "hp": float(creature.get("hp")), "max_hp": max_hp,
		"heal_seconds": seconds}}

func _home_bed_status() -> Dictionary:
	var game := root.get_node_or_null("Game")
	var bed := _home_bed()
	var party: RefCounted = game.get("party") if game != null else null
	var creature: RefCounted = party.call("at", 0) if party != null and int(party.call("size")) > 0 else null
	if bed == null or creature == null:
		return {"verdict": "FAIL", "detail": "home bed or party creature missing"}
	return {"verdict": "PASS", "detail": "home bed status read", "data": {
		"character_id": str(game.get("local").get("character_id")), "resting": bool(creature.get("resting")),
		"rest_bed_index": int(creature.get("rest_bed_index")), "occupied": bool(bed.call("is_occupied")),
		"hp": float(creature.get("hp")), "max_hp": float(creature.get("max_hp"))}}
