extends "res://tests/test_case.gd"

## F04#6 judge r6/r8: each Meadows named win changes the place itself. A captain's
## standard comes down and its cloth lies on the ground, their Sigil lights on
## a stone at their post, and their site gets its own touch; Dell's post loses
## its standard; the Warden's arena banners come down; the Hall readout shows a
## readout rather than a blank emissive quad.

const AFTERMATH := preload("res://scripts/world/trainer_aftermath.gd")
## The re-attach test mounts real props under the root (run_tests.gd).
const RUNS_IN_INITIALIZED_TREE := true
const CAPTAINS := {"captain_riverwatch": "river_sigil", "captain_field": "field_sigil", "captain_ridge": "ridge_sigil"}


const SITE_FIGHTS := ["relay_officer_dell", "relay_captain", "captain_riverwatch", "captain_field", "captain_ridge"]


func test_judged_site_candidate_is_on_and_changes_only_presentation_keys() -> void:
	var cfg := AFTERMATH.config()
	# F04#6 r22 (CPU-provisional 6.75, three code-blind judges): the site set is ON.
	assert_true(bool(cfg.get("visual_candidate_enabled", false)), "judged site candidate is ON")
	var judged: Dictionary = {}
	for id: String in SITE_FIGHTS:
		judged[id] = AFTERMATH.for_trainer(id).duplicate(true)
	cfg["visual_candidate_enabled"] = false
	var baseline: Dictionary = {}
	for id: String in SITE_FIGHTS:
		baseline[id] = AFTERMATH.for_trainer(id).duplicate(true)
	for id: String in SITE_FIGHTS:
		var candidate: Dictionary = judged[id].duplicate(true)
		var original: Dictionary = baseline[id].duplicate(true)
		assert_true(candidate["site_object"] != original["site_object"], id + " has a distinct judged site")
		# Only the site object and its presentation patches (sigil stone look,
		# stand-down spot) may differ; flags, rewards and dialogue stay.
		for key: String in ["site_object", "sigil_stone", "stand_down"]:
			candidate.erase(key)
			original.erase(key)
		assert_eq(candidate, original, id + " preserves every nonpresentation field")
	assert_true(AFTERMATH.for_trainer("unknown_trainer").is_empty(), "candidate cannot add a trainer")
	cfg["visual_candidate_enabled"] = true
	for id: String in SITE_FIGHTS:
		assert_eq(AFTERMATH.for_trainer(id), judged[id], id + " returns to the same judged set")


func test_every_captain_has_a_sigil_stone_and_every_fight_its_own_site_object() -> void:
	var cfg := AFTERMATH.config()
	# r8: the flat red cloth scraps are gone; the standard still sinks away.
	assert_true((cfg.get("fallen_cloth", {}) as Dictionary).is_empty(), "no flat cloth scrap is planted")
	assert_true(float(cfg.get("fall_sink_m", 0.0)) > 0.0, "the struck standard is pulled down out of sight")
	for id: String in CAPTAINS:
		var entry := AFTERMATH.for_trainer(id)
		var stone: Dictionary = entry.get("sigil_stone", {})
		assert_eq(str(stone.get("item", "")), str(CAPTAINS[id]), "%s's stone carries their own Sigil" % id)
	var sites := {}
	for id: String in SITE_FIGHTS:
		var site: Dictionary = AFTERMATH.for_trainer(id).get("site_object", {})
		var pieces: Array = site.get("pieces", [])
		assert_true(pieces.size() >= 2, "%s's win changes an object of its own" % id)
		var changed := pieces.filter(func(p: Dictionary) -> bool:
			return p.get("after") is Dictionary or str(p.get("state", "both")) != "both")
		assert_true(changed.size() >= 1, "%s's site object looks different after the win" % id)
		var key := JSON.stringify(pieces.map(func(p: Dictionary) -> String: return str(p.get("model", ""))))
		assert_false(sites.has(key), "%s's site object is not another fight's" % id)
		sites[key] = true
	assert_true(AFTERMATH.for_trainer("relay_officer_dell").has("standard"), "Dell's post has a standard to lose")


func test_settle_lays_the_cloth_down_and_lights_the_stone() -> void:
	var holder := Node3D.new()
	var body := Node3D.new()
	holder.add_child(body)
	body.set_meta(AFTERMATH.HOME_META, Transform3D(Basis(), Vector3.ZERO))
	var standard := Node3D.new()
	holder.add_child(standard)
	body.set_meta(AFTERMATH.STANDARD_META, standard)
	var fallen := Node3D.new()
	fallen.visible = false
	holder.add_child(fallen)
	body.set_meta(AFTERMATH.FALLEN_META, fallen)
	var stone := Node3D.new()
	holder.add_child(stone)
	var face := Node3D.new()
	stone.add_child(face)
	AFTERMATH._build_sigil(face, Vector3.ZERO, Color("4aa3df"), null, 1.0)
	AFTERMATH._set_sigil_lit(face, false)
	var light := OmniLight3D.new()
	light.name = "SigilLight"
	light.visible = false
	face.add_child(light)
	stone.set_meta("sigil_face", face)
	body.set_meta(AFTERMATH.STONE_META, stone)
	var touch := Node3D.new()
	touch.visible = false
	holder.add_child(touch)
	body.set_meta(AFTERMATH.TOUCH_META, touch)
	var site_before := Node3D.new()
	holder.add_child(site_before)
	body.set_meta(AFTERMATH.SITE_BEFORE_META, site_before)
	var site_after := Node3D.new()
	site_after.visible = false
	holder.add_child(site_after)
	body.set_meta(AFTERMATH.SITE_AFTER_META, site_after)
	var glowing := 0
	for node: Node in face.find_children("*", "MeshInstance3D", true, false):
		if ((node as MeshInstance3D).material_override as BaseMaterial3D).emission_enabled:
			glowing += 1
	assert_eq(glowing, 0, "the carved Sigil is dark while the captain holds the road")
	AFTERMATH.settle(body, "captain_field")
	if AFTERMATH._strikes_standard(AFTERMATH.for_trainer("captain_field")):
		# F04#6 r22 judged set: the site's after pieces carry the fallen standard.
		assert_false(standard.visible, "the upright standard is taken down")
		assert_true(site_after.visible, "the site's after state (with its fallen standard) shows")
	elif bool(AFTERMATH.config().get("keep_standards", false)):
		# F04#6 r13: the standards stay up; the site's own change carries the win.
		assert_true(standard.visible, "the standard stays up (keep_standards)")
		assert_false(fallen.visible, "no fallen cloth while the standard stands")
	else:
		assert_false(standard.visible, "the standard is down")
		assert_true(fallen.visible, "its cloth lies on the ground")
	assert_true(touch.visible, "the site's touch is there after the win")
	assert_true(light.visible, "the stone's Sigil is lit")
	assert_false(site_before.visible, "the site object's held state is gone")
	assert_true(site_after.visible, "the site object shows its after state")
	glowing = 0
	for node: Node in face.find_children("*", "MeshInstance3D", true, false):
		if ((node as MeshInstance3D).material_override as BaseMaterial3D).emission_enabled:
			glowing += 1
	assert_true(glowing >= 2, "the Sigil's face and rim glow once the captain is beaten")
	holder.free()


func test_the_warden_arena_banners_follow_his_defeat_flag() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/world/stronghold.gd")
	assert_true(src.contains('const WARDEN_DEFEAT_FLAG := "defeated_warden"'), "the arena banners read the Warden's defeat flag")
	assert_eq(src.count("_warden_banners.append(_hang_banner("), 2, "both arena banner pairs are tracked")
	assert_true(src.contains("banner.visible = not warden_down"), "they come down when he is beaten, on reload too")


func test_the_hall_readout_shows_a_readout() -> void:
	var climax := load("res://scripts/world/stronghold_climax.gd")
	var host: Node = climax.new()
	var material: StandardMaterial3D = host.call("_readout_screen_material", Color("7fd8c4"))
	assert_ne(material.albedo_texture, null, "the screen carries a drawn readout")
	assert_true(material.emission_energy_multiplier < 1.6, "lit below the level that blew it out to white")
	var image := material.albedo_texture.get_image()
	var bright := 0
	for y in range(0, image.get_height(), 4):
		for x in range(0, image.get_width(), 4):
			if image.get_pixel(x, y).v > 0.5:
				bright += 1
	var samples := (image.get_height() / 4) * (image.get_width() / 4)
	assert_true(bright > 0 and bright < samples / 2, "strokes on a dark field, not a flat panel")
	host.free()


## A reload or a rematch re-attaches a beaten trainer (BOSSES 9.2): every
## fight's site object comes up straight in its after state, with real props.
func test_a_beaten_trainer_reattaches_in_the_after_state() -> void:
	var placer := GroundStub.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(placer)
	for id: String in SITE_FIGHTS:
		var body := Node3D.new()
		placer.add_child(body)
		AFTERMATH.attach(placer, body, id, true)
		var before := AFTERMATH._meta_node(body, AFTERMATH.SITE_BEFORE_META)
		var after := AFTERMATH._meta_node(body, AFTERMATH.SITE_AFTER_META)
		assert_true(after != null and after.visible, "%s: after state shown on re-attach" % id)
		assert_true(before == null or not before.visible, "%s: held state hidden on re-attach" % id)
		assert_true(after != null and after.find_children("*", "MeshInstance3D", true, false).size() > 0,
			"%s: the after state is installed props, not an empty holder" % id)
		var fresh := Node3D.new()
		placer.add_child(fresh)
		AFTERMATH.attach(placer, fresh, id, false)
		var held := AFTERMATH._meta_node(fresh, AFTERMATH.SITE_BEFORE_META)
		assert_true(held != null and held.visible, "%s: an unbeaten trainer shows the held state" % id)
	placer.free()


class GroundStub extends Node3D:
	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0
