extends SceneTree

## OP-0830-3: did every pickup in the built world actually register with the
## shared highlight?
##
##   godot --headless --path . --script tools/_probe_pickup_glow_coverage.gd
##
## `tests/test_pickup_glow.gd` proves that each pickup SCRIPT calls
## `PICKUP_GLOW.attach`. That is a different claim from "every pickup the world
## actually builds is registered", and the gap between the two is where this
## kind of fix quietly half-lands: `attach()` needs the node to be in the tree
## to find the field, so a spawn path that calls `setup()` before `add_child()`
## would silently register nothing and no unit test would notice.
##
## So this stands the whole world up and counts, per pickup group, how many were
## built against how many hold a highlight. Headless is fine -- this counts
## registrations, it does not photograph them; `tools/capture_pickup_glow.gd`
## is what looks at them.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 120


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await process_frame

	var field := world.get_node_or_null(^"PickupGlowField")
	if field == null:
		print("[glow-coverage] FAIL: no PickupGlowField in the built world -- nothing registered")
		quit(1)
		return

	var registered := int(field.call("highlight_count"))
	var built := _count_pickups(world)
	print("[glow-coverage] pickups built in the world: %d" % built["total"])
	for key: String in built["by_kind"].keys():
		print("[glow-coverage]   %-22s %d" % [key, int(built["by_kind"][key])])
	print("[glow-coverage] highlights registered:      %d" % registered)

	# Not asserted equal: the count of *scripts* and the count of *registered
	# nodes* differ legitimately (a harvest node registers its visual, not
	# itself), and a pickup already taken in this save registers nothing at all.
	# What must hold is that the great majority carry one -- a wiring failure
	# shows up as a near-zero, not as an off-by-three.
	if registered < int(built["total"]) * 0.9:
		print("[glow-coverage] FAIL: only %d of %d pickups are highlighted" % [
			registered, int(built["total"])])
		quit(1)
		return
	print("[glow-coverage] ok")
	quit(0)


func _count_pickups(world: Node) -> Dictionary:
	var by_kind := {}
	var total := 0
	var game := world.get_node_or_null(^"/root/Game")
	var items: RefCounted = game.get("items") if game != null else null
	for node: Node in world.find_children("*", "Node3D", true, false):
		var script: Script = node.get_script() as Script
		if script == null:
			continue
		var path := script.resource_path
		if not path.ends_with("key_pickup.gd") and not path.ends_with("tm_pickup.gd") \
				and not path.ends_with("item_cache_pickup.gd") \
				and not path.ends_with("harvest_node.gd") \
				and not path.ends_with("felled_resource.gd") \
				and not path.ends_with("death_satchel.gd"):
			continue
		if not node.is_visible_in_tree():
			continue
		# OWNER PLAYTEST 2026-08-30B item 3: harvest_node.gd and felled_resource.gd
		# now withhold the highlight from "resource"-kind items (trees, wood,
		# stone, fiber, ore -- see `pickup_glow.gd::is_glow_kind()`) on purpose.
		# Counting those in `total` would fail this probe's 90% floor below on
		# exactly the pickups the owner asked to leave dark -- the majority of
		# every band's harvest table -- so they are excluded from "built" the
		# same way they are excluded from the glow.
		if (path.ends_with("harvest_node.gd") or path.ends_with("felled_resource.gd")) \
				and items != null and node.has_method("resource_item") \
				and str(items.call("kind", node.call("resource_item"))) == "resource":
			continue
		var kind := path.get_file()
		by_kind[kind] = int(by_kind.get(kind, 0)) + 1
		total += 1
	return {"total": total, "by_kind": by_kind}
