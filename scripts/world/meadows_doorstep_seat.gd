extends RefCounted

## P2-006 doorstep: the home-square bench sits parallel to the house's east
## wall facing the yard, and the potted fern beside the door, instead of
## standing loose in the square. Presentation only: per-id overrides merged
## into the Meadows catalogue's placement and cover-clearance rows before
## they are built. Independent OFF flag.
const CONFIG := "res://data/config/meadows_doorstep_seat.json"


static func settings() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	return parsed if parsed is Dictionary else {}


static func enabled() -> bool:
	return bool(settings().get("doorstep_seat_enabled", false))


## Returns the catalogue with this pass's overrides merged in (unchanged when
## the flag is off). Rows are matched by id; unknown ids are ignored.
static func apply(catalogue: Dictionary) -> Dictionary:
	var cfg := settings()
	if not bool(cfg.get("doorstep_seat_enabled", false)):
		return catalogue
	for section: String in ["placements", "cover_clearances"]:
		var overrides: Dictionary = cfg.get(section, {})
		for row: Variant in catalogue.get(section, []):
			if row is Dictionary and overrides.has(str(row.get("id", ""))):
				(row as Dictionary).merge(overrides[str(row.id)], true)
	return catalogue
