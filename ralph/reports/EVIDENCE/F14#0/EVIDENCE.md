# F14#0: named Tidewake encounters, C2/C3 (non-Veilfall)
Run 1:57–3:32 PM CT, Sun 11 Oct 2026, on the ORIGINAL reader pilot (f22_pattern_pilot.gd identical at da1163323 / ≥3057bf24). Godot 4.7 headless.
Exception: Fennel ran 11:57 AM–12:19 PM CT on the same pilot, before a cue-visual-only merge.
`godot --headless --path . --fixed-fps 60 --script tests/smoke_water_named_c2c3.gd -- --seeds=24 --case=<id> --party-level=<L> --json=<out>`
Each case runs all three starters × MASHER/READER × 24 seeds. Verdicts are scored by `score_water.py` using the COMBAT §7 rules (the smoke prints numbers but not verdicts): `verdicts.txt`, raw `run_*.txt/.json.gz`.
Fixture (disclosed): no save is used. The party is the retained five at the region entry of each fight's island. That is `chapter_curve.json` tidewake `team[0]`: first_shores 20, marsh_channels 23, tidal_cradle 26, outer_reaches 28, tether_current 30. lantern_cove→20, gull_rest/brine/shellwatch→23, drowned_garden→28, sluice/deep_watch→30, by island order. Flat collider, no tuning.
Bars: named wild/alpha and floor/named trainers use reader lead ≤0.55×masher and reader win ≥0.9. Top (Calder, Tess) uses reader win ≥0.75, masher lead faint 1.00 and reader party ≤0.55×masher. C3 requires worst hit <0.50 and tells ≥0.8 s.
## Result: FAIL (three Galewisp named-wild rows; chapter masher-loss for Galewisp)
- PASS: Aquaryn alpha, lantern_shell_sentinel and gull_basalt_claw (all three starters each); Pell, Tovin, Solm, Irva and Bex (floor/named); Calder and Tess (top). Every reader win is 1.00.
- FAIL, reader lead ≈ masher (Galewisp only): brine_root_watcher 0.417/0.413, deep_watch_tidecoil 0.285/0.337, drowned_garden_songweaver 0.344/0.334. Terrapup and Ripplet pass those three.
- C3 measured half passes everywhere: worst hit 0.258 (Tess), tells ≥0.85 s, heavy 1.10–1.25 s.
- Chapter masher loses ≥1 named trainer fight, counting all 12 Tidewake trainer cases including Veilfall: Terrapup 0.96, Ripplet 0.80, **Galewisp 0.12** (bar 0.25, per COMBAT.md:142 "same form applies to Tidewake F14#0").
Open: C3 framing and the code-blind footage verdict are capture items. No tuning was attempted (F04#7 found power is C3-bounded; parked as a balance call).
