# Net smoke run net-20260926T221834Z-2215

Scene: world
Peers: 2
Net conditions: clean (no proxy)

- peer 0 (host) pid=2658 exited=true unexpected_exit=false
- peer 1 (client) pid=2237 exited=true unexpected_exit=false

FAILURES:
- #53 peer 1 fly_launch (CONTROL: the guest launches past the open gate) -> FAIL -- the second airborne Jump did not launch; screen: no SequenceDirector here; nothing holding the screen; launch_blockers() said '', now 'Fly is unavailable while riding or in combat.'
