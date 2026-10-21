extends "res://tests/helpers/meadows_earned_team_segment.gd"

## training_t<1|2>_earn: earn the essence/XP that the next five paid Altar
## slots spend. The earned route through the South Bridge fights no ordinary
## wilds (the team reaches L5 on authored candy) and releases nothing, so its
## save holds no essence. A player then trains on the practice meadow: this
## piece reuses the team segment's own wild choice, approach, pilot care and
## piloted fight, and stops once every retained companion's remaining levels
## to its cap are covered by its earned XP, compatible essence or Tether
## Candy. Nothing is granted, written or skipped; each win is a production
## victory with its own durable essence/XP receipts.
const TRAINING := preload("res://tools/earned_saves/training_handoff.gd")
const TRAVEL := preload("res://tests/helpers/f20_portal_travel.gd")
const PROGRESSION_CFG := "res://data/config/progression.json"
const MAX_EARN_FIGHTS := 240
## The practice meadow's L2-5 rabbits pay ~10 XP a member and one essence a
## win (measured: 17 unfunded levels after 3 wins). A player training toward
## the L10 Master fights the Lower Meadows wilds around the village instead:
## any unowned wild within this ring, at or below the pilot's level (the team
## segment's own level_matched filter) and never above the tier's cap.
const EARN_CENTRE := Vector2(-20.0, 140.0)
const EARN_RADIUS := 260.0
var _tier_cap := 10


## Levels that the carried essence and candy cannot yet pay, given each
## companion's level, cap and essence types. One priced level per payment,
## as the Altar quotes it; candy pays any level.
static func unfunded_levels(cards: Array, stock: Dictionary, price: Callable, candy_item: String) -> int:
	var pools := stock.duplicate()
	var gap := 0
	for card: Dictionary in cards:
		for level in range(int(card.level), int(card.cap)):
			var cost: int = price.call(level)
			var paid := false
			for item: String in card.items:
				if cost > 0 and int(pools.get(item, 0)) >= cost:
					pools[item] = int(pools[item]) - cost
					paid = true
					break
			if not paid and int(pools.get(candy_item, 0)) > 0:
				pools[candy_item] = int(pools[candy_item]) - 1
				paid = true
			if not paid:
				gap += 1
	return gap


func run_earning(tree: SceneTree, world: Node3D, game: Node, args: Dictionary = {}) -> Dictionary:
	_tree = tree
	_world = world
	_game = game
	if tree == null or not is_instance_valid(world) or not is_instance_valid(game) or tree.current_scene != world \
			or str(game.get("current_realm")) != "meadows" or INPUT_OWNER.current(tree) != null:
		_fail("Essence earning needs the loaded Meadows with ordinary input")
		return result()
	var before := TRAINING.snapshot(game)
	if not TRAINING.compare({"training": args.get("previous_training", {})}, {"training": before}).matches:
		_fail("Essence earning input differs from the loaded predecessor's training")
		return result()
	_player = world.get_node_or_null("Player") as CharacterBody3D
	# The bridge piece ends on the far bank. The Home Key is the ordinary way back.
	if _player != null and Vector2(_player.global_position.x, _player.global_position.z).distance_to(PRACTICE_CENTRE) > 400.0:
		var travel = TRAVEL.new(tree, game)
		if not await travel.home_key():
			_failures.append_array(travel.failures)
			return result()
		_world = tree.current_scene as Node3D
		_receipt("home_key", {"landed": (_world.get_node("Player") as Node3D).global_position})
	if not _bind():
		return result()
	_initial_ids = _party_ids()
	_tier_cap = int(args.get("tier", 1)) * 10
	var wins := 0
	var gap := _gap()
	_receipt("earning_start", {"unfunded_levels": gap, "party": _party_snapshot(), "stock": _stock()})
	while gap > 0 and wins < MAX_EARN_FIGHTS:
		if not await _prepare_pilot(true) or not await _field_pilot():
			return result()
		var wild := _choose_wild()
		if wild == null:
			_respawn_waits += 1
			if not await _wait_for_training_respawn(wins):
				return result()
			continue
		var party_before := _party_snapshot()
		# The native navigator's plan/choice caps are lifetime counts sized
		# for one team-segment run; give each engagement its own, as each
		# segment run gets (49 wins exhausted MAX_PLANS in one instance).
		_nav = NAV.new(_tree, _player, _rig, _stick, true)
		if not await _engage(wild, true):
			return result()
		if not await _win_live_fight(true):
			if not _failures.is_empty():
				return result()
			_avoid.append(wild)
			continue
		wins += 1
		gap = _gap()
		_receipt("earning_win", {"number": wins, "unfunded_levels": gap, "before": party_before,
			"after": _party_snapshot(), "stock": _stock()})
	if gap > 0:
		_fail("Earning budget ended with %d retained levels still unfunded" % gap)
		return result()
	if _party_ids() != _initial_ids:
		_fail("Essence earning changed a permanent team member")
		return result()
	_completed = true
	_receipt("earning_funded", {"wins": wins, "respawn_waits": _respawn_waits, "training_losses": _training_losses,
		"training_before": before, "training_after": TRAINING.snapshot(game), "stock": _stock()})
	return result()


func _training_eligible(body: Node3D, owned: Array[int]) -> bool:
	var creature: RefCounted = body.get("instance")
	if creature == null or owned.has(creature.get_instance_id()) or int(creature.get("level")) > _tier_cap:
		return false
	var home: Vector3 = body.get("home") if body.get("home") is Vector3 else body.global_position
	return Vector2(home.x, home.z).distance_to(EARN_CENTRE) <= EARN_RADIUS


func _bind() -> bool:
	_player = _world.get_node_or_null("Player") as CharacterBody3D
	_rig = _world.get_node_or_null("CameraRig") as Node3D
	_director = _world.get_node_or_null("EncounterDirector")
	_combat = _world.get_node_or_null("CombatManager")
	_arbiter = _tree.get_first_node_in_group("interaction_arbiter")
	_menu = _game.call("menu")
	if _player == null or _rig == null or _director == null or _combat == null or _arbiter == null or _menu == null:
		return _fail("Essence earning lacks a production input/combat dependency")
	_nav = NAV.new(_tree, _player, _rig, _stick, true)
	return true


func _gap() -> int:
	var cfg := ESSENCE.config()
	var progression: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PROGRESSION_CFG))
	var personal: Dictionary = _game.get("local").get("redesign_character")
	var cards: Array = []
	for member: RefCounted in _party().call("members"):
		var items: Array[String] = []
		for type_id: String in ESSENCE._species_types({"species_id": member.get("species_id"),
				"creature_type": member.get("creature_type"), "secondary_type": member.get("secondary_type")}):
			items.append(ESSENCE.essence_item(type_id))
		cards.append({"level": int(member.get("level")), "cap": ESSENCE.creature_cap(personal, str(member.get("uid"))), "items": items})
	return unfunded_levels(cards, _stock(), func(level: int) -> int: return ESSENCE.level_cost(level, cfg, progression),
		str(cfg.get("tether_candy_item", "tether_candy")))


func _stock() -> Dictionary:
	var inventory: RefCounted = _game.get("inventory")
	var stock := {}
	for row: Dictionary in preload("res://scripts/data/redesign_data.gd").json_view("res://data/schema/essences.json"):
		stock[str(row.id)] = int(inventory.call("count", str(row.id)))
	var candy := str(ESSENCE.config().get("tether_candy_item", "tether_candy"))
	stock[candy] = int(inventory.call("count", candy))
	return stock
