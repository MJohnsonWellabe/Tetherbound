extends SceneTree

## Headless material-pipeline proof for HUMANOID-NIGHT-RIM01.
## This builds installed production rigs, drives them through the real
## WorldLook day/night binding, and inspects the materials actually assigned to
## their body meshes. Run only under the repository's guarded Godot lease:
##
##   godot --headless --path . --script tools/probe_character_night_readability.gd

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const NPC_RANKS := preload("res://scripts/characters/npc_ranks.gd")
const WORLD_LOOK := preload("res://scripts/world/world_look.gd")
const PLAYABLE := ["trainer", "kael", "sera", "lyra"]
const PLAYER_RIM := 0.55
const PLAYER_RIM_TINT := 0.15
const CACHE_VARIANT_RIM := 0.35
const RIM_STRENGTH_META := &"tetherbound_player_rim_strength"

var _checks := 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var look := _make_world_look()
	if look == null:
		_finish()
		return

	var playable_materials: Array[BaseMaterial3D] = []
	var emission_before: Array[Dictionary] = []
	for key: String in PLAYABLE:
		var cfg := CHARACTER_MODEL.config_for(key)
		var rim: Dictionary = cfg.get("night_rim", {})
		_check(is_equal_approx(float(rim.get("strength", 0.0)), PLAYER_RIM),
			"%s declares the bounded player rim" % key)
		_check(is_equal_approx(float(rim.get("tint", -1.0)), PLAYER_RIM_TINT),
			"%s declares the neutral rim tint" % key)
		var material := _build_body(cfg, key)
		if material == null:
			continue
		playable_materials.append(material)
		emission_before.append(_emission_state(material))
		_check(material.has_meta(RIM_STRENGTH_META), "%s body opts into player rim" % key)
		_check(not material.rim_enabled and is_zero_approx(material.rim),
			"%s day material has no rim" % key)

	# Same model, palette and texture, but a different authored rim value must
	# never alias the production trainer's cached body material.
	var cache_cfg := CHARACTER_MODEL.config_for("trainer").duplicate(true)
	cache_cfg["night_rim"] = {"strength": CACHE_VARIANT_RIM, "tint": PLAYER_RIM_TINT}
	var cache_variant := _build_body(cache_cfg, "trainer rim cache variant")
	if cache_variant != null and not playable_materials.is_empty():
		_check(cache_variant != playable_materials[0],
			"rim parameters participate in body material cache identity")

	# Bodies without the explicit player-profile opt-in retain their source rim
	# state. Grandpa exercises the unranked path; grunt exercises the rank path.
	var grandpa := _build_body(CHARACTER_MODEL.config_for("grandpa"), "grandpa")
	var grunt := _build_body(NPC_RANKS.config_for("grunt"), "ranked grunt")
	var grandpa_rim := _rim_state(grandpa)
	var grunt_rim := _rim_state(grunt)

	look.call("apply_time", "night")
	for index in playable_materials.size():
		var material := playable_materials[index]
		_check(material.rim_enabled and is_equal_approx(material.rim, PLAYER_RIM),
			"%s receives full night rim through WorldLook" % PLAYABLE[index])
		_check(is_equal_approx(material.rim_tint, PLAYER_RIM_TINT),
			"%s retains the configured rim tint" % PLAYABLE[index])
		_check(_same_emission(material, emission_before[index]),
			"%s rim does not alter emission" % PLAYABLE[index])
	if cache_variant != null:
		_check(cache_variant.rim_enabled and is_equal_approx(cache_variant.rim, CACHE_VARIANT_RIM),
			"cached variant retains its own night rim")
	_check(_same_rim(grandpa, grandpa_rim), "unranked NPC rim remains unchanged at night")
	_check(_same_rim(grunt, grunt_rim), "ranked NPC rim remains unchanged at night")

	look.call("apply_time", "day")
	for index in playable_materials.size():
		var material := playable_materials[index]
		_check(not material.rim_enabled and is_zero_approx(material.rim),
			"%s returns to exact no-rim day state" % PLAYABLE[index])
		_check(_same_emission(material, emission_before[index]),
			"%s day return still preserves emission" % PLAYABLE[index])
	if cache_variant != null:
		_check(not cache_variant.rim_enabled and is_zero_approx(cache_variant.rim),
			"cached variant also returns to exact no-rim day state")
	_check(_same_rim(grandpa, grandpa_rim), "unranked NPC rim remains unchanged after day return")
	_check(_same_rim(grunt, grunt_rim), "ranked NPC rim remains unchanged after day return")
	_finish()


func _make_world_look() -> Node:
	var look := Node.new()
	look.set_script(WORLD_LOOK)
	var holder := WorldEnvironment.new()
	holder.name = "Environment"
	holder.environment = Environment.new()
	look.add_child(holder)
	look.set("environment_path", NodePath("Environment"))
	root.add_child(look)
	look.call("set_clock_frozen", true)
	_check(look.get("_config") is Dictionary and not (look.get("_config") as Dictionary).is_empty(),
		"WorldLook loads production art config")
	return look


func _build_body(cfg: Dictionary, label: String) -> BaseMaterial3D:
	var model := Node3D.new()
	model.set_script(CHARACTER_MODEL)
	root.add_child(model)
	if not bool(model.call("build_from_config", cfg)):
		_check(false, "%s production body builds" % label)
		return null
	var material := model.call("body_material") as BaseMaterial3D
	_check(material != null, "%s bound body material resolves" % label)
	return material


func _rim_state(material: BaseMaterial3D) -> Dictionary:
	if material == null:
		return {}
	return {"enabled": material.rim_enabled, "strength": material.rim, "tint": material.rim_tint}


func _same_rim(material: BaseMaterial3D, expected: Dictionary) -> bool:
	return material != null and not expected.is_empty() \
		and material.rim_enabled == bool(expected["enabled"]) \
		and is_equal_approx(material.rim, float(expected["strength"])) \
		and is_equal_approx(material.rim_tint, float(expected["tint"]))


func _emission_state(material: BaseMaterial3D) -> Dictionary:
	return {
		"enabled": material.emission_enabled,
		"operator": material.emission_operator,
		"colour": material.emission,
		"energy": material.emission_energy_multiplier,
	}


func _same_emission(material: BaseMaterial3D, expected: Dictionary) -> bool:
	var expected_colour: Color = expected["colour"]
	return material.emission_enabled == bool(expected["enabled"]) \
		and material.emission_operator == int(expected["operator"]) \
		and material.emission.is_equal_approx(expected_colour) \
		and is_equal_approx(material.emission_energy_multiplier, float(expected["energy"]))


func _finish() -> void:
	print("CHARACTER_NIGHT_RIM checks=%d failures=%d" % [_checks, _failures.size()])
	for failure: String in _failures:
		push_error("CHARACTER NIGHT RIM FAIL: " + failure)
	quit(0 if _failures.is_empty() else 1)


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)
