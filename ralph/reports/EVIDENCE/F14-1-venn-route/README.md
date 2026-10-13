# Venn on the Tidewake route: root cause and fix (tb/ev-systems-a)
Symptom (routes-west, F13#0/F19#5 07_human_late): Officer Venn beats all five at L20/L32/L33/L44, while C2 at L32 wins even for the masher.

## Diagnosis (instrumented L44 run, coordinator 3f515e648, local prints only, 15:48–17:00 CT)
- The 1.9 foe_power_multiplier is applied once (water_encounter_runtime_data.team_member, then ×1.6 damage_scale), the same as in C2. The combat_profile label is not read.
- Levels do scale: damage = power×2×atk/(atk+def), so a level edge at most doubles damage. Nothing scales trainers to the party, and the solo session scaler is the identity.
- Bex took 180.1 s sim and Calder 252.0 s sim (power 36.6). The lead was barely hit: Calder 0 damage, Bex about 21.
- Venn (power 31.6): every attack cycle landed, one hit about every 3.0 s (cooldown 1.2 + tell 0.9 + recovery 0.9), about 40 per hit, from 8–10 m.
  - Terrapup (430 HP) fainted at 37 s, then Bramblebun at about 108 s.

## Root cause: a helper bug
- tests/helpers/water_combat_pilot.gd ignores the drawn shape. During a tell it backs straight out of the body's spaced reach, which is about 9 m for a large WALL. That never clears a named F22 shape inside the tell.
- Venn and Nerissa are the only Tidewake trainers with named patterns.

## Fix
- 17f33eec9: the pilot extends f22_pattern_pilot. When a pattern shape is committed it walks the shortest drawn exit, and it stays out of live fields.
- 1032b96d3: the shared reader also stops refusing inward exits near the arena edge and remembers a diver's landing marker.

## Proof
- L44, 07_human_late from tidewake_05 on 3f515e648 + 17f33eec9 (local 1a4c69a0b), 17:14–18:40 CT:
  - Bex won in 173.2 s sim and Calder in 248.5 s sim.
  - **Venn won in 193.9 s sim, all three opponents.**
  - The piece then FAILs at a later step: "Veilfall recovery waypoint 3 walk failed at (331.2,6.1,3798.4) toward (-14.8,166.2,4016.0) resets=2". This is route traversal, which no run had reached before.
- L20 (the earned five, no raise) on d83f2d3b7, 19:58–20:55 CT: Venn wins at 159.1 s sim. This is the separate 'Tidewake L20 cap, no breakthrough on route' gap: L20 is 10 levels under the Veilfall entry [32,33], so it is not a balance failure (coordinator).
- **L32 (chapter_curve Veilfall entry, disclosed raise) on f0f5897a8, 21:00–22:02 CT, hosting on udp/27015:**
  - Bex won in 172.5 s sim and Calder in 263.0 s sim.
  - **Venn won in 204.4 s sim, all three opponents.**
  - The run then stops at the same Veilfall walk-back step, which routes-west fixed on tb/ev-meadows-fights.

EV F14#1-route PASS 1a4c69a0b Venn defeated on the Tidewake route at L44 (193.9 s sim) after the route pilot reads F22 shapes; 07 next fails at the Veilfall recovery walk (routes-west)
EV F14#1-route PASS f0f5897a8 Venn defeated on the route at the Veilfall curve entry L32 (204.4 s sim, disclosed raise); L44 also passed; the walk-back after Venn is routes-west's fix
