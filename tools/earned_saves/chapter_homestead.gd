extends RefCounted

## Routes owns saved-piece wiring; Fights owns the paid Kitchen/feed/storage UI.
## Portal return ends at the authored arrival, never at the remote Master.
const TRAINING := preload("res://tools/earned_saves/training_handoff.gd")
const PORTAL := preload("res://tests/helpers/f49_portal_travel.gd")
const SPECS := {3: {"realm": "water", "arch": "tidewake", "kitchen": 2},
	4: {"realm": "cloudreach", "arch": "cloudreach", "kitchen": 3},
	5: {"realm": "stormwood", "arch": "stormwood", "kitchen": 4}}
const HELPERS := {"storage": "res://tools/earned_saves/wip_fights/storage_trip.gd",
	"kitchen": "res://tools/earned_saves/wip_fights/kitchen.gd",
	"feed": "res://tools/earned_saves/wip_fights/cook_feed.gd"}

static func spec(segment: String) -> Dictionary:
	var fields := segment.split("_")
	if fields.size() != 3 or fields[0] != "training" or fields[1] not in ["t3", "t4", "t5"] \
			or fields[2] not in ["home", "storage", "kitchen", "feed", "return"]: return {}
	var tier := int(fields[1].trim_prefix("t"))
	var result: Dictionary = SPECS[tier].duplicate()
	result.merge({"tier": tier, "phase": fields[2], "master": "master_t%d" % tier, "feast": "feast_t%d" % tier})
	return result

static func preflight(training: Dictionary, job: Dictionary, realm: String) -> Array[String]:
	var errors: Array[String] = []
	if job.is_empty(): return ["Unknown homestead training piece"]
	if realm != (str(job.realm) if job.phase == "home" else "meadows"):
		errors.append("Training piece starts in the wrong realm")
	if not training.get("master_wins", []).has(job.master): errors.append("Saved Master win required")
	if job.phase in ["kitchen", "feed"] and not training.get("feast_recipes", []).has(job.feast):
		errors.append("Saved chest recipe required before Kitchen/feed")
	var party: Array = training.get("party", [])
	if party.size() != 5: return errors + ["Training piece requires the retained five"]
	var seen := {}
	for card: Dictionary in party:
		var uid := str(card.get("uid", ""))
		if uid.is_empty() or seen.has(uid): errors.append("Missing or duplicate retained UID")
		seen[uid] = true
		if job.phase == "feed":
			var prior: Array = []
			for tier in range(1, int(job.tier)): prior.append(tier)
			if card.get("level") != int(job.tier) * 10 or card.get("cap_level") != int(job.tier) * 10 \
					or card.get("xp") != 0 or card.get("breakthroughs") != prior:
				errors.append("Feed requires every retained companion at its earned locked cap with exact prior tiers")
	return errors

static func postflight(before: Dictionary, after: Dictionary, job: Dictionary) -> Array[String]:
	if job.phase != "feed": return [] if before == after else ["Non-feed piece changed training state"]
	var old: Array = before.get("party", [])
	var next: Array = after.get("party", [])
	if old.size() != 5 or next.size() != 5: return ["Feed lost the retained five"]
	var expected: Array = []
	for tier in range(1, int(job.tier) + 1): expected.append(tier)
	for index in 5:
		for key: String in ["uid", "level", "xp"]:
			if old[index].get(key) != next[index].get(key): return ["Feed changed " + key]
		if next[index].get("cap_level") != (int(job.tier) + 1) * 10 or next[index].get("breakthroughs") != expected:
			return ["Feed did not advance every retained companion exactly one tier"]
	var preserved := before.duplicate(true)
	preserved.party = next.duplicate(true)
	return [] if preserved == after else ["Feed changed unrelated Master/recipe history"]

func run(tree: SceneTree, world: Node3D, game: Node, args: Dictionary) -> Dictionary:
	if tree == null or not is_instance_valid(world) or not is_instance_valid(game) \
			or tree.current_scene != world or bool(game.get("free_build")):
		return {"passed": false, "failures": ["Homestead piece requires the actual loaded world with paid building"], "receipts": []}
	var job := spec(str(args.get("segment", "")))
	var before := TRAINING.snapshot(game)
	var seam := TRAINING.compare({"training": args.get("previous_training", {})}, {"training": before})
	var errors := preflight(before, job, str(game.current_realm))
	if not bool(seam.matches): errors.append("Homestead training differs from loaded predecessor")
	if not errors.is_empty(): return {"passed": false, "failures": errors, "receipts": []}
	var outcome: Dictionary
	if job.phase in ["home", "return"]:
		var travel := PORTAL.new(tree, game)
		var passed: bool = await travel.home_key() if job.phase == "home" else await travel.enter(job.arch, job.realm)
		outcome = {"passed": passed, "failures": travel.failures.duplicate(), "receipts": [{"phase": job.phase, "realm": str(game.current_realm)}]}
	else:
		var path: String = HELPERS[job.phase]
		if not ResourceLoader.exists(path):
			return {"passed": false, "failures": ["Integrate Fights helper before this piece: " + path], "receipts": []}
		var options := {"station_tier": int(job.kitchen), "feast_id": str(job.feast),
			"choices": args.get("choices", {}), "keep": args.get("keep", []), "return": false}
		outcome = await (load(path) as Script).new().run(tree, world, game, options)
	var after := TRAINING.snapshot(game)
	if bool(outcome.get("passed", false)):
		errors = postflight(before, after, job)
		outcome["failures"] = outcome.get("failures", []) + errors
		outcome["passed"] = outcome.failures.is_empty()
	var receipts: Array = outcome.get("receipts", [])
	receipts.append({"phase": job.phase, "training_before": before, "training_after": after, "reload_verified": false})
	outcome["receipts"] = receipts
	return outcome
