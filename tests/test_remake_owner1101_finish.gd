extends "res://tests/test_case.gd"

## Cause-lane finish for the owner-rule remakes (1 Nov 2026), all OFF by default:
## coat flags remake_owner1101_glow_read / _plate_blend
## (data/config/creature_coat_flags.json) and scale flags
## remake_owner1101_body_line / _judged_short (creature_scale_flags.json).
## Off changes nothing; on applies every key; no species shrinks or outgrows its
## evolution; the models (and so their clips) are untouched.
## remake_owner1101_dark_lift was judged a gain (v1/b24, 4 Nov) and now ships ON
## with the per-species judged flags in JUDGED_ON.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const COAT_PATH := "res://data/config/creature_coat_flags.json"
const COAT_FLAGS := ["remake_owner1101_glow_read", "remake_owner1101_plate_blend"]
const SCALE_FLAGS := ["remake_owner1101_body_line", "remake_owner1101_judged_short"]
const REMAKE_DIR := "/candidate_owner1101/models/"
## Creatures-ralph coat flags judged on CPU against the shipped remake and kept
## ON (2 Nov 2026), with the mapped score each one's _why records.
const JUDGED_ON := {"creatures_ralph_meadowhart_warm": "6.80", "creatures_ralph_cliffspike_bands": "6.49", "creatures_ralph_cannonback_moss": "6.22", "creatures_ralph_cragclaw_body_mid": "6.34", "creatures_ralph_ashtusk_lift": "7.07", "creatures_ralph_thundertunnel_velvet": "5.36", "creatures_ralph_torrentoad_toad": "5.55", "creatures_ralph_skyrill_r10_lift": "6.37", "creatures_ralph_mangrove_monitor_r9_olive": "6.05", "creatures_ralph_stormraven_charge": "6.72", "creatures_ralph_fulgocobra_goldvein": "6.52", "remake_owner1101_dark_lift": "6.04"}


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, "%s parses to an object" % path)
	return parsed if parsed is Dictionary else {}


func _flags(path: String) -> Dictionary:
	return _json(path).get("flags", {})


## A remake's live albedo is its current model's _Image_0.jpg: the owner1101
## remake, or the coordinator's newer Meshy model (candidate_r9, candidate_r10)
## its remake flag now points at. An owner1101 albedo still counts while it
## remains a source texture (aspect repaints read it).
func _live_albedos() -> Dictionary:
	var out := {}
	var remakes := _remake_species()
	for id: String in remakes:
		out[str(remakes[id]).get_basename() + "_Image_0.jpg"] = true
	return out


func _remake_species() -> Dictionary:
	var out := {}
	var flags := _flags(SPECIES.MODEL_FLAGS_PATH)
	for flag: String in flags:
		if flag.begins_with("remake_owner1101_"):
			for id: String in (flags[flag] as Dictionary).species:
				out[id] = str((flags[flag] as Dictionary).species[id].model)
	return out


func test_finish_flags_ship_off_and_change_nothing_while_off() -> void:
	var coats := _flags(COAT_PATH)
	for flag: String in COAT_FLAGS:
		assert_true(coats.has(flag), "%s is declared" % flag)
		assert_false(bool((coats.get(flag, {}) as Dictionary).get("enabled", true)), "%s ships OFF" % flag)
	var scales := _flags(SPECIES.SCALE_FLAGS_PATH)
	for flag: String in SCALE_FLAGS:
		assert_true(scales.has(flag), "%s is declared" % flag)
		assert_false(bool((scales.get(flag, {}) as Dictionary).get("enabled", true)), "%s ships OFF" % flag)
	# Off: the finish flags, exactly as shipped, contribute nothing to the live
	# coat map. (Separately judged per-species coat flags may remap a remake;
	# see test_judged_creature_coat_flags_ship_on_with_their_scores.)
	var finish_only := {}
	for flag: String in COAT_FLAGS:
		finish_only[flag] = coats.get(flag, {})
	assert_eq(BODY.parse_coat_flags({"flags": finish_only}), {}, "the shipped finish flags remap nothing while off")


func test_enabled_coat_flags_apply_every_key() -> void:
	var coats := _flags(COAT_PATH)
	var live_albedos := _live_albedos()
	for flag: String in COAT_FLAGS:
		var entry: Dictionary = (coats.get(flag, {}) as Dictionary).duplicate(true)
		entry.enabled = true
		var resolved: Dictionary = BODY.parse_coat_flags({"flags": {flag: entry}})
		assert_eq(resolved.size(), (entry.coats as Dictionary).size(), "%s resolves every entry when on" % flag)
		for from_path: String in resolved:
			assert_true((from_path.contains(REMAKE_DIR) or live_albedos.has(from_path)) and from_path.ends_with("_Image_0.jpg"),
				"%s keys the remake's live albedo (%s)" % [flag, from_path])
			var spec: Dictionary = resolved[from_path]
			var source := StandardMaterial3D.new()
			source.albedo_texture = load(from_path) as Texture2D
			source.emission_enabled = true
			source.emission_energy_multiplier = 1.0
			var copy: BaseMaterial3D = BODY.coat_material(source, spec)
			if spec.has("emission"):
				var energy := float(spec.emission_energy)
				assert_true(energy > 1.0 and energy <= 4.0, "%s glow energy %.2f is a real push within the clamp" % [from_path, energy])
				assert_true(copy.emission_texture != null and copy.emission_texture.resource_path == str(spec.emission),
					"%s wears its glow map" % from_path)
				assert_almost_eq(copy.emission_energy_multiplier, energy)
			if spec.has("albedo"):
				assert_true(copy.albedo_texture != null and copy.albedo_texture.resource_path == str(spec.albedo),
					"%s wears its regraded albedo" % from_path)


func test_glow_pass_covers_every_remake_with_a_glow_mask() -> void:
	var glow: Dictionary = (_flags(COAT_PATH).get("remake_owner1101_glow_read", {}) as Dictionary).get("coats", {})
	var remakes := _remake_species()
	for id: String in remakes:
		var model := str(remakes[id])
		var mask := model.get_basename() + "_arc_emission.png"
		var albedo := model.get_basename() + "_Image_0.jpg"
		if ResourceLoader.exists(mask):
			assert_true(glow.has(albedo), "%s's glow mask is lifted by the glow pass" % id)


func test_scale_flags_only_grow_and_keep_evolution_order() -> void:
	var scales := _flags(SPECIES.SCALE_FLAGS_PATH)
	var remakes := _remake_species()
	var rows: Dictionary = SPECIES.table()
	for flag: String in SCALE_FLAGS:
		var factors: Dictionary = (scales.get(flag, {}) as Dictionary).get("species", {})
		assert_true(not factors.is_empty(), "%s names species" % flag)
		for id: String in factors:
			assert_true(remakes.has(id), "%s: %s is an owner-rule remake" % [flag, id])
			var factor := float(factors[id])
			assert_true(factor >= 1.0, "%s: %s grows (x%.2f), never shrinks" % [flag, id, factor])
			var grown := float((rows[id].placeholder as Dictionary).get("height", 1.0)) * factor
			for other: String in rows:
				if str((rows[other] as Dictionary).get("evolves_from", "")) == id:
					var evolved := float((rows[other].placeholder as Dictionary).get("height", 1.0))
					assert_true(grown < evolved, "%s: %s at %.2fm stays under its evolution %s (%.2fm)" % [flag, id, grown, other, evolved])


func test_judged_creature_coat_flags_ship_on_with_their_scores() -> void:
	var coats := _flags(COAT_PATH)
	var live := BODY.parse_coat_flags(_json(COAT_PATH))
	var live_albedos := _live_albedos()
	for flag: String in JUDGED_ON:
		var entry: Dictionary = coats.get(flag, {})
		assert_true(bool(entry.get("enabled", false)), "%s ships ON (judged gain)" % flag)
		assert_true(str(entry.get("_why", "")).contains(JUDGED_ON[flag]), "%s records its mapped score %s" % [flag, JUDGED_ON[flag]])
		for from_path: String in (entry.get("coats", {}) as Dictionary):
			assert_true(from_path.contains(REMAKE_DIR) or live_albedos.has(from_path), "%s grades a remake texture" % flag)
			assert_true(live.has(from_path), "%s reaches the live coat map" % from_path)


## Visual lane v1/b15 (4 Nov): Terrapup's hit clip holds its peak recoil to the end
## of the clip, so the hurt-end frame no longer returns to idle; judged 6.37 -> 6.79.
func test_terrapup_hit_holds_its_peak_with_its_score() -> void:
	var flags: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/creature_model_flags.json"))
	var why := ""
	for key: String in flags:
		if flags[key] is Dictionary and (flags[key] as Dictionary).has("remake_owner1101_terrapup"):
			why = str(flags[key]["remake_owner1101_terrapup"].get("_why", ""))
	assert_true(why.contains("6.79"), "the Terrapup remake records its hold-peak score")
	var scene: PackedScene = load("res://assets/creatures/tetherbound/terrapup/candidate_owner1101/models/creature_terrapup_owner1101.glb")
	var root: Node = scene.instantiate()
	var player := root.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	var anim := player.get_animation("hit")
	var held := 0
	for track in anim.get_track_count():
		if anim.track_get_type(track) != Animation.TYPE_ROTATION_3D or anim.track_get_key_count(track) < 2:
			continue
		var last: Quaternion = anim.track_get_key_value(track, anim.track_get_key_count(track) - 1)
		var mid: Quaternion = anim.rotation_track_interpolate(track, anim.length * 0.5)
		if last.is_equal_approx(mid):
			held += 1
	assert_true(held > 0, "hit-end matches mid-clip: the peak recoil is held")
	root.free()
