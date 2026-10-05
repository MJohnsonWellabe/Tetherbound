# Net smoke run net-20261005T154959Z-4019-shared_boss

Scene: world
Peers: 2
Net conditions: clean (no proxy)

- peer 0 (host) pid=6708 exited=false unexpected_exit=false
- peer 1 (client) pid=6709 exited=true unexpected_exit=false

FAILURES:
- peer 1 joined 'tournament_quarter_mira' rather than opening another fight (the join did not put this peer in a fight)
- both peers completed 'tournament_semi_tam' (no verdict)
