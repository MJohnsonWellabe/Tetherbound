extends SceneTree

## Read-only export proof. Use the pinned editor executable with --headless,
## --main-pack <actual release PCK>, --script <absolute path to this tool>,
## and -- --output=<fresh receipt path>. Exit 0 requires the production bake
## guard to accept the packed fingerprint and every referenced region file.
## Checking source alone cannot detect script export removing plaintext inputs.
const SCATTER := preload("res://scripts/world/stormwood_scatter.gd")
const BAKE := preload("res://scripts/world/scatter_bake.gd")
func _initialize() -> void:
	var output := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
	if output.is_empty() or FileAccess.file_exists(output):
		print("Scatter export proof requires a fresh --output receipt path.")
		quit(2)
		return
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/scatter/stormwood/manifest.json"))
	var sources: Array[Dictionary] = []
	for path: String in SCATTER.SOURCES:
		sources.append({"path": path, "exists": FileAccess.file_exists(path), "text_length": FileAccess.get_file_as_string(path).length()})
	var missing: Array[String] = []
	for pair: Array in manifest.get("regions", []):
		var path := "res://data/scatter/stormwood/region_%d_%d.bin" % [int(pair[0]), int(pair[1])]
		if not FileAccess.file_exists(path):
			missing.append(path)
	var fingerprint := SCATTER.fingerprint()
	var fresh := BAKE.is_fresh("stormwood", int(SCATTER.config().seed), fingerprint)
	var result := {"fingerprint": fingerprint, "manifest_fingerprint": manifest.get("config_fingerprint", 0),
		"fresh": fresh, "sources": sources, "manifest_regions": manifest.get("regions", []).size(), "missing_regions": missing}
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		quit(3)
		return
	var serialized := JSON.stringify(result, "\t") + "\n"
	file.store_string(serialized)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK or FileAccess.get_file_as_string(output) != serialized:
		print("Scatter export proof receipt could not be verified after close.")
		quit(3)
		return
	print("STORMWOOD PACK FRESHNESS: ", fresh, "; missing regions=", missing.size())
	quit(0 if fresh else 1)
