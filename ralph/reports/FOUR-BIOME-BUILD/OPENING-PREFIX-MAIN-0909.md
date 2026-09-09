# Main opening-prefix proof — 2026-09-09

Status: passed bounded earned prefix on clean main. This is opening evidence only,
not a full campaign, later Meadows, biome, visual, or fixture verdict.

## Runtime target and isolation

- detached worktree: `C:/Projects/Tetherbound-opening-prefix-d3cdb57`;
- exact HEAD: `d3cdb57ca38acc2691c014663419389037b5209c`;
- driver: `tests/smoke_four_biome_continuous.gd -- --through-opening`;
- unique `APPDATA` and `LOCALAPPDATA` under the artifact root;
- external guard: 600 seconds, 90% system commit and 400 total processes;
- no console, teleport, HP, inventory, item or progress seeding.

A separate cold import completed first in 120.2 seconds with exit 0, an empty
guard stop reason and no engine, script or parse errors. It rewrote 1,089 tracked
`.import` files by line-ending normalization only: `git diff
--ignore-space-at-eol --stat` was empty. Generated `.gd.uid` files were untracked.
No production source changed.

## Earned result

The prefix wrapper completed in 102.55 seconds and the scenario reported 95.894
seconds. Native exit was 0, the external stop reason was empty, and the exact
terminal payload was:

`requested_prefix_passed:true`, `reached:"opening"`,
`campaign_complete:false`, `failures:[]`.

The retained checkpoints show title interaction at 0.06 seconds, character choice
at 0.13, new-world entry at 2.79, wake/Get Up at 63.45, starter selection and naming
at 71.93, 50 Basic Orbs received through Grandpa at 73.39, and the house doorway
exited at 74.99. The driver engaged the exact offered live Bramblebun at 83.68,
naturally weakened it to 25/106 HP at 88.04, committed an eligible unobstructed
physical throw, and completed the catch at 95.89. Exploration resumed with a
two-creature party.

There were zero `ERROR`, `SCRIPT ERROR`, or parse-error hits across the console,
stderr and engine logs. Peak guarded resources were 58.81% system commit, 246
processes, 2,270,830,592 owned private bytes and 2,196,140,032 owned working-set
bytes. No Godot process remained afterward.

## Raw evidence and limit

- cold import: `.artifacts/opening-prefix-d3cdb57-0909/import/`;
- opening prefix: `.artifacts/opening-prefix-d3cdb57-0909/prefix/`;
- guarded wrapper: `.artifacts/opening-prefix-d3cdb57-0909/run-guarded.ps1`.

This run deliberately stopped after the first live catch. It does not prove the
road-key/gate interaction, village dialogue and equipment flow, authored gathers,
camp, tournament, any later Meadows boundary, or any later biome. The next built-in
earned prefix is `--through-village`.
