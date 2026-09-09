# Changed-source native adapter candidate v2 — fixture refused its realm ID

2026-09-09. Root approved the physical-client timeout correction after the first failure. The correction adds a role-aware physical-peer guard before `ENetMultiplayerPeer.get_peer`; its focused coverage passed 2 tests/8 assertions with no raw errors. The original failure remains recorded separately.

The changed-source candidate stopped at **6.847 seconds** on the first failing assertion. All six complete raw logs have **zero native ERROR and zero SCRIPT ERROR**. No protocol acceptance or retry pass is claimed.

| Role | PID | Terminal evidence |
|---|---:|---|
| Host | 3720 | No protocol checks; stopped by runner |
| Departing | 12680 | Two checks passed, then `begin_client` returned false; runner stopped |
| Staying | 20272 | One live-state check passed; runner stopped |

Both clients received the actual six trainer/creature bodies with continuous and reliable state. The departing client consumed its earlier ledger-channel request's reply while its source receiver still existed. The next assertion failed:

```text
ADAPTER CHECK departing FAIL production coordinator completed both fence rounds and actual drain
```

Source diagnosis: fixture constant `TARGET = "water_archipelago"` confuses the scene filename with the realm ID. `data/config/realm_hearts.json` names the realm **`water`**, whose scene is `res://scenes/world/water_archipelago.tscn`. The production coordinator validates the realm through real Realm Hearts and correctly refuses this fixture's invalid ID before starting a transaction. This is a fixture defect, not a native receive-map finding or a drain timeout. Correct the fixture identifier and add explicit refusal-state output before another authorized candidate.

The runner preserved all six logs and `receipt.json` under `.artifacts/realm-transition-adapter-20260909-v2/`. Resource samples were 71.20–75.52% used memory and 1914.77–2252.34 MB available, inside the 90%/400 MB stop thresholds. All three process exit codes are -1 because the first-failure runner stopped its owned processes; they are not successful process exits.

No subsequent native run has been executed. Game remains unconnected. Native drain/admission, real Water travel, actual late join/reconnect, Game rollback, existing host travel and full CI remain outstanding.
