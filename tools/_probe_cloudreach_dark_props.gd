## CLOUDREACH-DRESS-0906 scratch probe. Judge defect 6 names "near-black matte
## blobs with no highlight that read as bin bags or tents" at stand 11, two of
## them either side of the clearing. The absent-`metallicFactor` glTF defect was
## already ruled out (0 of 14 route-detail props import as metal), so this asks
## the frame itself: reconstruct the exact stand-11 production camera the
## capture tool poses, project every drawn surface into it, and rank what is
## both DARK and BIG ON SCREEN. Ranking by world size alone answers the wrong
## question -- a 32 m mooring line 40 m away and a 1.5 m sack 8 m away occupy
## very different amounts of the judge's frame.
##   godot --headless --path . --script tools/_probe_cloudreach_dark_props.gd
extends SceneTree

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
# tools/_capture_cloudreach_cliff_options.gd, view "11-aerie-ground-connection".
var STAND := Vector2(373.0, 3262.5356)
var TARGET := Vector3(400.0, 614.0, 3250.0)
var PITCH_DEG := -5.0
const SPRING_M := 5.8
const FOV := 70.0
const VIEW := Vector2(1280.0, 800.0)


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	# `--stand=06` re-points the reconstruction at the summit approach view.
	for arg in OS.get_cmdline_user_args():
		if arg == "--stand=06":
			STAND = Vector2(100.0, 5290.0)
			TARGET = Vector3(100.0, 1215.0, 5350.0)
			PITCH_DEG = 18.0
	var game := root.get_node_or_null(^"Game")
	if game != null and game.has_method("reset_for_new_game"):
		game.call("reset_for_new_game")
		game.set("current_realm", "cloudreach")
	var world := SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	for _f in 8:
		await process_frame

	# Rebuild the capture tool's camera pose arithmetic exactly.
	var ground := float(world.call("ground_height_at", STAND.x, STAND.y))
	var player_at := Vector3(STAND.x, ground + 0.2, STAND.y)
	var pivot := player_at + Vector3.UP * 1.55
	var sightline := TARGET - player_at
	var yaw := atan2(-sightline.x, -sightline.z)
	var rig_basis := Basis.from_euler(Vector3(deg_to_rad(PITCH_DEG), yaw, 0.0))
	# A SpringArm3D holds the camera SPRING_M back along its own +Z.
	var cam_at := pivot + rig_basis * Vector3(0.0, 0.0, SPRING_M)
	var cam_xform := Transform3D(rig_basis, cam_at)
	var to_view := cam_xform.affine_inverse()
	var focal := (VIEW.y * 0.5) / tan(deg_to_rad(FOV) * 0.5)
	print("stand ground=%.2f player=%s camera=%s" % [ground, player_at, cam_at])

	var rows: Array[Dictionary] = []
	for node: Node in world.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree():
			continue
		var world_aabb := mi.global_transform * mi.get_aabb()
		# Project the eight corners; keep it only if it lands in frame.
		var min_px := Vector2(INF, INF)
		var max_px := Vector2(-INF, -INF)
		var any_front := false
		for corner in 8:
			var local: Vector3 = to_view * world_aabb.get_endpoint(corner)
			if local.z > -0.25:
				continue
			any_front = true
			var px := Vector2(local.x / -local.z, local.y / -local.z) * focal
			min_px = min_px.min(px)
			max_px = max_px.max(px)
		if not any_front:
			continue
		var half := VIEW * 0.5
		if max_px.x < -half.x or min_px.x > half.x or max_px.y < -half.y or min_px.y > half.y:
			continue
		var box := Rect2(min_px, max_px - min_px).intersection(Rect2(-half, VIEW))
		var frac := (box.size.x * box.size.y) / (VIEW.x * VIEW.y)
		if frac < 0.0008:
			continue

		var darkest := 2.0
		var detail := ""
		for surface in mi.mesh.get_surface_count():
			var mat: Material = mi.get_surface_override_material(surface)
			if mat == null:
				mat = mi.get_active_material(surface)
			var albedo := Color(1, 1, 1)
			var note := "-"
			if mat is StandardMaterial3D:
				var std := mat as StandardMaterial3D
				albedo = std.albedo_color
				note = "std tex=%s m=%.2f r=%.2f" % [
					"y" if std.albedo_texture != null else "n", std.metallic, std.roughness]
			elif mat is ShaderMaterial:
				var sh := mat as ShaderMaterial
				note = "shader " + str(sh.shader.resource_path.get_file())
				var probe: Variant = sh.get_shader_parameter("tint")
				if probe == null:
					probe = sh.get_shader_parameter("colour")
				if probe is Color:
					albedo = probe
				else:
					continue  # cannot judge a shader with no flat colour parameter
			var lum := 0.2126 * albedo.r + 0.7152 * albedo.g + 0.0722 * albedo.b
			if lum < darkest:
				darkest = lum
				detail = "%s | %s" % [str(albedo).substr(0, 20), note]
		if darkest > 1.5:
			continue
		# Image-space rectangle (origin top-left), so a rect measured off the
		# rendered PNG can be matched straight back to the node that drew it.
		var img := Rect2(box.position.x + half.x, half.y - (box.position.y + box.size.y),
			box.size.x, box.size.y)
		rows.append({"img": img, "lum": darkest, "frac": frac, "name": str(mi.name),
			"path": str(world.get_path_to(mi)), "detail": detail,
			"d": mi.global_position.distance_to(cam_at),
			"px": Vector2(box.size.x, box.size.y)})

	# Rank by how much dark area each one actually puts on the judge's screen.
	rows.sort_custom(func(a, b):
		return float(a["frac"]) * (1.0 - float(a["lum"])) > float(b["frac"]) * (1.0 - float(b["lum"])))
	print("=== stand 11: in-frame surfaces ranked by (screen area x darkness) ===")
	var shown := 0
	for row: Dictionary in rows:
		if shown >= 22:
			break
		shown += 1
		var px: Vector2 = row["px"]
		var r: Rect2 = row["img"]
		print("  img x %.0f..%.0f  y %.0f..%.0f" % [r.position.x, r.position.x + r.size.x,
			r.position.y, r.position.y + r.size.y])
		print("score=%.4f lum=%.3f screen=%.2f%% (%.0fx%.0f px) d=%.0fm  %s\n        %s\n        %s" % [
			float(row["frac"]) * (1.0 - float(row["lum"])), row["lum"], float(row["frac"]) * 100.0,
			px.x, px.y, row["d"], row["name"], row["detail"], row["path"]])
	print("=== what draws inside the two measured blob rectangles ===")
	for probe: Dictionary in [
		{"label": "LEFT blob  (x 130-260, y 345-455)", "rect": Rect2(130, 345, 130, 110)},
		{"label": "RIGHT blob (x 880-1010, y 275-365)", "rect": Rect2(880, 275, 130, 90)},
		{"label": "06 lumber pile (x 850-1015, y 500-550)", "rect": Rect2(850, 500, 165, 50)},
	]:
		print("--- %s" % probe["label"])
		var hits: Array[Dictionary] = []
		for row: Dictionary in rows:
			var r: Rect2 = row["img"]
			var overlap := r.intersection(probe["rect"] as Rect2)
			if overlap.size.x <= 0.0 or overlap.size.y <= 0.0:
				continue
			# Only things whose own footprint is mostly inside the blob, so a
			# huge background mass that merely spans it is not the answer.
			var covered := (overlap.size.x * overlap.size.y) / maxf(r.size.x * r.size.y, 1.0)
			if covered < 0.25:
				continue
			hits.append({"covered": covered, "row": row})
		hits.sort_custom(func(a, b): return float(a["covered"]) > float(b["covered"]))
		for hit: Dictionary in hits.slice(0, 6):
			var row: Dictionary = hit["row"]
			var r2: Rect2 = row["img"]
			print("   covered=%.0f%% lum=%.3f d=%.0fm  x %.0f..%.0f y %.0f..%.0f  %s\n        %s\n        %s" % [
				float(hit["covered"]) * 100.0, row["lum"], row["d"], r2.position.x,
				r2.position.x + r2.size.x, r2.position.y, r2.position.y + r2.size.y,
				row["name"], row["detail"], row["path"]])
	quit(0)
