# F32#4 win shed (composed in F27's host wild-defeat stage)

- `scripts/creatures/essence.gd`: `host_wild_defeat_event` adds an optional tenth
  key `realm`; `stage_defeat` accepts 9 or 10 keys. With a realm and
  `f32_runtime.json runtime_enabled`, `_defeat_shed` calls
  `shed_drop_rules.wild_win_candidate` with the host-derived roll
  `sha256(json([world_namespace, event_id, enemy_uid, character_id]))[0:8] / 2^32`.
  Outputs join the same candidate as XP/essence (one receipt, one save/ACK);
  if they do not fit, the shed is skipped and the victory still pays. The
  proposal returns `shed_outputs`. A nine-key legacy row computes no shed and
  keeps the same receipt signature.
- `scripts/world/f32_source_actions.gd`: dead `compose_wild_shed` removed.
- Proof: `unit-test_f32_win_shed.txt` (skyplume from a Cloudreach Galecrest win,
  deterministic on retry, once on replay; misses, wrong realm and unlisted
  species shed nothing; legacy rows; full satchel still pays XP/essence).
  `smoke-wild-defeat-10-key-event.txt`: the real Meadows fight path still
  settles with the 10-key event (Bramblebun has no shed profile; disclosed
  actor-vitals override, see F27 proof README).
- Limits: production wild wins reach this path only with
  `combat.json actor_vitals.runtime_enabled`, which ships false; co-op wins
  are refused by `_commit_host_wild_victory` (`remote_training_baseline_not_ready`).
