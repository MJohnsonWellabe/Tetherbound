extends RefCounted

## Main-thread mailbox; the worker receives only an immutable request and a
## callable bound to its own saver. No live Game/Node ever crosses this seam.
signal completed(success: bool)
## Companion observations. The submission identifies the frozen request even
## when pending; only an actually joined writer receives a completion.
signal submitted(job_id: String, request: Dictionary)
signal completed_request(job_id: String, request: Dictionary, success: bool, receipt: Dictionary)

var _thread: Thread
var _pending: Dictionary = {}
var _writer: Callable
var _active_job: Dictionary = {}
var _pending_job: Dictionary = {}
var _joined_completion: Dictionary = {}


func submit(request: Dictionary, writer: Callable, observed_writer: Callable = Callable(), receipt_reader: Callable = Callable()) -> bool:
	var job := {"id":Crypto.new().generate_random_bytes(16).hex_encode(),"request":request,
		"observed_writer":observed_writer,"receipt_reader":receipt_reader}
	if _thread != null:
		# Keep only the newest complete snapshot; never overlap transactions.
		_pending = request
		_pending_job=job
		submitted.emit(job.id,request)
		return true
	_writer = writer
	return _start(job,true)


func busy() -> bool:
	return _thread != null


func poll() -> void:
	if _thread != null and not _thread.is_alive():
		var success := _join()
		var original: Dictionary = _joined_completion
		_joined_completion={}
		_start_pending()
		completed.emit(success)
		completed_request.emit(original.id,original.request,original.success,original.receipt)


## Required durability boundary for manual/rest/realm/quit saves. Joining is
## deliberately blocking here; ordinary fallback ticks only call poll().
func finish() -> bool:
	var success := true
	var results: Array[bool] = []
	var observations: Array[Dictionary] = []
	while _thread != null:
		var result := _join()
		results.append(result)
		observations.append(_joined_completion)
		success = result and success
		if not _start_pending():
			success = false
	_joined_completion={}
	for index: int in results.size():
		completed.emit(results[index])
		var original: Dictionary = observations[index]
		completed_request.emit(original.id,original.request,original.success,original.receipt)
	return success


func _start(job: Dictionary, notify_submission: bool = false) -> bool:
	_active_job=job
	_thread = Thread.new()
	if notify_submission: submitted.emit(job.id,job.request)
	var writer: Callable = job.observed_writer if job.observed_writer.is_valid() else _writer
	var error := _thread.start(writer.bind(job.request), Thread.PRIORITY_LOW)
	if error != OK:
		_thread = null
		_active_job={}
		completed.emit(false)
		completed_request.emit(job.id,job.request,false,{})
		return false
	return true


func _join() -> bool:
	var returned: Variant = _thread.wait_to_finish()
	var success := bool(returned) # Preserve the existing BOOL callable boundary.
	var strict_success: bool = returned is bool and returned == true
	var receipt: Dictionary = {}
	if strict_success and _active_job.receipt_reader.is_valid():
		var observed: Variant = _active_job.receipt_reader.call()
		if observed is Dictionary and observed.get("request_sha256") == preload("res://scripts/save/save_document.gd").stringify(_active_job.request).sha256_text():
			receipt=observed
	_joined_completion={"id":_active_job.id,"request":_active_job.request,"success":strict_success,"receipt":receipt}
	_active_job={}
	_thread = null
	return success


func _start_pending() -> bool:
	if _pending.is_empty():
		return true
	var job: Dictionary = _pending_job
	_pending = {}
	_pending_job={}
	return _start(job)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# RefCounted is already at zero here; calling our own script methods
		# would dereference a null instance. Normal shutdown uses finish(). This
		# last-resort owner disposal still joins and commits its accepted tail.
		if _thread != null:
			_thread.wait_to_finish()
		if not _pending.is_empty() and _writer.is_valid():
			_writer.call(_pending)
