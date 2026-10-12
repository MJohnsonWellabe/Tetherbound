# Net smoke run net-20261012T145051Z-15527

Scene: title
Peers: 2
Net conditions: clean (no proxy)

- peer 0 (host) pid=15596 exited=false unexpected_exit=false
- peer 1 (client) pid=15597 exited=true unexpected_exit=false

FAILURES:
- #35 peer 1 enter_realm (guest home to the Meadows (RD-17: Home Key home / Hall Stormwood arch back)) -> FAIL -- Game.enter_realm('meadows') refused from 'stormwood' (can_enter=true); Actual Home Key raise/saved arrival did not complete within original budget (refusal now=; last shown=The destination could not load.; key phase=idle pending= fade_locked=false; input owner=none; home_key count=1)
