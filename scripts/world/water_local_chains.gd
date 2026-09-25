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


func build(world: Node3D) -> void:
	_world = world
	_game = get_node_or_null("/root/Game")
	CLAIM.listen(self, _on_delta)
	var ledger: Node = CLAIM.transport(self)
	if ledger != null and not ledger.intent_refused.is_connected(_on_refused):
		ledger.intent_refused.connect(_on_refused)
	var data := RULES.load_data()
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
		root.add_child(visual)
	else:
		push_error("Water local-chain site model missing: " + str(row.get("model", "")))
	var prompt := INTERACT.new()
	prompt.name = "Prompt"
	root.add_child(prompt)
	prompt.position.y = 0.8
	prompt.configure(str(row.get("label", "Inspect")), prompt_radius, false)
	prompt.activated.connect(func() -> void: request_step(str(row.id)))
	_sites[str(row.id)] = {"row": row, "root": root, "prompt": prompt}


func _process(_delta: float) -> void:
	if _game == null or _game.get("world") == null:
		return
	if int(_game.world.flags.revision) != _last_revision:
		_refresh()


func _refresh() -> void:
	var flags: Variant = _game.world.flags if _game != null and _game.get("world") != null else null
	_last_revision = int(flags.revision) if flags != null else -1
	for id: String in _sites:
		var site: Dictionary = _sites[id]
		var row: Dictionary = site.row
		var open := site_offered(row, flags)
		var done: bool = flags != null and flags.has(str(row.get("flag", "")))
		site.prompt.enabled = open and not _world.simulation_only
		site.root.visible = not _world.simulation_only \
			and (open or (done and not bool(row.get("hide_when_done", false))))


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
	_pending[step_id] = str(row.get("flag", ""))
	var verdict := CLAIM.submit(self, {"kind": INTENT, "realm": "water", "action_id": step_id, "inventory": {},
		"party_species": NPCS.party_species(_game)})
	if not CLAIM.in_flight(verdict):
		_pending.erase(step_id)
	return verdict


func pending_steps() -> Array:
	return _pending.keys()


func _on_delta(delta: Dictionary) -> void:
	for step_id: String in _pending.keys():
		if CLAIM.sets_world_flag(delta, str(_pending[step_id])):
			_pending.erase(step_id)
			var message := str(RULES.step(step_id).get("message", ""))
			if _game != null and not message.is_empty():
				_game.push_world_message(message)


func _on_refused(kind: String, _code: String, _reason: String, _detail: Dictionary) -> void:
	if kind == INTENT:
		_pending.clear()
