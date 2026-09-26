# Net smoke run net-20260926T053151Z-3019

Scene: title
Peers: 2
Net conditions: clean (no proxy)

- peer 0 (host) pid=3040 exited=true unexpected_exit=false
- peer 1 (client) pid=3041 exited=true unexpected_exit=false

FAILURES:
- #30 peer 1 veyra_client_win (REJOIN: a repeat win after rejoin asks the host nothing and announces nothing) -> FAIL; data did not match {"had_flag":true,"local_flag_same_frame":true,"sent_to_host":false,"victory_emits":0,"world_store_writes_same_frame":0} -- no Game or no Cloudreach EncounterDirector in scene 'TitleScreen'
