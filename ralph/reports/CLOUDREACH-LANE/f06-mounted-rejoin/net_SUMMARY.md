# Net smoke run net-f06-20260925T195427Z-10286

Scene: title
Peers: 2
Net conditions: clean (no proxy)

- peer 0 (host) pid=10324 exited=true unexpected_exit=false
- peer 1 (client) pid=10325 exited=true unexpected_exit=false

FAILURES:
- #27 peer 1 assert (JOIN: guest is NOT standing in sealed Upper Cloudreach) -> PASS -- 0.00 m from (-400.0, 3890.0), wanted within 40.00
- #40 peer 1 assert (REJOIN: guest is NOT standing in sealed Upper Cloudreach) -> PASS -- 0.00 m from (-400.0, 3890.0), wanted within 40.00
- #41 peer 1 assert (REJOIN: guest stands at the gate's legal side) -> FAIL -- 1483.82 m from (-104.0, 2436.0), wanted within 20.00
- #43 peer 1 fly_launch (MOUNTED: guest launches on its galecrest at the gate's legal side) -> FAIL -- the second airborne Jump did not launch; screen: no SequenceDirector here; nothing holding the screen; launch_blockers() said 'This wind route is still sealed: cloudreach_upper.', now 'Fly is unavailable while riding or in combat.'
