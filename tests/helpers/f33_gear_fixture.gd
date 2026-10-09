extends RefCounted

## F33#2 (disclosed fixture) shared by the boss sims: the party's creature gear
## written straight into the real owner record, where the production combat
## hooks read it (encounter_director / combat_manager / encounter_host). These
## sim-only rows are not full creature records, so a geared sim detaches the
## save system: an autosave would (rightly) refuse them, and a balance sim
## saves nothing. The in-world smoke can retain its isolated saver explicitly
## after producing complete owner records. Bare (empty tier) leaves them as is.
##   --gear-tier=<rootiron|tidesteel|skyglass|stormglass> [--gear-upgrade=0..3]


## Returns {"tier", "upgrade"} from the script's user args.
static func from_args() -> Dictionary:
	var out := {"tier": "", "upgrade": 0}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--gear-tier="): out.tier = arg.trim_prefix("--gear-tier=")
		elif arg.begins_with("--gear-upgrade="): out.upgrade = clampi(int(arg.trim_prefix("--gear-upgrade=")), 0, 3)
	return out


static func equip(tree: SceneTree, party: Array[RefCounted], tier: String, upgrade: int, detach_saving: bool = true) -> void:
	if tier.is_empty(): return
	var game := tree.root.get_node("Game")
	if detach_saving: game.set("save_system", null)
	var character: Dictionary = (game.get("local") as RefCounted).get("redesign_character")
	var creatures: Dictionary = character.get("creatures", {})
	var suffix := "" if upgrade == 0 else "_plus_%d" % upgrade
	for creature: RefCounted in party:
		var uid := str(creature.get("uid"))
		# The in-world named-fight smoke supplies complete production mirrors and
		# an isolated saver. Other balance sims keep their detached legacy setup.
		var record: Dictionary = {} if detach_saving else creatures.get(uid, {}).duplicate(true)
		record["gear"] = {"harness": tier + "_harness" + suffix, "charm": tier + "_charm" + suffix}
		creatures[uid] = record
	character["creatures"] = creatures


static func label(tier: String, upgrade: int) -> String:
	return "bare" if tier.is_empty() else tier + ("" if upgrade == 0 else "+%d" % upgrade)
