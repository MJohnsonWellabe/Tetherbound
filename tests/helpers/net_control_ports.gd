extends RefCounted

## Reserve the actual TCP listeners, not guessed port numbers. Port zero asks
## the OS to select an available port while binding it atomically. Keep every
## listener alive until harness teardown; never close/rebind between selection
## and child startup. A nonzero base is an exact caller override, never retried.
static func reserve(peer_count: int, base_port: int = 0) -> Dictionary:
	var servers: Array[TCPServer] = []
	var ports: Array[int] = []
	if peer_count <= 0 or base_port < 0 or base_port + peer_count - 1 > 65535:
		return {"ok": false, "servers": servers, "ports": ports,
			"reason": "invalid control listener count/base"}
	for index in peer_count:
		var requested := 0 if base_port == 0 else base_port + index
		var server := TCPServer.new()
		var error := server.listen(requested, "127.0.0.1")
		if error != OK:
			release(servers)
			return {"ok": false, "servers": [], "ports": [],
				"reason": "could not listen on control port %d for peer %d (error %d)" % [requested, index, error]}
		servers.append(server)
		ports.append(server.get_local_port())
	return {"ok": true, "servers": servers, "ports": ports, "reason": ""}


static func release(servers: Array) -> void:
	for server: TCPServer in servers:
		server.stop()
