# Net smoke run net-20261005T164329Z-7953-idrerun

Scene: title
Peers: 2
Net conditions: clean (no proxy)

- peer 0 (host) pid=10500 exited=true unexpected_exit=false
- peer 1 (client) pid=10501 exited=true unexpected_exit=false

FAILURES:
- peer 1 returned to Grandpa but the catch-supply dialogue never opened
