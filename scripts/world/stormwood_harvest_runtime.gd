extends Node3D

## Mount-only adapter for Stormwood's authored harvest catalogue. It reuses the
## permanent, ledger-backed HarvestNode path; this file does not add a local
## phase check or alter host authority.

const HARVEST_NODE := preload("res://scripts/world/harvest_node.gd")
const ARCH_BUILD := preload("res://scripts/world/stormwood_arch_build_rules.gd")
const RENEWABLE_SITES := preload("res://scripts/world/renewable_site_catalog.gd")

const DATA_PATH := "res://data/config/stormwood_harvests.json"
const REALM_ID := "stormwood"

var world: Node3D
var _game: Node
var _flags: RefCounted
var _placements: Dictionary = {}
var _revision := -1
var _event_check_left := 0.0
var _catalogue: Dictionary = {}
var _crown_glass_required := -1


static func read(path: String = DATA_PATH) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## Shared catalogue identity reaches the host's phase and first-claim rules.
static func authority_contract() -> Dictionary:
	return {
		"intent_kind": "stormwood_harvest",
		"harvest_override": "res://scripts/world/harvest_node.gd::_on_gathered",
		"ledger_override": "res://scripts/net/world_ledger.gd::_stormwood_harvest",
	}


## F32 host registration data only. Charged/crown availability and region
## prerequisites remain host validators; neither is accepted from a client.
static func renewable_site(spec: Dictionary, _catalogue: Dictionary) -> Dictionary:
	return RENEWABLE_SITES.by_id(REALM_ID, str(spec.get("id", "")))


func mount(owner_world: Node3D) -> void:
	world = owner_world
	_catalogue = read()
	_game = get_node_or_null(^"/root/Game")
	_flags = _game.get("progression") if _game != null else null
	add_to_group("progression_restore")
	sync_progression()


func _process(delta: float) -> void:
	if _flags != null and int(_flags.get("revision")) != _revision:
		_revision = int(_flags.get("revision"))
		sync_progression()
	_event_check_left -= delta
	if _flags != null and _event_check_left <= 0.0:
		_event_check_left = 0.5
		if not bool(world.get("simulation_only")) and not _flags.has("stormwood:first_stormglass_gathered"):
			for spec: Dictionary in _catalogue.get("sites", []):
				if str(spec.region_id) == "cinder_verge" and str(spec.item) == "stormglass" and _flags.has("harvest_node:order:" + str(spec.id)):
					world.get_node("StormwoodChapter").emit_event("harvest:verge_stormglass")
					break
		# Crown Stormglass can be claimed before its chapter recipe prerequisite.
		# Reconcile the durable host-ledger claim independently so learning the
		# recipe later cannot leave the ordinary story route dead-ended.
		if not bool(world.get("simulation_only")) \
				and _flags.has("stormwood:arch_recipe_known") \
				and not _flags.has("stormwood:crown_glass_gathered"):
			if _crown_glass_required < 0:
				_crown_glass_required = crown_glass_cost()
			if _crown_glass_required > 0 and claimed_crown_glass(_catalogue, _flags) >= _crown_glass_required:
				world.get_node("StormwoodChapter").emit_event("harvest:crown_grade")


static func crown_glass_cost() -> int:
	for footing: Dictionary in ARCH_BUILD.ARCHES.config().get("footings", []):
		if str(footing.get("fixed_twin", "")) != "e_crown":
			continue
		var at: Array = footing.at
		var total := 0
		for need: Dictionary in ARCH_BUILD.cost(Vector3(float(at[0]), 0.0, float(at[1]))):
			if str(need.id) == "stormglass_crown":
				total += int(need.n)
		return total
	return 0


## This world objective records shared gathering, not one player's current
## inventory. The ledger still grants each yield only to its claiming peer;
## the builder must hold and pay the complete production cost separately.
static func claimed_crown_glass(catalogue: Dictionary, flags: RefCounted) -> int:
	var total := 0
	var seen := {}
	for spec: Dictionary in catalogue.get("sites", []):
		var id := str(spec.get("id", ""))
		if id.is_empty() or seen.has(id) or str(spec.get("grade", "")) != "crown" \
				or str(spec.get("item", "")) != "stormglass_crown" \
				or not flags.has("harvest_node:order:" + id):
			continue
		seen[id] = true
		total += maxi(0, int(spec.get("amount", 0)))
	return total


func restore_progression_from_game(game: Node) -> void:
	_game = game
	_flags = game.get("progression") if game != null else null
	# HarvestNode restores its own flag. Keep pending winners alive until their
	# delta callback settles tool wear and feedback.
	sync_progression()


func sync_progression() -> void:
	if world == null or _game == null or _flags == null:
		return
	_revision = int(_flags.get("revision"))
	var items: RefCounted = _game.get("items")
	for raw: Variant in (_catalogue.get("sites", []) as Array):
		if not (raw is Dictionary):
			continue
		var spec := raw as Dictionary
		var id := str(spec.get("id", ""))
		var item := str(spec.get("item", ""))
		if _placements.has(id) and not is_instance_valid(_placements[id]) and not _flags.has("harvest_node:order:" + id):
			_placements.erase(id)
		if id.is_empty() or item.is_empty() or _placements.has(id):
			continue
		if items == null or not bool(items.call("has", item)):
			continue # The item payload has not been integrated yet.
		var prerequisite := str((_catalogue.get("region_prerequisites", {}) as Dictionary).get(str(spec.get("region_id", "")), ""))
		if not prerequisite.is_empty() and not bool(_flags.call("has", prerequisite)):
			continue
		_mount_site(spec)


func _mount_site(spec: Dictionary) -> void:
	var point: Array = spec.get("position", []) as Array
	if point.size() != 2:
		return
	var x := float(point[0])
	var z := float(point[1])
	var node := HARVEST_NODE.new()
	node.name = str(spec.get("id", "StormwoodHarvest"))
	add_child(node)
	node.global_position = Vector3(x, _ground_height(x, z), z)
	node.set_meta("stormwood_harvest_intent", str(spec.get("intent_kind", "")))
	node.set_meta("stormwood_harvest_site", str(spec.id))
	node.set_meta("stormwood_region", str(spec.region_id))
	node.set_meta("stormwood_item", str(spec.item))
	node.setup({
		"item": str(spec.get("item", "")),
		"amount": int(spec.get("amount", 1)),
		"label": "Gather " + str(spec.get("item", "resource")).capitalize(),
		"model": str(spec.get("model", "")),
		"model_scale": float(spec.get("model_scale", 1.0)),
		"order": str(spec.get("id", "")),
		"realm": REALM_ID,
	})
	add_material_cue(node, str(spec.get("item", "")), _catalogue.get("material_cues", {}), _ground_height)
	_placements[str(spec.get("id", ""))] = node


func _ground_height(x: float, z: float) -> float:
	if world != null and world.has_method("ground_height_at"):
		return float(world.call("ground_height_at", x, z))
	return 0.0


## P2-046: a visual-only cue so a node reads as its named material (a plain
## rock read as stone, not Stormglass). A child of the node, so it hides with
## it once harvested. No collider, stock, reward or placement change.
static func add_material_cue(node: Node3D, item: String, cues: Dictionary,
		ground_height: Callable = Callable()) -> Node3D:
	var cue: Variant = cues.get(item, null)
	if not cue is Dictionary or node.get_node_or_null(^"MaterialCue") != null:
		return null
	var spec := cue as Dictionary
	var root := Node3D.new()
	root.name = "MaterialCue"
	node.add_child(root)
	var glow := StandardMaterial3D.new()
	var colour := Color(str(spec.get("colour", "#ffffff")))
	# A darker body under a softer glow keeps the hue: albedo and emission both
	# at full colour tonemapped the Stormglass shards to flat white on Low.
	glow.albedo_color = colour.darkened(clampf(float(spec.get("albedo_shade", 0.0)), 0.0, 1.0))
	glow.emission_enabled = true
	glow.emission = colour
	glow.emission_energy_multiplier = float(spec.get("emission", 1.0))
	glow.roughness = 0.2
	var lift := float(spec.get("lift_m", 0.0))
	var radius := float(spec.get("radius_m", 0.4))
	match str(spec.get("kind", "")):
		"shards":
			var count := maxi(1, int(spec.get("count", 4)))
			var height := float(spec.get("height_m", 0.8))
			for index in count:
				var shard := MeshInstance3D.new()
				shard.name = "Shard%d" % index
				# Deterministic per-index variation; every peer builds the same cue.
				var factor := 0.65 + 0.35 * float((index * 7) % 5) / 4.0
				var width := float(spec.get("width_m", radius * 0.32))
				shard.mesh = _crystal_mesh(width, height * factor)
				shard.material_override = glow
				var angle := TAU * float(index) / float(count)
				# A ring around the model's base: placed near the centre, shards
				# sat inside the Stormglass rock and never showed.
				var ring := float(spec.get("ring_m", radius * 0.45))
				var at := Vector3(cos(angle) * ring, lift - .06, sin(angle) * ring)
				if ground_height.is_valid():
					var world_at := node.to_global(at)
					at.y = node.to_local(Vector3(world_at.x, float(ground_height.call(world_at.x, world_at.z)), world_at.z)).y + lift - .06
				shard.position = at
				shard.rotation = Vector3(sin(angle) * 0.35, angle, cos(angle) * 0.35)
				shard.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				root.add_child(shard)
		"glow_cap":
			var cap := MeshInstance3D.new()
			cap.name = "GlowCap"
			var dome := SphereMesh.new()
			dome.radius = radius
			dome.height = radius
			dome.is_hemisphere = true
			cap.mesh = dome
			glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			glow.albedo_color.a = 0.55
			cap.material_override = glow
			cap.position = Vector3(0.0, lift, 0.0)
			cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(cap)
		"moss":
			# Low overlapping cushions read as ground growth, not mushrooms.
			for index in 9:
				var pad := MeshInstance3D.new()
				var dome := SphereMesh.new()
				dome.radius = radius * (0.6 + 0.08 * (index % 4))
				dome.height = dome.radius * 0.42
				pad.mesh = dome
				pad.material_override = glow
				var angle := TAU * float(index) / 9.0
				pad.position = Vector3(cos(angle) * radius, lift, sin(angle) * radius)
				root.add_child(pad)
		"veins":
			# Broken copper/blue seams follow the node's trunk or vine body.
			var height := float(spec.get("height_m", 2.0))
			for strand in 3:
				for step in 12:
					var t := float(step) / 12.0
					var next_t := float(step + 1) / 12.0
					var angle := TAU * (float(strand) / 3.0 + t * 0.55)
					var next_angle := TAU * (float(strand) / 3.0 + next_t * 0.55)
					var a := Vector3(cos(angle) * radius, lift + t * height, sin(angle) * radius)
					var b := Vector3(cos(next_angle) * radius, lift + next_t * height, sin(next_angle) * radius)
					var seam := MeshInstance3D.new()
					var tube := CylinderMesh.new()
					tube.top_radius = float(spec.get("width_m", 0.035))
					tube.bottom_radius = tube.top_radius
					tube.height = a.distance_to(b)
					tube.radial_segments = 5
					seam.mesh = tube
					seam.material_override = glow
					seam.position = (a + b) * 0.5
					seam.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
					root.add_child(seam)
	# Keep new cues on the same visibility lifecycle as the harvest model.
	# In particular, hiding a bush in a fight must also hide its copper seams.
	if item in ["glowmoss", "conductor_vine", "thunderwood", "stormglass", "stormglass_crown"]:
		var visual := node.get("_visual") as Node3D
		if visual != null:
			if bool(spec.get("replace_model", false)):
				visual.queue_free()
				node.set("_visual", root)
			else:
				node.remove_child(root)
				visual.add_child(root)
				root.transform = visual.transform.affine_inverse()
	return root


## An offset broken tip and six flat side faces distinguish fused crystals
## from both the base rock and the former roof-shaped primitive.
static func _crystal_mesh(width: float, height: float) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in 6:
		var angle := TAU * float(index) / 6.0
		var next_angle := TAU * float(index + 1) / 6.0
		var a := Vector3(cos(angle) * width, 0, sin(angle) * width)
		var b := Vector3(cos(next_angle) * width, 0, sin(next_angle) * width)
		var c := b * .66 + Vector3.UP * height * .77
		var d := a * .66 + Vector3.UP * height * .77
		var tip := Vector3(width * .18, height, -width * .12)
		for point: Vector3 in [a, b, c, a, c, d, d, c, tip]:
			surface.add_vertex(point)
	surface.generate_normals()
	return surface.commit()
