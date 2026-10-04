extends RefCounted
## F35 visual-only choreography. No gameplay state is read or written here.
## All strike bodies meet their authored endpoint at the one host-frozen arrival.
## Aftermath objects withdraw from that endpoint; they never produce a second hit.


static func compose(row: Dictionary, tier: Dictionary, context: Dictionary) -> Array[Dictionary]:
	var parts: Array[Dictionary] = []
	var visual: Dictionary = row.get("visual", {})
	var p: Dictionary = visual.duplicate(true)
	p["radius_m"] = maxf(0.1, float(visual.get("radius_m", 2.0)))
	p["height_m"] = maxf(0.1, float(visual.get("height_m", 3.0)))
	p["head_gap_m"] = maxf(0.1, float(visual.get("head_gap_m", 1.0)))
	p["spread_m"] = maxf(0.0, float(visual.get("spread_m", 1.0)))
	p["arc_height_m"] = maxf(0.0, float(visual.get("arc_height_m", 2.0)))
	p["charge_fraction"] = clampf(float(visual.get("charge_fraction", 0.35)), 0.05, 0.8)
	p["impact_fraction"] = clampf(float(visual.get("impact_fraction", 0.15)), 0.02, 0.45)
	p["spin_turns"] = float(visual.get("spin_turns", 1.0))
	p["size_scale"] = maxf(0.1, float(tier.get("size_scale", 1.0))) * maxf(0.1, float(visual.get("object_scale", 1.0)))
	p["mastery_detail_scale"] = 1.0 + maxf(0.0, float(visual.get("mastery_detail_scale", 0.0))) * float(clampi(int(context.get("mastery_rank", 1)), 1, 5) - 1)
	# This is a total descriptor ceiling, including charge and aftermath objects.
	var authored_cap: int = clampi(int(visual.get("component_cap", 48)), 1, 256)
	var cap: int = mini(authored_cap, maxi(1, int(context.get("component_cap", 48))))
	# Build a bounded candidate set before admission. A base phase must not
	# consume the final ceiling before newly earned growth motifs are authored.
	p["cap"] = clampi(int(visual.get("composition_candidate_cap", 128)), authored_cap, 256)
	var mastery_step: int = clampi(int(context.get("mastery_rank", 1)), 1, 5) - 1
	var count: int = clampi(int(visual.get("base_count", 4)) + mastery_step + int(tier.get("count_add", 0)), 1, cap)
	var r: float = float(p["radius_m"])
	var h: float = float(p["height_m"])
	var gap: float = float(p["head_gap_m"])
	var key: String = str(row.get("composition", "shared"))
	match key:
		"tectonic_jaws":
			# Two stratified jaws gather beside the paws and close horizontally.
			_group(parts, "tectonic_jaw", "source", "jaw_charge", "charge", 2, [r, h * 0.24, 0.0], [r * 0.35, h * 0.65, r], p)
			_group(parts, "tectonic_jaw", "target", "jaw_clamp", "strike", 2, [maxf(gap, r * 0.55), 0.0, 0.0], [r * 0.35, h * 0.65, r], p)
			_group(parts, "rock", "path", "ground_skip", "strike", count, [r * 0.35, 0.0, 0.0], [r * 0.2, h * 0.16, r * 0.2], p)
			_group(parts, "rock", "target", "settle", "aftermath", count, [r, 0.0, 0.0], [r * 0.18, h * 0.12, r * 0.18], p)
		"leviathan_breach":
			# A solid crest/leviathan rears from the source then breaches in an arc.
			_group(parts, "tide_crest", "source", "breach_charge", "charge", 1, [0.0, 0.0, -gap], [r, h, r * 0.65], p)
			_group(parts, "tide_crest", "path", "breach", "strike", 1, [0.0, 0.0, 0.0], [r, h, r * 0.65], p)
			_group(parts, "water", "path", "surf", "strike", count, [r * 0.5, 0.0, 0.0], [r * 0.35, h * 0.18, r * 0.65], p)
			_group(parts, "water", "target", "wash_out", "aftermath", count, [r * 0.55, 0.0, 0.0], [r * 0.35, h * 0.2, r * 0.55], p)
		"feather_tempest":
			# Visible individual feathers wheel high, then converge as a raking fan.
			_group(parts, "gale_feather", "source", "feather_wheel", "charge", count, [r, h, 0.0], [r * 0.3, h * 0.45, r * 0.15], p)
			_group(parts, "gale_feather", "path", "feather_dive", "strike", count, [gap, h * 0.1, 0.0], [r * 0.3, h * 0.45, r * 0.15], p)
			_group(parts, "wind", "target", "feather_release", "aftermath", 2, [r, h * 0.5, 0.0], [r * 0.35, h * 0.35, r * 0.3], p)
		"antler_grove":
			# A branching antler avenue rises on both flanks, preserving the face gap.
			_group(parts, "verdant_antler", "source", "antler_bud", "charge", 2, [maxf(gap, r * 0.6), 0.0, 0.0], [r * 0.65, h, r * 0.4], p)
			_group(parts, "verdant_antler", "target", "antler_rise", "strike", count, [maxf(gap, r * 0.75), 0.0, 0.0], [r * 0.65, h, r * 0.4], p)
			_group(parts, "tusk_root", "path", "root_rush", "strike", 2, [gap, 0.0, 0.0], [r * 0.5, h * 0.2, r], p)
			_group(parts, "verdant_antler", "target", "grove_fold", "aftermath", 2, [r, 0.0, 0.0], [r * 0.5, h * 0.65, r * 0.3], p)
		"abyssal_crown":
			# Deep-water ribs form an open crown above, then fold down beside the target.
			_group(parts, "abyss_rib", "source", "crown_open", "charge", count, [r, h, 0.0], [r * 0.45, h * 0.75, r * 0.3], p)
			_group(parts, "abyss_rib", "target", "crown_fold", "strike", count, [maxf(gap, r), h * 0.2, 0.0], [r * 0.45, h * 0.75, r * 0.3], p)
			_group(parts, "shadow", "path", "undertow", "strike", 2, [gap, 0.0, 0.0], [r * 0.35, h * 0.15, r], p)
			_group(parts, "water", "target", "drain", "aftermath", 2, [r, 0.0, 0.0], [r * 0.35, h * 0.3, r * 0.45], p)
		"solar_pride":
			# A radial mane opens behind the creature, rays surge in a forward fan.
			_group(parts, "solar_ray", "source", "mane_open", "charge", count, [r, h * 0.65, gap], [r * 0.3, h * 0.65, r * 0.2], p)
			_group(parts, "solar_ray", "path", "solar_fan", "strike", count, [gap, h * 0.25, 0.0], [r * 0.3, h * 0.65, r * 0.2], p)
			_group(parts, "flame", "target", "sun_exhale", "aftermath", 2, [r, h * 0.3, 0.0], [r * 0.3, h * 0.45, r * 0.3], p)
		"serpent_circuit":
			# A coil unthreads into a double helix path, then snaps apart at contact.
			_group(parts, "cobra_coil", "source", "coil_charge", "charge", 1, [0.0, 0.0, gap], [r, h * 0.5, r], p)
			_group(parts, "cobra_coil", "path", "circuit", "strike", 2, [gap, h * 0.25, 0.0], [r * 0.6, h * 0.7, r * 0.6], p)
			_group(parts, "lightning", "path", "circuit_link", "strike", count, [gap, h * 0.25, 0.0], [r * 0.12, h * 0.65, r * 0.12], p)
			_group(parts, "cobra_coil", "target", "coil_unwind", "aftermath", 2, [r, 0.0, 0.0], [r * 0.4, h * 0.4, r * 0.4], p)
		"tuskroot_arboretum":
			# Thick tusk roots split into alternating lanes and lift a rooted colonnade.
			_group(parts, "tusk_root", "source", "root_curl", "charge", 2, [r, 0.0, 0.0], [r * 0.65, h * 0.7, r * 0.6], p)
			_group(parts, "tusk_root", "path", "root_rush", "strike", count, [gap, 0.0, 0.0], [r * 0.5, h * 0.65, r * 0.6], p)
			_group(parts, "verdant_antler", "target", "root_canopy", "strike", 2, [maxf(gap, r), 0.0, 0.0], [r * 0.7, h, r * 0.4], p)
			_group(parts, "tusk_root", "target", "root_sink", "aftermath", 2, [r, 0.0, 0.0], [r * 0.65, h * 0.65, r * 0.5], p)
		"ashtusk_forge":
			# Capped vents compress, open like bellows, and throw an arcing slag hammer.
			_group(parts, "furnace_vent", "source", "forge_compress", "charge", 2, [r, 0.0, 0.0], [r * 0.6, h * 0.6, r * 0.6], p)
			_group(parts, "furnace_vent", "target", "forge_open", "strike", 2, [maxf(gap, r * 0.8), 0.0, 0.0], [r * 0.6, h * 0.8, r * 0.6], p)
			_group(parts, "rock", "path", "slag_arc", "strike", 1, [0.0, 0.0, 0.0], [r * 0.65, h * 0.55, r * 0.65], p)
			_group(parts, "flame", "target", "vent_exhaust", "aftermath", count, [r, 0.0, 0.0], [r * 0.2, h * 0.4, r * 0.2], p)
		"cannonback_battery":
			# Paired shell barrels unfold; the salvo is one simultaneous arrival fan.
			_group(parts, "shell_cannon", "source", "battery_aim", "charge", 2, [r * 0.6, h * 0.45, gap], [r * 0.6, h * 0.6, r], p)
			_group(parts, "shell_cannon", "source", "battery_recoil", "strike", 2, [r * 0.6, h * 0.45, gap], [r * 0.6, h * 0.6, r], p)
			_group(parts, "rock", "path", "battery_salvo", "strike", count, [gap, h * 0.1, 0.0], [r * 0.25, h * 0.25, r * 0.4], p)
			_group(parts, "rock", "target", "shatter", "aftermath", count, [r * 0.5, 0.0, 0.0], [r * 0.15, h * 0.15, r * 0.15], p)
		"stormcapra_ascent":
			# Forked horns climb in mirrored corkscrews and rake down from the sky.
			_group(parts, "capra_horn", "source", "horn_ascend", "charge", 2, [gap, h * 0.2, 0.0], [r * 0.5, h, r * 0.3], p)
			_group(parts, "capra_horn", "path", "horn_descent", "strike", 2, [gap, 0.0, 0.0], [r * 0.5, h, r * 0.3], p)
			_group(parts, "lightning", "path", "horn_trace", "strike", count, [gap, 0.0, 0.0], [r * 0.1, h * 0.65, r * 0.1], p)
			_group(parts, "wind", "target", "horn_release", "aftermath", 2, [r, h * 0.2, 0.0], [r * 0.4, h * 0.5, r * 0.35], p)
		"stormursa_grounding":
			# Four broad paws plant in pairs; grounding conduits receive sky forks.
			_group(parts, "thunder_paw", "source", "paw_plant", "charge", 4, [maxf(gap, r * 0.65), 0.0, 0.0], [r * 0.5, h * 0.25, r * 0.6], p)
			_group(parts, "thunder_paw", "target", "paw_stamp", "strike", 4, [maxf(gap, r * 0.65), 0.0, 0.0], [r * 0.5, h * 0.25, r * 0.6], p)
			_group(parts, "lightning", "target", "sky_ground", "strike", 2, [maxf(gap, r * 0.65), 0.0, 0.0], [r * 0.18, h * 1.2, r * 0.18], p)
			_group(parts, "lightning", "target", "ground_drain", "aftermath", count, [r, 0.0, 0.0], [r * 0.1, h * 0.2, r * 0.35], p)
		_:
			_shared(parts, row, count, p)
	# Breakthrough layers are additive object motifs, not just colour/intensity.
	var layers: int = clampi(int(tier.get("secondary_layers", 0)), 0, 5)
	var secondary_scale: float = maxf(0.1, float(visual.get("secondary_layer_scale", 0.4)))
	var secondary: String = _type_shape(str(row.get("type", "rock")))
	for layer in range(layers):
		var layer_p: Dictionary = p.duplicate()
		layer_p["layer"] = layer + 1
		_group(parts, secondary, "path", "growth_orbit", "strike", 1, [gap + r * secondary_scale * float(layer + 1), h * secondary_scale, 0.0], [r * secondary_scale, h * secondary_scale, r * secondary_scale], layer_p)
		_group(parts, secondary, "target", "growth_release", "aftermath", 1, [gap + r * secondary_scale * float(layer + 1), 0.0, 0.0], [r * secondary_scale, h * secondary_scale, r * secondary_scale], layer_p)
	# Preserve authored order inside each priority (sort_custom is not stable).
	var ordered: Array[Dictionary] = []
	for priority in range(4):
		for part in parts:
			if _priority(part) == priority and ordered.size() < cap:
				ordered.append(part)
	return ordered


static func _priority(part: Dictionary) -> int:
	if str(part.get("motion", "")).begins_with("growth_"):
		return 1
	match str(part.get("phase", "")):
		"strike": return 0
		"charge": return 2
	return 3


static func _shared(parts: Array[Dictionary], row: Dictionary, count: int, p: Dictionary) -> void:
	var shape: String = _type_shape(str(row.get("type", "rock")))
	var r: float = float(p["radius_m"])
	var h: float = float(p["height_m"])
	var gap: float = float(p["head_gap_m"])
	match str(row.get("role", "WALL")).to_upper():
		"CHARGER":
			_group(parts, shape, "source", "lance_gather", "charge", count, [gap, h * 0.25, 0.0], [r * 0.25, h * 0.3, r], p)
			_group(parts, shape, "path", "lance", "strike", count, [gap, h * 0.25, 0.0], [r * 0.25, h * 0.3, r], p)
			_group(parts, shape, "target", "shatter", "aftermath", 2, [r, 0.0, 0.0], [r * 0.25, h * 0.25, r * 0.25], p)
		"DIVER":
			_group(parts, shape, "source", "talon_gather", "charge", count, [gap, h, 0.0], [r * 0.3, h * 0.6, r * 0.25], p)
			_group(parts, shape, "path", "talon", "strike", count, [gap, 0.0, 0.0], [r * 0.3, h * 0.6, r * 0.25], p)
			_group(parts, shape, "target", "feather_release", "aftermath", 2, [r, 0.0, 0.0], [r * 0.3, h * 0.25, r * 0.3], p)
		"CURRENT":
			_group(parts, shape, "source", "fountain_gather", "charge", count, [gap, 0.0, 0.0], [r * 0.3, h * 0.5, r * 0.3], p)
			_group(parts, shape, "path", "fountain", "strike", count, [gap, 0.0, 0.0], [r * 0.3, h * 0.5, r * 0.3], p)
			_group(parts, shape, "target", "wash_out", "aftermath", 2, [r, 0.0, 0.0], [r * 0.3, h * 0.25, r * 0.3], p)
		_:
			# An open vaulted colonnade, purely visual: no collision or protection.
			_group(parts, shape, "source", "shelter_gather", "charge", count, [r, 0.0, 0.0], [r * 0.4, h, r * 0.35], p)
			_group(parts, shape, "target", "shelter", "strike", count, [maxf(gap, r), 0.0, 0.0], [r * 0.4, h, r * 0.35], p)
			_group(parts, shape, "target", "settle", "aftermath", 2, [r, 0.0, 0.0], [r * 0.25, h * 0.3, r * 0.3], p)


static func _type_shape(type: String) -> String:
	match type.to_lower():
		"earth", "ground", "rock", "stone": return "rock"
		"fire": return "flame"
		"water": return "water"
		"wind", "air": return "wind"
		"ice": return "ice"
		"shadow", "dark": return "shadow"
		"psychic": return "psychic"
		"electric", "lightning": return "lightning"
		"nature", "grass", "leaf": return "tusk_root"
	return "rock"


static func _group(parts: Array[Dictionary], shape: String, anchor: String, motion: String, phase: String, count: int, offset: Array, size: Array, p: Dictionary) -> void:
	for i in range(count):
		if parts.size() >= int(p["cap"]):
			return
		parts.append({"shape": shape, "anchor": anchor, "motion": motion, "phase": phase, "count": 1, "index": i, "total": count, "angle": TAU * float(i) / float(maxi(count, 1)), "offset": offset.duplicate(), "size": size.duplicate(), "params": p.duplicate()})


static func pose(part: Dictionary, t: float, arrival_s: float, duration_s: float, from: Vector3, to: Vector3, seed: int) -> Transform3D:
	var p: Dictionary = part.get("params", {})
	var arrival: float = maxf(arrival_s, 0.001)
	var duration: float = maxf(duration_s, arrival + 0.001)
	var charge_end: float = arrival * float(p.get("charge_fraction", 0.35))
	var phase: String = str(part.get("phase", "strike"))
	var progress: float = 0.0
	var envelope: float = 1.0
	match phase:
		"charge":
			progress = clampf(t / maxf(charge_end, 0.001), 0.0, 1.0)
			envelope = sin(progress * PI) if t >= 0.0 and t <= charge_end else 0.0
		"aftermath":
			progress = clampf((t - arrival) / (duration - arrival), 0.0, 1.0)
			envelope = (1.0 - progress) if t >= arrival and t <= duration else 0.0
		_:
			progress = clampf((t - charge_end) / (arrival - charge_end), 0.0, 1.0)
			var impact_window: float = (duration - arrival) * float(p.get("impact_fraction", 0.15))
			envelope = minf(progress * 4.0, 1.0) if t >= charge_end and t <= arrival else maxf(0.0, 1.0 - (t - arrival) / maxf(impact_window, 0.001)) if t > arrival else 0.0
	if envelope <= 0.0:
		return Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), from)
	var delta: Vector3 = to - from
	var forward: Vector3 = Vector3(delta.x, 0.0, delta.z).normalized()
	if forward.length_squared() < 0.001:
		forward = Vector3.FORWARD
	var right: Vector3 = forward.cross(Vector3.UP).normalized()
	var frame: Basis = Basis(right, Vector3.UP, -forward)
	var index: int = int(part.get("index", 0))
	var total: int = maxi(1, int(part.get("total", 1)))
	var angle: float = float(part.get("angle", 0.0))
	var noise: float = _seed_unit(seed, index)
	var alternate: float = -1.0 if index % 2 == 0 else 1.0
	var lane: float = floorf(float(index) * 0.5)
	var lane_total: float = ceilf(float(total) * 0.5)
	var lane_spread: float = float(p.get("spread_m", 1.0)) * lane / maxf(1.0, lane_total - 1.0)
	var offset: Vector3 = _vector(part.get("offset", [0.0, 0.0, 0.0]))
	var size: Vector3 = _vector(part.get("size", [1.0, 1.0, 1.0]))
	var position: Vector3 = from
	match str(part.get("anchor", "path")):
		"source": position = from
		"target": position = to
		_: position = from.lerp(to, progress)
	var local: Vector3 = Vector3.ZERO
	var rotation: Vector3 = Vector3.ZERO
	var stretch: Vector3 = Vector3.ONE
	var motion: String = str(part.get("motion", "lance"))
	var h: float = float(p.get("height_m", 3.0))
	var arc: float = float(p.get("arc_height_m", 2.0))
	var spin: float = TAU * float(p.get("spin_turns", 1.0))
	match motion:
		"jaw_charge", "jaw_clamp":
			local = Vector3(alternate * offset.x * (1.6 - 0.6 * progress), offset.y, offset.z)
			rotation.z = alternate * (1.0 - progress) * PI * 0.25
			rotation.y = 0.0 if alternate < 0.0 else PI
		"breach_charge", "breach":
			local = offset + Vector3(0.0, sin(progress * PI) * arc, 0.0)
			rotation.x = lerpf(-PI * 0.35, PI * 0.2, progress)
		"surf":
			local = Vector3(alternate * offset.x, sin(progress * PI) * arc * 0.2, float(index) / float(total) * offset.x * (1.0 - progress))
			rotation.z = alternate * progress * PI * 0.25
		"feather_wheel", "crown_open", "mane_open":
			var a: float = angle + progress * spin
			local = Vector3(cos(a) * offset.x, offset.y + sin(a) * offset.x * 0.3, offset.z + sin(a) * offset.x)
			rotation = Vector3(0.0, -a, sin(a) * PI * 0.3)
		"feather_dive", "talon", "horn_descent":
			local = Vector3(alternate * (offset.x + lane_spread), offset.y + lane_spread * 0.3 + arc * (1.0 - progress) * (1.0 - progress), sin(angle) * offset.x * (1.0 - progress))
			rotation.x = -PI * 0.3 + progress * PI * 0.4
			rotation.z = alternate * PI * 0.18
		"antler_bud", "antler_rise", "root_canopy", "shelter":
			local = Vector3(alternate * offset.x, offset.y - h * (1.0 - progress), (lane - (lane_total - 1.0) * 0.5) * float(p.get("spread_m", 1.0)))
			stretch.y = maxf(0.05, progress)
			rotation.z = alternate * (1.0 - progress) * PI * 0.1
		"crown_fold":
			local = Vector3(cos(angle) * offset.x, offset.y + h * (1.0 - progress), sin(angle) * offset.x)
			rotation = Vector3(progress * PI * 0.3, -angle, 0.0)
		"solar_fan":
			local = Vector3(alternate * (offset.x + lane_spread) + sin(angle) * offset.x * (1.0 - progress), offset.y + lane_spread * 0.3 + sin(progress * PI) * arc * 0.3, 0.0)
			rotation.z = alternate * (1.0 - progress) * PI * 0.5
		"coil_charge":
			local = offset + Vector3(cos(progress * spin) * offset.x, 0.0, sin(progress * spin) * offset.x)
			rotation.y = progress * spin
		"circuit", "circuit_link", "growth_orbit":
			var a: float = angle + progress * spin
			# Orbit collapses to its side lane at arrival, never crosses the face.
			local = Vector3(alternate * (offset.x + lane_spread), offset.y + lane_spread * 0.3 + sin(a) * arc * (1.0 - progress), cos(a) * offset.x * (1.0 - progress))
			rotation = Vector3(0.0, a, alternate * PI * 0.2)
		"root_curl", "root_rush":
			local = Vector3(alternate * (offset.x + lane_spread), offset.y - h * 0.25 * (1.0 - progress), sin(angle + progress * PI) * offset.x * (1.0 - progress))
			rotation.y = alternate * (1.0 - progress) * PI * 0.25
		"forge_compress", "forge_open":
			local = Vector3(alternate * offset.x, offset.y, offset.z)
			stretch = Vector3(1.0 + (1.0 - progress) * 0.2, 0.5 + progress * 0.5, 1.0)
			rotation.z = alternate * progress * PI * 0.1
		"slag_arc", "ground_skip", "battery_salvo", "fountain":
			# Fountain launches are staggered but all bodies share one arrival.
			var launch: float = float(index) / float(total) * float(p.get("charge_fraction", 0.35)) if motion == "fountain" else 0.0
			var q: float = clampf((progress - launch) / maxf(1.0 - launch, 0.001), 0.0, 1.0)
			position = from.lerp(to, q)
			local = Vector3(alternate * (offset.x + lane_spread), offset.y + sin(q * PI) * arc * (0.5 + noise * 0.5), sin(angle) * offset.x * (1.0 - q))
			rotation.x = -q * spin
			rotation.z = alternate * q * PI * 0.25
		"battery_aim", "battery_recoil":
			local = Vector3(alternate * offset.x, offset.y, offset.z + sin(progress * PI) * float(p.get("spread_m", 1.0)))
			rotation.x = (1.0 - progress) * PI * 0.15
		"horn_ascend", "horn_trace":
			local = Vector3(alternate * offset.x, offset.y + sin(progress * PI) * arc, cos(progress * spin) * offset.x * (1.0 - progress))
			rotation = Vector3(-PI * 0.2, alternate * progress * spin, alternate * PI * 0.15)
		"paw_plant", "paw_stamp":
			local = Vector3(alternate * offset.x, offset.y + (1.0 - progress) * arc * 0.35, (lane - 0.5) * offset.x)
			rotation.x = (1.0 - progress) * PI * 0.15
		"sky_ground":
			# Forks descend from above and touch ground exactly at arrival.
			local = Vector3(alternate * offset.x, offset.y + h * (1.0 - progress), 0.0)
			stretch.y = maxf(0.05, progress)
		"lance_gather", "talon_gather", "fountain_gather", "shelter_gather":
			local = Vector3(alternate * offset.x, offset.y + sin(progress * PI) * arc * 0.25, cos(angle) * offset.x)
			rotation.z = alternate * (1.0 - progress) * PI * 0.25
		"lance":
			local = Vector3(alternate * (offset.x + lane_spread), offset.y + lane_spread * 0.2, sin(angle) * offset.x * (1.0 - progress))
			rotation.x = PI * 0.5
		_:
			# Every aftermath moves away/up/down from the endpoint, never inward.
			local = Vector3(cos(angle) * offset.x * (1.0 + progress), offset.y, sin(angle) * offset.x * (1.0 + progress))
			if motion in ["settle", "drain", "root_sink", "ground_drain", "grove_fold"]:
				local.y -= progress * h * 0.35
			else:
				local.y += progress * arc * (0.25 + noise * 0.25)
			rotation = Vector3(progress * PI * 0.2, angle + progress * spin * 0.25, 0.0)
	var scale: float = float(p.get("size_scale", 1.0)) * float(p.get("mastery_detail_scale", 1.0))
	# The endpoint stays fixed through the strike fade after arrival.
	var result_basis: Basis = frame * Basis.from_euler(rotation) * Basis.from_scale(size * stretch * scale * envelope)
	return Transform3D(result_basis, position + frame * local)


static func _vector(value: Array) -> Vector3:
	return Vector3(float(value[0]), float(value[1]), float(value[2])) if value.size() >= 3 else Vector3.ONE


static func _seed_unit(seed: int, index: int) -> float:
	# Integer arithmetic is platform-stable and never touches the global RNG.
	var mixed: int = (seed ^ ((index + 1) * 1103515245)) & 0x7fffffff
	mixed = (mixed * 1664525 + 1013904223) & 0x7fffffff
	return float(mixed % 10000) / 10000.0
