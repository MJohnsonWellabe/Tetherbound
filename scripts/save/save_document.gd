extends RefCounted

## The gameplay schema remains inside a versioned JSON codec envelope. Godot's
## decimal JSON round-trip is not exact even with full_precision=true; journal
## before/after carriers must retain their original numeric values instead.
## Older readers reject the outer document (it has no gameplay version).
## Existing plain JSON saves still load without changing their saved values.
const FORMAT := "tetherbound-save"
const CODEC_VERSION := 1
const FLOAT := "$tb_float64"
const INTEGER := "$tb_int64"
const DICTIONARY := "$tb_dictionary"
const MAX_SAFE_INTEGER := 9007199254740991
const MAX_DEPTH := 128


static func stringify(data: Dictionary) -> String:
	var status := {"ok": true}
	var payload: Variant = _encode(data, status, 0)
	if not status.ok: return ""
	return JSON.stringify({"format": FORMAT, "codec_version": CODEC_VERSION, "payload": payload}, "\t")


## null means invalid, including an unknown codec. Callers must refuse it.
static func parse(text: String) -> Variant:
	var parser := JSON.new()
	if parser.parse(text) != OK or not parser.data is Dictionary: return null
	var outer: Dictionary = parser.data
	if outer.get("format") != FORMAT: return outer
	if outer.size() != 3 or not outer.has("payload") or typeof(outer.get("codec_version")) not in [TYPE_INT, TYPE_FLOAT] \
		or outer.codec_version != CODEC_VERSION: return null
	var status := {"ok": true}
	var result: Variant = _decode(outer.payload, status, 0)
	return result if status.ok and result is Dictionary else null


static func _invalid(status: Dictionary) -> Variant:
	status.ok = false
	return null


static func _encode(value: Variant, status: Dictionary, depth: int) -> Variant:
	if depth > MAX_DEPTH: return _invalid(status)
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_STRING:
			return value
		TYPE_INT:
			if value >= -MAX_SAFE_INTEGER and value <= MAX_SAFE_INTEGER: return value
			return {INTEGER: str(value)}
		TYPE_FLOAT:
			if not is_finite(value): return _invalid(status)
			var bytes := PackedByteArray()
			bytes.resize(8)
			bytes.encode_double(0, value)
			return {FLOAT: bytes.hex_encode()}
		TYPE_ARRAY:
			var out: Array = []
			for item: Variant in value: out.append(_encode(item, status, depth + 1))
			return out
		TYPE_DICTIONARY:
			var out := {}
			for key: Variant in value:
				# Godot property dictionaries can expose interned StringName
				# keys. Like existing JSON saves, preserve their textual key.
				if not key is String and not key is StringName: return _invalid(status)
				out[str(key)] = _encode(value[key], status, depth + 1)
			# Escape authentic dictionaries containing codec keys, so arbitrary
			# saved strings/dictionaries can never be mistaken for numeric tags.
			if value.has(FLOAT) or value.has(INTEGER) or value.has(DICTIONARY):
				var pairs: Array = []
				for key: String in out: pairs.append([key, out[key]])
				return {DICTIONARY: pairs}
			return out
	return _invalid(status)


static func _decode(value: Variant, status: Dictionary, depth: int) -> Variant:
	if depth > MAX_DEPTH: return _invalid(status)
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_STRING:
			return value
		TYPE_INT, TYPE_FLOAT:
			# All untagged codec numbers were exact small integers. Float
			# gameplay values always have a binary tag, including integral ones.
			if not is_finite(float(value)) or abs(float(value)) > MAX_SAFE_INTEGER or float(value) != floor(float(value)):
				return _invalid(status)
			return int(value)
		TYPE_ARRAY:
			var out: Array = []
			for item: Variant in value: out.append(_decode(item, status, depth + 1))
			return out
		TYPE_DICTIONARY:
			if value.has(FLOAT):
				if value.size() != 1 or not value[FLOAT] is String: return _invalid(status)
				var hex: String = value[FLOAT]
				if hex.length() != 16: return _invalid(status)
				for character: String in hex:
					if not character in "0123456789abcdef": return _invalid(status)
				var number := hex.hex_decode().decode_double(0)
				return number if is_finite(number) else _invalid(status)
			if value.has(INTEGER):
				if value.size() != 1 or not value[INTEGER] is String: return _invalid(status)
				var text: String = value[INTEGER]
				var number := text.to_int()
				if str(number) != text or (number >= -MAX_SAFE_INTEGER and number <= MAX_SAFE_INTEGER): return _invalid(status)
				return number
			if value.has(DICTIONARY):
				if value.size() != 1 or not value[DICTIONARY] is Array: return _invalid(status)
				var out := {}
				for pair: Variant in value[DICTIONARY]:
					if not pair is Array or pair.size() != 2 or not pair[0] is String or out.has(pair[0]): return _invalid(status)
					out[pair[0]] = _decode(pair[1], status, depth + 1)
				if not out.has(FLOAT) and not out.has(INTEGER) and not out.has(DICTIONARY): return _invalid(status)
				return out
			var out := {}
			for key: String in value: out[key] = _decode(value[key], status, depth + 1)
			return out
	return _invalid(status)
