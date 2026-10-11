extends "res://tests/test_case.gd"

## F04#6 judge r6: each Meadows named win changes the place itself. A captain's
## standard comes down and its cloth lies on the ground, their Sigil lights on
## a stone at their post, and their site gets its own touch; Dell's post loses
## its standard; the Warden's arena banners come down; the Hall readout shows a
## readout rather than a blank emissive quad.

const AFTERMATH := preload("res://scripts/world/trainer_aftermath.gd")
const CAPTAINS := {"captain_riverwatch": "river_sigil", "captain_field": "field_sigil", "captain_ridge": "ridge_sigil"}


func test_every_captain_has_a_sigil_stone_and_a_touch_of_their_own() -> void:
	var cfg := AFTERMATH.config()
	assert_false((cfg.get("fallen_cloth", {}) as Dictionary).is_empty(), "the struck standard has a cloth to lie on the ground")
	var touches := {}
	for id: String in CAPTAINS:
		var entry := AFTERMATH.for_trainer(id)
		var stone: Dictionary = entry.get("sigil_stone", {})
		assert_eq(str(stone.get("item", "")), str(CAPTAINS[id]), "%s's stone carries their own Sigil" % id)
		var touch: Array = entry.get("touch", [])
		assert_true(touch.size() >= 1, "%s's site gets its own touch" % id)
		var key := JSON.stringify(touch.map(func(t: Dictionary) -> String: return str(t.get("model", ""))))
		assert_false(touches.has(key), "%s's touch is not another captain's" % id)
		touches[key] = true
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
	var glowing := 0
	for node: Node in face.find_children("*", "MeshInstance3D", true, false):
		if ((node as MeshInstance3D).material_override as BaseMaterial3D).emission_enabled:
			glowing += 1
	assert_eq(glowing, 0, "the carved Sigil is dark while the captain holds the road")
	AFTERMATH.settle(body, "captain_field")
	assert_false(standard.visible, "the standard is down")
	assert_true(fallen.visible, "its cloth lies on the ground")
	assert_true(touch.visible, "the site's touch is there after the win")
	assert_true(light.visible, "the stone's Sigil is lit")
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
