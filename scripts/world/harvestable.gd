extends Node3D

## What in the meadow can be gathered, and what is left of it.
##
## THE PROBLEM THIS FILE EXISTS FOR. The scatter draws 73,695 props as MultiMesh
## instances across 708 batches, and a MultiMesh instance is an INDEX, not a node
## — it cannot be raycast, picked, named or given a script. `structures.gd`
## records the same fact from the other side and chose individual nodes for
## player-placed buildings precisely because of it. A node per tree is not
## available here: seventy thousand of them is the thing the MultiMesh exists to
## avoid, and it would cost more than every other system in the game put together.
##
## THE SOLVE: a spatial hash built ONCE from the batches themselves.
##
##   - Walk the scatter. 136 of the 708 batches draw a model named by a
##     harvestable kind in `data/config/gathering.json`; the rest — grass,
##     flowers, clover, path stones, village walls — are skipped without being
##     read. Grass alone is over 60,000 instances.
##   - Read each kept batch's positions from `multimesh.buffer`: ONE
##     RenderingServer round trip per batch rather than one per instance. That is
##     the difference between 136 calls and seventy thousand.
##   - Keep a record for each of the ~2,500 harvestable instances and bucket them
##     by 4m cell, so "what is in front of the trainer" is a scan of nine buckets
##     rather than of the meadow.
##   - Each record keeps its batch node and its instance index, which is the
##     per-instance identity MultiMesh does not give you. Writing ONE instance's
##     transform is O(1) — the expensive operation is DELETING an instance, which
##     rewrites the array, and this file never deletes one.
##
## WHAT IT COSTS, against the current scatter: ~2,500 records held for the life of
## the world, 136 buffer reads when the index is built, and a rebuild whenever the
## scatter is. There is no per-frame cost at all beyond ticking the props that are
## currently spent, which is a handful.
##
## WHAT IT CANNOT DO UNDER `--headless`: anything. The dummy renderer discards
## MultiMesh instance data entirely, so every batch is dropped and gathering is
## unavailable. That is DETECTED and said out loud rather than guessed around —
## see `_origins_of` for the bug that made it necessary and D19 for the full note.
##
## WHAT IT ASSUMES about a file this agent does not own: that the scatter draws
## with `MultiMeshInstance3D` nodes named after the model they draw, and that
## solid layers get `CollisionShape3D` children under the same parent. Both are
## observed rather than configured — nothing here reads `vegetation.json` — so a
## rewrite that keeps drawing MultiMeshes keeps working, and one that does not
## degrades to an empty index and a refusal that says so, rather than to a silent
## success.
##
## NOTHING HERE YIELDS ANYTHING FROM A CREATURE. GAME_DESIGN.md §19: "There is no
## hunting/butchering gameplay. Do not create a meat/leather economy that assumes
## killing pals/wildlife." The kinds are trees, timber, boulders, stones, bushes
## and berry bushes, and the item ids they name are checked against items.json by
## `tests/test_gathering.gd`.

const CONFIG_PATH := "res://data/config/gathering.json"

## This node is one contributor to the single save envelope, found automatically
## by `save_director._register_contributors()` because it has `save_data`,
## `load_data` and this constant. See `autoload/save_manager.gd` for why there is
## only one file.
const SAVE_DOMAIN := "harvest"

## Refusal tokens, not sentences — `party.gd` established the idiom and the
## reason holds here: the world has no business knowing how a refusal is worded,
## and a sentence written here is one no HUD can shorten for a toast.
const REFUSED_NOTHING := "nothing_there"
const REFUSED_SPENT := "spent"
const REFUSED_NEEDS_TOOL := "needs_tool"
const REFUSED_WRONG_TOOL := "wrong_tool"
const REFUSED_NO_SCATTER := "no_scatter"

const REFUSALS := [
	REFUSED_NOTHING,
	REFUSED_SPENT,
	REFUSED_NEEDS_TOOL,
	REFUSED_WRONG_TOOL,
	REFUSED_NO_SCATTER,
]

## A prop that is spent is sunk to nothing rather than scaled to exactly zero. A
## zero basis is a degenerate transform and Godot is entitled to complain about
## one; this is invisible at any distance and is unambiguously still a transform.
const HIDDEN_SCALE := 0.0001

## Metres. How close a collision shape has to be, in XZ, to be considered THIS
## prop's collider. Half the tightest collision radius in the scatter, so a
## neighbouring tree's cylinder cannot be mistaken for a bush's.
const COLLIDER_EPSILON := 0.35

## Emitted after a successful swing, with the whole result dictionary — what
## kind, what item, how many, and where. Whoever owns feedback (a particle burst,
## a HUD line, a sound) hangs off this rather than polling.
signal harvested(result: Dictionary)
## A prop has just run out, and has just come back. The two halves of the visible
## story for anything that wants to draw a marker on a spent bush.
signal depleted(kind: String, position: Vector3)
signal regrown(kind: String, position: Vector3)

## The node the scatter draws under. Left empty means "look for it", which is
## what happens in the shipping scene where this node is mounted next to it.
@export var scatter_path: NodePath

## Names this node will accept as the scatter root when `scatter_path` is empty.
## Ordered: the first one found wins.
const SCATTER_NAMES := ["Vegetation", "Scatter", "Props"]

static var _config: Dictionary = {}

## `{kind_name: definition}` and `{model_basename: kind_name}`, both derived from
## the config once.
var _kinds: Dictionary = {}
var _model_kinds: Dictionary = {}
## Model basenames longest-first, so `Bush_Common_Flowers` is tested before
## `Bush_Common` and a berry bush is never read as a plain one.
var _model_order: Array[String] = []

var _cell: float = 4.0
var _reach: float = 3.2

## One entry per harvestable prop. Deliberately a flat Array of Dictionaries with
## the hash holding INDICES into it: the records are hot, the hash is rebuilt
## whenever the scatter is, and an Array of small dictionaries is the cheapest
## thing GDScript has that can carry a mixed record.
var _records: Array[Dictionary] = []
## `Vector2i(cell_x, cell_z)` -> `Array[int]` of indices into `_records`.
var _buckets: Dictionary = {}
## Indices of records that are currently spent, so the regrow tick is over a
## handful rather than over the whole meadow.
var _spent: Array[int] = []

var _indexed: bool = false
var _refusal: String = ""
## Batches the last `reindex()` had to skip because their instance data could not
## be read back. See `_origins_of`.
var _unreadable: int = 0

## Every collision shape in the scatter, bucketed by 1m XZ cell, so that "is
## something already solid here" is nine bucket lookups rather than a physics
## query. Built once and kept, because it only changes when the scatter does.
var _colliders: Dictionary = {}
var _colliders_built: bool = false
## The scatter handed over by `bind()`, which wins over `scatter_path`.
var _bound: Node = null

## Depletion read out of a save file, keyed the same way `save_data()` writes it,
## and applied when the index is next built.
##
## HELD RATHER THAN APPLIED, because a load can arrive before the scatter exists:
## `save_director` restores one frame after boot and the world builds its
## vegetation across several awaited frames. Anything that tried to apply state
## to an index that was not there yet would restore nothing and report success,
## which is the exact failure D14 records for the whole save system.
var _pending: Dictionary = {}


func _ready() -> void:
	_load_config()
	_register()


## Put this node into the save envelope itself, as well as being found by
## `save_director`'s tree scan.
##
## Both, because the two happen at different moments and this node is created at
## runtime rather than being in the scene file: the director scans once at boot,
## and a node added a frame later than that scan would be a system that works all
## session and is not in the save. `SaveManager.register()` is idempotent by
## design, which is what makes belt and braces free — `structures.gd` carries the
## same note.
func _register() -> void:
	var manager := get_node_or_null(^"/root/SaveManager")
	if manager != null:
		manager.call("register", SAVE_DOMAIN, self)


## --- the index -------------------------------------------------------------

## Build the index from the scatter, throwing away whatever was there.
##
## Safe to call repeatedly. The world rebuilds its scatter — `vegetation.build()`
## frees every child and starts again — and an index built before that is
## pointing at freed nodes.
func reindex() -> int:
	_load_config()
	_records.clear()
	_buckets.clear()
	_spent.clear()

	var scatter := _scatter()
	# `_indexed` LATCHES ONLY ONCE THERE IS SOMETHING TO INDEX. The world builds
	# its scatter several awaited frames after `_ready()`, so an index built at
	# boot finds nothing — and one that latched anyway would mean gathering was
	# permanently unavailable for the whole session because it was asked one frame
	# too early. A rescan while there is no scatter costs one `get_node_or_null`.
	_indexed = scatter != null
	if scatter == null:
		return 0

	_build_collider_index(scatter)
	_unreadable = 0
	for node in scatter.find_children("*", "MultiMeshInstance3D", true, false):
		var batch := node as MultiMeshInstance3D
		if batch == null or batch.multimesh == null:
			continue
		var kind_name := kind_of_batch(batch.name)
		if kind_name.is_empty():
			continue
		var kind: Dictionary = _kinds[kind_name]
		var origins := _origins_of(batch)
		if origins.is_empty():
			_unreadable += 1
			continue
		var frame := batch.global_transform if batch.is_inside_tree() else batch.transform
		for i in origins.size():
			var at: Vector3 = frame * (origins[i] as Vector3)
			_insert({
				"kind": kind_name,
				"position": at,
				"uses_left": int(kind.get("uses", 1)),
				"regrow_left": 0.0,
				"batch": batch,
				"index": i,
				# Restored on regrowth. Read at the moment a prop is HIDDEN rather
				# than now: holding 2,500 spare transforms to be able to put back the
				# handful that are ever spent is 2,500 transforms of nothing.
				"restore": null,
				# A prop is hidden while spent ONLY if nothing in the scatter is
				# colliding for it. Hiding the mesh of something that still has a
				# collision cylinder leaves an invisible wall, which is a worse bug
				# than a tree that is visibly still standing — so the rule is
				# observed from the world rather than configured, and it works out
				# as: bushes, berry bushes and fallen timber vanish and come back;
				# trees and boulders stay up and are simply spent for a while.
				"collider": _collider_at(at),
			})

	if _unreadable > 0:
		# LOUD, because the alternative is silent nonsense. See `_origins_of`.
		push_warning(
			"%d scatter batches would not give up their instance transforms; " % _unreadable
			+ "nothing in them can be gathered in this session"
		)
	return _records.size()


## Where every instance in a batch is, read from the MultiMesh's own buffer.
##
## ONE server call per batch rather than one per instance. `get_instance_transform`
## is a round trip into the RenderingServer, and at seventy thousand props that is
## seventy thousand round trips; `multimesh.buffer` hands the whole batch over as a
## flat float array in one.
##
## RETURNS EMPTY WHEN THE BUFFER IS NOT THERE, and that case is real and had to be
## found the hard way: under `--headless` Godot runs the DUMMY renderer, which
## accepts `set_instance_transform` and discards it. Every transform reads back as
## the identity and `buffer` is empty. A version of this function that trusted
## `get_instance_transform` indexed 2,500 props all stacked on the world origin —
## which, in a headless smoke, looks exactly like a working meadow with infinite
## wood at the spawn point.
##
## So: no buffer, no records, and `reindex()` says so out loud. Gathering is a
## thing that works in a rendered session, and the parts of it that do not need a
## renderer are the parts the test suite covers.
func _origins_of(batch: MultiMeshInstance3D) -> Array:
	var multi := batch.multimesh
	if multi == null or multi.instance_count <= 0:
		return []
	# 12 floats for the 3x4 transform, plus 4 each for the optional colour and
	# custom-data streams. The scatter uses neither, but a stride computed from
	# what the MultiMesh actually declares cannot be wrong about it later.
	var stride := 12
	if multi.use_colors:
		stride += 4
	if multi.use_custom_data:
		stride += 4
	if multi.transform_format != MultiMesh.TRANSFORM_3D:
		return []
	var buffer := multi.buffer
	if buffer.size() < multi.instance_count * stride:
		return []
	var out: Array = []
	out.resize(multi.instance_count)
	for i in multi.instance_count:
		var base := i * stride
		# Rows 0, 1 and 2 of the 3x4; the translation is the last float of each.
		out[i] = Vector3(buffer[base + 3], buffer[base + 7], buffer[base + 11])
	return out


## Whether this session's renderer keeps MultiMesh instance data at all.
##
## False means every scatter batch was skipped and gathering from the meadow is
## unavailable — which is the honest state under `--headless` and never the state
## in a real game window. Exposed so a smoke can say which of the two it is
## looking at instead of reporting an empty meadow as a content bug.
func transforms_readable() -> bool:
	return _unreadable == 0


## Hand this node its scatter directly, rather than through an exported path.
##
## The seam a test uses and the seam whatever eventually mounts this node in the
## world scene can use — `save_director.bind()` keeps the same one for the same
## reason: a system that can only be wired through the editor is a system that
## cannot be exercised without one.
func bind(scatter: Node) -> void:
	_bound = scatter
	reindex()


func _insert(record: Dictionary) -> void:
	var at: Vector3 = record["position"]
	var index := _records.size()
	_records.append(record)
	var key := _cell_of(at)
	if not _buckets.has(key):
		_buckets[key] = ([] as Array[int])
	(_buckets[key] as Array[int]).append(index)
	# Saved depletion is applied AS EACH RECORD ARRIVES rather than in a second
	# pass afterwards. That is what makes the ordering between a load and a world
	# build stop mattering: whichever happens first, a prop that was worked comes
	# back worked the moment it exists.
	_apply_saved(index)


## Put a harvestable in by hand. The seam a test uses, and the seam a future
## planted crop or player-placed resource would use — nothing about this file
## requires a prop to have come from the scatter.
func add_prop(kind_name: String, at: Vector3) -> bool:
	_load_config()
	if not _kinds.has(kind_name):
		push_error("no harvestable kind called '%s'" % kind_name)
		return false
	_indexed = true
	_insert({
		"kind": kind_name,
		"position": at,
		"uses_left": int((_kinds[kind_name] as Dictionary).get("uses", 1)),
		"regrow_left": 0.0,
		"batch": null,
		"index": -1,
		"restore": null,
		# Asked of the world even for a hand-placed prop: whether something is
		# already colliding at this spot is a fact about the spot, not about how
		# the prop got there.
		"collider": _collider_at(at),
	})
	return true


func _cell_of(at: Vector3) -> Vector2i:
	return Vector2i(int(floor(at.x / _cell)), int(floor(at.z / _cell)))


## The scatter root: the exported path, or the first plausibly-named sibling.
##
## `get_parent()` rather than a tree-wide `find_child`, because a tree-wide
## search would also find the preview tools' scatters and, in a test, whatever
## another test left in the root.
func _scatter() -> Node:
	if _bound != null and is_instance_valid(_bound):
		return _bound
	var node := get_node_or_null(scatter_path)
	if node != null:
		return node
	var parent := get_parent()
	if parent == null:
		return null
	for name: String in SCATTER_NAMES:
		var found := parent.get_node_or_null(NodePath(name))
		if found != null:
			return found
	return null


## Which kind a batch draws, by the LONGEST model name its node name begins with.
##
## Batch nodes are named after the model file, plus a `_x_y` suffix when the
## scatter splits a model into spatial cells for culling. Longest-first is what
## keeps `Bush_Common_Flowers_3_-2` from matching `Bush_Common`, which would turn
## every berry bush in the meadow into a fiber bush.
func kind_of_batch(batch_name: String) -> String:
	_load_config()
	for model: String in _model_order:
		if batch_name.begins_with(model):
			return str(_model_kinds[model])
	return ""


## Every collision shape in the scatter, bucketed by 1m XZ cell.
##
## Read from the world rather than from `vegetation.json`, so that which layers
## are solid stays a question about what is actually there. One pass, and the
## dictionary is thrown away as soon as the index is built.
func _build_collider_index(scatter: Node) -> void:
	_colliders.clear()
	_colliders_built = true
	if scatter == null:
		return
	var out: Dictionary = _colliders
	for node in scatter.find_children("*", "CollisionShape3D", true, false):
		var shape := node as CollisionShape3D
		if shape == null:
			continue
		var at := shape.global_position if shape.is_inside_tree() else shape.position
		var key := Vector2i(int(floor(at.x)), int(floor(at.z)))
		if not out.has(key):
			out[key] = []
		(out[key] as Array).append(shape)


func _collider_at(at: Vector3) -> CollisionShape3D:
	if not _colliders_built:
		_build_collider_index(_scatter())
	var base := Vector2i(int(floor(at.x)), int(floor(at.z)))
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			var bucket: Variant = _colliders.get(Vector2i(base.x + dx, base.y + dz))
			if not bucket is Array:
				continue
			for entry: Variant in (bucket as Array):
				var shape := entry as CollisionShape3D
				if shape == null or not is_instance_valid(shape):
					continue
				var where := shape.global_position if shape.is_inside_tree() else shape.position
				if absf(where.x - at.x) <= COLLIDER_EPSILON and absf(where.z - at.z) <= COLLIDER_EPSILON:
					return shape
	return null


## --- asking -----------------------------------------------------------------

func is_indexed() -> bool:
	return _indexed


func count() -> int:
	return _records.size()


func reach() -> float:
	_load_config()
	return _reach


func last_refusal() -> String:
	return _refusal


func kinds() -> Dictionary:
	_load_config()
	return _kinds.duplicate(true)


## The nearest harvestable to a point, spent or not, as an index into `_records`
## or -1. Nine buckets rather than the meadow.
func _nearest_index(point: Vector3, radius: float) -> int:
	var base := _cell_of(point)
	var span := maxi(1, int(ceil(radius / _cell)))
	var best := -1
	var best_distance := radius
	for dx in range(-span, span + 1):
		for dz in range(-span, span + 1):
			var bucket: Variant = _buckets.get(Vector2i(base.x + dx, base.y + dz))
			if not bucket is Array:
				continue
			for index: int in (bucket as Array[int]):
				var distance: float = (_records[index]["position"] as Vector3).distance_to(point)
				if distance <= best_distance:
					best_distance = distance
					best = index
	return best


## What is in front of you, as a description rather than as a record: kind, its
## display name, where it is, whether it is spent and what tool it wants. What an
## interaction prompt draws without being able to change anything.
func inspect(point: Vector3, radius: float = -1.0) -> Dictionary:
	_load_config()
	var index := _nearest_index(point, _reach if radius < 0.0 else radius)
	if index < 0:
		return {}
	var record: Dictionary = _records[index]
	var kind: Dictionary = _kinds[record["kind"]]
	return {
		"kind": str(record["kind"]),
		"display_name": str(kind.get("display_name", record["kind"])),
		"position": record["position"],
		"spent": int(record["uses_left"]) <= 0,
		"regrow_left": float(record["regrow_left"]),
		"tool": str(kind.get("tool", "")),
		"yields": str(kind.get("yields", "")),
	}


## Whether the prop nearest `point` has a collider in the scatter, and therefore
## whether it may be hidden while it is spent.
##
## Public because it is the only way to check that rule from outside: whether the
## mesh actually went is a rendered-session question, and the DECISION is not. See
## `_set_hidden` for why an invisible wall is the thing being avoided.
func collides_at(point: Vector3, radius: float = -1.0) -> bool:
	_load_config()
	var index := _nearest_index(point, _reach if radius < 0.0 else radius)
	if index < 0:
		return false
	return _records[index].get("collider") != null


## --- swinging ---------------------------------------------------------------

## Take one swing at whatever is nearest `point`.
##
## `tool_id` is the item id of what is being swung, or "" for bare hands. This
## function does NOT wear the tool down and does NOT put anything in a bag: it
## says what the swing WOULD produce and what it should cost, and
## `scripts/items/tools.gd` — which owns the tool and reaches the inventory —
## does both. Splitting it there is what lets the whole of this file be tested
## without an inventory, a player or a scene.
##
## Returns a dictionary that always carries `ok`. On a refusal it carries
## `refusal` and nothing else is meaningful.
func harvest(point: Vector3, tool_id: String = "") -> Dictionary:
	_refusal = ""
	if not _indexed:
		reindex()
	if _records.is_empty():
		_refusal = REFUSED_NO_SCATTER
		return {"ok": false, "refusal": _refusal}

	var index := _nearest_index(point, _reach)
	if index < 0:
		_refusal = REFUSED_NOTHING
		return {"ok": false, "refusal": _refusal}

	var record: Dictionary = _records[index]
	var kind: Dictionary = _kinds[record["kind"]]
	if int(record["uses_left"]) <= 0:
		_refusal = REFUSED_SPENT
		return {
			"ok": false,
			"refusal": _refusal,
			"kind": str(record["kind"]),
			"regrow_left": float(record["regrow_left"]),
		}

	var wanted := str(kind.get("tool", ""))
	var amount := int(kind.get("amount", 1))
	var wear := int(kind.get("durability", 0))
	if wanted != "" and tool_id != wanted:
		# A prop with a hand fallback lets you work at it barehanded for less. One
		# without says what it wants and refuses — and the two refusals are
		# different tokens, because "you need an axe" and "that is the wrong tool
		# for this" are different sentences on screen.
		if not kind.has("hand_amount"):
			_refusal = REFUSED_WRONG_TOOL if tool_id != "" else REFUSED_NEEDS_TOOL
			return {"ok": false, "refusal": _refusal, "kind": str(record["kind"]), "tool": wanted}
		if tool_id != "":
			_refusal = REFUSED_WRONG_TOOL
			return {"ok": false, "refusal": _refusal, "kind": str(record["kind"]), "tool": wanted}
		amount = int(kind.get("hand_amount", 1))
		wear = 0

	record["uses_left"] = int(record["uses_left"]) - 1
	var emptied := int(record["uses_left"]) <= 0
	if emptied:
		record["regrow_left"] = float(kind.get("regrow", 300.0))
		_spent.append(index)
		_set_hidden(record, true)
		depleted.emit(str(record["kind"]), record["position"])

	var result := {
		"ok": true,
		"refusal": "",
		"kind": str(record["kind"]),
		"display_name": str(kind.get("display_name", record["kind"])),
		"item": str(kind.get("yields", "")),
		"count": amount,
		"durability": wear,
		"position": record["position"],
		"spent": emptied,
		"uses_left": int(record["uses_left"]),
	}
	harvested.emit(result)
	return result


## Undo one swing, because there was nowhere to put what it produced.
##
## `tools.gd` calls this when the trainer's inventory refuses the yield: the
## swing landed, the prop lost a use, and then the wood had nowhere to go. Losing
## the use as well would mean a full inventory silently strips the meadow, which
## is the kind of thing a player only notices an hour later.
##
## Takes the RESULT of the swing rather than an index, so the caller never has to
## hold on to anything this file owns.
func put_back(result: Dictionary) -> bool:
	if not bool(result.get("ok", false)):
		return false
	var at: Variant = result.get("position")
	if not at is Vector3:
		return false
	var index := _nearest_index(at, 0.05)
	if index < 0:
		return false
	var record: Dictionary = _records[index]
	var kind: Dictionary = _kinds.get(record["kind"], {})
	if int(record["uses_left"]) <= 0:
		var spent_at := _spent.find(index)
		if spent_at >= 0:
			_spent.remove_at(spent_at)
		_set_hidden(record, false)
	record["regrow_left"] = 0.0
	record["uses_left"] = clampi(int(record["uses_left"]) + 1, 0, int(kind.get("uses", 1)))
	return true


## --- regrowth ---------------------------------------------------------------

func _process(delta: float) -> void:
	tick(delta)


## Advance every spent prop's timer. Split out from `_process` so a test can
## drive five minutes in one call without a tree, a clock or a scene — the same
## seam `save_director.tick()` keeps for the same reason.
func tick(delta: float) -> int:
	if _spent.is_empty() or delta <= 0.0:
		return 0
	var still: Array[int] = []
	var back := 0
	for index: int in _spent:
		var record: Dictionary = _records[index]
		record["regrow_left"] = maxf(0.0, float(record["regrow_left"]) - delta)
		if float(record["regrow_left"]) > 0.0:
			still.append(index)
			continue
		var kind: Dictionary = _kinds[record["kind"]]
		record["uses_left"] = int(kind.get("uses", 1))
		_set_hidden(record, false)
		regrown.emit(str(record["kind"]), record["position"])
		back += 1
	_spent = still
	return back


## Sink a prop's own MultiMesh instance out of sight, or put it back.
##
## This is the one place per-instance identity is spent, and it is O(1): the
## record kept the batch and the index, so one transform is written. Nothing is
## removed from the MultiMesh — removal is what would rewrite the array — and the
## batch's instance count never changes.
##
## Refused for anything that has a collider, see the note in `reindex()`.
func _set_hidden(record: Dictionary, hidden: bool) -> void:
	if record.get("collider") != null:
		return
	var batch: MultiMeshInstance3D = record.get("batch")
	var index := int(record.get("index", -1))
	if batch == null or not is_instance_valid(batch) or batch.multimesh == null:
		return
	if index < 0 or index >= batch.multimesh.instance_count:
		return
	if hidden:
		var original := batch.multimesh.get_instance_transform(index)
		record["restore"] = original
		batch.multimesh.set_instance_transform(
			index, Transform3D(original.basis.scaled(Vector3.ONE * HIDDEN_SCALE), original.origin)
		)
	elif record.get("restore") is Transform3D:
		batch.multimesh.set_instance_transform(index, record["restore"] as Transform3D)
		record["restore"] = null


## --- the `harvest` save domain ----------------------------------------------
##
## ONLY WHAT THE PLAYER CHANGED is written. The props themselves are content: the
## scatter is deterministic from a seed in `vegetation.json` and comes back
## identical every boot, so writing 2,500 untouched trees into every save would
## be 2,500 lines saying "still a tree". What is not reproducible is which ones
## somebody has been at, and that is a handful.
##
## Records are keyed by QUANTISED WORLD POSITION rather than by index into the
## batch. An index is meaningless the moment the scatter's batching changes —
## which it does whenever `batch_cell` is retuned or a layer gains a model — and
## a save that came back pointing at the wrong trees would be invisible until
## somebody noticed the wrong bush was empty. A position survives all of that,
## and a prop that has genuinely moved because the seed changed simply comes back
## full, which is the harmless failure.


func save_data() -> Dictionary:
	var out: Array = []
	for index: int in _spent:
		var record: Dictionary = _records[index]
		out.append({
			"at": _key_of(record["position"]),
			"kind": str(record["kind"]),
			"left": int(record["uses_left"]),
			"regrow": snappedf(float(record["regrow_left"]), 0.1),
		})
	# Partly-worked props matter too: a tree three swings into four is a real
	# state and coming back to a full tree is free wood.
	for i in _records.size():
		var record: Dictionary = _records[i]
		if _spent.has(i):
			continue
		var kind: Dictionary = _kinds.get(record["kind"], {})
		if int(record["uses_left"]) >= int(kind.get("uses", 1)):
			continue
		out.append({
			"at": _key_of(record["position"]),
			"kind": str(record["kind"]),
			"left": int(record["uses_left"]),
			"regrow": 0.0,
		})
	return {"worked": out}


func load_data(data: Dictionary) -> void:
	_pending.clear()
	for entry: Variant in data.get("worked", []):
		if not entry is Dictionary:
			continue
		var record: Dictionary = entry
		_pending[str(record.get("at", ""))] = record
	if _indexed:
		_apply_pending()


## Put saved depletion onto every record that has some.
##
## Only needed when a load arrives AFTER the index was built; the usual path is
## `_insert()` applying it one record at a time.
func _apply_pending() -> void:
	if _pending.is_empty():
		return
	_spent.clear()
	for i in _records.size():
		_apply_saved(i)


## Saved depletion for one record, if the save has any for it.
##
## Held state that finds no prop is simply never applied, and that is the right
## outcome rather than a gap: it means the scatter changed under the save, the
## tree it described is not there, and a meadow that is fully grown is better
## than an invisible bookkeeping entry that can never be cleared.
func _apply_saved(index: int) -> void:
	if _pending.is_empty():
		return
	var record: Dictionary = _records[index]
	var saved: Variant = _pending.get(_key_of(record["position"]))
	if not saved is Dictionary:
		return
	var kind: Dictionary = _kinds.get(record["kind"], {})
	record["uses_left"] = clampi(
		int((saved as Dictionary).get("left", 0)), 0, int(kind.get("uses", 1))
	)
	record["regrow_left"] = maxf(0.0, float((saved as Dictionary).get("regrow", 0.0)))
	if int(record["uses_left"]) <= 0:
		if not _spent.has(index):
			_spent.append(index)
		_set_hidden(record, true)
	else:
		_set_hidden(record, false)


## 5cm resolution, which is finer than any two props in the scatter are apart and
## coarse enough that a float printed into JSON and read back cannot drift out of
## its own bucket.
func _key_of(at: Vector3) -> String:
	return "%d,%d" % [roundi(at.x * 20.0), roundi(at.z * 20.0)]


## --- config -----------------------------------------------------------------

func _load_config() -> void:
	if not _kinds.is_empty():
		return
	var config := config()
	_cell = maxf(1.0, float(config.get("cell", 4.0)))
	_reach = maxf(0.5, float(config.get("reach", 3.2)))
	var entries: Variant = config.get("kinds", {})
	if not entries is Dictionary:
		return
	for name: String in (entries as Dictionary).keys():
		if name.begins_with("_"):
			continue
		var kind: Dictionary = (entries as Dictionary)[name]
		_kinds[name] = kind
		for model: Variant in kind.get("models", []):
			_model_kinds[str(model)] = name
	_model_order.assign(_model_kinds.keys())
	# Longest first. See `_kind_of_batch`.
	_model_order.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())


## Memoised on the script, like `item_defs.table()`, so the six kinds are parsed
## once however many worlds a test builds.
static func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("gathering config missing at %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("gathering config is not readable: %s" % CONFIG_PATH)
		return {}
	_config = parsed
	return _config
