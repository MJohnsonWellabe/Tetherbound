extends "res://tools/capture_stormwood_f10_matrix.gd"

## Explicitly stage on the actual raised production floors. The catalogue's
## horizontal Dynamo Core destination resolves to terrain and cannot prove the
## upper arena. The inherited production camera, weather and image capture stay
## unchanged; an eight-metre ray bracket verifies each intended physical floor.
## --phases=calm,break --no-aftermath yields eight frames.
var _deck_height := NAN
var _deck_floor_hit := {}
var _expected_floor := ""
const HERO_CONFIG := "res://data/config/stormheart_presentation.json"
var _hero_original := PackedByteArray()
var _hero_candidate := false
var _hero_source := ""
var _hero_config_sha256 := ""
## --probe=<stand>:x,y+x,y — diagnostic only. After the frame is saved, lists
## the visible geometry whose screen-space bounds cover each pixel (1280x720
## frame coordinates), nearest first, in <frame>_probe.json. Changes nothing.
var _probes := {}


func _run() -> void:
	# Reuse the exterior matrix's hero-only overlay. This explicit preview
	# changes no shipping flag or regional material and restores exact bytes.
	_hero_candidate = OS.get_cmdline_user_args().has("--f41-candidate")
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--probe="):
			var spec := arg.trim_prefix("--probe=")
			var points: Array = []
			for pair: String in spec.get_slice(":", 1).split("+", false):
				points.append(Vector2(float(pair.get_slice(",", 0)), float(pair.get_slice(",", 1))))
			_probes[spec.get_slice(":", 0)] = points
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--source-commit="):
			_hero_source = arg.trim_prefix("--source-commit=")
	if _hero_candidate:
		var sha := RegEx.new()
		sha.compile("^[0-9a-f]{40}$")
		if sha.search(_hero_source) == null:
			push_error("Stormheart candidate needs an exact --source-commit")
			quit(2)
			return
		_hero_original = FileAccess.get_file_as_bytes(HERO_CONFIG)
		var parsed: Variant = JSON.parse_string(_hero_original.get_string_from_utf8())
		if not parsed is Dictionary:
			_failures.append("Stormheart candidate config is invalid")
			_done()
			return
		var config: Dictionary = parsed
		config.enabled = true
		for part: String in ["ancient_trunk", "built_detail", "branching_crown", "canopy_atlas", "core_finish", "visible_roots"]:
			config[part].enabled = true
		var file := FileAccess.open(HERO_CONFIG, FileAccess.WRITE)
		if file == null:
			_failures.append("Stormheart candidate config cannot be staged")
			_done()
			return
		file.store_string(JSON.stringify(config, "\t") + "\n")
		file.flush()
		var error := file.get_error()
		file.close()
		if error != OK:
			_failures.append("Stormheart candidate config flush failed")
			_done()
			return
	_hero_config_sha256 = FileAccess.get_file_as_string(HERO_CONFIG).sha256_text()
	await super._run()
	_restore_hero_config()


func _restore_hero_config() -> void:
	if _hero_original.is_empty():
		return
	var file := FileAccess.open(HERO_CONFIG, FileAccess.WRITE)
	if file == null:
		_failures.append("Stormheart original config cannot be restored")
		return
	file.store_buffer(_hero_original)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or FileAccess.get_file_as_bytes(HERO_CONFIG) != _hero_original:
		_failures.append("Stormheart original config restore mismatch")
	_hero_original.clear()


func _capture(frame_id: String, description: String, full_size: bool, extra: Dictionary = {}) -> void:
	await super._capture(frame_id, description, full_size, extra.merged({
		"candidate_preview": _hero_candidate, "source_commit": _hero_source,
		"stormheart_config_sha256": _hero_config_sha256}, true))


func _done() -> void:
	_restore_hero_config()
	super._done()


func _matrix_pass(aftermath: bool) -> void:
	var tree := _world.get_node_or_null("StormheartTree") as Node3D
	if tree == null:
		_failures.append("StormheartTree missing")
		return
	if aftermath:
		_game.get("progression").call("set_flag","stormwood:long_storm_ended",true)
		_note("aftermath flag set by capture fixture")
	var stands := [
		{"id":"entry_deck","floor":"OuterWorks","at":Vector3(0,6,-35),"focus":Vector3(0,42,0),"pitch":16.0},
		{"id":"middle_ascent","floor":"HollowTrunkAscent","at":tree.call("ascent_point",0.38),"focus":Vector3(0,80,0),"pitch":10.0},
		{"id":"core_arena","floor":"DynamoCore","at":Vector3(0,150,25),"focus":Vector3(0,155,-25),"pitch":4.0},
		{"id":"crown_chamber","floor":"CrownChamber","at":Vector3(12,174,0),"focus":Vector3(0,174,0),"pitch":-4.0}
	]
	var known: Array = stands.map(func(row: Dictionary) -> String: return str(row.id))
	for requested: String in _stands_only:
		if not known.has(requested):
			_failures.append("unknown raised-deck stand: "+requested)
			return
	for phase: String in _phases_only:
		if phase not in ["calm","building","break","fading"]:
			_failures.append("unknown storm phase: "+phase)
			return
	var captured_before := _frames.size()
	for stand: Dictionary in stands:
		if not _stands_only.is_empty() and not _stands_only.has(str(stand.id)):
			continue
		var at := tree.to_global(stand.at)
		_deck_height = at.y
		_deck_floor_hit = {}
		_expected_floor = "StormheartTree/"+str(stand.floor)
		await _stand(Vector2(at.x,at.z),tree.to_global(stand.focus),float(stand.pitch))
		if _deck_floor_hit.is_empty() or absf(_player.global_position.y-_deck_height)>0.65:
			_failures.append("%s did not settle on its intended raised floor"%stand.id)
			continue
		_note("debug placement on actual raised floor; not earned ascent or traversal proof")
		var phases: Array = ["calm"] if aftermath else _phases_only
		for phase: String in phases:
			await _enter_phase(phase,aftermath)
			_heal()
			if phase == "break" and not aftermath:
				await _await_sky_bolt()
			if absf(_player.global_position.y-_deck_height)>0.65:
				_failures.append("%s left the raised floor before capture"%stand.id)
				continue
			_hud_visible(_hud)
			var id := "%s_%s%s"%[stand.id,"aftermath_" if aftermath else "",phase]
			await _capture(id,"Stormheart actual raised "+str(stand.id),true,{
				"camera_basis":[_vec3(_camera.global_basis.x),_vec3(_camera.global_basis.y),_vec3(_camera.global_basis.z)],
				"tree_origin":_vec3(tree.global_position),"intended_local_floor":_vec3(stand.at),
				"actual_player_local":_vec3(tree.to_local(_player.global_position)),"floor_hit":_deck_floor_hit,
				"fixture_limit":"Debug placement on verified floor; not earned ascent/traversal proof."})
			_log("captured "+id)
			_write_probes(id, str(stand.id))
	if _frames.size() == captured_before:
		_failures.append("raised-deck selection captured no frames")


func _floor_at(x: float,z: float,_probe_above: float = 4.0) -> float:
	var query := PhysicsRayQueryParameters3D.create(Vector3(x,_deck_height+4.0,z),Vector3(x,_deck_height-4.0,z),1)
	query.exclude = [_player.get_rid()]
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or absf(float((hit.position as Vector3).y)-_deck_height)>0.1:
		_failures.append("raised floor ray failed at "+str(Vector3(x,_deck_height,z)))
		return _deck_height
	var collider := hit.collider as Node
	if collider == null or str(_world.get_path_to(collider)) != _expected_floor:
		_failures.append("floor ray did not hit "+_expected_floor)
		return _deck_height
	_deck_floor_hit = {"position":_vec3(hit.position),"normal":_vec3(hit.normal),
		"collider_path":str(_world.get_path_to(collider)) if collider != null else ""}
	return float((hit.position as Vector3).y)


func _write_probes(frame_id: String, stand_id: String) -> void:
	if not _probes.has(stand_id):
		return
	var size := Vector2(root.get_visible_rect().size)
	var rows: Array = []
	for pixel: Vector2 in _probes[stand_id]:
		var at := pixel * size / Vector2(1280, 720)
		var hits: Array = []
		for node: Node in _world.find_children("*", "GeometryInstance3D", true, false):
			var geo := node as GeometryInstance3D
			if not geo.is_visible_in_tree():
				continue
			var boxes: Array[AABB] = []
			if geo is MultiMeshInstance3D and (geo as MultiMeshInstance3D).multimesh != null:
				var mm := (geo as MultiMeshInstance3D).multimesh
				if mm.mesh == null:
					continue
				for i in mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count:
					boxes.append(geo.global_transform * mm.get_instance_transform(i) * mm.mesh.get_aabb())
			else:
				boxes.append(geo.global_transform * geo.get_aabb())
			for index in boxes.size():
				var hit := _box_covers(boxes[index], at)
				if hit >= 0.0:
					var material := geo.material_override if geo.material_override != null else null
					hits.append({"path": str(_world.get_path_to(geo)), "instance": index, "distance": hit,
						"class": geo.get_class(), "aabb_size": _vec3(boxes[index].size),
						"material": material.resource_name if material != null else ""})
		hits.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.distance) < float(b.distance))
		# Large meshes that enclose the camera (ramp, trunk) fail the box test;
		# a physics ray names the solid surface actually under the pixel.
		var from := _camera.project_ray_origin(at)
		var query := PhysicsRayQueryParameters3D.create(from, from + _camera.project_ray_normal(at) * 2000.0)
		var ray := _camera.get_world_3d().direct_space_state.intersect_ray(query)
		var surface := {}
		if not ray.is_empty() and ray.collider is Node:
			surface = {"collider": str(_world.get_path_to(ray.collider as Node)), "position": _vec3(ray.position),
				"normal": _vec3(ray.normal), "distance": from.distance_to(ray.position)}
		rows.append({"pixel": [pixel.x, pixel.y], "ray": surface, "nearest": hits.slice(0, 14)})
	var file := FileAccess.open(ProjectSettings.globalize_path("%s/%s_probe.json" % [_output_dir, frame_id]), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(rows, "\t"))
		file.close()


## Camera distance to the box centre when its projected corners cover `pixel`
## and it is in front of the camera; -1 otherwise.
func _box_covers(box: AABB, pixel: Vector2) -> float:
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for corner in 8:
		var point := box.get_endpoint(corner)
		if _camera.is_position_behind(point):
			return -1.0
		var screen := _camera.unproject_position(point)
		low = low.min(screen)
		high = high.max(screen)
	if pixel.x < low.x or pixel.x > high.x or pixel.y < low.y or pixel.y > high.y:
		return -1.0
	return _camera.global_position.distance_to(box.get_center())
