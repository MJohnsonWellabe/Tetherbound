extends "res://tests/test_case.gd"

## F38#1/#2/#26 creature rim (client presentation): ships ON since qj rim10
## (4 Nov); inactive outside its listed looks and inert there; when on it dresses only shadow-casting creature body meshes,
## never replaces another overlay, and lends the slot to combat tell auras.

const RIM := preload("res://scripts/world/creature_rim.gd")
const TELL_STYLE := preload("res://scripts/combat/tell_style.gd")
const MEADOWS_LOOK := "res://data/config/meadows_look.json"
const OTHER_LOOK := "res://data/config/stormwood_look.json"
## The exit/re-entry test mounts a body under the live root.
const RUNS_IN_INITIALIZED_TREE := true


func after_each() -> void:
	RIM._material = null


func _body() -> Dictionary:
	var body := Node3D.new()
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	body.add_child(mesh)
	var card := MeshInstance3D.new()
	card.mesh = QuadMesh.new()
	card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(card)
	var held := MeshInstance3D.new()
	held.mesh = BoxMesh.new()
	held.material_overlay = StandardMaterial3D.new()
	body.add_child(held)
	return {"body": body, "mesh": mesh, "card": card, "held": held}


func _rim_material() -> ShaderMaterial:
	var material := preload("res://scripts/world/stormwood_character_rim.gd").overlay(RIM.settings())
	material.set_meta(RIM.META, true)
	return material


## Visual lane qj rim10-f38-1-2 (4 Nov): ships ON (F38#1 CPU 5.53 -> 5.84). The
## inactive path is still checked, through a realm look the arm does not list.
func test_creature_rim_ships_on_with_its_score_and_inactive_is_a_no_op() -> void:
	var cfg := RIM.settings()
	assert_eq(str(cfg.get("scope", "")), "client_presentation", "the arm declares its scope")
	assert_true(bool(cfg.get("enabled", false)), "the creature rim ships ON (judged gain)")
	assert_true(str(cfg.get("_why_on", "")).contains("5.84"), "it records its mapped score")
	assert_true((cfg.get("realm_looks", []) as Array).has(MEADOWS_LOOK), "the arm targets the Meadows look")
	assert_false((cfg.get("realm_looks", []) as Array).has(OTHER_LOOK), "and not the Stormwood look")
	var colour := Color(str(cfg.get("colour", "#ff0000")))
	assert_true(colour.b > colour.r, "the rim is a cool tone, never red/oxblood")
	RIM.set_realm(MEADOWS_LOOK)
	assert_true(RIM.active(), "ON makes the rim active in the Meadows")
	RIM.set_realm(OTHER_LOOK)
	assert_false(RIM.active(), "an unlisted look leaves the rim inactive")
	var parts := _body()
	assert_eq(RIM.dress_body(parts.body), 0, "inactive dresses nothing")
	assert_eq((parts.mesh as MeshInstance3D).material_overlay, null, "inactive leaves the body mesh bare")
	assert_eq(RIM.rest_overlay(parts.mesh), null, "inactive hands a transient overlay back to nothing")
	assert_false(RIM.is_rim((parts.held as MeshInstance3D).material_overlay), "another overlay is never the rim")
	(parts.body as Node).free()


func test_creature_rim_dresses_only_shadow_casting_bare_meshes() -> void:
	var parts := _body()
	var material := _rim_material()
	var keep: Material = (parts.held as MeshInstance3D).material_overlay
	assert_eq(RIM.dress(parts.body, material), 1, "only the bare shadow-casting body mesh takes the rim")
	assert_eq((parts.mesh as MeshInstance3D).material_overlay, material, "the body mesh carries the rim")
	assert_eq((parts.card as MeshInstance3D).material_overlay, null, "effect cards are left alone")
	assert_eq((parts.held as MeshInstance3D).material_overlay, keep, "an existing overlay is never clobbered")
	assert_eq(RIM.dress(parts.body, material), 0, "dressing twice changes nothing")
	assert_true(RIM.is_rim(material), "the rim is recognisable as the yielding overlay")
	(parts.body as Node).free()


func test_tell_aura_takes_the_rim_slot_and_hands_it_back() -> void:
	var parts := _body()
	var material := _rim_material()
	RIM._material = material
	RIM.dress(parts.body, material)
	var mesh := parts.mesh as MeshInstance3D
	var held := TELL_STYLE.apply_aura(parts.body, Color("#5fd8ff"), {"tell_aura": 1.0})
	assert_true(held != null, "a wind-up aura still lands on a rimmed creature")
	assert_true(mesh.material_overlay != material and mesh.material_overlay != null, "the aura replaces the rim while it runs")
	TELL_STYLE.clear_aura(held)
	assert_eq(mesh.material_overlay, material, "the rim returns when the aura ends")
	RIM.undress(parts.body)
	assert_eq(mesh.material_overlay, null, "undressing lifts the rim")
	(parts.body as Node).free()


## CI 4 Nov (batch 6): a body freed while its meshes still wore the rim logged
## "Parameter material is null" (material_get_instance_shader_parameters) on the
## net and region smokes. A dressed body sheds the rim as it leaves the tree and
## is dressed again if it comes back while the rim is on.
func test_a_body_sheds_the_rim_leaving_the_tree_and_regains_it_on_return() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	RIM.set_realm(MEADOWS_LOOK)
	assert_true(RIM.active(), "the shipped rim is active in the Meadows")
	var parts := _body()
	var body := parts.body as Node3D
	var mesh := parts.mesh as MeshInstance3D
	tree.root.add_child(body)
	assert_eq(RIM.dress_body(body), 1, "the bare body mesh takes the rim")
	assert_true(RIM.is_rim(mesh.material_overlay), "dressed in the tree")
	tree.root.remove_child(body)
	assert_eq(mesh.material_overlay, null, "leaving the tree sheds the rim")
	assert_false(RIM.is_rim((parts.held as MeshInstance3D).material_overlay), "another overlay is untouched")
	assert_true((parts.held as MeshInstance3D).material_overlay != null, "and kept")
	tree.root.add_child(body)
	assert_true(RIM.is_rim(mesh.material_overlay), "coming back while the rim is on dresses it again")
	RIM.set_realm(OTHER_LOOK)
	body.free()
