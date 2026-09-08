extends RefCounted

## Main-thread mailbox; the worker receives only an immutable request and a
## callable bound to its own saver. No live Game/Node ever crosses this seam.
signal completed(success: bool)

var _thread: Thread
var _pending: Dictionary = {}
var _writer: Callable


func submit(request: Dictionary, writer: Callable) -> bool:
	if _thread != null:
		# Keep only the newest complete snapshot; never overlap transactions.
		_pending = request
		return true
	_writer = writer
	return _start(request)


func busy() -> bool:
	return _thread != null


func poll() -> void:
	if _thread != null and not _thread.is_alive():
		var success := _join()
		_start_pending()
		completed.emit(success)


## Required durability boundary for manual/rest/realm/quit saves. Joining is
## deliberately blocking here; ordinary fallback ticks only call poll().
func finish() -> bool:
	var success := true
	var results: Array[bool] = []
	while _thread != null:
		var result := _join()
		results.append(result)
		success = result and success
		if not _start_pending():
			success = false
	for result: bool in results:
		completed.emit(result)
	return success


func _start(request: Dictionary) -> bool:
	_thread = Thread.new()
	var error := _thread.start(_writer.bind(request), Thread.PRIORITY_LOW)
	if error != OK:
		_thread = null
		completed.emit(false)
		return false
	return true


func _join() -> bool:
	var success := bool(_thread.wait_to_finish())
	_thread = null
	return success


func _start_pending() -> bool:
	if _pending.is_empty():
		return true
	var request := _pending
	_pending = {}
	return _start(request)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# RefCounted is already at zero here; calling our own script methods
		# would dereference a null instance. Normal shutdown uses finish(). This
		# last-resort owner disposal still joins and commits its accepted tail.
		if _thread != null:
			_thread.wait_to_finish()
		if not _pending.is_empty() and _writer.is_valid():
			_writer.call(_pending)
