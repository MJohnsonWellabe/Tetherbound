extends RefCounted

## P2-015 / P2-028 side-lie faint (UIPOSES lane, 1 Nov 2026). GPU item scores:
## Veridian's faint "still reads upright", Terrapup's faint is "indistinguishable
## from its resting pose", Riptusk's faint "sits in an upright crouch". When
## data/config/creature_faint_presentation.json is enabled, a listed species'
## visual pivot rolls onto its side as the faint plays, so a fainted body reads
## as down and differs from the curled rest. Presentation only: the
## CharacterBody, collider, HP, catch and save state are never touched, and
## revive restores the exact pivot transform.
const CONFIG_PATH := "res://data/config/creature_faint_presentation.json"
static var _config: Dictionary = {}


static func config() -> Dictionary:
	if _config.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
		_config = raw if raw is Dictionary else {"enabled": false}
	return _config


## The recipe for one presentation id (Water forms may be listed separately),
## or {} when the flag is off or the species is not listed.
static func recipe(species_id: String, cfg: Dictionary = {}) -> Dictionary:
	var source := cfg if not cfg.is_empty() else config()
	if not bool(source.get("enabled", false)):
		return {}
	var rows: Variant = source.get("species", {})
	if not rows is Dictionary:
		return {}
	var row: Variant = (rows as Dictionary).get(species_id, {})
	return row if row is Dictionary else {}


## The rolled pivot for `before`. Same grounding rule as the bed-rest roll in
## creature_body.gd: the roll's own dip is lifted by radius*|sin|, the body
## re-centres sideways by half its standing height, and an optional sink and
## offset settle it into the ground.
static func rolled_transform(before: Transform3D, row: Dictionary, height: float, radius: float) -> Transform3D:
	var roll := deg_to_rad(float(row.get("roll_deg", 80.0)))
	var basis := before.basis * Basis(Vector3.BACK, roll)
	var extra: Variant = row.get("offset_m", [0.0, 0.0, 0.0])
	var offset := Vector3.ZERO
	if extra is Array and (extra as Array).size() >= 3:
		offset = Vector3(float(extra[0]), float(extra[1]), float(extra[2]))
	var lift := radius * absf(sin(roll)) * float(row.get("lift_scale", 1.0)) - float(row.get("sink_m", 0.06))
	var side := height * 0.5 * sin(roll) * float(row.get("recentre_scale", 1.0))
	return Transform3D(basis, before.origin + before.basis * Vector3(side, 0.0, 0.0) + Vector3(0.0, lift, 0.0) + offset)
