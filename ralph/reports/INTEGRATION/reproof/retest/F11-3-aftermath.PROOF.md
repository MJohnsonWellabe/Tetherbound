# Two-peer proof: F11#3: Long Storm aftermath, the Spark shrine and the Waterward gate persist through a host process restart, a rejoin and a mid-session guest drop

**Verdict: FAIL** (exit 1)

Scenario: `/home/user/Tetherbound/tools/net/proof_scenarios/stormwood_f11_aftermath_shrine_two_peer_reload_rejoin.json`  
Run: `net-20261004T202411Z-5142`  
Rendered: no (headless)

ACCEPTANCE F11 'Long Storm aftermath, Spark/shrine and the once-opened physical Tidewake gate persist' (S3). Two real peers. The Long Storm ends through the real completion path: the host's Stormwood ending sees Marrow's defeat, records the participants and emits the chapter event dynamo:release, whose objective grants stormwood:long_storm_ended and realm_heart_stormwood_earned on the host ledger (both peers receive them). Both peers' StormwoodSurge then presents the aftermath (aftermath timings, no flashes). The host charts the Waterward view, the guest opens the gate once. In the Meadows the GUEST sets the Spark of the Stormwood into its home-circle socket (a world fact) and the HOST wears its power (a personal choice). Host save (autosave_here), then the host's Godot PROCESS ends and a fresh one boots the title on the same user data and presses Load (title_screen _load_slot, which hosts); the guest rejoins from the title as the same character. World-state hashes agree and equal the pre-restart hash; aftermath, Spark placed/active, gate and receipts match on both. The restart and every check after it happen in Stormwood; afterwards only the GUEST crosses realms (to the Meadows socket), because a HOST realm crossing after any guest reconnect stalls 120 s and fails (realm_transition.gd epoch mismatch, reported separately as a SHARED-FILE REQUEST with its own repro). Then the guest's link dies mid-session and it rejoins: it rebuilds the same state from the host, no conversation replays, and nothing is granted twice. Negative controls: the aftermath assertion on the fresh save, the gate before its press, the hash against the arrival world and the saved-aftermath check on the pre-run world all FAIL as expected. Setup, disclosed: the Dynamo fight fixture (Marrow's defeat committed through the ledger, the fight not played), `teleport` beside the view and gate prompts, and spark_socket's teleport beside the Spark socket (its press is an ordinary interact press). Break strikes: the aftermath still has a 45 s Break per 2550 s cycle by design (stormwood_surge.json aftermath_seconds); this proof reports the strike warnings each peer saw in two 10 s watches, it does not claim strikes can never happen after the Long Storm.

## Failures

- #1 peer 0 load_save (named save: Meadows, Stormwood route open, loaded like Continue) -> FAIL; data did not match {"character_id":"character-f41f4a49223483d6bfdf56715944bb7b","form":"captured directory (split path)","realm":"meadows"} -- Game.load_game(0) refused /home/user/Tetherbound/tools/net/proof_saves/host_meadows_stormwood_route_open

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — named save: Meadows, Stormwood route open, loaded like Continue | PASS + {"character_id":"character-f41f4a49223483d6bfdf56715944bb7b","form":"captured directory (split path)","realm":"meadows"} | FAIL **(unexpected)** | Game.load_game(0) refused /home/user/Tetherbound/tools/net/proof_saves/host_meadows_stormwood_route_open |

## Captured files

