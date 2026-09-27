# F10#2: Stormwood named fights vs C2 and measurable C3

**C2 and measurable C3: PASS for all 18 fight × starter rows** (six named fights × three starters). The run was 864 fights with 0 errors and 0 stalls, and exited 0.

This closes only the **numeric** part of "Named fights pass C2/C3". C3 also requires "framing/readability passes at actual creature scale". That needs production-camera footage and a code-blind judge, which is a separate slice (`FOOTAGE_VERDICT.md`, in progress). Until that passes, F10#2 stays open.

Scope: the six BOSSES §7 named wilds are Hollows Alpha, Capacitor Alpha, Crown Guardian, Old Rodfolk Hall Guardian, Blackwater Elder and Glass Field Alpha. Captain Marrow and the Dynamo are F11, owned by the Stormwood main lane.

## Method

- **Harness.** `tests/smoke_stormwood_b_named_c2c3.gd` over the shared `tests/helpers/combat_depth_pilot.gd`, unmodified. It is the same method as the Tidewake F14#0 report: the real CombatManager, the WildCreature AI and CharacterBody3D bodies on a flat collider, with READER and MASHER policies.
- **Foes.** Built as production builds them: the placeholder species at the authored level, with the BOSSES §7 combat block the encounter director installs as `combat_override` (`stormwood_encounter_catalogue.gd::named_combat`), `trainer_owned=false`.
- **Party.**
  - The retained five: the starter plus bramblebun, mudsnout, pipwing and trailpup.
  - The lead cycles through terrapup, ripplet and galewisp.
  - No items.
- **Party level.** COMBAT §7 says "region-entry levels". This report uses each region's Calm wild band midpoint + 1: Hollows L35, Conductor Run L37, Crown L39, Deepwood L41, Dynamo L42. This is disclosed, and `--party-level` overrides it. Calibration: the chapter's declared entry level, L33, is one above Cinder Verge's 30–34 band midpoint.
- **Seeds.** 24 per policy per starter.
- **Engine.** Godot 4.7, headless, `--fixed-fps 60`.
- **Command.** `godot --headless --path . --fixed-fps 60 --script tests/smoke_stormwood_b_named_c2c3.gd -- --seeds=24 --json=res://ralph/reports/STORMWOOD/b/f10_2/c2c3_runs.json`
- **Commit.** Measured on 6459f2aa. The only later branch changes to game code are Rook's reward, which does not touch combat.
- **Artifacts.**
  - `RUN_c2c3.txt`: every row.
  - `c2c3_runs.json`: every run.
  - `SUMMARY_TABLE.md`: the tabulated rows (`summarize.py`).

## Rules applied

These are the ACCEPTANCE C2/C3 bars, applied per fight × starter:

| Rule | Bar |
|---|---|
| C2, named wild | READER median lead HP cost ≤ 0.55 × MASHER's, and READER win ≥ 90% |
| C3, single hit | No incoming hit ≥ 50% of an entry creature's HP. This is the worst hit seen in any matchup, which is harsher than the neutral-only bar. |
| C3, tells | Every tell ≥ 0.8 s. A fight BOSSES authors as heavy (≥ 1.1 s, here the Hall Guardian) must show ≥ 1.1 s. |

## Result (see `SUMMARY_TABLE.md`)

- **Reader vs masher.**
  - The reader wins 100% everywhere, at a 0–4.7% median lead cost.
  - The masher pays 21–100% of its lead's HP.
  - Against Hollows Alpha, the Terrapup and Galewisp mashers lose their lead in 79–83% of runs and win only 17–21%.
  - The ratio is at most 0.15 (Blackwater Elder with Terrapup leading).
- **Worst single hit:** 12.9% of an entry creature's HP (Old Rodfolk Hall Guardian vs Galewisp).
- **Tells:** exactly the authored values. Hollows, Capacitor, Blackwater and Glass Field are 0.80 s, the Crown Guardian is 0.85 s and the Hall Guardian is 1.10 s.

## Caveats (disclosed, not waived)

1. **The passes are strong on "decisions have value" but thin on reader pressure.** The reader is often never hit: 0 incoming hits in 12 of 18 rows. The pilot's READER reacts after 0.25 s to a 0.8 s tell and steps out of the shown geometry cleanly. This is the same pattern the Tidewake F14#0 report records. A human player will be hit more; the C2 bar is relative and is met.
2. **Heavy tells.** Only the Hall Guardian authors a ≥ 1.1 s tell. No other named fight used a heavy or charged signature during these runs, so C3's heavy rule is exercised by that one fight.
3. **Pacing** (COMBAT §7, informational, not part of C2/C3). A single named wild takes the reader 34–123 s. Capacitor Alpha takes 96–123 s and Glass Field 54–96 s, which is long against the 20–45 s ordinary-wild target. That target does not bind named wilds, but long fights with no decision point are a known failure mode.
4. **Not covered by this fixture:**
   - terrain and arena geometry;
   - storm strikes in the fight;
   - Y skills and manual switch or burst;
   - co-op scaling;
   - a party from an earned save;
   - framing, which needs the footage slice.
5. **Pilot artefact:** a fainted lead ends a wild fight, and the pilot never switches by hand. The masher's low win rate against Hollows Alpha partly reflects that.

## Next

- **Footage slice:** production fight-camera frames and a code-blind judge per fight, for C3 framing and readability.
- **Optional:** re-run from an earned Stormwood save's party once F09#0 produces one.
