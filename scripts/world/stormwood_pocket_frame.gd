extends RefCounted

## The one place a dead-end pocket's horizontal frame is computed. The runtime
## walls (stormwood_pockets.gd) and the forest bake (stormwood_scatter.gd, which
## lists this file as a bake source) both read it, so the bake's approach cone
## and the built mouth can never disagree.


## `forward` points out through the mouth (mouth_yaw_deg: 0 = +Z, 90 = +X).
static func frame(pocket: Dictionary) -> Dictionary:
	var yaw := deg_to_rad(float(pocket.mouth_yaw_deg))
	var forward := Vector2(sin(yaw), cos(yaw))
	return {"centre": Vector2(float(pocket.at[0]), float(pocket.at[1])), "forward": forward,
		"right": Vector2(forward.y, -forward.x)}


## The centre of the mouth's outer face, in world XZ.
static func mouth(pocket: Dictionary, cfg: Dictionary) -> Vector2:
	var f := frame(pocket)
	return (f.centre as Vector2) + (f.forward as Vector2) * (float(cfg.interior_half_m) + float(cfg.wall_thickness_m))
