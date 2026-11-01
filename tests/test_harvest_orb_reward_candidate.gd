extends "res://tests/test_case.gd"

## P2-034 (vis-meadows, OFF until GPU-judged): the Basic Orb harvest node's
## lone-orb candidate ships OFF and targets exactly one authored node.

const CONFIG := "res://data/config/meadows_orb_reward_presentation.json"
const HARVEST := "res://data/config/bands/band1_lower_meadows/harvest.json"


func test_candidate_ships_off_and_targets_one_basic_orb_node() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	assert_false(bool(cfg.get("enabled", true)), "P2-034 candidate ships OFF")
	assert_eq(str(cfg.target_item), "orb_basic")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(HARVEST))
	var rows: Array = parsed if parsed is Array else []
	if parsed is Dictionary:
		for value: Variant in (parsed as Dictionary).values():
			if value is Array:
				rows = value
	var hits := rows.filter(func(r: Variant) -> bool:
		return r is Dictionary and "order:%d" % int(r.get("order", -1)) == str(cfg.target_node_id) and str(r.get("item")) == "orb_basic")
	assert_eq(hits.size(), 1, "the target node is the band-1 Basic Orb")
