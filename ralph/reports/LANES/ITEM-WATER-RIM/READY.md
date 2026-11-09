STATUS: land (GPU-judged arm ships; coordinator change, config only)
BRANCH: tb/item-water-rim-soft

# Tidewake character rim softened (coordinator, 9 Nov)

- Cause: LANE-SCOUT ralph/reports/LANES/ITEM-NPC-ALBEDO/CAUSE-TIDEWAKE.md (tb/item-scout-1108 069e01457). data/config/water_character_rim.json puts an additive, unshaded, fog-disabled cream overlay (#fff0d8, energy 0.8, power 2.2, fill 0.14) on every Tidewake named NPC and trainer body. On Forward+ it lifts dark costumes toward the dune colour and outlines every edge, so speakers read as see-through. It shipped on 4 Nov from a CPU-only judgement.
- GPU arm round (ralph/reports/GPU-PASS/1108/G-water-rim.md, 143b91bad; confirming batch, three code-blind judges): rimSoft (energy 0.3, power 3.5, fill 0) wins every row 3/3: F39#18 +1.87, F39#26 +2.13 (7.52 at High), F39#27 +1.09 (the backlit row the rim was made for), F39#29 +1.50. Rim off scored the same or slightly lower, so the thin edge stays.
- Change: energy 0.3, power 3.5, fill_energy 0.0, with `_why_soft`. `enabled` and `_why_on` are unchanged, so tests/test_near6_tw_judged_on.gd still holds.
- Tests that grep water_character_rim: tests/test_near6_tw_judged_on.gd only (asserts enabled and the 6.23 record, both unchanged). JSON parses.
