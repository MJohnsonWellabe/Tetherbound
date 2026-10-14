import json
root='/home/user/Tetherbound/'
# vegetation
p=root+'scripts/world/vegetation.gd'; s=open(p).read()
anchor='func restore_fight_occluders(token: PackedInt32Array) -> int:'
assert s.count(anchor)==1
add='''## F10#2 (coordinator, 13 Oct): trees ON the line from the fight camera to the
## fight dither out at any distance, not only near the lens (near_lens_fade).
## Render instances only: their trunk colliders, placements and harvest stay.
## `foliage_camera_visibility.json` `line_of_sight_fade` lists the realm,
## models and the clear radius around each sight line. Key -> [mesh, transform].
var _los_hidden: Dictionary = {}


func update_line_of_sight_occluders(lens: Vector3, targets: Array) -> void:
	var cfg: Dictionary = CAMERA_VISIBILITY.config().get("line_of_sight_fade", {})
	var enabled := bool(cfg.get("enabled", false)) and _realm_bake_name in cfg.get("realms", []) \\
		and _instancer != null and not simulation_only and lens.is_finite()
	var want := {}
	if enabled:
		var clear := maxf(0.0, float(cfg.get("clear_radius_m", 1.5)))
		var models: Array = cfg.get("models", [])
		var flat_lens := Vector2(lens.x, lens.z)
		for batch: Dictionary in _collision_batches:
			var model := str(batch.get("model", ""))
			if not model in models:
				continue
			var mesh_id := _mesh_id_for(model)
			if mesh_id < 0:
				continue
			var span := _model_footprint_radius(model)
			for placement: Dictionary in batch.get("placements", []):
				var spot: Vector3 = placement["position"]
				var flat := Vector2(spot.x, spot.z)
				var reach := span * float(placement.get("scale", 1.0)) + clear
				for target: Variant in targets:
					if not target is Vector3:
						continue
					var end := Vector2((target as Vector3).x, (target as Vector3).z)
					var line := end - flat_lens
					var length_sq := line.length_squared()
					if length_sq < 0.01:
						continue
					var t := (flat - flat_lens).dot(line) / length_sq
					if t <= 0.0 or t >= 0.92:
						continue
					if (flat_lens + line * t).distance_to(flat) > reach:
						continue
					var basis := Basis(Vector3.UP, float(placement.get("yaw", 0.0))).scaled(
						Vector3.ONE * float(placement.get("scale", 1.0)))
					want["%d|%.2f|%.2f" % [mesh_id, spot.x, spot.z]] = [mesh_id, Transform3D(basis, spot - Vector3.UP * SINK), spot]
					break
	var changed := false
	for key: String in want:
		if _los_hidden.has(key):
			continue
		var row: Array = want[key]
		_remove_render_instance(int(row[0]), row[2] as Vector3, false)
		_los_hidden[key] = row
		changed = true
	var restore := {}
	for key: String in _los_hidden.keys():
		if want.has(key):
			continue
		var row: Array = _los_hidden[key]
		if not restore.has(row[0]):
			restore[row[0]] = []
		(restore[row[0]] as Array).append(row[1])
		_los_hidden.erase(key)
	for mesh_id: int in restore:
		var transforms: Array[Transform3D] = []
		transforms.assign(restore[mesh_id])
		_instancer.call("add_transforms", mesh_id, transforms, PackedColorArray(), false)
		changed = true
	if changed:
		_refresh_render_instances()


'''
s=s.replace(anchor, add+anchor)
open(p,'w').write(s)
# arena
p=root+'scripts/combat/combat_arena.gd'; s=open(p).read()
old='''func _exit_tree() -> void:
	for pair: Array in _stepped_aside:'''
new='''## F10#2: re-checks the trees on the camera-to-fight line this often (s).
const LINE_OF_SIGHT_PERIOD_S := 0.2
var _line_of_sight_left := 0.0


func _process(delta: float) -> void:
	_line_of_sight_left -= delta
	if _line_of_sight_left > 0.0:
		return
	_line_of_sight_left = LINE_OF_SIGHT_PERIOD_S
	var vegetation := get_parent().get_node_or_null(^"Vegetation") if get_parent() != null else null
	var camera := get_viewport().get_camera_3d() if get_viewport() != null else null
	if vegetation == null or camera == null or not vegetation.has_method("update_line_of_sight_occluders"):
		return
	vegetation.call("update_line_of_sight_occluders", camera.global_position, [global_position + Vector3.UP * 1.2])


func _exit_tree() -> void:
	var sight := get_parent().get_node_or_null(^"Vegetation") if get_parent() != null else null
	if sight != null and is_instance_valid(sight) and sight.has_method("update_line_of_sight_occluders") \\
			and not sight.is_queued_for_deletion():
		sight.call("update_line_of_sight_occluders", Vector3.INF, [])
	for pair: Array in _stepped_aside:'''
assert s.count(old)==1; s=s.replace(old,new); open(p,'w').write(s)
# config
p=root+'data/config/foliage_camera_visibility.json'; d=json.load(open(p))
d['line_of_sight_fade']={"_why":"F10#2 (coordinator, 13 Oct): trees on the line from the fight camera to the fight centre are hidden from rendering at any distance while the fight lasts (collision unchanged), re-checked every 0.2 s by combat_arena.gd. Capacitor (Conductor Run) still had trunks beyond the 7 m near-lens fade crossing the view (judge 4.5/10). TUNABLE.","enabled":True,"realms":["stormwood"],"clear_radius_m":1.5,"models":d['near_lens_fade']['models'][:5]}
json.dump(d,open(p,'w'),indent=2); open(p,'a').write('\n')
print('patched')
