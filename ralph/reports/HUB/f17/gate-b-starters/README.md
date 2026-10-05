# F01#4/#5 Gate B full chain per starter (tb/f17)

Command: `tests/smoke_gate_b_continuous.gd -- --gate-b-full-chain --starter=<s>` (headless). Each run covers naming, the
fight and physical catch, village tools, team of 5, camp (hammer, tent, fire, bedroll, creature beds), three-bed
readiness with save/reload, the Quarter/Semi/Final bracket, save/reload after round 3, and all 12 Gate B objectives.

| Starter | Run | Commit | Result |
|---|---|---|---|
| ripplet | local | f003834e | PASS, exit 0 (`ripplet-key-lines.txt`, `ripplet-local.log.gz`) |
| ripplet | render.yml 37239863776 | 261fc489 | PASS (job success = exit 0) |
| galewisp | render.yml 37239859189 | 261fc489 | FAIL: the village-tools walk stood on the trainer_camp campfire stone ring and left the floor stepping off it → navigator fix 44ffb9d1 |
| galewisp | render.yml 37241020668 | 44ffb9d1 | **PASS** |
| terrapup | render.yml 37239861479 | 261fc489 | FAIL: walk stalled 4.5 m short of creature bed 1 among practice-cluster wilds → product fix 7663a085 (camp keep-clear) |
| terrapup | render.yml 37241022619 | 44ffb9d1 | **PASS** (before the keep-clear fix; the crowding is positional and does not happen every run) |

Fixes on the way (all on tb/f17):
- 9729e527: quick-bar tap race (harness). The tap and settle finished inside one main-loop iteration's physics steps, so
  the check ran before the HUD's idle-frame poll saw the press.
- f003834e: the reload checkpoint saves the live world's own autosave slot (v28 journal-slot invariant; same assertion).
- 44ffb9d1: the navigator steers round any Props clutter more than 0.05 m above the foot; walkable treads are excluded.
- 7663a085: product fix. Wild bodies are kept 10 m clear of the Practice Meadow camp build site
  (combat.json arena.wild_keep_clear).

The retest's "can't reach creature_bed in the catalogue / stone 0" did not reproduce: every run placed three creature
beds (creature_bed costs no stone).
