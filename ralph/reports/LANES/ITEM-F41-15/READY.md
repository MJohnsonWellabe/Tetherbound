STATUS: land (GPU-judged arm ships)
BRANCH: tb/item-f41-15
HEAD: (this commit)

F41#15 arm B ships: the captain_a albedo grade only. GPU 1108 G-f41-15
(tb/item-scout-1108 6e5822d99, ralph/reports/GPU-PASS/1108/G-f41-15.md) scored
F41#15 +0.91 and F41#7 +0.95, with 3 of 3 judges preferring it. Arm A
(conversation speaker light) made no visible change and is dropped.

- data/config/character_body_flags.json: npc_vis_look_captain_a is enabled, with
  `_why_on` recording the score. day_rim and idle_relax are removed for captain_a,
  exactly as overlay_albedo_grade.json did, so only body_albedo_override remains.
- tests/test_character_body_flags.gd: npc_vis_look_captain_a joins JUDGED_ON. The
  "records its judged score" check also accepts a `_why_on` that names its GPU
  pass. Batch-7 flags still need "GPU batch 7" in `_why`.
- Tests: test_character_body_flags, test_texture_import_policy,
  test_trainer_defeat_reaction, test_named_trainer_wild_clear and
  test_water_guardian_reward give 15 tests, 2158 assertions, 0 failed.
