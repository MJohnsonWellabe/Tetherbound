extends Node

## Adapter to Foundation's existing typed registry, save/ACK and world mirror.
## Callables are injected by the shared owner. No RPC, journal or durable state.
signal settled(op: String, source_id: String, action_id: String, verdict: Dictionary)
var _submit: Callable
var _stock: Callable
var _plot: Callable

func configure(submit_action: Callable, read_stock: Callable, read_plot: Callable) -> void:
	_submit = submit_action
	_stock = read_stock
	_plot = read_plot

func submit(op: String, intent: Dictionary, consumer: Node) -> Dictionary:
	if not _enabled() or not _submit.is_valid():
		return {"ok": false, "code": "source_unavailable", "reason": "The resource system is not ready."}
	var result: Variant = _submit.call(op, intent.duplicate(true), consumer)
	return result if result is Dictionary else {"ok": false, "code": "invalid_source_verdict"}

func stock(realm: String, site_id: String) -> Dictionary:
	if not _enabled() or not _stock.is_valid(): return {}
	var result: Variant = _stock.call(realm, site_id)
	return result.duplicate(true) if result is Dictionary else {}

func plot(realm: String, plot_id: String) -> Dictionary:
	if not _enabled() or not _plot.is_valid(): return {}
	var result: Variant = _plot.call(realm, plot_id)
	return result.duplicate(true) if result is Dictionary else {}

## Shared owner calls only after the existing owner bool-save/ACK settlement.
## Notification reads that result; it cannot commit or manufacture an output.
func notify_settled(op: String, source_id: String, action_id: String, verdict: Dictionary) -> void:
	settled.emit(op, source_id, action_id, verdict.duplicate(true))

static var _enabled_cache := {}

## Read once per file change, not parsed from disk on every stock read: every
## renewable node reads stock, so the parse ran per node per poll (PERF).
static func _enabled() -> bool:
	var path := "res://data/config/f32_runtime.json"
	# Time and size: a same-second true <-> false edit changes the size, so it
	# is never served stale (Codex review of 33e131af).
	var stamp := "%d:%d" % [FileAccess.get_modified_time(path), FileAccess.get_size(path)]
	if not _enabled_cache.has("value") or _enabled_cache.get("stamp") != stamp:
		var cfg: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		_enabled_cache = {"stamp": stamp, "value": cfg is Dictionary and cfg.get("runtime_enabled") == true}
	return bool(_enabled_cache.value)
