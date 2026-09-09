# Varga focused corrected continuation — launch brief

Status: the one authorized observational continuation ran on merged production
`95fe105fb91f219bcd664e784e82d70da7c47756` and directly observed a corrected
finalized-death loss during Varga round two. It is diagnostic non-victory evidence,
not campaign completion or a clean-engine run.

## Exact bounded seam

Run the existing `tools/probe_varga_focused.gd` once in a fresh isolated profile.
The probe uses the production realm router, Stormwood scene, encounter authority,
combat manager, player death runtime and controller input. Its sole synthetic seams
remain unchanged:

- submit the normal Cloudreach-to-Stormwood admission key;
- create the disclosed five-creature entry party at level 44;
- place the human once two metres south of Varga after the production shell,
  population and entry settle.

After that placement, inherited `_defeat_trainer()` and
`_fight_current_encounter()` drive real recall, challenge, locomotion and quick attack
input. The probe does not write health, opponent state, round state, victory, reward,
trainer outcome or Stormwood progression. It is not a campaign continuation and does
not traverse Hollow Crown.

The run has one 590-second internal watchdog and a 600-second external limit. The
launcher stops only its owned process tree above 90% system commit or 400 system
processes. It records a unique profile, incremental telemetry JSONL, stdout, stderr,
engine log, two-second resource samples and a wrapper result. Every failure and the
earlier timeout run under `.artifacts/varga-focused-20260909T0500` remain retained.

## Minimal observer addition

The landed probe already separated an ordinary victory from its old timeout through
`trainer_outcomes`, `_last_combat_outcome`, defeat progression and live manager/fight
telemetry. It did not directly observe the newly landed finalized-death signal, so a
loss after human recovery could still require inference.

The only source adjustment is in `tools/probe_varga_focused.gd`. It connects a passive
observer to the production `PlayerDeath.finalized_death` signal and adds these fields
to existing telemetry: `finalized_death_events`, `trainer_battle_active`, and
`varga_defeat_flag`. The final row adds an observational `classification`, the last
manager outcome, trainer outcomes and defeat flag. It does not change the inherited
driver's return predicate or production code.

Expected distinctions:

- `victory`: probe result true, direct death count zero, manager outcome `won`, Varga
  finished outcome true and durable defeat flag true;
- `finalized_death_loss`: direct death count at least one, manager outcome `lost`,
  trainer inactive, Varga defeat flag false, and telemetry shows the local peer absent
  from the authority participant set after withdrawal;
- `duel_timeout`: direct death count zero, no published manager outcome, manager and
  trainer still active, participant retained, and the inherited 180-second failure;
- any other combination is `nonvictory_unclassified` and must be diagnosed rather than
  credited.

A finalized-death loss remains a process failure/non-victory; its classification is
diagnostic evidence that the corrected lifecycle withdrew instead of resuming combat.
A clean victory is valid combat evidence but does not exercise the death repair. The
fixture does not force either outcome.

The classifier label is an index, not an acceptance predicate. Interpretation must
independently verify its raw terminal fields, especially trainer inactivity, authority
participant removal, loss outcome and absence of the defeat flag.

## Launch-ready wrapper

Use a new, non-existing artifact root such as
`.artifacts/varga-focused-corrected-20260909T1630/`, set both `APPDATA` and
`LOCALAPPDATA` to its `runtime-profile`, and set
`TETHERBOUND_TELEMETRY_OUTPUT` to its `telemetry.jsonl`. Refuse launch if any Godot
process exists. Start:

```text
C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe --headless --path C:/Projects/Tetherbound --script res://tools/probe_varga_focused.gd --log-file C:/Projects/Tetherbound/.artifacts/varga-focused-corrected-20260909T1630/engine.log
```

The PowerShell guard should reuse the old launcher's owned-descendant tracking while
fixing two receipt weaknesses: refuse an existing runtime-profile rather than append
to it, and serialize terminal Godot count alongside start/end UTC, owned PIDs, guard
reason and any available exit code. Redirect stdout/stderr to distinct files and hash
all retained evidence after terminal process confirmation.

Before interpretation, require nonempty telemetry and a final `result` row. Scan the
three raw streams independently for `ERROR`, `SCRIPT ERROR` and `WARNING`; do not sum
the duplicated engine log into stderr counts. Record peak system commit, process count,
owned private/working bytes and the absence of every owned Godot PID before releasing
the lease.

## Frozen source identities

- focused probe with passive outcome classifier:
  `F97657D886FAD4888D4143ADC91E7CCC2F8FB13E20BE16CF0F0352D187B652D0`
- inherited continuous driver:
  `D3A0AF00F4B8F10242C8FF2054797067DF0D6671B26C38364525E9961E5CA13E`
- telemetry collector:
  `748DF91F4B1F95BDE7225DE30B134E097DC781D33655B39FFF961EC9B1AE0AAF`
- `player_death.gd`:
  `4888F42642B7B98132377E6555C4D0021F7BA5D6789F2B9FB1128139C7889945`
- `stormwood_combat_runtime.gd`:
  `93C43450C4D9716F2894AF6B267F60DEDCBD5B9749220B1F7FB4818B29306713`
- `stormwood_encounter_hub.gd`:
  `81A9C30B11CBE924DD42B0DEB9EBCC864F259D2662957CEDCB5F1FD8F5BDEE80`
- `stormwood_combat_manager.gd`:
  `38FA93D6DCE24056B42B3441128CF60BF5EB9DF36B4509B82DBF13F88A850FA2`

## Single execution result

The single run is retained at
`.artifacts/varga-focused-corrected-20260909T1637/`. It started
`2026-09-09T16:37:35.103Z` and ended `16:39:05.101Z`, about 90 seconds. Owned PIDs
were 17660, 4044 and 8216; all were absent and global Godot count was zero before the
lease was released. No guard fired. Peak system commit was 60.37%, peak process count
255, peak owned private bytes 1,179,086,848 and peak owned working set 1,229,967,360.
The wrapper serialized `exit_code:null`; the non-victory tool finish and final JSONL
row are the result authority.

The first Varga opponent resolved through controller input with manager outcome `won`.
During the second opponent, raw telemetry shows human health descending 64, 46, 28,
10, then 0 while the opponent remained alive at 111.5257/305.9 HP. JSONL line 107 is
the direct `finalized_death_observed` row, independent of the classifier. It records:

- `finalized_death_events=1` and human health `0/100`;
- manager `fighting=false`, state 0 and `_encounter_id=""`;
- manager outcome `lost` and trainer battle inactive;
- authority record phase `done`, participants empty, opponent still alive;
- Varga trainer outcome false and durable Varga defeat flag false;
- healthy active level-44 Mudsnout still at 358/358 HP.

Lines 108–110 retain the same loss, inactive trainer, false outcome and false defeat
flag. Line 111 labels that independently verified combination
`finalized_death_loss`, with `ok=false`. There was no 180-second timeout, remote camp
stall, immediate false win or reward. Because the probe returns as soon
as the trainer sequence reports loss, it observes finalized death before the later
fade/recovery relocation; existing native and two-peer tests own recovery and delayed
snapshot/rechallenge proof.

Raw logs are not clean. `stderr.log` has one expected inherited driver `ERROR` for
"trainer sequence ended in a loss", three `SCRIPT ERROR` lines, and 13 existing
interpolation/terrain-mipmap warnings. `engine.log` duplicates them; `console.log` has
zero error/script-error/warning lines. The three script errors occur only in terminal
observer captures after the decisive line 107: the shared telemetry collector still
casts `fight.opponent` after that object is freed. They do not erase line 107's complete
authority record, but no error-free observer claim is made and no replay is authorized.

The run retained 111 incremental JSONL rows. Evidence SHA-256 values:

- `telemetry.jsonl`:
  `85678757A6B08B6C76FB7969D5DF64C06D9FC5EA94098678040A16AE66C72893`;
- `console.log`:
  `5E2953128BEDB2CB46D2024B6BB34136B5DD1C70C91B82703D4284D2F7958582`;
- `stderr.log`:
  `A81447CCE44EB919728D288E82091EA9D283CDE8701AD4FFDD945BAEA7ADA8BA`;
- `engine.log`:
  `B5C215512140AB85BC7DEFFF94D3C84690B568AD10969D1762F8A5CE4FADF0A2`;
- `resources.csv`:
  `82AB2288BD486B37DF4EEF881BB9CDD49356FE9749AA70793D0704B4376F839D`;
- `result.json`:
  `A6C3EE20953C43C8FE3967D2345CD5AC5EE36231A124DF5D2F80FC47E03EAAD4`.

No production code changed, and no retry or campaign run was launched.

## Observer guard after the retained run

The three retained script errors had one exact cause. The collector checked that the
fight node was live, but nested `fight.get("opponent") as Node3D` directly cast the
already freed authority opponent. Its existing `live_body(raw: Variant)` guard was
used by the probe for ally/replica references but bypassed for this nested field.

After preserving the failed world logs, the collector now passes that one authority
Variant through `live_body()` before `_body()`. The focused initialized smoke frees
the actual authority opponent while leaving the fight, authority record, replica and
manager live. It requires invalid `authority_body` together with a valid replica,
active manager and intact active record.

The one authorized tiny smoke ran from `2026-09-09T16:42:00.264Z` to
`16:42:03.130Z`, exited 0, and ended with Godot count zero. It passed 16 checks in 930
ms with zero `ERROR`, `SCRIPT ERROR` or `WARNING` lines in console, stderr and engine
logs. This repairs future observation only; it does not retroactively fill world-run
JSONL lines 108–110 and no world replay followed.

Final observer source identities:

- telemetry collector:
  `A794B0A725C387DFD6F25678050C184AA8904C2C51525102D5DACC4EB5D59BF1`;
- focused collector smoke:
  `98A574D4BB297A23EB6201D6FDEDA61FD0372F4193CF863ADC87BA7EDE4129DD`;
- unchanged executed Varga probe:
  `F97657D886FAD4888D4143ADC91E7CCC2F8FB13E20BE16CF0F0352D187B652D0`.

Focused artifact hashes:

- `telemetry.json`:
  `E490C2FEAC1EB567B7FBC229893706AC2324C944F54A3F9A65BFD79A42224401`;
- `console.log`:
  `2AEE595D61EC94AC0436304E30920CE6DE396F8660DC9C63E89EFA255C1BE89C`;
- `stderr.log` (empty):
  `E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855`;
- `engine.log`:
  `899F16DCE88359C343AC20BC0136A9BFF37C42D3D729EEB0D9EE05E4FAD7B9EF`;
- `result.json`:
  `25A65336F17EE6235C1116ABC934DD233E1C49A462A44AD575B5F077C19FC68A`.
