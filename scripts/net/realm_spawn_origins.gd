extends RefCounted

## Host-created transition cohorts. Each deny names one existing receiver and
## one immutable originating token. No row means the prior admission policy.
var rows: Dictionary = {}
var live_bodies: Dictionary = {}
var pending_receivers: Dictionary = {}
var receiver_sequences: Dictionary = {}

func create(token: String, realm: String, owner: int, peers: Array) -> void:
	if rows.has(token):
		return
	var denied: Dictionary = {}
	var members: Dictionary = {}
	var versions: Dictionary = {}
	for peer: Dictionary in peers:
		var id := int(peer.peer_id)
		members[id] = token
		versions[id] = 0
		if id != 1 and id != owner and str(peer.get("realm", "")) != realm:
			denied[id] = token
	rows[token] = {"realm": realm, "owner": owner, "denied": denied,
		"members": members, "versions": versions}
	for receiver: int in pending_receivers:
		var pending: Dictionary = pending_receivers[receiver]
		_register_row(rows[token], receiver, str(pending.generation), int(pending.sequence))

func track(token: String, body: Node) -> void:
	if not rows.has(token):
		return
	var bodies: Dictionary = live_bodies.get(token, {})
	bodies[body.get_instance_id()] = weakref(body)
	live_bodies[token] = bodies

func allowed(token: String, receiver: int) -> bool:
	if receiver == 1 or not rows.has(token):
		return true
	var row: Dictionary = rows[token]
	return receiver == int(row.owner) or ((row.get("members", {}) as Dictionary).has(receiver) \
		and not row.denied.has(receiver))

func _register_row(row: Dictionary, receiver: int, generation: String, sequence: int) -> void:
	if sequence <= int((row.get("versions", {}) as Dictionary).get(receiver, -1)):
		return
	row.versions[receiver] = sequence
	row.members[receiver] = generation
	row.denied[receiver] = generation

func begin_receiver(receiver: int, generation: String, sequence: int) -> void:
	var latest := int(receiver_sequences.get(receiver, -1))
	for row: Dictionary in rows.values():
		latest = maxi(latest, int((row.get("versions", {}) as Dictionary).get(receiver, -1)))
	if sequence <= latest:
		return
	receiver_sequences[receiver] = sequence
	pending_receivers[receiver] = {"generation": generation, "sequence": sequence}
	for row: Dictionary in rows.values():
		_register_row(row, receiver, generation, sequence)

func complete_receiver(receiver: int, realm: String, generation: String) -> void:
	if not pending_receivers.has(receiver) or str(pending_receivers[receiver].generation) != generation:
		return
	for row: Dictionary in rows.values():
		if str(row.realm) == realm and str(row.members.get(receiver, "")) == generation \
				and str(row.denied.get(receiver, "")) == generation:
			row.denied.erase(receiver)
	pending_receivers.erase(receiver)

func capture(receiver: int, realm: String) -> Dictionary:
	var result: Dictionary = {}
	for token: String in rows:
		var row: Dictionary = rows[token]
		if str(row.realm) == realm and row.denied.has(receiver):
			result[token] = row.denied[receiver]
	return result

func admit_ready(receiver: int, realm: String, captured: Dictionary) -> void:
	for token: String in captured:
		if not rows.has(token):
			continue
		var row: Dictionary = rows[token]
		if str(row.realm) == realm and str(row.denied.get(receiver, "")) == str(captured[token]):
			row.denied.erase(receiver)

func disconnect_peer(receiver: int) -> void:
	pending_receivers.erase(receiver)
	for row: Dictionary in rows.values():
		row.denied.erase(receiver)
		row.members.erase(receiver)

func collect_dead() -> Array[String]:
	var removed: Array[String] = []
	for token: String in live_bodies.keys().duplicate():
		var bodies: Dictionary = live_bodies[token]
		for id: int in bodies.keys().duplicate():
			if (bodies[id] as WeakRef).get_ref() == null:
				bodies.erase(id)
		if bodies.is_empty():
			live_bodies.erase(token)
			rows.erase(token)
			removed.append(token)
	return removed

func reset() -> void:
	rows.clear()
	live_bodies.clear()
	pending_receivers.clear()
	receiver_sequences.clear()
