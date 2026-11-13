extends "res://tests/test_case.gd"

## THINGS-TELLDUST3 (ships 13 Nov 2026): `dust_phase_coherence`. Off, each puff
## fades on its own random phase and the band breaks into beads; on, the puffs
## share one slow wave and none fades out. ON: LANE-JUDGE
## G-things-telldust3-grunt-medium.md, F38#11 6.55 -> 7.06 (3/3), no loss.
const TELL_STYLE := preload("res://scripts/combat/tell_style.gd")


func _soft() -> Dictionary:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/combat.json"))
	return (parsed.get("telegraph", {}) as Dictionary).get("soft_style", {})


## Per-puff alpha factor and size along an 8 m line at the style's spacing.
func _puffs(style: Dictionary, coherence: float, time: float) -> Array[Vector4]:
	var out: Array[Vector4] = []
	var spacing := float(style.get("dust_spacing_m", 0.3))
	for slot in int(8.0 / spacing):
		out.append(TELL_STYLE.dust_puff(slot, slot * spacing, time, float(style.get("dust_size_m", 0.8)),
			float(style.get("dust_rise_m", 0.06)), float(style.get("dust_hz", 1.1)), coherence,
			float(style.get("dust_wave_per_m", 0.12)), float(style.get("dust_phase_jitter", 0.06))))
	return out


func test_the_judged_band_ships_on() -> void:
	var soft := _soft()
	assert_eq(float(soft.get("dust_phase_coherence", 0.0)), 1.0)
	assert_eq(float(soft.get("dust_size_m", 0.0)), 0.5)
	assert_eq(float(soft.get("dust_spacing_m", 0.0)), 0.2)
	assert_eq(float(soft.get("dust_rise_m", 0.0)), 0.04)
	assert_eq(int(soft.get("dust_max", 0)), 400)
	var why := str(soft.get("_why_dust_coherent_1113", ""))
	assert_true(why.contains("G-things-telldust3-grunt-medium.md") and why.contains("7.06") and why.contains("6.55"))


func test_off_reproduces_the_beads_and_on_keeps_one_band() -> void:
	var soft := _soft()
	for time: float in [0.0, 0.37, 1.1, 2.6]:
		var beads := _puffs(soft, 0.0, time)
		var band := _puffs(soft, 1.0, time)
		assert_true(beads.size() > 10)
		var bead_fade: Array = beads.map(func(p: Vector4) -> float: return p.z)
		var band_fade: Array = band.map(func(p: Vector4) -> float: return p.z)
		assert_true(bead_fade.min() < bead_fade.max() * 0.25, "off: some puff is nearly invisible beside a full one")
		assert_true(band_fade.min() > band_fade.max() * 0.4, "on: no puff fades out")
		for index in band.size() - 1:
			assert_true(absf(band[index].z - band[index + 1].z) < 0.08, "on: neighbours share near-equal alpha")
			assert_true(absf(band[index].x - band[index + 1].x) < float(soft.get("dust_size_m", 0.8)) * 0.15,
				"on: neighbours share near-equal size")
			assert_true(band[index].w == 0.0, "on: no puff jumps back along a lane")


func test_off_is_the_shipped_maths() -> void:
	# The shipped formula, written out: random phase per slot, fade sin(pi * phase).
	var puff: Vector4 = TELL_STYLE.dust_puff(7, 2.1, 0.5, 0.8, 0.06, 1.1, 0.0, 0.12, 0.06)
	var seed := fposmod(sin(7.0 * 12.9898) * 43758.5453, 1.0)
	var phase := fposmod(0.5 * 1.1 + seed, 1.0)
	assert_almost_eq(puff.x, 0.8 * (0.55 + 0.9 * phase) * (0.8 + 0.4 * seed), 0.00001)
	assert_almost_eq(puff.y, 0.06 * phase, 0.00001)
	assert_almost_eq(puff.z, sin(PI * phase), 0.00001)
	assert_almost_eq(puff.w, phase, 0.00001)
