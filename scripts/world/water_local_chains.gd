extends Node3D
## F13 Tidewake local chains, scene side. Holds no chain state: every step is
## a `water_dock_action` intent the host arbitrates with
## `water_local_chain_rules.gd`, and completion is read back from the committed
## world delta. Speech steps arrive from WaterChapter's guarded conversations.
## The step's message is shown only to the peer who asked for it; a refusal is
## already spoken by LedgerClaim (host/solo) or the ledger's verdict (client).
const RULES := preload("res://scripts/world/water_local_chain_rules.gd")
const CLAIM := preload("res://scripts/world/ledger_claim.gd")
const INTERACT := preload("res://scripts/world/interactable.gd")
const NPCS := preload("res://scripts/world/water_scene_npcs.gd")
const INTENT := "water_dock_action"
var _world: Node3D
var _game: Node
## step id -> the world flag its commit writes, while this peer awaits it.
var _pending: Dictionary = {}
## step id -> {"row", "root", "prompt"} for site steps.
var _sites: Dictionary = {}
var _last_revision := -1
const REST_POLL_S := 0.5
var _rest_poll_left := 0.0


func build(world: Node3D) -> void:
	_world = world
	_game = get_node_or_null("/root/Game")
	CLAIM.listen(self, _on_delta)
	var ledger: Node = CLAIM.transport(self)
	if ledger != null and not ledger.intent_refused.is_connected(_on_refused):
		ledger.intent_refused.connect(_on_refused)
	var data := RULES.load_data()
	for lamp: Variant in data.get("landmark_lamps", []):
		if lamp is Dictionary:
			_build_landmark_lamp(lamp)
	for row: Variant in data.get("steps", []):
		if row is Dictionary and str(row.get("kind", "")) == "site":
			_build_site(row, float(data.get("site_prompt_radius_m", 3.6)))
	_refresh()


## A site is open while its prerequisites hold and its record is not yet set.
## World flags are host truth on the host and the delta-fed mirror on a client.
static func site_offered(row: Dictionary, world_flags: Variant) -> bool:
	return world_flags != null and RULES.prerequisites_met(row, world_flags) \
		and not world_flags.has(str(row.get("flag", "")))


func site_root(step_id: String) -> Node3D:
	var site: Variant = _sites.get(step_id)
	return (site as Dictionary).root if site is Dictionary else null


## The landmark's authored position (water_world.json `landmarks`), or INF.
func landmark_xz(landmark_id: String) -> Vector2:
	var config: Variant = _world.get("config") if _world != null else null
	if config is Dictionary:
		for raw: Variant in (config as Dictionary).get("landmarks", []):
			if raw is Dictionary and str(raw.get("id", "")) == landmark_id:
				var at: Array = raw.position
				return Vector2(float(at[0]), float(at[2]))
	return Vector2.INF


func landmark_root(landmark_id: String) -> Node3D:
	return get_node_or_null("Landmark_" + landmark_id) as Node3D


## A named lamp-post landmark a chain's lead points at (Lastlight). Always
## standing: the lamp is the lure, not a chain step. The post collides on every
## peer; the post, lantern, flame and light are art only.
func _build_landmark_lamp(lamp: Dictionary) -> void:
	var landmark_id := str(lamp.get("landmark_id", ""))
	var xz := landmark_xz(landmark_id)
	var ground := float(_world.ground_height_at(xz.x, xz.y)) if xz.is_finite() else NAN
	if not is_finite(ground) or ground < 0.0:
		push_error("Water landmark lamp has no dry terrain: " + landmark_id)
		return
	var width := float(lamp.get("post_width_m", 0.36))
	var height := float(lamp.get("post_height_m", 4.0))
	var root := StaticBody3D.new()
	root.name = "Landmark_" + landmark_id
	add_child(root)
	root.position = Vector3(xz.x, ground, xz.y)
	var facing_raw: Array = lamp.get("facing_xz", [0.0, 1.0])
	root.rotation.y = atan2(float(facing_raw[0]), float(facing_raw[1]))
	var collision := CollisionShape3D.new()
	collision.name = "PostCollider"
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, height + 0.4, width)
	collision.shape = shape
	collision.position.y = (height - 0.4) * 0.5
	root.add_child(collision)
	if _world.simulation_only:
		return
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(str(lamp.get("post_colour", "#927448")))
	wood.albedo_texture = load("res://assets/environment/stylized_nature/Bark_TwistedTree.png")
	wood.uv1_scale = Vector3(0.35, 0.35, 1)
	wood.roughness = 0.88
	var post := MeshInstance3D.new()
	post.name = "LampPost"
	var box := BoxMesh.new()
	# 0.4 m of footing below the sampled ground covers the downhill side.
	box.size = Vector3(width, height + 0.4, width)
	post.mesh = box
	post.material_override = wood
	post.position.y = (height - 0.4) * 0.5
	root.add_child(post)
	var lantern_scale := float(lamp.get("lantern_scale", 1.4))
	var scene: Variant = load(str(lamp.get("lantern_model", ""))) \
		if ResourceLoader.exists(str(lamp.get("lantern_model", ""))) else null
	if not scene is PackedScene:
		push_error("Water landmark lamp model missing: " + str(lamp.get("lantern_model", "")))
		return
	var lantern := (scene as PackedScene).instantiate() as Node3D
	lantern.name = "Lantern"
	lantern.scale = Vector3.ONE * lantern_scale
	lantern.position = Vector3(0.0, float(lamp.get("lantern_mount_height_m", 2.0)), width * 0.5)
	root.add_child(lantern)
	# The installed lantern's cage centre sits at (0, 0.85, 0.73) in its own units.
	var cage := lantern.position + Vector3(0.0, 0.85, 0.73) * lantern_scale
	var flame := StandardMaterial3D.new()
	flame.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame.albedo_color = Color(str(lamp.get("flame_emission", "#ffb347")))
	flame.emission_enabled = true
	flame.emission = flame.albedo_color
	flame.emission_energy_multiplier = float(lamp.get("flame_emission_energy", 4.0))
	var bulb := MeshInstance3D.new()
	bulb.name = "AmberFlame"
	var sphere := SphereMesh.new()
	sphere.radius = float(lamp.get("flame_radius_m", 0.24))
	sphere.height = sphere.radius * 2.0
	bulb.mesh = sphere
	bulb.material_override = flame
	bulb.position = cage
	root.add_child(bulb)
	var light := OmniLight3D.new()
	light.name = "WarmLight"
	light.light_color = Color(str(lamp.get("light_colour", "#ffb15c")))
	light.light_energy = float(lamp.get("light_energy", 1.6))
	light.omni_range = float(lamp.get("light_range_m", 12.0))
	light.shadow_enabled = false
	light.position = cage
	root.add_child(light)


func _build_site(row: Dictionary, prompt_radius: float) -> void:
	var xz := RULES.step_xz(row)
	var ground := float(_world.ground_height_at(xz.x, xz.y)) if xz.is_finite() else NAN
	if not is_finite(ground) or ground < 0.0:
		push_error("Water local-chain site has no dry terrain: " + str(row.get("id", "")))
		return
	var root := Node3D.new()
	root.name = str(row.id)
	add_child(root)
	root.position = Vector3(xz.x, ground, xz.y)
	var scene: Variant = load(str(row.get("model", ""))) if ResourceLoader.exists(str(row.get("model", ""))) else null
	if scene is PackedScene:
		var visual := (scene as PackedScene).instantiate() as Node3D
		visual.name = "Visual"
		visual.scale = Vector3.ONE * float(row.get("model_scale", 1.0))
		visual.rotation.y = deg_to_rad(float(row.get("yaw_deg", 0.0)))
		visual.position.y = float(row.get("model_offset_y", 0.0))
		root.add_child(visual)
	else:
		push_error("Water local-chain site model missing: " + str(row.get("model", "")))
	var done_scene: Variant = load(str(row.get("done_model", ""))) if ResourceLoader.exists(str(row.get("done_model", ""))) else null
	if done_scene is PackedScene:
		# What the finished step leaves standing (the Lastlight bed shelter).
		var built := (done_scene as PackedScene).instantiate() as Node3D
		built.name = "Built"
		var offset: Array = row.get("done_model_offset_xz", [0.0, 0.0])
		var spot := Vector2(xz.x + float(offset[0]), xz.y + float(offset[1]))
		built.position = Vector3(float(offset[0]), float(_world.ground_height_at(spot.x, spot.y)) - ground \
			+ float(row.get("done_model_offset_y", 0.0)), float(offset[1]))
		built.scale = Vector3.ONE * float(row.get("done_model_scale", 1.0))
		built.rotation.y = deg_to_rad(float(row.get("done_yaw_deg", 0.0)))
		root.add_child(built)
	var prompt := INTERACT.new()
	prompt.name = "Prompt"
	root.add_child(prompt)
	prompt.position.y = 0.8
	prompt.configure(str(row.get("label", "Inspect")), prompt_radius, false)
	prompt.activated.connect(func() -> void: request_step(str(row.id)))
	_sites[str(row.id)] = {"row": row, "root": root, "prompt": prompt}


func _process(delta: float) -> void:
	if _game == null or _game.get("world") == null:
		return
	if int(_game.world.flags.revision) != _last_revision:
		_refresh()
	_rest_poll_left -= delta
	if _rest_poll_left <= 0.0:
		_rest_poll_left = REST_POLL_S
		_watch_rests()


## A rest step is wanted once its prerequisites hold, it is unrecorded, and one
## of this peer's companions is resting in the step's camp bed.
static func rest_wanted(row: Dictionary, world_flags: Variant, resting_beds: Array) -> bool:
	return str(row.get("kind", "")) == "rest" and site_offered(row, world_flags) \
		and resting_beds.has(int(row.get("bed_index", 0)))


## Bed indices this peer's own resting companions occupy (beds are local
## state; see creature_bed.gd occupant_index()).
func _resting_beds() -> Array:
	var out: Array = []
	var party: Variant = _game.get("party") if _game != null else null
	if party == null:
		return out
	for creature: Variant in party.call("members"):
		if creature != null and bool((creature as Object).get("resting")):
			out.append(int((creature as Object).get("rest_bed_index")))
	return out


func _watch_rests() -> void:
	if _world == null or _world.simulation_only or str(_game.get("current_realm")) != "water":
		return
	var rig := _world.call("local_rig") as Node3D
	var beds := _resting_beds()
	for row: Variant in RULES.load_data().get("steps", []):
		if not row is Dictionary or _pending.has(str(row.get("id", ""))) \
				or not rest_wanted(row, _game.world.flags, beds):
			continue
		# Only from beside the bed, so the host never has to refuse a far request.
		var at := RULES.step_xz(row)
		if rig != null and Vector2(rig.global_position.x, rig.global_position.z).distance_to(at) <= RULES.reach_m(row):
			request_step(str(row.id))


func _refresh() -> void:
	var flags: Variant = _game.world.flags if _game != null and _game.get("world") != null else null
	_last_revision = int(flags.revision) if flags != null else -1
	for id: String in _sites:
		var site: Dictionary = _sites[id]
		var row: Dictionary = site.row
		var open := site_offered(row, flags)
		var done: bool = flags != null and flags.has(str(row.get("flag", "")))
		site.prompt.enabled = open and not _world.simulation_only
		# `always_visible`: the place itself is the lure (a vault wall seen from
		# afar); only its prompt waits for the lead.
		site.root.visible = not _world.simulation_only and (bool(row.get("always_visible", false)) \
			or open or (done and not bool(row.get("hide_when_done", false))))
		var visual: Node3D = site.root.get_node_or_null("Visual")
		var built: Node3D = site.root.get_node_or_null("Built")
		if built != null:
			# A delivery site shows its marker while open and what it built after.
			built.visible = done
			if visual != null:
				visual.visible = not done


## Ask the host to record one chain step for this peer's character. Returns
## the ledger verdict ({} when nothing was sent).
func request_step(step_id: String) -> Dictionary:
	if _world == null or _world.simulation_only or _pending.has(step_id) or not RULES.has_step(step_id):
		return {}
	var row := RULES.step(step_id)
	# A grant lands in this peer's satchel; check room first, as pickups do.
	var grant: Variant = row.get("grant", {})
	if grant is Dictionary and _game != null:
		for item: String in grant:
			if not bool(_game.inventory.has_room_for(item, int(grant[item]))):
				_game.push_world_message("Satchel is full.")
				return {}
	# Inventory proof for a delivery: this peer's own counts of the cost items.
	var counts: Dictionary = {}
	var cost: Variant = row.get("cost", {})
	if cost is Dictionary and _game != null:
		for item: String in cost:
			counts[item] = int(_game.inventory.count(item))
	_pending[step_id] = str(row.get("flag", ""))
	var intent := {"kind": INTENT, "realm": "water", "action_id": step_id, "inventory": counts,
		"party_species": NPCS.party_species(_game)}
	if str(row.get("kind", "")) == "rest":
		intent["resting_bed_index"] = int(row.get("bed_index", 0))
	var verdict := CLAIM.submit(self, intent)
	if not CLAIM.in_flight(verdict):
		_pending.erase(step_id)
	return verdict


func pending_steps() -> Array:
	return _pending.keys()


func _on_delta(delta: Dictionary) -> void:
	# Prompts follow the committed record at once, not on the next idle frame.
	_refresh()
	for step_id: String in _pending.keys():
		if CLAIM.sets_world_flag(delta, str(_pending[step_id])):
			_pending.erase(step_id)
			var message := str(RULES.step(step_id).get("message", ""))
			if _game != null and not message.is_empty():
				_game.push_world_message(message)


func _on_refused(kind: String, _code: String, _reason: String, _detail: Dictionary) -> void:
	if kind == INTENT:
		_pending.clear()
