# Hall alpha from the earned save

- **Save:** `tests/fixtures/earned_saves/checkpoints/seed4_hall/save`, loaded with `--save-dir`, which copies it unmodified. The Cloudreach lane's earned C1 chain produced it through play (`tools/earned_saves/run_chain.sh 4`). Its disclosures are in `tests/fixtures/earned_saves/checkpoints/seed4_hall/receipts/` and `tools/earned_saves/BLOCKERS.md`.
- **Party:** as earned, Lv15–18, with two members knocked out.
- **Run:** render.yml **36289584698** at **e315d4ca**, `tests/capture_activity_lures.gd --act --activity=hall --budget-s=900`. It replaced the earlier unrecorded local render. The walk leaves the Hall chamber by chamber (6 stronghold markers), then takes the road to the band5 off-road alpha. The lure was first seen on the road at 154 m with no deliberate look. The player presses Engage and fights with the input combat pilot.
- **Result:** fight `won` ("The wild creature is beaten"; "The west shoulder has gone quiet"). The game set `wild_once_5001`. `load_vs_saved_xz_m` 0.0, `script_state_writes` none.
