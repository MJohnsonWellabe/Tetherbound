# v1/b20: Mosshock and Sparkit lateral hit arms (F36#54, F36#70), stay OFF

**Arms:** `creatures_ralph_mosshock_lateral_hit` and `creatures_ralph_sparkit_lateral_hit` in `creature_model_flags.json`. Each is the Burrowback recipe that gained on F38#2: `lateral_recoil.py --spec=spine:z:24,neck:y:38,head:z:24`, then `hold_clip.py` on a copy of the live remake GLB.

**Frames:** `capture_f36_poses.gd --species=mosshock,sparkit --whole-body --context`. Base (OFF) and candidate (ON) come from one run (`q_ms.sh`). Stage sets use hit 50/100 and faint 50/100. CPU, Compatibility.

**Yardstick:** JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py` (linear, slope 1.22, intercept -0.78, r 0.82).

| Row | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand |
|---|---|---|---|---|
| F36#54 Mosshock | 5.95 | 5.79 | -0.16 | 5.4 5.5 5.6 / 5.2 5.4 5.5 |
| F36#70 Sparkit | 6.20 | 5.75 | -0.45 | 5.8 5.5 5.8 / 5.4 5.2 5.4 |

**Verdict:** both worse, so both stay OFF and stay in `test_creature_model_flags` HELD.
- **Sparkit:** the judges read the held low lunge as a crouch that drops it below the trainer's head. They preferred the base's upright recoil.
- **Mosshock:** the hunch holds, but they found it barely different from standing either way.
- **Sparkit as shipped:** it maps at 6.20 in this round, above the floor.
- **Mosshock's next lever (judges):** the face and elemental trait don't read at stage distance, and the faint collapses into a "rock-like lump". That needs new art rather than a pose tweak.
