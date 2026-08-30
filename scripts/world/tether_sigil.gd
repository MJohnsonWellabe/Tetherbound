extends RefCounted

## TEAM TETHER'S MARK, AND THE CLOTH IT HANGS ON.
##
## T1-HALL-3 (2026-08-30). Two of JUDGE-5's findings are the same missing thing
## seen at two ranges:
##
##   D6 -- the Hall's banners are "pure-fill magenta-crimson rectangles, no
##         cloth shape, no sag, NO SIGIL ... the key art's banners carry the
##         compass sigil".
##   D4 -- the "sigil gate" "has neither sigil nor gate ... a three-rail farm
##         fence with a small yellow padlock. No sigil, no banner, no gatehouse,
##         no Team Tether mark of any kind. Nothing tells the player they have
##         crossed into hostile ground."
##
## The mark therefore lives in one place, shared by the Hall and the gate,
## rather than being drawn twice and drifting -- the same discipline
## `severed_spokes.gd` already enforces for the reserved oxblood and teal.
##
## Generated, not painted. The lane's constraints are explicit: no new Meshy
## generations, and Meshy is reserved for Team Tether HERO OBJECTS (pylons,
## relay apparatus, the tether machine) -- a device on a flag is not one. A
## ring with four cardinal arms and a longer north arm is what the key art's
## banners carry and is what survives being read at 150 m as "that flag has a
## device on it".

## The device is drawn WHITE on an opaque field so it can be used as an
## `albedo_texture` multiplied by whatever `albedo_color` the caller wants --
## one cached image serves the oxblood banners and the faded Meadows-blue
## relic banner alike, and neither needs its own copy.
const SIGIL_PX := 128

static var _texture: ImageTexture = null


## The shared sigil texture. Built once per process, on first ask.
static func texture() -> ImageTexture:
	if _texture != null:
		return _texture
	var img := Image.create(SIGIL_PX, SIGIL_PX, false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 1.0, 1.0, 1.0))
	var cx := float(SIGIL_PX) * 0.5
	# The device sits in the FIELD -- the upper three quarters of the cloth,
	# which is the part `_hang_banner`'s panel box shows -- so the banner's
	# tails do not cut through it.
	var cy := float(SIGIL_PX) * 0.42
	var ring_r := float(SIGIL_PX) * 0.26
	var ring_t := float(SIGIL_PX) * 0.045
	var arm_t := float(SIGIL_PX) * 0.038
	# Bleached linen rather than pure white: a device painted on cloth that has
	# hung outdoors, not a decal.
	var mark := Color(0.86, 0.82, 0.70)
	for y in SIGIL_PX:
		for x in SIGIL_PX:
			var dx := float(x) - cx
			var dy := float(y) - cy
			var d := sqrt(dx * dx + dy * dy)
			var on := absf(d - ring_r) <= ring_t
			# Four cardinal arms, with north (up, -y) running longer. The long
			# arm is what gives the device an ORIENTATION -- without it the mark
			# reads as a snowflake and carries no direction.
			var reach_v := ring_r * (1.62 if dy < 0.0 else 1.06)
			if absf(dx) <= arm_t and absf(dy) <= reach_v:
				on = true
			if absf(dy) <= arm_t and absf(dx) <= ring_r * 1.06:
				on = true
			if on:
				img.set_pixel(x, y, mark)
	_texture = ImageTexture.create_from_image(img)
	return _texture


## A banner material carrying the mark. `colour` multiplies the device with it,
## so the caller keeps ownership of the faction hue and this file never becomes
## a second place a reserved colour is decided.
static func cloth_material(colour: Color) -> StandardMaterial3D:
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = colour
	cloth.albedo_texture = texture()
	cloth.roughness = 0.95
	# Cloth is thin and is routinely seen from behind (the Hall's gate face is
	# the SHADED face -- HALL_DESIGN sec2 -- so its banners are backlit as often
	# as not). Without this the reverse of every banner is a black rectangle.
	cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
	return cloth
