extends SceneTree

## OWNER-0912 Tier 0 #11: pressing a real Meadows pickup with a full satchel
## must leave both the satchel and the world find unchanged and visibly say
## "Satchel is full." Once a slot is freed, the same physical interaction must
## collect the find normally.
##
## Covers both production placement paths that `smoke_playground.gd`'s broad
## gather check cannot distinguish:
##   * `Cache_tm_rock_throw` -- playground_world.gd's world-cache table;
##   * `BandPickup_b1_candy_gate_meadow` -- band_pickups.gd's authored loader.
## Both are activated with the real `interact` input through InteractionArbiter,
## and the refusal is read from PlaygroundHUD's player-facing message label,
## never directly from Game's pending queue.
##
##   godot --headless --path . --script tests/smoke_meadows_inventory_full_pickups_0912.gd

const SCENE := preload("res://scenes/world/meadows_playground.tscn")
const CACHE := preload("res://scripts/world/item_cache_pickup.gd")

const WORLD_NODE := ^"Cache_tm_rock_throw"
const WORLD_ITEM := "tm_rock_throw"
const WORLD_FLAG := "cache:tm_rock_throw"
const BAND_NODE := ^"BandPickup_b1_candy_gate_meadow"
const BAND_ITEM := "good_candy"
const BAND_PLACEMENT := "b1_candy_gate_meadow"
const BAND_FLAG := "cache:b1_candy_gate_meadow"
const FILLER_ITEM := "axe" # stack size 1: every add occupies one real slot.
const FULL_MESSAGE := "Satchel is full."
const WORLD_READY_FRAMES := 1800
const OFFER_WAIT_FRAMES := 90
const RESULT_WAIT_FRAMES := 240

var _game: Node = null
var _world: Node3D = null
var _player: CharacterBody3D = null
var _arbiter: Node = null
var _message: Label = null
var _inventory: RefCounted = null
var _failures: Array[String] = []
var _receipts: Array[Dictionary] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	_game = root.get_node_or_null(^"Game")
	if not _require(_game != null, "Game autoload is missing"):
		_report()
		return

	# This is the same clean state as New Game, without touching save files.
	# Free-play suppresses the opening modal so the production arbiter owns the
	# physical interact presses this focused smoke sends.
	_game.call("reset_for_new_game")
	_game.get("progression").call("set_flag", "opening:beat:free_play")
	_world = SCENE.instantiate() as Node3D
	root.add_child(_world)

	for _frame in WORLD_READY_FRAMES:
		if _world.get_node_or_null(WORLD_NODE) != null \
				and _world.get_node_or_null(BAND_NODE) != null \
				and _world.get_node_or_null(^"PlaygroundHUD") != null:
			break
		await process_frame

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_arbiter = _world.get_node_or_null(^"InteractionArbiter")
	var hud := _world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	_message = hud.get_node_or_null(
		^"Root/BottomDock/HotbarPanel/Margin/Layout/Message") as Label if hud != null else null
	_inventory = _game.get("inventory") as RefCounted
	if not _require(_player != null and _arbiter != null and _message != null and _inventory != null,
			"production Meadows is missing Player, InteractionArbiter, HUD message, or inventory"):
		_report()
		return

	var world_pickup := _world.get_node_or_null(WORLD_NODE) as Node3D
	var band_pickup := _world.get_node_or_null(BAND_NODE) as Node3D
	if not _validate_pickup(world_pickup, WORLD_ITEM, "", WORLD_FLAG, "world cache"):
		_report()
		return
	if not _validate_pickup(band_pickup, BAND_ITEM, BAND_PLACEMENT, BAND_FLAG, "band pickup"):
		_report()
		return
	if not _require(int(_inventory.call("count", WORLD_ITEM)) == 0
			and int(_inventory.call("count", BAND_ITEM)) == 0,
			"New Game fixture unexpectedly already owns one of the pickup rewards"):
		_report()
		return
	if not _fill_satchel():
		_report()
		return

	if not await _prove_full_then_recover(world_pickup, WORLD_ITEM, 1, WORLD_FLAG,
			"world cache"):
		_report()
		return
	# The freed slot was consumed by the successful world pickup, so the real
	# satchel is full again for the independent band-placement refusal.
	if not _require(bool(_inventory.call("is_full")),
			"successful world pickup did not consume the recovered satchel slot"):
		_report()
		return
	if not await _prove_full_then_recover(band_pickup, BAND_ITEM, 1, BAND_FLAG,
			"band pickup"):
		_report()
		return

	_report()


func _validate_pickup(pickup: Node3D, item_id: String, placement_id: String,
		expected_flag: String, label: String) -> bool:
	if not _require(pickup != null, "%s node is absent from the production world" % label):
		return false
	var prompt := pickup.get_node_or_null(^"Interactable") as Node3D
	if not _require(pickup.get_script() == CACHE and prompt != null,
			"%s is not mounted through item_cache_pickup.gd with its real prompt" % label):
		return false
	if not _require(str(pickup.get("_item_id")) == item_id
			and str(pickup.get("_placement_id")) == placement_id
			and int(pickup.get("_count")) == 1,
			"%s no longer carries its expected item/placement/count identity" % label):
		return false
	if not _require(CACHE.flag_id(item_id, placement_id, "meadows") == expected_flag,
			"%s persistence flag does not match its production key" % label):
		return false
	return _require(not bool(_game.get("progression").call("has", expected_flag)),
		"%s began already consumed despite the New Game fixture" % label)


func _fill_satchel() -> bool:
	var guard := int(_inventory.call("slot_count")) + 1
	while not bool(_inventory.call("is_full")) and guard > 0:
		var leftover := int(_inventory.call("add", FILLER_ITEM, 1))
		if leftover != 0:
			return _require(false, "production inventory refused an Axe before reporting full")
		guard -= 1
	if not _require(bool(_inventory.call("is_full")),
			"could not fill the real satchel through Inventory.add"):
		return false
	return _require(not bool(_inventory.call("has_room_for", WORLD_ITEM, 1))
			and not bool(_inventory.call("has_room_for", BAND_ITEM, 1)),
		"full fixture still has stack room for a representative pickup")


func _prove_full_then_recover(pickup: Node3D, item_id: String, count: int,
		flag: String, label: String) -> bool:
	var prompt := pickup.get_node_or_null(^"Interactable") as Node3D
	var full_snapshot := _satchel_snapshot()
	var item_before := int(_inventory.call("count", item_id))
	_clear_message_surface()
	if not await _stage_exact_offer(prompt):
		return _require(false, "%s did not own an actionable production prompt" % label)
	await _tap_interact()

	var surfaced := false
	for _frame in RESULT_WAIT_FRAMES:
		if _message.visible and _message.text == FULL_MESSAGE:
			surfaced = true
			break
		await process_frame
	if not _require(surfaced,
			"%s full-satchel press did not visibly surface '%s' (text='%s', visible=%s)" % [
				label, FULL_MESSAGE, _message.text, _message.visible]):
		return false
	if not _require(_satchel_snapshot() == full_snapshot
			and int(_inventory.call("count", item_id)) == item_before,
			"%s full-satchel refusal changed inventory contents" % label):
		return false
	if not _require(is_instance_valid(pickup) and pickup.is_inside_tree() and pickup.visible
			and not bool(pickup.get("_taken")) and not bool(pickup.get("_claiming")),
			"%s vanished or began a claim despite the full satchel" % label):
		return false
	if not _require(not bool(_game.get("progression").call("has", flag)),
			"%s full-satchel refusal consumed its one-time world flag" % label):
		return false

	# Capacity recovery uses the normal all-or-nothing Inventory.remove API.
	# The same still-standing node must now be physically collectible.
	if not _require(bool(_inventory.call("remove", FILLER_ITEM, 1))
			and bool(_inventory.call("has_room_for", item_id, count)),
			"removing one filler did not recover capacity for %s" % label):
		return false
	_clear_message_surface()
	if not await _stage_exact_offer(prompt):
		return _require(false, "%s stopped offering after capacity recovery" % label)
	await _tap_interact()

	var collected := false
	for _frame in RESULT_WAIT_FRAMES:
		if bool(_game.get("progression").call("has", flag)) \
				and int(_inventory.call("count", item_id)) == item_before + count:
			collected = true
			break
		await process_frame
	if not _require(collected,
			"%s did not grant its item and durable flag after capacity recovery" % label):
		return false
	for _frame in 8:
		await process_frame
	if not _require(not is_instance_valid(pickup) or not pickup.is_inside_tree(),
			"%s remained in the world after its successful production claim" % label):
		return false

	_receipts.append({
		"path": label,
		"item": item_id,
		"count": count,
		"flag": flag,
		"full_message": FULL_MESSAGE,
		"inventory_unchanged_while_full": true,
		"collected_after_capacity_recovery": true,
	})
	return true


func _stage_exact_offer(prompt: Node3D) -> bool:
	if prompt == null or not is_instance_valid(prompt):
		return false
	# Adjacent world caches exist on the Rise. Try four arm's-reach seats and
	# accept only the one where the live arbiter names this exact prompt.
	var offsets: Array[Vector3] = [
		Vector3(0.0, 0.0, -1.1), Vector3(1.1, 0.0, 0.0),
		Vector3(0.0, 0.0, 1.1), Vector3(-1.1, 0.0, 0.0),
	]
	var frames_per_offset := maxi(1,
		ceili(float(OFFER_WAIT_FRAMES) / float(offsets.size())))
	for offset: Vector3 in offsets:
		var at := prompt.global_position + offset
		at.y = float(_world.call("ground_height_at", at.x, at.z)) + 1.0
		_player.global_position = at
		_player.velocity = Vector3.ZERO
		_player.reset_physics_interpolation()
		for _frame in frames_per_offset:
			await process_frame
			if bool(_arbiter.call("enabled")) \
					and _arbiter.call("winning_provider") == prompt \
					and bool((_arbiter.call("winner") as Dictionary).get("actionable", false)):
				return true
	return false


func _tap_interact() -> void:
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	await physics_frame


func _clear_message_surface() -> void:
	_game.call("take_pending_world_message")
	_message.text = ""
	_message.visible = false


func _satchel_snapshot() -> Array:
	var result: Array = []
	for index in int(_inventory.call("slot_count")):
		result.append(_inventory.call("stack_at", index))
	return result


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_failures.append(message)
	return false


func _report() -> void:
	Input.action_release("interact")
	print("")
	if _failures.is_empty():
		print("meadows inventory-full pickup receipts: " + JSON.stringify(_receipts))
		print("meadows inventory-full pickups: OK -- world and band finds stayed put with clear full-satchel feedback, then collected after one slot was recovered.")
		quit(0)
		return
	for failure: String in _failures:
		print("meadows inventory-full pickups FAIL: " + failure)
	quit(1)
