extends SceneTree

## Capture the backpack and build tabs for the EV9-remainder blind-judge pass
## (inventory grid + crafting panel re-skinned onto playground_hud.gd's dark
## blue-gray/teal panel language, bible §16).
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_menu_panels.gd
##
## Three frames:
##   menu_backpack      - the backpack tab, grid + detail panel
##   menu_build         - the build tab, catalogue list + detail panel
##   menu_target_picker - OF2's new item-target picker, mid-flow (backpack tab
##                        with the picker open over an injured party member)

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/_diag"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 8


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	if OS.get_cmdline_user_args().has("--actual-master-sites"):
		await _capture_actual_master_sites()
		return

	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return

	var world: Node = packed.instantiate()
	root.add_child(world)
	if OS.get_cmdline_user_args().has("--actual-bounty-board"):
		# Shipping local authority resolves its actual realm through this scene.
		current_scene = world

	for i in SETTLE_FRAMES:
		await physics_frame

	var game := root.get_node_or_null(^"Game")
	if game == null:
		push_error("Game autoload not in the tree")
		quit(1)
		return
	var menu: Node = game.call("menu")
	if menu == null:
		push_error("autoload did not stand up the menu")
		quit(1)
		return
	if OS.get_cmdline_user_args().has("--actual-bounty-board"):
		await _capture_actual_bounty(game)
		return

	# A stocked satchel and a couple of buildables, so the panels shown are not
	# just empty rows — the critic needs to judge the panel treatment against
	# real contents, the same way it would in a played build.
	var inventory: RefCounted = game.get("inventory")
	var party: RefCounted = game.get("party")
	if party != null and int(party.call("size")) == 0:
		var creature: RefCounted = game.call("make_creature", "terrapup")
		if creature != null:
			party.call("add", creature)
	if inventory != null:
		inventory.call("add", "orb_basic", 3)
		inventory.call("add", "potion_small", 2)
		inventory.call("add", "wood", 12)
		inventory.call("add", "stone", 5)
		inventory.call("add", "fiber", 20)
		inventory.call("add", "berries", 4)

	var written: Array[String] = []
	var failures: Array[String] = []

	menu.call("open", "backpack")
	for i in POSE_FRAMES:
		await process_frame
	await _shoot("menu_backpack", written, failures)

	# open() is a no-op while the menu is already open (game_menu.gd's own
	# guard) -- switching tabs mid-session needs close() first, or the second
	# shot silently repeats the first tab.
	menu.call("close")
	menu.call("open", "build")
	for i in POSE_FRAMES:
		await process_frame
	await _shoot("menu_build", written, failures)

	menu.call("close")
	menu.call("open", "backpack")
	for i in POSE_FRAMES:
		await process_frame
	# Injure whoever is in slot 1 so the picker's HP readout has something to
	# show besides a flat full bar, then drive the real Use path -- inject
	# the actual `interact` action rather than calling a private method, so
	# this frame shows what a player's press really produces.
	var backpack: Node = menu.get("_bodies")[0]
	var target: RefCounted = party.call("at", 1) if party != null and int(party.call("size")) > 1 else null
	if target != null:
		target.set("hp", float(target.get("max_hp")) * 0.4)
	var slot: int = int(inventory.call("find_slot", "potion_small")) if inventory != null else -1
	if slot >= 0:
		(backpack.get("_buttons")[slot] as Button).grab_focus()
		var event := InputEventAction.new()
		event.action = "interact"
		event.pressed = true
		Input.parse_input_event(event)
		Input.action_press("interact")
		await process_frame
		await process_frame
		Input.action_release("interact")
		event.pressed = false
		Input.parse_input_event(event)
	for i in POSE_FRAMES:
		await process_frame
	await _shoot("menu_target_picker", written, failures)

	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])
	print("Software rendering. Frame times from this harness are NOT a performance measurement.")

	if not failures.is_empty():
		print("")
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


func _capture_actual_bounty(game: Node) -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Actual bounty pixels require a native display")
		quit(1)
		return
	# Visual-only approach pose, never an earned journey or a payment. The
	# actual first-day board and rows come from the shipping owner/host path;
	# this branch precedes the legacy inventory/party layout fixtures above.
	var session: Node = game.get("session")
	var adapter := session.get_node_or_null(^"FoundationComposition/BountyInteraction") if session != null else null
	var player: Node3D = game.call("find_player")
	var prompt: Node3D = adapter.get("_prompt") if adapter != null else null
	var panel := adapter.get_node_or_null(^"BountyBoardPanel") if adapter != null else null
	if player == null or prompt == null or panel == null:
		push_error("Actual mounted Halda prompt/player/panel required")
		quit(1)
		return
	var original_local: RefCounted = game.get("local")
	var original_world: RefCounted = game.get("world")
	var epoch: String = session.call("_altar_current_epoch")
	player.global_position = prompt.global_position + Vector3(0, -0.9, 0.5)
	player.set("velocity", Vector3.ZERO)
	for frame in 120: await physics_frame
	var arbiter := get_first_node_in_group(&"interaction_arbiter")
	if arbiter == null or arbiter.call("winning_provider") != prompt:
		push_error("Actual Halda prompt must win physical interaction")
		quit(1)
		return
	var written: Array[String] = []
	var failures: Array[String] = []
	for size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = size
		root.content_scale_size = Vector2i.ZERO
		for frame in POSE_FRAMES: await process_frame
		var press := InputEventAction.new()
		press.action = "interact"
		press.pressed = true
		Input.parse_input_event(press)
		Input.action_press("interact")
		for frame in 4: await process_frame
		Input.action_release("interact")
		press.pressed = false
		Input.parse_input_event(press)
		for frame in POSE_FRAMES: await process_frame
		var view: Dictionary = adapter.call("view")
		var owner := preload("res://scripts/ui/input_owner.gd").current(self)
		var valid: bool = game.get("session") == session and game.get("local") == original_local and game.get("world") == original_world \
			and session.call("_altar_current_epoch") == epoch and view.get("ready") == true \
			and view.get("character_id") == original_local.get("character_id") \
			and view.get("world_namespace") == original_world.get("reward_delivery_namespace") \
			and (view.get("rows", []) as Array).size() == 3 and panel.get("_shown") == true and owner == panel
		var row_ids: Array[String] = []
		for row: Dictionary in view.get("rows", []):
			var found := false
			for button: Button in panel.get("_buttons"):
				if button.get_meta("system_focus_key", "") == row.get("instance"): found = true
			valid = valid and found
			row_ids.append(str(row.get("instance", "")))
		if not valid:
			failures.append("Actual current-scope three-row board did not open through physical X")
			break
		print("ACTUAL_BOUNTY %dx%d character=%s namespace=%s instances=%s focus=%s" % [size.x, size.y,
			original_local.get("character_id"), original_world.get("reward_delivery_namespace"), row_ids, root.gui_get_focus_owner()])
		await _shoot("actual_bounty_%dx%d" % [size.x, size.y], written, failures)
		press.action = "menu_cancel"
		press.pressed = true
		Input.parse_input_event(press)
		Input.action_press("menu_cancel")
		for frame in 4: await process_frame
		Input.action_release("menu_cancel")
		press.pressed = false
		Input.parse_input_event(press)
		for frame in 15: await physics_frame
		if panel.get("_shown") == true or preload("res://scripts/ui/input_owner.gd").current(self) != null:
			failures.append("One ordinary B must restore world input after actual bounty capture")
			break
	print("Actual bounty visual capture: approach pose only; no invented rows, payment, earned-route or performance claim.")
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() and written.size() == 2 else 1)


## F28#1 placement-only opt-in. Actual mounted sites/signs in the four shipping
## scenes, with disclosed capture-realm selection and trainer/camera poses.
## No party, stock, recipe, win, clock, save or configuration grants; no
## earned travel, duel or access proof.
func _capture_actual_master_sites() -> void:
	# SceneTree._init runs before the actual Game autoload is mounted.
	await process_frame
	if DisplayServer.get_name() == "headless":
		push_error("Master placement capture requires the existing render mode")
		quit(1)
		return
	var written: Array[String] = []
	var failures: Array[String] = []
	var observed: Array[Dictionary] = []
	var capture_ids: Array[String] = ["master_t1", "master_t2", "master_t3", "master_t4", "master_t5"]
	var measure_clearance := false
	for argument: String in OS.get_cmdline_user_args():
		if not argument.begins_with("--master-sites="): continue
		if measure_clearance or argument not in ["--master-sites=master_t1,master_t3,master_t4", "--master-sites=master_t1,master_t4"]:
			push_error("Master subset must be one retained blocked-sign set, once")
			quit(1)
			return
		capture_ids = ["master_t1", "master_t4"] if argument == "--master-sites=master_t1,master_t4" else ["master_t1", "master_t3", "master_t4"]
		measure_clearance = true
	var game := root.get_node_or_null(^"Game")
	if game == null or game.get("local") == null:
		push_error("Actual capture owner is missing")
		quit(1)
		return
	var original_realm := str(game.get("current_realm"))
	var cases := [
		{"biome": "meadows", "scene": SCENE, "ids": ["master_t1", "master_t2"]},
		{"biome": "tidewake", "scene": "res://scenes/world/water_archipelago.tscn", "ids": ["master_t3"]},
		{"biome": "cloudreach", "scene": "res://scenes/world/cloudreach_cliffs.tscn", "ids": ["master_t4"]},
		{"biome": "stormwood", "scene": "res://scenes/world/stormwood.tscn", "ids": ["master_t5"]}]
	for entry: Dictionary in cases:
		# Existing regional capture convention: bind the displayed realm so
		# ordinary occupied-world mounting observes the matching live scene.
		# This is capture setup, not a portal crossing or a permanent unlock.
		game.set("current_realm", preload("res://scripts/data/biome_order.gd").runtime_id(str(entry.biome)))
		var packed := load(str(entry.scene)) as PackedScene
		if packed == null:
			failures.append("Missing actual scene: " + str(entry.scene))
			break
		var world := packed.instantiate() as Node3D
		root.add_child(world)
		current_scene = world
		for frame in SETTLE_FRAMES: await physics_frame
		var player := world.get_node_or_null(^"Player") as CharacterBody3D
		var camera := root.get_camera_3d()
		if player == null or camera == null:
			failures.append("Actual trainer/camera missing: " + str(entry.biome))
			break
		# Retain the shipping camera object; stop only its automatic positioning
		# while this capture tool supplies its disclosed composition.
		camera.get_parent().set_process(false)
		camera.get_parent().set_physics_process(false)
		# SpringArm3D internally rewrites direct children's transforms even
		# with its script stopped. Retain the shipping lens outside that arm
		# while the existing capture tool supplies its disclosed composition.
		camera.reparent(world)
		for id: String in entry.ids:
			var matches: Array[Node3D] = []
			for node: Node in get_nodes_in_group("foundation_master_sites"):
				if node is Node3D and world.is_ancestor_of(node) and node.get("master_id") == id: matches.append(node as Node3D)
			if matches.size() != 1 or matches[0].get("_mounted") != true:
				failures.append("One actual mounted Master required: " + id)
				break
			var site: Node3D = matches[0]
			var definition: Dictionary = site.get("_definition")
			var expected: Array = definition.get("position", [])
			var sign_at: Array = definition.get("sign_position", []).duplicate()
			var npc := site.get_node_or_null(^"Master") as Node3D
			if definition.get("biome") != entry.biome or expected.size() != 3 or sign_at.size() != 3 \
				or npc == null or not npc.is_visible_in_tree() \
				or Vector2(site.global_position.x, site.global_position.z).distance_to(Vector2(float(expected[0]), float(expected[2]))) > 0.05:
				failures.append("Actual Master placement/cast disagrees with its authored identity: " + id)
				break
			# Cloudreach dresses its sign at the configured court edge. Match the
			# same loaded presentation offset without changing its authored source.
			if entry.biome == "cloudreach":
				var visual: Dictionary = world.get("_visual_config")
				var offset: Variant = visual.get("master_signpost_offsets", {}).get(str(definition.get("author_reference", "")))
				if offset is Array and offset.size() >= 2:
					if typeof(offset[0]) not in [TYPE_FLOAT, TYPE_INT] or typeof(offset[1]) not in [TYPE_FLOAT, TYPE_INT] \
							or not is_finite(float(offset[0])) or not is_finite(float(offset[1])):
						failures.append("Invalid loaded Master sign presentation offset: " + id)
						break
					sign_at[0] = float(sign_at[0]) + float(offset[0])
					sign_at[2] = float(sign_at[2]) + float(offset[1])
			var signs: Array[Node3D] = []
			for child: Node in world.get_children():
				var candidate := child as Node3D
				if candidate == null or Vector2(candidate.global_position.x, candidate.global_position.z).distance_to(Vector2(float(sign_at[0]), float(sign_at[2]))) >= 0.05: continue
				var candidate_texts: Array[String] = []
				for part: Node in candidate.get_children():
					var label := part as Label3D
					if label != null: candidate_texts.append(label.text)
				if candidate_texts == [str(definition.sign_text) + "\nFollow the side path →"]: signs.append(candidate)
			if signs.size() != 1:
				failures.append("One actual authored sign required: " + id)
				break
			var sign: Node3D = signs[0]
			var texts: Array[String] = []
			for child: Node in sign.get_children():
				var label := child as Label3D
				if label != null: texts.append(label.text)
			if texts != [str(definition.sign_text) + "\nFollow the side path →"]:
				failures.append("Actual sign text missing/ambiguous: " + id)
				break
			var player_before := player.global_position
			var captures: Array[String] = []
			var clearance: Array[Dictionary] = []
			if capture_ids.has(id):
				player.global_position = sign.global_position + Vector3(0, 1, 5)
				player.velocity = Vector3.ZERO
				camera.global_position = sign.global_position + Vector3(0, 4, 11)
				camera.look_at(sign.global_position + Vector3(0, 2.5, 0), Vector3.UP)
				for frame in POSE_FRAMES: await physics_frame
				await _shoot(id + "_sign", written, failures)
				if measure_clearance:
					# Read the geometry already in this captured scene. No raycast,
					# generated debug mesh, collider or visibility change is needed.
					var geometry: Array[Node] = world.find_children("*", "MeshInstance3D", true, false)
					geometry.append_array(world.find_children("*", "MultiMeshInstance3D", true, false))
					geometry.append_array(world.find_children("*", "CollisionShape3D", true, false))
					for node: Node in geometry:
						var spatial := node as Node3D
						var local_box := AABB()
						var kind := "mesh"
						var transforms: Array[Transform3D] = [spatial.global_transform]
						if node is MeshInstance3D:
							var mesh := node as MeshInstance3D
							if mesh.mesh == null or not mesh.is_visible_in_tree(): continue
							local_box = mesh.get_aabb()
						elif node is MultiMeshInstance3D:
							var mesh := node as MultiMeshInstance3D
							if mesh.multimesh == null or mesh.multimesh.mesh == null or not mesh.is_visible_in_tree(): continue
							if mesh.multimesh.transform_format != MultiMesh.TRANSFORM_3D: continue
							local_box = mesh.multimesh.mesh.get_aabb()
							kind = "multimesh_instance"
							transforms.clear()
							var count := mesh.multimesh.instance_count
							if mesh.multimesh.visible_instance_count >= 0: count = mini(count, mesh.multimesh.visible_instance_count)
							for index in count: transforms.append(spatial.global_transform * mesh.multimesh.get_instance_transform(index))
						else:
							var collider := node as CollisionShape3D
							var shape: Shape3D = collider.shape
							if shape == null or collider.disabled: continue
							kind = shape.get_class()
							var half := Vector3.ZERO
							var points := PackedVector3Array()
							if shape is BoxShape3D: half = (shape as BoxShape3D).size * 0.5
							elif shape is SphereShape3D: half = Vector3.ONE * (shape as SphereShape3D).radius
							elif shape is CapsuleShape3D:
								half = Vector3((shape as CapsuleShape3D).radius, (shape as CapsuleShape3D).height * 0.5, (shape as CapsuleShape3D).radius)
							elif shape is CylinderShape3D:
								half = Vector3((shape as CylinderShape3D).radius, (shape as CylinderShape3D).height * 0.5, (shape as CylinderShape3D).radius)
							elif shape is ConvexPolygonShape3D: points = (shape as ConvexPolygonShape3D).points
							elif shape is ConcavePolygonShape3D: points = (shape as ConcavePolygonShape3D).get_faces()
							else: continue # Unbounded/heightfield shapes are not text occluder bounds.
							if not points.is_empty():
								local_box = AABB(points[0], Vector3.ZERO)
								for point: Vector3 in points: local_box = local_box.expand(point)
							else: local_box = AABB(-half, half * 2.0)
						for index in transforms.size():
							var box: AABB = transforms[index] * local_box
							var nearest := Vector2(clampf(sign.global_position.x, box.position.x, box.end.x),
								clampf(sign.global_position.z, box.position.z, box.end.z))
							var distance := nearest.distance_to(Vector2(sign.global_position.x, sign.global_position.z))
							if distance > 16.0 or box.end.y < sign.global_position.y + 0.5 or box.position.y > sign.global_position.y + 10.0: continue
							clearance.append({"path": str(world.get_path_to(node)), "kind": kind, "instance": index if kind == "multimesh_instance" else -1,
								"position": [box.position.x, box.position.y, box.position.z], "size": [box.size.x, box.size.y, box.size.z],
								"distance_m": distance, "centre_distance_m": box.get_center().distance_to(sign.global_position)})
					clearance.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
						return a.centre_distance_m < b.centre_distance_m if is_equal_approx(a.distance_m, b.distance_m) else a.distance_m < b.distance_m)
					if clearance.size() > 32: clearance.resize(32)
				player.global_position = site.global_position + Vector3(0, 1, 8)
				player.velocity = Vector3.ZERO
				var centre := (site.global_position + sign.global_position) * 0.5
				camera.global_position = centre + Vector3(0, 28, 55)
				camera.look_at(centre + Vector3(0, 1.5, 0), Vector3.UP)
				for frame in POSE_FRAMES: await physics_frame
				await _shoot(id + "_context", written, failures)
				captures = [id + "_sign", id + "_context"]
			observed.append({"id": id, "biome": entry.biome, "cap_level": definition.cap_level, "access": definition.access,
				"site_position": [site.global_position.x, site.global_position.y, site.global_position.z],
				"sign_position": [sign.global_position.x, sign.global_position.y, sign.global_position.z], "text": texts,
				"player_before": [player_before.x, player_before.y, player_before.z], "captures": captures, "nearby_geometry": clearance})
		if not failures.is_empty(): break
		world.queue_free()
		for frame in POSE_FRAMES: await physics_frame
	print("MASTER PLACEMENT OBSERVED ", JSON.stringify(observed))
	game.set("current_realm", original_realm)
	print("Master placement capture: capture-realm selection and trainer/camera pose only; no earned route, access, duel, recipe or reward claim.")
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() and observed.size() == 5 and written.size() == capture_ids.size() * 2 else 1)


func _shoot(name: String, written: Array[String], failures: Array[String]) -> void:
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		failures.append("%s: viewport returned no image" % name)
		return

	var path := "%s/%s.png" % [OUT_DIR, name]
	var error := image.save_png(path)
	if error != OK:
		failures.append("%s: save_png failed (%d)" % [name, error])
		return

	written.append(path)
	print("  %-16s -> %s" % [name, path])
