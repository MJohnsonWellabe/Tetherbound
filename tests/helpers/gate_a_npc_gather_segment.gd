extends RefCounted

## Reusable Gate A continuous-session segment: village conversations, Satchel
## tool assignment, and authored gathering.  The opening/catch harness invokes
## `run()` without changing scenes, so this remains the same uninterrupted
## production world session.
##
## Canonical constraints are intentional and load-bearing here:
##
## - every action enters through a physical joypad event and the live InputMap;
## - travel is by the player's left stick, including through real doors;
## - Tam's production dialogue is the only source of the tools;
## - the Satchel's focused controller UI assigns the quick slots;
## - harvesting uses the PAD's own gather button, never a direct gather call.
##   That is `interact` (X) since CONTROLLER-MAP: the owner's map gives X
##   "talk, gather, chop, mine", and `use_tool` kept only its mouse button.
##   Pressing `use_tool` here meant this segment could never run on a pad at
##   all -- `_required_pad_actions_exist()` failed the whole Gate A continuous
##   core on it -- and, worse, it hid that X gathered without ever swinging;
## - no teleport, direct inventory grant, progression mutation, or private
##   gameplay method stages the route.
##
## This helper deliberately does not boot or finish a SceneTree.  Its caller
## owns the title/opening/catch preamble and the later build/rest/map/save
## segments, while this bounded helper reports its own exact first blocker.

const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const INTERACTABLE_SCRIPT := "res://scripts/world/interactable.gd"
const DOOR_SCRIPT := "res://scripts/world/village_door.gd"
const HARVEST_NODE_SCRIPT := "res://scripts/world/harvest_node.gd"
const BACKPACK_COLUMNS := 6
const NAVIGATOR := preload("res://tests/helpers/opening_geometry_navigator.gd")
const VILLAGE_BOUNDARY := preload("res://scripts/world/village_boundary.gd")

## Metres out along a door's own outward normal that the approach stands off
## before asking for the prompt, and metres in past the leaf once it is open.
const DOOR_STANDOFF := 2.6
const DOOR_STEP_IN := 2.2

## Real auto-run taps during the meadow return. Physics ticks already spent
## walking service the press/release edges; this adds no wait or walk allowance.
class RoadRunTap extends RefCounted:
	enum Phase { ARMED, ON_RELEASE, ON_GAP, RUNNING, OFF_RELEASE, OFF_GAP, DONE, FAILED }
	enum Edge { NONE, PRESS, RELEASE }
	var phase := Phase.ARMED
	var finish := false
	var _cutoff: float
	var _edge_frame := -1
	var walked := 0
	var _counted_frame := -1
	func _init(cutoff: float) -> void:
		_cutoff = cutoff
	func advance(frame: int, z: float, driving: bool, running: bool, controllable: bool = true) -> int:
		# The navigator's original budget counts walking ticks, excluding
		# combat/UI holds. Service and stick callbacks share a physics tick.
		if phase != Phase.ARMED and controllable and frame != _counted_frame:
			walked += 1
			_counted_frame = frame
		if phase == Phase.ARMED:
			if finish or z >= _cutoff:
				phase = Phase.DONE
			elif driving and controllable:
				if running:
					phase = Phase.FAILED
				else:
					phase = Phase.ON_RELEASE
					_edge_frame = frame
					walked = 1
					_counted_frame = frame
					return Edge.PRESS
		elif phase == Phase.ON_RELEASE and frame - _edge_frame >= 3:
			phase = Phase.ON_GAP if running else Phase.FAILED
			_edge_frame = frame
			return Edge.RELEASE
		elif phase == Phase.ON_GAP and frame - _edge_frame >= 5:
			phase = Phase.RUNNING
		elif phase == Phase.OFF_RELEASE and frame - _edge_frame >= 3:
			phase = Phase.OFF_GAP if not running else Phase.FAILED
			_edge_frame = frame
			return Edge.RELEASE
		elif phase == Phase.OFF_GAP and frame - _edge_frame >= 5:
			phase = Phase.DONE
		# Reserve the existing3press+5release ticks and two callback-order ticks
		# before the original900frame deadline; this never adds a tick.
		if phase == Phase.RUNNING and controllable and (finish or (driving and z >= _cutoff) or walked >= 900 - 3 - 5 - 2):
			if running:
				phase = Phase.OFF_RELEASE
				_edge_frame = frame
				return Edge.PRESS
			phase = Phase.DONE
		return Edge.NONE

var _mira_road_run: RoadRunTap = null
var _mira_run_refused := false
var _mira_run_trace: Array[Dictionary] = []
var _tree: SceneTree = null
var _world: Node = null
var _game: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _dialogue: CanvasLayer = null
var _arbiter: Node = null
var _menu: CanvasLayer = null
var _hud: CanvasLayer = null
var _failures: Array[String] = []
var _started_ms := 0
## The interaction arbiter recomputes its winner on the physics tick that reads
## the physical press.  Its `winning_provider()` value from the preceding idle
## frame is therefore only permission to TRY, not proof that the same provider
## received the press.  This witness is set from the arbiter's production
## `activated` signal. A press that activates nothing stays inside the existing
## approach budget; a press that activates a competing provider fails at that
## exact event instead of being misreported later as "dialogue did not open".
enum ActivationVerdict { NONE, TARGET, COMPETING }
var _activation_target: Object = null
var _activation_verdict := ActivationVerdict.NONE
var _competing_activation := ""
## Travel. See `stick_navigator.gd` for why walking is no longer a straight
## line: the village has buildings in it and the game has no navmesh.
var _nav = null  # stick_navigator.gd; untyped so its methods read as methods
## Opt-in earned campaign care basket. Other village/capture callers retain
## their original shopping behavior. Purchases occur only in Mira's actual
## first open shop; returning before defeating her opens her trainer challenge.
var care_basket_purchases := 0


## `include_vendors`: Oskar (the creature trader) and Bram (the innkeeper) are
## commerce-only stops -- nothing downstream of this segment (gathering,
## hammer, tools, the objective flags) depends on either. Defaulted true so
## every existing caller's coverage is unchanged; a caller proving something
## that starts after this segment and has nothing to do with trade (the
## build/camp/sleep chain, for instance) can pass false to skip them.
func run(tree: SceneTree, world: Node, game: Node, player: CharacterBody3D,
		camera_rig: Node3D, include_vendors: bool = true) -> Array[String]:
	_started_ms = Time.get_ticks_msec()
	_tree = tree
	_world = world
	_game = game
	_player = player
	_rig = camera_rig
	_dialogue = _world.get_node_or_null(^"DialoguePanel") as CanvasLayer
	_arbiter = _world.get_node_or_null(^"InteractionArbiter")
	_hud = _world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	_menu = _game.call("menu") as CanvasLayer if _game != null and _game.has_method("menu") else null
	if (_tree == null or _world == null or _game == null or _player == null
			or _rig == null or _dialogue == null or _arbiter == null
			or _hud == null or _menu == null):
		_fail("segment dependencies are incomplete")
		return _failures
	if int((_game.get("party") as RefCounted).call("size")) < 2:
		_fail("NPC/gather segment began before the natural opening catch completed")
		return _failures
	if not _required_pad_actions_exist():
		return _failures
	_nav = NAVIGATOR.new(_tree, _player, _rig, _send_stick, true) # Observe actual production steering.
	var activation_handler := Callable(self, "_on_arbiter_activated")
	if not _arbiter.is_connected("activated", activation_handler):
		_arbiter.connect("activated", activation_handler)

	# ORDER-BUG, found running this segment for real (OWNER-0901-PLAYER-SLEEP-V2):
	# this used to visit only Tam here and then assert `recipe_orb_basic` plus
	# an axe/pickaxe count -- all three of which are Mira's gifts, not Tam's
	# (`village_mira_shop_intro` in data/dialogue/village.json is the only place
	# any of them are granted). Nothing here had visited Mira yet; her own visit
	# was scheduled far later, after gathering. So this segment -- the ONE real,
	# continuous, fresh-save proof of the gather/build/sleep chain -- has been
	# failing at the very first village check since whichever pass moved the
	# starter tools from Tam onto Mira, and every later beat this segment was
	# meant to prove (the hammer, gathering, the camp, the bedroll, sleeping)
	# has gone unexercised by real automated play since. A real player is not
	# affected -- `village_npcs.json`'s own `greeting_when` gates neither
	# villager's first-visit branch on the other, so either can be greeted
	# first -- but this harness asserted an order it never actually walked.
	# Mira first, matching Tam's own line ("Mira set you up for gathering").
	if not await _visit_villager("Mira", "shop_panel.gd", 1):
		return _failures
	if not _progression_has("recipe_orb_basic"):
		_fail("Mira's required opening visit left 'recipe_orb_basic' unset; the gift branch is "
			+ "what the opening orb recipe waits on")
		return _failures
	for tool_id in ["axe", "pickaxe"]:
		if int((_game.get("inventory") as RefCounted).call("count", tool_id)) != 1:
			_fail("Mira's completed dialogue did not leave exactly one %s in the Satchel" % tool_id)
			return _failures
	_checkpoint("Mira handed over axe, pickaxe and the Basic Orb pattern through dialogue")

	if not await _visit_villager("Tam", "", 1):
		return _failures
	if not _progression_has("tam_tools_given"):
		_fail("Tam's required opening visit left 'tam_tools_given' unset")
		return _failures
	for tool_id in ["knife", "torch", "hammer"]:
		if int((_game.get("inventory") as RefCounted).call("count", tool_id)) != 1:
			_fail("Tam's completed dialogue did not leave exactly one %s in the Satchel" % tool_id)
			return _failures
	if not _progression_has("camp_hammer_given"):
		_fail("Tam's required opening visit left 'camp_hammer_given' unset")
		return _failures
	_checkpoint("Tam handed over knife, torch and build hammer through dialogue")

	if not await _assign_tools_in_satchel():
		return _failures
	if not await _gather_authored_node("wood", "axe", "hotbar_1"):
		return _failures
	if not await _gather_authored_node("stone", "pickaxe", "hotbar_2"):
		return _failures
	if not await _gather_authored_node("fiber", "knife", "hotbar_3"):
		return _failures

	if not include_vendors:
		_checkpoint("tools/gather chain returned world control (vendors skipped by caller)")
		return _failures

	# Oskar exercises the same dialogue -> distinct modal -> B -> world
	# lifecycle Mira and Tam already did above. Bram is deliberately
	# reopened three times: unlike the trainers, his steady-state greeting
	# remains a service and does not turn the second visit into a battle
	# outside this segment's scope.
	if not await _visit_villager("Oskar", "swap_panel.gd", 1):
		return _failures
	if not await _visit_villager("Bram", "shop_panel.gd", 3):
		return _failures

	_checkpoint("five NPC/modal exits and three equipped-tool gathers returned world control")
	return _failures


func _progression_has(flag_id: String) -> bool:
	var progression: RefCounted = _game.get("progression")
	return progression != null and bool(progression.call("has", flag_id))


func _visit_villager(who: String, expected_panel_suffix: String, cycles: int) -> bool:
	var npc := _world.find_child(who, true, false) as Node3D
	if npc == null:
		_fail("production world has no villager named %s" % who)
		return false

	# Only these two villagers are authored inside buildings.  Oskar stands
	# close enough to Mira's cottage that a nearest-door heuristic alone would
	# incorrectly walk indoors before trying his outdoor prompt.
	var door := _nearest_door(npc) if who in ["Mira", "Bram"] else null
	if door != null and _player.global_position.distance_to(npc.global_position) > 4.0:
		if not await _enter_through(door, npc.global_position):
			_fail("could not naturally enter %s's building" % who)
			return false

	var prompt := _npc_prompt(npc)
	if prompt == null:
		_fail("%s has no enabled production greeting prompt" % who)
		return false
	for cycle in cycles:
		# 1400 frames is 23 seconds of walking, which is fine for a villager a
		# few metres away and short for one on the other side of the village --
		# the Foreman stands at (0, -6) and Oskar at (22, -6), with the well,
		# two cottages and a wagon between them. Derived from the leg.
		if not await _walk_to_and_activate(prompt,
				maxi(1400, 600 + int(_player.global_position.distance_to(
					prompt.global_position) * 120.0)), who == "Oskar"):
			var holder: Variant = _arbiter.call("winning_provider")
			_fail(("natural controller travel could not activate %s cycle %d "
				+ "(%.1fm away, arbiter winner=%s under %s). A winner that is not %s "
				+ "means something nearer took the interact line.") % [
				who, cycle + 1,
				_player.global_position.distance_to(npc.global_position),
				str((holder as Node).name) if holder is Node else "<none>",
				str((holder as Node).get_parent().name) if holder is Node \
					and (holder as Node).get_parent() != null else "<none>",
				who])
			return false
		if not await _wait_dialogue_open(90):
			_fail("%s cycle %d did not open dialogue" % [who, cycle + 1])
			return false
		if not await _close_dialogue(40):
			_fail("%s cycle %d dialogue did not close through Interact" % [who, cycle + 1])
			return false
		if not expected_panel_suffix.is_empty():
			var panel := await _wait_open_panel(expected_panel_suffix, 90)
			if panel == null:
				_fail("%s cycle %d did not hand off to %s" % [who, cycle + 1, expected_panel_suffix])
				return false
			if who == "Mira" and care_basket_purchases > 0:
				if not await _buy_care_basket(panel):
					return false
			await _tap_action(&"menu_cancel")
			if not await _wait_world_owned(45):
				_fail("%s cycle %d left stale modal ownership after B" % [who, cycle + 1])
				return false
		elif not await _wait_world_owned(30):
			_fail("%s cycle %d left stale dialogue ownership" % [who, cycle + 1])
			return false
		if not await _prove_movement_resumed(door, npc.global_position):
			_fail("%s cycle %d returned visually but world movement stayed dead" % [who, cycle + 1])
			return false
		_checkpoint("%s cycle %d exited and movement resumed" % [who, cycle + 1])

	# Leave an interior through the same open doorway before the next route leg.
	if door != null:
		if not await _exit_through(door, npc.global_position):
			_fail("could not naturally leave %s's building (player %.1fm from door at %s)" % [
				who, _player.global_position.distance_to(door.global_position),
				str(_player.global_position.round())])
			return false
	return true


func _buy_care_basket(panel: Node) -> bool:
	if care_basket_purchases > 5 or INPUT_OWNER.current(_tree) != panel \
			or not bool(panel.call("is_open")) or str(panel.call("vendor_id")) != "mira":
		_fail("care purchase refused: expected Mira's live owned shop and at most five purchases")
		return false
	var trade: RefCounted = panel.get("_trade")
	var inventory: RefCounted = _game.get("inventory")
	var db: RefCounted = _game.get("items")
	var party: RefCounted = _game.get("party")
	var stock: Array = trade.call("stocked_ids", "mira")
	var index := stock.find("potion_small")
	var price := int(trade.call("buy_price", "mira", "potion_small"))
	var coin := str(trade.call("currency_id"))
	if index < 0 or price <= 0 or int(inventory.call("count", coin)) < price * care_basket_purchases:
		_fail("care purchase refused: authored potions or earned funds are unavailable")
		return false
	for purchase in care_basket_purchases:
		# Production _refresh replaces the Buttons after every transaction.
		var rows: Array = panel.get("_rows")
		var column: VBoxContainer = panel.get("_buy_column")
		if index >= column.get_child_count() or not column.get_child(index) is Button:
			_fail("care purchase has no canonical visible potion row")
			return false
		var target: Button = column.get_child(index)
		var labels := _shop_labels(target)
		if target.disabled or not labels.has(str(db.call("item_name", "potion_small"))) or not labels.has(str(price)):
			_fail("care purchase row disagrees with canonical potion name, price or affordability")
			return false
		for _step in rows.size() * 2:
			if target.has_focus():
				break
			var focused := rows.find(_tree.root.gui_get_focus_owner())
			if focused < 0:
				_fail("care purchase lost real controller focus")
				return false
			await _tap_shop_action(&"ui_down" if focused < index else &"ui_up")
		if not target.has_focus() or INPUT_OWNER.current(_tree) != panel:
			_fail("care purchase controller did not reach the actual potion row")
			return false
		var before := _inventory_counts(inventory)
		var party_before: Array = party.call("members")
		var creature_states := _shop_party_states(party)
		var party_revision := int(party.get("revision"))
		var active_before := int(party.call("active_index"))
		var before_coin := int(inventory.call("count", coin))
		var before_potions := int(inventory.call("count", "potion_small"))
		var binding := _event_for(&"menu_confirm", true)
		if binding == null:
			_fail("shop confirmation has no physical pad binding")
			return false
		var player_state: RefCounted = _game.get("local")
		print("F17 SHOP INPUT PRE_EDGE " + JSON.stringify({"purchase": purchase + 1,
			"ui_accept_held": Input.is_action_pressed("ui_accept"), "menu_confirm_held": Input.is_action_pressed("menu_confirm"),
			"interact_held": Input.is_action_pressed("interact"), "target_focused": target.has_focus(),
			"binding_device": binding.device, "binding": binding.as_text(),
			"pressed_connections": target.get_signal_connection_list("pressed").size(),
			"inventory_guard_blocked": bool(inventory.call("_owner_mutation_blocked")),
			"same_panel_inventory": panel.call("_inventory") == inventory,
			"same_player_inventory": player_state != null and player_state.get("inventory") == inventory,
			"scope": "read-only live input, focus, identity and guard observation; no bypass"}))
		var edges := [0, 0, 0]
		target.button_down.connect(func() -> void: edges[0] += 1)
		target.button_up.connect(func() -> void: edges[1] += 1)
		target.pressed.connect(func() -> void: edges[2] += 1)
		await _tap_shop_action(&"menu_confirm")
		print("F17 SHOP INPUT OBSERVATION " + JSON.stringify({"purchase": purchase + 1,
			"button_down": edges[0], "button_up": edges[1], "pressed": edges[2],
			"coin_before": before_coin, "coin_after": int(inventory.call("count", coin)),
			"potions_before": before_potions, "potions_after": int(inventory.call("count", "potion_small")),
			"message": str((panel.get("_message") as Label).text), "paused": _tree.paused,
			"menu_confirm_released": not Input.is_action_pressed("menu_confirm"),
			"party_unchanged": _shop_party_states(party) == creature_states,
			"scope": "read-only GUI event and actual paid-state observation"}))
		if int(inventory.call("count", coin)) != before_coin - price \
				or int(inventory.call("count", "potion_small")) != before_potions + 1 \
				or party.call("members") != party_before or int(party.get("revision")) != party_revision \
				or int(party.call("active_index")) != active_before or _shop_party_states(party) != creature_states:
			_fail("care purchase did not spend exact earned coins for one potion with unchanged party")
			return false
		# Compare every other item against the real pre-purchase inventory.
		var after := _inventory_counts(inventory)
		for permitted: String in [coin, "potion_small"]:
			before.erase(permitted)
			after.erase(permitted)
		if before != after:
			_fail("care purchase unexpectedly changed another carried item")
			return false
		_checkpoint("paid Mira care purchase %d: potion_small +1, %s -%d, purse %d" % [purchase + 1, coin, price, before_coin - price])
	return true


func _shop_labels(node: Node) -> Array[String]:
	var out: Array[String] = []
	if node is Label:
		out.append((node as Label).text)
	for child: Node in node.get_children():
		out.append_array(_shop_labels(child))
	return out


func _tap_shop_action(action: StringName) -> void:
	var event := _event_for(action, true)
	if event == null:
		_fail("shop action has no physical pad binding: " + str(action))
		return
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	# Buttons consume GUI input at idle delivery; separate press and release
	# across process frames even when several physics ticks share one idle.
	await _tree.process_frame
	for _frame in 3:
		await _tree.physics_frame
	var released := event.duplicate() as InputEvent
	if released is InputEventJoypadButton:
		(released as InputEventJoypadButton).pressed = false
	elif released is InputEventJoypadMotion:
		(released as InputEventJoypadMotion).axis_value = 0.0
	Input.parse_input_event(released)
	Input.flush_buffered_events()
	await _tree.process_frame
	for _frame in 5:
		await _tree.physics_frame


func _inventory_counts(inventory: RefCounted) -> Dictionary:
	var counts := {}
	for index in int(inventory.call("slot_count")):
		var stack: Dictionary = inventory.call("stack_at", index)
		if not stack.is_empty():
			var id := str(stack.get("id", ""))
			counts[id] = int(counts.get(id, 0)) + int(stack.get("n", 0))
	return counts


func _shop_party_states(party: RefCounted) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for creature: RefCounted in (party.call("members") as Array):
		var state := {}
		for property: Dictionary in creature.get_property_list():
			if int(property.get("usage", 0)) & PROPERTY_USAGE_SCRIPT_VARIABLE:
				var value: Variant = creature.get(str(property.name))
				state[str(property.name)] = value.duplicate(true) if value is Array or value is Dictionary else value
		out.append(state)
	return out


func _assign_tools_in_satchel() -> bool:
	await _tap_action(&"inventory")
	for _i in 90:
		if bool(_menu.call("is_open")) and str(_menu.call("current_tab_id")) == "backpack":
			break
		await _tree.process_frame
	if not bool(_menu.call("is_open")) or str(_menu.call("current_tab_id")) != "backpack":
		_fail("physical Y did not open the Satchel tab")
		return false

	var bodies: Array = _menu.get("_bodies") as Array
	if bodies.is_empty():
		_fail("Satchel menu has no tab body")
		return false
	var backpack: Node = bodies[0]
	var buttons: Array = backpack.get("_buttons") as Array
	var inventory: RefCounted = _game.get("inventory")
	# Assign in reverse quick-slot order.  The one-button assignment verb walks
	# an item through slot 1, 2, ...; reverse order prevents a later walk from
	# overwriting an earlier tool on its way to its destination.
	# GATEB-COORD: the HAMMER takes quick slot 4, not the torch.
	#
	# It is the one tool the chapter cannot proceed without -- CONTROLLER-MAP
	# retired `build_open`'s pad button, so hammer-in-hand plus Interact is the
	# only route a controller has into build mode, and
	# `gate_a_build_segment.gd::HOTBAR_ACTIONS` reaches slots 1-4 only. The
	# torch stays in the Satchel, where OW12 already put it: it is equipped the
	# same way any other tool is and Gate B never asks for it, whereas a house
	# with no hammer on the bar is a chapter that stops.
	for spec: Array in [["hammer", 3], ["knife", 2], ["pickaxe", 1], ["axe", 0]]:
		var item_id := str(spec[0])
		var destination := int(spec[1])
		var inventory_slot := int(inventory.call("find_slot", item_id))
		if inventory_slot < 0 or inventory_slot >= buttons.size():
			_fail("Satchel has no focusable slot for %s" % item_id)
			return false
		if not await _focus_satchel_slot(buttons, inventory_slot):
			_fail("controller focus could not reach %s in Satchel slot %d" % [item_id, inventory_slot + 1])
			return false
		# The verb cycles unbound -> 1 -> ... -> 5 -> unbound. The HUD autofills
		# a wholly empty bar from the Satchel, so the tool may already sit on a
		# slot: press as a player watching the badge does, until it lands, and
		# never more than one full cycle.
		var hotbar_size := (_game.get("hotbar") as Array).size()
		for _press in hotbar_size + 1:
			if str((_game.get("hotbar") as Array)[destination]) == item_id:
				break
			await _tap_action(&"backpack_assign")
		if str((_game.get("hotbar") as Array)[destination]) != item_id:
			_fail("Satchel controller assignment did not put %s on quick slot %d" % [item_id, destination + 1])
			return false

	await _tap_action(&"menu_cancel")
	if not await _wait_world_owned(45):
		_fail("closing the Satchel left pause/modal ownership behind")
		return false
	if not await _prove_movement_resumed():
		_fail("closing the Satchel returned visually but movement stayed dead")
		return false
	_checkpoint("Satchel assigned four tools by focused controller input")
	return true


func _focus_satchel_slot(buttons: Array, target: int) -> bool:
	var focused := _tree.root.get_viewport().gui_get_focus_owner()
	var current := buttons.find(focused)
	if current < 0:
		return false
	var current_row: int = current / BACKPACK_COLUMNS
	var current_column := current % BACKPACK_COLUMNS
	var target_row: int = target / BACKPACK_COLUMNS
	var target_column := target % BACKPACK_COLUMNS
	for _i in absi(target_row - current_row):
		await _tap_action(&"ui_down" if target_row > current_row else &"ui_up")
	for _i in absi(target_column - current_column):
		await _tap_action(&"ui_right" if target_column > current_column else &"ui_left")
	return _tree.root.get_viewport().gui_get_focus_owner() == buttons[target]


func _gather_authored_node(item_id: String, tool_id: String, hotbar_action: StringName) -> bool:
	var node := _nearest_authored_node(item_id)
	if node == null:
		_fail("no unspent authored %s node exists in the opening route" % item_id)
		return false
	# The direct wood leg crossed Grandpa's furnished yard and lost actual floor.
	# Follow the existing Pond road to its nearest authored node, then leave it
	# for the resource. Nearest live nodes vary with the real NPC arrival pose.
	# A stone heading that crosses the concave fence uses the existing meadow
	# road; an interior heading stays direct. A heading through an authored prop
	# cluster's placed collider (the practice-meadow trainer_camp's fire ring and
	# bedroll sit on the eastern-wood -> Stoneyard line) uses the same road, as
	# the wood leg does around Grandpa's furnished yard. This hint admits no
	# native contact; it reads placed collider boxes only as layout metadata.
	# Every leg shares the same 1800-frame walk and unchanged live floor checks.
	var road := "The Pond" if item_id == "wood" else ""
	if item_id == "stone":
		var outline := VILLAGE_BOUNDARY.outline(VILLAGE_BOUNDARY.load_config())
		var hint := stone_road_hint(Vector2(_player.global_position.x, _player.global_position.z),
			Vector2(node.global_position.x, node.global_position.z), outline, 1.55, _authored_prop_footprints())
		if hint == StoneRoadHint.INVALID:
			_fail("actual stone approach is outside the bounded village fence hint")
			return false
		if hint == StoneRoadHint.MEADOW:
			road = "Practice Meadow"
	if not await _walk_toward(node.global_position, 1800, 1.55, road, item_id == "wood"):
		_fail("natural controller travel could not reach the authored %s node (%s)" % [item_id, _walk_diagnosis(node.global_position)])
		return false
	# A visible swing owns the held prop for its full production animation.  Do
	# not overlap the next hotbar edge with it: the player cannot switch tools
	# mid-swing, and a continuous controller route must respect that same rule.
	if not await _wait_for_tool_idle():
		return false
	# A tool slot TOGGLES. `playground_hud.gd:2228` -- "press slot, tool in hand"
	# is an owner directive, and pressing the slot again puts the tool away, so
	# one button is both draw and stow.
	#
	# This helper pressed it unconditionally, which makes the whole segment
	# depend on what the previous beat left in hand: with the axe already
	# equipped the press STOWS it and the check below reports "hotbar_1 quick
	# slot did not put a visible axe in the trainer's hand (assigned=axe,
	# game=, hold=)". Two consecutive runs of this file failed at two different
	# points with no code change between them, which is what a toggle pressed
	# blind looks like.
	#
	# A player does not press the slot when the tool is already in hand, so
	# neither does this.
	var hold: Node = _player.get("tool_hold")
	if str(_game.get("equipped_tool")) != tool_id:
		await _tap_action(hotbar_action)
	for _i in 30:
		if str(_game.get("equipped_tool")) == tool_id and hold != null and hold.call("prop_node") != null:
			break
		await _tree.process_frame
	if str(_game.get("equipped_tool")) != tool_id or hold == null or hold.call("prop_node") == null:
		var hotbar: Array = _game.get("hotbar") as Array
		var action_text := str(hotbar_action)
		var hotbar_index := action_text.trim_prefix("hotbar_").to_int() - 1 if action_text.begins_with("hotbar_") else -1
		var assigned := str(hotbar[hotbar_index]) if hotbar_index >= 0 and hotbar_index < hotbar.size() else "<unavailable>"
		_fail("%s quick slot did not put a visible %s in the trainer's hand (assigned=%s, game=%s, hold=%s, prop=%s, swinging=%s)" % [
			hotbar_action, tool_id, assigned, str(_game.get("equipped_tool")),
			str(hold.call("equipped")) if hold != null else "<missing>",
			str(hold.call("prop_node")) if hold != null else "<missing>",
			str(hold.call("is_swinging")) if hold != null else "<missing>"])
		return false

	var inventory: RefCounted = _game.get("inventory")
	var before := int(inventory.call("count", item_id))
	var message := _hud.get_node_or_null(^"Root/BottomDock/HotbarPanel/Margin/Layout/Message") as Label
	if message != null:
		message.text = ""
		message.visible = false
	# Sampled BEFORE the press, because the failure below reports an empty
	# `equipped` and the check twelve lines above proved it was full. Only the
	# press sits between them, so which side of it the tool leaves on is the
	# whole question -- and an after-the-fact sample cannot answer it.
	var equipped_before := str(_game.get("equipped_tool"))
	# `is_instance_valid`, not `== null`. A FREED object is neither reliably
	# equal to null nor safe to `str()`, and the check twelve lines above uses
	# `!= null` -- so a prop freed between the equip and the press would pass
	# that guard and then read as null here, which is exactly the contradiction
	# this sample exists to resolve.
	var prop_raw: Variant = hold.call("prop_node")
	var prop_before := "<null>"
	if prop_raw != null:
		prop_before = "<freed>" if not is_instance_valid(prop_raw) \
			else "%s(%s)" % [str(prop_raw.get_class()), str(prop_raw.name)]
	# Was a swing ALREADY running when the button went down?
	#
	# This is the one thing the failure below could not tell you, and it
	# separates the only two stories that fit the evidence it does print.
	# `harvest_logic.gd::swing_answers_the_prompt()` returns TRUE without
	# starting anything when a swing is already in flight -- "that swing
	# resolves on its own and will gather something itself" -- so a press that
	# lands in the tail of a previous swing is answered by that older swing and
	# starts no new one. `_tap_action()` then waits 8 physics frames, which is
	# long enough for the tail of a ~37-frame swing to finish, and the sample
	# below reads `is_swinging=false` on a press that was in fact swallowed.
	# The other story is that the press reached a genuinely idle hand and the
	# swing simply never began. `hold.equipped()` is sampled for the same
	# reason: `swing()` refuses on an empty hand, and tool_hold's own idea of
	# what is equipped is a DIFFERENT variable from `Game.equipped_tool`, which
	# is what the check above proved -- the two disagreeing is its own bug and
	# would look identical from outside.
	var swinging_before := bool(hold.call("is_swinging"))
	var hold_equipped_before := str(hold.call("equipped"))
	await _tap_action(&"interact")
	if not bool(hold.call("is_swinging")):
		# Say WHY, not just that. This assertion has never once run in CI --
		# `--gate-a-continuous-core` is a flag no shard passes -- so the first
		# time it fired, on 2026-08-23, it reported a bare "did not start the
		# swing" about a path with no working baseline to compare against.
		#
		# The three things that decide this: who won the interact button (a
		# nearer prop takes a distance-ranked arbiter), whether the tool is
		# still in hand at the moment of the press, and whether a swing was
		# already running and refused the new one.
		var winner: Variant = _arbiter.call("winning_provider") if _arbiter != null else null
		_fail(("physical interact on the node did not start the visible %s swing "
			+ "(arbiter winner=%s, equipped=%s, prop=%s, cooling=%s, node=%s)") % [
			tool_id,
			str(winner.name) if winner is Node else "<none>",
			str(_game.get("equipped_tool")),
			str(hold.call("prop_node")),
			str(hold.call("is_swinging")),
			str(node.name) if node != null else "<null>"])
		_fail(("  ...and BEFORE the press: equipped=%s prop=%s swinging=%s hold_equipped=%s "
			+ "| winner parent=%s") % [
			equipped_before,
			prop_before,
			str(swinging_before),
			hold_equipped_before,
			str((winner as Node).get_parent().name) if winner is Node \
				and (winner as Node).get_parent() != null else "<none>"])
		return false
	for _i in 90:
		if int(inventory.call("count", item_id)) > before and message != null and message.visible:
			break
		await _tree.process_frame
	var credited := int(inventory.call("count", item_id)) - before
	if credited <= 0:
		_fail("visible %s swing credited no %s" % [tool_id, item_id])
		return false
	var expected := "+%d %s" % [credited, str((_game.get("items") as RefCounted).call("item_name", item_id))]
	if message == null or not message.visible or message.text != expected:
		_fail("%s credited %d but visible pickup feedback was '%s'" % [
			item_id, credited, message.text if message != null else "<missing>"])
		return false
	_checkpoint("%s equipped, swung, gathered %s" % [tool_id, expected])
	return true


func _wait_for_tool_idle() -> bool:
	var hold: Node = _player.get("tool_hold")
	if hold == null:
		_fail("trainer has no ToolHold while waiting to switch tools")
		return false
	for _i in 120:
		if not bool(hold.call("is_swinging")):
			return true
		await _tree.physics_frame
	_fail("previous tool swing did not finish before the next controller hotbar edge")
	return false


enum StoneRoadHint { INVALID, DIRECT, MEADOW }
const MAX_PROP_FOOTPRINTS := 4096
const MAX_PROP_RADIUS := 32.0


## Bounded layout guidance only. Inside endpoints can still cross a concave
## fence twice, leaving via an open gate and returning through a solid panel.
## Native production movement, floor, skin and raw contact checks still decide
## whether the unchanged actual target is physically reached.
static func stone_road_hint(from: Vector2, goal: Vector2, outline: PackedVector2Array, clearance: float,
		footprints: PackedVector3Array = PackedVector3Array()) -> int:
	if not from.is_finite() or not goal.is_finite() or outline.size() < 3 or outline.size() > 64 \
			or from.distance_to(goal) > 180.0 or not is_finite(clearance) or clearance <= 0.0 or clearance > 1.65 \
			or footprints.size() > MAX_PROP_FOOTPRINTS:
		return StoneRoadHint.INVALID
	for index in outline.size():
		if not outline[index].is_finite() or outline[index] == outline[(index + 1) % outline.size()]:
			return StoneRoadHint.INVALID
	for footprint: Vector3 in footprints:
		if not footprint.is_finite() or footprint.z <= 0.0 or footprint.z > MAX_PROP_RADIUS:
			return StoneRoadHint.INVALID
	if not Geometry2D.is_point_in_polygon(from, outline) or not Geometry2D.is_point_in_polygon(goal, outline):
		return StoneRoadHint.INVALID
	for index in outline.size():
		var a := outline[index]
		var b := outline[(index + 1) % outline.size()]
		if Geometry2D.segment_intersects_segment(from, goal, a, b) != null:
			return StoneRoadHint.MEADOW
		var gap := minf(from.distance_to(Geometry2D.get_closest_point_to_segment(from, a, b)),
			goal.distance_to(Geometry2D.get_closest_point_to_segment(goal, a, b)))
		gap = minf(gap, a.distance_to(Geometry2D.get_closest_point_to_segment(a, from, goal)))
		gap = minf(gap, b.distance_to(Geometry2D.get_closest_point_to_segment(b, from, goal)))
		if gap <= clearance:
			return StoneRoadHint.MEADOW
	# A placed prop collider (x, z, footprint radius) the direct heading crosses.
	# One beside either endpoint is part of that stop, which no road choice avoids.
	for footprint: Vector3 in footprints:
		var centre := Vector2(footprint.x, footprint.y)
		var reach := footprint.z + clearance
		if from.distance_to(centre) <= reach or goal.distance_to(centre) <= reach:
			continue
		if centre.distance_to(Geometry2D.get_closest_point_to_segment(centre, from, goal)) <= reach:
			return StoneRoadHint.MEADOW
	return StoneRoadHint.DIRECT


## Placed authored prop colliders (props.gd: one centred box per prop, under its
## cluster in Props) as (x, z, horizontal half-diagonal). Walkable terrace
## segments are ground, not furnishing, and are left out. Metadata only.
func _authored_prop_footprints() -> PackedVector3Array:
	var footprints := PackedVector3Array()
	var props := _world.get_node_or_null(^"Props")
	if props == null:
		return footprints
	for cluster: Node in props.get_children():
		for child: Node in cluster.get_children():
			if not child is StaticBody3D or not str(child.name).ends_with("_Collision"):
				continue
			if cluster.get_node_or_null(NodePath(str(child.name).trim_suffix("_Collision"))) is MeshInstance3D:
				continue # A walkable segment's visible surface, not a prop root.
			for shape_node: Node in child.get_children():
				var shape := shape_node as CollisionShape3D
				if shape == null or not shape.shape is BoxShape3D:
					continue
				var size := (shape.shape as BoxShape3D).size * shape.global_basis.get_scale()
				var at := shape.global_position
				footprints.append(Vector3(at.x, at.z, 0.5 * Vector2(size.x, size.z).length()))
				if footprints.size() >= MAX_PROP_FOOTPRINTS:
					return footprints
	return footprints


func _nearest_authored_node(item_id: String) -> Node3D:
	var best: Node3D = null
	var distance := INF
	for node: Node in _tree.get_nodes_in_group("harvestable"):
		if not node is Node3D or _script_path(node) != HARVEST_NODE_SCRIPT:
			continue
		if (str(node.get("_item_id")) != item_id or not node.is_inside_tree()
				or float(node.get("_respawn_left")) > 0.0):
			continue
		var candidate := node as Node3D
		var gap := _player.global_position.distance_to(candidate.global_position)
		if gap < distance:
			distance = gap
			best = candidate
	return best


## Four ways to fail and, until now, one bare `false` for all of them.
##
## This has never run in CI (`--gate-a-continuous-core` is a flag no shard
## passes), so the first time it fired it reported "could not naturally enter
## Mira's building" about a door nobody has watched. Each branch says which one
## it was, for the same reason the swing assertion now does: on this path a
## symptom without a cause costs a twenty-minute run to re-derive.
func _enter_through(door: Node3D, inside_target: Vector3) -> bool:
	var prompt := door.get_node_or_null(^"Prompt") as Node3D
	if prompt == null:
		_fail("door '%s' has no Prompt child; nothing can open it" % door.name)
		return false
	var outward := _door_outward(door, inside_target)
	if not bool(door.call("is_open")):
		# Require the actual axial standoff within its existing 900-frame budget.
		var hints: Array[Vector2] = []
		if _nav.uses_production_steering() and str(door.get_parent().get_meta("village_role", "")) == "mira_shop":
			hints = _mira_approach_hint(door)
			if hints.is_empty():
				_fail("missing bounded Mira road/doorstep approach metadata")
				return false
			print("MIRA PROVISIONAL APPROACH ", hints, " original_standoff=", door.global_position + outward * DOOR_STANDOFF)
			if not _begin_mira_road_run(hints):
				return false
		var arrived := await _walk_toward(door.global_position + outward * DOOR_STANDOFF, 900, 1.0, "", false, hints)
		var run_restored := await _finish_mira_road_run()
		if not arrived or not run_restored:
			_fail("could not reach actual door standoff: " + _walk_diagnosis(door.global_position))
			return false
		if not await _walk_to_and_activate(prompt, 1200):
			var winner: Variant = _arbiter.call("winning_provider")
			_fail(("could not reach or activate door '%s' in 1200 frames "
				+ "(player %.1fm away at %s, door at %s, prompt enabled=%s, "
				+ "arbiter winner=%s). A distance that does not shrink across "
				+ "runs is the player walking into geometry, not walking slowly.") % [
				door.name, _player.global_position.distance_to(door.global_position),
				str(_player.global_position.round()), str(door.global_position.round()),
				str(prompt.get("enabled")) if prompt.has_method("get") else "?",
				str((winner as Node).name) if winner is Node else "<none>"])
			return false
		for _i in 45:
			if bool(door.call("is_open")):
				break
			await _tree.process_frame
	if not bool(door.call("is_open")):
		_fail("door '%s' was activated and did not open within 45 frames" % door.name)
		return false
	# Straight in through the frame, along the door's own axis rather than at the
	# villager standing somewhere off to one side of the room: a 1.6m clear
	# opening does not forgive an oblique entry.
	var step := door.global_position - outward * DOOR_STEP_IN
	if not await _walk_toward(step, 600, 0.7):
		_fail(("opened door '%s' but could not walk the 2.2m inward to %s "
			+ "(stopped %.1fm short)") % [
			door.name, str(step.round()), _player.global_position.distance_to(step)])
		return false
	return true


func _mira_approach_hint(door: Node3D) -> Array[Vector2]:
	var village := _world.get_node_or_null(^"Village")
	var capsule := _player.get_node_or_null(^"Collision") as CollisionShape3D
	if village == null or village.get_child_count() > NAVIGATOR.MAX_ROAD_INPUTS \
			or capsule == null or not capsule.shape is CapsuleShape3D \
			or absf(capsule.shape.height - 1.8) > 0.000001 \
			or capsule.transform.origin.distance_to(Vector3(0, 0.9, 0)) > 0.000001:
		return []
	var threshold: Node3D = null
	for candidate: Node in village.get_children():
		if str(candidate.get_meta("village_role", "")) == "mira_shop_threshold":
			if threshold != null or not candidate is Node3D:
				return []
			threshold = candidate as Node3D
	if threshold == null:
		return []
	var body := threshold.get_node_or_null(^"Collision") as StaticBody3D
	if body == null or body.get_child_count() != 1:
		return []
	var shape := body.get_child(0) as CollisionShape3D
	if shape == null or shape.disabled or not shape.shape is BoxShape3D \
			or shape.global_transform.basis != Basis.IDENTITY or door.global_transform.basis != Basis.IDENTITY:
		return []
	return mira_approach_hint(_player.global_position, door.global_position, shape.global_position,
		shape.shape.size, capsule.shape.radius, _player.safe_margin, _nav.authored_road_points("Practice Meadow"))


## Current Mira only: return along the painted road, then approach sideways
## inside the ORIGINAL standoff radius from the terrain strip behind the lip.
## These are ordinary stick hints. Neither this box nor any road is admitted.
static func mira_approach_hint(from: Vector3, door: Vector3, box: Vector3, size: Vector3,
		radius: float, skin: float, road: Array[Vector2]) -> Array[Vector2]:
	if not from.is_finite() or not door.is_finite() or not box.is_finite() or not size.is_finite() \
			or not is_finite(radius) or not is_finite(skin) or absf(radius - 0.4) > 0.00001 \
			or absf(skin - 0.001) > 0.00000001 or size.distance_to(Vector3(4, 0.1, 2)) > 0.0001 \
			or absf(door.x - 27.0) > 0.0001 or absf(door.z - 5.0) > 0.0001 \
			or absf(box.x - door.x) > 0.0001 or absf(box.z - door.z - 2.9) > 0.0001 \
			or absf(box.y - door.y - 0.05) > 0.0001:
		return []
	var strip_z := door.z + DOOR_STANDOFF - 0.95
	var gap := box.z - size.z * 0.5 - strip_z - 0.04 # SOURCE tracking reserve at the lip.
	var expanded := radius + skin
	if gap <= 0.0 or gap >= expanded or radius - sqrt(expanded * expanded - gap * gap) <= size.y * 0.5 + skin:
		return [] # Full bottom hemisphere, not a point-sized or smaller trainer.
	var corner := Vector2(20, strip_z - 0.35)
	var result := NAVIGATOR.road_slice(road, Vector2(from.x, from.z), corner)
	# The actual catch can finish north of the nearest southern road segment.
	# Joining its projection then walks away from the shop over an uphill chord.
	# In that case join the nearest forward authored node in this same slice;
	# retain every remaining bend and the original walking/contact allowances.
	var origin := Vector2(from.x, from.z)
	var return_axis := corner - origin
	if not result.is_empty() and (result.front() - origin).dot(return_axis) < 0.0:
		var join_index := -1
		var join_distance := INF
		for index in range(1, result.size()):
			if (result[index] - origin).dot(return_axis) < 0.0:
				continue
			var distance := origin.distance_squared_to(result[index])
			if distance < join_distance:
				join_index = index
				join_distance = distance
		if join_index < 0:
			return []
		result = result.slice(join_index)
	if result.is_empty() or result.back().distance_to(corner) > 0.0001 or result.size() >= NAVIGATOR.MAX_CHOICES:
		return []
	result.append(Vector2(door.x, strip_z))
	return result


## The same painted return and original900frames. Tap the existing auto-run
## control for the long field leg, then walk from the original(20,-12) node
## through the village turn and low-lip standoff. Stamina and speed are earned
## by the ordinary production controller; no flag or velocity is written here.
func _begin_mira_road_run(hints: Array[Vector2]) -> bool:
	if not hints.has(Vector2(20, -12)) or _player.global_position.z >= -12.0 or bool(_game.get("auto_run")):
		return true # Short returns and an existing player preference stay unchanged.
	if not _event_for(&"auto_run", true) is InputEventJoypadButton:
		_fail("Mira meadow return has no physical auto-run tap binding")
		return false
	_mira_road_run = RoadRunTap.new(-12.0)
	_mira_run_trace.clear()
	_tree.connect("physics_frame", Callable(self, "_service_mira_road_run"))
	return true


func _service_mira_road_run() -> void:
	_mira_road_run_edge(false) # Release edges only, except failure-path cleanup.


func _mira_road_run_edge(driving: bool) -> void:
	if _mira_road_run == null:
		return
	var controllable := not _tree.paused and INPUT_OWNER.current(_tree) == null \
		and bool(_player.call("locomotion_enabled"))
	var edge := _mira_road_run.advance(Engine.get_physics_frames(), _player.global_position.z,
		driving, bool(_game.get("auto_run")), controllable)
	if edge != RoadRunTap.Edge.NONE:
		var event := _event_for(&"auto_run", edge == RoadRunTap.Edge.PRESS) as InputEventJoypadButton
		_mira_run_trace.append({"physics_frame": Engine.get_physics_frames(), "pressed": event.pressed,
			"pad_button": event.button_index, "auto_run_before_dispatch": bool(_game.get("auto_run")),
			"controllable": controllable, "walked": _mira_road_run.walked,
			"player": [_player.global_position.x, _player.global_position.y, _player.global_position.z]})
		Input.parse_input_event(event)
		# The native movement callback flushes a press before the controller.
		# A release must also reach the controller when a refused walk has ended.
		if not driving:
			Input.flush_buffered_events()
	if _mira_road_run.phase == RoadRunTap.Phase.FAILED:
		_mira_run_refused = true
		_fail("physical Mira auto-run tap did not restore the observed production state")
	if _mira_road_run.phase in [RoadRunTap.Phase.DONE, RoadRunTap.Phase.FAILED]:
		_tree.disconnect("physics_frame", Callable(self, "_service_mira_road_run"))
		_mira_road_run = null


func _finish_mira_road_run() -> bool:
	if _mira_road_run != null:
		_mira_road_run.finish = true
		_mira_road_run_edge(false)
		# A refused walk can finish its physical off tap using only unused
		# ticks from the ORIGINAL900 allowance. It remains refused throughout.
		var held := 0
		while _mira_road_run != null and _mira_road_run.walked < 900 and held <= 36000:
			_stop_left_stick()
			Input.flush_buffered_events()
			if _tree.paused or INPUT_OWNER.current(_tree) != null or not bool(_player.call("locomotion_enabled")):
				held += 1
			await _tree.physics_frame
		# Never extend the budget or accept an arrival with an owned run toggle.
		if _mira_road_run != null:
			_fail("Mira road run did not finish within the original standoff allowance")
			return false
	if not _mira_run_trace.is_empty():
		print("MIRA ROAD RUN INPUT ", JSON.stringify({"acceptance": false, "edges": _mira_run_trace,
			"auto_run_after": bool(_game.get("auto_run")), "refused": _mira_run_refused}))
	return _failures.is_empty()


## Reproduced twice running this segment for real (OWNER-0901-PLAYER-SLEEP-V2):
## after Bram's third dialogue/shop cycle, `_prove_movement_resumed()`'s own
## exploratory nudge (four cardinal directions, whichever moves first) can
## leave the player off the door's own axis -- behind his counter, say -- and
## a single straight line from THERE to the door clips the room's furniture
## the same way `_enter_through`'s own header says an oblique entry clips a
## 1.6m opening. `_enter_through` never has this problem because it starts
## from a chosen standoff point on the door's axis; this now regains that same
## axis (the identical `step` point `_enter_through` walks to) before
## approaching the door, rather than one direct line from an arbitrary
## interior position.
func _exit_through(door: Node3D, inside_target: Vector3) -> bool:
	var outward := _door_outward(door, inside_target)
	var step := door.global_position - outward * DOOR_STEP_IN
	if not await _walk_toward(step, 700, 0.7):
		return false
	if not await _walk_toward(door.global_position, 400, 0.65):
		return false
	return await _walk_toward(door.global_position + outward * 2.4, 500, 0.7)


## Which way a door faces, as a planar unit vector pointing OUT of the building.
##
## `village_door.gd` is added as a child of the building at the recipe's doorway
## centre with no rotation of its own, so its global basis is the building's:
## local +z is the front the recipe authored the doorway into, for every prefab
## that declares a `door`. The dot product against a point known to be indoors
## is the guard for a recipe that ever authors one the other way round -- the
## harness should not be the thing that silently walks through a wall because a
## building was mirrored.
func _door_outward(door: Node3D, inside_target: Vector3) -> Vector3:
	var outward: Vector3 = door.global_transform.basis.z
	outward.y = 0.0
	if outward.length() < 0.01:
		outward = door.global_position - inside_target
		outward.y = 0.0
	var inward := inside_target - door.global_position
	inward.y = 0.0
	if outward.dot(inward) > 0.0:
		outward = -outward
	return outward.normalized()


func _nearest_door(npc: Node3D) -> Node3D:
	var best: Node3D = null
	var distance := INF
	for node: Node in _descendants(_world):
		if not node is Node3D or _script_path(node) != DOOR_SCRIPT:
			continue
		var gap := npc.global_position.distance_to((node as Node3D).global_position)
		# Outdoor villagers must not inherit a nearby cottage door.  Mira is a
		# few metres behind hers; Bram is at the far end of the longer inn.
		if gap < distance and gap < 10.5:
			distance = gap
			best = node as Node3D
	return best


func _npc_prompt(npc: Node3D) -> Node3D:
	for node: Node in _descendants(npc):
		if node is Node3D and _script_path(node) == INTERACTABLE_SCRIPT \
				and bool(node.get("enabled")):
			return node as Node3D
	return null


## Walk until the world OFFERS the thing, then press.
##
## Not "walk to within 1.65m, then press". A player presses when the prompt
## appears, and how far away that happens is the interactable's business -- some
## reach further than others, and a doorway's own frame can stop you closing the
## last metre. The distance-first version reported "could not reach or activate
## door 'Door' in 1200 frames (player 3.6m away, prompt enabled=true)": twenty
## seconds of walking into a wall while the door sat there, offerable, unpressed.
##
## So the offer is the success condition and the distance is only the fallback
## for something that is not currently winning.
## GATEB-COORD: pauses while the player cannot move, and starts over rather
## than spending one budget in one attempt.
##
## A wild creature picking a fight freezes locomotion
## (`encounter_director.gd::_set_exploration_active()`), and a walker that
## keeps pushing at a frozen body reads every frame as a stall and then sets
## off in a stale detour direction when the fight ends. Village doorframes and
## street furniture can require a second approach; one long attempt from a
## navigator boxed into a corner stays boxed in:
##
##   natural controller travel could not activate Mira cycle 1
##   (7.0m away, arbiter winner=EncounterDirector under MeadowsPlayground)
func _walk_to_and_activate(target: Node3D, budget: int, oskar_road: bool = false) -> bool:
	for attempt in 3:
		var headings: Array[Vector2] = []
		if oskar_road:
			var npc := _world.find_child("Oskar", true, false) as Node3D
			if npc == null or target != _npc_prompt(npc) or not _world.is_ancestor_of(target):
				_fail("authored Oskar guidance lacks the actual current-world prompt")
				return false
			var from := Vector2(_player.global_position.x, _player.global_position.z)
			var goal := Vector2(target.global_position.x, target.global_position.z)
			if from.distance_to(goal) > 4.0:
				headings = oskar_approach_path(_nav.authored_road_points("Practice Meadow"),
					_nav.authored_approach_points("village_main_street"),
					_nav.authored_approach_points("oskar_house_walk"), from, goal)
				if headings.is_empty() or _nav.refused():
					_fail("missing/malformed bounded authored Oskar approach")
					return false
		if await _one_approach(target, budget, headings):
			return true
		if not _failures.is_empty():
			return false
		_stop_left_stick()
		for _i in 30:
			await _tree.physics_frame
	return false


## Frames spent held do NOT count against the budget, for the same reason
## `stick_navigator.gd::walk_to()` says: the budget measures walking, and a
## fight that freezes the body for twenty seconds is not twenty seconds of
## failing to get somewhere. Counting them spent the whole allowance waiting
## and then reported the villager as unreachable from twenty-nine metres away.
func _one_approach(target: Node3D, budget: int, headings: Array[Vector2] = []) -> bool:
	_nav.reset()
	_nav.set_approach_radius(1.65 if headings.is_empty() else 0.8)
	var walked := 0
	var held := 0
	var heading_index := 0
	while walked < budget:
		if not _nav.can_walk():
			# Hands off while a fight owns the body; nothing learned during it
			# says anything about what is in the way.
			held += 1
			if held > 36000:
				return false
			_stop_left_stick()
			_nav.reset()
			await _tree.physics_frame
			continue
		if _nav.refused():
			_fail("Native opening refused: " + _nav.refusal_reason())
			return false
		walked += 1
		# Keep the same walking allowance and index through fights/resets. Every
		# authored bend is reached by observed real motion before the next one.
		if heading_index < headings.size() and not _nav.departure_pending(target.global_position):
			var at := Vector2(_player.global_position.x, _player.global_position.z)
			if at.distance_to(headings[heading_index]) <= 0.8 or _nav.heading_circled(headings[heading_index]):
				heading_index += 1
				_nav.reset()
				_nav.set_approach_radius(1.65 if heading_index == headings.size() else 0.8)
			if heading_index < headings.size():
				var next := headings[heading_index]
				await _nav.step(Vector3(next.x, target.global_position.y, next.y))
				if _nav.refused():
					_fail("Native authored Oskar approach refused: " + _nav.refusal_reason())
					return false
				continue
		if heading_index == headings.size() and not _nav.departure_pending(target.global_position) and _arbiter.call("winning_provider") == target:
			var activation := await _press_and_observe_activation(target)
			if activation == ActivationVerdict.TARGET:
				return true
			if activation == ActivationVerdict.COMPETING:
				_fail("physical interact meant for %s activated competing provider %s" % [
					target.name, _competing_activation])
				return false
			# The pre-press snapshot changed when production recomputed on the
			# physics tick and NOTHING activated, so this is still the same
			# approach -- keep walking/sidestepping within its original budget.
			_nav.reset()
			continue
		var to := target.global_position - _player.global_position
		to.y = 0.0
		if heading_index == headings.size() and not _nav.departure_pending(target.global_position) and to.length() <= 1.65:
			# Close enough, and something ELSE is holding the interact line.
			#
			# The village stands in open meadow and the arbiter ranks by
			# distance, so a wandering wild creature -- or any prop closer than
			# the villager -- takes the prompt. Breaking out here made that a
			# hard failure, which is why this segment could reach Tam on one run
			# and not the next with no code change between them: what was
			# standing nearby had changed.
			#
			# A player sidesteps and asks again. `smoke_party_count_after_catches.gd`
			# already fixed the identical thing this way after reporting "could
			# not engage" from 3.3m inside a 6.0m range.
			var aside := to.cross(Vector3.UP).normalized() * 1.4
			if walked % 2 == 1:
				aside = -aside
			# `push_once`, not the navigator's `step`: this is a deliberate 1.4m
			# shuffle to change the arbiter's mind, not a leg of travel, and
			# letting the detour machinery read it as one would have it fighting
			# the very stall the shuffle exists to create.
			for _j in 10:
				_nav.push_once(aside.normalized())
				await _tree.physics_frame
				if _nav.refused():
					_fail("Native opening shuffle refused: " + _nav.refusal_reason())
					return false
			_stop_left_stick()
			for _j in 6:
				await _tree.physics_frame
			_nav.reset()
			continue
		await _nav.step(target.global_position)
		if _nav.refused():
			_fail("Native opening refused: " + _nav.refusal_reason())
			return false
	_stop_left_stick()
	# Standing close and still not winning: give the arbiter a few frames to
	# settle before giving up, which is what the previous version did and is
	# still right once the walking is over.
	for _i in 30:
		if heading_index == headings.size() and not _nav.departure_pending(target.global_position) and _arbiter.call("winning_provider") == target:
			var activation := await _press_and_observe_activation(target)
			if activation == ActivationVerdict.TARGET:
				return true
			if activation == ActivationVerdict.COMPETING:
				_fail("physical interact meant for %s activated competing provider %s" % [
					target.name, _competing_activation])
				return false
		await _tree.physics_frame
	return false


## Join existing painted roads without claiming their geometry is clear. Only
## same-direction collinear intermediate coordinates may be compressed; bends
## and the unchanged eight-choice/edge bounds are preserved.
static func oskar_approach_path(meadow: Array[Vector2], street: Array[Vector2], approach: Array[Vector2], from: Vector2, goal: Vector2) -> Array[Vector2]:
	if not from.is_finite() or not goal.is_finite():
		return []
	for road: Array[Vector2] in [meadow, street, approach]:
		if road.size() < 2 or road.size() > NAVIGATOR.MAX_ROAD_INPUTS:
			return []
		for index in road.size():
			if not road[index].is_finite() or (index > 0 \
					and (road[index - 1].distance_to(road[index]) <= NAVIGATOR.CONTACT_EPS \
					or road[index - 1].distance_to(road[index]) > NAVIGATOR.MAX_EDGE)):
				return []
	var street_join := NAVIGATOR.road_slice(street, meadow[0], approach[0])
	if street_join.is_empty() or street_join[0].distance_to(meadow[0]) > NAVIGATOR.CONTACT_EPS \
			or street_join.back().distance_to(approach[0]) > NAVIGATOR.CONTACT_EPS \
			or approach.back().distance_to(goal) > 1.65:
		return []
	var meadow_leg := NAVIGATOR.road_slice(meadow, from, meadow[0])
	var street_leg := NAVIGATOR.road_slice(street, from, approach[0])
	if meadow_leg.is_empty() or street_leg.is_empty():
		return []
	var raw: Array[Vector2] = []
	if from.distance_to(meadow_leg[0]) < from.distance_to(street_leg[0]):
		raw.append_array(meadow_leg)
		raw.append_array(street_join)
	else:
		raw.append_array(street_leg)
	raw.append_array(approach)
	# The actual prompt remains _one_approach's final activation/walking target.
	# Count only authored headings here; appending that same prompt made an
	# otherwise valid eight-bend deep-meadow return incorrectly require nine.
	var result: Array[Vector2] = []
	for point: Vector2 in raw:
		if not result.is_empty() and result.back().distance_to(point) <= NAVIGATOR.CONTACT_EPS:
			continue
		if result.size() >= 2:
			var incoming: Vector2 = result.back() - result[result.size() - 2]
			var outgoing: Vector2 = point - result.back()
			if absf(incoming.cross(outgoing)) <= NAVIGATOR.CONTACT_EPS \
					and incoming.dot(outgoing) > 0.0:
				result.pop_back()
		result.append(point)
	if result.size() > NAVIGATOR.MAX_CHOICES:
		return []
	var previous := from
	for point: Vector2 in result:
		if previous.distance_to(point) > NAVIGATOR.MAX_EDGE:
			return []
		previous = point
	return result


## A physical press succeeds only when the live arbiter says the requested
## provider was actually activated.  Checking the winner before the press is
## insufficient: `interaction_arbiter.gd::_physics_process()` deliberately
## recomputes it at the button edge to avoid an idle/physics-clock race.
func _press_and_observe_activation(target: Object) -> int:
	_stop_left_stick()
	_activation_target = target
	_activation_verdict = ActivationVerdict.NONE
	_competing_activation = ""
	await _tap_action(&"interact")
	_activation_target = null
	return _activation_verdict


func _on_arbiter_activated(provider: Object) -> void:
	if _activation_target == null:
		return
	_activation_verdict = activation_verdict(provider, _activation_target)
	if _activation_verdict == ActivationVerdict.COMPETING:
		_competing_activation = provider.name if provider is Node else str(provider)


static func activation_verdict(provider: Object, target: Object) -> int:
	if provider == null:
		return ActivationVerdict.NONE
	return ActivationVerdict.TARGET if provider == target else ActivationVerdict.COMPETING


## Native opening queries share the real stick seam and original frame budgets.


func _walk_diagnosis(point: Vector3) -> String:
	var colliders: Array[String] = []
	for index in _player.get_slide_collision_count():
		var collider: Object = _player.get_slide_collision(index).get_collider()
		colliders.append(str((collider as Node).get_path()) if collider is Node else str(collider))
	return "player=%s target=%s distance=%.2f colliders=%s" % [_player.global_position, point,
		Vector2(point.x - _player.global_position.x, point.z - _player.global_position.z).length(), colliders]


func _walk_toward(point: Vector3, budget: int, close_enough: float = 0.8, authored_road: String = "", end_road_at_goal: bool = false, provisional_path: Array[Vector2] = []) -> bool:
	var arrived: bool = await _nav.walk_to(point, budget, close_enough, authored_road, end_road_at_goal, provisional_path)
	_stop_left_stick()
	if _nav.refused():
		_fail("Native opening refused: " + _nav.refusal_reason())
		return false
	if arrived:
		for _i in 5:
			await _tree.physics_frame
	return arrived


func _prove_movement_resumed(door: Node3D = null, inside_target: Vector3 = Vector3.ZERO) -> bool:
	# Say WHICH of the four ways this fails. "Movement stayed dead" covers a
	# paused tree, a stale input owner, a cleared locomotion flag and a player
	# who simply could not walk anywhere, and those are four different bugs
	# with four different fixes -- the caller used to report them identically.
	#
	# Given TIME, though. `_wait_world_owned()` clears the moment the panel is
	# gone, and `sequence_director.gd::_refresh_lockout` hands locomotion back a
	# little after that -- the fade is still running. Sampling the flag on the
	# first frame after the modal closed therefore fails intermittently on a beat
	# that is working: one run of this file reported "movement dead:
	# locomotion_enabled is false" at Tam where four earlier runs of the same
	# unchanged code walked away from him fine. A player waits for the fade; so
	# does this, and only then is a still-dead flag real evidence.
	for _i in 120:
		if not _tree.paused and INPUT_OWNER.current(_tree) == null \
				and bool(_player.call("locomotion_enabled")):
			break
		await _tree.physics_frame
	if _tree.paused:
		print("movement dead: the scene tree is still paused")
		return false
	var owner_node: Variant = INPUT_OWNER.current(_tree)
	if owner_node != null:
		print("movement dead: input still owned by %s" % str(owner_node))
		return false
	if not bool(_player.call("locomotion_enabled")):
		print("movement dead: locomotion_enabled is false after two seconds of waiting")
		return false
	# An indoor greeting first returns toward the SAME doorway-axis point already
	# used by _exit_through. The camera's forward nudge pointed into guest
	# furniture in CI6173; the aisle uses these existing frames instead.
	var aisle := Vector3.INF
	if door != null:
		aisle = doorway_resume_goal(door.global_position, _door_outward(door, inside_target))
		if not aisle.is_finite():
			_fail("invalid doorway-axis movement-resume hint")
			return false
	# Try four physical directions because a villager counter or wall can block
	# one without implying dead world input.  This is ordinary walking, not a
	# relocation shortcut, and leaves the player wherever the successful step
	# naturally ended.
	for axis: Vector2 in [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]:
		var before := _player.global_position
		_nav.reset()
		for _i in 22:
			if axis == Vector2(0, -1) and aisle.is_finite():
				await _nav.step(aisle)
			else:
				var basis: Basis = _rig.call("planar_basis")
				var requested := basis * Vector3(axis.x, 0.0, axis.y)
				_nav.push_once(requested)
				await _tree.physics_frame
			if _nav.refused():
				_stop_left_stick()
				_fail("Native opening refused during movement resume: " + _nav.refusal_reason())
				return false
		_stop_left_stick()
		for _i in 4:
			_nav.push_once(Vector3.ZERO)
			await _tree.physics_frame
			if _nav.refused():
				_fail("Native opening refused during movement-resume settle: " + _nav.refusal_reason())
				return false
		if Vector2(_player.global_position.x - before.x,
				_player.global_position.z - before.z).length() >= 0.3:
			return true
	print("movement dead: locomotion is live but four stick directions moved the player nowhere from (%.2f, %.2f, %.2f)" % [
		_player.global_position.x, _player.global_position.y, _player.global_position.z,
	])
	return false


## Heading only. Original door, inward distance, stick input, frame allowance,
## displacement witness and both actual native guards remain decisive.
static func doorway_resume_goal(door: Vector3, outward: Vector3) -> Vector3:
	if not door.is_finite() or not outward.is_finite() or absf(outward.y) > 0.00001 \
			or absf(outward.length_squared() - 1.0) > 0.00001:
		return Vector3.INF
	return door - outward * DOOR_STEP_IN


func _wait_dialogue_open(budget: int) -> bool:
	for _i in budget:
		if bool(_dialogue.call("is_open")):
			return true
		await _tree.process_frame
	return false


func _close_dialogue(max_presses: int) -> bool:
	for _i in max_presses:
		if not bool(_dialogue.call("is_open")):
			return true
		await _tap_action(&"interact")
	return not bool(_dialogue.call("is_open"))


func _wait_open_panel(script_suffix: String, budget: int) -> Node:
	for _i in budget:
		for node: Node in _tree.get_nodes_in_group(INPUT_OWNER.GROUP):
			if (_script_path(node).ends_with(script_suffix) and node.has_method("is_open")
					and bool(node.call("is_open"))):
				return node
		await _tree.process_frame
	return null


func _wait_world_owned(budget: int) -> bool:
	for _i in budget:
		if (not _tree.paused and INPUT_OWNER.current(_tree) == null
				and not bool(_dialogue.call("is_open")) and not bool(_menu.call("is_open"))):
			return true
		await _tree.process_frame
	return false


func _tap_action(action: StringName) -> void:
	var event := _event_for(action, true)
	if event == null:
		_fail("'%s' has no physical joypad binding" % action)
		return
	Input.parse_input_event(event)
	for _i in 3:
		await _tree.physics_frame
	# Menus poll `is_action_just_pressed` from `_process`. On a slow runner the
	# three physics ticks above can all fall inside one rendered frame, and a
	# release parsed before any `_process` poll ran drops the tap entirely.
	# Hold through two rendered frames as well, as a real finger does.
	for _i in 2:
		await _tree.process_frame
	var released := event.duplicate() as InputEvent
	if released is InputEventJoypadButton:
		(released as InputEventJoypadButton).pressed = false
	elif released is InputEventJoypadMotion:
		(released as InputEventJoypadMotion).axis_value = 0.0
	Input.parse_input_event(released)
	for _i in 5:
		await _tree.physics_frame


func _event_for(action: StringName, pressed: bool) -> InputEvent:
	if not InputMap.has_action(action):
		return null
	for configured: InputEvent in InputMap.action_get_events(action):
		if configured is InputEventJoypadButton:
			var button := InputEventJoypadButton.new()
			button.device = 0
			button.button_index = (configured as InputEventJoypadButton).button_index
			button.pressed = pressed
			return button
		if configured is InputEventJoypadMotion:
			var motion := InputEventJoypadMotion.new()
			motion.device = 0
			motion.axis = (configured as InputEventJoypadMotion).axis
			motion.axis_value = (configured as InputEventJoypadMotion).axis_value if pressed else 0.0
			return motion
	return null


func _required_pad_actions_exist() -> bool:
	for action: StringName in [&"inventory", &"backpack_assign", &"ui_up", &"ui_down",
			&"ui_left", &"ui_right", &"menu_cancel", &"interact",
			&"hotbar_1", &"hotbar_2", &"hotbar_3"]:
		if _event_for(action, true) == null:
			_fail("required action '%s' has no physical joypad binding" % action)
	return _failures.is_empty()


func _send_axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis
	event.axis_value = clampf(value, -1.0, 1.0)
	Input.parse_input_event(event)


## The left stick, as `stick_navigator.gd` asks for it. Still a real
## `InputEventJoypadMotion` on device 0 -- which is also why `Input.action_press`
## is gone from this file: a detour driven by poking action strengths directly
## would not have been travel by the player's own left stick, and this segment's
## header makes that a load-bearing constraint.
func _send_stick(x: float, y: float) -> void:
	_mira_road_run_edge(x != 0.0 or y != 0.0)
	if _mira_run_refused:
		x = 0.0
		y = 0.0
	_send_axis(JOY_AXIS_LEFT_X, x)
	_send_axis(JOY_AXIS_LEFT_Y, y)


func _stop_left_stick() -> void:
	_send_axis(JOY_AXIS_LEFT_X, 0.0)
	_send_axis(JOY_AXIS_LEFT_Y, 0.0)


func _script_path(node: Node) -> String:
	var script := node.get_script() as Script
	return script.resource_path if script != null else ""


func _descendants(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child: Node in node.get_children():
		out.append_array(_descendants(child))
	return out


func _checkpoint(label: String) -> void:
	print("GATE A NPC/GATHER +%.2fs — %s" % [
		(Time.get_ticks_msec() - _started_ms) / 1000.0, label])


func _fail(message: String) -> void:
	if not _failures.has(message):
		_failures.append(message)
	push_error(message)
