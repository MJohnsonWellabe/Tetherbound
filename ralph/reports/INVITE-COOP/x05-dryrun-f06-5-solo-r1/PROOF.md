# Two-peer proof: DRY RUN — does not count: F06#5 solo half from the earned flight-trained checkpoint

**Verdict: FAIL** (exit 1)

Scenario: `/home/runner/work/Tetherbound/Tetherbound/tools/net/proof_scenarios/f06_5_solo_flight_autosave_earned_dryrun.json`  
Run: `net-20260927T055350Z-2399`  
Rendered: no (headless)

DRY RUN — does not count until Cloudreach's tap-climb fix (held-button flight, #356 05:20) lands and the strict re-check runs. From the earned checkpoint c1_flight_trained (tb/cloudreach-b b084432d; Fly unlocked by Maela's trial, the same earned five, upper gate closed): the trainer walks off the Aerie deck by stick and TAPS jump in the air (the ordinary launch; Maela's loaner carries it -- none of the five flies); the game's OWN periodic autosave is taken while it is flying; the process ends and a fresh one loads that save through the title. Then: same five UIDs, standing on a floor, not flying/carried, upper gate still closed and not inside sealed Upper Cloudreach. No flag, party, item or position is written.

## Failures

- #7 peer 0 ledge_launch (LAUNCH by input: waits for the game's autosave timer to near its next save, walks off the deck by stick, TAPS jump in the air) -> FAIL -- no verdict

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — the EARNED flight-trained checkpoint, loaded through Game.load_game | PASS | PASS | loaded save (earned save fixture root (split path)) as slot 1; realm 'cloudreach' booted as 'cloudreach'; character 'character-afb79936a9ddebd411e54dfa2817d5b0' |
| 2 | 0 | assert — Fly was earned (Maela's trial) in this save | PASS | PASS | flag fly_traversal_unlocked set |
| 3 | 0 | assert — the upper counterweight gate is CLOSED | FAIL | FAIL | flag cloudreach_upper_route_unlocked NOT set |
| 4 | 0 | party_uids — the earned five | PASS | PASS | 5 owned: ["creature-f4118d54a2317867246afbf1e8ea834f", "creature-390db8e0de00cd1fcaaf1747203b0768", "creature-c785f517af159966b72ca0f49f61d386", "creature-8e12dace31044e591f02b96391ca2372", "creature-9d1cb676a71c2f31e5555ec9eec9905f"]; kept as 'five' |
| 5 | 0 | probe position — on the Aerie deck | PASS | PASS | [399.736694335938,610.130126953125,3249.18383789062] |
| 6 | 0 | ledge_probe — read-only: where the deck drops away | PASS | PASS | [{"drop_m":600.0,"edge_m":22.0,"heading_deg":0,"to":[399.7,3277.2]},{"drop_m":600.0,"edge_m":22.0,"heading_deg":22,"to":[410.5,3275.1]},{"drop_m":50.0,"edge_m":22.0,"heading_deg":45,"to":[419.5,3269.0]},{"drop_m":600.0,"edge_m":22.0,"heading_deg":67,"to":[425.6,3259.9]},{"drop_m":600.0,"edge_m":21.0,"heading_deg":90,"to":[426.7,3249.2]},{"drop_m":600.0,"edge_m":21.0,"heading_deg":112,"to":[424.7,3238.9]},{"drop_m":600.0,"edge_m":21.0,"heading_deg":135,"to":[418.8,3230.1]},{"drop_m":600.0,"edge_m":20.0,"heading_deg":157,"to":[409.7,3225.2]},{"drop_m":31.0,"edge_m":20.0,"heading_deg":180,"to":[399.7,3223.2]},{"drop_m":600.0,"edge_m":20.0,"heading_deg":202,"to":[389.8,3225.2]},{"drop_m":600.0,"edge_m":20.0,"heading_deg":225,"to":[381.4,3230.8]},{"drop_m":600.0,"edge_m":21.0,"heading_deg":247,"to":[374.8,3238.9]},{"drop_m":600.0,"edge_m":27.0,"heading_deg":270,"to":[366.7,3249.2]},{"drop_m": |
| 7 | 0 | ledge_launch — LAUNCH by input: waits for the game's autosave timer to near its next save, walks off the deck by stick, TAPS jump in the air | PASS | FAIL **(unexpected)** | no verdict |

## Captured files

