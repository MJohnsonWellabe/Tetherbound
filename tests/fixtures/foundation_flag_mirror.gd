extends RefCounted

## Explicit Session personal-flag mirror double for legacy reward fixtures.
## Records only published player flag ops addressed to the admitted character;
## it does not replace the production registry, writer, or player-op receiver.
var flags: Dictionary = {}

func record(delta: Dictionary, roster: RefCounted) -> void:
	for op: Variant in delta.get("ops", []):
		if not op is Dictionary or op.get("scope") != "player" or op.get("op") != "flag": continue
		for peer: int in op.get("peers", []):
			var row: Dictionary = roster.call("row", peer)
			var character: String = str(row.get("character_id", ""))
			if character.is_empty(): continue
			if not flags.has(character): flags[character] = {}
			flags[character][str(op.get("id", ""))] = op.get("value", true) == true
