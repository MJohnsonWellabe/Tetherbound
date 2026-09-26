extends Node3D

## Doss's existing wood-and-fiber request repairs a visible river-bank perch.
## The original world flags and personal reward remain save-compatible.

const NPC := preload("res://scripts/npc/npc_body.gd")
const VILLAGE_NPCS := preload("res://scripts/world/village_npcs.gd")
const ITEM_GATE := preload("res://scripts/world/item_gate.gd")
const PREFABS := preload("res://scripts/world/building_prefabs.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const GRASS_FIELD := preload("res://scripts/world/grass_field.gd")
## Stage B lane 5.A. A cleared nest is a WORLD fact.
const STORY_LEDGER := preload("res://scripts/story/story_ledger.gd")
const LEDGER_CLAIM := preload("res://scripts/world/ledger_claim.gd")
const SATCHEL_RULES := preload("res://scripts/world/death_satchel_rules.gd")

const ITEM_IDS := ["wood", "fiber"]
const FLAG_ID := "river_nest_doss_cleared"
const MET_FLAG := "river_nest_doss_met"
const BLOCKED_CONVERSATION := "river_nest_doss_challenge"
const CLEARED_CONVERSATION := "river_nest_doss_defeated"

const REWARD_COINS := 45
const REWARD_ITEM_ID := "potion_large"
const REWARD_ITEM_COUNT := 1

var _spec := {
	"name": "Doss",
	"config_key": "villager_ranger",
	"hair": {"visible": true, "color": "#4a5c3d"},
}

var _gate: RefCounted = null
var _prompt: Node3D = null
var _perch: Node3D = null
var _perch_floor: CollisionShape3D = null
var _broken_roll := 16.0
var _claim_pending := false


func build(world: Node3D, player: Node3D, at: Vector2, facing_deg: float) -> void:
	_gate = ITEM_GATE.new(ITEM_IDS, FLAG_ID)

	var npc: Node3D = NPC.new()
	npc.name = "Doss"
	add_child(npc)
	if not bool(npc.call("setup_from_config", VILLAGE_NPCS.model_config(_spec), player)):
		push_error("river nest: no model for Doss's config key; nothing will stand there")
		return
	if not bool(npc.call("stand_at", at.x, at.y)):
		push_error("no ground under Doss at %.0f, %.0f" % [at.x, at.y])
		return
	npc.rotation.y = deg_to_rad(facing_deg)

	_prompt = npc.call("add_prompt", "Greet Doss")
	_prompt.connect("activated", _on_greeted)
	_build_perch(world, at, facing_deg)

	# Stage B lane 5.A: a cleared nest is a WORLD fact (D99). The pose is
	# restored from the world's store and re-checked when a delta lands, so a
	# nest the other player cleared reads as cleared here too.
	add_to_group("progression_restore")
	STORY_LEDGER.listen(self, _on_delta_applied)
	var transport := LEDGER_CLAIM.transport(self)
	if transport != null and transport.has_signal("intent_refused") \
			and not transport.is_connected("intent_refused", _on_intent_refused):
		transport.connect("intent_refused", _on_intent_refused)
	restore_progression_from_game(get_node_or_null(^"/root/Game"))


func is_cleared() -> bool:
	return STORY_LEDGER.world_flag(self, FLAG_ID)


## The `progression_restore` seam: a save load, a joiner's snapshot, or another
## peer's delta. Idempotent.
func restore_progression_from_game(_game: Node) -> void:
	var cleared := is_cleared()
	if _prompt != null and is_instance_valid(_prompt):
		_prompt.call("set_enabled", true)
		_prompt.set("label", "Greet Doss" if cleared else "Help Doss repair the bank perch")
	if _perch != null:
		_perch.set_meta("repaired", cleared)
		for index in _perch.get_child_count():
			var part := _perch.get_child(index) as Node3D
			if part != null and not part is StaticBody3D:
				part.rotation.z = 0.0 if cleared else deg_to_rad(_broken_roll * (1.0 if index % 2 == 0 else -1.0))
	if _perch_floor != null:
		_perch_floor.set_deferred("disabled", not cleared)


func _on_delta_applied(delta: Dictionary) -> void:
	if STORY_LEDGER.delta_sets_world_flag(delta, FLAG_ID):
		restore_progression_from_game(get_node_or_null(^"/root/Game"))
		if _claim_pending and _delta_rewards_local_player(delta):
			_claim_pending = false
			_say(CLEARED_CONVERSATION)


func _on_greeted() -> void:
	if is_cleared():
		# The claim's world flag can land before its delta reaches
		# `_on_delta_applied` (host/solo commit first, then emit). A greeting in
		# that gap already shows the thanks, so the pending claim is settled
		# here -- otherwise the late delta said it a second time, reopening the
		# conversation right after the player closed it (the Doss
		# repeat-greeting flake in smoke_local_requests).
		_claim_pending = false
		_say(CLEARED_CONVERSATION)
		return
	if _claim_pending:
		return
	var game := get_node_or_null(^"/root/Game")
	var inventory: RefCounted = game.get("inventory") if game != null else null
	# Meeting Doss is a world fact (`river_nest_doss_met`), so it is committed
	# rather than written locally.
	STORY_LEDGER.write_flag(self, MET_FLAG)
	if inventory == null or not _gate.can_open(inventory):
		_say(BLOCKED_CONVERSATION)
		return
	if not reward_fits_after_cost(inventory):
		_say("river_nest_doss_satchel_full")
		return
	_claim_pending = true
	var verdict := LEDGER_CLAIM.submit(self, {
		"kind": "river_nest_clear", "realm": "meadows",
		"inventory_slots": claim_slots(inventory),
	})
	if not bool(verdict.get("ok", false)) and not bool(verdict.get("pending", false)):
		_claim_pending = false
		_say("river_nest_doss_satchel_full" if str(verdict.get("code", "")) == "no_room" \
			else BLOCKED_CONVERSATION)
		return
	# Host/solo commits synchronously and clients settle after the same addressed
	# delta arrives. No pending request spends or pays locally.


func _on_intent_refused(kind: String, code: String, _reason: String,
		_details: Dictionary) -> void:
	if kind != "river_nest_clear" or not _claim_pending:
		return
	_claim_pending = false
	_say("river_nest_doss_satchel_full" if code == "no_room" else BLOCKED_CONVERSATION)


func _delta_rewards_local_player(delta: Dictionary) -> bool:
	var game := get_node_or_null(^"/root/Game")
	var local: Variant = game.get("local") if game != null else null
	var character_id := str((local as RefCounted).get("character_id")) if local != null else ""
	if character_id.is_empty():
		return false
	for raw: Variant in (delta.get("ops", []) as Array):
		if not raw is Dictionary or str((raw as Dictionary).get("op", "")) != "reward_delivery":
			continue
		var delivery: Variant = (raw as Dictionary).get("delivery", {})
		if delivery is Dictionary \
				and str((delivery as Dictionary).get("character_id", "")) == character_id \
				and str((delivery as Dictionary).get("source", "")).begins_with("river_nest_doss:"):
			return true
	return false


static func reward_fits_after_cost(inventory: RefCounted) -> bool:
	if inventory == null:
		return false
	var trial := INVENTORY.new(inventory.get("_db"))
	for index in int(inventory.call("slot_count")):
		trial.set_slot(index, inventory.call("stack_at", index))
	for item: String in ITEM_IDS:
		if not trial.remove(item, 1):
			return false
	return trial.add("coin", REWARD_COINS) == 0 \
		and trial.add(REWARD_ITEM_ID, REWARD_ITEM_COUNT) == 0


static func claim_slots(inventory: RefCounted) -> Array:
	return SATCHEL_RULES.slots(inventory) if inventory != null else []


func _build_perch(world: Node3D, at: Vector2, facing_deg: float) -> void:
	var prefabs := PREFABS.new()
	if not prefabs.load_recipes():
		return
	var templates := Node3D.new()
	templates.name = "PerchTemplates"
	templates.visible = false
	add_child(templates)
	prefabs.set_template_holder(templates)
	var recipe := prefabs.recipe("river_bank_perch")
	var presentation: Dictionary = recipe.get("presentation", {})
	var offset: Array = presentation.get("offset", [-4.0, 0.0, 3.0])
	var local_offset := Basis(Vector3.UP, deg_to_rad(facing_deg)) * Vector3(
		float(offset[0]), float(offset[1]), float(offset[2]))
	var x := at.x + local_offset.x
	var z := at.y + local_offset.z
	var ground := float(world.call("ground_height_at", x, z))
	if is_nan(ground):
		push_error("Doss's bank perch has no supported ground")
		return
	_perch = prefabs.instantiate("river_bank_perch")
	if _perch == null:
		return
	_perch.name = "BankPerch"
	add_child(_perch)
	_perch.position = Vector3(x, ground, z)
	_perch.rotation.y = deg_to_rad(facing_deg)
	_perch.set_meta(GRASS_FIELD.CLEAR_RADIUS_META, 2.75)
	_perch.add_to_group(GRASS_FIELD.CLEAR_GROUP)
	_broken_roll = float(presentation.get("broken_roll_deg", 16.0))
	var body := StaticBody3D.new()
	body.name = "RepairedPerchFloor"
	_perch.add_child(body)
	_perch_floor = CollisionShape3D.new()
	_perch_floor.name = "CollisionShape3D"
	var floor_shape := BoxShape3D.new()
	var collider: Dictionary = (recipe.get("colliders", []) as Array)[0]
	var size: Array = collider.get("size", [4.0, 0.2, 2.0])
	floor_shape.size = Vector3(float(size[0]), float(size[1]), float(size[2]))
	_perch_floor.shape = floor_shape
	var floor_at: Array = collider.get("at", [0.0, 0.1, 0.0])
	_perch_floor.position = Vector3(float(floor_at[0]), float(floor_at[1]), float(floor_at[2]))
	_perch_floor.disabled = true
	body.add_child(_perch_floor)


func _say(conversation_id: String) -> void:
	var panel := get_tree().get_first_node_in_group("dialogue_panel")
	if panel == null:
		push_warning("no node in the 'dialogue_panel' group; Doss has nothing to say")
		return
	if bool(panel.call("is_open")):
		return
	panel.call("start", conversation_id)
