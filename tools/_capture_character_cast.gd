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
## (`docs/AGENT_WORKFLOW.md`, "Art pipeline traps"). Drop `--headless`, keep
## `xvfb-run` for the virtual display -- the identical script then writes its
## PNGs and exits 0.
##
## WHY NOT `meadows_playground.tscn`: `_probe_corridor_survey.gd` measured
## ~2.4s/frame under llvmpipe rendering that scene's 143,630 scattered props,
## and that cost is per AWAITED FRAME regardless of what the shot is actually
## about. This tool photographs fourteen still humans against a flat backdrop --
## no terrain, no Terrain3D streaming, no vegetation -- so it builds its own
## bare stage, the same pattern `capture_npc_ranks.gd` and
## `capture_village_npcs.gd` already ship (both build a `Node3D` + two
## `DirectionalLight3D`s + however many `CharacterModel` holders and shoot,
## with no scene dependency at all).
##
## FRAME BUDGET, counted directly against the constants below, at the
## PESSIMISTIC 2.4s/frame corridor-survey rate (this stage is dramatically
## lighter -- seven distinct human meshes total (trainer/grandpa/warden/
## villager-male/villager-female/grunt, the rank frames all reuse either the
## grunt or the Warden's own rig, NP2-grunt-wire) -- so the real rate should
## beat this by a wide margin; the arithmetic below is the worst case, not the
## expectation):
##
##   world settle                 WORLD_SETTLE_FRAMES  =  15
##   group build settle           GROUP_SETTLE_FRAMES   =  35
##   per-view camera/pose settle  CAST.size() * 2 views * TURN_FRAMES
##                                 = 13 * 2 * 6           = 156
##   line-up settle               LINEUP_SETTLE_FRAMES  =  15
##   shutter waits (one frame_post_draw per PNG, 26 portraits + 1 line-up)
##                                                        =  27
##   -----------------------------------------------------------
##   total awaited frames                                = 248
##   248 * 2.4s ~= 595s ~= 9.9 minutes -- still under the 15-minute target.
##   MEASURED on this box: the whole pass completes in well under two minutes,
##   because a bare stage is nowhere near the corridor survey's per-frame cost.
##
## STAGING: every character is built ONCE, all thirteen side by side along +X
## (`SPACING` apart), the same "build the whole group, settle once" shape
## `capture_npc_ranks.gd` already proved -- rebuilding per-shot would multiply
## the one real cost in this scene (shader/material compile on first use) by
## thirteen for no reason. Each character's own portrait camera then frames just
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
## - grunt-archetype: NP2-grunt-wire added `art.json`'s own `grunt` block, so
##   this is now `art.json`'s own top-level entry like trainer/grandpa/warden
##   above, not a hand-built stand-in -- it shows the rig's unranked, un-tinted
##   painted finish, the same reference every rank-grunt/officer/captain frame
##   below is judged against.
## - rank-grunt / rank-officer / rank-captain: `npc_ranks.gd`'s `config_for()`,
##   which is now the GRUNT rig (each rank entry's own `base` key) with that
##   rank's body palette and chest badge laid over it -- NP2-grunt-wire moved
##   these three off the Warden's own body onto the faction's actual
##   rank-and-file archetype.
## - rank-warden: same `config_for()` path, but the Warden rank entry names no
##   `base`, so it still falls back to his own `art.json` rig -- the one rank
##   that does NOT share a body with anyone else in this cast.
## - captain-field / captain-ridge / captain-riverwatch: `trainer_npc.gd`'s own
##   `model_config()`, the path the shipped world uses, so these three show the
##   rank config WITH each site's palette override laid over it. See the CAST
##   entry's own note for why photographing only the generic `rank-captain`
##   made this survey blind to the three captains a player actually fights.
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
## These frames (`07`-`10` and `11`-`13`, front and three-quarter) are the real
## evidence for whether the fix reads today; nothing here tells the critic that.

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const NPC_RANKS := preload("res://scripts/characters/npc_ranks.gd")
const TRAINER_NPC := preload("res://scripts/world/trainer_npc.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const OUT_DIR := "res://shots/characters"

## Left to right in the line-up, and the order everything else below iterates
## in. `kind` says which of the two config sources `_config_for()` should
## read; `key` is that source's own lookup key.
const CAST := [
	{"slug": "trainer", "kind": "config", "key": "trainer"},
	{"slug": "grandpa", "kind": "config", "key": "grandpa"},
	{"slug": "warden", "kind": "config", "key": "warden"},
	{"slug": "villager-male", "kind": "config", "key": "villager_keeper"},
	{"slug": "villager-female", "kind": "config", "key": "villager_farmer"},
	{"slug": "grunt-archetype", "kind": "config", "key": "grunt"},
	{"slug": "rank-grunt", "kind": "rank", "key": "grunt"},
	{"slug": "rank-officer", "kind": "rank", "key": "officer"},
	{"slug": "rank-captain", "kind": "rank", "key": "captain"},
	{"slug": "rank-warden", "kind": "rank", "key": "warden"},
	# The three NAMED captains, built through the same `TrainerNpc.model_config()`
	# the shipped world builds them with -- not through `npc_ranks.config_for()`
	# like the four rank frames above.
	#
	# They are here because leaving them out is how this survey photographed the
	# wrong subject. `rank-captain` renders the GENERIC captain, and until VIS-CAST
	# the generic captain was the only captain wearing the faction's oxblood: each
	# of these three overrides `palette` at its own site, and `model_config()`
	# replaced the whole dictionary rather than merging it, so all three rendered
	# in the old olive/tan/slate. A blind round shown only `rank-captain` would
	# have confirmed the faction colour had landed while every captain a player
	# actually fights still had none of it -- the same class of harness defect
	# `archive/ralph/VISUAL_LEDGER.md` records six of, where "a fix that lives in one tool
	# does not protect the next tool that does the same thing".
	{"slug": "captain-field", "kind": "trainer", "key": "captain_field"},
	{"slug": "captain-ridge", "kind": "trainer", "key": "captain_ridge"},
	{"slug": "captain-riverwatch", "kind": "trainer", "key": "captain_riverwatch"},
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

## Line-up camera: pulled back far enough for all THIRTEEN slots -- `SPACING` *
## (CAST.size() - 1) = 36m of spread, plus body-width margin, at 1280x800's
## ~1.6 aspect ratio (Godot's default `KEEP_HEIGHT`, so the wider horizontal
## FOV comes from `LINEUP_FOV` through the aspect, not from `LINEUP_FOV`
## alone): horizontal half-angle = atan(tan(60/2 deg) * 1.6) ~= 42.8deg, so
## `LINEUP_DIST` * tan(42.8deg) ~= 20.4m of half-width at 22m back -- a full
## ~40m across, over the 36m spread plus each figure's own width.
##
## 22m, not the 17m this held while the cast was ten: 17m frames ~31m, and the
## three named captains added below push the spread to 36m, so the old distance
## would have cropped the far end of its own line-up off the edge of the frame
## -- and cropped it silently, since nothing in this tool measures whether the
## last slot landed inside the view.
## Shoulder-to-shoulder for the line-up only; `SPACING` still governs the
## portraits, where a neighbour must stay outside the portrait cone.
const LINEUP_SPACING := 1.15
const LINEUP_FOV := 48.0
## Derived from the spread rather than guessed, and deliberately snug.
##
## This was 17.0 for a ten-character cast and was raised to 22.0 when three more
## were added -- which fixed the crop and created a worse defect a blind round
## measured immediately: at 22 m the whole cast renders as a 58-pixel strip
## filling under 10% of an 800px frame, so the one shot whose entire job is
## comparing the cast at a single scale could not be read without magnifying it
## 4x. Godot's default `KEEP_HEIGHT` means the horizontal half-angle is
## `atan(tan(LINEUP_FOV/2) * aspect)`; at 1280x800 and a 48 deg FOV that is
## ~35.6 deg, so the half-width is `LINEUP_DIST * 0.716`. Closing the ranks to
## `LINEUP_SPACING` puts the cast inside 13.8 m plus a body either side, so 11.5 m
## back gives ~16.5 m of width -- and, far more importantly, a figure now stands
## roughly a third of the frame high instead of a fourteenth, which is the only
## thing that makes a one-scale cast comparison actually readable.
const LINEUP_DIST := 11.5
## Eye level, not a raised three-quarter view. At 2.2m the camera looked DOWN on
## the line and pushed it into the top third of the plate, leaving 40% of the
## frame as empty floor; at roughly chest height the cast fills the frame and the
## horizon sits behind their heads, which is also the angle a player meets them from.
const LINEUP_CAM_HEIGHT := 1.15
const LINEUP_LOOK_HEIGHT := 0.92


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
		# Feet on the ground line, not the rig's own pivot -- the same measured
		# seating `_capture_creature_roster.gd` uses. Rigs disagree about where
		# their origin sits, so a shared `position.y` leaves some sunk and some
		# floating, and every height measured off the frame inherits that error.
		holder.position.y = -box.position.y * holder.scale.y
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

		# ONLY the subject is visible for its own portrait.
		#
		# Every character stands `SPACING` apart on one stage and the key light
		# is a directional at -52 degrees, so each figure throws a shadow several
		# metres along the ground -- straight into its neighbour's portrait frame.
		# A blind round measured a hard-edged intruding shadow in 24 of 28 frames
		# and, correctly, called it a bug in the shot. The tell was in the
		# exception list: the only portraits WITHOUT it were the trainer's, and
		# the trainer is slot 0, the one character with no neighbour to his left.
		#
		# Hiding the rest costs nothing -- they are already built, and staging
		# them all once is still what avoids re-paying the shader compile per
		# shot, which is the whole reason the group is built up front.
		for other in holders:
			if other != null:
				(other as Node3D).visible = (other == holder)
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
		# same way the portraits opened on, and visible again.
		holder.rotation.y = 0.0
		for other in holders:
			if other != null:
				(other as Node3D).visible = true

	var live := holders.filter(func(h: Node3D) -> bool: return h != null)
	if live.size() < 2:
		print("FAIL %s: fewer than two characters staged; skipping the ruler frame" % _lineup_stem())
	else:
		# Close the ranks for this one frame. The portraits need SPACING wide
		# enough that a neighbour never intrudes on a 45-degree portrait cone
		# (3.0m), but that same spacing puts 36m between the end characters,
		# and a camera far enough back to hold 36m renders the whole cast as a
		# ~58px strip in an 800px frame -- which a blind round called out as
		# making the one comparison shot unreadable without 4x magnification.
		# Standing them shoulder to shoulder is the fix that does not trade
		# away the portraits: the line-up wants them CLOSE.
		for i in CAST.size():
			if holders[i] != null:
				(holders[i] as Node3D).position.x = i * LINEUP_SPACING
		_frame_lineup(camera)
		for f in LINEUP_SETTLE_FRAMES:
			await process_frame
		await _shoot(_lineup_stem(), -1.0)

	print("")
	print("cast written to %s" % OUT_DIR)
	quit(0)


## Which of the two config sources this cast entry reads from. Never a guess:
## both go through the game's own lookup code (`character_model.gd`,
## `npc_ranks.gd`).
func _config_for(entry: Dictionary) -> Dictionary:
	match str(entry.get("kind", "")):
		"config":
			return CHARACTER_MODEL.config_for(str(entry.get("key", "")))
		"rank":
			return NPC_RANKS.config_for(str(entry.get("key", "")))
		"trainer":
			# Through the real path, so this frame shows what the world builds --
			# rank config first, then that trainer's own site overrides laid over
			# it, exactly as `trainer_npc.gd` does when it places the body.
			var spec: Dictionary = TRAINER_NPC.trainer(str(entry.get("key", "")))
			if spec.is_empty():
				return {}
			return TRAINER_NPC.model_config(spec)
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
	# MID VALUE, not near-black. At (0.10,0.11,0.13) the backdrop sat behind every
	# head at roughly the same value as the cast's dark caps and dark hair, and a
	# blind round noted the consequence: head silhouettes were being judged against
	# a background that hides them, for the dark-haired majority of the cast. A
	# character survey stages heads against a value they can be cut out of.
	env.background_color = Color(0.28, 0.30, 0.33)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.87, 0.90)
	# CALIBRATED against this stage's own floor, the same way and for the same
	# reason as `_capture_creature_roster.gd` -- see that file's long note. This
	# rig summed ambient 2.2 plus a 1.8 key plus a 1.0 fill, and a survey that
	# over-exposes cannot be trusted on colour: three creature rounds spent their
	# top finding on an over-exposure that measured 2.3x on the sibling tool.
	# THE FLOOR IS THE TARGET: albedo (0.34,0.35,0.37) must render near
	# (87,89,94). Re-measure it after any change here rather than eyeballing.
	#
	# It matters more here than anywhere, because this survey's own subject is
	# a faction whose costume a blind round measured at 0.11-0.18 lightness. A
	# judgement about whether near-black uniforms read is worthless taken off a
	# stage that is not exposed correctly in the first place.
	# Two measured passes: 2.2/1.8/1.0 gave 1.9x, 0.62/0.75/0.42 gave 1.45x,
	# 0.43/0.52/0.29 gave 1.22x, 0.35/0.43/0.24 landed it; lifting the backdrop
	# drifted it to 1.25 so 0.28/0.34/0.19 re-lands it. Re-measure after ANY change here.
	env.ambient_light_energy = 0.28
	env_node.environment = env
	world.add_child(env_node)

	# A GROUND PLANE and a CONTACT SHADOW, ported from
	# `_capture_creature_roster.gd` rather than reinvented. The creature survey
	# was told by its own blind critic that "everything floats on the pale ground
	# like a sticker", root-caused to Godot defaulting
	# `DirectionalLight3D.shadow_enabled` to FALSE on a bare stage while the
	# shipped world sets it true from `art.json`, and fixed there. This tool does
	# exactly the same job and never received the fix -- which is
	# `archive/ralph/VISUAL_LEDGER.md`'s own recurring lesson, stated in that file as "a
	# fix that lives in one tool does not protect the next tool that does the
	# same thing", recorded against six separate instances before this one.
	#
	# It is not cosmetic here. Without a ground line there is nothing fixing where
	# a character's feet ARE, and the sole lines in this survey's own output
	# genuinely disagreed -- a blind round measured the trainer's at y=745 and
	# every Team Tether body's at y=721, 24px apart under a camera the header
	# claims is identical. Every height read off these frames carried that error.
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	# Large enough that the plane's own edge never enters a frame -- at 80m the
	# far edge cut a visible diagonal across the portraits and read as a seam.
	plane.size = Vector2(400.0, 400.0)
	floor_mesh.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	# Mid grey, not the near-black backdrop: a blind round pointed out that a
	# near-black stage is the worst possible ground for judging the near-black
	# Team Tether costumes this survey exists to photograph.
	floor_mat.albedo_color = Color(0.34, 0.35, 0.37)
	floor_mesh.material_override = floor_mat
	world.add_child(floor_mesh)

	var key := DirectionalLight3D.new()
	# -52 deg, not -25. At 25 degrees of elevation a 1.8m figure throws a shadow
	# almost four metres long, which crossed most of the plate and read as a grey
	# streak rather than as contact. Steeper puts the shadow under the character,
	# where its whole job is to say "this body is standing on that ground".
	key.rotation = Vector3(deg_to_rad(-52.0), deg_to_rad(-18.0), 0.0)
	key.light_energy = 0.34
	key.shadow_enabled = true
	world.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation = Vector3(deg_to_rad(-20.0), deg_to_rad(170.0), 0.0)
	fill.light_energy = 0.19
	fill.light_color = Color(0.80, 0.85, 0.95)
	world.add_child(fill)


func _frame_portrait(camera: Camera3D, slot_x: float) -> void:
	camera.fov = FOV
	camera.global_position = Vector3(slot_x, CAM_HEIGHT, DIST)
	camera.look_at(Vector3(slot_x, LOOK_HEIGHT, 0.0), Vector3.UP)


## The line-up always sorts LAST in the contact sheet, whatever the cast size.
## Hardcoded as "11-lineup-all" while the cast was ten, which silently collided
## with `11-captain-field-*` the moment three more characters were added -- two
## different frames claiming one index, and nothing in the tool would have said so.
func _lineup_stem() -> String:
	return "%02d-lineup-all" % (CAST.size() + 1)


func _frame_lineup(camera: Camera3D) -> void:
	# LINEUP_SPACING, not SPACING: the ranks are closed up before this frame, so
	# centring on the portrait spread aims the camera at empty ground past the
	# end of the line and crops most of the cast out of its own group shot.
	var centre_x: float = (CAST.size() - 1) * 0.5 * LINEUP_SPACING
	camera.fov = LINEUP_FOV
	camera.global_position = Vector3(centre_x, LINEUP_CAM_HEIGHT, LINEUP_DIST)
	camera.look_at(Vector3(centre_x, LINEUP_LOOK_HEIGHT, 0.0), Vector3.UP)


## `height_m` is BURNED INTO THE FRAME, not just printed to stdout.
##
## A blind round had to derive every character's height by measuring silhouette
## pixels, because this survey's own scale evidence only ever reached the
## terminal -- and the critic reading the PNGs never sees the terminal. Criterion
## 8 of the visual-judge rubric is entirely about scale and tells a critic to
## measure against the 1.80 m trainer; handing it unlabelled frames makes that
## the critic's arithmetic problem rather than the survey's answer.
func _label(text: String) -> void:
	if _caption == null:
		var layer := CanvasLayer.new()
		root.add_child(layer)
		_caption = Label.new()
		_caption.position = Vector2(24, 20)
		_caption.add_theme_font_size_override("font_size", 22)
		_caption.add_theme_color_override("font_color", Color(1, 1, 1))
		_caption.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		_caption.add_theme_constant_override("outline_size", 6)
		layer.add_child(_caption)
	_caption.text = text


var _caption: Label = null


func _shoot(name: String, height_m: float) -> void:
	_label(name if height_m < 0.0 else "%s  -  %.2f m   (trainer = 1.80 m)" % [name, height_m])
	# One extra frame so the caption is actually composited before the shutter.
	await process_frame
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
