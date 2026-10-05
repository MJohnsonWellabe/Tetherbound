extends "res://tests/test_case.gd"

## Coordinator ruling on the shared 4096 transaction_receipts cap: the
## high-frequency kinds (essence spends, wild defeats, trainer rounds, shed
## wins, grooms, station crafts, bounty decisions; care by host day) stay
## bounded; once-ever kinds are never compacted.
##
## Disclosed fixtures: the real-stage case builds a wild-defeat host event from
## spawned creatures and a character record already holding 4095 prior
## receipts (one short of the old refusal). ESSENCE.stage_defeat is not mocked.

const RW := preload("res://scripts/creatures/receipt_windows.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const CHARACTER := "character-0123456789abcdef0123456789abcdef"


func _hex(i: int) -> String:
	return str(i).md5_text()


func _sample(kind: String, i: int) -> String:
	match kind:
		"essence_spend": return "essence_spend:%s:%s:uid:1:wood:1:%d" % [CHARACTER, _hex(i), i]
		"wild_defeat": return "defeat:%s:%s:%s" % [CHARACTER, _hex(i), _hex(i + 1)]
		"trainer_round": return "defeat:trainer_round_%s:%s" % [_hex(i), CHARACTER]
		"shed_win": return "craft:%s:shed_win:%s" % [CHARACTER, _hex(i)]
		"groom": return "groom:uid%d:%s" % [i % 5, _hex(i)]
		"station_craft": return "craft:%s:%s" % [CHARACTER, _hex(i)]
		"bounty_decision": return "bounty:clock_%s:%s" % [_hex(i), CHARACTER]
	return ""


const ONCE_EVER := ["research:sprig:seen:%s", "master_recipe:aldis:%s", "starter_choice:%s:", "relic_hang:meadows:%s",
	"craft:%s:gear_0123", "craft:%s:relic_power_meadows", "craft:portal_arrival_x:%s", "release:uid9"]


func test_every_high_frequency_kind_stays_bounded_and_drops_its_oldest() -> void:
	for kind: String in ["essence_spend", "wild_defeat", "trainer_round", "shed_win", "groom", "station_craft", "bounty_decision"]:
		var size := RW.window(kind)
		assert_true(size >= 2, "%s has a configured window" % kind)
		var receipts: Array = []
		for template: String in ONCE_EVER: receipts.append(template % CHARACTER if template.contains("%s") else template)
		for i in size + 600:
			receipts = RW.compact(receipts, kind, CHARACTER)
			receipts.append(_sample(kind, i))
		var kept: Array = receipts.filter(func(r: Variant) -> bool: return RW.is_kind(str(r), kind, CHARACTER))
		assert_eq(kept.size(), size, "%s bounded at its window" % kind)
		assert_eq(str(kept[0]), _sample(kind, 600), "%s drops the oldest" % kind)
		for template: String in ONCE_EVER:
			var once := template % CHARACTER if template.contains("%s") else template
			assert_true(receipts.has(once), "%s never touches once-ever %s" % [kind, once])


func test_station_craft_matches_only_the_32_hex_craft_receipt() -> void:
	assert_true(RW.is_kind("craft:%s:%s" % [CHARACTER, _hex(1)], "station_craft", CHARACTER))
	for other: String in ["craft:%s:gear_%s" % [CHARACTER, _hex(1)], "craft:%s:f32:%s" % [CHARACTER, _hex(1).sha256_text()],
			"craft:%s:shed_win:%s" % [CHARACTER, _hex(1)], "craft:%s:den:%s" % [CHARACTER, _hex(1)],
			"craft:regional_ending_homecoming_seen:%s" % CHARACTER, "craft:%s:%s" % ["someone-else", _hex(1)]]:
		assert_false(RW.is_kind(other, "station_craft", CHARACTER), "%s is not a station craft" % other)


func test_care_keeps_only_the_current_host_day() -> void:
	var receipts: Array = ["care:%s:3:uid1:2" % CHARACTER, "care:%s:4:uid1:2" % CHARACTER,
		"care:%s:5:uid2:2" % CHARACTER, "care:other:3:uid1:2", "research:x:y:%s" % CHARACTER]
	var kept := RW.compact_care(receipts, CHARACTER, 5)
	assert_eq(kept, ["care:%s:5:uid2:2" % CHARACTER, "care:other:3:uid1:2", "research:x:y:%s" % CHARACTER])


func test_a_wild_defeat_past_4096_receipts_is_paid_not_refused() -> void:
	var player := preload("res://autoload/player_state.gd").new()
	player.configure(ITEM_DB.new())
	player.character_id = CHARACTER
	var mine: RefCounted = SPECIES.spawn("terrapup")
	player.party.add(mine)
	var record := RECORD.portable_projection(player.save_data())
	for i in 4095:
		record.redesign_character.transaction_receipts.append(_sample("wild_defeat", i))
	var wild := preload("res://autoload/player_state.gd").new()
	wild.configure(ITEM_DB.new())
	wild.character_id = "wild-holder"
	wild.party.add(SPECIES.spawn("mudsnout"))
	var enemy_record: Dictionary = RECORD.portable_projection(wild.save_data()).party[0]
	enemy_record.hp = 0
	enemy_record.fainted = true
	var uid := str(record.party[0].uid)
	var outcome := []
	for i in 3:
		var event := {"event_id": _hex(9000 + i), "world_namespace": "0123456789abcdef0123456789abcdef",
			"encounter_id": _hex(8000 + i), "enemy_uid": str(enemy_record.uid), "enemy_record": enemy_record,
			"active_uid": uid, "eligible_uids": [uid], "kind": "wild_defeat", "xp_mode": "ordinary"}
		var staged := ESSENCE.stage_defeat(record, CHARACTER, event, i, ESSENCE.config(), PROGRESSION.config())
		outcome.append(staged.get("code", "ok"))
		if staged.get("ok") != true: break
		record = staged.state
	assert_eq(outcome, ["ok", "ok", "ok"], "every defeat past the old cap pays (codes %s)" % str(outcome))
	var defeats: Array = record.redesign_character.transaction_receipts.filter(
		func(r: Variant) -> bool: return RW.is_kind(str(r), "wild_defeat", CHARACTER))
	assert_eq(defeats.size(), RW.window("wild_defeat"), "and the defeat receipts stay at the window")
