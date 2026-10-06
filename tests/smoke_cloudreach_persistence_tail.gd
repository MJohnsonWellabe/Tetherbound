extends "res://tests/smoke_cloudreach_continuous.gd"

## Exact production save/load regression for the continuous acceptance tail.
## The fixture varies durable fields across all five members, then freezes only
## the observation window so real-time condition decay cannot race the reads.
##
## REDESIGN (RD-17/RD-20/RD-21): the chapter's Stormwood entitlement is no
## longer the world-scoped `realm_key_stormwood` flag behind a physical gate.
## Captain Veyra's hand-off (chapter_rewards.json boss_handoffs, resolved by
## encounter_rewards.gd::chapter_hand_off) gives EACH participant their own
## `stormwood_portal_key` ITEM and the Cloudreach relic in
## `redesign_character.relics_held`; the key is used once on the Hall's
## Stormwood arch. This smoke now runs under the shipped config (portal runtime
## on, no legacy-crossing override) and proves that personal end state survives
## the same production save/reload exactly once. The wind-road and Wings
## assertions are unchanged (not legacy).
##
## F08 tail: the chapter's end-state -- restored wind roads, the Wings of
## Cloudreach with the Sky Shrine reached, and the player's own Stormwood
## portal key and Cloudreach relic -- must survive the same real disk reload.
## The live flag store is a set, so a reload cannot show a duplicate there; the
## on-disk check instead counts each flag across every `flags` array in the two
## split halves this save wrote (this slot's world.json and the local
## character's character.json; the slot file's merged mirror is excluded), so
## a flag written into both halves -- the split-save double grant -- or twice
## within one file fails. The key item is counted the same way (it must live
## once, in the character half only). A second save after the reload must
## write the same flag set and the same single key (the reload granted nothing
## new). This does NOT replay the finale's grant path (F19's boss-delivery
## tests own that); the personal hand-off state is a DISCLOSED FIXTURE shaped
## exactly like Veyra's resolved hand-off row. Negative control:
## `-- --f08-unsaved=<flag>` grants that one flag only AFTER the save, so its
## reload and on-disk assertions must fail; `-- --f08-double=<flag>` writes that
## flag into the character half as well after the save (the split-save double
## grant), so its on-disk count must fail.

const BIOME_ORDER := preload("res://scripts/data/biome_order.gd")

const ENCOUNTER_REWARDS := preload("res://scripts/net/encounter_rewards.gd")
const VEYRA := "captain_veyra_storm_anchor"

const F08_DURABLE_FLAGS: Array[String] = ["cloudreach_winds_restored",
	"realm_heart_cloudreach_earned", "sky_shrine_reached"]


func _run() -> void:
	# Shipped config only: no legacy-crossing override (RD-17).
	BIOME_ORDER.clear_test_overrides()
	start_usec=Time.get_ticks_usec()
	# Events go to user:// by default so a run never dirties the checkout
	# (CI and every lane run this). Pass `-- --evidence-dir=<res:// or abs path>`
	# to write them into a report directory on purpose.
	output_dir="user://cloudreach_persistence_tail_events"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="):
			output_dir = arg.trim_prefix("--evidence-dir=")
	DirAccess.make_dir_recursive_absolute(output_dir)
	game=root.get_node("Game")
	game.reset_for_new_game()
	game.save_system=SAVE.new("user://cloudreach_persistence_tail_regression")
	for index in 5:
		var species: String=["sparkit","mudsnout","bramblebun","terrapup","brooktail"][index]
		var member: RefCounted=SPECIES.spawn(species)
		member.set_level(22+index,PROGRESSION.config())
		member.set("xp",101+index*37)
		member.set("hp",float(member.get("max_hp"))-(index+1)*7.25)
		member.set("energy",17.5+index)
		member.set("nickname","Tail%d"%index)
		member.set("bond",index*3)
		member.set("battles_fought",index+4)
		member.set("distance_m_together",1234.56789+index*0.125)
		member.set("nourishment",0.375+index*7.125)
		member.set("happiness",44.875+index*3.25)
		member.set("rested",index<2)
		member.set("rested_seconds_left",987.654321-index*11.25 if index<2 else 0.0)
		game.party.add(member)
	var unsaved := ""
	var doubled := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--f08-unsaved="):
			unsaved = arg.trim_prefix("--f08-unsaved=")
		elif arg.begins_with("--f08-double="):
			doubled = arg.trim_prefix("--f08-double=")
	for flag: String in F08_DURABLE_FLAGS:
		if flag != unsaved:
			game.progression.set_flag(flag)
	# DISCLOSED FIXTURE: the personal state Veyra's resolved hand-off leaves on
	# this participant (foundation_actions.gd boss_relic: one key item into the
	# satchel, the relic biome into relics_held). Read from the authored row.
	var handoff: Dictionary = ENCOUNTER_REWARDS.chapter_hand_off(VEYRA, "cloudreach")
	var key_item := str(handoff.get("portal_key_item", ""))
	var relic := str(handoff.get("relic_biome", ""))
	_require(key_item == "stormwood_portal_key" and relic == "cloudreach"
		and str(handoff.get("next_biome", "")) == "stormwood",
		"Veyra's authored hand-off is the personal Stormwood key item and the Cloudreach relic (%s)" % str(handoff))
	_require(not BIOME_ORDER.legacy_physical_crossings(game),
		"Shipped config retires the physical crossings (portal runtime on, no override)")
	var inventory: RefCounted = game.get("local").get("inventory")
	_require(int(inventory.call("count", key_item)) == 0 and int(inventory.call("add", key_item, 1)) == 0,
		"Fixture placed exactly one %s in the satchel" % key_item)
	var personal: Dictionary = (game.get("local").get("redesign_character") as Dictionary).duplicate(true)
	_require(not (personal.relics_held as Array).has(relic), "Fixture starts without the %s relic" % relic)
	(personal.relics_held as Array).append(relic)
	game.get("local").set("redesign_character", personal)
	stage="persistence_tail_exact"
	paused=true
	var before:=_party_persistence_snapshot()
	var save_ok: bool=game.save_game(0)
	if not unsaved.is_empty():
		# NEGATIVE CONTROL ONLY: granted after the write, so the disk never had it.
		game.progression.set_flag(unsaved)
	if not doubled.is_empty():
		# NEGATIVE CONTROL ONLY: the same flag also written into the character half.
		_f08_append_flag_to_character_half(doubled)
	var load_ok: bool=save_ok and game.load_game(0)
	var after:=_party_persistence_snapshot()
	var differences:=_party_persistence_differences(before,after)
	paused=false
	_require(save_ok,"Production save wrote the five-member tail fixture")
	_require(load_ok,"Production load restored the five-member tail fixture")
	_log("persistence_party_diff",{"differences":differences,"before":before,"after":after})
	_require(differences.is_empty(),"All declared persisted fields round-tripped exactly")
	_require(game.party.size()==5,"Round-trip retained exactly five party members")
	# The reload must restore each end-state flag from disk. The live store is a
	# set (presence only); the duplicate check is on the files the save wrote.
	var loaded: Array = game.progression.all_set()
	var local_character: RefCounted = game.get("local")
	var character_id := str(local_character.get("character_id")) if local_character != null else ""
	var root_dir := "user://cloudreach_persistence_tail_regression"
	var on_disk := _f08_disk_flag_counts([root_dir.path_join("worlds/slot-0/world.json"),
		root_dir.path_join("characters/%s/character.json" % character_id)])
	for flag: String in F08_DURABLE_FLAGS:
		var disk_count := int(on_disk.get(flag, 0))
		_log("persistence_f08_flag", {"flag": flag, "restored": loaded.has(flag),
			"disk_count": disk_count, "unsaved_control": flag == unsaved})
		_require(loaded.has(flag), "Reload restored %s from disk" % flag)
		_require(disk_count == 1, "The save wrote %s in exactly one place (count %d)" % [flag, disk_count])
	var flags_after_reload: Array = loaded.duplicate()
	flags_after_reload.sort()
	var resave_ok: bool = game.save_game(0) and game.load_game(0)
	var flags_after_resave: Array = game.progression.all_set().duplicate()
	flags_after_resave.sort()
	_require(resave_ok and flags_after_resave == flags_after_reload,
		"A second save/load after the reload kept the same flag set (nothing re-granted)")
	_require(int(game.get("local").get("inventory").call("count", key_item)) == 1
		and ((game.get("local").get("redesign_character") as Dictionary).get("relics_held", []) as Array).count(relic) == 1,
		"A second save/load after the reload kept exactly one key and one held relic (nothing re-granted)")
	_require(game.realm_hearts.is_earned("cloudreach", game.progression),
		"Reload restored the Wings of Cloudreach as earned")
	var reloaded_inventory: RefCounted = game.get("local").get("inventory")
	var reloaded_relics: Array = (game.get("local").get("redesign_character") as Dictionary).get("relics_held", [])
	_require(int(reloaded_inventory.call("count", key_item)) == 1,
		"Reload restored exactly one personal %s (count %d)" % [key_item, int(reloaded_inventory.call("count", key_item))])
	_require(reloaded_relics.count(relic) == 1,
		"Reload restored the %s relic held exactly once (%s)" % [relic, str(reloaded_relics)])
	var key_on_disk := _f08_disk_text_counts([root_dir.path_join("worlds/slot-0/world.json"),
		root_dir.path_join("characters/%s/character.json" % character_id)], "\"%s\"" % key_item)
	_require(int(key_on_disk[0]) == 0 and int(key_on_disk[1]) == 1,
		"The save wrote the personal %s once, in the character half only (world %d, character %d)"
			% [key_item, int(key_on_disk[0]), int(key_on_disk[1])])
	# RD-20: the key is the gate, used once on its Hall arch. Holding it is not
	# an unlock, and no world-scoped legacy key was written.
	_require(not game.can_enter_realm("stormwood") and not loaded.has("realm_key_stormwood"),
		"Holding the Stormwood key is not itself an unlock, and no world-scoped legacy key exists")
	print("CLOUDREACH PERSISTENCE TAIL %s members=%d differences=%d"%[
		"FAIL" if failed else "PASS",game.party.size(),differences.size()])
	BIOME_ORDER.clear_test_overrides()
	quit(1 if failed else 0)


## Every flag id in the given split-half files, counted across all their
## `flags` arrays, so a flag stored in both halves (or twice in one) counts twice.
func _f08_disk_flag_counts(paths: Array) -> Dictionary:
	var counts := {}
	for path: String in paths:
		_require(FileAccess.file_exists(path), "The production save wrote %s" % path)
		var parsed: Variant = preload("res://scripts/save/save_document.gd").parse(FileAccess.get_file_as_string(path))
		_require(parsed is Dictionary, "%s parses as a JSON object" % path)
		_f08_count_flags(parsed, counts)
	_log("persistence_f08_disk", {"files": paths})
	return counts


## Occurrences of `needle` in each file's text, in order (world, character).
func _f08_disk_text_counts(paths: Array, needle: String) -> Array:
	var out: Array = []
	for path: String in paths:
		out.append(FileAccess.get_file_as_string(path).count(needle) if FileAccess.file_exists(path) else -1)
	return out


func _f08_count_flags(node: Variant, counts: Dictionary) -> void:
	if node is Dictionary:
		for key: Variant in node:
			var value: Variant = node[key]
			if str(key) == "flags" and value is Array:
				for flag: Variant in value:
					counts[str(flag)] = int(counts.get(str(flag), 0)) + 1
			else:
				_f08_count_flags(value, counts)
	elif node is Array:
		for item: Variant in node:
			_f08_count_flags(item, counts)


## Negative control helper: append `flag` to the local character's saved flags.
func _f08_append_flag_to_character_half(flag: String) -> void:
	var local_character: RefCounted = game.get("local")
	var path := "user://cloudreach_persistence_tail_regression/characters/%s/character.json" % str(
		local_character.get("character_id"))
	var data: Variant = preload("res://scripts/save/save_document.gd").parse(FileAccess.get_file_as_string(path))
	var holder: Dictionary = _f08_first_flags_holder(data)
	_require(not holder.is_empty(), "Negative control found a flags array in %s" % path)
	(holder["flags"] as Array).append(flag)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(preload("res://scripts/save/save_document.gd").stringify(data))
	file.close()


func _f08_first_flags_holder(node: Variant) -> Dictionary:
	if node is Dictionary:
		if node.get("flags") is Array:
			return node
		for key: Variant in node:
			var found := _f08_first_flags_holder(node[key])
			if not found.is_empty():
				return found
	elif node is Array:
		for item: Variant in node:
			var found := _f08_first_flags_holder(item)
			if not found.is_empty():
				return found
	return {}
