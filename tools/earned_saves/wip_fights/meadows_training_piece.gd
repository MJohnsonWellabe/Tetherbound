extends RefCounted

## One bounded CARD:M2 piece per process. Routes owns loading/exporting the
## actual earned save and supplies its previous training snapshot. Comparing
## snapshots is a seam check, not proof of the checkpoint's earned provenance.
## Use master -> kitchen -> feed at L10, then actual earned training to L20,
## then master -> kitchen -> feed again. Both Meadows feasts need Kitchen 1.
## For matched Evolve/Stay, run feed twice from the same exported checkpoint;
## that checkpoint must already own the catalyst through an earned pickup.
const MASTER := preload("res://tools/earned_saves/wip_fights/meadows_master.gd")
const KITCHEN := preload("res://tools/earned_saves/wip_fights/kitchen.gd")
const FEED := preload("res://tools/earned_saves/wip_fights/cook_feed.gd")
const HANDOFF_PATH := "res://tools/earned_saves/training_handoff.gd"

func run(tree: SceneTree, world: Node3D, game: Node, args: Dictionary = {}) -> Dictionary:
	var tier := int(args.get("tier", 0))
	var phase := str(args.get("phase", ""))
	if tier not in [1, 2] or phase not in ["master", "kitchen", "feed"]:
		return _failed("Expected Meadows tier 1/2 and one master/kitchen/feed phase")
	if tree == null or not is_instance_valid(game) or not is_instance_valid(world) or tree.current_scene != world:
		return _failed("Training piece requires the actual loaded world and character")
	if not ResourceLoader.exists(HANDOFF_PATH):
		return _failed("Integrate Routes-owned training_handoff.gd before this piece")
	var handoff: Script = load(HANDOFF_PATH)
	var before: Dictionary = handoff.snapshot(game)
	var seam: Dictionary = handoff.compare({"training": args.get("previous_training", {})}, {"training": before})
	if not bool(seam.get("matches", false)):
		return _failed("Loaded earned checkpoint differs from previous training snapshot: " + str(seam.get("reason", "")))
	var errors := preflight(before, tier, phase)
	if not errors.is_empty(): return {"passed": false, "failures": errors, "receipts": []}
	var outcome: Dictionary
	match phase:
		"master":
			outcome = await MASTER.new().run(tree, world, game, {"master_id": "master_t%d" % tier,
				"creature_uid": str(args.get("creature_uid", ""))})
		"kitchen":
			outcome = await KITCHEN.new().run(tree, world, game, {"station_tier": 1})
		"feed":
			outcome = await FEED.new().run(tree, world, game, {"feast_id": "feast_t%d" % tier,
				"choices": args.get("choices", {})})
	var after: Dictionary = handoff.snapshot(game)
	if bool(outcome.get("passed", false)):
		errors = postflight(before, after, tier, phase)
		outcome["failures"] = outcome.get("failures", []) + errors
		outcome["passed"] = outcome.failures.is_empty()
	var receipts: Array = outcome.get("receipts", [])
	receipts.push_front({"beat": "training_piece_input", "tier": tier, "phase": phase, "training": before, "seam": seam})
	receipts.append({"beat": "training_piece_output", "training": after, "reload_verified": false})
	outcome["receipts"] = receipts
	outcome["training"] = after
	return outcome

static func preflight(training: Dictionary, tier: int, phase: String) -> Array[String]:
	var errors: Array[String] = []
	var party: Array = training.get("party", [])
	if party.size() != 5: return ["Matched Meadows piece requires all five earned companions"]
	var seen := {}
	for card: Dictionary in party:
		var uid := str(card.get("uid", ""))
		if uid.is_empty() or seen.has(uid): errors.append("Missing or duplicate retained creature identity")
		seen[uid] = true
		if int(card.get("level", -1)) != tier * 10 or int(card.get("cap_level", -1)) != tier * 10 or int(card.get("xp", -1)) != 0:
			errors.append("All five companions must reach the authored locked cap through prior earned training")
		var expected: Array = [] if tier == 1 else [1]
		if card.get("breakthroughs", []) != expected: errors.append("Missing exact prior breakthrough history")
	if phase != "master":
		if not training.get("master_wins", []).has("master_t%d" % tier) or not training.get("feast_recipes", []).has("feast_t%d" % tier):
			errors.append("Master win and chest recipe must be saved before the homestead piece")
	return errors

static func postflight(before: Dictionary, after: Dictionary, tier: int, phase: String) -> Array[String]:
	var errors: Array[String] = []
	var old: Array = before.get("party", [])
	var next: Array = after.get("party", [])
	if old.size() != 5 or next.size() != 5: return ["Piece lost the retained five"]
	for i in old.size():
		for key: String in ["uid", "level", "xp"]:
			if old[i].get(key) != next[i].get(key): errors.append("Piece changed " + key + " outside earned training")
		if phase == "feed":
			var expected: Array = [1] if tier == 1 else [1, 2]
			if next[i].get("breakthroughs", []) != expected or int(next[i].get("cap_level", -1)) != (tier + 1) * 10:
				errors.append("Feed piece did not open the next cap for every retained companion")
		elif old[i] != next[i]: errors.append("Non-feed piece changed creature training")
	if not after.get("master_wins", []).has("master_t%d" % tier) or not after.get("feast_recipes", []).has("feast_t%d" % tier):
		errors.append("Piece lacks the durable Master win and chest recipe")
	return errors

static func _failed(message: String) -> Dictionary:
	return {"passed": false, "failures": [message], "receipts": []}
