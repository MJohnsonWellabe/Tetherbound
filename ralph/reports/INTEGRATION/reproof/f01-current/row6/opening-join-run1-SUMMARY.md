# Net smoke run net-20261005T155644Z-4019-meadows_identity_fresh_join

Scene: title
Peers: 2
Net conditions: clean (no proxy)

- peer 0 (host) pid=7100 exited=true unexpected_exit=false
- peer 1 (client) pid=7101 exited=true unexpected_exit=false

FAILURES:
- peer 1 returned to Grandpa but the catch-supply dialogue never opened
