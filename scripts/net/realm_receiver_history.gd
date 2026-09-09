extends RefCounted

## A completed departure keeps its receiver closed until an explicitly readied
## replacement consumes that exact deny. Session reset/real disconnect retire
## identity; an unsuccessful re-entry cannot reopen a missing scene.
var epoch := 1
var denied: Dictionary = {}

func reset() -> void:
	epoch += 1
	denied.clear()

func disconnect_peer(peer: int) -> void:
	denied.erase(peer)

func token_for(peer: int, realm: String) -> String:
	return str((denied.get(peer, {}) as Dictionary).get(realm, ""))

func retire(peer: int, realm: String, token: String) -> void:
	var realms: Dictionary = denied.get(peer, {})
	realms[realm] = token
	denied[peer] = realms

func admit_ready(peer: int, realm: String, expected: String, captured_epoch: int) -> bool:
	if captured_epoch != epoch or token_for(peer, realm) != expected:
		return false
	var realms: Dictionary = denied.get(peer, {})
	realms.erase(realm)
	if realms.is_empty():
		denied.erase(peer)
	else:
		denied[peer] = realms
	return true
