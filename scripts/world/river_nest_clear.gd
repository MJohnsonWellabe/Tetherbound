extends Node3D

## T3-ACTIVITIES, CI-TRAINER-CENSUS (2026-08-30). Band 3's "River Nest" Local
## Request -- spec sec6's "aggressive Water/Air creatures block a fishing
## location". Originally authored as a trainer battle (Doss's team WAS the
## blocking pair), which is a legitimate reading of the spec line, but it
## made her the third brand-new distinct trainer opponent this content lane
## added. `tests/test_chapter_content_map.gd::
## test_the_chapter_fields_the_number_of_trainers_it_is_aiming_for` caps the
## whole chapter at 24 distinct trainer opponents, on purpose (its own header:
## "raising the ceiling ... would have to be raised again by whichever band
## authors the next good optional trainer, which is exactly the 'quota to
## fill mechanically' reading [it] rejects"), and the chapter was already AT
## 24 before this lane started. There was no headroom for even one new name,
## let alone three.
##
## Doss stays -- same site, same portrait, same "civilian ranger annoyed
## about her fishing spot" character -- but she is no longer a `trainers.json`
## row. Placed here exactly like a `village_npcs.json` entry (`npc_body.gd`,
## `stand_at`, a "Greet Doss" prompt) and resolved with the same `item_gate.gd`
## contract `cart_repair.gd` already proved for Band 1's Broken Cart: gather
## wood and fiber (driftwood stakes and lashings to pen the nest back)  and
## hand them to her, rather than fighting her team. Spec sec6 never actually
## requires a human fight here -- "aggressive creatures block a location" is
## satisfied by clearing the blockage, and doing it by build-and-give reuses a
## verb the player already has instead of inventing a new one.

const NPC := preload("res://scripts/npc/npc_body.gd")
const VILLAGE_NPCS := preload("res://scripts/world/village_npcs.gd")
const ITEM_GATE := preload("res://scripts/world/item_gate.gd")

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

	var game := get_node_or_null(^"/root/Game")
	var progression: RefCounted = game.get("progression") if game != null else null
	if progression != null and _gate.is_open(progression):
		_prompt.call("set_enabled", false)


func is_cleared() -> bool:
	var game := get_node_or_null(^"/root/Game")
	var progression: RefCounted = game.get("progression") if game != null else null
	return progression != null and _gate.is_open(progression)


func _on_greeted() -> void:
	if is_cleared():
		return
	var game := get_node_or_null(^"/root/Game")
	var inventory: RefCounted = game.get("inventory") if game != null else null
	var progression: RefCounted = game.get("progression") if game != null else null
	if progression != null:
		progression.call("set_flag", MET_FLAG)
	if inventory != null and progression != null and _gate.try_open(inventory, progression):
		inventory.call("add", "coin", REWARD_COINS)
		inventory.call("add", REWARD_ITEM_ID, REWARD_ITEM_COUNT)
		_prompt.call("set_enabled", false)
		_say(CLEARED_CONVERSATION)
	else:
		_say(BLOCKED_CONVERSATION)


func _say(conversation_id: String) -> void:
	var panel := get_tree().get_first_node_in_group("dialogue_panel")
	if panel == null:
		push_warning("no node in the 'dialogue_panel' group; Doss has nothing to say")
		return
	if bool(panel.call("is_open")):
		return
	panel.call("start", conversation_id)
