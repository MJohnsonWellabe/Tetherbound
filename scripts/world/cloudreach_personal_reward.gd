extends Node3D

## A WORLD §11 personal activity payoff: one per eligible CHARACTER, once.
##
## `packs_on_the_wrong_side`: "one eligible personal small-potion×2 reward,
## once". A placed cache (`item_cache_pickup.gd`) is the wrong tool for that:
## its `claim_pickup` writes a WORLD flag and pays whichever peer arrives first,
## so in co-op one character takes the only copy. This claims through the
## ledger's `reward_grant` instead, the same host-authoritative, per-character
## delivery the Meadows herd visit uses (`meadowhart_herd_visit.gd`): every
## character standing here after the shared world flag holds gets their own
## receipt, and a character that has claimed never sees the offer again.
##
## The claimed flag must be player-scoped; `cloudreach_payout:` already is
## (`data/progression/flag_scopes.json`).

const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const LEDGER_CLAIM := preload("res://scripts/world/ledger_claim.gd")
const PICKUP_GLOW := preload("res://scripts/world/pickup_glow.gd")
const POLL_S := 0.25
## A claim the host never answers (a disconnect, a refusal that never reached
## this peer) must not leave a dead prompt on a visible offer forever. The
## ledger's own delivery reconcile still settles an escrowed grant on its own.
const CLAIM_TIMEOUT_S := 8.0

var spec: Dictionary = {}
var claims_paid := 0
var _prompt: Node3D
var _claiming := false
var _poll_left := 0.0
var _count_before := 0
var _claim_left := 0.0


func setup(reward: Dictionary) -> void:
	spec = reward.duplicate(true)
	_build_visual()
	_prompt = INTERACTABLE.new()
	_prompt.name = "Interactable"
	_prompt.position = Vector3.UP * 0.6
	_prompt.call("configure", str(spec.get("label", "Take the reward")), 2.4, true)
	_prompt.connect("activated", _on_activated)
	add_child(_prompt)
	add_to_group("progression_restore")
	LEDGER_CLAIM.listen(self, _on_delta_applied)
	_listen_for_refusals()
	_refresh()


func _ready() -> void:
	LEDGER_CLAIM.listen(self, _on_delta_applied)
	_listen_for_refusals()


func _process(delta: float) -> void:
	if _claiming:
		_claim_left -= delta
		if _claim_left <= 0.0:
			_claiming = false
			_refresh()
	_poll_left -= delta
	if _poll_left <= 0.0:
		_poll_left = POLL_S
		_refresh()


func restore_progression_from_game(_game: Node) -> void:
	_refresh()


## Offered only while the shared completion holds and THIS character has not
## claimed.
func offered() -> bool:
	var game := get_node_or_null(^"/root/Game")
	if game == null or spec.is_empty():
		return false
	var world_flags: RefCounted = game.get("progression")
	var unlock := str(spec.get("requires_unlock", ""))
	if world_flags == null or (not unlock.is_empty() and not bool(world_flags.call("has", unlock))):
		return false
	return not claimed(game)


func claimed(game: Node) -> bool:
	var local: Variant = game.get("local") if game != null else null
	var flags: Variant = (local as RefCounted).get("flags") if local != null else null
	return flags != null and bool((flags as RefCounted).call("has", str(spec.get("claimed_flag", ""))))


func _refresh() -> void:
	var show := offered()
	visible = show
	if _prompt != null and is_instance_valid(_prompt):
		_prompt.call("set_enabled", show and not _claiming)


func _on_activated() -> void:
	if _claiming or not offered():
		return
	var game := get_node_or_null(^"/root/Game")
	var inventory: RefCounted = game.get("inventory") if game != null else null
	var item := str(spec.get("item_id", ""))
	var count := int(spec.get("count", 1))
	if inventory == null or not bool(inventory.call("has_room_for", item, count)):
		if game != null:
			game.call("push_world_message", "Satchel is full.")
		return
	_count_before = int(inventory.call("count", item))
	_claiming = true
	_claim_left = CLAIM_TIMEOUT_S
	_refresh()
	var verdict := LEDGER_CLAIM.submit(self, {
		"kind": "reward_grant",
		"realm": "cloudreach",
		"source": str(spec.get("source", "")),
		"item": item,
		"count": count,
		"flag": str(spec.get("claimed_flag", "")),
	})
	if not LEDGER_CLAIM.in_flight(verdict):
		_claiming = false
		_refresh()


## Host, client and solo all arrive here; the player's own claimed flag is the
## acknowledgement that the delivery settled into this character.
func _on_delta_applied(_delta: Dictionary) -> void:
	if not _claiming:
		_refresh()
		return
	var game := get_node_or_null(^"/root/Game")
	if not claimed(game):
		return
	_claiming = false
	claims_paid += 1
	var inventory: RefCounted = game.get("inventory")
	if inventory != null and int(inventory.call("count", str(spec.get("item_id", "")))) \
			>= _count_before + int(spec.get("count", 1)):
		game.call("push_world_message", str(spec.get("acknowledgement", "")))
	_refresh()


func _on_intent_refused(kind: String, _code: String, _reason: String, _detail: Dictionary) -> void:
	if kind == "reward_grant" and _claiming:
		_claiming = false
		_refresh()


func _listen_for_refusals() -> void:
	var transport := LEDGER_CLAIM.transport(self)
	if transport != null and not transport.is_connected("intent_refused", _on_intent_refused):
		transport.connect("intent_refused", _on_intent_refused)


func _build_visual() -> void:
	var game := get_node_or_null(^"/root/Game")
	var definition: Dictionary = {}
	if game != null and game.get("items") != null:
		definition = game.get("items").call("definition", str(spec.get("item_id", "")))
	# An authored presentation (the couriers' thanks is a courier bag, the same
	# installed prop as Neri's pack) reads at plaza distance where a lone item
	# model does not; the item's own world model is the fallback.
	var path := str(spec.get("model", definition.get("world_model", "")))
	var visual: Node3D = null
	if path != "" and ResourceLoader.exists(path):
		var resource: Resource = load(path)
		if resource is PackedScene:
			visual = (resource as PackedScene).instantiate() as Node3D
		elif resource is Mesh:
			var mesh := MeshInstance3D.new()
			mesh.mesh = resource as Mesh
			visual = mesh
	if visual == null:
		var box := MeshInstance3D.new()
		box.mesh = BoxMesh.new()
		(box.mesh as BoxMesh).size = Vector3.ONE * 0.3
		visual = box
	visual.name = "RewardVisual"
	visual.scale *= float(spec.get("model_scale", definition.get("world_model_scale", 1.0)))
	add_child(visual)
	PICKUP_GLOW.attach(self, Color("#e7e0bb"))
