# Cloudreach combat balance evidence — 2026-09-05

## Verdict and scope

**Keep the measured trainer-only power values 24 / 28 / 32 / 36. Retain the current
trainer levels.** The coordinator applied those candidate profiles after the
original ladder proved too weak. All **28 candidate fights won**, with no timeout
or script/resource error. The brawler now loses one or two creatures in demanding
segments; the spacer preserves all five but needs significant lead-creature
recovery. Actual input switching, all-five defeat, recovery and retry passed.
This closes the measured lack of attack pressure without HP inflation.

The original power-8 data let Terrapup clear the entire ladder by closing and
attacking without using the other four. Those before/after results are retained
below. Neither version contains an impossible base fight in this measurement.
Captain Veyra is evaluated as a **creature team only**; this is not a verdict on
the integrated finale's wind/relay mechanics or full chapter acceptance.

Evidence comes from `tools/_probe_cloudreach_combat_balance.gd`. It instantiates
the production Cloudreach encounter director/combat manager, real creature bodies,
the production camera rig and CombatHUD over an isolated 240 m collision floor.
It challenges the authored trainer specs through `begin_trainer_battle`, the same
entry the real trainer interaction uses. Movement, quick/charged attacks and run
use `tools/combat_pilot.gd`. A probe-only subclass replaces the base pilot's direct
switch call with `party_cycle` input, consumed by the production CombatHUD.
Production code owns AI, damage, fainting, automatic replacements, round resolution,
XP, reward payment and defeat markers. There is no direct damage/lethal seam,
private HP assignment, in-battle healing or combat-configuration override.

The probe is **combat evidence**, not continuous chapter acceptance. It does not
test trainer approaches/dialogue, world arena clearance, wind/relay hazards,
the travel between camps, wild encounters, physical camp UI, saving/loading or
controller camera acquisition. Camera aim is the existing pilot's idealized yaw
steering. The inherited switching policy reacts to the offensive matchup arrow;
it does not evaluate incoming type advantage or switch preemptively at low HP.
Damage retains the production randomized spread; individual numbers vary.

## Team and recovery assumptions

The five are Terrapup, Ripplet, Galewisp, Mosshell and Duskhush, all initially
level 25 with average individuality, default installed moves, fresh bond counters
and no stat boosts/candy. This is a plausible prepared Meadows team with a
conservative bond/move investment assumption. The same live five persist through
each complete ladder; only production victories and completed recovery award XP.
The original baseline and candidate spacer finish at levels
**29 / 27 / 27 / 27 / 27**, with Terrapup receiving the active fighter share.
Candidate brawler/switching runs finish at **27 / 27 / 27 / 27 / 27**: actual
faints/switches redistribute participation and XP. No authored expected-player
curve was fabricated.

Full recovery is assumed before Ila at Galefoot Waycamp, before Maela at Windscar
Flight Aerie Camp, before Tavi at Cliffhold Commons, before Voss at Summit Bivouac,
and after Voss by returning to that same bivouac before the captain. **Ila → Orrin
→ Senn has no intervening heal.** The optional survivors' refuge is not assumed
available. Recovery uses the public `home_recovery.rest` operation on each member;
it represents completing each needed bed rest, not an assertion that ordinary
player sleep automatically heals five. Recovery UI/time/travel are unmeasured.

No consumables are spent. Per-fight and per-camp JSON records include the remaining
HP of every member and the equivalent number of the real 80-HP Ridge Tonics and
50%-HP Revives needed for full recovery. This is a camp-avoidance estimate, not
observed item use. No owner save is read or written.

## Original power-8 trainer results

The first complete three-pilot baseline measured the following. HP is the total
remaining HP divided by the total maximum HP of all five; therefore it must be
read alongside the **zero faints and zero switches** finding. In these rows the
lead absorbs all damage. All 21 base-trainer outcomes were victories.

| Trainer | Opposing levels | Spacer seconds / HP left | Brawler seconds / HP left | Brawler hits dealt/taken | Brawler damage taken |
|---|---|---:|---:|---:|---:|
| Ila | 19, 21 | 23.0 / 99.1% | 18.7 / 98.2% | 20 / 4 | 23.8 |
| Orrin | 21, 23 | 26.0 / 97.0% | 20.9 / 95.1% | 25 / 6 | 41.2 |
| Senn | 22, 24 | 30.1 / 95.0% | 24.6 / 90.9% | 30 / 7 | 54.5 |
| Maela | 23, 25 | 27.5 / 98.3% | 21.1 / 96.7% | 25 / 6 | 43.6 |
| Tavi | 26, 28, 29 | 51.4 / 97.0% | 40.9 / 91.9% | 50 / 12 | 109.6 |
| Voss | 29, 30, 31 | 57.4 / 95.1% | 44.4 / 90.0% | 55 / 14 | 135.0 |
| Veyra, roster only | 31, 32, 34 | 56.1 / 96.0% | 44.0 / 90.0% | 54 / 14 | 138.1 |

The switching-enabled Terrapup baseline never elected to switch; its results were
within ordinary damage-RNG variation of the brawler. A separate **Ripplet-leading,
switching-enabled** seven-rung run exited 0: the pilot pressed `party_cycle` once
in Ila's battle, production combat switched it to Terrapup, and it won every
subsequent fight without another switch or any faint. Its times were
16.0 / 20.4 / 23.5 / 22.0 / 40.9 / 44.4 / 44.8 seconds, with 90.6–97.6% party HP
left after each fight. This proves the input switch path and also demonstrates
how little continued roster choice the original base ladder demanded.

The initial baseline's full-team HP deficit after the unhealed opening three was
121.6 HP for the brawler: two Ridge Tonics replace the next camp recovery, with
no Revive required. Maela costs one tonic; Tavi, Voss and the captain each cost
two. The spacer's comparable deficits all fit inside one tonic. These encounters
did not establish meaningful five-member recovery pressure by themselves.

## Candidate power-24/28/32/36 results

The coordinator created `trainer_scout`, `trainer_controller`, `trainer_pursuer`
and `trainer_ace`, gave them powers 24/28/32/36 respectively, and rewired only the
seven base trainer sequences. Existing timing, movement, levels, teams and wild
profiles remained as authored. The probe did not modify these values at runtime.

All rows below won. Faints in Senn include the preceding unhealed Ila/Orrin fights;
the other later trainers begin after their named recovery. Damage lists dealt /
taken and is actual production hit telemetry, including possible overkill.

| Trainer | Spacer seconds / HP / faints | Brawler seconds / HP / faints | Brawler hits dealt/taken | Brawler damage dealt/taken |
|---|---:|---:|---:|---:|
| Ila | 23.05 / 96.9% / 0 | 18.70 / 93.4% / 0 | 20 / 4 | 412.6 / 87.1 |
| Orrin | 26.02 / 88.4% / 0 | 20.88 / 80.7% / 0 | 25 / 6 | 470.7 / 168.6 |
| Senn | 30.88 / 81.4% / 0 | 23.98 / 58.6% / 2 | 33 / 8 | 479.8 / 336.8 |
| Maela | 27.12 / 95.5% / 0 | 18.53 / 83.5% / 0 | 25 / 5 | 477.4 / 218.6 |
| Tavi | 51.35 / 87.7% / 0 | 32.75 / 75.0% / 1 | 42 / 8 | 798.0 / 342.3 |
| Voss | 55.52 / 81.2% / 0 | 40.10 / 61.8% / 1 | 52 / 13 | 835.2 / 537.3 |
| Veyra, roster only | 56.95 / 84.4% / 0 | 44.77 / 58.6% / 2 | 61 / 15 | 930.1 / 636.3 |

The spacer's apparently high five-member percentage is not a free clear: all
damage still lands on Terrapup. Its HP after Senn and Voss is below 20% of its
own maximum. The candidate therefore gives camps and item preparation a purpose
even when the player reads the telegraphs well.

The candidate's switching-enabled default run wins seven and records two voluntary
`party_cycle` switches, in Senn and Voss. It finishes Senn with one faint, compared
with the brawler's two. Its upper results are Tavi 32.75 s / 74.5% / one faint,
Voss 41.28 s / 65.5% / one faint, and captain 40.38 s / 64.8% / one faint. This is
evidence that the real switching path participates in successful combat; the
production random spread and resulting active-creature sequence mean it is not
an exact deterministic attribution of every saved HP point to switching.

A separate Ripplet-leading candidate run also wins all seven with no errors.
It records three voluntary switches (Ila, Senn, Voss), one faint at Senn, Tavi,
Voss and the captain, and times 16.83 / 20.85 / 23.08 / 18.55 / 33.95 / 39.25 /
40.47 seconds. The captain ends at 65.5% five-member HP.

The brawler now needs the following item equivalents to restore the team after
each recovery boundary: **Senn four tonics + two Revives; Maela three tonics;
Tavi four tonics + one Revive; Voss five tonics + one Revive; captain four tonics
and two Revives.** The spacer needs four / one / three / four / three tonics at
those same boundaries, with no Revives. Actual camps offer an alternative to
spending that stock. Ila and Orrin each award two tonics: using those four before
Senn could restore the observed 255.7-HP opening damage rather than entering Senn
nearly fainted. That preventive item use is an arithmetic implication, not an
item-use interaction exercised by the probe.

## Actual loss and retry

A fresh level-25 five deliberately supplied **no combat input** against candidate
Ila. Production AI dealt **50 hits / 1437.1 damage over 158.83 seconds**, fainted
all five, performed four automatic replacements, and emitted `trainer_lost`
without granting a victory or trainer reward. The production challenge check
returned false while all five were fainted. Full Galefoot recovery then allowed
an ordinary retry, won through brawler input in **18.68 seconds**, with zero
faints and the normal 45-coin reward. The retry verdict is `passed: true` and
the complete candidate suite exits 0.

For comparison, the original power-8 unattended wipe took 436.45 seconds,
141 hits / 1345.3 damage; its actual recovery/retry also passed. Neither run
used synthetic damage, a private faint flag assignment or a lethal test seam.

## Exact tuning recommendation after measurement

The original profiles overrode timing and movement but inherited
`combat.json`'s enemy attack power of 8. The player has quick power 9 and charged
power 38. Raising enemy levels only moves a bounded attack/(attack+defence) ratio.
The measured profile-power candidate closes that pressure gap while preserving
the visible wind-up/recovery rhythm and existing HP curve.

1. **Keep** the coordinator's trainer-only profiles at scout **24**, controller
   **28**, pursuer **32**, ace **36**, with their current timing/movement values.
   Continue using the original profiles for wild habitat bodies, whose pressure
   was not measured here.
2. **Retain every current trainer level** listed in the original-results table.
   The initial idea of raising the below-arrival early levels is not supported
   after the candidate run: the unhealed opening already causes two brawler
   faints, and late encounters already test replacements. Increasing levels and
   damage together would add unmeasured pressure and alter natural XP pacing.
3. Keep the currently authored recovery opportunities and early tonic rewards.
   Verify their real route/UI use during continuous play. The no-consumable probe
   deliberately exposes the cost of ignoring preparation; it does not imply every
   ordinary player must lose creatures before Senn.
4. Measure the captain with the actual finale controller and arena before any
   additional boss tuning. The roster already costs the brawler two creatures;
   wind/relay displacement can add pressure that this fixture does not model.

The evidence agent changed only the new probe and this report. The coordinator
owns the measured shipping profile changes. No species, trainer level, reward,
shared combat rule or type-chart change is recommended from these results.

## Reproduction and evidence status

Windows executable:
`D:\Tetherbound-tools\godot\Godot_v4.7-stable_win64_console.exe`.
Run from `D:\Tetherbound-source` on `codex/cloudreach-cliffs`. The initial task
inspection found `main` at `75bb1dc7db36fb4452a746410f45e9ac77699300` and branch HEAD
at `edabce6bfe2aac513ca2a6c7e3fd5336ebdead5a` with shared in-progress production
integration changes. Raw reports record actual authored opposition and per-hit
totals; updated probe output also includes hashes of its source configuration.

```powershell
Get-Process *godot* -ErrorAction SilentlyContinue
# Wait for other world/GPU/fixture processes to finish before either command.
& 'D:\Tetherbound-tools\godot\Godot_v4.7-stable_win64_console.exe' --headless --path . --fixed-fps 60 --script tools/_probe_cloudreach_combat_balance.gd -- --loss-retry --tag=trainer-power-candidate
& 'D:\Tetherbound-tools\godot\Godot_v4.7-stable_win64_console.exe' --headless --path . --fixed-fps 60 --script tools/_probe_cloudreach_combat_balance.gd -- --pilot=brawler_switch --lead=1 --tag=trainer-power-candidate
```

Raw JSON lives under `ralph/reports/CLOUDREACH-COMBAT-BALANCE-0905/` and is telemetry,
not shipping source. Commit this verdict and the probe, not telemetry payloads.

- Initial single-Ila fixture: exit 0, no script/resource errors after correcting
  one probe variable's inferred type during initial compilation.
- Initial default three-mode baseline + actual loss/retry: all **21 scoped fights
  and the loss/retry completed**, but overall exit 1 because a newly authored
  optional Tavi rematch appeared in `trainer_specs`; the generic iteration also
  attempted that eighth encounter without its distinct side-chain conditions.
  The probe now explicitly enumerates the assigned seven base encounters. This
  failure is preserved as a harness finding, not presented as a clean pass.
- Ripplet-leading, switching-enabled seven-rung run: **exit 0**, `errors: []`,
  all seven wins and one real voluntary switch, no script/resource errors.
- Final scoped candidate default + loss/retry: **exit 0**, `errors: []`,
  21/21 active victories and actual loss/retry passed, no script/resource errors.
- Final candidate Ripplet-leading switch suite: **exit 0**, `errors: []`,
  7/7 victories and three voluntary input switches, no script/resource errors.

Candidate raw files:
`mixed-spacer-brawler-brawler_switch-lead0-trainer-power-candidate.json` and
`mixed-brawler_switch-lead1-trainer-power-candidate.json`. The default candidate
run records encounter-config SHA-256
`06fd13d236db6da5cacd6c929e3cb1c90fdb0bee0d95d5038ae5e5243db7e33f`.

Continuous world combat/approach, physical camp service, integrated finale balance
and owner controller play remain separate acceptance evidence.
