extends SceneTree

## CAST CALL. One photograph of every humanoid the game actually puts in front
## of a player -- the six production rigs `docs/art/HUMANOID_ASSET_INVENTORY.md`
## lists as current `main`, plus every Team Tether rank `data/config/
## npc_ranks.json` declares -- at the SAME camera, lighting and framing per
## character, so a blind critic is judging faces and palettes against each
## other rather than judging one shot's lighting against another's.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_character_cast.gd
##
## NEVER `--headless` with a real rendering driver: verified 2026-08-22 on a
## bare `ColorRect` with no project scenes at all -- with `--headless` the
## process prints its first line and then sits in total silence until killed,
## no error, no crash, no partial output, exit 124/143 from `timeout`. It also
## leaves a ZOMBIE Godot process still burning CPU after the lane that started
## it gives up, which is the single most expensive trap in this repo
## (`ralph/conventions.md`, "Art pipeline traps"). Drop `--headless`, keep
## `xvfb-run` for the virtual display -- the identical script then writes its
## PNGs and exits 0.
##
## WHY NOT `meadows_playground.tscn`: `_probe_corridor_survey.gd` measured
## ~2.4s/frame under llvmpipe rendering that scene's 143,630 scattered props,
## and that cost is per AWAITED FRAME regardless of what the shot is actually
## about. This tool photographs eleven still humans against a flat backdrop --
## no terrain, no Terrain3D streaming, no vegetation -- so it builds its own
## bare stage, the same pattern `capture_npc_ranks.gd` and
## `capture_village_npcs.gd` already ship (both build a `Node3D` + two
## `DirectionalLight3D`s + however many `CharacterModel` holders and shoot,
## with no scene dependency at all).
##
## FRAME BUDGET, counted directly against the constants below, at the
## PESSIMISTIC 2.4s/frame corridor-survey rate (this stage is dramatically
## lighter -- six distinct human meshes total, the four rank variants reuse
## the Warden's -- so the real rate should beat this by a wide margin; the
## arithmetic below is the worst case, not the expectation):
##
##   world settle                 WORLD_SETTLE_FRAMES  =  15
##   group build settle           GROUP_SETTLE_FRAMES   =  35
##   per-view camera/pose settle  CAST.size() * 2 views * TURN_FRAMES
##                                 = 10 * 2 * 6           = 120
##   line-up settle               LINEUP_SETTLE_FRAMES  =  15
##   shutter waits (one frame_post_draw per PNG, 20 portraits + 1 line-up)
##                                                        =  21
##   -----------------------------------------------------------
##   total awaited frames                                = 206
##   206 * 2.4s ~= 494s ~= 8.2 minutes -- well under the 15-minute target.
##
## STAGING: every character is built ONCE, all ten side by side along +X
## (`SPACING` apart), the same "build the whole group, settle once" shape
## `capture_npc_ranks.gd` already proved -- rebuilding per-shot would multiply
## the one real cost in this scene (shader/material compile on first use) by
## ten for no reason. Each character's own portrait camera then frames just
## that slot; a neighbour three metres away sits well outside `FOV`'s cone.
## The three-quarter view turns the CHARACTER (`holder.rotation.y`), not the
## camera -- camera position, target and lighting stay bit-for-bit identical
## across every character and both views, which is what "identical camera/
## lighting/framing per character" in the shoot brief actually buys: two
## frames differing only in what is being photographed, never in how.
##
## WHO'S SHOT, and where each config actually comes from:
## - trainer / grandpa / warden: `art.json`'s own top-level blocks.
## - villager-male / villager-female: `HUMANOID_ASSET_INVENTORY.md` names
##   `villager_male_lod0.glb` / `villager_female_lod0.glb` as the two rigs,
##   but neither has a bare config key in `art.json` -- only per-persona
##   blocks that ride on top of them (`villager_keeper`/`villager_quarryman`
##   on the male base, `villager_farmer`/`villager_smith`/`villager_ranger`
##   on the female one; confirmed by reading every block's own `model` field).
##   `villager_keeper` and `villager_farmer` are shot as the representative
##   persona for each base rig -- picked because both carry a plain/neutral
##   look (keeper: unmodified `#ffffff` tint; farmer: the base tint plus its
##   own hair colour) rather than one of the other personas' extra palette
##   tweaks.
## - grunt-archetype: `assets/characters/grunt/grunt_lod0.glb` is imported and
##   sits on disk, but NOTHING in `data/config/` or `scripts/` references
##   `assets/characters/grunt` -- confirmed by grep. It has no `art.json` key
##   to read, so `GRUNT_CFG` below is built directly, not guessed: the raw
##   glTF JSON chunk was parsed off disk and its `animations` array reads
##   `["idle","walk","sprint","jump","throw"]` with `Armature`/`Hips`/
##   `Spine02`/`Head` bones present -- the same clip set and bone names every
##   wired rig carries, so this is the same rig baked through the same
##   pipeline, just never plugged into a config. Height is set to the
##   trainer's own 1.80m (CLAUDE.md's stated human ruler) for lack of any
##   other authored value; this is a CAPTURE-ONLY convenience, not a data
##   change, and is not written back to any config file.
## - rank-grunt / rank-officer / rank-captain / rank-warden: `npc_ranks.gd`'s
##   `config_for()`, which is the WARDEN'S OWN RIG with that rank's body
##   palette and chest-badge accessory laid over it (`npc_ranks.json`'s own
##   comment: no faction-specific body exists yet, so every rank reuses his
##   geometry regardless of the orphaned grunt archetype above).
##
## WHY THE RANK FRAMES MATTER (repo note -- the critic below is blind to this,
## and stays that way; nothing about it is said to it): `ralph/
## ASSESSMENT_2026-08-23.md` recorded black Team Tether figures as a confirmed
## game bug -- `character_model.gd`'s `_shared_variant_material()` multiplied
## a dark rank palette into BOTH `albedo_color` and the shared self-lit
## `emission` channel, crushing a dark rank to a near-black silhouette. An
## ADDITIVE emission floor has since landed there (the `EMISSION_FLOOR_BLEND`/
## `EMISSION_FLOOR_MULTIPLIER` block). The four rank frames are shot under the
## same flat, near-frontal key `capture_npc_ranks.gd` already chose for
## exactly this reason -- its own comment: "so the jacket's own tint reads
## without deep self-shadow crushing it to near-black -- this is a palette
## comparison render, not a mood shot" -- deliberately the lighting state
## where a still-crushed figure would be visible rather than hidden by shadow.
## These ten frames (`07`-`10`, front and three-quarter) are the real evidence
## for whether the fix reads today; nothing here tells the critic that.

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const NPC_RANKS := preload("res://scripts/characters/npc_ranks.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const OUT_DIR := "res://shots/characters"

## See the header's "grunt-archetype" note for where every field here came
## from -- read off the raw .glb, not assumed.
const GRUNT_CFG := {
	"model": "res://assets/characters/grunt/grunt_lod0.glb",
	"height": 1.80,
	"model_yaw": 0.0,
	"clips": {
		"idle": "idle", "walk": "walk", "sprint": "sprint",
		"jump": "jump", "throw": "throw"
	}
}

## Left to right in the line-up, and the order everything else below iterates
## in. `kind` says which of the three config sources `_config_for()` should
## read; `key` is that source's own lookup key (unused for "raw").
const CAST := [
	{"slug": "trainer", "kind": "config", "key": "trainer"},
	{"slug": "grandpa", "kind": "config", "key": "grandpa"},
	{"slug": "warden", "kind": "config", "key": "warden"},
	{"slug": "villager-male", "kind": "config", "key": "villager_keeper"},
	{"slug": "villager-female", "kind": "config", "key": "villager_farmer"},
	{"slug": "grunt-archetype", "kind": "raw", "key": ""},
	{"slug": "rank-grunt", "kind": "rank", "key": "grunt"},
	{"slug": "rank-officer", "kind": "rank", "key": "officer"},
	{"slug": "rank-captain", "kind": "rank", "key": "captain"},
	{"slug": "rank-warden", "kind": "rank", "key": "warden"},
]

const SPACING := 3.0            # metres between each character's own stage slot
const WORLD_SETTLE_FRAMES := 15
const GROUP_SETTLE_FRAMES := 35 # after all ten build, before the first shutter
const TURN_FRAMES := 6          # after a camera reposition or a character turn
const LINEUP_SETTLE_FRAMES := 15

## Portrait camera: identical for every character and both views. Sized so a
## 1.85m figure (the Warden, the tallest rig shot here) keeps headroom and
## ground both in frame at `FOV`/`DIST`.
const FOV := 45.0
const DIST := 3.0
const CAM_HEIGHT := 1.3
const LOOK_HEIGHT := 1.0
const THREE_QUARTER_DEG := 35.0

## Line-up camera: pulled back far enough for all ten slots -- `SPACING` *
## (CAST.size() - 1) = 27m of spread, plus body-width margin, at 1280x800's
## ~1.6 aspect ratio (Godot's default `KEEP_HEIGHT`, so the wider horizontal
## FOV comes from `LINEUP_FOV` through the aspect, not from `LINEUP_FOV`
## alone): horizontal half-angle = atan(tan(60/2 deg) * 1.6) ~= 42.8deg, so
## `LINEUP_DIST` * tan(42.8deg) ~= 15.7m of half-width at 17m back -- a full
## ~31m across, comfortably over the 27m spread plus each figure's own width.
const LINEUP_FOV := 60.0
const LINEUP_DIST := 17.0
const LINEUP_CAM_HEIGHT := 2.2
const LINEUP_LOOK_HEIGHT := 1.0


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; this tool only makes sense under xvfb-run")
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var world := Node3D.new()
	root.add_child(world)
	_build_environment(world)
	for i in WORLD_SETTLE_FRAMES:
		await process_frame

	# Build every character once, all ten side by side, before any shutter --
	# see the header's "STAGING" note for why this is one settle, not ten.
	var holders: Array[Node3D] = []
	var heights: Array[float] = []
	for i in CAST.size():
		var entry: Dictionary = CAST[i] as Dictionary
		var slug: String = str(entry.get("slug", "?"))
		var cfg := _config_for(entry)
		var holder := Node3D.new()
		holder.set_script(CHARACTER_MODEL)
		holder.position = Vector3(i * SPACING, 0.0, 0.0)
		world.add_child(holder)
		var built := false
		if not cfg.is_empty():
			built = bool(holder.call("build_from_config", cfg))
		if not built:
			var reason := "no config found" if cfg.is_empty() else "build_from_config() returned false"
			print("FAIL %s: could not stage this character (%s)" % [slug, reason])
			holder.queue_free()
			holders.append(null)
			heights.append(-1.0)
			continue
		if holder.has_method("play"):
			holder.call("play", "idle")
		var box: AABB = RENDER_BOUNDS.measure(holder)
		holders.append(holder)
		heights.append(box.size.y)

	for i in GROUP_SETTLE_FRAMES:
		await process_frame

	var camera := Camera3D.new()
	camera.far = 200.0
	world.add_child(camera)
	camera.make_current()

	for i in CAST.size():
		var holder: Node3D = holders[i]
		if holder == null:
			continue
		var entry: Dictionary = CAST[i] as Dictionary
		var slug: String = str(entry.get("slug", "?"))
		var slot_x: float = i * SPACING
		var height_m: float = heights[i]
		var stem := "%02d-%s" % [i + 1, slug]

		holder.rotation.y = 0.0
		_frame_portrait(camera, slot_x)
		for f in TURN_FRAMES:
			await process_frame
		await _shoot("%s-front" % stem, height_m)

		holder.rotation.y = deg_to_rad(THREE_QUARTER_DEG)
		for f in TURN_FRAMES:
			await process_frame
		await _shoot("%s-threequarter" % stem, height_m)

		# Reset for the line-up below, which wants every figure facing the
		# same way the portraits opened on.
		holder.rotation.y = 0.0

	var live := holders.filter(func(h: Node3D) -> bool: return h != null)
	if live.size() < 2:
		print("FAIL 11-lineup-all: fewer than two characters staged; skipping the ruler frame")
	else:
		_frame_lineup(camera)
		for f in LINEUP_SETTLE_FRAMES:
			await process_frame
		await _shoot("11-lineup-all", -1.0)

	print("")
	print("cast written to %s" % OUT_DIR)
	quit(0)


## Which of the three config sources this cast entry reads from. Never a
## guess: "config" and "rank" both go through the game's own lookup code
## (`character_model.gd`, `npc_ranks.gd`); "raw" is the one archetype with no
## wired config, documented in the header above.
func _config_for(entry: Dictionary) -> Dictionary:
	match str(entry.get("kind", "")):
		"config":
			return CHARACTER_MODEL.config_for(str(entry.get("key", "")))
		"rank":
			return NPC_RANKS.config_for(str(entry.get("key", "")))
		"raw":
			return GRUNT_CFG.duplicate(true)
		_:
			return {}


## Flat, near-frontal key plus a cool fill -- the same shape
## `capture_npc_ranks.gd` already uses, and for the same reason: this is a
## palette-comparison render, and deep self-shadow would hide the exact
## defect these frames exist to surface (see the header's rank note).
func _build_environment(world: Node3D) -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.10, 0.11, 0.13)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.87, 0.90)
	env.ambient_light_energy = 2.2
	env_node.environment = env
	world.add_child(env_node)

	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-25.0), deg_to_rad(-10.0), 0.0)
	key.light_energy = 1.8
	world.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation = Vector3(deg_to_rad(-20.0), deg_to_rad(170.0), 0.0)
	fill.light_energy = 1.0
	fill.light_color = Color(0.80, 0.85, 0.95)
	world.add_child(fill)


func _frame_portrait(camera: Camera3D, slot_x: float) -> void:
	camera.fov = FOV
	camera.global_position = Vector3(slot_x, CAM_HEIGHT, DIST)
	camera.look_at(Vector3(slot_x, LOOK_HEIGHT, 0.0), Vector3.UP)


func _frame_lineup(camera: Camera3D) -> void:
	var centre_x: float = (CAST.size() - 1) * 0.5 * SPACING
	camera.fov = LINEUP_FOV
	camera.global_position = Vector3(centre_x, LINEUP_CAM_HEIGHT, LINEUP_DIST)
	camera.look_at(Vector3(centre_x, LINEUP_LOOK_HEIGHT, 0.0), Vector3.UP)


func _shoot(name: String, height_m: float) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		print("FAIL %s: viewport returned no image" % name)
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	if image.save_png(path) != OK:
		print("FAIL %s: save_png" % name)
		return
	if height_m >= 0.0:
		print("  %-26s -> %s  (%.3fm tall)" % [name, path, height_m])
	else:
		print("  %-26s -> %s" % [name, path])
