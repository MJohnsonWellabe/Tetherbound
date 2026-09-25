extends SceneTree

## F04 / ACCEPTANCE §6.1: "no ordinary wild inherits a boss override".
##
## A boss or named-fight profile reaches a body through exactly one field,
## `wild_creature.gd::combat_override`, merged over combat.json's shared `enemy`
## block by `_enemy_config_for_this_body()`. An ordinary wild inherits a boss
## override in one of two ways, and this checks both on the production world:
##
##  1. AUTHORING -- a spawn table puts a `combat` block on an ordinary entry
##     (top level) instead of inside a named `alpha`/`elder` individual. Checked
##     statically over every Meadows band's spawns.json.
##  2. RUNTIME -- a body that is not a named once-only individual carries an
##     override after the world is built, or merging a named/trainer override
##     mutates the SHARED base dictionary every ordinary wild is handed (the
##     common path returns that dictionary itself, not a copy). Checked on the
##     live Meadows population: every override-bearing wild must be a once-only
##     individual, and after every authored override in the Meadows
##     (spawns.json named blocks, trainers.json members, the Warrens guardian)
##     has been merged through a real body, the shared `enemy` block and every
##     ordinary wild's effective config are unchanged.
##
##   godot --headless --path . --script tests/smoke_no_wild_inherits_boss_override.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const MATH := preload("res://scripts/combat/combat_math.gd")
const WILD_SCRIPT := preload("res://scripts/creatures/wild_creature.gd")
const BANDS_DIR := "res://data/config/bands/"
const SETTLE_FRAMES := 900

var _failures: Array[String] = []
var _receipt: Dictionary = {}


func _init() -> void:
	_run()


func _run() -> void:
	var authored := _check_spawn_tables()

	var world: Node3D = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	var director := world.get_node_or_null(^"EncounterDirector")
	if director == null:
		_fail("production Meadows has no EncounterDirector")
		_report()
		return
	for _frame in SETTLE_FRAMES:
		await physics_frame

	var base_before: Dictionary = (MATH.config().get("enemy", {}) as Dictionary).duplicate(true)
	var once_only: Dictionary = director.get("_once_only") as Dictionary
	var ordinary: Array[Node3D] = []
	var named := 0
	for candidate: Variant in director.get("_wild_creatures"):
		var body := candidate as Node3D
		if body == null or not is_instance_valid(body):
			continue
		var override: Dictionary = body.get("combat_override") as Dictionary
		if override.is_empty():
			ordinary.append(body)
			continue
		named += 1
		if str(once_only.get(body, "")).is_empty():
			_fail("%s carries a boss/named combat override %s but is not a once-only named individual" % [
				body.name, JSON.stringify(override)])
	if ordinary.is_empty():
		_fail("the Meadows populated no ordinary wilds to check")

	var ordinary_before := {}
	for body: Node3D in ordinary:
		var effective: Dictionary = body.call("_enemy_config_for_this_body")
		if effective != base_before:
			_fail("ordinary wild %s does not fight with the shared enemy baseline: %s" % [
				body.name, JSON.stringify(effective)])
		ordinary_before[body] = effective.duplicate(true)

	# Merge every authored override in the Meadows through a real body --
	# the live named individuals above plus the trainer members and the Warrens
	# guardian, pushed through a scratch body exactly as `_send_out_next_creature`
	# does -- then prove none of it reached the shared base or an ordinary wild.
	var probe: Node3D = Node3D.new()
	probe.set_script(WILD_SCRIPT)
	var merged_sources := 0
	for override: Dictionary in authored:
		probe.set("combat_override", override.duplicate(true))
		for trainer_owned: bool in [false, true]:
			probe.set("trainer_owned", trainer_owned)
			var merged: Dictionary = probe.call("_enemy_config_for_this_body")
			merged["power"] = -1.0  # a consumer mutating its own copy must not leak either
			merged_sources += 1
	for candidate: Variant in director.get("_wild_creatures"):
		var body := candidate as Node3D
		if body != null and is_instance_valid(body) \
				and not (body.get("combat_override") as Dictionary).is_empty():
			(body.call("_enemy_config_for_this_body") as Dictionary)["power"] = -1.0
			merged_sources += 1
	probe.free()

	var base_after: Dictionary = MATH.config().get("enemy", {}) as Dictionary
	if base_after != base_before:
		_fail("merging authored boss overrides mutated combat.json's shared enemy block: %s -> %s" % [
			JSON.stringify(base_before), JSON.stringify(base_after)])
	for body: Node3D in ordinary:
		var effective: Dictionary = body.call("_enemy_config_for_this_body")
		if effective != ordinary_before[body]:
			_fail("ordinary wild %s changed its fighting numbers after boss overrides were merged: %s" % [
				body.name, JSON.stringify(effective)])

	_receipt = {
		"ordinary_wilds": ordinary.size(),
		"named_override_wilds": named,
		"authored_overrides_merged": merged_sources,
		"authored_sources": authored.size(),
	}
	_report()


## Every Meadows band's spawns.json: a `combat` block may only appear inside a
## named `alpha`/`elder` individual. Returns every authored Meadows override
## (spawn named blocks, trainers.json members, the Warrens guardian) for the
## runtime merge check.
func _check_spawn_tables() -> Array[Dictionary]:
	var authored: Array[Dictionary] = []
	var dir := DirAccess.open(BANDS_DIR)
	if dir == null:
		_fail("cannot open %s" % BANDS_DIR)
		return authored
	var bands := 0
	for band: String in dir.get_directories():
		var spawns := _json("%s%s/spawns.json" % [BANDS_DIR, band])
		if spawns.is_empty():
			continue
		bands += 1
		for raw: Variant in spawns.get("spawns", []) as Array:
			var entry := raw as Dictionary
			if entry == null:
				continue
			if entry.has("combat"):
				_fail("%s spawns.json order %s (%s) authors a combat block on the ordinary population" % [
					band, str(entry.get("order", "?")), str(entry.get("species", "?"))])
			for key: String in ["alpha", "elder"]:
				var block: Variant = entry.get(key, {})
				if block is Dictionary and (block as Dictionary).get("combat", null) is Dictionary:
					authored.append((block as Dictionary)["combat"])
		var trainers := _json("%s%s/trainers.json" % [BANDS_DIR, band])
		_collect_combat_blocks(trainers, authored)
	if bands == 0:
		_fail("found no Meadows band spawn tables under %s" % BANDS_DIR)
	_collect_combat_blocks(_json("res://data/config/burrow_warrens.json"), authored)
	if authored.is_empty():
		_fail("found no authored boss/named overrides to merge; the runtime check would prove nothing")
	return authored


## Any `combat` Dictionary anywhere inside a trainers/warrens file is an
## authored per-creature override (the G-2 shape).
func _collect_combat_blocks(value: Variant, out: Array[Dictionary]) -> void:
	if value is Dictionary:
		for key: Variant in value:
			var child: Variant = value[key]
			if str(key) == "combat" and child is Dictionary:
				out.append(child)
			else:
				_collect_combat_blocks(child, out)
	elif value is Array:
		for child: Variant in value:
			_collect_combat_blocks(child, out)


func _json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("no wild inherits boss override receipt: " + JSON.stringify(_receipt))
		print("no wild inherits boss override: OK")
		quit(0)
		return
	for failure in _failures:
		print("no wild inherits boss override FAIL: " + failure)
	quit(1)
