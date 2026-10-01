# CI6169 Warden verdict deadline and separate coordinator save fault

The multiplayer shard's original relic-key smoke failed at the command's
95-second wall deadline, while both peers still produced combat heartbeats.
The fixture reached the actual host challenge and guest encounter join. It
never received the win command's verdict, so it stopped before the key, Heart,
placement, personal power, reload and rejoin assertions. No payout or durability
failure is established.

The exact CI source is `fd96f9031383cf51239de7d229dc4963c29e98b7`, merging
`aba5268a53` into `30fcc38`. All nine inspected source files match that CI
source. The fetched job log and original uploaded artifact are separately
hashed in `source-cut.json`. The ZIP's SHA matches the digest in the upload
log; its exact Warden folder is preserved under Foundation's ignored scratch,
including NET_RUN, peer logs, boot logs and both original saved profiles.

The guest join check prints at 12:45:39.2806682 UTC and the first missing-verdict
failure at 12:47:14.2842291 UTC, approximately 95.004 seconds apart. The next
command is the win command; its exact send timestamp was not recorded.
`net_harness.step()` derives its deadline from 5,400 nominal 60-Hz frames plus
five seconds of slack. The smoke-wide allowance is 1,500 seconds and the
heartbeat allowance 240 seconds; neither is the reported failure.

The original NET_RUN reports no fatal harness reason, matching hashes and
combat contexts on both peers. Their final observed cumulative physics counts
are both 4,560, with host/guest process-frame counts 942/921. The win driver's
local counter ceiling is 5,160. These cumulative heartbeats include setup and
teardown and do not establish that the loop's internal ceiling was reached.
The count and continued ticks support deadline expiration during ongoing
combat; they do not prove why the fight failed to finish early. Live encounter
HP, queued opponents, strike receipts and refusals were not retained. Saved
pre-fight fixtures contain all four intended level-18 party members, so an
unproved missing-party or low-level-starter explanation is not substituted.

The peer's control loop awaits the whole win command before reading another
message. Consequently, the host cannot service the queued quit while it is
still awaiting that command. Harness finish waits five seconds and terminates
stragglers. The host-still-live/guest-exited summary therefore does not itself
establish a deadlock, host crash or network admission failure.

There is a separate actual publication failure in the retained host log:
after the guest is logged as disconnected, six native RPC errors target its
unknown peer ID. Backtraces name `_publish_host_attack_launch` and
`_host_publish_peer_impact` through `_send_realm_rpc`. The publication loops
read retained encounter participants; the helper checks realm admission but
does not check live transport membership before rpc_id. This is an observed
disconnected-recipient fault. Its peer-log ordering does not establish that it
caused the earlier missing verdict. ROOT determines ownership and allocation;
no shared director edit or archived-chat reopening occurred here.

The adjacent fallback directory error is absent from both peer stdout logs
and both peer godot.log files. Linux child stdout/stderr are redirected into
those peer logs. The error is coordinator output, not an observed host or
guest save failure. Both peer pre-fight slot saves are present in the artifact.

The coordinator has a source-order fault that explains its unintended
fallback autosave despite the harness's isolation intent. The smoke starts
launch from SceneTree._initialize. Launch calls `_isolate_coordinator()` before
its first await, relinquishing Game's world-save ownership when the autoload is
not ready. The [pinned SceneTree initialization](https://github.com/godotengine/godot/blob/5b4e0cb0f/scene/main/scene_tree.cpp#L547)
calls [MainLoop's script initialization](https://github.com/godotengine/godot/blob/5b4e0cb0f/core/os/main_loop.cpp#L52)
before mounting the root into the tree. Then Game._ready calls
reset_for_new_game, which sets `_world_save_owned = true`. No later isolation
call follows readiness. Its blank coordinator Game can therefore reach its
180-second fallback interval. This is distinct from either peer's combat.

The error identifies mkdir failure beneath `user://saves`, but does not supply
the underlying filesystem errno. [Recursive user-path creation](https://github.com/godotengine/godot/blob/5b4e0cb0f/core/io/dir_access.cpp#L126)
starts beneath the resolved user root. Missing-root or permission explanations
remain unproved without filesystem evidence. If ROOT allocates a repair, the
bounded coordinator change is to reassert its existing isolation after
autoload readiness, preserving production Game ownership behavior and all
budgets. No SaveGame validator, payout, health, flags, or fixture success
condition is changed or proposed as an acceptance workaround.

This packet is read-only diagnosis. No runtime source change, engine/parser,
import, GPU/render/export, CI dispatch, push, new session/agent, or ROOT checkout
write occurred. The original smoke remains FAIL; exact combat-stall cause,
timeout resolution, performance and full acceptance remain unproved.
