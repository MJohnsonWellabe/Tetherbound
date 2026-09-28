# F03#0 lure judge, set C (code-blind; herd, doss, bram, juno, hall)

**Judge input:** the 20 frames in `lure-judge-c/` plus the criterion and ruling. Each filename caption gives only the distance and whether the player was on the road.

| activity | frames from | visible from road | readable on approach | overall |
|---|---|---|---|---|
| herd | render.yml 36314439928 (S04, road-bound) | PASS, marginal (two deer on a rock at 63 m, on the road) | PASS | PASS (marginal) |
| doss | render.yml 36315597612 (S07-band3, road-bound) | FAIL: no smoke at 155 m on the road | FAIL: the column is cut off at the frame top under the HUD; a hill crest hides Doss until the prompt | **FAIL** |
| bram | render.yml 36315593617 (S04, road-bound; open-field site (300,983)) | FAIL: nothing identifiable at 70 m after the glance; the smoke is thin and pale against the hazy sky | PASS, marginal (fire and figure at 35 m) | **FAIL** |
| juno | earned render.yml 36282587113 | PASS (tall dark column at 130 m) | PASS, marginal | PASS (marginal) |
| hall | render.yml 36311702392 (alpha at (-30,7295)) | PASS, marginal (nameplate over trees at 86 m) | PASS, marginal | PASS (marginal) |

**Result: 3 of 5; vault pending.**

Both failures rest on the signal smoke. Bram's and Doss's columns are 28 m tall, colour #4f4a45 at alpha 0.9. Juno's column is 42 m tall, colour #2e2a27 at alpha 1.0, and it is the only one that reads. Smoke size, colour and opacity are art (ceded to Codex); coordinator ruling requested on #356.
