extends Node
## Spike S1 RPC/spawn hub. Lives at a fixed path (/root/RpcHub) on every peer
## so @rpc calls can address it identically on host and client. All frame-
## budget / await orchestration lives in tools/net/_spike_enet.gd; this file
## only holds the pieces that must be network-addressable (RPCs) or must run
## identically on every peer (the spawn function).
##
## Reference only — a throwaway instrument for
## docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md Wave 0 lane 0.C, not the
## real net harness (tests/helpers/net_harness.gd, lane 0.F).

signal pong_received(seq: int)
signal client_ready(peer_id: int)

# --- ping / pong round trip -------------------------------------------------

@rpc("any_peer", "call_remote", "reliable")
func ping(seq: int) -> void:
	# Runs on the host when a client calls ping.rpc_id(1, seq).
	var sender := multiplayer.get_remote_sender_id()
	pong.rpc_id(sender, seq)


@rpc("any_peer", "call_remote", "reliable")
func pong(seq: int) -> void:
	# Runs on the client when the host replies.
	pong_received.emit(seq)


@rpc("any_peer", "call_remote", "reliable")
func announce_ready() -> void:
	# Client -> host: "my ping test is done, proceed to the spawn phase."
	client_ready.emit(multiplayer.get_remote_sender_id())


# --- spawn payload / spawn function -----------------------------------------
# Built identically on every peer (host and every client run this same code
# from the same script), which is what makes MultiplayerSpawner.spawn_function
# replicate correctly: the node it returns is structurally identical on every
# peer; the spawner (whose authority defaults to peer 1, the host) is what
# tells every *other* peer to invoke it too.

func make_spawn_payload(target_authority: int, seq: int) -> Dictionary:
	return {"authority": target_authority, "seq": seq}


func spawn_function(data) -> Node3D:
	var n := Node3D.new()
	n.name = "Spawned_%d" % int(data.get("seq", 0))

	var sync := MultiplayerSynchronizer.new()
	sync.name = "Sync"
	var cfg := SceneReplicationConfig.new()
	cfg.add_property(NodePath(".:position"))
	cfg.property_set_replication_mode(NodePath(".:position"), SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	sync.replication_config = cfg
	n.add_child(sync)

	# Authority is set here, before MultiplayerSpawner adds this node to the
	# tree under spawn_path — the pattern D-MP2/D-MP7 rely on ("host spawns
	# and sets authority before the node enters the tree"). recursive=true so
	# the Sync child picks it up too.
	n.set_multiplayer_authority(int(data.get("authority", 1)), true)
	return n
