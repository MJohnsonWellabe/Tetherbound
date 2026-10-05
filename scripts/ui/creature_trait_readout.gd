extends VBoxContainer

const TRAITS := preload("res://scripts/creatures/traits.gd")
var _labels: Array[Label] = []
var _fingerprint := ""

## Shared catch and inspect presentation. Caller supplies a HOST projection.
## Hidden bond secondary is never disclosed. Zero rolled traits is explicit.
func show_creature(creature: Variant) -> void:
	var rows := TRAITS.rows(creature)
	var fingerprint := JSON.stringify(rows)
	if fingerprint == _fingerprint: return
	_fingerprint = fingerprint
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_labels.clear()
	if rows.is_empty(): _add_line("No active traits")
	for row: Dictionary in rows:
		_add_line("%s · %s — %s" % [row.display_name,str(row.rarity).capitalize(),row.description])

## One-line catch readout: the caught creature's active traits by name and
## tier, or an explicit "No traits" for a lawful zero roll.
static func summary(creature: Variant) -> String:
	var names: Array[String] = []
	for row: Dictionary in TRAITS.rows(creature):
		names.append("%s (%s)" % [row.display_name, str(row.rarity).capitalize()])
	return ("Traits: " + ", ".join(names)) if not names.is_empty() else "No traits"

func _add_line(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",20)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(label)
	_labels.append(label)
