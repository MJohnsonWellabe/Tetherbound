extends Node3D

## `stormwood_glass_for_bryn`: Warden-Elect Bryn asks for ordinary Stormglass
## and Conductor Vine to re-insulate the rod crew's shelter beside the Rodline
## workshop; the player hands them over once, inspects the repaired supplies at
## the shelter, and the shelter becomes a safe care point with one creature bed.
##
## Every fact is WORLD-scoped (the chapter's own step scopes): the shelter is a
## shared place, so one delivery repairs it for everyone in this world and a
## second character is never charged again. The delivery is the one
## transaction, and the host owns it: a peer asks through the Stormwood
## encounter channel, the host checks Bryn's stance, the chain order and the
## requester's reported materials, then commits the step flag and the
## requester's `item_take`s as ONE delta, journals the world before publishing
## it, and rolls the whole commit back if the journal fails. A repeated or
## raced request finds the step already set and takes nothing.
##
## The payoff reuses `rest_point.gd` (the same rest offer every camp makes) and
## its authored creature bed at a reserved index. It adds no lightning rod to
## the camp rod list, writes no rod flag and never touches the Surge: Rodline
## Post is already a Surge safe zone and Conductor Run has no rod flag, so the
## mandatory rod disable and its Calm multiplier stay the only ones.
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const LEDGER_CLAIM := preload("res://scripts/world/ledger_claim.gd")
const REST_POINT := preload("res://scripts/world/rest_point.gd")
const RUNNER := preload("res://scripts/story/dialogue_runner.gd")
const PYLON_MATERIALS := preload("res://scripts/world/tether_pylon_materials.gd")

const CONFIG_PATH := "res://data/config/stormwood_glass_for_bryn.json"
const CHAIN := "stormwood_glass_for_bryn"
const REVEALED := "stormwood:bryn_met"
const STEP_1 := "stormwood:side_glass_for_bryn_1"
const STEP_2 := "stormwood:side_glass_for_bryn_2"
const COMPLETE := "stormwood:side_glass_for_bryn_complete"
## World-scoped (the `stormwood:` prefix): Bryn has given the acknowledgement,
## so he returns to his ordinary lines. Chooses a greeting only.
const THANKED := "stormwood:side_glass_for_bryn_thanked"
const BRYN := "warden_elect_bryn"
const OFFER := "stormwood_bryn_glass_offer"
const REQUEST := "stormwood_bryn_glass_request"
const INSPECT_HINT := "stormwood_bryn_glass_inspect"
const THANKS := "stormwood_bryn_glass_thanks"
const DELIVERY_KIND := "bryn_glass_delivery"
const DELIVERED_KIND := "bryn_glass_delivered"
const REFUSED_KIND := "bryn_glass_refused"
## A lost reply must not wedge the request forever. A retry is always safe: the
## host refuses once the step is set.
const REQUEST_TIMEOUT_S := 10.0
const MODEL_PATHS := {
	"tent": "res://assets/props/generated_camp/camp_tent.glb",
	"lightning_rod": "res://assets/environment/team_tether/tether_pylon.glb",
	"crate": "res://assets/props/quaternius_fantasy/Crate_Wooden.gltf",
}
const PORTRAIT := "res://assets/ui/portraits/villager_male.png"

var world: Node3D
var game: Node
var shelter: Node3D
var supplies: Node3D
var inspect_prompt: Node3D
var care_point: Node3D
var _revision := -1
var _delivering := false
var _delivery_wait := 0.0


static func config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	return parsed if parsed is Dictionary else {}


static func cost() -> Dictionary:
	var out := {}
	var raw: Dictionary = config().get("cost", {})
	for item: String in raw:
		out[item] = int(raw[item])
	return out


static func shelter_at() -> Vector2:
	var at: Array = config().shelter.at
	return Vector2(float(at[0]), float(at[1]))


static func bed_index() -> int:
	return int(config().shelter.creature_bed.bed_index)


## Greeting branches to put in front of Bryn's normal ones, in priority order.
static func branches_for(actor_id: String) -> Array:
	if actor_id != BRYN:
		return []
	return [
		{"if_flag": COMPLETE, "unless_flag": THANKED, "conversation": THANKS},
		{"if_flag": STEP_2, "unless_flag": COMPLETE, "conversation": INSPECT_HINT},
		{"if_flag": STEP_1, "unless_flag": STEP_2, "conversation": REQUEST},
		{"if_flag": REVEALED, "unless_flag": STEP_1, "conversation": OFFER},
	]


## Bryn's authored lines for this chain, registered beside the realm's
## conversations when the chain mounts.
static func conversations() -> Dictionary:
	var speaker := "Warden-Elect Bryn"
	return {
		OFFER: {"speaker": speaker, "portrait": PORTRAIT, "state": "side_offer",
			"requires_flags": [REVEALED], "lines": [
				"Warden-Elect Bryn: The rod crews sleep in a shelter behind the workshop, and every strike on the post has cracked its insulators.",
				"Three pieces of ordinary Stormglass and two lengths of Conductor Vine would re-wrap it. Bring them to me here and my crew will do the rest.",
			]},
		REQUEST: {"speaker": speaker, "portrait": PORTRAIT, "state": "side_progress",
			"requires_flags": [STEP_1], "lines": [
				"Warden-Elect Bryn: Three Stormglass and two Conductor Vine. Glass seams glitter on the open ridges; the vine grows on the copper-scarred trunks.",
				"If you are carrying them, they go straight to the crew. Varga still holds the bridge, and Keeper Ondra waits at the Still Grove.",
			]},
		INSPECT_HINT: {"speaker": speaker, "portrait": PORTRAIT, "state": "side_progress",
			"requires_flags": [STEP_2], "lines": [
				"Warden-Elect Bryn: The crew is wrapping the glass now. Go and look at the supplies by the rod shelter behind the workshop.",
				"If the seams hold, the shelter is yours to use as much as ours.",
			]},
		THANKS: {"speaker": speaker, "portrait": PORTRAIT, "state": "side_return",
			"requires_flags": [COMPLETE], "lines": [
				"Warden-Elect Bryn: The shelter held through the last Break without a spark inside. The crew has laid a creature bed under its roof.",
				"Rest there whenever the post is on your road. The rod line is still yours to break; we only keep the roof dry.",
			]},
	}


## Host rule for one delivery request. Pure so the unit suite proves the same
## order, stance and material checks the host runs. `position` is the host's
## own view of the requester's trainer, never a value from the request.
static func evaluate_delivery(intent: Dictionary, position: Variant, flags: RefCounted) -> Dictionary:
	var data := config()
	if flags == null:
		return _refusal("not_ready", "The Rodline Post is not ready yet.")
	if bool(flags.call("has", STEP_2)):
		return _refusal("already_delivered", "Bryn's crew already has the glass and vine.")
	if not bool(flags.call("has", STEP_1)):
		return _refusal("not_asked", "Ask Bryn what the rod crews need first.")
	var bryn: Dictionary = data.bryn
	var centre := Vector2(float(bryn.at[0]), float(bryn.at[1]))
	if not position is Vector3 or not (position as Vector3).is_finite() \
			or Vector2((position as Vector3).x, (position as Vector3).z).distance_to(centre) > float(bryn.delivery_radius_m):
		return _refusal("too_far", "Stand with Bryn to hand over the materials.")
	var needed := cost()
	for item: String in needed:
		var carried: Variant = intent.get(item, 0)
		if not (carried is int or carried is float) or not is_finite(float(carried)) \
				or float(carried) < float(needed[item]):
			return _refusal("materials", material_sentence())
	return {"ok": true, "code": "", "reason": ""}


static func take_ops(peer: int) -> Array:
	var ops: Array = []
	var needed := cost()
	for item: String in needed:
		ops.append({"op": "item_take", "scope": "player", "peers": [peer],
			"item": item, "count": int(needed[item])})
	return ops


## What this inventory lacks, item -> missing count; empty when it can pay.
static func missing_from(inventory: RefCounted) -> Dictionary:
	var out := {}
	var needed := cost()
	for item: String in needed:
		var have := int(inventory.call("count", item)) if inventory != null else 0
		if have < int(needed[item]):
			out[item] = int(needed[item]) - have
	return out


static func material_sentence() -> String:
	return "Bryn needs 3 Stormglass and 2 Conductor Vine for the rod shelter."


static func _refusal(code: String, reason: String) -> Dictionary:
	return {"ok": false, "code": code, "reason": reason}


func mount(owner_world: Node3D) -> void:
	world = owner_world
	game = get_node_or_null("/root/Game")
	add_to_group("progression_restore")
	var authored := conversations()
	for id: String in authored:
		RUNNER.table()[id] = (authored[id] as Dictionary).duplicate(true)
	# A realm shell still arbitrates remote requests, but draws nothing.
	if not bool(world.get("simulation_only")):
		_build_shelter()
		var panel := world.get_node_or_null("DialoguePanel")
		if panel != null and panel.has_signal("completed"):
			panel.connect("completed", _dialogue_completed)
	restore_progression_from_game(game)


func _process(delta: float) -> void:
	if game == null:
		return
	if _delivering:
		_delivery_wait -= delta
		if _delivery_wait <= 0.0:
			_delivering = false
	if int(game.get("progression").get("revision")) != _revision:
		restore_progression_from_game(game)


func restore_progression_from_game(_game: Node) -> void:
	if game == null:
		return
	var flags: RefCounted = game.get("progression")
	_revision = int(flags.get("revision"))
	var delivered := bool(flags.call("has", STEP_2))
	var complete := bool(flags.call("has", COMPLETE))
	if delivered:
		_delivering = false
	if supplies != null:
		supplies.visible = delivered
	if inspect_prompt != null:
		inspect_prompt.set("enabled", delivered and not complete)
	if complete and care_point == null and shelter != null:
		_build_care_point()


# --- dialogue --------------------------------------------------------------------

## Only a conversation read to its last line counts: closing Bryn early is not
## agreeing to anything.
func _dialogue_completed(conversation_id: String) -> void:
	match conversation_id:
		OFFER:
			_emit("side:%s:step_1" % CHAIN)
		REQUEST:
			request_delivery()
		THANKS:
			if not bool(game.get("progression").call("has", THANKED)):
				LEDGER_CLAIM.submit(self, {"kind": "set_world_flag", "realm": "stormwood",
					"id": THANKED, "value": true})
	restore_progression_from_game(game)


func _emit(event: String) -> void:
	var chapter := world.get_node_or_null("StormwoodChapter")
	if chapter != null:
		chapter.call("emit_event", event)


# --- the delivery ----------------------------------------------------------------

## Ask the host to take the materials. Nothing changes locally until the host's
## delta arrives; a second press while one is in flight asks nothing.
func request_delivery() -> bool:
	if _delivering or game == null:
		return false
	var flags: RefCounted = game.get("progression")
	if bool(flags.call("has", STEP_2)) or not bool(flags.call("has", STEP_1)):
		return false
	var inventory: RefCounted = game.get("inventory")
	var missing := missing_from(inventory)
	if not missing.is_empty():
		game.call("push_world_message", "%s You carry %d Stormglass and %d Conductor Vine." % [
			material_sentence(), int(inventory.call("count", "stormglass")),
			int(inventory.call("count", "conductor_vine"))])
		return false
	_delivering = true
	_delivery_wait = REQUEST_TIMEOUT_S
	var intent := {"kind": DELIVERY_KIND}
	for item: String in cost():
		intent[item] = int(inventory.call("count", item))
	var session := get_node_or_null("/root/Game/Session")
	if session != null and _hub() != null:
		session.call("request_stormwood_encounter", intent)
	else:
		# A bare fixture with no Session transport is its own host.
		dispatch(1, intent)
	return true


## Host entry point, routed by `stormwood_encounter_hub.gd` for the
## authenticated sender.
func dispatch(peer: int, intent: Dictionary) -> void:
	if str(intent.get("kind", "")) != DELIVERY_KIND:
		return
	var result := host_commit(peer, intent)
	if bool(result.get("ok", false)):
		_reply(peer, {"kind": DELIVERED_KIND})
	else:
		_reply(peer, {"kind": REFUSED_KIND, "code": str(result.get("code", "")),
			"reason": str(result.get("reason", ""))})


## Validate and commit one delivery for `peer`, then publish it.
func host_commit(peer: int, intent: Dictionary) -> Dictionary:
	if game == null:
		return _refusal("not_ready", "The Rodline Post is not ready yet.")
	var transport: Node = game.get("ledger") as Node
	var ledger: RefCounted = transport.get("ledger") as RefCounted if transport != null else null
	var result := commit_delivery(game, ledger, peer, intent, _actor_position(peer))
	if bool(result.get("ok", false)):
		transport.call("publish_journaled_delta", result.delta)
	return result


## The host transaction, without publication. One delta carries the step flag
## and the requester's takes; the world is journaled before anyone sees it,
## and a refusal or failed journal restores the world and sequence first.
static func commit_delivery(host: Object, ledger: RefCounted, peer: int, intent: Dictionary,
		position: Variant) -> Dictionary:
	if host == null or not host.has_method("is_host") or not bool(host.call("is_host")):
		return _refusal("not_host", "Only the host can record Bryn's delivery.")
	var state: RefCounted = host.get("world") as RefCounted
	if ledger == null or state == null or ledger.get("world") != state:
		return _refusal("not_ready", "The Rodline Post is not ready yet.")
	var rule := evaluate_delivery(intent, position, state.get("flags") as RefCounted)
	if not bool(rule.ok):
		return rule
	var world_id := str(state.get("world_id"))
	var saver: RefCounted = host.get("save_system") as RefCounted
	if world_id.is_empty() or saver == null:
		return _refusal("journal_failed", "The world cannot save Bryn's delivery. Your materials remain safe.")
	var before: Dictionary = state.call("save_data")
	var before_revision := int(state.get("revision"))
	var before_sequence := int(ledger.get("seq"))
	var verdict: Dictionary = ledger.call("commit", {"kind": "set_world_flag", "realm": "stormwood",
		"id": STEP_2, "value": true}, 1)
	var ops: Array = ((verdict.get("delta", {}) as Dictionary).get("ops", []) as Array).duplicate(true)
	if not bool(verdict.get("ok", false)) or ops.is_empty():
		_restore(state, ledger, before, before_revision, before_sequence)
		return _refusal("ledger_refused", "Bryn's crew could not take the delivery. Try again.")
	if not bool(saver.call("save_world", host, world_id)):
		_restore(state, ledger, before, before_revision, before_sequence)
		return _refusal("journal_failed", "The world could not save Bryn's delivery. Your materials remain safe.")
	ops.append_array(take_ops(peer))
	return {"ok": true, "code": "", "reason": "",
		"delta": {"seq": int(ledger.get("seq")), "realm": "stormwood", "ops": ops}}


static func _restore(state: RefCounted, ledger: RefCounted, before: Dictionary,
		before_revision: int, before_sequence: int) -> void:
	state.call("load_data", before)
	state.set("revision", before_revision)
	ledger.set("seq", before_sequence)


func _actor_position(peer: int) -> Variant:
	var hub := _hub()
	if hub != null:
		var actor: Variant = hub.call("actor_for", peer)
		return (actor as Node3D).global_position if actor is Node3D and is_instance_valid(actor) else null
	if peer == 1 and not bool(world.get("simulation_only")):
		var player := world.get_node_or_null("Player") as Node3D
		return player.global_position if player != null else null
	return null


func _hub() -> Node:
	if world == null:
		return null
	return world.get_node_or_null("StormwoodEncounterHub")


func _reply(peer: int, event: Dictionary) -> void:
	var hub := _hub()
	if hub != null:
		hub.call("send_to", peer, event)
	elif peer == 1:
		receive(event)


## Host -> requester answer, routed by the encounter hub.
func receive(event: Dictionary) -> void:
	match str(event.get("kind", "")):
		DELIVERED_KIND:
			_delivering = false
			game.call("push_world_message",
				"Bryn's crew takes 3 Stormglass and 2 Conductor Vine to re-wrap the rod shelter.")
		REFUSED_KIND:
			_delivering = false
			var reason := str(event.get("reason", ""))
			if not reason.is_empty():
				game.call("push_world_message", reason)
	restore_progression_from_game(game)


func delivering() -> bool:
	return _delivering


# --- the shelter -------------------------------------------------------------------

func _build_shelter() -> void:
	var data: Dictionary = config().shelter
	var at := shelter_at()
	shelter = Node3D.new()
	shelter.name = "RodShelter"
	add_child(shelter)
	for prop: Dictionary in data.props:
		_prop(shelter, prop, at)
	supplies = Node3D.new()
	supplies.name = "RepairedSupplies"
	supplies.visible = false
	shelter.add_child(supplies)
	for prop: Dictionary in data.supplies:
		_prop(supplies, prop, at)
	var inspect: Dictionary = data.inspect
	inspect_prompt = INTERACTABLE.new()
	inspect_prompt.name = "InspectInteractable"
	shelter.add_child(inspect_prompt)
	inspect_prompt.global_position = _grounded(at + _offset(inspect.offset)) + Vector3.UP * 0.6
	inspect_prompt.call("configure", str(inspect.label), float(inspect.radius_m), false)
	inspect_prompt.connect("activated", _inspect)


func _prop(parent: Node3D, prop: Dictionary, at: Vector2) -> void:
	var model := str(prop.model)
	var instance := (load(str(MODEL_PATHS[model])) as PackedScene).instantiate() as Node3D
	instance.name = model
	parent.add_child(instance)
	instance.global_position = _grounded(at + _offset(prop.offset))
	instance.rotation.y = deg_to_rad(float(prop.get("yaw_deg", 0.0)))
	if model == "lightning_rod":
		# The same drained, unpowered finish the camp rods wear.
		PYLON_MATERIALS.apply(instance, false)
		instance.scale = Vector3.ONE * 0.55
	elif prop.has("scale"):
		instance.scale = Vector3.ONE * float(prop.scale)


func _grounded(at: Vector2) -> Vector3:
	return Vector3(at.x, float(world.call("ground_height_at", at.x, at.y)), at.y)


static func _offset(raw: Array) -> Vector2:
	return Vector2(float(raw[0]), float(raw[1]))


func _inspect() -> void:
	var flags: RefCounted = game.get("progression")
	if not bool(flags.call("has", STEP_2)) or bool(flags.call("has", COMPLETE)):
		return
	_emit("side:%s:step_3" % CHAIN)
	restore_progression_from_game(game)


## The payoff: the shared rest offer and one authored creature bed, reused.
func _build_care_point() -> void:
	var data: Dictionary = config().shelter
	var at := shelter_at()
	var bed: Dictionary = (data.creature_bed as Dictionary).duplicate(true)
	var bed_xz := at + _offset(bed.offset)
	bed["at"] = [bed_xz.x, bed_xz.y]
	var care: Dictionary = data.care
	care_point = REST_POINT.new()
	care_point.name = "CarePoint"
	# RestPoint samples ground through its parent chain; the world owns it.
	add_child(care_point)
	care_point.call("build", {"at": [at.x, at.y], "label": str(care.label),
		"radius": float(care.radius_m), "craft": false, "creature_bed": bed})
	# RestPoint places its bed as a child at world XZ; ground it where authored,
	# exactly as the Stormwood camps correct theirs.
	var placed := care_point.get_node_or_null(^"CampCreatureBed") as Node3D
	if placed != null:
		placed.global_position = _grounded(bed_xz)
