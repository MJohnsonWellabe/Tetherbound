extends SceneTree

## CL-E1 runtime proof, run once and not part of the suite: the C-3 profiles
## authored on `captain_riverwatch` are actually merged onto a live body's
## enemy config by the same call `wild_creature.set_engaged()` makes, and the
## third member is genuinely left on the shipped default.
##
## Why a probe and not a test: the natural home for the assertion is
## `tests/test_encounter_combat_override.gd`, which lane W10-TRAINER-RULES owns
## this round. See ralph/reports/W20-SMALL-FIXES-0904/REPORT.md.

const WILD := preload("res://scripts/creatures/wild_creature.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const BAND_CONTENT := preload("res://scripts/data/band_content.gd")


func _init() -> void:
	var merged: Array = BAND_CONTENT.load_config(
		"res://data/config/trainers.json", "trainers").get("trainers", []) as Array
	var oreth: Dictionary = {}
	for entry: Variant in merged:
		if str((entry as Dictionary).get("id", "")) == "captain_riverwatch":
			oreth = entry
	if oreth.is_empty():
		print("[oreth] FAIL: captain_riverwatch is not in the merged trainer table")
		quit(1)
		return
	var shipped: Dictionary = MATH.config().get("enemy", {})
	print("[oreth] shipped enemy defaults: telegraph=%s recovery=%s cooldown=%s power=%s reposition_distance=%s chase_speed=%s"
		% [shipped.get("telegraph"), shipped.get("recovery"), shipped.get("attack_cooldown"),
			shipped.get("power"), shipped.get("reposition_distance"), shipped.get("chase_speed")])
	var configs: Array[Dictionary] = []
	for member: Variant in (oreth.get("team", []) as Array):
		var block: Dictionary = (member as Dictionary).get("combat", {})
		var body := WILD.new()
		body.combat_override = block
		var cfg: Dictionary = body._enemy_config_for_this_body()
		body.free()
		configs.append(cfg)
		print("[oreth] %s L%d -> telegraph=%s recovery=%s cooldown=%s power=%s reposition_distance=%s reposition_time=%s chase_speed=%s"
			% [str((member as Dictionary).get("species", "?")),
				int((member as Dictionary).get("level", 0)),
				cfg.get("telegraph"), cfg.get("recovery"), cfg.get("attack_cooldown"),
				cfg.get("power"), cfg.get("reposition_distance"),
				cfg.get("reposition_time"), cfg.get("chase_speed")])
	var ok := true
	ok = ok and _expect(configs[0], {"telegraph": 0.85, "recovery": 1.1, "power": 12.0,
		"chase_speed": 3.4, "reposition_distance": 2.5}, "mosshell/WALL")
	ok = ok and _expect(configs[2], {"attack_cooldown": 0.7, "recovery": 0.55,
		"reposition_time": 0.5, "reposition_distance": 2.0, "power": 6.4}, "brooktail/CURRENT")
	# The middle member must be byte-identical to the shipped block.
	if configs[1] != shipped:
		print("[oreth] FAIL: trailpup should carry no override at all")
		ok = false
	# And the two profiles must be tellable apart on the numbers the player reads.
	if is_equal_approx(float(configs[0].get("telegraph")), float(configs[2].get("telegraph"))) \
			or is_equal_approx(float(configs[0].get("power")), float(configs[2].get("power"))):
		print("[oreth] FAIL: WALL and CURRENT resolve to the same telegraph or power")
		ok = false
	print("[oreth] %s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)


func _expect(cfg: Dictionary, want: Dictionary, label: String) -> bool:
	for key: String in want:
		if not is_equal_approx(float(cfg.get(key, NAN)), float(want[key])):
			print("[oreth] FAIL %s: %s is %s, expected %s" % [label, key, str(cfg.get(key)), str(want[key])])
			return false
	return true
