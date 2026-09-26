# Net smoke run net-20260926T220450Z-2092

Scene: world
Peers: 2
Net conditions: clean (no proxy)

- peer 0 (host) pid=2663 exited=true unexpected_exit=false
- peer 1 (client) pid=2115 exited=true unexpected_exit=false

FAILURES:
- #32 peer 1 check_saved (the guest's character saved mid-flight: in Cloudreach, carrier owned) -> ERROR -- unresolved ["$character1"] (no session/character for that peer yet)
