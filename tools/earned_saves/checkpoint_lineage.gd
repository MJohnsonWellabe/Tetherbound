extends RefCounted
const DOCUMENT := preload("res://scripts/save/save_document.gd")

static func from_directory(directory: String, current: Array = [], verified_prefix: bool = false) -> Dictionary:
	var previous: Variant = DOCUMENT.parse(FileAccess.get_file_as_string(directory.path_join("receipt.json"))) \
		if FileAccess.file_exists(directory.path_join("receipt.json")) else {}
	var provenance: Variant = JSON.parse_string(FileAccess.get_file_as_string(directory.path_join("PROVENANCE.json"))) \
		if FileAccess.file_exists(directory.path_join("PROVENANCE.json")) else {}
	return derive(previous if previous is Dictionary else {}, provenance if provenance is Dictionary else {}, current, verified_prefix)

## Evidence classification only. A local PASS or legacy "earned" label cannot
## establish fresh-save ancestry. Only the full prefix verifier supplies that.
static func derive(previous: Dictionary, provenance: Dictionary, current: Array = [], verified_prefix: bool = false) -> Dictionary:
	var inherited: Variant = previous.get("lineage", {})
	var origins: Array = []
	var status := "earned" if verified_prefix else "unproven"
	if inherited is Dictionary:
		if inherited.get("status") == "generated":
			status = "generated"
		elif inherited.get("version") == 1 and inherited.get("status") == "earned" \
				and inherited.get("continuous_fresh_save") == true and inherited.get("origins") == []:
			status = "earned"
		if inherited.get("origins") is Array:
			origins = inherited.origins.duplicate(true)
	var mode := str(previous.get("input_mode", ""))
	if mode.begins_with("generated"):
		origins.append("predecessor input_mode=" + mode)
	if previous.has("generated_origin"):
		origins.append("predecessor generated_origin=" + JSON.stringify(previous.generated_origin))
	# Old fixture metadata carries ancestry outside the piece receipt. Preserve
	# that conservative classification even where an old piece said "earned".
	if provenance.get("prior_earned_play") == false or JSON.stringify(provenance).to_lower().contains("generated"):
		origins.append("legacy PROVENANCE declares generated ancestry")
	if JSON.stringify(previous.get("disclosures", [])).to_lower().contains("generated"):
		origins.append("legacy receipt discloses generated input")
	origins.append_array(current)
	var unique: Array = []
	for origin: Variant in origins:
		if not unique.has(origin): unique.append(origin)
	if not unique.is_empty() or status == "generated": status = "generated"
	return {"version": 1, "status": status, "origins": unique,
		"continuous_fresh_save": status == "earned"}


static func input_mode(lineage: Dictionary) -> String:
	match lineage.get("status"):
		"earned": return "earned"
		"generated": return "generated_ancestry"
	return "unproven_ancestry"
