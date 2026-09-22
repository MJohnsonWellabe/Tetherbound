extends RefCounted
class_name SnapshotTransfer

## Transport-independent bounded encoding and assembly for initial world
## snapshots. Session owns sequencing; this helper owns only bytes, integrity,
## and the rule that no partial or malformed payload becomes a Dictionary.

const VERSION := 1
const DEFAULT_CHUNK_BYTES := 192 * 1024
const DEFAULT_MAX_BYTES := 64 * 1024 * 1024
const SHA256_BYTES := 32

var _chunk_bytes: int
var _max_bytes: int
var _descriptor: Dictionary = {}
var _chunks: Array[PackedByteArray] = []
var _received: Array[bool] = []
var _received_count := 0
var _received_bytes := 0
var _ready_snapshot: Dictionary = {}
var _ready := false
var _failed := false
var _last_error := ""


func _init(chunk_bytes: int = DEFAULT_CHUNK_BYTES,
		max_bytes: int = DEFAULT_MAX_BYTES) -> void:
	_chunk_bytes = chunk_bytes
	_max_bytes = max_bytes


## Returns {ok, descriptor, chunks, error}. Failure is explicit and never
## returns a shortened payload.
func encode_snapshot(snapshot: Dictionary, transfer_id: int) -> Dictionary:
	var limits_error := _limits_error()
	if not limits_error.is_empty():
		return _encode_failure(limits_error)
	if transfer_id <= 0:
		return _encode_failure("Snapshot transfer id must be positive.")
	var bytes := var_to_bytes(snapshot)
	if bytes.is_empty():
		return _encode_failure("Snapshot could not be serialized.")
	if bytes.size() > _max_bytes:
		return _encode_failure("Snapshot is %d bytes; the safety limit is %d bytes." % [
			bytes.size(), _max_bytes,
		])
	var count := ceili(float(bytes.size()) / float(_chunk_bytes))
	var chunks: Array[PackedByteArray] = []
	chunks.resize(count)
	for index in count:
		var start := index * _chunk_bytes
		chunks[index] = bytes.slice(start, mini(start + _chunk_bytes, bytes.size()))
	return {
		"ok": true,
		"descriptor": {
			"version": VERSION,
			"transfer_id": transfer_id,
			"total_bytes": bytes.size(),
			"chunk_count": count,
			"sha256": _sha256(bytes),
		},
		"chunks": chunks,
		"error": "",
	}


## Starts one receive operation and releases any bytes from the previous one.
func begin(descriptor: Dictionary) -> bool:
	reset()
	var limits_error := _limits_error()
	if not limits_error.is_empty():
		return _fail_begin(limits_error)
	for field in ["version", "transfer_id", "total_bytes", "chunk_count"]:
		if not descriptor.has(field) or typeof(descriptor[field]) != TYPE_INT:
			return _fail_begin("Snapshot descriptor field '%s' must be an integer." % field)
	if int(descriptor["version"]) != VERSION:
		return _fail_begin("Snapshot transfer version is not supported.")
	if int(descriptor["transfer_id"]) <= 0:
		return _fail_begin("Snapshot transfer id must be positive.")
	var total_bytes := int(descriptor["total_bytes"])
	if total_bytes <= 0:
		return _fail_begin("Snapshot transfer byte count must be positive.")
	if total_bytes > _max_bytes:
		return _fail_begin("Snapshot is %d bytes; the safety limit is %d bytes." % [
			total_bytes, _max_bytes,
		])
	var expected_count := ceili(float(total_bytes) / float(_chunk_bytes))
	if int(descriptor["chunk_count"]) != expected_count:
		return _fail_begin("Snapshot descriptor chunk count does not match its byte count.")
	if not descriptor.has("sha256") or not descriptor["sha256"] is PackedByteArray:
		return _fail_begin("Snapshot descriptor SHA-256 digest is missing.")
	var digest: PackedByteArray = descriptor["sha256"]
	if digest.size() != SHA256_BYTES:
		return _fail_begin("Snapshot descriptor SHA-256 digest must be 32 bytes.")

	_descriptor = descriptor.duplicate(true)
	_chunks.resize(expected_count)
	_received.resize(expected_count)
	_received.fill(false)
	_last_error = ""
	return true


## Chunks may arrive in any order. Exact duplicates are harmless; a chunk that
## conflicts with accepted bytes is rejected and cannot replace them.
func accept_chunk(transfer_id: int, index: int, bytes: PackedByteArray) -> bool:
	if _descriptor.is_empty() or _failed:
		return _reject("No snapshot transfer is accepting chunks.")
	if transfer_id != int(_descriptor["transfer_id"]):
		return _reject("Snapshot chunk belongs to a different transfer.")
	if index < 0 or index >= _received.size():
		return _reject("Snapshot chunk index is outside the descriptor range.")
	var expected_size := _expected_chunk_size(index)
	if bytes.size() != expected_size:
		return _reject("Snapshot chunk %d is %d bytes; expected %d." % [
			index, bytes.size(), expected_size,
		])
	if _received[index]:
		if _chunks[index] != bytes:
			return _reject("Snapshot chunk %d conflicts with its accepted duplicate." % index)
		_last_error = ""
		return true

	_chunks[index] = bytes.duplicate()
	_received[index] = true
	_received_count += 1
	_received_bytes += expected_size
	_last_error = ""
	if _received_count == _received.size():
		_finish()
	return not _failed


func is_ready() -> bool:
	return _ready


## The only payload access point. It remains empty until byte count, digest,
## decoding, and Dictionary type have all been validated.
func snapshot() -> Dictionary:
	return _ready_snapshot.duplicate(true) if _ready else {}


func last_error() -> String:
	return _last_error


func received_bytes() -> int:
	return _received_bytes


func transfer_id() -> int:
	return int(_descriptor.get("transfer_id", 0))


func reset() -> void:
	_descriptor.clear()
	_chunks.clear()
	_received.clear()
	_received_count = 0
	_received_bytes = 0
	_ready_snapshot.clear()
	_ready = false
	_failed = false
	_last_error = ""


func _finish() -> void:
	if _received_bytes != int(_descriptor["total_bytes"]):
		_fail_transfer("Snapshot byte count does not match its descriptor.")
		return
	var buffer := PackedByteArray()
	for chunk: PackedByteArray in _chunks:
		buffer.append_array(chunk)
	var actual_digest := _sha256(buffer)
	if actual_digest != (_descriptor["sha256"] as PackedByteArray):
		_fail_transfer("Snapshot SHA-256 digest does not match its descriptor.")
		return
	# bytes_to_var() does not construct Objects; that requires the separate
	# bytes_to_var_with_objects() API, which this protocol never calls.
	var decoded: Variant = bytes_to_var(buffer)
	if not decoded is Dictionary:
		_fail_transfer("Snapshot payload did not decode to a Dictionary.")
		return
	_ready_snapshot = (decoded as Dictionary).duplicate(true)
	_ready = true
	_last_error = ""


func _expected_chunk_size(index: int) -> int:
	if index < _received.size() - 1:
		return _chunk_bytes
	return int(_descriptor["total_bytes"]) - index * _chunk_bytes


func _limits_error() -> String:
	if _chunk_bytes <= 0:
		return "Snapshot chunk size must be positive."
	if _chunk_bytes > DEFAULT_CHUNK_BYTES:
		return "Snapshot chunk size cannot exceed %d bytes." % DEFAULT_CHUNK_BYTES
	if _max_bytes <= 0:
		return "Snapshot safety limit must be positive."
	if _max_bytes > DEFAULT_MAX_BYTES:
		return "Snapshot safety limit cannot exceed %d bytes." % DEFAULT_MAX_BYTES
	if _chunk_bytes > _max_bytes:
		return "Snapshot chunk size cannot exceed the safety limit."
	return ""


func _fail_begin(message: String) -> bool:
	_failed = true
	_last_error = message
	return false


func _reject(message: String) -> bool:
	_last_error = message
	return false


func _fail_transfer(message: String) -> void:
	_failed = true
	_ready = false
	_ready_snapshot.clear()
	_last_error = message


func _encode_failure(message: String) -> Dictionary:
	return {"ok": false, "descriptor": {}, "chunks": [], "error": message}


func _sha256(bytes: PackedByteArray) -> PackedByteArray:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK:
		return PackedByteArray()
	if context.update(bytes) != OK:
		return PackedByteArray()
	return context.finish()
