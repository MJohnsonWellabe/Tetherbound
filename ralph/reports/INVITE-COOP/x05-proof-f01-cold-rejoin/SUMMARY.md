# Net smoke run net-f01cold-24987

Scene: title
Peers: 2
Net conditions: clean (no proxy)

- peer 0 (host) pid=25027 exited=true unexpected_exit=false
- peer 1 (client) pid=25381 exited=true unexpected_exit=false

FAILURES:
- COLD: a fresh guest process rejoins as the same character through the title's returning route (returning title route retained character 'character-f0c0a33403c373ecc914e36f16d99a34', expected 'character-81729f6a04a2f9da7f7c9bd34fca1b41')
- COLD: peer 0 sees both players again (registry reports 1 peer(s), wanted 2)
- COLD: peer 1 sees both players again (registry reports 1 peer(s), wanted 2)
- COLD: the fresh process holds the same character and the SAME starter (UID ["creature-8d7c97332feeb28ffe9a2a8caa26c771"] -> [])
- peer 1's starter is its ripplet named 'A' after the cold reconnect ([] [])
- COLD: the starter receipt came back from disk
- COLD: exactly the 50 orbs it had before its process died (orb_basic count 0)
- both peers hold the same road layout after the cold reconnect (host 34 bands / 248 points b7c6b5ed2fea, guest 0 / 0 )
