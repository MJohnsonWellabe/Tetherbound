# Net smoke run net-20260926T230227Z-3132

Scene: world
Peers: 2
Net conditions: clean (no proxy)

- peer 0 (host) pid=3703 exited=true unexpected_exit=false
- peer 1 (client) pid=3155 exited=true unexpected_exit=false

FAILURES:
- #55 peer 1 fly_launch (CONTROL: the guest launches past the open gate) -> FAIL -- the second airborne Jump did not launch; screen: no SequenceDirector here; nothing holding the screen; launch_blockers() said '', now 'Fly is unavailable while riding or in combat.'
