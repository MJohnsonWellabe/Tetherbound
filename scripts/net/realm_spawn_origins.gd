extends RefCounted

## Host-created transition cohorts. Each deny names one existing receiver and
## one immutable originating token. No row means the prior admission policy.
var rows: Dictionary = {}
var live_bodies: Dictionary = {}

func create(token: String, realm: String, owner: int, peers: Array) -> void:
	if rows.has(token):
		return
	var denied: Dictionary = {}
	for peer: Dictionary in peers:
		var id := int(peer.peer_id)
		if id != 1 and id != owner and str(peer.get("realm", "")) != realm:
			denied[id] = token
	rows[token] = {"realm": realm, "owner": owner, "denied": denied}

func track(token: String, body: Node) -> void:
	if not rows.has(token):
		return
	var bodies: Dictionary = live_bodies.get(token, {})
	bodies[body.get_instance_id()] = weakref(body)
	live_bodies[token] = bodies

func allowed(token: String, receiver: int) -> bool:
	return receiver == 1 or not rows.has(token) or not rows[token].denied.has(receiver)

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
	for row: Dictionary in rows.values():
		row.denied.erase(receiver)

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
