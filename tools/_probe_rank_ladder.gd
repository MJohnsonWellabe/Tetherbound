extends SceneTree

## T1-CAST. Is the rank value ladder still a ladder?
##
##   godot --headless --path . --script tools/_probe_rank_ladder.gd
##
## `npc_ranks.json` builds grunt/officer/captain as three steps on one value
## ladder, and C2 of `docs/acceptance/MEADOWS_EXIT_CRITERION.md` requires that ladder to
## read on sight. T1-LIGHT then closed the black-NPC defect by reviving
## `character_model.gd`'s ADDITIVE emission floor -- but that floor is gated on
## `tint luminance < 0.95`, and the captain's own tint is `#ffffff`. So the
## captain is the one rank the floor deliberately skips, on the grounds that it
## "still skips the trainer/Grandpa/villagers/captain/Warden, unchanged". That
## reasoning holds for the four rigs with their own bright textures. It does not
## hold for the captain, who is on the SAME near-black grunt-family texture the
## floor exists to rescue.
##
## This prints, per rank and per individual, the built material's albedo
## multiply and emission add together with the source texture's own median, so
## the ladder can be read as numbers rather than asserted from a comment.
## Headless is correct here: nothing is rendered, only materials built.

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const NPC_RANKS := preload("res://scripts/characters/npc_ranks.gd")
const TRAINER_NPC := preload("res://scripts/world/trainer_npc.gd")

## Every named grunt/officer/captain the chapter actually fields, in ladder
## order, plus the rank defaults they fall back to.
const NAMED := [
	{"rank": "grunt", "key": ""},
	{"rank": "officer", "key": ""},
	{"rank": "captain", "key": ""},
	{"rank": "grunt", "key": "quarry_picket_dorn"},
	{"rank": "grunt", "key": "warrens_watch_pell"},
	{"rank": "grunt", "key": "band2_outrider_kest"},
	{"rank": "officer", "key": "relay_officer_dell"},
	{"rank": "officer", "key": "stronghold_checkpoint"},
	{"rank": "officer", "key": "stronghold_courtyard"},
	{"rank": "captain", "key": "relay_captain"},
	{"rank": "captain", "key": "captain_riverwatch"},
	{"rank": "captain", "key": "captain_field"},
	{"rank": "captain", "key": "captain_ridge"},
	{"rank": "captain", "key": "stronghold_elite"},
]


func _init() -> void:
	print("rank      individual                 base            texMedian  albedoMul  emissAdd  effective")
	for row: Dictionary in NAMED:
		var rank := str(row["rank"])
		var key := str(row["key"])
		var base_key := ""
		if key != "":
			var spec := _spec_for(key)
			if spec.is_empty():
				print("  MISSING trainer spec: %s" % key)
				continue
			base_key = str(spec.get("base", ""))
		var cfg := NPC_RANKS.config_for(rank, base_key)
		if cfg.is_empty():
			print("  MISSING rank config: %s" % rank)
			continue
		var model_path := str(cfg.get("model", ""))
		var tex_median := _texture_median(model_path)
		var tint := _body_tint(cfg)
		var tint_lum := tint.r * 0.2126 + tint.g * 0.7152 + tint.b * 0.0722
		# The two channels `_shared_variant_material()` actually writes for a
		# body surface: an albedo multiply always, and the rank's own declared
		# ADDITIVE emission floor (`npc_ranks.json`'s `emission_floor`).
		var emiss := tint_lum * float(cfg.get("emission_floor", 0.0))
		var effective := tex_median * tint_lum + emiss
		print("%-9s %-26s %-15s %8.3f %10.3f %9.3f %10.3f" % [
			rank, (key if key != "" else "(rank default)"),
			(base_key if base_key != "" else "(rank base)"),
			tex_median, tint_lum, emiss, effective])
	quit()


## The trainer entry for `id`, out of the same merged band tables the world
## places from.
func _spec_for(id: String) -> Dictionary:
	for path: String in _band_tables():
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if not parsed is Dictionary:
			continue
		for value: Variant in (parsed as Dictionary).values():
			if not value is Array:
				continue
			for entry: Variant in value as Array:
				if entry is Dictionary and str((entry as Dictionary).get("id", "")) == id:
					return entry as Dictionary
	return {}


func _band_tables() -> Array:
	var out: Array = []
	var dir := DirAccess.open("res://data/config/bands")
	if dir == null:
		return out
	for band: String in dir.get_directories():
		out.append("res://data/config/bands/%s/trainers.json" % band)
	return out


func _body_tint(cfg: Dictionary) -> Color:
	var palette: Dictionary = cfg.get("palette", {})
	var hex := str(palette.get("*", "#ffffff"))
	return Color(hex)


## Median luminance of the rig's own painted texture, over the pixels that
## actually carry paint -- the same measure `npc_ranks.json`'s own
## `_comment_palette` quotes for the grunt (0.137).
func _texture_median(model_path: String) -> float:
	if model_path == "":
		return -1.0
	var tex_path := model_path.get_basename() + "_texture_0.png"
	if not ResourceLoader.exists(tex_path):
		# The .glb sits beside its own texture; fall back to the directory scan.
		var dir_path := model_path.get_base_dir()
		var dir := DirAccess.open(dir_path)
		if dir == null:
			return -1.0
		for f: String in dir.get_files():
			if f.ends_with("_texture_0.png"):
				tex_path = dir_path.path_join(f)
				break
	var image := Image.load_from_file(ProjectSettings.globalize_path(tex_path))
	if image == null:
		return -1.0
	image.resize(256, 256, Image.INTERPOLATE_BILINEAR)
	var values: Array[float] = []
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			var l := c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
			if l > 0.02:
				values.append(l)
	if values.is_empty():
		return -1.0
	values.sort()
	return values[values.size() / 2]
