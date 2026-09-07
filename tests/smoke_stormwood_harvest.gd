extends SceneTree

## Live, single-host harvest proof: a real authored charged Verge seam must
## refuse during Calm, then commit its exact data-owned yield once during a
## Break.  This deliberately mounts the production runtime and calls the
## HarvestNode public gather seam, rather than duplicating ledger rules here.

const RUNTIME := preload("res://scripts/world/stormwood_harvest_runtime.gd")
const HARVEST_NODE := preload("res://scripts/world/harvest_node.gd")
const SITE_ID := "stormwood_harvest_cinder_verge_018"
const ITEM_ID := "stormglass"
const AUTHORED_AMOUNT := 3

var _failures: Array[String] = []
var _assertions := 0


class FlatStormwoodWorld extends Node3D:
	var simulation_only := false

	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0


class ChapterStub extends Node:
	var events: Array[String] = []
	var game: Node

	func emit_event(event: String) -> void:
		events.append(event)
		# The production chapter dispatcher completes this first-event objective.
		# Keep the stub's state transition so the runtime's next normal scan proves
		# it neither faults on the freed node nor re-emits a completed event.
		if event == "harvest:verge_stormglass":
			game.get("progression").set_flag("stormwood:first_stormglass_gathered")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node_or_null(^"Game")
	_expect(game != null, "real Game autoload is available")
	if game == null:
		_finish()
		return
	game.call("reset_for_new_game")
	game.set("current_realm", "stormwood")
	var inventory: RefCounted = game.get("inventory")
	_expect(inventory != null, "Game exposes its real Inventory")
	if inventory == null:
		_finish()
		return
	_expect(int(inventory.call("add", "pickaxe", 1)) == 0, "Inventory accepted the existing pickaxe item")
	var pickaxe_slot := int(inventory.call("find_slot", "pickaxe"))
	_expect(pickaxe_slot >= 0, "pickaxe has an Inventory slot")
	if pickaxe_slot < 0:
		_finish()
		return
	game.set("equipped_tool", "pickaxe")
	_expect(str(game.get("equipped_tool")) == "pickaxe", "the live pickaxe is equipped")

	var world := FlatStormwoodWorld.new()
	world.name = "StormwoodHarvestSmokeFlatWorld"
	root.add_child(world)
	var chapter := ChapterStub.new()
	chapter.name = "StormwoodChapter"
	chapter.game = game
	world.add_child(chapter)
	var runtime := RUNTIME.new()
	runtime.name = "StormwoodHarvestRuntime"
	world.add_child(runtime)
	runtime.mount(world)
	await process_frame

	var placements: Dictionary = runtime.get("_placements")
	var node := placements.get(SITE_ID) as Node3D
	_expect(node != null, "the selected charged Cinder Verge site mounted")
	_expect(node != null and str(node.get_meta("stormwood_region", "")) == "cinder_verge", "selected node is a Verge site")
	_expect(node != null and str(node.get_meta("stormwood_item", "")) == ITEM_ID, "selected node is authored Stormglass")
	if node == null:
		world.queue_free()
		_finish()
		return

	var item_before := int(inventory.call("count", ITEM_ID))
	var durability_before := int(inventory.call("durability_at", pickaxe_slot))
	game.get("world").realm_environment = {"stormwood": {"elapsed": 0.0}}
	node.call("gather", "pickaxe")
	await process_frame
	_expect(is_instance_valid(node) and node.is_inside_tree(), "charged Verge seam remains during Calm")
	_expect(int(inventory.call("count", ITEM_ID)) == item_before, "Calm grants no Stormglass")
	_expect(int(inventory.call("durability_at", pickaxe_slot)) == durability_before, "Calm spends no pickaxe durability")

	game.get("world").realm_environment = {"stormwood": {"elapsed": 420.0}}
	node.call("gather", "pickaxe")
	await process_frame
	_expect(int(inventory.call("count", ITEM_ID)) == item_before + AUTHORED_AMOUNT, "Break grants exactly the authored Stormglass amount")
	_expect(int(inventory.call("durability_at", pickaxe_slot)) == durability_before - 1, "one successful gather spends exactly one pickaxe durability")
	_expect(game.get("progression").has(HARVEST_NODE.flag_id("order:" + SITE_ID)), "successful gather commits the stable world flag")
	_expect(not is_instance_valid(node) or not node.is_inside_tree(), "committed site is removed from the live world")

	# No direct runtime call: this waits for the normal half-second scan after
	# deferred node deletion, then for its next scan after chapter completion.
	await create_timer(0.7).timeout
	_expect(chapter.events.has("harvest:verge_stormglass"), "Verge Stormglass commit reaches StormwoodChapter naturally after node free")
	_expect(chapter.events.count("harvest:verge_stormglass") == 1, "first normal scan delivers one chapter event")
	await create_timer(0.7).timeout
	_expect(chapter.events.count("harvest:verge_stormglass") == 1, "second normal scan has no stale-node error or duplicate event")
	var repeat: Dictionary = game.get("ledger").call("submit", {
		"kind": "stormwood_harvest", "realm": "stormwood", "site_id": SITE_ID,
	})
	_expect(not bool(repeat.get("ok", false)) and str(repeat.get("code", "")) == "already_taken", "repeat authority claim is refused")
	_expect(int(inventory.call("count", ITEM_ID)) == item_before + AUTHORED_AMOUNT, "repeat gather cannot duplicate Stormglass")
	_expect(int(inventory.call("durability_at", pickaxe_slot)) == durability_before - 1, "repeat gather spends no additional durability")
	world.queue_free()
	_finish()


func _expect(condition: bool, label: String) -> void:
	_assertions += 1
	if not condition:
		_failures.append(label)


func _finish() -> void:
	if _assertions == 0:
		_failures.append("smoke aborted before any assertion")
	for failure: String in _failures:
		push_error("STORMWOOD HARVEST: " + failure)
	print("STORMWOOD HARVEST: %s (%d assertions)" % ["PASS" if _failures.is_empty() else "FAIL", _assertions])
	quit(0 if _failures.is_empty() else 1)
