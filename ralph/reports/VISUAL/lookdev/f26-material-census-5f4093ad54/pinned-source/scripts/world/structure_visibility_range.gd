extends RefCounted

## PERF-ROG follow-up (WORLD lane, 2026-09-02). Godot's own per-instance
## `GeometryInstance3D.visibility_range_end` cull, applied to whole built
## structure/prop node groups so a shed the size of a few screen pixels stops
## costing a draw call just because the camera can technically see it.
##
## Measured at `band1_open` (tools/perf_render_stats.gd), the discrete
## prop/structure/character/water meshes cost 4058 of the stand's 7659 draw
## calls; the eight biggest named groups (Village, Props, Stronghold,
## BurrowWarrens, VillageBoundary, GrandpaHouse, SeveredSpokes,
## MillCrossing) are named and reasoned about in
## ralph/reports/... (WORLD lane visibility-range pass). This file is only
## the mechanism; every distance lives in data/config/performance.json.
##
## NEVER applied to vegetation -- CLAUDE.md's own hard rule -- and several of
## these "structure" groups plant real vegetation meshes as dressing anyway
## (village.gd's square_oak_a/b settlement trees at the square, and
## burrow_warrens.gd's skirt flora -- Bush_Common / Grass_Wide_Tall / Plant_1
## -- around the mound). `apply()` walks every descendant of the group's own
## root looking for GeometryInstance3D nodes, but skips a node's WHOLE
## subtree the moment its name contains one of `skip_name_contains`, so a
## tree standing inside a "structures" group is never touched, root to leaf.
##
## Gated the same way `scatter_lod_ranges` gates the vegetation LOD pass in
## this same config file: a top-level bool (`structure_visibility_ranges`,
## default false) PLUS a per-call distance that must itself be > 0. Either
## one being off is a complete no-op -- calling `apply()` before an owner
## turns this on changes nothing.

const PERF_CONFIG := preload("res://scripts/world/performance_config.gd")


## Call once per built group, right after that group's own root is standing
## in the tree (`village.call("build")` etc.) — `root` is the group's own
## Node3D (e.g. the `Village`/`Props`/`GrandpaHouse` node), `group_key` is
## its lookup name in `structure_visibility_range.groups`
## (data/config/performance.json). An unknown key just falls back to
## `structure_visibility_range.default`.
static func apply(root: Node, group_key: String) -> void:
	if root == null:
		return
	var cfg: Dictionary = PERF_CONFIG.config()
	if not bool(cfg.get("structure_visibility_ranges", false)):
		return
	var block: Variant = cfg.get("structure_visibility_range", {})
	if not block is Dictionary:
		return
	var settings := _resolve(block as Dictionary, group_key)
	var range_end := float(settings.get("visibility_range_end", 0.0))
	if range_end <= 0.0:
		return
	var margin := clampf(float(settings.get("visibility_range_end_margin", 0.0)), 0.0, range_end)
	var skip: Array = (block as Dictionary).get("skip_name_contains", [])
	_walk(root, range_end, margin, skip)


static func _resolve(block: Dictionary, group_key: String) -> Dictionary:
	var groups: Variant = block.get("groups", {})
	if groups is Dictionary and (groups as Dictionary).has(group_key):
		var per_group: Variant = (groups as Dictionary)[group_key]
		if per_group is Dictionary:
			return per_group as Dictionary
	var fallback: Variant = block.get("default", {})
	return fallback as Dictionary if fallback is Dictionary else {}


static func _walk(node: Node, range_end: float, margin: float, skip: Array) -> void:
	for child in node.get_children():
		if _is_skipped(child, skip):
			continue
		if child is GeometryInstance3D:
			var gi := child as GeometryInstance3D
			gi.visibility_range_end = range_end
			gi.visibility_range_end_margin = margin
			gi.visibility_range_fade_mode = (
				GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF if margin > 0.0
				else GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
			)
		_walk(child, range_end, margin, skip)


static func _is_skipped(node: Node, skip: Array) -> bool:
	var name := String(node.name)
	for token: Variant in skip:
		if name.findn(str(token)) != -1:
			return true
	return false
