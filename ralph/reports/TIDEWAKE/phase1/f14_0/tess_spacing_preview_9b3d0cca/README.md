# Tess C3 preview on the unlanded contact-spacing rule

This is a **preview, not landing evidence**. It is a local detached merge of main c188b96e2 and `tb/combat-spacing` 9b3d0cca1. That commit had not landed on main, and it has no PR yet.

**Capture:**
- `tests/capture_tidewake_named_fights.gd --trainer=water_trainer_tess --approach=sluice_isle_to_deep_watch_arrival --pilot=READER --level=43 --interval=12 --tells-per-opponent=2`, at 1280x720 opengl3.
- The approach is a 317 m stick walk, then the challenge prompt.
- The disk filled mid-run, so the third opponent's frames are lost. 24 frames are usable (Mirejaw and Riverdrake).

**Geometry:** the smallest ally-opponent gap is 6.99 m. Before the rule, r5's contact frames got to within 4.7 m.

**One code-blind judge** (default model) under `../../C3_RUBRIC.md`, handed the rubric before any frame: **19/24 = 79.2%**; tell-start markings 4/4.

The five failures are all rule 3:
- **At contact** (hit-004.25, t-000.00, t-036.02): Ripplet's head covers Mirejaw's snout. At the rule's 0.6 m margin (configured, not measured), the bodies still read as touching behind the ally.
- **The player trainer** (tell-ended-000.58, tell-ended-001.93): after Mirejaw's lunge carries it past Ripplet, the player stands in front of Mirejaw's lowered head. The fight camera fades only the ally, not the trainer.

**Reading:** the rule stops fighters from interpenetrating. As committed, it does not by itself bring Tess to the C3 bar.
