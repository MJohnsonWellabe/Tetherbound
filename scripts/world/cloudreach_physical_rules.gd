extends RefCounted

## Pure guards for the scene adapter. State remains in the shared progression.
const LOGIC := preload("res://scripts/world/realm_chapter_progression.gd")


static func read(path: String) -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return raw if raw is Dictionary else {}


static func vec(raw: Array) -> Vector3:
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2])) if raw.size() == 3 else Vector3.INF


static func holds(flags: RefCounted, required: Array) -> bool:
	return flags != null and LOGIC.flags_hold(flags, required)


static func available(flags: RefCounted, spec: Dictionary) -> bool:
	return holds(flags, spec.get("requires_flags", [])) and not bool(flags.call("has", str(spec.get("completion_flag", ""))))


static func in_landing(at: Vector3, spec: Dictionary) -> bool:
	var offset := at - vec(spec.get("position", []))
	return Vector2(offset.x, offset.z).length() <= float(spec.get("radius_m", 12)) \
		and absf(offset.y) <= float(spec.get("height_tolerance_m", 3))


static func next_gate(index: int, from: Vector3, to: Vector3, gates: Array, flying: bool) -> int:
	if not flying or index < 0 or index >= gates.size():
		return index
	var gate: Dictionary = gates[index]
	var point := vec(gate["position"])
	var nearest := Geometry3D.get_closest_point_to_segment(point, from, to)
	return index + 1 if nearest.distance_to(point) <= float(gate.get("radius_m", 6)) else index


static func dialogue_guard(flags: RefCounted, runtime: Dictionary, effect: String) -> Dictionary:
	for guard: Dictionary in runtime.get("dialogue_event_guards", []):
		if guard["effect"] == effect and holds(flags, guard.get("requires_flags", [])):
			return guard
	return {}


static func encounter_spec(chapter: Dictionary, id: String) -> Dictionary:
	for spec: Dictionary in chapter.get("trainer_ladder", []):
		if spec["id"] == id:
			return spec
	return {}


static func encounter_allowed(flags: RefCounted, chapter: Dictionary, runtime: Dictionary, id: String) -> bool:
	var requirements: Dictionary = runtime.get("encounter_requirements", {})
	return not encounter_spec(chapter, id).is_empty() and requirements.has(id) and holds(flags, requirements[id])


static func circuit_events(flags: RefCounted, runtime: Dictionary) -> Array[String]:
	var events: Array[String] = []
	var requirements: Dictionary = runtime.get("circuit_requirements", {})
	if holds(flags, requirements.get("lower", ["missing_circuit_contract"])):
		events.append("side:the_cliff_circuit:beat_lower_pair")
	if holds(flags, requirements.get("windscar", ["missing_circuit_contract"])):
		events.append("side:the_cliff_circuit:beat_windscar_pair")
	if bool(flags.call("has", "defeated_cloudreach_tavi")):
		events.append("side:the_cliff_circuit:beat_tavi")
	return events


static func npc_specs(chapter: Dictionary, runtime: Dictionary, flags: RefCounted, position_overrides: Dictionary = {}) -> Array:
	var result: Array = []
	for placement: Dictionary in runtime.get("npcs", []):
		for authored: Dictionary in chapter.get("npcs", []):
			if placement["id"] != authored["id"]:
				continue
			var spec := placement.duplicate(true)
			spec["name"] = authored["name"]
			spec["config_key"] = authored["body_profile"]
			spec["position"] = position_overrides.get(placement["id"], placement.get("position", authored["position"]))
			for branch: Dictionary in placement.get("position_when", []):
				var raw: Variant = branch.get("if_flag", [])
				var required: Array = raw if raw is Array else [raw]
				if holds(flags, required):
					spec["position"] = branch["position"]
					break
			result.append(spec)
	return result
