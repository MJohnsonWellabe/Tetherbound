extends "res://tests/test_case.gd"

## F04#6: each captain's fight leaves a visible change -- the standard beside
## them falls and they step out of the road -- derived only from the defeat
## flag, so a reload or a late joiner sees the same thing.

const AFTERMATH := preload("res://scripts/world/trainer_aftermath.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")


func test_every_captain_has_a_standard_and_a_stand_down_and_the_warden_a_show() -> void:
	for id: String in ["relay_captain", "captain_riverwatch", "captain_field", "captain_ridge"]:
		var entry := AFTERMATH.for_trainer(id)
		assert_false(TRAINERS.trainer(id).is_empty(), "%s is a real trainer" % id)
		assert_true(entry.has("standard"), "%s plants a standard" % id)
		assert_true(entry.has("stand_down"), "%s stands down" % id)
	assert_true(AFTERMATH.for_trainer("warden_aldis").has("victory_show"), "the Warden shows the key and heart")
	assert_true(AFTERMATH.for_trainer("relay_officer_dell").has("stand_down"), "Dell steps aside from his post")
	assert_true(AFTERMATH.for_trainer("quarry_picket_dorn").is_empty(), "an ordinary trainer changes nothing")


func test_offsets_are_in_the_body_frame_facing_plus_z() -> void:
	var at := AFTERMATH.local_offset(Vector3.ZERO, 0.0, [0.0, 2.0])
	assert_almost_eq(at.z, 2.0, 0.001, "forward is +Z at yaw 0")
	var turned := AFTERMATH.local_offset(Vector3.ZERO, PI * 0.5, [0.0, 2.0])
	assert_almost_eq(turned.x, 2.0, 0.001, "forward follows the yaw")
	var right := AFTERMATH.local_offset(Vector3.ZERO, 0.0, [1.0, 0.0])
	assert_almost_eq(right.x, -1.0, 0.001, "right is -X at yaw 0")


func test_settle_puts_a_beaten_captain_in_the_after_state() -> void:
	var holder := Node3D.new()
	var body := Node3D.new()
	holder.add_child(body)
	body.rotation.y = 0.3
	body.set_meta(AFTERMATH.HOME_META, Transform3D(Basis(Vector3.UP, 0.3), Vector3(10.0, 0.0, 20.0)))
	var standard := Node3D.new()
	holder.add_child(standard)
	var cloth := MeshInstance3D.new()
	var box := BoxMesh.new()
	var source := StandardMaterial3D.new()
	source.resource_name = "MI_Banner"
	box.material = source
	cloth.mesh = box
	standard.add_child(cloth)
	body.set_meta(AFTERMATH.STANDARD_META, standard)
	AFTERMATH.settle(body, "captain_field")
	var struck := cloth.get_surface_override_material(0) as StandardMaterial3D
	assert_ne(struck, null, "the cloth has its own material")
	assert_almost_eq(struck.albedo_color.a, 0.0, 0.001, "the standard's colours are struck")
	assert_almost_eq(source.albedo_color.a, 1.0, 0.001, "the shared Banner_1 material is untouched")
	var down: Dictionary = AFTERMATH.for_trainer("captain_field")["stand_down"]
	assert_almost_eq(body.rotation.y, 0.3 + deg_to_rad(float(down["turn_deg"])), 0.001,
		"the captain has turned from the fight")
	holder.free()


## Judge r4 (7121d40c): a Sigil hung at face height between lens and captain
## read as an interact marker over the face. Each handover is held out below
## the face and to one side, and each Sigil shows its own emblem.
func test_victory_tokens_are_held_beside_the_speaker_below_the_face() -> void:
	for id: String in ["captain_riverwatch", "captain_field", "captain_ridge", "warden_aldis"]:
		var show: Dictionary = AFTERMATH.for_trainer(id)["victory_show"]
		assert_true(float(show.get("height_m", 1.55)) <= 1.3, "%s's tokens sit below the face" % id)
		assert_true(absf(float(show.get("side_m", 0.0))) >= 0.5, "%s's tokens are held to one side" % id)
	assert_true(float(AFTERMATH.for_trainer("warden_aldis")["victory_show"].get("heart_scale", 1.0)) > 1.0,
		"the Warden's heart is shown larger than the shrine's own")


func test_each_captains_sigil_carries_its_own_emblem() -> void:
	var items := preload("res://autoload/item_db.gd").new()
	var seen := {}
	for id: String in ["captain_riverwatch", "captain_field", "captain_ridge"]:
		var token: Dictionary = (AFTERMATH.for_trainer(id)["victory_show"]["tokens"] as Array)[0]
		var icon := str(items.definition(str(token["item"])).get("icon", ""))
		assert_true(ResourceLoader.exists(icon), "%s's sigil has an emblem icon" % id)
		assert_false(seen.has(icon), "%s's emblem is its own" % id)
		seen[icon] = true
	var holder := Node3D.new()
	var texture := load(str(seen.keys()[0])) as Texture2D
	AFTERMATH._build_sigil(holder, Vector3.ZERO, Color("4e8ea3"), texture, 1.35)
	var sigil := holder.get_node("Sigil") as Node3D
	var emblem := sigil.get_node_or_null(^"Emblem") as MeshInstance3D
	assert_ne(emblem, null, "the medallion face shows the emblem")
	assert_eq((emblem.material_override as StandardMaterial3D).albedo_texture, texture, "with the item's own icon")
	assert_almost_eq(sigil.scale.x, 1.35, 0.001, "at the configured size")
	holder.free()


## Render af2 (03e7486c): three spheres read as a pale cloud. The Heart is the
## classic square point with a lobe on each upper edge, and the Warden holds it
## far enough aside to clear his chest.
func test_the_heart_is_a_heart_and_held_clear_of_the_warden() -> void:
	var holder := Node3D.new()
	AFTERMATH._build_heart(holder, Vector3.ZERO, 1.6)
	var heart := holder.get_node("Heart") as Node3D
	var boxes := 0
	var lobes := 0
	for child: Node in heart.get_children():
		var mesh := (child as MeshInstance3D).mesh
		if mesh is BoxMesh:
			boxes += 1
			assert_almost_eq(absf((child as Node3D).rotation.z), deg_to_rad(45.0), 0.001, "the point is a turned square")
		elif mesh is CylinderMesh:
			lobes += 1
			assert_true((child as Node3D).position.y > 0.0, "the lobes sit on the upper edges")
	assert_eq(boxes, 1, "one point")
	assert_eq(lobes, 2, "two lobes")
	assert_almost_eq(heart.scale.x, 1.6, 0.001, "at the configured size")
	holder.free()
	var show: Dictionary = AFTERMATH.for_trainer("warden_aldis")["victory_show"]
	assert_true(absf(float(show["side_m"])) >= 1.2, "held clear of the Warden's chest")


## Aftermath render af3 (b0b922d9): laid out across Vess's own shoulder line,
## her Sigil landed on her from the swung victory camera. Given the lens, the
## tokens sit across the line the shot looks along -- beside her on screen.
## (Pure layout: the unit runner has no live tree for show_victory itself.)
func test_tokens_are_laid_out_beside_the_speaker_as_the_lens_sees_them() -> void:
	var speaker := Vector3(10.0, 0.0, 10.0)
	var lens := Vector3(10.0, 2.0, 16.0)
	var player := Vector3(14.0, 0.0, 10.0)
	var toward := AFTERMATH.victory_toward(speaker, lens, player)
	assert_almost_eq(toward.z, 1.0, 0.001, "the lens, not the player, sets the layout line")
	var show: Dictionary = AFTERMATH.for_trainer("captain_ridge")["victory_show"]
	var offset := AFTERMATH.victory_origin(speaker, toward, show) - speaker
	assert_almost_eq(offset.z, float(show["toward_player_m"]), 0.01, "toward the lens")
	assert_almost_eq(absf(offset.x), absf(float(show["side_m"])), 0.01, "and across the lens line, beside her on screen")
	assert_almost_eq(offset.y, float(show["height_m"]), 0.01, "at the configured height")
	assert_almost_eq(AFTERMATH.victory_toward(speaker, Vector3.INF, player).x, 1.0, 0.001,
		"with no solved shot, toward the player as before")
