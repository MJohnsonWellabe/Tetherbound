# Net smoke run net-20261012T171827Z-26477

Scene: title
Peers: 2
Net conditions: clean (no proxy)

- peer 0 (host) pid=26520 exited=false unexpected_exit=false
- peer 1 (client) pid=26521 exited=true unexpected_exit=false

FAILURES:
- #43 peer 1 enter_realm (guest back to Stormwood (RD-17: Home Key home / Hall Stormwood arch back)) -> FAIL -- Game.enter_realm('stormwood') refused from 'meadows' (can_enter=true); Actual correlated saved/arrived completion missing within original budget
