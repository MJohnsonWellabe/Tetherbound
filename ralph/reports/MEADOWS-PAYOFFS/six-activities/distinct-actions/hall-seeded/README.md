# Hall alpha, seeded save (F03#1)

**Fixture (seeded, disclosed):** `tests/fixtures/f03_lure_saves/S09-exit-seeded.json.gz` is an unmodified gzipped copy of `ralph/reports/gate-f-leg-s09/saves/S09-exit.json` (sha256 of the JSON: 593fd305ed71d3e5b33eb8742521ca9e6f4e2005d1e37b5755035db532994abf). That save grew from a hand-authored idealised seed (five Lv18 creatures; the Stronghold approach was then driven for real, leaving Lv19), so it is **not earned play**. The coordinator accepted it on #289 (option 1) for this capture only.

**Run:** `tests/capture_activity_lures.gd --act --activity=hall --budget-s=900`. The player walks from the saved pose to the band5 off-road alpha by ordinary input, presses "Engage Alpha Galecrest" and fights it with the input combat pilot.

**Result:** fight `won` ("The wild creature is beaten"; "The west shoulder has gone quiet"), and the game set the once flag `wild_once_5001`. See `receipt.txt`.
