# Cloudreach live summit combat — 2026-09-05

Three input-driven policies each won the production captain's three rounds in
the actual Cloudreach arena, then walked to and activated all three relays.
All three processes exited 0, with empty report errors and no engine/script
errors or warnings. No damage, health, AI, hazard or balance tuning was made.

This closes the flat-arena probe's **live environmental-force** omission. It
does not close continuous chapter attrition, statistical difficulty, visual
acceptance or owner-device performance.

## Declared fixture

`tools/probe_cloudreach_live_finale.gd` mounts the real Cloudreach scene/runtime,
director, CombatManager and finale controller. It seeds the explicit pre-boss
unlock checkpoint and starts the player once at the summit. The five-member
rested team copies the pre-captain `brawler_switch` ladder snapshot: Terrapup
L26/793 XP, Ripplet L27/620 XP, Galewisp L26/961 XP, Mosshell L26/1590 XP and
Duskhush L26/1423 XP. Bond counters start fresh. No sixth member, consumables,
mid-fight health/position writes, lethal test seam or hidden recovery is used.

The existing input pilot reads attack telegraphs but does not deliberately plan
around wind or lee pockets. Movement, attacks, optional switching and relay
interactions use production input. Combat RNG is seeded; these are three
specific trajectories, not a distribution. Headless fixed-60 timing measures
simulated gameplay, not frame-rate performance.

## Results

| Policy | Round durations, simulated seconds | Party HP after fight | Faints | Largest individual hit | Actual drift frames |
| --- | --- | ---: | ---: | ---: | ---: |
| Brawler | 15.63 / 18.38 / 15.15 | 23.21% | 3 | 37.11% max HP | 1,300 |
| Spacer | 14.57 / 21.48 / 19.55 | 51.96% | 2 | 40.58% max HP | 1,928 |
| Brawler with switching | 16.83 / 17.75 / 21.48 | 25.58% | 3 | 33.03% max HP | 1,373 |

The switching run used two voluntary switches. All runs paid the production
150 Coin reward, reached `captain_veyra_defeated`, and activated west/crown/east
relays to earn `storm_anchor_network_disabled`. Final input-walk gaps were
0.42–0.50m. No recovery event occurred. Each run observed actual stored movement
drift, wind, lightning-arc and lee samples, with all three combat phases followed
by `awaiting_restoration`. Largest measured drift was 10.00m/s. The largest
individual hit across this set remained below the D77 half-health ceiling;
victory still left substantial team attrition. No assertion of ideal tuning is
made from these three seeded runs.

## Reproduction and retained evidence

```powershell
& 'D:/Tetherbound-tools/godot/Godot_v4.7-stable_win64_console.exe' --headless --path . --fixed-fps 60 --log-file ralph/reports/CLOUDREACH-LIVE-FINALE-0905/brawler.log --script tools/probe_cloudreach_live_finale.gd -- --pilot=brawler
```

Use `spacer` or `brawler_switch` for the other policies. Create the log directory
before launching on a fresh checkout. Raw JSON/logs remain local in
`ralph/reports/CLOUDREACH-LIVE-FINALE-0905/`; JSON includes per-hit damage,
before/after teams, phase events, relay positions, limits and source hashes.
The first brawler-switch launch failed with native signal 11 before the engine
header; its log parent had not yet been created. Creating it and retrying
produced the recorded clean run (`brawler-switch-retry.log`). That launch failure
is not counted as a successful test or claimed as a diagnosed engine defect.

## Additional rendered run

The same switching policy also completed on real Windows/NVIDIA Compatibility
at 1280x800: three wins (15.50 / 17.33 / 21.38 simulated seconds), all three
movement-driven relays, 1,525 actual drift frames, no errors/warnings, exit 0.
Separate JSON/log and four real screenshots are retained under `rendered/` so
the headless evidence is not overwritten. The results differ slightly from the
headless trajectory; the seeded pilot is not asserted deterministic across
render scheduling. Root inspected the live wind/attack view, reward view and
network-result view. Phase-named captures wait for a render frame, so a filename
can describe the triggering phase rather than the state ultimately shown (the
`break_the_eye` image already shows the reward). Do not present that image as
an active third-round fight. These images establish rendered integration, not
a fresh blind visual acceptance or a quiet performance benchmark.

Next: finish the continuous route and carry its actual earned team/resources
through this finale, then replay aftermath and exact disk save/reload. The
bounded probe's optional rendered capture is separate from these headless data.
