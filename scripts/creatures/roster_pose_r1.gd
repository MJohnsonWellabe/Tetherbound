extends RefCounted

## Roster-wide F36 pose candidate (UIPOSES lane, 1 Nov 2026; coordinator
## priority from the owner). Today's judges named the same faults on nearly
## every species: faint-mid/end floats, pitches nose-down or rises into an
## S-curve instead of a grounded side-lying collapse; hit react looks like
## standing. f36_pose_candidates.json `roster_pose_r1` (OFF) rewrites every
## installed recipe's faint and hit roles at install time, once, here:
##   faint - the authored limb collapse kept, the pivot's pitch removed and a
##           roll to a side-lie ramped in; the installer grounds each frame on
##           its posed vertices and re-centres the rolled body over its shadow.
##   hit   - a pivot recoil (nose up, slight lean) over the authored clip,
##           peaking early; grounded the same way.
## Species a remake lane owns (creature_model_flags.json
## flags.remake_owner1101_<species>) are skipped. Presentation only.
const MODEL_FLAGS := "res://data/config/creature_model_flags.json"


static func enabled(data: Dictionary) -> bool:
	var block: Variant = data.get("roster_pose_r1", {})
	return block is Dictionary and bool((block as Dictionary).get("enabled", false))


static func settings(data: Dictionary) -> Dictionary:
	var block: Variant = data.get("roster_pose_r1", {})
	return block if block is Dictionary else {}


## True when a remake lane has claimed this species (base id, water_ prefix
## stripped). A missing flags file means nobody has.
static func remake_owned(species_id: String, flags: Dictionary = {}) -> bool:
	var source := flags
	if source.is_empty() and FileAccess.file_exists(MODEL_FLAGS):
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(MODEL_FLAGS))
		source = raw if raw is Dictionary else {}
	var table: Variant = source.get("flags", source)
	if not table is Dictionary:
		return false
	var base := species_id.trim_prefix("water_")
	for key: String in ["remake_owner1101_" + base, "remake_owner1101_" + species_id]:
		var value: Variant = (table as Dictionary).get(key, false)
		if value is Dictionary:
			if bool((value as Dictionary).get("enabled", false)):
				return true
		elif bool(value):
			return true
	return false


static func _smooth(t: float) -> float:
	var x := clampf(t, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


## A side-lying faint from an authored faint spec. Bones are kept; the pivot
## loses its pitch and gains a roll ramping in over [roll_start, roll_end].
static func faint_side_lie(spec: Dictionary, cfg: Dictionary) -> Dictionary:
	var out := spec.duplicate(true)
	var roll := float(cfg.get("faint_roll_deg", 84.0))
	var start := float(cfg.get("roll_start", 0.2))
	var finish := maxf(start + 0.05, float(cfg.get("roll_end", 0.85)))
	for frame: Dictionary in out.get("frames", []):
		var r := _smooth((float(frame.get("phase", 0.0)) - start) / (finish - start))
		var authored: Array = frame.get("pivot_rotation_deg", [0.0, 0.0, 0.0])
		var yaw := float(authored[1]) if authored.size() >= 2 else 0.0
		frame["pivot_rotation_deg"] = [0.0, yaw, roll * r]
		frame["pivot_roll_deg"] = 0
	out["side_lie"] = true
	return out


## A visible recoil on hit: pivot nose-up and a small lean, rising fast to a
## peak at `recoil_peak` and easing back by the clip's end.
static func hit_recoil(spec: Dictionary, cfg: Dictionary) -> Dictionary:
	var out := spec.duplicate(true)
	var pitch := float(cfg.get("hit_pitch_deg", -11.0))
	var lean := float(cfg.get("hit_lean_deg", 5.0))
	var peak := clampf(float(cfg.get("recoil_peak", 0.3)), 0.05, 0.9)
	for frame: Dictionary in out.get("frames", []):
		var t := float(frame.get("phase", 0.0))
		var e := _smooth(t / peak) if t <= peak else 1.0 - _smooth((t - peak) / (1.0 - peak))
		var authored: Array = frame.get("pivot_rotation_deg", [0.0, 0.0, 0.0])
		var base := Vector3(float(authored[0]), float(authored[1]), float(authored[2])) if authored.size() >= 3 \
			else Vector3(0.0, 0.0, float(frame.get("pivot_roll_deg", 0.0)))
		frame["pivot_rotation_deg"] = [base.x + pitch * e, base.y, base.z + lean * e]
	return out
