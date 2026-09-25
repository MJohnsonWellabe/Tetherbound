extends "res://tests/smoke_cloudreach_continuous.gd"

## Exact production save/load regression for the continuous acceptance tail.
## The fixture varies durable fields across all five members, then freezes only
## the observation window so real-time condition decay cannot race the reads.
##
## F08 tail: the chapter's end-state -- restored wind roads, the Wings of
## Cloudreach with the Sky Shrine reached, and the Stormwood key -- must survive
## the same real disk reload, each exactly once (no double grant). Negative
## control: `-- --f08-unsaved=<flag>` grants that one flag only AFTER the save,
## so its reload assertion must fail.

const F08_DURABLE_FLAGS: Array[String] = ["cloudreach_winds_restored",
	"realm_heart_cloudreach_earned", "sky_shrine_reached", "realm_key_stormwood"]


func _run() -> void:
	start_usec=Time.get_ticks_usec()
	output_dir="res://ralph/reports/CLOUDREACH-CONTINUOUS-0905/persistence-tail-regression"
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
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--f08-unsaved="):
			unsaved = arg.trim_prefix("--f08-unsaved=")
	for flag: String in F08_DURABLE_FLAGS:
		if flag != unsaved:
			game.progression.set_flag(flag)
	stage="persistence_tail_exact"
	paused=true
	var before:=_party_persistence_snapshot()
	var save_ok: bool=game.save_game(0)
	if not unsaved.is_empty():
		# NEGATIVE CONTROL ONLY: granted after the write, so the disk never had it.
		game.progression.set_flag(unsaved)
	var load_ok: bool=save_ok and game.load_game(0)
	var after:=_party_persistence_snapshot()
	var differences:=_party_persistence_differences(before,after)
	paused=false
	_require(save_ok,"Production save wrote the five-member tail fixture")
	_require(load_ok,"Production load restored the five-member tail fixture")
	_log("persistence_party_diff",{"differences":differences,"before":before,"after":after})
	_require(differences.is_empty(),"All declared persisted fields round-tripped exactly")
	_require(game.party.size()==5,"Round-trip retained exactly five party members")
	# The reload must restore each end-state flag from disk, exactly once. The
	# loaded store is asked by id and counted; a merged world+character reload
	# that granted twice or dropped one fails here.
	var loaded: Array = game.progression.all_set()
	for flag: String in F08_DURABLE_FLAGS:
		var count := loaded.count(flag)
		_log("persistence_f08_flag", {"flag": flag, "count": count, "unsaved_control": flag == unsaved})
		_require(count == 1, "Reload restored %s exactly once (count %d)" % [flag, count])
	_require(game.realm_hearts.is_earned("cloudreach", game.progression),
		"Reload restored the Wings of Cloudreach as earned")
	_require(game.realm_hearts.entry_key_for_realm("stormwood") == "realm_key_stormwood"
		and game.can_enter_realm("stormwood"), "Reload restored the Stormwood key: the realm opens")
	print("CLOUDREACH PERSISTENCE TAIL %s members=%d differences=%d"%[
		"FAIL" if failed else "PASS",game.party.size(),differences.size()])
	quit(1 if failed else 0)
