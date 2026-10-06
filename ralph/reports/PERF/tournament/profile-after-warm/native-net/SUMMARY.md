# Net smoke run p2-tournament-profile-after-warm

Scene: world
Peers: 2
Net conditions: clean (no proxy)

- peer 0 (host) pid=19168 exited=false unexpected_exit=false
- peer 1 (client) pid=9148 exited=true unexpected_exit=false

FAILURES:
- peer 1 joined 'tournament_quarter_mira' rather than opening another fight (the join did not put this peer in a fight)
- peer 1 reduced 'tournament_quarter_mira' shared opponent HP -- attempt 6: host hp 121.314 -> 121.314 at (0.88, 2.15, 5.96); stand_in=this peer has no opponent body to move place=creature stands at (3.50, 0.91, 5.55) strike=FAIL this peer is not in a networked fight; no host receipt for peer 386475135; guest refusal={  }
- peer 1 received 'tournament_quarter_mira' authored reward in full
- 'trainer:tournament_quarter_mira:coins' has accepted durable receipts for both stable participants (["character-7cd10e80d298e5744c40e401657aa913"])
- 'trainer:tournament_quarter_mira:item:potion_small' has accepted durable receipts for both stable participants (["character-7cd10e80d298e5744c40e401657aa913"])
- both peers completed 'tournament_semi_tam' (no verdict)
