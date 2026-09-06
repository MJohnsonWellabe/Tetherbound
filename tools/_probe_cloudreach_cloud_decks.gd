extends SceneTree

## CLOUDREACH-ATMOS-0906 scratch probe: is the cloud sheet under the player?
##
## A render costs about eleven minutes on this box, and a cloud sheet that ends
## up ABOVE a stand is invisible in every counter the smokes print and glaring
## in the picture. This boots the real scene and prints, for each authored
## capture stand, the ground `tools/_capture_cloudreach_cliff_options.gd` would
## put the player on, the cloud sheet's height under that same XZ, and the gap.
## A negative gap is the defect: cloud over the player's head.
##
## It reads `cloudreach_world.gd::cloud_sheet_height_at`, the same function the
## sheet mesh is built from, so it cannot report a height the mesh does not have.
##
##   godot --headless --path . --script tools/_probe_cloudreach_cloud_decks.gd

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")

## The stands of the capture tool, verbatim.
const STANDS := {
	"01-arrival-first-reveal": Vector2(0.0, -260.0),
	"02-broken-causeways": Vector2(-534.0, 1285.3333),
	"02-lower-cliffs-galefoot": Vector2(-280.0, 496.0),
	"03-windscar-ravine": Vector2(-520.0, 2720.0),
	"04-high-roost-before-fly": Vector2(330.0, 3282.5),
	"05-upper-cloudreach-cliffhold": Vector2(-400.0, 3890.0),
	"06-summit-final-approach": Vector2(100.0, 5290.0),
	"07-fly-only-destination": Vector2(1110.0, 2927.0),
	"08-upper-cliffhold-east-arrival": Vector2(-309.2, 3991.2),
	"09-final-arena-space": Vector2(100.0, 5427.0),
	"11-aerie-ground-connection": Vector2(373.0, 3262.5356),
	"12-cliffhold-ground-connection": Vector2(-352.0, 3954.0),
}


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node(^"Game")
	game.current_realm = "cloudreach"
	var world := SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in 6:
		await physics_frame

	var decks := world.get_node_or_null(^"CloudDecks")
	if decks == null:
		printerr("CLOUD DECK PROBE: no CloudDecks node -- cloud_sea.enabled is false, or the build failed")
		quit(1)
		return

	var worst := INF
	var worst_stand := ""
	print("CLOUD DECK PROBE  stand                            ground      cloud        gap")
	for stand_name: String in STANDS.keys():
		var xz: Vector2 = STANDS[stand_name]
		var ground := float(world.call("ground_height_at", xz.x, xz.y))
		var cloud := float(world.call("cloud_sheet_height_at", xz.x, xz.y, 55.0))
		var gap := ground - cloud
		print("CLOUD DECK PROBE  %-32s %9.1f %10.1f %10.1f" % [stand_name, ground, cloud, gap])
		if is_nan(ground):
			continue
		if gap < worst:
			worst = gap
			worst_stand = stand_name

	for label: String in ["CloudSeaUpper", "CloudSeaLower"]:
		var sheet := decks.get_node_or_null(NodePath(label)) as MeshInstance3D
		if sheet == null:
			print("CLOUD DECK PROBE  %s: absent" % label)
			continue
		var box := sheet.get_aabb()
		print("CLOUD DECK PROBE  %s: y %.1f .. %.1f, %d surfaces"
			% [label, box.position.y, box.position.y + box.size.y, sheet.mesh.get_surface_count()])
	var billows := decks.get_node_or_null(^"CloudBillows") as MultiMeshInstance3D
	print("CLOUD DECK PROBE  CloudBillows: %d instances"
		% [0 if billows == null else billows.multimesh.instance_count])

	print("CLOUD DECK PROBE  worst clearance %.1f m at %s" % [worst, worst_stand])
	if worst < 0.0:
		printerr("CLOUD DECK PROBE FAIL: the sheet is ABOVE the player at %s" % worst_stand)
		quit(1)
		return
	print("CLOUD DECK PROBE OK: the sheet is below every authored stand")
	quit(0)
