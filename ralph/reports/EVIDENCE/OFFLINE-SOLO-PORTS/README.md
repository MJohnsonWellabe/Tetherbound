# Offline-solo boss rewards when every port is taken (STATE known bug; Systems bar 1)

Systems lane, tb/ev-systems, Tue 13 Oct 2026 (CT).

## Cause
Session.host() with no port asked tries the default and the next `port_fallback_span` (8).
When all were taken it left the session inactive. EncounterDirector._is_host() needs an
active host session, so host-authored durable rewards (chapter boss hand-off records, the
Warden's relic and portal key) never opened: the boss was beaten and nothing was paid.

## Fix (product)
- session.gd host(): when the whole span is taken and no port was asked for, host a session
  of one on Godot's OfflineMultiplayerPeer (transport "offline"). It uses the same
  admission and journals, has no socket, and nobody can join. It still returns false
  (no port bound) and bound_port() is 0. Config: multiplayer.json
  `offline_session_when_ports_taken` (true).
- title_screen.gd: no LAN beacon for an offline transport.
- tab_players.gd: says plainly that friends can't join this time and why.
- An explicitly asked, taken port still refuses and stays offline-solo, as before.

## Proof (headless, local)
- New tests/test_session_offline_fallback.gd: blocks the default port and the whole span,
  then checks host(-1) gives an active host on transport "offline" with bound_port 0, and
  that an asked port still refuses. With related suites (multiplayer_identity, steam_lobby,
  lan_beacon): 47 tests, 0 failed.
- tests/smoke_session_port_fallback.gd still PASS (a single taken default binds udp/27017).
- Not proven here: an end-to-end solo boss clear with every port blocked.
