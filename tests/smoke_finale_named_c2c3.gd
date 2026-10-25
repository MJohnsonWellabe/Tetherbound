extends "res://tests/smoke_meadows_named_c2c3.gd"

## F22#4 C2/C3 for the two named finales no chapter smoke covers: Captain
## Veyra (BOSSES 4.6, Cloudreach summit) and Captain Marrow (BOSSES 4.7, the
## Stormwood Dynamo finale). Same harness, pilot and verdict rules as
## tests/smoke_meadows_named_c2c3.gd (top trainer bar, C3 ceiling and tell
## floors), with each team built by its chapter's production translator:
## - Veyra: cloudreach_encounter_director.gd::trainer_spec over her
##   cloudreach_chapter.json trainer_ladder row and her cloudreach_encounters.json
##   placement (behavior_sequence profiles per send-out);
## - Marrow: stormwood_encounter_catalogue.gd::trainer_specs().
## Patterns: named_<id> (combat.json patterns.named), chapter cloudreach /
## stormwood, as encounter_director.gd configures them. Party level: the
## region's wild band midpoint + 1, the rule tests/smoke_stormwood_b_named_c2c3.gd
## uses (Cloudreach summit 40-43 -> 42; Stormwood Dynamo Calm 50-53 -> 52).
##
##   godot --headless --path . --fixed-fps 60 --script tests/smoke_finale_named_c2c3.gd \
##       -- --seeds=24 [--case=<substring>] [--starter=<id>] --json=<path>
##
## Lines print with the MEADOWS_C2C3 prefix of the shared harness. The
## chapter masher product is not judged (it needs the six Meadows fights).

const CLOUDREACH := preload("res://scripts/combat/cloudreach_encounter_director.gd")
const STORMWOOD := preload("res://scripts/combat/stormwood_encounter_catalogue.gd")
const VEYRA := "captain_veyra_storm_anchor"
const MARROW := "captain_marrow_dynamo_core"


func _cases(errors: Array[String]) -> Array[Dictionary]:
	var cases: Array[Dictionary] = []
	var chapter := _json_file("res://data/config/cloudreach_chapter.json")
	var encounters := _json_file("res://data/config/cloudreach_encounters.json")
	var authored := CLOUDREACH.find_id(chapter.get("trainer_ladder", []), VEYRA)
	var placement := CLOUDREACH.find_id(encounters.get("trainers", []), VEYRA)
	if authored.is_empty() or placement.is_empty():
		errors.append("no Cloudreach trainer %s" % VEYRA)
	else:
		var spec := CLOUDREACH.trainer_spec(authored, placement, encounters)
		cases.append(_case(VEYRA, "cloudreach", "cloudreach_summit",
			_band_entry(chapter.get("encounter_tables", []), "cloudreach_summit_wild"), spec.get("team", [])))
	var stormwood := _json_file("res://data/config/stormwood_encounters.json")
	var marrow := {}
	for spec: Dictionary in STORMWOOD.trainer_specs():
		if str(spec.get("id", "")) == MARROW:
			marrow = spec
	var dynamo := -1
	for table: Dictionary in stormwood.get("tables", []):
		if str(table.get("surge_phase", "")) == "calm" and str(table.get("region_id", "")) == "dynamo":
			dynamo = _midpoint_plus_one(table.get("level_range", []))
	if marrow.is_empty() or dynamo < 0:
		errors.append("no Stormwood trainer %s or Dynamo Calm band" % MARROW)
	else:
		cases.append(_case(MARROW, "stormwood", "dynamo", dynamo, marrow.get("team", [])))
	return cases


func _case(id: String, chapter: String, band: String, level: int, team: Array) -> Dictionary:
	var heavy := false
	for member: Dictionary in team:
		var c: Dictionary = member.get("combat", {})
		heavy = heavy or float(c.get("charged_telegraph", c.get("telegraph", 0.0))) >= HEAVY_TELL
	return {"id": id, "kind": "top", "owned": true, "band": band, "chapter": chapter,
		"party_level": level, "heavy": heavy, "foes": team}


func _band_entry(tables: Array, table_id: String) -> int:
	for table: Dictionary in tables:
		if str(table.get("id", "")) == table_id:
			return _midpoint_plus_one(table.get("level_range", []))
	return -1


static func _midpoint_plus_one(band: Array) -> int:
	return floori((int(band[0]) + int(band[1])) / 2.0) + 1 if band.size() == 2 else -1


static func _json_file(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
