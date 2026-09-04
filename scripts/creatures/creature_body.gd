extends CharacterBody3D

## The physical body of a creature: how it looks, and how it moves.
##
## A CharacterBody3D rather than a Node3D because combat is piloted
## (docs/decisions/D07). Both fighters move under their own power over the same
## terrain the trainer walks on, so they need the same collision treatment. The
## earlier version faked motion by offsetting a mesh, which was fine for a fight
## in which nobody moved and is wrong now.
##
## Everything above this — the combat manager, the AI, the encounter director —
## talks to `request_move`, `add_impulse`, `face_towards` and `place_on_ground`,
## and never touches `velocity`. That is what lets the player's creature and the wild
## one share one movement implementation while being driven by a stick and by a
## state machine respectively.
##
## M11 replaces `_build_placeholder` with a rigged model. Nothing else here
## changes.

const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const ANIMATOR := preload("res://scripts/creatures/creature_animator.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const VISUAL := preload("res://scripts/creatures/creature_visual.gd")
const BUILT_FLOOR := preload("res://scripts/world/built_floor.gd")
const ALPHA_AURA := preload("res://scripts/creatures/alpha_aura.gd")
const ASPECT_VFX := preload("res://scripts/creatures/vfx/aspect_vfx.gd")

## CREATURE-IDENTITY-2 alpha presence. Warm gold rather than a warning red:
## an alpha is a bigger animal, not an attack telegraph, and combat already owns
## red (`combat/telegraph_glow.gd`). Tunable here rather than in config because
## these are one look, not a per-region balance number -- if the roster ever
## wants per-species alpha colours they belong in the species table, not in a
## global.
const ALPHA_RIM_STRENGTH := 0.65
## The field-separation rim's ceiling, for the reason `_apply_field_separation()`
## gives: an alpha's rim is its identity tell, so an ordinary creature's must
## stay clearly under it. Species opt in below this via `placeholder.field_rim`.
const FIELD_RIM_MAX := 0.30

## OWNER DIRECTIVE 2026-09-01 ("some of the smaller creatures blend into the
## environment too well... they either need to be bigger or brighter"), and
## `_apply_field_separation()`'s own conclusion for why a rim never reached
## bramblebun's target ratio: the fix needs to change how bright the creature
## itself reads, not add an edge highlight the render already showed is too
## weak to matter.
##
## That comment's premise -- "these models are self-lit, an albedo change
## would compile and still be invisible" -- turned out NOT to hold for
## `bramblebun_redesign`: inspected directly (a body spawned and its active
## surface material read back), the shipped material has
## `emission_enabled = false`. It is a plain lit PBR material, not the
## painted-albedo-into-emission convention the older production creature
## pipeline uses (and which the OF27/OF28 tint code above correctly still
## assumes for species that DO ship that way). So `_apply_field_brightness()`
## multiplies `albedo_color` unconditionally -- the lever this mesh's own
## material actually renders through -- and ALSO multiplies emission energy
## when a surface happens to have it enabled, so the same per-species knob
## keeps working correctly for a species whose material ships the other way.
## Pure multiply on purpose: it raises value without touching hue, so it
## cannot walk the creature's colour out of its painted family.
##
## `field_emission` is the per-species opt-in, exactly like `field_rim`. No
## ceiling anywhere near `FIELD_RIM_MAX`'s -- brightness past 1.0 is a
## deliberately available push (`SHINY_PLACEHOLDER_TINT` above already
## multiplies past 1.0 for the same "a near-1x multiply is not visible in a
## screenshot" reason), and the owner directive names this species' modest
## scale as already exhausted.
const FIELD_EMISSION_MAX := 3.0

## OWNER-0901-CREATURE-GRASS-VISIBILITY-V2. `field_emission` alone re-tested
## against the real, camera-relative grass field (`grass_field.gd`, off during
## the original 09-01 fix and back on since -- see this branch's own report)
## still reads as blended for bramblebun specifically, and not because it is
## too dim: `bramblebun_redesign`'s own reference art
## (`assets/creatures/tetherbound/bramblebun_redesign/reference/side.png`)
## paints real moss/lichen patches across its back and shoulders, measured off
## the shipped albedo texture at mean hue 39.6 -- but that whole-texture mean
## is dominated by the brown body fur; the moss patches themselves sample much
## closer to the meadow's own measured ground hue (68.3,
## `grass_field.json`'s `_comment_colour`) than the rest of the coat. A pure
## multiply (`_brighten_node`'s original `factor` on every channel alike)
## brightens those patches without ever moving them off that hue, so a
## brighter creature can still read as "more grass" over the exact area a
## human eye uses to separate silhouette from field. Terrapup and Mudsnout's
## reference sheets carry no such green -- solid dirt-brown and tan/grey
## respectively -- so `field_emission` alone remains correct for them; this is
## a second, independently opt-in lever for the one species whose own paint
## job works against a uniform brightness push.
##
## `field_degreen` (0.0 default, no-op) suppresses the green channel's share
## of the same brightness push rather than adding a new colour: at
## `strength=0.9, degreen=1.0` the red/blue channels still get the full 1.9x
## `_apply_field_brightness()` always applied, but green gets roughly half of
## that boost, which pulls a moss-hued pixel toward the coat's own warm brown
## instead of a brighter version of the same green -- and does nothing at all
## to pixels that are not green-dominant to begin with (the tan majority of
## the coat), so the rest of the creature's palette is untouched.
const FIELD_DEGREEN_MAX := 1.0
const ALPHA_RIM_TINT := 0.15
const ALPHA_AURA_COLOUR := Color("#ffd479")

## Audit B3 (2026-08-31): `tier` ("common"/"uncommon"/"rare", drawn by
## `spawn_tables.gd` from `data/config/spawn_tables.json`) reached exactly as
## far as picking which species to spawn and was then discarded -- no reader
## anywhere turned it into anything the player could see, so the exit
## criterion's "common/uncommon/rare/alpha differ in presentation, not just a
## stat block" failed for three of the four tiers. `alpha` already has its own
## full treatment (colourway + rim + aura); this gives the three tiers below
## it a rung on the same silhouette-edge rim `_apply_field_separation()`
## already uses for grass legibility, scaled well under `ALPHA_RIM_STRENGTH` so
## alpha stays the strongest tell. `common` is 0.0 on purpose -- it is the
## baseline every other tier reads as more-than, not a fourth look to author.
## An unrecognised or missing tier (every authored, non-rolled spawn today --
## `spawns.json` carries no `tier` field) resolves to `common`'s 0.0, so this
## is a no-op for the shipped seed-0 Meadows and only becomes visible once a
## world is actually rolled (`TB_WORLD_SEED`/`roll_new_worlds`), which is the
## only place tier-bearing data exists at all right now.
const TIER_RIM_STRENGTH := {
	"common": 0.0,
	"uncommon": 0.14,
	"rare": 0.26,
}

## OWNER-0901-CREATURE-GRASS-VISIBILITY-V2. A local-suppression lever
## (`grass_field.gd`'s existing `CLEAR_GROUP`/`CLEAR_RADIUS_META`, the same
## path a building's own floor uses to keep grass from growing through it)
## was tried here and reverted. It reaches `grass_field.json`'s own
## procedural `cover_tiers` bushes but NOT `vegetation.json`'s separate,
## statically-baked `bushes` scatter layer -- two different things both named
## "bushes" -- and the coordinator's own worst-case example (a creature
## standing inside a real bush) turned out to be the static one. Proven with
## a real before/after render: pixel-identical in the bush region either way.
## Left out rather than kept as a partial no-op, because it also carried a
## real cost this session could not justify once it stopped solving the
## problem: `grass_field.gdshader`'s per-vertex loop is only cheap because
## `built_count` is zero almost everywhere, and the Meadows' 200+ wild
## individuals would have kept it non-zero across most of any populated band.
## See this branch's own report for the reasoning and the fix that replaced
## it: spawn siting avoids baked scatter instead
## (`scripts/combat/encounter_director.gd`).

## The grounding ray starts this far above the requested spot and traces this far
## down.
##
## Generous on purpose. At 12m up, a spawn point on a hill started the ray
## *inside* the terrain — a downward ray from underground never exits, so the
## placement failed silently and the creature was never spawned at all. The
## playground's relief is about 72m, so the start has to clear the tallest thing
## that can be above a point the caller thought was ground level.
const GROUND_PROBE_UP := 120.0
const GROUND_PROBE_DOWN := 300.0

## How much wider than its collider a creature's art may be.
##
## Above 1 because a quadruped's body legitimately overhangs the capsule that
## represents it — a fox is longer than it is wide and the collider is a
## cylinder. Far above 1 and creatures visibly interpenetrate before their
## colliders touch, which reads as attacks landing at the wrong distance.
const FOOTPRINT_ALLOWANCE := 2.4

## OWNER-0901-CREATURE-BED-POSE. No shipped creature carries an authored
## lie-down clip -- `faint` is the only pose beyond idle/walk/run/attack/hit
## every species ships (BACKLOG-BED-SCALE-POSE inspected every .glb directly
## and confirmed this) -- and that clip alone reads as "standing/crouching on
## a bed" for every body plan except the one bird in the roster (galecrest),
## whose wing-collapse happens to fall sideways on its own. `play_rest()`
## below rolls the model onto its side around its own ground-contact line
## (the way a felled body actually tips over) so the rest of the roster reads
## as lying down too. How far a species should roll is a fact about its body
## plan, not a universal constant -- a tall, narrow creature (an antlered
## deer) oversteers past a bed's rim at the same angle a low, wide one settles
## at -- so it lives in species.json's `rest_roll_deg` per species, defaulting
## to this when a species has not been tuned yet.
const DEFAULT_REST_ROLL_DEG := 90.0

## OF27 placeholder tint: a deliberately garish magenta-shift multiply,
## applied to both albedo AND emission (see `_shared_variant_material`'s own
## comment for why emission has to be included). This is not the shiny
## LOOK — OF28 owns that, per-species, in real palette data — it exists only
## to prove the roll -> save -> tint pipeline actually changes what renders.
## Values above 1.0 on purpose: multiplying a mid-value albedo by ~1 leaves it
## nearly unchanged, and "nearly unchanged" is exactly the kind of tint that
## silently fails to prove anything in a screenshot.
const SHINY_PLACEHOLDER_TINT := Color(2.6, 0.12, 2.6)

var species_id: String = ""
var display_name: String = ""

## OF27: "make a version that is a 'shiny' like Pokemon go... nothing
## different than just the colors" (owner report). Set through `setup()`/
## `set_shiny()`, never rolled here — this node draws whatever it is told,
## the same way it never decides its own species.
var shiny: bool = false

## CREATURE-IDENTITY-2. Whether this body is its cluster's ALPHA.
##
## WILD-ECOLOGY (prompt 60) already spawns cluster leaders with a level bonus
## and a size multiplier, and `encounter_director._make_alpha` sets a meta flag
## so a test can find one -- but nothing about an alpha's PRESENTATION differed
## from its neighbours', so at the distance where a 1.3x size difference is
## ambiguous (which is most distances, with no ordinary member of the same
## species conveniently standing beside it) the player had no way to know a
## fight was going to be harder than the last one.
##
## Set through `set_alpha()`, never decided here -- same rule as `shiny`.
var alpha: bool = false

## Audit B3. The spawn-weight tier this individual was drawn at --
## "common"/"uncommon"/"rare", or "" for a body nobody has told (every
## authored spawn today; see `TIER_RIM_STRENGTH`'s own comment). Set through
## `set_tier()`, never decided here -- same rule as `shiny`/`alpha`. Distinct
## from `alpha`: a creature can be a rolled "rare" AND its cluster's alpha at
## once, and alpha's own presentation already wins that combination in
## `_apply_field_separation()`.
var tier: String = ""

## T1-CREATURE-ART. Non-empty for a body wearing an ASPECT VARIANT's recolor +
## glow + VFX treatment (Nightburrow, Stormtrail, Riftfrill, Ashtusk --
## docs/owner/TETHERBOUND_MEADOWS_CREATURE_EXPANSION.md), independent
## of `shiny`/`alpha`: an Aspect variant is its own species identity (own
## typing, own catch data, owned by T3-CREATURES' species.json entries), not a
## per-individual roll on an existing one, so it is never combined with the
## vivid/shiny/alpha suffix logic below -- it replaces it outright.
##
## Read from `placeholder.aspect_variant` in `_build_placeholder()` when a
## species entry declares one (dormant today: no species.json entry declares
## it yet, see this lane's own handover for the exact contract), or set
## directly through `set_aspect_variant()` for a caller that builds the
## presentation without a species table entry -- this project's own capture
## tooling does exactly that to prove the technique ahead of the data.
var aspect_variant: String = ""

## Which species' texture FOLDER an aspect variant's sibling colourway files
## live in -- e.g. Stormtrail (species id, eventually, "stormtrail") is built
## on Trailpup's own model and textures, so its `_stormtrail.png` siblings sit
## next to Trailpup's shipped files, not in a "stormtrail" folder that does
## not exist. Defaults to `species_id` when unset, which is correct for a
## caller that never sets it (the source and the wearer are the same species).
var _aspect_source_species: String = ""

## The aspect variant's own idle VFX (flame/arcs/motes/embers), rebuilt
## whenever the body is re-dressed -- same lifecycle as `_aura` below.
var _aspect_vfx: Node3D = null

var _height: float = 1.0
var _radius: float = 0.4
var _footprint_allowance: float = FOOTPRINT_ALLOWANCE

## Requested movement for this physics frame, cleared after it is consumed.
## Cleared rather than latched on purpose: a driver that stops driving stops the
## creature, so a state machine that forgets to say "stand still" cannot leave a
## creature sliding across the arena forever.
var _requested: Vector3 = Vector3.ZERO
var _requested_speed: float = 0.0

## Attack lunges and knockbacks, decaying. Separate from `velocity` so being hit
## mid-stride reads as a shove rather than as a cancelled input.
var _impulse: Vector3 = Vector3.ZERO

var _speed: float = 5.0
var _acceleration: float = 34.0
var _friction: float = 30.0
var _turn_speed: float = 13.0
var _gravity: float = 26.0
var _impulse_damping: float = 9.0

## Optional arena that holds this creature inside a boundary. Null outside
## combat, which is why the wild creature can wander freely before it is engaged.
var arena: Node = null

## The world node that answers `ground_height_at`. Found once, then cached.
var _ground_source: Node = null

## True when a real model loaded. False means the capsule fallback is showing,
## which is a visible, reported failure rather than a silent one.
var _has_model: bool = false

## Drives the model's clips. Null when a creature fell back to the capsule,
## which has nothing to animate.
var _animator: RefCounted = null

## CREATURE-LEGIBILITY-0903. The ground-contact shadow quad, built lazily on
## first `_apply_ground_contact_shadow()` call and reused (resized in place)
## on every rebuild -- see that function's own comment.
var _contact_shadow: MeshInstance3D = null

@onready var _collision: CollisionShape3D = $Collision
@onready var _model: Node3D = $Model
@onready var _body: MeshInstance3D = $Body
@onready var _head: MeshInstance3D = $Head


## The pivot the art hangs off. Procedural motion moves this, never the body:
## the body's position is gameplay and belongs to the combat manager.
func model_pivot() -> Node3D:
	return _model


func has_model() -> bool:
	return _has_model


## T1-AUDIO. Every creature body joins this so `scripts/audio/world_audio.gd`
## can find the ones near the player to give an idle call, without a per-creature
## audio node or a registry either side has to keep in step. Same shape as
## `world_look.gd`'s own `day_cycle` group: the thing that wants to be found
## announces itself, and the thing doing the finding asks the tree.
const AUDIO_GROUP := &"creature_voice"


func _ready() -> void:
	_load_config()
	add_to_group(AUDIO_GROUP)
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()
	if species_id != "" and _body != null:
		_build_placeholder()


## A hidden creature is switched off entirely — no physics, no collider.
##
## The player's creature exists in the world the whole time and is only hidden
## outside combat, so that deploying it is not a hitch in the one frame that
## most needs to be smooth. But an invisible CharacterBody3D standing inside the
## trainer is still a solid object, and two overlapping bodies resolve the
## overlap by shoving each other apart: the trainer was launched off the
## playground at 500 m/s, accelerating, on the first frame of every run.
func _on_visibility_changed() -> void:
	set_physics_process(visible)
	if _collision != null:
		# Deferred because visibility is usually flipped from inside a physics
		# callback, and changing a collider's state mid-step is not allowed.
		_collision.set_deferred("disabled", not visible)


func _load_config() -> void:
	var cfg: Dictionary = MATH.config().get("creature_movement", {})
	_speed = float(cfg.get("speed", _speed))
	_acceleration = float(cfg.get("acceleration", _acceleration))
	_friction = float(cfg.get("friction", _friction))
	_turn_speed = float(cfg.get("turn_speed", _turn_speed))
	_gravity = float(cfg.get("gravity", _gravity))
	_impulse_damping = float(cfg.get("impulse_damping", _impulse_damping))


## Configure from the species table. Safe to call before or after the node is in
## the tree; the mesh is built on whichever happens second.
##
## `is_shiny` defaults false so every existing caller that has not been
## taught about OF27 yet keeps building the ordinary, untinted body it always
## has. A wild spawn is the one caller that does not know its own shiny
## status yet at `setup()` time (the roll happens after `populate()` calls
## this) — see `set_shiny()` below for how that one re-tints after the fact.
func setup(id: String, is_shiny: bool = false) -> void:
	species_id = id
	shiny = is_shiny
	display_name = str(SPECIES.definition(id).get("display_name", id))
	if is_inside_tree() and _body != null:
		_build_placeholder()


## Change shiny status on a body that may already be built, and re-tint it —
## the wild-spawn path: `encounter_director._roll_wild_level` rolls the
## outcome from the seeded per-spawn stream AFTER `populate()` has already
## called `setup()` and built this body (the shiny draw has to be the
## stream's LAST draw, so every earlier draw stays byte-for-byte what it was
## before OF27 — see that function's own comment). A no-op if the status has
## not actually changed, so a caller that calls this defensively every frame
## cannot re-tint (and re-cache) a material it already tinted.
func set_shiny(value: bool) -> void:
	if shiny == value:
		return
	shiny = value
	_refresh_shiny_tint()


## CREATURE-IDENTITY-2. Mark this body as its cluster's alpha and re-dress it.
##
## Same shape and the same reasons as `set_shiny()` above: the director decides
## alpha status in `_make_alpha()` AFTER the body has been built and populated,
## so this has to work on an existing body, and it is a no-op when the status
## has not changed so a defensive caller cannot re-swap a material every frame.
func set_alpha(value: bool) -> void:
	if alpha == value:
		return
	alpha = value
	_refresh_shiny_tint()


## Audit B3. Give this body its rolled spawn-weight tier and re-dress it --
## same shape as `set_alpha()` above: the director/encounter table decides
## tier AFTER `populate()` has already built this body, this has to work on an
## existing body, and it is a no-op when the tier has not actually changed.
func set_tier(value: String) -> void:
	if tier == value:
		return
	tier = value
	_refresh_shiny_tint()


## T1-CREATURE-ART. Dress this body as an Aspect variant and re-dress it if
## already built -- same shape as `set_shiny()`/`set_alpha()` above, and a
## no-op when the variant has not actually changed for the same reason those
## two are: a defensive caller must not re-swap (and re-cache) a material
## every frame. `source_species` names whose texture folder the sibling
## colourway files live in; left empty it defaults to this body's own
## `species_id`, which is correct only when the wearer and the source are the
## same species (never true for the four named variants, always true for a
## test rig that wears its own species' colourway).
func set_aspect_variant(variant_id: String, source_species: String = "") -> void:
	if aspect_variant == variant_id:
		return
	aspect_variant = variant_id
	_aspect_source_species = source_species
	_refresh_shiny_tint()


## PW2 (BAND1-D1). An individual's gameplay size as a multiple of its
## species' own, for alpha/elder variants: 1.0 is an ordinary creature.
##
## It scales `_height` and `_radius` TOGETHER, before the capsule is built,
## which is the only correct place for it. PW2's own rule is "do not alter
## hitboxes merely because visual scale changes unless current creature
## collision already derives safely from scale" -- and the note below is why
## scaling the art instead would break exactly that: the collider, the hit
## cone's reach and the catch accuracy bonus all read `_height`/`_radius`, and
## `_fit()` then scales the model to match. Scale those two and the art, the
## reach and the catch odds all move together. Scale the node and only the
## picture changes, which is the invisible discrepancy PW2 forbids.
##
## Must be set BEFORE `populate()`; afterwards the capsule already exists.
var body_scale: float = 1.0


func _build_placeholder() -> void:
	var look: Dictionary = SPECIES.placeholder(species_id)
	# T1-CREATURE-ART contract (dormant until a species entry declares one --
	# see set_aspect_variant()'s own comment): a species whose placeholder
	# names `aspect_variant` wears that colourway/VFX instead of the ordinary
	# vivid/shiny/alpha ladder. Only read here, never overwritten, so a caller
	# that already set it programmatically (this lane's own capture tooling)
	# is not clobbered by a species table that has no such field yet.
	if aspect_variant == "":
		aspect_variant = str(look.get("aspect_variant", ""))
		if aspect_variant != "":
			_aspect_source_species = str(look.get("aspect_source_species", ""))
	var size_factor: float = maxf(body_scale, 0.01)
	_height = float(look.get("height", 1.0)) * size_factor
	_radius = float(look.get("radius", 0.4)) * size_factor
	# How long a body may be for its width, as a multiple of its collider
	# diameter. Per species because it is a fact about the animal: a triceratops
	# is genuinely several times longer than it is wide and a frog is not.
	_footprint_allowance = float(look.get("footprint_allowance", FOOTPRINT_ALLOWANCE))

	# The collider is built from the SPECIES, never from the art.
	#
	# Gameplay size is `height` and `radius`, and those drive the capsule, the
	# hit cone's reach, and the catch accuracy bonus through `body_radius()`.
	# Art is then scaled to fit that. The other way round — letting a model's
	# bounding box set the collider — means importing a new creature silently
	# retunes combat, and a fight that changes because an artist exported at a
	# different scale is not a fight anybody can tune.
	var shape := CapsuleShape3D.new()
	shape.radius = _radius
	shape.height = maxf(_height, _radius * 2.0 + 0.01)
	_collision.shape = shape
	_collision.position = Vector3(0.0, _height * 0.5, 0.0)

	if not _build_model(look):
		_build_capsule(look)
	_refresh_shiny_tint()
	_apply_ground_contact_shadow()
	_apply_night_floor()


## Load the species' model and fit it to the gameplay size. Returns false when
## there is nothing to load or it failed, so the caller can fall back.
func _build_model(look: Dictionary) -> bool:
	var path := str(look.get("model", ""))
	if path == "":
		return false
	if not ResourceLoader.exists(path):
		push_error("species '%s' names a model at %s that does not exist" % [species_id, path])
		return false
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		push_error("species '%s' model at %s did not load as a scene" % [species_id, path])
		return false

	for child in _model.get_children():
		child.free()
	var art: Node3D = packed.instantiate() as Node3D
	if art == null:
		push_error("species '%s' model root is not a Node3D" % species_id)
		return false
	_model.add_child(art)
	_fit(art, float(look.get("model_scale", 1.0)))

	# Sourced models point in whatever direction their author chose, and there
	# is no convention to rely on. Combat faces creatures along +Z (`facing()`),
	# so this is the per-species correction, verified by looking at a survey
	# frame rather than assumed.
	_model.rotation.y = deg_to_rad(float(look.get("model_yaw", 0.0)))

	_body.visible = false
	_head.visible = false
	_has_model = true
	_build_animator(art, look)
	return true


## Wire the model's AnimationPlayer to the role names the species declares.
##
## Clip names are per-pack and live in data: the shipped creatures use
## `Armature|Frog_Attack` and `Armature|Triceratops_Run`. Nothing in code knows
## those strings, so a new creature is a data edit.
func _build_animator(art: Node3D, look: Dictionary) -> void:
	var players: Array[Node] = art.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		push_warning("model for '%s' has no AnimationPlayer; it will not animate" % species_id)
		return
	_animator = ANIMATOR.new(players[0] as AnimationPlayer, look.get("animations", {}))


## Scale and centre an imported model so it stands on the node's origin at the
## species' gameplay height.
##
## Every model arrives differently: measured across the three shipped creatures,
## one was 263 units tall with its origin at its middle, one was 94 units with
## the same problem, and one was 3.8 units standing on its feet. Hand-tuning a
## scale and an offset per model is three magic numbers per species that nobody
## can check. Measuring the bounds and fitting is none.
func _fit(art: Node3D, extra_scale: float) -> void:
	var box := _bounds(art)
	if box.size.y <= 0.0001:
		push_warning("model for '%s' has no measurable height; leaving it unscaled" % species_id)
		return

	# Fit to the gameplay VOLUME, not just to the height.
	#
	# Scaling by height alone works for something upright and fails badly for
	# anything low and long: the shipped rabbit measures nearly as wide and deep
	# as it is tall, so matching its height gave a two-metre-wide rabbit sitting
	# next to a fox half its footprint. Taking the tighter of the two fits keeps
	# a creature inside the space its collider claims.
	#
	# But the clamp must never shrink a creature QUIETLY, and it used to.
	#
	# A long quadruped fitted to its height overruns a footprint allowance
	# written for compact creatures, so it was scaled back down — and rendered
	# visibly shorter than the height its own collider claims, while a stubby
	# creature beside it got its full declared size. That is the exact "art and
	# gameplay disagree" failure this function exists to prevent, and it hid
	# because `smoke_art` allowed 0.35m of slack. The owner spotted it before any
	# test did.
	#
	# So: the allowance is per species, because how long a body is for its width
	# is a fact about the animal; and when the clamp does bite, it says so.
	var footprint := maxf(box.size.x, box.size.z)
	var fit := _height / box.size.y
	if footprint > 0.0001:
		var allowed: float = (_radius * 2.0 * _footprint_allowance) / footprint
		if allowed < fit:
			push_warning(("'%s' is %.0f%% longer than its footprint allowance and " % [
				species_id, (fit / allowed - 1.0) * 100.0
			]) + ("has been scaled down to %.2fm instead of the %.2fm its collider claims. " % [
				_height * allowed / fit, _height
			]) + "Raise `footprint_allowance` or `radius` for this species.")
		fit = minf(fit, allowed)
	fit *= maxf(extra_scale, 0.01)
	art.scale = Vector3.ONE * fit
	# Feet to the origin, and centred on it horizontally.
	art.position = Vector3(
		-(box.position.x + box.size.x * 0.5) * fit,
		-box.position.y * fit,
		-(box.position.z + box.size.z * 0.5) * fit
	)


## Measure a model as it will actually render.
##
## Through `render_bounds.gd`, which is the shared answer to the two ways this
## measurement has been wrong: `global_transform` races add_child (a fitted
## Triceratops 528 metres tall), and a local node chain never sees a SKIN's
## scale (a 180-metre trainer that every AABB test swore was 1.80m). The
## creature models are authored with skin and armature both at 1.0, so for
## them this is the same number the old chain produced — the guard is against
## the next asset that is not.
func _bounds(node: Node3D) -> AABB:
	return RENDER_BOUNDS.measure(node)


## The original capsule, now only a fallback. A missing model renders as this
## and says so, rather than leaving an invisible creature the player can still
## be killed by.
func _build_capsule(look: Dictionary) -> void:
	var colour := Color(str(look.get("colour", "#cccccc")))
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.85

	var torso := CapsuleMesh.new()
	torso.radius = _radius
	torso.height = maxf(_height, _radius * 2.0 + 0.01)
	_body.mesh = torso
	_body.material_override = material
	_body.position = Vector3(0.0, _height * 0.5, 0.0)
	_body.visible = true

	# A smaller sphere forward and high, so the capsule has a front. Without it
	# there is no reading which way a creature is facing — and in a fight where
	# attacks are aimed, facing is the information the player needs most.
	var snout := SphereMesh.new()
	snout.radius = _radius * 0.55
	snout.height = _radius * 1.1
	_head.mesh = snout
	_head.material_override = material
	_head.position = Vector3(0.0, _height * 0.82, _radius * 0.9)
	_head.visible = true
	_has_model = false


## --- variant tinting (OF27) --------------------------------------------------
##
## Modelled directly on `scripts/characters/character_model.gd`'s
## `_apply_palette`/`_palette_node`/`_shared_variant_material` — same
## dict-of-material-name-to-colour contract, same recursive walk, same shared-
## material cache, same emission fix. Kept as a second implementation rather
## than a shared one because the two operate on different shapes (that file
## takes hex strings through `art.json`; this one takes `Color`s directly,
## since OF27 has no palette data file yet to hold hex strings in — see
## `_shiny_palette()`) and because creature_body.gd already has no dependency
## on scripts/characters/, which this would otherwise create.

## Re-applies (or applies for the first time) whatever tint `shiny` implies.
## Called after every model/capsule build, and from `set_shiny()` when shiny
## status changes on a body that already exists. Does nothing when not shiny
## — OF27 never needs to UN-tint a body, because nothing ever un-shinies a
## creature once rolled, so there is no "restore the original material" path
## to maintain.
func _refresh_shiny_tint() -> void:
	## T1-CREATURE-ART. An Aspect variant REPLACES the vivid/shiny/alpha
	## ladder outright rather than adding a fourth rung to it -- see
	## `aspect_variant`'s own comment for why. `alpha` can still be true at
	## the same time (Nightburrow and Stormtrail both are, per the owner
	## brief), so `_apply_alpha_presence()` still runs after the colourway
	## swap to layer the rim/aura on top; `shiny` never applies to a variant
	## that is already its own rare identity.
	if aspect_variant != "":
		var texture_species := _aspect_source_species if _aspect_source_species != "" else species_id
		if _has_model:
			_swap_colourway_textures(aspect_variant, texture_species)
		_apply_aspect_vfx()
		_apply_alpha_presence()
		return
	## OF28 (owner directive, quoted in docs/CURRENT_STATE.md): a colourway is a
	## REPAINT, never a tint — "if our newt is blue, I want red. not blue
	## with a red shade over it." tools/repaint_creature_textures.py writes
	## two sets of siblings from data/creatures/shiny_colourways.json:
	## `*_vivid.png` (the ORDINARY creature, repainted off the shipped
	## naturalistic mud toward the mystical palette — "more mystical like in
	## palworld") and `*_shiny.png` (the rare variant). Both swap albedo AND
	## emission, because the emission channel carries the same painted image
	## on these assets and swapping albedo alone would be invisible (the NP2
	## lesson, again).
	##
	## A shiny with no authored colourway falls back to OF27's placeholder
	## tint so it is never silently indistinguishable; an ordinary creature
	## with no vivid colourway simply keeps its shipped texture.
	##
	## CREATURE-IDENTITY-2 adds a third: `*_alpha.png`, the cluster leader.
	## Shiny wins over alpha when a creature is both -- a shiny is one in 128
	## and is the rarer thing to have to recognise -- and an alpha with no
	## authored alpha colourway falls back to the ordinary `vivid` one, so a
	## species can gain the variant later without any code change here.
	var suffix := "vivid"
	if shiny:
		suffix = "shiny"
	elif alpha:
		suffix = "alpha"
	if _has_model and _swap_colourway_textures(suffix):
		_apply_alpha_presence()
		return
	if _has_model and suffix == "alpha" and _swap_colourway_textures("vivid"):
		_apply_alpha_presence()
		return
	if shiny:
		_apply_variant_tint(_shiny_palette())
	_apply_alpha_presence()


## CREATURE-IDENTITY-2. The half of alpha presence that is not the texture:
## a rim light on the body and a slow ring of drifting motes around it.
##
## The colourway (`*_alpha.png`) carries the material difference the owner board
## asks for -- heavier stone plates on burrowback, storm-blue tips on galecrest
## -- but it only differs on the species that have one authored, and a texture
## difference alone is not visible against a sunlit meadow at fifty metres. The
## rim is: BaseMaterial3D's own rim term brightens exactly the silhouette edge,
## which is the part of an animal a player can still resolve at the distance
## where they choose whether to walk toward it.
##
## Rim rather than emission because these models are already self-lit (the
## painted albedo is wired into the emission slot, which is what
## creatures_visual.json's `emission_scale` exists to tame) -- raising emission
## on an alpha would brighten its whole body toward the pale wash that pass was
## fixing, and would not touch the outline at all.
##
## The materials this edits are the per-species swap materials cached in
## `_shiny_swap_materials`, so the edit is keyed by the `alpha` suffix and can
## never leak onto an ordinary creature of the same species: an alpha that fell
## back to the shared `vivid` material gets its own duplicate first.
func _apply_alpha_presence() -> void:
	_apply_field_brightness()
	if _aura != null:
		_aura.queue_free()
		_aura = null
	if not alpha or shiny:
		_apply_field_separation()
		return
	if _has_model:
		_rim_light_node(_model, ALPHA_RIM_STRENGTH, "alpha")
	_aura = ALPHA_AURA.attach(self, _radius * 1.5, _height, ALPHA_AURA_COLOUR)


## T1-CREATURE-ART. The Aspect variant's idle VFX -- purple flame
## (Nightburrow), electric arcs (Stormtrail), rift motes (Riftfrill) or ember
## smoke (Ashtusk), plus every variant's glowing-eyes billboard. Rebuilt
## whenever the body is re-dressed, same reason `_aura` is in
## `_apply_alpha_presence()`: a model rebuild (`apply_size_multiplier`) would
## otherwise leave the old effect parented to art that no longer exists.
##
## Per Nightburrow's own reference sheet, this is not decorative: "the purple
## flame effect is important. Without emissive/VFX treatment, this variant is
## not successful." The other three boards ask for the same thing in their
## own colour.
func _apply_aspect_vfx() -> void:
	if _aspect_vfx != null:
		_aspect_vfx.queue_free()
		_aspect_vfx = null
	if aspect_variant == "" or not _has_model:
		return
	_aspect_vfx = ASPECT_VFX.attach(self, aspect_variant, _radius, _height)


## OWNER DIRECTIVE 2026-08-28 §2b: "creatures need to stand out in the grass.
## some are now too small to see or they're the color of the grass."
##
## The other half of that directive from `_build_placeholder`'s `height`, and
## the half that scale cannot reach. Measured on a real render of a Bramblebun
## at throwing range in real grass
## (`ralph/reports/hud-catch/shots/01-before-aim.png`): where the creature is
## visible at all, hue separation is fine (47 degrees, tan against green) but
## LUMINANCE contrast is 1.15:1 -- and this repo's own `vegetation.json` quotes
## a blind critic calling 1.00:1 "invisible". Hue discrimination falls off with
## angular size far faster than value does, which is why 47 degrees of hue is
## not rescuing it at throwing range on a 7-inch panel.
##
## RIM rather than a brighter albedo, and that choice is not mine -- it is the
## one `_apply_alpha_presence()` above already made, for a reason that applies
## identically here and is recorded in its own header: these models are self-lit
## (the painted albedo is wired into the emission slot), so an albedo change
## "would compile, pass a material-only unit test, and still be invisible in a
## render". The rim term brightens exactly the silhouette EDGE, which is the
## part of an animal a player can still resolve when the body is behind grass.
## It also leaves the creature's own colours alone, which is the "prefer the
## levers that do not change silhouette" instruction: a rim does not restyle the
## animal, it outlines it.
##
## STRENGTH is deliberately well under the alpha's, and per-species opt-in
## rather than global. An alpha's rim is its identity tell; if every creature in
## the Meadows wore the same rim at the same strength the tell would be gone.
## At `FIELD_RIM_STRENGTH` an alpha still reads as more than twice the rim, and
## still carries the aura and the `_alpha` colourway that this does not.
##
## Opt-in per species via `placeholder.field_rim` so the lever is applied where
## a measurement says it is needed and nowhere else -- see this species' own
## note in `data/creatures/species.json` for its number.
##
## Audit B3 shares this same channel for rarity-tier legibility: both are "make
## a non-alpha body's silhouette edge read at a distance", and `_rim_light_node`
## sets one `rim`/`rim_tint` pair per material, so a second call under a
## different tag would silently overwrite this one rather than add to it (the
## same material comes back from `get_active_material` either way). Taking the
## max of the two sources keeps that a single write and means a creature that
## needs both (a rare Bramblebun, say) still reads as whichever need is
## stronger, never less legible than either alone.
func _apply_field_separation() -> void:
	if not _has_model:
		return
	var field_strength := clampf(
		float(SPECIES.placeholder(species_id).get("field_rim", 0.0)), 0.0, FIELD_RIM_MAX)
	var tier_strength := clampf(
		float(TIER_RIM_STRENGTH.get(tier, 0.0)), 0.0, FIELD_RIM_MAX)
	var strength := maxf(field_strength, tier_strength)
	if strength <= 0.0:
		return
	_rim_light_node(_model, strength, "field")


## OWNER DIRECTIVE 2026-09-01, "bigger or brighter". BACKLOG-B2-GRASS-SEPARATION
## measured that a rim alone cannot reach the target creature/grass luminance
## ratio for a species this small. See `FIELD_EMISSION_MAX`'s own comment for
## why this brightens `albedo_color` (unconditionally) and `emission` (only
## when the material actually has it enabled) rather than emission alone --
## `bramblebun_redesign`'s shipped material does not self-light the way the
## rest of this file assumes, so the rim's own "emission drowns out an albedo
## change" reasoning does not transfer, and the lever has to cover both cases
## to work for every species that opts in, not just this one.
##
## Applied on whatever material is currently active (so it stacks correctly
## after a colourway swap, or on the raw shipped material when no swap
## applies). Opt-in via `placeholder.field_emission`, exactly like
## `field_rim`: applied only where a measurement says it is needed, and left
## at 0.0 (a no-op) everywhere else.
func _apply_field_brightness() -> void:
	if not _has_model:
		return
	var strength := clampf(
		float(SPECIES.placeholder(species_id).get("field_emission", 0.0)), 0.0, FIELD_EMISSION_MAX)
	var degreen := clampf(
		float(SPECIES.placeholder(species_id).get("field_degreen", 0.0)), 0.0, FIELD_DEGREEN_MAX)
	if strength <= 0.0:
		return
	_brighten_node(_model, strength, degreen)


## NIGHT-LEGIBILITY (ROADMAP 2.7). `character_model.gd::set_emission_floor_scale`
## gives humans a small additive, time-of-day-scaled emission floor so a body
## lit by nothing but ambient/moon still reads at night; creatures never had
## the equivalent, because most of the roster ships from the older production
## pipeline SELF-LIT (painted albedo copied into the emission slot at a
## constant multiplier, `creatures_visual.json`'s `emission_scale`), and that
## constant glow alone already keeps them legible after dark -- measured with
## `tools/_capture_night_legibility.gd` this session, a self-lit species
## (mudsnout) renders with real form and good contrast at night, no fix needed.
##
## The species that do NOT ship that convention -- a plain lit PBR material,
## `emission_enabled == false` (Bramblebun's redesign mesh is one, and any
## future creature exported the same way) -- have nothing standing between
## them and the world's own deliberately-dim night ambient. The same capture
## measured one of them (sparkit) rendering completely invisible against the
## grass at night while the trainer two metres away read fine: a genuine
## silhouette-less gap, not a framing artefact.
##
## This gives exactly those materials the same mechanism humans have: a small
## additive floor, sourced from the creature's OWN current albedo texture
## (never a foreign colour, and read AFTER every colourway/field-brightness
## pass above so it floors whatever the creature currently looks like) that
## `world_look.gd` scales to zero in daylight and up at night. A creature that
## already reads fine (self-lit, or an ordinary daylight scene) is untouched;
## `emission_enabled` is the gate, so this only ever adds where nothing was
## already keeping the shape visible.
static var _night_floor_scale := 0.0
static var _night_floor_materials: Dictionary = {}


## Called by `world_look.gd` on each look change, exactly like
## `character_model.gd`'s own version -- rescales every material this body
## class already floored, in place, rather than waiting for the next spawn to
## pick up a new time of day.
static func set_emission_floor_scale(scale: float) -> void:
	var wanted := clampf(scale, 0.0, 1.0)
	if is_equal_approx(wanted, _night_floor_scale):
		return
	_night_floor_scale = wanted
	for material: BaseMaterial3D in _night_floor_materials.values():
		material.emission_energy_multiplier = wanted


func _apply_night_floor() -> void:
	if _has_model:
		_night_floor_node(_model)
		return
	for node in [_body, _head]:
		if node != null and node.material_override is BaseMaterial3D:
			node.material_override = _night_floor_material(node.material_override as BaseMaterial3D)


func _night_floor_node(node: Node) -> void:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		var mesh: Mesh = instance.mesh
		for surface in (mesh.get_surface_count() if mesh != null else 0):
			var source: Material = instance.get_active_material(surface)
			if not (source is BaseMaterial3D) or (source as BaseMaterial3D).emission_enabled:
				continue
			instance.set_surface_override_material(surface, _night_floor_material(source as BaseMaterial3D))
	for child in node.get_children():
		_night_floor_node(child)


## One floored material per (species, source material) pair, shared the same
## way every other cache in this file is -- keyed by `resource_name` so a
## `_field_bright`/`_alpha_rim`/plain-shipped material each floor separately
## and never leak across species or variants.
func _night_floor_material(source: BaseMaterial3D) -> BaseMaterial3D:
	var suffix := "_night_floor"
	if source.resource_name.ends_with(suffix):
		return source
	var key := "%s|%s" % [species_id, source.resource_name]
	if _night_floor_materials.has(key):
		return _night_floor_materials[key]
	var floored := source.duplicate() as BaseMaterial3D
	floored.resource_name = "%s%s" % [floored.resource_name, suffix]
	floored.emission_enabled = true
	floored.emission_operator = BaseMaterial3D.EMISSION_OP_ADD
	floored.emission_texture = floored.albedo_texture
	floored.emission = Color(1.0, 1.0, 1.0, 1.0)
	floored.emission_energy_multiplier = _night_floor_scale
	_night_floor_materials[key] = floored
	return floored


## G3-CREATURE-COLOUR-0904 (docs/CURRENT_STATE.md §3, reopening CREATURE-LEGIBILITY-
## 0903/Gate 2.4). Two separate defects were closing over the same code path.
##
## (1) NIGHT: `field_emission`/`field_degreen` were a plain multiply applied once
## at spawn/colourway-swap time with no clock awareness -- raising `field_emission`
## for a daytime grass-separation bar meant the identical push then ran unchanged
## after dark, reading as an out-of-place bright/pink self-lit glow (confirmed
## identical pixels with `world_look.gd`'s NIGHT-LEGIBILITY floor on and off -- not
## that floor's doing). Fixed the same way `_night_floor_material()` above fixes
## the mirror-image problem: one shared, rescalable material per (species, source
## material) pair, cached in `_field_bright_info` and rescaled in place by
## `set_field_brightness_scale()`, driven off the same clock `world_look.gd` already
## drives `set_emission_floor_scale()` from. `_field_scale` defaults to 1.0 (full
## daytime push, unchanged) so nothing here moves anything until `world_look.gd`
## actually calls the setter with a config value below 1.0.
##
## (2) DAYLIGHT: the GATE2-EVIDENCE-0903 blind judge independently called the same
## creature "candy pink" in broad daylight, on a species whose shipped coat texture
## (measured directly) is a plain warm tan (mean RGB 123/101/57) with nothing pink
## in it. Root cause: `field_degreen`'s green-channel suppression used to scale
## WITH `strength`, so CREATURE-LEGIBILITY-0903 raising `field_emission` 0.9 -> 2.5
## for a value/luminance bar unintentionally nearly tripled the R/B-vs-G gap a
## totally separate hue lever (OWNER-0901-CREATURE-GRASS-VISIBILITY-V2's fix for
## moss patches reading grass-hued) had been tuned to open -- a value push widening
## a hue lever it was never meant to touch. `FIELD_DEGREEN_GAP` fixes that gap's
## SIZE at what a real blind pass already approved at `field_emission`'s ORIGINAL
## 0.9 (0.9 * 0.5 * 0.75 = 0.3375, kept as a flat constant rather than a fraction of
## `strength`), so any future daytime value push stays hue-neutral instead of
## quietly re-opening the same defect at a new brightness.
static var _field_scale := 1.0
## One shared, rescalable material per (species, source material) pair -- same
## `species_id|resource_name` sharing discipline `_night_floor_materials` above
## uses, for the same reason: many instances of one species must not each own a
## private duplicate this static setter would otherwise have to hunt down.
static var _field_bright_info: Dictionary = {}
const FIELD_DEGREEN_GAP := 0.35


## Called by `world_look.gd` on each look change, exactly like
## `set_emission_floor_scale()` above -- rescales every material this body class
## already brightened, in place, rather than waiting for the next spawn/colourway
## swap to pick up a new time of day.
static func set_field_brightness_scale(scale: float) -> void:
	var wanted := clampf(scale, 0.0, 1.0)
	if is_equal_approx(wanted, _field_scale):
		return
	_field_scale = wanted
	for info: Dictionary in _field_bright_info.values():
		_apply_field_bright_values(info)


static func _apply_field_bright_values(info: Dictionary) -> void:
	var material: BaseMaterial3D = info["material"]
	var strength: float = float(info["strength"]) * _field_scale
	var degreen: float = float(info["degreen"])
	var factor := 1.0 + strength
	# Green gets the same push as red/blue minus a FIXED gap -- see this
	# section's own header comment for why the gap no longer scales with
	# `strength`/`_field_scale`. degreen=0 leaves this equal to `factor`,
	# unchanged from before this lever existed.
	var g_factor := maxf(factor - degreen * FIELD_DEGREEN_GAP, 0.0)
	var albedo: Color = info["orig_albedo"]
	var new_albedo := Color(
		albedo.r * factor, albedo.g * g_factor, albedo.b * factor, albedo.a)
	material.albedo_color = new_albedo
	if material.emission_enabled:
		material.emission_energy_multiplier = float(info["orig_emission_mult"]) * factor
	# `_night_floor_material()` above duplicates whichever material is active
	# at BUILD time and only ever revisits its OWN `emission_energy_multiplier`
	# afterwards (`set_emission_floor_scale()`'s loop) -- if this exact material
	# was in turn wrapped by that floor (the ordinary case: colourway -> field
	# brightness -> night floor, see `_apply_night_floor()`'s call order in
	# `_build_placeholder()`), the floored copy's `albedo_color` is a frozen
	# snapshot from whenever it was made and would otherwise go stale the first
	# time this scale changes after spawn -- a live creature's coat would stop
	# tracking the clock even though its own emission glow kept doing so
	# correctly. Same cache, same key shape as `_night_floor_material()` uses.
	var floored_key := "%s|%s" % [String(info.get("species_id", "")), material.resource_name]
	if _night_floor_materials.has(floored_key):
		(_night_floor_materials[floored_key] as BaseMaterial3D).albedo_color = new_albedo


func _field_bright_material(source: BaseMaterial3D, strength: float, degreen: float) -> BaseMaterial3D:
	# Keyed on strength/degreen as well as species/material, not just the first
	# two like `_night_floor_material()` above -- unlike that floor (one fixed
	# config value per time of day), `field_emission`/`field_degreen` are read
	# from the species table at spawn time, and `tools/_probe_grass_separation.gd`
	# depends on being able to mutate that table and re-spawn the SAME species
	# mid-process to sweep values. Keying on the value too means a sweep gets a
	# fresh cache entry per value tried, exactly like the un-cached original did,
	# while steady-state gameplay (one fixed value per species) still shares one
	# material across every live instance of that species.
	var key := "%s|%s|%.4f|%.4f" % [species_id, source.resource_name, strength, degreen]
	if _field_bright_info.has(key):
		return _field_bright_info[key]["material"] as BaseMaterial3D
	var material := source.duplicate() as BaseMaterial3D
	material.resource_name = "%s_field_bright" % material.resource_name
	var info := {
		"material": material,
		"orig_albedo": source.albedo_color,
		"orig_emission_mult": source.emission_energy_multiplier,
		"strength": strength,
		"degreen": degreen,
		"species_id": species_id,
	}
	_field_bright_info[key] = info
	_apply_field_bright_values(info)
	return material


func _brighten_node(node: Node, strength: float, degreen: float = 0.0) -> void:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		var mesh: Mesh = instance.mesh
		for surface in (mesh.get_surface_count() if mesh != null else 0):
			var source: Material = instance.get_active_material(surface)
			if not (source is BaseMaterial3D):
				continue
			var material := source as BaseMaterial3D
			if material.resource_name.ends_with("_field_bright"):
				continue
			instance.set_surface_override_material(
				surface, _field_bright_material(material, strength, degreen))
	for child in node.get_children():
		_brighten_node(child, strength, degreen)


## CREATURE-LEGIBILITY-0903 (Gate 2.4). The "sits ON the ground, not IN it"
## lever, separate from `_apply_field_brightness()`'s colour/value lever
## above. `tools/survey.sh`'s own header says this renderer has no SSAO, so
## nothing else in the scene pins a creature's feet down the way a real-time
## shadow would -- a small body standing in tall grass has no contact cue at
## all, which reads as floating/buried rather than standing.
##
## A flat, unshaded, soft-edged ellipse under the model's own origin (which
## `_fit()` already puts at the creature's feet). Applies to every creature
## with a loaded model, not per-species like the rim/emission/degreen levers
## above -- this is a fact about the renderer, not a fact about any one
## species' palette, so `creatures_visual.json::contact_shadow` has no
## per-species table. Built once and resized in place on every call rather
## than freed and rebuilt, so a `_visual_rest` entry captured mid-tween
## (`play_absorb`/`play_breakout`) never ends up pointing at a freed node.
func _apply_ground_contact_shadow() -> void:
	if not _has_model or not VISUAL.contact_shadow_enabled():
		if _contact_shadow != null:
			_contact_shadow.visible = false
		return
	if _contact_shadow == null:
		_contact_shadow = MeshInstance3D.new()
		_contact_shadow.name = "ContactShadow"
		_contact_shadow.mesh = QuadMesh.new()
		_contact_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_contact_shadow.material_override = _shared_contact_shadow_material()
		# Lays the quad flat on the XZ plane facing +Y; unshaded, so which way
		# the normal points changes nothing about how it renders.
		_contact_shadow.rotation.x = -PI * 0.5
		add_child(_contact_shadow)
	var diameter := _radius * 2.0 * VISUAL.contact_shadow_radius_scale()
	(_contact_shadow.mesh as QuadMesh).size = Vector2.ONE * diameter
	# A hair above the origin, not AT it -- coplanar with the ground plane a
	# creature's collider already sits flush against is exactly the geometry
	# that z-fights.
	_contact_shadow.position = Vector3(0.0, 0.02, 0.0)
	_contact_shadow.visible = true


## One shader material for every creature's shadow blob, same cache
## discipline as `_variant_materials`/`_shiny_swap_materials` below -- the
## colour/softness come from config, not per-instance state, so nothing here
## ever needs a second copy.
static var _contact_shadow_material: ShaderMaterial = null


func _shared_contact_shadow_material() -> ShaderMaterial:
	if _contact_shadow_material == null:
		var material := ShaderMaterial.new()
		material.shader = load("res://shaders/creature_contact_shadow.gdshader")
		material.set_shader_parameter(
			"shadow_colour", Color(0.0, 0.0, 0.0, VISUAL.contact_shadow_opacity()))
		material.set_shader_parameter("core_fraction", VISUAL.contact_shadow_core_fraction())
		material.set_shader_parameter("edge_power", VISUAL.contact_shadow_edge_power())
		_contact_shadow_material = material
	return _contact_shadow_material


func _rim_light_node(node: Node, strength: float, tag: String) -> void:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		var mesh: Mesh = instance.mesh
		for surface in (mesh.get_surface_count() if mesh != null else 0):
			var source: Material = instance.get_active_material(surface)
			if not (source is BaseMaterial3D):
				continue
			var material := source as BaseMaterial3D
			var suffix := "_%s_rim" % tag
			if not material.resource_name.ends_with(suffix):
				material = material.duplicate() as BaseMaterial3D
				material.resource_name = "%s%s" % [material.resource_name, suffix]
				instance.set_surface_override_material(surface, material)
			material.rim_enabled = true
			material.rim = strength
			material.rim_tint = ALPHA_RIM_TINT
	for child in node.get_children():
		_rim_light_node(child, strength, tag)


## Walks the model's surfaces looking for materials whose albedo texture has
## a `_<suffix>` sibling on disk; swaps albedo+emission to the repainted pair
## on a cached duplicate material. Returns true if at least one surface
## swapped — a shiny caller falls back to the placeholder tint otherwise.
##
## `texture_species` names whose texture folder the sibling files live in,
## for the T1-CREATURE-ART aspect-variant case where that is NOT this body's
## own `species_id` (Stormtrail's files sit beside Trailpup's). Empty
## defaults to `species_id`, which is every pre-existing vivid/shiny/alpha
## caller's behaviour, unchanged.
func _swap_colourway_textures(suffix: String, texture_species: String = "") -> bool:
	_colourway = suffix
	_colourway_species = texture_species if texture_species != "" else species_id
	return _swap_node_textures(_model)


## Which colourway `_swap_node_textures` is currently applying, and whose
## texture folder it reads siblings from. Plain fields rather than arguments
## threaded through the recursion, which would have to reach the two static
## helpers as well for no benefit.
var _colourway: String = "vivid"
var _colourway_species: String = ""

## The alpha's drifting motes, freed and rebuilt whenever the body is re-dressed
## (a model rebuild through `apply_size_multiplier` is the live case -- without
## this the old aura would be left parented to the replaced art).
var _aura: Node3D = null


func _swap_node_textures(node: Node) -> bool:
	var swapped := false
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		var mesh: Mesh = instance.mesh
		var surfaces := mesh.get_surface_count() if mesh != null else 0
		for surface in surfaces:
			# Clear any override this node already applied BEFORE reading the
			# material back.
			#
			# CREATURE-IDENTITY-2 found this the hard way. `get_active_material`
			# returns the override when one is set, so the second swap on the
			# same body was reading the FIRST swap's output: an alpha
			# burrowback, which is dressed `vivid` at build time and re-dressed
			# `alpha` when the director marks it, asked for the alpha sibling of
			# `..._base_color_vivid.png` -- a file that does not and should not
			# exist -- found nothing, and silently stayed vivid. Clearing first
			# makes every swap derive from the model's own shipped material, so
			# colourways never chain.
			instance.set_surface_override_material(surface, null)
			var source: Material = instance.get_active_material(surface)
			if not (source is BaseMaterial3D):
				continue
			var texture_species := _colourway_species if _colourway_species != "" else species_id
			var replacement := _swapped_material(source as BaseMaterial3D, texture_species, _colourway)
			if replacement != null:
				instance.set_surface_override_material(surface, replacement)
				swapped = true
	for child in node.get_children():
		if _swap_node_textures(child):
			swapped = true
	return swapped


## One swapped Material per source material, shared by every body of the same
## species — same cache discipline as `_shared_variant_material` below.
static var _shiny_swap_materials: Dictionary = {}


## T1-VARIANTS 2026-08-30 (JUDGE-3 5b: Stormtrail's markings "too small to
## read... at 30% this is simply a grey wolf", the same rendered-too-faint
## complaint would apply to any of the four at gameplay distance). Unlike the
## ordinary vivid/shiny/alpha colourways above -- which wire a full-body
## COPY of the albedo into the emission slot, and `emission_scale` exists
## specifically to tame that so a creature does not wash out pale in
## daylight -- an Aspect variant's emission texture is a mostly-BLACK
## synthesised glow map (tools/generate_aspect_variant_textures.py): a sparse
## network of cracks/veins over an otherwise-dark canvas, not a second copy
## of the whole animal. Taming it by the same shared 0.5 multiplier crushes
## the one thing that is supposed to read as supernatural glow. Rendered and
## measured directly (ralph/reports/T1-VARIANTS/shots/*-close.png,
## *-night-close.png): at the shared scale alone, Stormtrail's veins were
## essentially invisible at night with nothing but the VFX eye/mote
## billboards showing. This multiplies ON TOP of `VISUAL.emission_scale()`,
## only for an aspect-variant suffix -- every ordinary colourway is
## byte-for-byte unaffected.
const ASPECT_EMISSION_BOOST := {
	"nightburrow": 1.7,
	"stormtrail": 2.2,
	"riftfrill": 1.6,
	"ashtusk": 1.7,
}


static func _swapped_material(source: BaseMaterial3D, species: String, suffix: String) -> BaseMaterial3D:
	var shiny_albedo := _texture_for(source.albedo_texture, species, suffix, "base_color")
	if shiny_albedo == null:
		return null
	var key := "%d:%s" % [source.get_instance_id(), suffix]
	if _shiny_swap_materials.has(key):
		return _shiny_swap_materials[key]
	var copy := source.duplicate() as BaseMaterial3D
	copy.resource_name = "%s_%s" % [source.resource_name, suffix]
	copy.albedo_texture = shiny_albedo
	if copy.emission_enabled:
		var shiny_emission := _texture_for(source.emission_texture, species, suffix, "emissive")
		copy.emission_texture = shiny_emission if shiny_emission != null else shiny_albedo
		# CREATURE-PRESENTATION: these materials wire the painted albedo into
		# the emission slot at full energy, so a creature in daylight renders as
		# its own texture plus a second unshaded copy of itself -- which is what
		# turns a saturated mid-brown map into a pale peach animal and flattens
		# the value contrast a face needs. Tunable in creatures_visual.json.
		copy.emission_energy_multiplier *= VISUAL.emission_scale()
		copy.emission_energy_multiplier *= float(ASPECT_EMISSION_BOOST.get(suffix, 1.0))
	_shiny_swap_materials[key] = copy
	return copy


## `<texture path minus .png>_<suffix>.png`, or null when no repaint exists —
## the naming contract tools/repaint_creature_textures.py writes. A texture
## embedded inside a .glb has no usable resource_path; those species'
## repaints live at the tool's extracted-texture path instead, keyed by
## species id (the tool extracts the glb's images before repainting them).
##
## `kind` ("base_color" or "emissive") names which of the two extracted
## siblings the FALLBACK branch below should look for.
##
## T1-CREATURE-ART bugfix: this fallback branch used to hardcode
## "base_color" regardless of which texture (`tex`) it was actually asked
## about, so an "extracted"-convention species' EMISSIVE swap always
## resolved to its base_color sibling and could never find a genuinely
## different emissive file even if one existed on disk. That was silently
## harmless for every species that shipped no colourway-specific emissive
## (every one of them, until this lane wrote
## `trailpup_extracted_emissive_stormtrail.png`) because the caller already
## falls back to the base_color texture when this returns null -- same
## rendered result either way. It stopped being harmless the moment a real
## `..._extracted_emissive_<suffix>.png` file existed to be found.
static func _texture_for(tex: Texture2D, species: String, suffix: String, kind: String = "base_color") -> Texture2D:
	if tex == null:
		return null
	var path := tex.resource_path
	var candidate := ""
	if path != "" and path.ends_with(".png"):
		candidate = "%s_%s.png" % [path.get_basename(), suffix]
	else:
		candidate = "res://assets/creatures/tetherbound/%s/models/%s_extracted_%s_%s.png" % [
			species, species, kind, suffix]
	if not ResourceLoader.exists(candidate):
		return null
	return load(candidate) as Texture2D


## OF27's placeholder answer to "what colour is a shiny": one magenta-shift
## wildcard, applied to every surface with no more specific entry. OF28 owns
## the real answer — per-species base AND shiny palettes read from data
## (spec: OF27 is "nothing different than just the colors" made to WORK;
## OF28 is choosing what the colors actually are) — and is expected to
## replace this function's body with a data read, not to touch
## `_apply_variant_tint` itself.
func _shiny_palette() -> Dictionary:
	return {"*": SHINY_PLACEHOLDER_TINT}


## The tint hook. `colours` maps a mesh surface's material `resource_name`
## (or `"*"` as the wildcard every other name falls back to) to a `Color`
## multiplier, applied to both the real model (when one loaded) and the
## capsule fallback (when it did not) — a creature whose model failed to load
## should not also silently lose its shiny tint, the one thing a player
## catching it would actually notice.
func _apply_variant_tint(colours: Dictionary) -> void:
	if colours.is_empty():
		return
	if _has_model:
		_tint_node(_model, colours)
	else:
		_tint_capsule(colours)


func _tint_node(node: Node, colours: Dictionary) -> void:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		var mesh: Mesh = instance.mesh
		var surfaces := mesh.get_surface_count() if mesh != null else 0
		for surface in surfaces:
			var source: Material = instance.get_active_material(surface)
			var name := source.resource_name if source != null and source.resource_name != "" \
				else "surface_%d" % surface
			var colour: Variant = colours.get(name, colours.get("*"))
			if colour == null:
				continue
			instance.set_surface_override_material(
				surface, _shared_variant_material(source, name, colour as Color))
	for child in node.get_children():
		_tint_node(child, colours)


## The capsule fallback sets `material_override` directly (`_build_capsule`
## above), which takes rendering priority over any per-surface override —
## `_tint_node`'s `set_surface_override_material` calls would compile, cache
## a material, and change nothing on screen. Handled as its own small path
## instead of folding into `_tint_node` so that mismatch cannot silently
## reappear the way character_model.gd's own NP2 history warns an
## albedo-only tint can.
func _tint_capsule(colours: Dictionary) -> void:
	var colour: Variant = colours.get("*")
	if colour == null:
		return
	for node in [_body, _head]:
		if node == null or node.material_override == null:
			continue
		node.material_override = _shared_variant_material(
			node.material_override, "capsule", colour as Color)


## One Material per (species, material-or-part name, colour) tuple, shared by
## every body of the same species asking for the same tint — the same "mints
## a material per variant" mistake `character_model.gd`'s own cache comment
## warns against, avoided the same way.
##
## Found doing `NP2` on the human rigs, and treated as true here on the same
## authority (OF27's own brief): these creature assets ship
## `emission_enabled = true` with the SAME painted texture set as both
## `albedo_texture` and `emission_texture`, at a full white `emission`
## multiplier — a self-lit "painted" look, not a shading bug. Emission is
## additive and reads independently of lighting, so it swamps any
## `albedo_color` change completely; an albedo-only tint here would compile,
## pass a material-only unit test, and still be invisible in a render.
## `smoke_art.gd`'s own shiny check asserts the emission channel specifically
## for exactly this reason. Tinting `emission` the same way `albedo_color`
## already is closes the gap either way.
static var _variant_materials: Dictionary = {}


func _shared_variant_material(source: Material, name: String, colour: Color) -> Material:
	var key := "%s|%s|%s" % [species_id, name, colour.to_html()]
	if _variant_materials.has(key):
		return _variant_materials[key]
	var material: BaseMaterial3D = (source.duplicate() as BaseMaterial3D) \
		if source is BaseMaterial3D else StandardMaterial3D.new()
	material.albedo_color = material.albedo_color * colour
	if material.emission_enabled:
		material.emission = material.emission * colour
	_variant_materials[key] = material
	return material


func body_height() -> float:
	return _height


## What counts as a clean hit on this creature. Read by the orb for collision and
## by the catch formula for accuracy, so a bigger creature is genuinely easier to
## hit and that shows up in the odds rather than only in the physics.
## Grow this body, gameplay size and all.
##
## WILD-ECOLOGY alphas need to read as bigger AND fight as bigger, and those are
## the same fact here: `_height` and `_radius` drive the capsule, the collider,
## the hit cone's reach and -- through `body_radius()` -- the catch accuracy
## bonus. `_build_placeholder`'s own comment says so: "Gameplay size is `height`
## and `radius`... Art is then scaled to fit that."
##
## So this multiplies the gameplay size and rebuilds from it, rather than
## setting `scale` on the node. Scaling the node was the first attempt and it is
## wrong in a way that is invisible until someone throws an orb: the art would
## be 35% bigger while `body_radius()` returned the unscaled value and `centre()`
## sat low on the model, so throws that visually struck the creature would
## resolve as edge hits or misses. That is `reticle_outside_body`, which this
## project has already spent a debugging session on once.
##
## Call after `populate()`; it re-runs the sizing path over the new numbers.
func apply_size_multiplier(multiplier: float) -> void:
	if multiplier <= 0.0 or is_equal_approx(multiplier, 1.0):
		return
	_height *= multiplier
	_radius *= multiplier
	var shape := CapsuleShape3D.new()
	shape.radius = _radius
	shape.height = maxf(_height, _radius * 2.0 + 0.01)
	_collision.shape = shape
	_collision.position = Vector3(0.0, _height * 0.5, 0.0)
	var look: Dictionary = SPECIES.placeholder(species_id)
	if not _build_model(look):
		_build_capsule(look)
	_refresh_shiny_tint()
	_apply_ground_contact_shadow()
	_apply_night_floor()
	# BACKLOG-VISUAL-ALPHA-GROUNDING. The caller already stood this body on the
	# ground via `place_on_ground()` BEFORE calling here (`encounter_director.
	# _make_alpha()` resizes an already-placed wild), and that call's
	# `_seat_over_footprint()` sampled the ground under the ORDINARY `_radius`.
	# An alpha's footprint just grew, so re-seating with the now-larger radius
	# is the only way its rearmost feet see the same ground a smaller body
	# would have been placed on -- on any slope, the wider stance the bigger
	# `_radius` implies reaches further outward than the sample this body was
	# originally planted on, which is exactly "lit ground under every claw,
	# the rearmost toe in mid-air" reads like on a rise. Skipped with no
	# ground source (a capture-tool stage with its own flat floor and no
	# `ground_height_at` node) since `place_on_ground` already returns false
	# harmlessly there.
	if is_inside_tree():
		place_on_ground(global_position)


func body_radius() -> float:
	return _radius


## Where an attack aimed at this creature should be measured to: the middle of
## the body rather than the point between its feet.
func centre() -> Vector3:
	return global_position + Vector3.UP * (_height * 0.5)


## Facing, on the horizontal plane. This is what an attack is aimed along.
func facing() -> Vector3:
	var forward := global_transform.basis.z
	forward.y = 0.0
	return Vector3.FORWARD if forward.length() < 0.01 else forward.normalized()


## --- driving --------------------------------------------------------------

## Ask to move in a world-space direction this frame. Must be called every frame
## the creature should be moving; see `_requested`.
## The species' own config speed, for a caller that wants to scale it (a
## tonic) without re-reading the config or reaching into `_speed`.
func base_speed() -> float:
	return _speed


func request_move(direction: Vector3, speed: float = -1.0) -> void:
	_requested = Vector3(direction.x, 0.0, direction.z)
	if _requested.length() > 1.0:
		_requested = _requested.normalized()
	_requested_speed = _speed if speed < 0.0 else speed
	# Real movement beats a stale one-shot pose. See `creature_animator.gd`'s
	# `cancel_hold` for why: a creature already being driven again must not
	# stay frozen on an attack/hit pose for the rest of that clip's length.
	if _requested.length() > 0.01 and _animator != null:
		_animator.call("cancel_hold")


func add_impulse(direction: Vector3, strength: float) -> void:
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length() < 0.01:
		return
	_impulse += flat.normalized() * strength


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		# Small downward bias, the same trick the trainer uses, so the creature
		# stays pinned to slopes instead of skipping off every crest.
		velocity.y = -2.0

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	if _requested.length() < 0.01:
		horizontal = horizontal.move_toward(Vector3.ZERO, _friction * delta)
	else:
		horizontal = horizontal.move_toward(_requested * _requested_speed, _acceleration * delta)
		_turn_towards(_requested, delta)

	_impulse = _impulse.move_toward(Vector3.ZERO, _impulse_damping * _impulse.length() * delta)

	velocity.x = horizontal.x + _impulse.x
	velocity.z = horizontal.z + _impulse.z
	move_and_slide()

	if arena != null:
		arena.call("hold_inside", self)

	if _animator != null:
		var moving := Vector3(velocity.x, 0.0, velocity.z).length()
		_animator.call("tick", delta, moving, _speed)

	_requested = Vector3.ZERO


func _turn_towards(direction: Vector3, delta: float) -> void:
	var target_yaw := atan2(direction.x, direction.z)
	rotation.y = rotate_toward(rotation.y, target_yaw, _turn_speed * delta)


## --- animation, poked by combat ---------------------------------------------
##
## Speed tells the body how to move; it cannot tell it that a blow just landed.
## These are the three moments combat has to announce.

func play_attack() -> void:
	if _animator != null:
		_animator.call("play_once", "attack")


func play_hit() -> void:
	if _animator != null:
		_animator.call("play_once", "hit")


func play_faint() -> void:
	if _animator != null:
		_animator.call("play_faint")


## A rolled body's own rigid rotation dips one side below its own origin by
## roughly `_radius` (a quadruped's width, halved either side of centre) --
## verified against terrapup's measured box (tools/_diag_rest_roll_math.gd:
## -0.834m against a declared radius of 0.76m, the small gap being the art's
## normal overhang past its collider). `_radius` grounds that dip from KNOWN,
## pose-independent data, the same way `_height` (below) sizes the sideways
## re-centre -- neither reads a measured pose. On top of that, a small extra
## sink settles the body into the bedding rather than balancing exactly on
## its surface, per the owner's own suggestion; kept modest on purpose after
## the first attempt (0.35 of full standing HEIGHT) buried terrapup almost
## entirely, when radius-grounding alone already looked right for it.
const REST_SINK_METERS := 0.12

## The bed-rest pose: idle (not faint) rolled onto its side so it reads as
## lying rather than crouching, then sunk partway into the bedding. See
## `DEFAULT_REST_ROLL_DEG` above for why the angle is per-species data, not
## a constant. Only ever called on the cosmetic body `creature_bed.gd`
## spawns to represent a resting occupant -- never on the piloted creature
## -- so tipping the model over here cannot affect combat, which reads
## `_height`/`_radius`/the collider and never this node's rotation.
##
## Idle, not faint: `faint` is a death-flop, and on a winged species it
## flings the wings out wide rather than settling, which reads as "shot out
## of the sky" once rolled rather than "asleep". Idle is closer to a
## species' own resting silhouette on every rig this project ships.
##
## `rest_roll_deg: 0` opts a species out of all of this, back to the
## original `play_faint()`-only behaviour. galecrest's own data carries it:
## galecrest is the one species whose `faint` clip already falls sideways
## into a genuine lying pose on its own (a wing-collapse, not anything this
## roll produces), so ticking it into idle and not rolling would trade an
## already-correct pose for a standing one.
func play_rest() -> void:
	var roll := float(SPECIES.placeholder(species_id).get("rest_roll_deg", DEFAULT_REST_ROLL_DEG))
	if roll == 0.0:
		play_faint()
		return
	if _animator != null:
		_animator.call("tick", 0.0, 0.0, 1.0)
	if not _has_model:
		return
	var roll_rad := deg_to_rad(roll)
	_model.rotate_z(roll_rad)
	# Re-centre sideways by half of what used to be standing height (that is
	# where the roll sends it: see the corner derivation in
	# tools/_diag_rest_roll_math.gd); ground the rotation's own dip by
	# `_radius`; sink an extra `rest_sink_extra` (species data, defaulting to
	# REST_SINK_METERS -- a hovering flier's idle can sit well clear of its
	# own rest pose, which the radius term above cannot see, so an outlier
	# gets a bigger number here rather than the whole roster paying for it).
	var sink := float(SPECIES.placeholder(species_id).get("rest_sink_extra", REST_SINK_METERS))
	_model.position = Vector3(_height * 0.5 * sin(roll_rad), _radius * sin(roll_rad) - sink, 0.0)


func revive_animation() -> void:
	if _animator != null:
		_animator.call("revive")


## --- catching, the creature's half ------------------------------------------
##
## Being caught happens TO the body, so the body owns the two animations: being
## drawn into the orb, and bursting back out of it. Both animate the VISUAL
## children only (`Model`, and the capsule fallback's `Body`/`Head`) — the
## gameplay node, its collider and its transform stay untouched, because a
## scaled CharacterBody3D is a physics problem and the fight still owns this
## node's position. Physics-clock tweens, for the same reason impact_flash.gd
## runs on the physics clock: presentation that only advances on render frames
## is invisible to the survey harness and unreviewable.

var _catch_tween: Tween = null
var _visual_rest: Dictionary = {}


func _visual_children() -> Array[Node3D]:
	var visuals: Array[Node3D] = []
	for node in [_model, _body, _head, _contact_shadow]:
		if node != null and node.visible:
			visuals.append(node)
	return visuals


## Drawn into the orb: shrink toward the strike point, then hide. Replaces the
## old presentation, which was `visible = false` on the strike frame — the
## creature POPPED out of existence, and the one moment the whole mechanic
## builds to had no body. Ends by hiding the node (which also disables physics
## and the collider, via `_on_visibility_changed`) and restoring the visual
## children, so nothing downstream ever sees a shrunken creature.
func play_absorb(world_point: Vector3, seconds: float) -> void:
	# The creature is already spoken for; it must not wander, attack or slide
	# while it is being converted into light.
	set_physics_process(false)
	velocity = Vector3.ZERO

	_kill_catch_tween()
	_visual_rest.clear()
	var visuals := _visual_children()
	for node in visuals:
		_visual_rest[node] = node.transform

	var local_point := to_local(world_point)
	_catch_tween = create_tween().set_parallel(true)
	_catch_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	for node in visuals:
		_catch_tween.tween_property(node, "scale", Vector3.ONE * 0.02, seconds) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_catch_tween.tween_property(node, "position", local_point, seconds) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_catch_tween.chain().tween_callback(_finish_absorb)


func _finish_absorb() -> void:
	visible = false
	_restore_visuals()


## Burst back out of a failed catch: reappear small and pop up to full size
## with an overshoot, so the breakout reads as an event rather than a toggle.
func play_breakout(seconds: float) -> void:
	_kill_catch_tween()
	_visual_rest.clear()
	# Restore visibility FIRST (re-enables physics and the collider), then
	# animate the visuals up from nothing.
	visible = true
	_catch_tween = create_tween().set_parallel(true)
	_catch_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	for node in _visual_children():
		var rest_scale: Vector3 = node.scale
		_visual_rest[node] = node.transform
		node.scale = Vector3.ONE * 0.05
		_catch_tween.tween_property(node, "scale", rest_scale, seconds) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _restore_visuals() -> void:
	for node in _visual_rest:
		if is_instance_valid(node):
			(node as Node3D).transform = _visual_rest[node]
	_visual_rest.clear()


func _kill_catch_tween() -> void:
	if _catch_tween != null and _catch_tween.is_valid():
		_catch_tween.kill()
	_catch_tween = null


## Turn to face a world point, immediately. Used when a fight is arranged and by
## the peaceful idle; combat turning goes through `_turn_towards`.
func face_towards(point: Vector3) -> void:
	var to := point - global_position
	to.y = 0.0
	if to.length() < 0.01:
		return
	rotation.y = atan2(to.x, to.z)


## Move to an x/z position and sit on the ground under it.
##
## Asks the world for the ground height first, and only falls back to a ray.
##
## The ray used to be the whole implementation, and it was wrong. Downward rays
## against Terrain3D's heightmap collision miss roughly a quarter of the time at
## points where the ground is definitely present — a shape query at the same
## spot collides and the character walks over it happily, because `move_and_slide`
## uses shape casts and only rays lie. A wild creature placed by ray simply never
## spawned: no error, no body, no encounter.
##
## The fallback stays for anything the terrain does not know about — a rock, a
## structure, whatever M8 builds — where a ray is the only answer available.
func place_on_ground(target: Vector3) -> bool:
	if not is_inside_tree():
		return false

	var height := _ground_height(target.x, target.z)
	if is_nan(height):
		height = _ray_ground(target)
	if is_nan(height):
		# Leaving it where it is beats teleporting it into the sky, and the
		# caller is told so it can pick somewhere else.
		return false
	height = _seat_over_footprint(target, height)

	global_position = Vector3(target.x, height, target.z)
	velocity = Vector3.ZERO
	_impulse = Vector3.ZERO
	return true


## The highest ground under this body's own footprint, not just under its
## centre.
##
## T1-GROUND-3, routed from the 2026-08-30 blind pass: creatures on open ground
## 100m from any water photograph "sunk into the slope from the hindquarters
## back, cut off by the ground plane". That is not the water-spawn path and it
## is not a spawn-table defect -- it is this seat.
##
## `place_on_ground` sampled the ground at ONE point and put the root there. A
## creature stands level, so on a slope the uphill half of a body `_radius`
## wide is below ground by roughly `radius * tan(slope)` -- 0.4m of radius on a
## 25-degree hillside buries 19cm of it, which on a small creature is the
## hindquarters. This is exactly the defect T1-GROUND measured and fixed for
## `path_stones` (a rigid shape sampled at its centre and laid on a slope), one
## system over.
##
## Seating on the MAXIMUM under the footprint rather than the centre means the
## downhill side can float by the same amount instead of the uphill side
## burying. That is deliberate and it is not symmetric in how it reads: a small
## gap under one flank on a hillside is what a standing animal looks like, and
## a body sliced off by the ground plane is what a bug looks like. Any creature
## that then activates resolves the gap on its first `move_and_slide` anyway;
## nothing resolves being buried, which is why the frames show it.
##
## Four samples on the footprint's own axes, not a ring: this runs on every
## placement and every respawn, the terrain query is not free, and four points
## already capture the worst case on a plane, which is what a hillside locally
## is. Falls back to the centre height whenever the world cannot answer, so a
## scene with no ground source behaves exactly as it did before this existed.
func _seat_over_footprint(target: Vector3, centre_height: float) -> float:
	if _radius <= 0.0:
		return centre_height
	var highest := centre_height
	for offset: Vector2 in [
		Vector2(_radius, 0.0), Vector2(-_radius, 0.0),
		Vector2(0.0, _radius), Vector2(0.0, -_radius),
	]:
		var at := _ground_height(target.x + offset.x, target.z + offset.y)
		if not is_nan(at):
			highest = maxf(highest, at)
	return highest


## The world's own ground query, found by walking up the tree. Cached, because
## this runs every frame for a wandering creature.
##
## Discovered rather than injected so a creature can be dropped into any scene: a
## world that offers `ground_height_at` is used, and one that does not falls
## through to the ray without anybody having to wire anything.
## GATE-E: corrected upward by a BUILT floor when a building stands over the
## same spot. The terrain under the stronghold's five spaces is metres below
## the floor the player walks in on, and a creature placed by the terrain
## answer lands under the building -- see `scripts/world/built_floor.gd` for
## the measurement and what it cost the finale. Outside a building
## `BUILT_FLOOR.resolve` returns the terrain answer unchanged, so nothing in
## the open meadow moves.
func _ground_height(x: float, z: float) -> float:
	if _ground_source == null or not is_instance_valid(_ground_source):
		_ground_source = _find_ground_source()
	if _ground_source == null:
		return NAN
	return BUILT_FLOOR.resolve(self, x, z, float(_ground_source.call("ground_height_at", x, z)))


func _find_ground_source() -> Node:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("ground_height_at"):
			return node
		node = node.get_parent()
	return null


func _ray_ground(target: Vector3) -> float:
	var world := get_world_3d()
	if world == null:
		return NAN
	var space := world.direct_space_state
	if space == null:
		return NAN
	var from := Vector3(target.x, target.y + GROUND_PROBE_UP, target.z)
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * GROUND_PROBE_DOWN)
	query.collide_with_areas = false
	query.exclude = [get_rid()]
	var hit: Dictionary = space.intersect_ray(query)
	return NAN if hit.is_empty() else float((hit["position"] as Vector3).y)
