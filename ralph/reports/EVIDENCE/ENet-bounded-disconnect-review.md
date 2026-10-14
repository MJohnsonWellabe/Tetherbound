# Bounded disconnect review

The configured ENet maximum alone cannot enforce a wall-clock disconnect bound. Its timeout checks occur when a command's current retry delay expires; changing minimum, maximum or multiplier does not remove that scheduling condition. Do not reduce the135s loading tolerance or increase the cut-key test budget to conceal it. A framework timeout cannot run while the process is stalled, so the truthful product contract must be: disconnect on the first servicing frame after the180s liveness deadline.

## Product design, distinct from diagnostics

A transport-independent Session challenge/response can supply that contract without changing the engine or manufacturing a test disconnect:

1. Start one host-side record per physical admitted connection, identified by peer ID plus a fresh unpredictable connection token. A record's initial confirmed time is admission time. Keep ENet's existing timeout values; they remain its retransmission policy, not the hard deadline.
2. Send a small unreliable challenge about once per second from Session, which already processes while menus are paused and remains present during realm changes. Respond from the remote Session regardless of gameplay bootstrap/fences, without touching saves, progression or player state. Authenticate sender ID through MultiplayerAPI; never accept a payload-provided peer ID. Gate support on compatible protocol/build identity.
3. Record issued nonce -> monotonic send time for a bounded window (at most the180s deadline plus one interval). Accept each nonce once for that exact connection. A valid response advances confirmed time to its challenge's send time, not response arrival time. Delayed queued replies therefore cannot extend a dead connection indefinitely. Wrong peer, unknown nonce, previous-connection token, duplicate/reordered older response and future timestamp do not renew it. The receiver supplies no authoritative clock.
4. At the first Session frame with no confirmation inside peer_timeout_max_ms, close that physical connection and invoke the existing departure lifecycle exactly once. Preserve flush_gather_batch, owner-passive departure, unjournaled-item cancellation, registry removal, reconnect seat reservation, broadcasts and realm reconciliation. Do not route it through deliberate goodbye/kick, which changes reservation semantics. Verify the engine's force-disconnect signal behavior before implementation; a transport close and a later duplicate callback must not double-reserve or lose journal rows.
5. Clear the monitor on disconnect and teardown, and reinitialize on rejoin even if a peer ID is reused. Keep this scoped to physical connections, never relayed client IDs. Host death also requires a symmetric client monitor or a separately documented existing detection contract; host-only monitoring must not be described as a universal session bound.

This is a new product protocol and lifecycle change, not a one-line timeout adjustment. Current public ENetPacketPeer statistics expose RTT and packet state but no last-receive or earliest-retry timestamp, so the same guarantees cannot be reconstructed from the diagnostic statistics alone.

## Required evidence before integration

- Pure deterministic clock tests: first admission; healthy response;135s loading gap survives; expiration at180s; stale/replayed/wrong-peer replies; nonce-window bound; reconnect token and teardown reset; no RTT-dependent deadline.
- Lifecycle fixture: the timeout follows exactly the ordinary unexpected-departure cleanup and reserves the same character; duplicate native disconnect callback does not duplicate cleanup. Confirm pending owner-save/journal data is retained for rejoin.
- Root-only native checks on the unchanged cut-key12000-frame assertion, authentic rejoin/single key spend, and a healthy long realm transition. Include a live peer with delayed/lost heartbeats so a real loading interval is not mistaken for death.
- Keep all original failures and warning policies. A diagnostic pass alone cannot demonstrate this new deadline contract or close the incident.

No product watchdog is wired by this review. The exact-source diagnostic candidate contains only the peer-runner observations from ac6732181d on coordinator a9aa64e45d. It is intended to distinguish a live ENet peer from a stale registry at the original failure boundary before choosing a lifecycle repair.

## Independent source findings

Session already uses PROCESS_MODE_ALWAYS. Its existing one-second world clock traffic is host-to-client unreliable only, so it does not prove the host received a fresh guest response. The normal unexpected-departure callback reserves the reconnect seat only after registry removal; the test comment describing a120s held seat before link drop is inaccurate. The120s reservation starts after transport detection and is separate from ENet's135/180s retry settings. The resumed guest remains at title and cannot renew the old connection in the retained failed run.
