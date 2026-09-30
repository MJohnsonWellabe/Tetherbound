extends "res://tools/catalogue_survey.gd"

const BOOTSTRAP := preload("res://tools/lookdev_capture_bootstrap.gd")
var _graphics_capture: Dictionary = {}


func _run() -> void:
	_graphics_capture = BOOTSTRAP.prepare(self)
	if _graphics_capture.is_empty():
		quit(1)
		return
	# Stormwood's matrix must show its own Surge phases and always-purple
	# weather look; use capture_lookdev_stormwood.gd for that biome.
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--biome=stormwood":
			push_error("Use the Surge matrix for Stormwood look development")
			quit(2)
			return
	await super._run()


func _begin_manifest() -> void:
	super._begin_manifest()
	_manifest["graphics_capture"] = _graphics_capture
	_manifest["acceptance_scope"] = "Production-camera catalogue frame matrix with explicit staged poses and day/night clock. Visual evidence only; no earned campaign, frame-time route, Hall or owner Ally claim."
