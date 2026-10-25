extends Node3D

const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const GUARDIAN_CLEAR_FLAG := "stormwood:named:crown_guardian:cleared"
const ENGINE_TRUTH_FLAG := "stormwood:engine_truth_learned"
const FINISH_SHADER := preload("res://shaders/stormwood_heartstone.gdshader")
const FINISH_CONFIG := "res://data/config/stormwood_heartstone_visual.json"
const HERO_PROP := preload("res://scripts/world/meshy_hero_prop.gd")
var world: Node3D
var game: Node
var prompt: Node3D
var _revision := -1
var _finish: Dictionary = {}
var _veins: Array[ShaderMaterial] = []
var _crystal_lit: Array[BaseMaterial3D] = []
var _hero_glow: Array[ShaderMaterial] = []
var _stone_light: OmniLight3D

func mount(owner_world: Node3D) -> void:
	world = owner_world
	game = get_node("/root/Game")
	position = Vector3(700, world.ground_height_at(700, 2712), 2712)
	add_to_group("progression_restore")
	# Read on every shell: the stone's size sets its collider too, so host
	# and clients agree on the body whatever they draw.
	_finish = JSON.parse_string(FileAccess.get_file_as_string(FINISH_CONFIG))
	var hero: Dictionary = _finish.get("hero", {})
	var use_hero := bool(hero.get("enabled", false)) and ResourceLoader.exists(str(hero.get("model", "")))
	# The hero stone is taller; its collider follows it on every shell.
	var height := float(hero.get("height_m", 4.0)) if use_hero else float(_finish.get("height_m", 2.4))
	var solid := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = height * 0.5
	collision.shape = sphere
	collision.position.y = height * 0.5
	solid.add_child(collision)
	add_child(solid)
	_satellites(height, bool(world.get("simulation_only")))
	if not bool(world.get("simulation_only")) and use_hero:
		# GPU F41#0 / r16-r17 judges: no heartstone presence. The Meshy hero
		# (tb/meshy-1024 ae67083ec: standing stone, embedded blue crystal,
		# root plinth) replaces the installed rock; its crystal glows.
		var model := HERO_PROP.load_model(str(hero.model))
		HERO_PROP.fit_height(model, height, float(hero.get("sink_m", 0.1)))
		model.rotation.y = deg_to_rad(float(hero.get("yaw_deg", 0.0)))
		model.name = "HeartstoneHero"
		add_child(model)
		_hero_glow = HERO_PROP.glow(model, Color(str(_finish.get("charge_colour", "#9adecd"))), float(hero.get("glow_energy", 1.2)))
	elif not bool(world.get("simulation_only")):
		var stone := (load("res://assets/environment/stylized_nature/Rock_Medium_3.gltf") as PackedScene).instantiate() as Node3D
		var bounds := BOUNDS.measure(stone)
		var factor := height / maxf(0.1, bounds.size.y)
		stone.scale = Vector3.ONE * factor
		stone.position.y = -bounds.position.y * factor
		add_child(stone)
		if bool(_finish.get("veins", true)):
			_finish_stone(stone)
		_crown_crystal(height)
		var light := OmniLight3D.new()
		_stone_light = light
		light.position.y = 2
		light.light_color = Color(str(_finish.get("charge_colour", "#9adecd")))
		light.omni_range = float(_finish.get("light_range_m", 14.0))
		light.light_energy = float(_finish.get("light_energy", 1.5))
		add_child(light)
		prompt = INTERACTABLE.new()
		prompt.name = "HeartstoneInteractable"
		prompt.position = Vector3(0, 0.8, -(height * 0.5 + 0.8))
		add_child(prompt)
		prompt.activated.connect(_touch)
	restore_progression_from_game(game)


## GPU F41#0 (Crown heartstone, 25 Oct: "frame the stone and give it
## presence"): a broken ring of lesser stones around the heartstone, the
## same installed rock family, each a small solid body. Layout is config
## (`satellites`), identical on every shell.
func _satellites(height: float, simulation_only: bool) -> void:
	var cfg: Dictionary = _finish.get("satellites", {})
	if not bool(cfg.get("enabled", false)):
		return
	var count := int(cfg.get("count", 7))
	var ring := float(cfg.get("ring_m", height + 2.0))
	var models: Array = cfg.get("models", ["Rock_Medium_1", "Rock_Medium_2"])
	var heights: Array = cfg.get("heights_m", [1.2])
	var skip := int(cfg.get("gap_index", -1))
	for index in count:
		if index == skip:
			continue
		var angle := TAU * (float(index) + 0.31 * sin(float(index) * 2.3)) / float(count)
		var at := Vector3(sin(angle), 0.0, cos(angle)) * ring * (0.92 + 0.08 * cos(float(index) * 1.7))
		var ground := float(world.ground_height_at(position.x + at.x, position.z + at.z)) - position.y
		var h := float(heights[index % heights.size()])
		var body := StaticBody3D.new()
		body.name = "HeartstoneRing%d" % index
		body.position = Vector3(at.x, ground, at.z)
		var shape := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = h * 0.45
		shape.shape = sphere
		shape.position.y = h * 0.45
		body.add_child(shape)
		add_child(body)
		if simulation_only:
			continue
		var rock := (load("res://assets/environment/stylized_nature/%s.gltf" % str(models[index % models.size()])) as PackedScene).instantiate() as Node3D
		var bounds := BOUNDS.measure(rock)
		var factor := h / maxf(0.1, bounds.size.y)
		rock.scale = Vector3.ONE * factor
		rock.position.y = -bounds.position.y * factor - 0.08
		rock.rotation = Vector3(0.08 * sin(float(index) * 3.1), angle + 0.6 * float(index), 0.06 * cos(float(index) * 2.2))
		body.add_child(rock)
		if bool(cfg.get("veins", true)):
			_finish_stone(rock)


## r17 (Crown heartstone, 25 Oct): code-blind judges could not find the
## stone and read its veins as wireframe. The installed glass-scar crystal
## cluster crowns it instead, glowing in the stone's own charge colour, so the
## landmark reads at survey distance. Presentation only (no collider change).
func _crown_crystal(height: float) -> void:
	var cfg: Dictionary = _finish.get("crown_crystal", {})
	if not bool(cfg.get("enabled", false)):
		return
	var scene := load(str(cfg.get("model", ""))) as PackedScene
	if scene == null:
		return
	var crystal := scene.instantiate() as Node3D
	crystal.name = "HeartCrystal"
	var bounds := BOUNDS.measure(crystal)
	var factor := float(cfg.get("height_m", 1.8)) / maxf(0.1, bounds.size.y)
	crystal.scale = Vector3.ONE * factor
	crystal.position = Vector3(0.0, height * float(cfg.get("seat", 0.82)) - bounds.position.y * factor, 0.0)
	add_child(crystal)
	var glow := Color(str(_finish.get("charge_colour", "#9adecd")))
	for visual: MeshInstance3D in crystal.find_children("*", "MeshInstance3D", true, false):
		for surface in visual.mesh.get_surface_count():
			var source := visual.get_active_material(surface) as BaseMaterial3D
			if source == null:
				continue
			var lit := source.duplicate() as BaseMaterial3D
			lit.emission_enabled = true
			lit.emission = glow
			lit.emission_energy_multiplier = float(cfg.get("emission_energy", 1.2))
			visual.set_surface_override_material(surface, lit)
			_crystal_lit.append(lit)


func _finish_stone(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		if mesh.mesh != null:
			for surface in mesh.mesh.get_surface_count():
				var source := mesh.get_active_material(surface) as BaseMaterial3D
				if source == null:
					continue
				var material := source.duplicate() as BaseMaterial3D
				var veins := ShaderMaterial.new()
				veins.shader = FINISH_SHADER
				var bounds := mesh.mesh.get_aabb()
				veins.set_shader_parameter("bound_min", bounds.position)
				veins.set_shader_parameter("bound_size", bounds.size)
				for key: String in ["vein_scale", "vein_width", "pulse_depth", "pulse_speed"]:
					veins.set_shader_parameter(key, float(_finish[key]))
				material.next_pass = veins
				mesh.set_surface_override_material(surface, material)
				_veins.append(veins)
	for child in node.get_children():
		_finish_stone(child)

func _process(_delta: float) -> void:
	if game != null and int(game.get("progression").get("revision")) != _revision:
		restore_progression_from_game(game)

func restore_progression_from_game(_game: Node) -> void:
	var flags: RefCounted = game.get("progression")
	_revision = int(flags.get("revision"))
	var released := bool(flags.has("stormwood:rootgate_released"))
	var tint := Color(str(_finish.get("released_colour" if released else "charge_colour", "#9adecd")))
	for veins: ShaderMaterial in _veins:
		veins.set_shader_parameter("charge_colour", tint)
		veins.set_shader_parameter("charge_energy", float(_finish.get("released_energy" if released else "charge_energy", 1.1)))
	var crystal_energy := float((_finish.get("crown_crystal", {}) as Dictionary).get("emission_energy", 1.2))
	var hero_energy := float((_finish.get("hero", {}) as Dictionary).get("glow_energy", 1.2))
	for glow: ShaderMaterial in _hero_glow:
		glow.set_shader_parameter("glow_colour", tint)
		glow.set_shader_parameter("glow_energy", hero_energy * (0.2 if released else 1.0))
	for lit: BaseMaterial3D in _crystal_lit:
		lit.emission = tint
		lit.emission_energy_multiplier = crystal_energy * (0.2 if released else 1.0)
	if is_instance_valid(_stone_light):
		_stone_light.light_color = tint
		_stone_light.light_energy = float(_finish.get("released_light_energy" if released else "light_energy", 1.5))
	if prompt != null:
		var opened := bool(flags.has("stormwood:rootgate_released"))
		var guardian_clear := bool(flags.has(GUARDIAN_CLEAR_FLAG))
		var truth_learned := bool(flags.has(ENGINE_TRUTH_FLAG))
		var ready := guardian_clear and truth_learned and not opened
		var label := "Touch the Crown heartstone"
		if opened:
			label = "The Rootgate is open"
		elif not guardian_clear:
			label = "The Crown guardian bars the heartstone"
		elif not truth_learned:
			label = "Hear what Wen learned from the Crown"
		prompt.configure(label, 3.2, not opened)
		prompt.set("actionable", ready)

func _touch() -> void:
	if not game.get("progression").has(GUARDIAN_CLEAR_FLAG):
		game.push_world_message("The Crown guardian still bars the heartstone.")
		return
	if not game.get("progression").has(ENGINE_TRUTH_FLAG):
		game.push_world_message("Wen can read what the heartstone remembers. Hear the truth first.")
		return
	world.get_node("StormwoodChapter").emit_event("heartstone:rootgate")
	restore_progression_from_game(game)
