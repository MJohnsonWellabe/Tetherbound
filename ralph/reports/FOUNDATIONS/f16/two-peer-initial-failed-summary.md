# Net smoke run local-4410608

Scene: world
Peers: 2
Net conditions: clean (no proxy)

- peer 0 (host) pid=15324 exited=true unexpected_exit=false
- peer 1 (client) pid=15416 exited=true unexpected_exit=false

FAILURES:
- peer 0 foundations_state seed: ["$.creatures.creature-1b22f37882b93688cffabdfc4b05b308.cap_level: unknown id/value 20"]
