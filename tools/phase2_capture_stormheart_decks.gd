extends "res://tools/capture_stormwood_f10_matrix.gd"

## Explicitly stage on the actual raised production floors. The catalogue's
## horizontal Dynamo Core destination resolves to terrain and cannot prove the
## upper arena. The inherited production camera, weather and image capture stay
## unchanged; an eight-metre ray bracket verifies each intended physical floor.
## --phases=calm,break --no-aftermath yields eight frames.
var _deck_height := NAN
var _deck_floor_hit := {}
var _expected_floor := ""


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
