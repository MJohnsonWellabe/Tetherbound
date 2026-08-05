extends Node

## Build Mode: a STATE, not a scene.
##
## Same shape as `combat_manager.gd`, and its header says why better than a new
## comment would: the world keeps rendering, the trainer stays standing where
## they opened it, nothing is unloaded and nothing is instanced from a separate
## scene. Entering build mode suspends locomotion and shows a ghost. That is all
## it is.
##
## This is the single place that knows building is happening. The HUD is told and
## does not ask; `structures.gd` is told what to place and does not decide.
##
## ONE WAY IN AND ONE WAY OUT, for the reason `encounter_director` gives about
## fights: "One place, so a new way of entering a fight cannot forget half of
## it." A second route that forgot to suspend locomotion would leave the player
## walking around with a ghost stuck to their face.

const GRID := preload("res://scripts/building/build_grid.gd")
const DEFS := preload("res://scripts/items/item_defs.gd")
const CONFIG_PATH := "res://data/config/building.json"

## Where the trainer's inventory is expected to be, when the scene names one.
##
## The trainer's inventory belongs to another system entirely. This file reaches
## it through a duck-typed surface — `count_of`, `add`, `remove`, `last_refusal`
## — the way the UI reaches its systems, and never builds one of its own. A
## second inventory would be a second opinion about what the player is carrying,
## and the first thing that would disagree about is whether they can afford a
## wall.
const INVENTORY_NODE := "TrainerInventory"

signal opened()
signal closed()
signal selection_changed(piece_id: String)
signal placed(piece_id: String)
signal refused(reason: String)

@export var player_path: NodePath
@export var world_path: NodePath
@export var structures_path: NodePath
@export var combat_path: NodePath

var _player: CharacterBody3D = null
var _world: Node = null
var _structures: Node3D = null
var _combat: Node = null

var _open: bool = false
var _ghost: Node3D = null
var _ghost_material: StandardMaterial3D = null
var _selected: int = 0
var _ids: Array[String] = []
var _yaw: float = 0.0
var _valid: bool = false
var _refusal: String = ""

var _reach: float = 9.0
var _reach_min: float = 1.6
var _max_slope_deg: float = 18.0
var _max_step: float = 0.55
var _remove_radius: float = 3.0
var _refund_on_remove: bool = true
var _ghost_alpha: float = 0.55
var _valid_colour: Color = Color("#8fd694")
var _invalid_colour: Color = Color("#e0a05a")

## Swallows the frame the mode opened on.
##
## `combat_manager` documents the same guard for the same reason: "Engage and
## charged attack are the same physical button... Without this, the press that
## starts the fight is also read as the first attack of it." Here it is the
## press that opens build mode also being read as the first placement, which
## drops a wall on the player's feet the instant they enter.
var _input_guard: bool = false


func _ready() -> void:
	_load_config()
	_player = get_node_or_null(player_path) as CharacterBody3D
	_world = get_node_or_null(world_path)
	_structures = get_node_or_null(structures_path) as Node3D
	_combat = get_node_or_null(combat_path)
	if _structures != null:
		_ids.assign(_structures.call("catalogue").keys())
		_ids.sort()
	# DEFERRED, because `_ready()` runs inside the parent's own `add_child()` and
	# a node added to a parent that is busy setting up its children is refused.
	_mount_field_systems.call_deferred()


## MOUNT THE M8 FIELD SYSTEMS, AND MOVE THIS THE DAY THE SCENE CAN CARRY THEM.
##
## `scripts/world/harvestable.gd` and `scripts/items/tools.gd` are two nodes with
## no scene of their own. They belong in `scenes/world/meadows_playground.tscn`
## beside `Structures` and `BuildMode`, as:
##
##   [node name="Harvestable" type="Node3D" parent="."]
##   script = <res://scripts/world/harvestable.gd>
##   [node name="Tools" type="Node" parent="."]
##   script = <res://scripts/items/tools.gd>
##   player_path = NodePath("../Player")
##   harvestable_path = NodePath("../Harvestable")
##   build_path = NodePath("../BuildMode")
##   combat_path = NodePath("../CombatManager")
##
## They are created HERE instead because the milestone that wrote them did not own
## that scene file and three other agents were editing it at the time. This is
## wiring, not design: it creates nothing if the scene already provides the nodes,
## so adding them properly is a scene edit and the deletion of this function, in
## either order.
##
## The alternative was shipping M8's gathering as two well-tested files that
## nothing in the running game ever called — which is the "written and never
## called" shape this project keeps getting bitten by, and which `save_director.gd`
## exists because of.
func _mount_field_systems() -> void:
	var world := get_parent()
	if world == null:
		return
	var harvestable := world.get_node_or_null(^"Harvestable")
	if harvestable == null:
		harvestable = (load("res://scripts/world/harvestable.gd") as GDScript).new()
		harvestable.name = "Harvestable"
		world.add_child(harvestable)
	if world.get_node_or_null(^"Tools") == null:
		var kit: Node = (load("res://scripts/items/tools.gd") as GDScript).new()
		kit.name = "Tools"
		world.add_child(kit)
		kit.call("bind", _player, harvestable, self, _combat)


func is_open() -> bool:
	return _open


func selected_id() -> String:
	return _ids[_selected] if _selected < _ids.size() else ""


func selected_name() -> String:
	if _structures == null:
		return ""
	return str((_structures.call("definition", selected_id()) as Dictionary).get("display_name", ""))


func ghost_valid() -> bool:
	return _valid


func refusal() -> String:
	return _refusal


func piece_ids() -> Array[String]:
	return _ids


## Input is read in `_physics_process`, never `_process`.
##
## `encounter_director` records the cost of getting this wrong:
## `Input.is_action_just_pressed()` is scoped to the frame the press was recorded
## in, so a system reading it from `_process` while another reads from
## `_physics_process` will sometimes each see a different half of one press.
func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("build_toggle"):
		_set_open(not _open)
		return

	if not _open:
		return
	if _input_guard:
		_input_guard = false
		return

	# Build mode's OWN actions. It used to read `combat_switch_*` and `tool_cycle`
	# — the M4 pal switch and the M8 tool wheel — which worked only for as long
	# as neither of those existed.
	if Input.is_action_just_pressed("build_cycle_right"):
		_cycle(1)
	elif Input.is_action_just_pressed("build_cycle_left"):
		_cycle(-1)
	if Input.is_action_just_pressed("build_rotate"):
		_yaw = GRID.snap_yaw(_yaw + GRID.YAW_STEP)

	_update_ghost()

	if Input.is_action_just_pressed("combat_quick"):
		_try_place()
	elif Input.is_action_just_pressed("combat_charged"):
		_try_remove()


## The single door in and out.
func _set_open(value: bool) -> void:
	if value == _open:
		return

	# Refused rather than queued. Redecorating mid-fight is not a thing anyone
	# needs, and a build ghost over a combat HUD is two modes drawing at once.
	if value and _combat != null and bool(_combat.call("is_fighting")):
		refused.emit("not while you are in a fight")
		return

	_open = value
	if _player != null:
		_player.call("set_locomotion_enabled", not _open)

	if _open:
		_input_guard = true
		_yaw = 0.0
		_build_ghost()
		opened.emit()
	else:
		_clear_ghost()
		closed.emit()


func _cycle(step: int) -> void:
	if _ids.is_empty():
		return
	_selected = posmod(_selected + step, _ids.size())
	_build_ghost()
	selection_changed.emit(selected_id())


## Where the piece would go if you placed it now.
##
## The aim point is a fixed distance in front of the trainer rather than under a
## cursor: this is a controller-first game and there is no mouse look action in
## the input map at all.
func _aim_point() -> Vector3:
	if _player == null:
		return Vector3.ZERO
	var forward := -_player.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		forward = Vector3.FORWARD
	return _player.global_position + forward.normalized() * (_reach * 0.55)


func _update_ghost() -> void:
	if _ghost == null or _structures == null:
		return
	var piece: Dictionary = _structures.call("definition", selected_id())
	if piece.is_empty():
		return

	var snapped: Dictionary = GRID.snap(_aim_point(), str(piece.get("anchor", GRID.ANCHOR_CELL)))
	var where: Vector3 = snapped["position"]
	# An edge anchor decides its own facing — a wall lies ALONG the edge it is
	# on, so taking yaw from the player here would float walls diagonally across
	# cell corners. The manual yaw still turns cell-anchored pieces.
	var yaw: float = _yaw if is_nan(float(snapped.get("yaw", NAN))) else float(snapped["yaw"]) + _yaw

	var ground := _ground_under(where, piece, yaw)
	if not is_nan(ground):
		where.y = ground

	_ghost.global_position = where
	_ghost.rotation.y = yaw
	_valid = _check(where, yaw, piece)
	if _ghost_material != null:
		var colour := _valid_colour if _valid else _invalid_colour
		colour.a = _ghost_alpha
		_ghost_material.albedo_color = colour


## Lowest ground height under the piece's footprint, or NAN off the terrain.
##
## `ground_height_at` and never a raycast: D09 measured roughly a quarter of
## downward rays missing terrain that is unquestionably there, and its closing
## section names this exact case — "ask the terrain first, and fall back to a ray
## only for what the terrain has never heard of."
func _ground_under(centre: Vector3, piece: Dictionary, yaw: float) -> float:
	if _world == null:
		return NAN
	var cells: Array = piece.get("size_cells", [1, 1])
	var corners := GRID.footprint_corners(
		centre, Vector2i(int(cells[0]), int(cells[1])), yaw
	)
	var lowest := INF
	for corner: Vector3 in corners:
		var height: float = float(_world.call("ground_height_at", corner.x, corner.z))
		if is_nan(height):
			return NAN
		lowest = minf(lowest, height)
	return lowest


func _check(where: Vector3, yaw: float, piece: Dictionary) -> bool:
	_refusal = ""
	if _player == null or _world == null:
		return false

	# AFFORDABILITY IS CHECKED FIRST, BEFORE ANYTHING POSITIONAL, and the order is
	# the whole answer to "a piece the player cannot afford must be visibly
	# unaffordable BEFORE they try to place it".
	#
	# `_update_ghost()` runs `_check()` every physics frame, so a piece you cannot
	# pay for turns the ghost amber the moment it is selected and stays amber
	# wherever you point it — and `refusal()`, which the palette already reads,
	# says which material is short. Checking it after the ground rules would mean
	# a player walked around hunting for flat ground to be told no on.
	var missing := shortfall_of(selected_id())
	if not missing.is_empty():
		_refusal = describe_shortfall(missing)
		return false

	var flat := Vector2(where.x - _player.global_position.x, where.z - _player.global_position.z)
	if flat.length() > _reach:
		_refusal = "too far away"
		return false
	if flat.length() < _reach_min:
		_refusal = "too close to stand"
		return false

	var cells: Array = piece.get("size_cells", [1, 1])
	var corners := GRID.footprint_corners(where, Vector2i(int(cells[0]), int(cells[1])), yaw)
	var lowest := INF
	var highest := -INF
	for corner: Vector3 in corners:
		var height: float = float(_world.call("ground_height_at", corner.x, corner.z))
		if is_nan(height):
			_refusal = "no ground there"
			return false
		lowest = minf(lowest, height)
		highest = maxf(highest, height)
	if highest - lowest > _max_step:
		_refusal = "ground is too uneven"
		return false

	# The pond. `vegetation._drown()` already refuses to plant a meadow in open
	# water and this is the same question asked by the same method.
	if _world.has_method("water_level_at"):
		var water: float = float(_world.call("water_level_at", where.x, where.z))
		if not is_nan(water) and where.y < water:
			_refusal = "that is under water"
			return false

	if bool(_structures.call("occupied", where, yaw)):
		_refusal = "something is already there"
		return false
	return true


## Put the selected piece down, and pay for it.
##
## THE MATERIALS ARE SPENT BEFORE THE PIECE IS BUILT, and put back if the build
## fails. The other order — build, then charge — has a failure mode where the
## charge is refused and a wall is standing that nobody paid for, and there is no
## way to tell that apart from a wall that was paid for. Spending first means the
## only failure is a refund, which is exact.
func _try_place() -> void:
	if not _valid:
		refused.emit(_refusal if _refusal != "" else "cannot build there")
		return
	var id := selected_id()
	var cost: Dictionary = _structures.call("cost_of", id)
	if not _spend(cost):
		refused.emit(_refusal if _refusal != "" else "you cannot afford that")
		return
	if _structures.call("place", id, _ghost.global_position, _ghost.rotation.y) == null:
		_give(cost)
		refused.emit("that piece could not be built")
		return
	placed.emit(id)


## Take a piece back, and hand its materials back with it.
##
## FULL REFUND, and it is a tunable (`refund_on_remove`) rather than a mechanic.
## Building here is free-form, placed pieces have no durability and nothing
## decays, so a removal tax would only ever punish a player for misjudging a
## thumbstick — and this is a controller-first game aiming a ghost down a fixed
## line in front of the trainer, where misjudging it is the normal case. Charging
## for experimentation would teach people to stop experimenting with the one
## system whose whole appeal is that it is theirs.
##
## A CHEST WITH SOMETHING IN IT IS REFUSED. Deleting it would delete the
## contents, and "I lost everything I had stored" is not a mistake a player
## should be able to make with one button.
func _try_remove() -> void:
	if _structures == null:
		return
	var at := _aim_point()
	var station: Node = _structures.call("nearest_placed_station", at, _remove_radius)
	if station != null and station.has_method("is_empty") and not bool(station.call("is_empty")):
		refused.emit("empty it before you take it down")
		return
	if not bool(_structures.call("remove_nearest", at, _remove_radius)):
		refused.emit("nothing here to remove")
		return
	if _refund_on_remove:
		_give(_structures.call("cost_of", str(_structures.call("last_removed"))))


## --- paying for it ----------------------------------------------------------

## What a piece costs, as `{item_id: count}`. For the palette.
func cost_of(piece_id: String) -> Dictionary:
	return {} if _structures == null else _structures.call("cost_of", piece_id)


## What the trainer is short of before they could build `piece_id`, as
## `{item_id: count}`. Empty means they can afford it.
func shortfall_of(piece_id: String) -> Dictionary:
	return shortfall(_purse(), cost_of(piece_id))


func can_afford(piece_id: String) -> bool:
	return shortfall_of(piece_id).is_empty()


## What is missing before `purse` could pay `cost`.
##
## Static and duck-typed, so a test can hand it a bare `inventory.gd` and the
## running game can hand it whatever façade the trainer's inventory lives behind.
## A NULL PURSE CANNOT AFFORD ANYTHING — never a silent success. There is no
## fallback inventory here and there must never be one: the day building charges
## a bag of its own is the day the player's real bag stops being the truth.
static func shortfall(purse: Object, cost: Dictionary) -> Dictionary:
	var missing: Dictionary = {}
	if cost.is_empty():
		return missing
	if purse == null or not purse.has_method("count_of"):
		return cost.duplicate()
	for item: String in cost.keys():
		var short: int = int(cost[item]) - int(purse.call("count_of", item))
		if short > 0:
			missing[item] = short
	return missing


## "4 Wood, 2 Stone". Uses the item table's display names, so a rename in
## items.json reaches the palette without anyone editing a string here.
static func describe_cost(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for item: String in cost.keys():
		parts.append("%d %s" % [int(cost[item]), DEFS.display_name(item)])
	return ", ".join(parts)


## "you need 4 more Wood". The refusal a player reads, and the reason it names
## the material: "you cannot afford that" sends them out to gather the wrong
## thing.
static func describe_shortfall(missing: Dictionary) -> String:
	if missing.is_empty():
		return ""
	var parts: Array[String] = []
	for item: String in missing.keys():
		parts.append("%d more %s" % [int(missing[item]), DEFS.display_name(item)])
	return "you need %s" % ", ".join(parts)


## Spend a cost. All or nothing, the same discipline `inventory.remove()` keeps.
func _spend(cost: Dictionary) -> bool:
	if cost.is_empty():
		return true
	var purse := _purse()
	if purse == null:
		# REFUSED, never waived. A missing inventory means the trainer's bag has
		# not been built yet, not that building is free; letting the placement
		# through would put up a stronghold the player never paid for and could
		# never have paid for.
		_refusal = "there is nothing to pay from"
		return false
	var missing := shortfall(purse, cost)
	if not missing.is_empty():
		_refusal = describe_shortfall(missing)
		return false
	for item: String in cost.keys():
		if not bool(purse.call("remove", item, int(cost[item]))):
			_refusal = describe_shortfall({item: int(cost[item])})
			return false
	return true


## Hand materials back — a refund, or an undo after a failed placement.
func _give(cost: Dictionary) -> void:
	var purse := _purse()
	if purse == null or cost.is_empty():
		return
	for item: String in cost.keys():
		if not bool(purse.call("add", item, int(cost[item]))):
			# A refund that will not fit is a full bag, not a lost wall. Said out
			# loud rather than swallowed, because materials quietly evaporating is
			# the hardest kind of bug to report.
			push_warning("could not refund %d %s; the trainer's inventory is full" % [
				int(cost[item]), item
			])


## The trainer's inventory, or null.
##
## Looked up rather than cached: it is built by another system and may arrive
## after this node does, and a cached null would mean building was free for the
## rest of the session. Two shapes are accepted and both answer the same four
## methods — a `TrainerInventory` node beside this one in the world scene, or the
## player's own `inventory()`.
func _purse() -> Object:
	var node := get_parent()
	if node != null:
		var found := node.get_node_or_null(NodePath(INVENTORY_NODE))
		if found != null and found.has_method("count_of") and found.has_method("remove"):
			return found
	if _player != null and is_instance_valid(_player) and _player.has_method("inventory"):
		var held: Variant = _player.call("inventory")
		if held is Object and (held as Object).has_method("count_of"):
			return held
	return null


## A translucent copy of the selected piece, with no collider.
##
## Its material is unshaded and transparent, and it deliberately keeps drawing
## when a placement is refused — it goes amber instead of vanishing. `combat_hud`
## learned that with cooldown verbs: a widget that disappears reads as broken,
## one that changes colour reads as an answer.
func _build_ghost() -> void:
	_clear_ghost()
	if _structures == null:
		return
	var piece: Dictionary = _structures.call("definition", selected_id())
	var model_path := str(piece.get("model", ""))
	if not ResourceLoader.exists(model_path):
		return

	_ghost = (load(model_path) as PackedScene).instantiate() as Node3D
	if _ghost == null:
		return
	add_child(_ghost)

	_ghost_material = StandardMaterial3D.new()
	_ghost_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_material.albedo_color = Color(_valid_colour, _ghost_alpha)
	# Visible through the wall it is about to join, so you can see where a piece
	# lands when the thing you are building is between you and it.
	_ghost_material.no_depth_test = true
	for node in _ghost.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		mesh.material_override = _ghost_material
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _clear_ghost() -> void:
	if _ghost != null and is_instance_valid(_ghost):
		_ghost.queue_free()
	_ghost = null
	_ghost_material = null


func _load_config() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_warning("building config missing: %s; using defaults" % CONFIG_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	var config: Dictionary = parsed
	_reach = float(config.get("reach", _reach))
	_reach_min = float(config.get("reach_min", _reach_min))
	_max_slope_deg = float(config.get("max_slope_deg", _max_slope_deg))
	_max_step = float(config.get("max_step", _max_step))
	_remove_radius = float(config.get("remove_radius", _remove_radius))
	_refund_on_remove = bool(config.get("refund_on_remove", _refund_on_remove))
	_ghost_alpha = float(config.get("ghost_alpha", _ghost_alpha))
	_valid_colour = Color(str(config.get("ghost_valid_colour", "#8fd694")))
	_invalid_colour = Color(str(config.get("ghost_invalid_colour", "#e0a05a")))
