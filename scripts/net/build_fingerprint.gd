extends RefCounted

## Build and content compatibility for co-op admission (MULTIPLAYER §1.1 step 5).
##
## Lobby membership is discovery, not admission. Before the host adds a
## registry row, prepares a realm or sends a snapshot, a joiner must match on
## three things. A mismatch in any of them could desynchronize the shared
## world without an obvious error.
##
##   * `wire_protocol`: the RPC surface and payload shapes. It is bumped by
##     hand whenever a session/ledger/encounter RPC changes. The Steam lobby
##     publishes the same marker (`steam_lobby.gd::PROTOCOL` reads it from
##     here), so there is one place to bump it.
##   * `engine`: the Godot major.minor.patch/status. Variant encoding and the
##     high-level multiplayer API are only promised stable within one engine
##     release.
##   * `content`: SHA-256 over every JSON file under `res://data`, in sorted
##     path order, each prefixed with its path and length. These files hold
##     the tunables, rewards, recipes, dialogue and encounter data that host
##     and client must agree on. Scripts are left out on purpose: exports
##     tokenize them (`script_export_mode=2`), so an editor build and an
##     exported build of the same commit would hash differently. Binary
##     terrain/scatter data is left out because it is authored geometry,
##     large, and changes only alongside JSON content or the wire protocol.
##
## This is compatibility, not authentication. A modified client can claim any
## fingerprint; the host still validates every transaction on its own state.

const WIRE_PROTOCOL := "tetherbound-invite-v5"
const CONTENT_ROOT := "res://data"
const CONTENT_EXTENSION := "json"
## Hex digits of the content hash shown to players. Long enough to tell builds
## apart at a glance, and short enough to read aloud to a friend.
const SHORT_HASH_CHARS := 8
## Longest claimed value echoed into a refusal reason or the host log. The
## claim is untrusted wire data; a real marker or engine string is far shorter.
const MAX_ECHO_CHARS := 48
## Development-only overrides so a multi-process smoke can stand up a
## deliberately mismatched peer from the same checkout: an environment
## variable, or a user argument after `--` for one harness peer. Release
## templates are not debug builds, so shipped games ignore both.
const TEST_CONTENT_OVERRIDE_ENV := "TB_NET_CONTENT_FINGERPRINT_OVERRIDE"
const TEST_CONTENT_OVERRIDE_ARG := "--net-content-fingerprint="

static var _cached_content := ""


## This process's fingerprint. The content hash is computed once per process.
static func current() -> Dictionary:
	return {
		"wire_protocol": WIRE_PROTOCOL,
		"engine": engine_version(),
		"content": content_hash(),
	}


static func engine_version() -> String:
	var info := Engine.get_version_info()
	return "%d.%d.%d.%s" % [int(info.get("major", 0)), int(info.get("minor", 0)),
		int(info.get("patch", 0)), str(info.get("status", ""))]


static func content_hash() -> String:
	if OS.is_debug_build():
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with(TEST_CONTENT_OVERRIDE_ARG):
				var claimed := arg.trim_prefix(TEST_CONTENT_OVERRIDE_ARG).strip_edges()
				if not claimed.is_empty():
					return claimed
		var override := OS.get_environment(TEST_CONTENT_OVERRIDE_ENV).strip_edges()
		if not override.is_empty():
			return override
	if _cached_content.is_empty():
		_cached_content = hash_content_under(CONTENT_ROOT)
	return _cached_content


## Deterministic SHA-256 over the JSON files below `root`. Public so a focused
## test can hash a temporary tree.
static func hash_content_under(root: String) -> String:
	var files: Array[String] = []
	_collect(root, files)
	files.sort()
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	for path in files:
		var bytes := FileAccess.get_file_as_bytes(path)
		var relative := path.trim_prefix(root)
		ctx.update(("%s\n%d\n" % [relative, bytes.size()]).to_utf8_buffer())
		ctx.update(bytes)
	return ctx.finish().hex_encode()


static func _collect(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.include_hidden = false
	for file_name in dir.get_files():
		if file_name.get_extension().to_lower() == CONTENT_EXTENSION:
			out.append(dir_path.path_join(file_name))
	for sub in dir.get_directories():
		_collect(dir_path.path_join(sub), out)


## Short display form, also the Steam lobby metadata value.
static func token(fingerprint: Dictionary) -> String:
	return "%s|%s|%s" % [str(fingerprint.get("wire_protocol", "")),
		str(fingerprint.get("engine", "")),
		str(fingerprint.get("content", "")).left(SHORT_HASH_CHARS)]


## Host-side verdict for a joiner's claimed fingerprint. `remote` is untrusted
## wire data, so any shape is accepted and anything malformed is refused.
## The reason says which part differs, so two friends know whether to update
## the game or check that they are on the same build.
static func compare(local: Dictionary, remote: Variant) -> Dictionary:
	if not remote is Dictionary:
		return _refuse("Your game is too old for this host. Update Tetherbound so both of you run the same version.")
	var theirs: Dictionary = remote
	for key: String in ["wire_protocol", "engine", "content"]:
		if not theirs.get(key) is String or str(theirs.get(key)).is_empty():
			return _refuse("Your game did not report its version. Update Tetherbound so both of you run the same version.")
	if theirs["wire_protocol"] != local.get("wire_protocol"):
		return _refuse("You and the host run different network versions of Tetherbound (host %s, yours %s). Both players need the same version."
			% [str(local.get("wire_protocol")), str(theirs["wire_protocol"]).left(MAX_ECHO_CHARS)])
	if theirs["engine"] != local.get("engine"):
		return _refuse("You and the host run different builds of Tetherbound (host engine %s, yours %s). Both players need the same version."
			% [str(local.get("engine")), str(theirs["engine"]).left(MAX_ECHO_CHARS)])
	if theirs["content"] != local.get("content"):
		return _refuse("You and the host have different game content (host %s, yours %s). Both players need the same version."
			% [str(local.get("content")).left(SHORT_HASH_CHARS),
				str(theirs["content"]).left(SHORT_HASH_CHARS)])
	return {"ok": true, "code": "", "reason": ""}


static func _refuse(reason: String) -> Dictionary:
	return {"ok": false, "code": "incompatible_version", "reason": reason}
