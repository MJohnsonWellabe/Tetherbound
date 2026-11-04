# Quick judge f38_22-market-folk2: F38#22

- Head `b7e5a80d6e5993d49d072673c2040ebae30bc6a5`, tree `549e491833d9`; CPU llvmpipe, Compatibility (`quick_judge.py`).
- Overlay: `{"data/config/village_npcs.json": {"market_folk": {"enabled": true, "villagers": [{"name": "Market Trader", "config_key": "trader", "position": [14.3, -6.3], "facing_deg": 210.0}, {"name": "Market Shopper", "config_key": "villager_farmer", "position": [12.4, -7.4], "facing_deg": 40.0}, {"name": "Cart Hand", "config_key": "inn_helper", "position": [9.4, -2.2], "facing_deg": 170.0}, {"name": "Table Craftsperson", "config_key": "craftsperson", "position": [11.2, -3.6], "facing_deg": 130.0}]}}}`
- Capture: 1 launch(es); base 472s, candidate 475s, wall 947s.
- Yardstick: JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py`: linear, slope 1.3979, intercept -1.9959, r 0.9669, anchor RMSE 0.347, confirming batch.

| Row | Subject | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Defect calls base / cand |
|---|---|---|---|---|---|---|
| F38#22 | mill and settlements | 6.44 | **6.62** | +0.18 | 5.7 6.2 6.2 / 5.9 6.4 6.2 | PRESENT / PARTIAL,PRESENT |

CPU mapped scores rank candidates only; a row closes only on the GPU (High, then Medium).
