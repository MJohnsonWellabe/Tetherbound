extends "res://tools/phase2_capture_locations.gd"

## Preserve the full catalogue's fallback route headings, then capture only
## Stormheart and Dynamo Core. Filtering before landmark planning changes the
## neighbours used for orientation; --subset must therefore not be supplied.
## All placement, floor settling and camera behaviour comes from the recorder.
## Use --biome=stormwood --times=day,night for eight frames (two destinations,
## two views, two clock pins). Inherited day,golden,night defaults produce twelve.

func _parse_args() -> bool:
	if not super._parse_args():
		return false
	if _biome_id != "stormwood" or not _subsets.is_empty():
		push_error("Stormheart views require --biome=stormwood and no --subset")
		return false
	return true


func _load_plan() -> bool:
	if not super._load_plan():
		return false
	_planned = _planned.filter(func(row: Dictionary) -> bool:
		var identity := str(row.get("identity", ""))
		return "stormheart" in identity or "dynamo_core" in identity)
	if _planned.is_empty():
		push_error("Stormheart view selection is empty")
		return false
	return true
