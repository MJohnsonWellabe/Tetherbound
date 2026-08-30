extends Node

## A minimal stand-in for world_look.gd's public contract, for capture rigs
## that stage their own flat sun/sky (tools/_capture_structures.gd::_stage())
## rather than booting the full playground scene. Anything that reaches for
## the "day_cycle" group's `is_dark()` -- campfire_glow.gd's daylight energy
## scale is the first caller -- needs a node there to find, or it silently
## falls back to "no day cycle exists, behave as if always night" (see that
## file's own `_daylight_scale()` comment for why that specific fallback was
## chosen). These isolated rigs ARE always daytime by construction
## (`_stage()`'s fixed sun), so `is_dark()` always returns false here.
func is_dark() -> bool:
	return false
