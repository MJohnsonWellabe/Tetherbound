# Cloudreach combat balance evidence — 2026-09-05

## Current verdict after merged W23 baseline

**Retain trainer-only powers 24 / 28 / 32 / 36 and all existing levels.**
The final rerun after the coordinator's VFX fixes wins **28/28 base-ladder
fights plus the actual recovery/retry**, exits 0 twice, and has **no engine errors
or warnings** in either log. Final measured values are recorded below; the first
merged pass is preserved separately because its errors exposed real defects.
The earlier candidate measurements below predate main's W23 difficulty merge and
must not be used as current balance numbers. The remeasurement starts at branch
HEAD `1f1f23652244df9c687566a7cc7d57b7d4a3d6ee`, containing main
`2cd711eb1`. Main now multiplies each authored opponent power by **1.6 after the
body profile merge**, and trainer-owned creatures inherit a **0.7-second first
attack delay**. Thus Cloudreach's effective trainer powers are
**38.4 / 44.8 / 51.2 / 57.6**. The global combat baseline is preserved.

The first merged run won all **28 base-ladder fights** (three Terrapup-leading
policies and a separate Ripplet-leading switching policy). No active fight timed
out or wiped the team. A fresh passive five did actually wipe and then recover
and win a retry. These are combat outcomes, not a claim of clean engine logs:
this first pass exposed the VFX lifecycle failures described below.

All percentages below are remaining HP across the five. Each later fight starts
after the existing named recovery boundary; Ila, Orrin and Senn are unhealed.
Faints therefore accumulate across those opening three. No consumables were used.

| Trainer | Spacer seconds / HP / faints | Brawler seconds / HP / faints | Switching seconds / HP / faints |
|---|---:|---:|---:|
| Ila | 21.17 / 100.0% / 0 | 16.82 / 91.9% / 0 | 18.33 / 89.3% / 0 |
| Orrin | 25.83 / 89.6% / 0 | 21.32 / 74.6% / 1 | 19.70 / 74.9% / 1 |
| Senn | 30.15 / 77.5% / 1 | 20.77 / 46.9% / 2 | 21.82 / 47.5% / 2 |
| Maela | 28.35 / 81.1% / 0 | 20.18 / 74.8% / 1 | 27.00 / 67.5% / 1 |
| Tavi | 46.27 / 80.7% / 1 | 39.32 / 36.1% / 3 | 40.55 / 39.5% / 2 |
| Voss | 48.20 / 58.2% / 1 | 46.47 / 34.6% / 3 | 47.22 / 32.3% / 3 |
| Veyra, roster only | 57.88 / 70.7% / 1 | 45.73 / 12.0% / 4 | 48.13 / 21.0% / 3 |

This is materially more pressure than the pre-merge candidate: the brawler's
captain recovery estimate rises from four tonics and two Revives to **eleven
tonics and four Revives**. The full named rest immediately before the captain
matters. Reading telegraphs remains valuable: the spacer finishes the same roster
at 70.7% party HP with one faint, versus the brawler's 12.0% and four faints.
The switching pilot only uses the offensive matchup arrow; it does not react to
low HP or incoming type advantage. It is not an optimal defensive player.

A separate observer-only hit audit adds every incoming production hit, target,
target level/max HP and damage fraction to the probe's JSON. The manager emits
this signal before replacing a fainted creature, so the denominator is the actual
target, including lethal overkill. It changes no combat behavior. The audit wins
seven of seven with the Ripplet-leading switching policy. Maximum observed hit
fractions by trainer are **20.4 / 15.8 / 32.3 / 25.9 / 36.7 / 32.2 / 36.4%**.
The largest is Tavi's Galecrest hitting level-26 Galewisp for 84.42 of 230 HP.
These observed blows remain below D77's half-full-health ceiling. That audit's
captain ends at 37.2% party HP and three faints, illustrating the production RNG
and replacement-sequence variability; one sample is not a statistical win rate.

Taken together, clean combat resolution, the surviving telegraph skill gap and
sub-half-health blows do **not** justify automatically dividing Cloudreach's
powers by 1.6. Retain the harder measured ladder. The remaining risk is the
**integrated captain arena**: its wind/relay displacement is absent here, and the
brawler has little spare health. This report does not approve full finale balance,
wild attrition, physical camp UI or continuous chapter acceptance.

The merged passive loss is **97.65 seconds, 31 hits, 1449.4 damage**, five faints
and four automatic replacements, with `trainer_lost`, zero reward, and challenge
refusal while all five are fainted. Public Galefoot recovery permits a real input
retry: **17.62 seconds, zero faints, 45 coins**, `passed: true`. No victory flag,
private HP assignment, lethal seam or owner save is used to manufacture outcomes.

### Runtime failures and exact evidence

The initial default and lead-1 commands both exited 0 with probe `errors: []`,
but their logs contain `body_glow.gd:143` accessing a freed instance during
cleanup, `level_up_flourish.gd:162` ending an empty ImmediateMesh surface, and
shutdown resource/leak diagnostics. Probe outcome success does not erase those
engine failures. The coordinator owns their production fixes; the balance agent
changes only observational probe telemetry and this report. The hit-audit process
loaded after the body-glow fix but before the flourish fix and still records the
empty-surface error. All failure logs remain in the local report directory.

Source configuration SHA-256 for these merged runs:

- Encounters: `06fd13d236db6da5cacd6c929e3cb1c90fdb0bee0d95d5038ae5e5243db7e33f`.
- Shared combat: `ed339b53fc7e8d63511c4512d4537d3afb47192bf8f0933cf57d190cb55d37b2`.
- Chapter: `dd30fdd666ec6d8e551bd333c86e82113675394cea49f45b97e9be0993e57335`.
- Progression: `45875dd868ed32ffdaa410b5ed740a7209140ea6675081a55b8d10faf9c2e61e`.

Raw files under `ralph/reports/CLOUDREACH-COMBAT-BALANCE-0905/`:
`mixed-spacer-brawler-brawler_switch-lead0-merged-main.json`,
`mixed-brawler_switch-lead1-merged-main.json`, and
`mixed-brawler_switch-lead1-merged-main-hit-audit.json`.
Their logs use `merged-main-default.log`, `merged-main-lead1.log` and
`merged-main-hit-audit.log`. Other headless suites ran concurrently; simulation
time/hit metrics remain usable, wall-clock performance is not measured.

### Final clean rerun after VFX fixes

The exact same authored encounters, team assumptions and global combat config
were rerun after the coordinator fixed both VFX lifecycle defects and passed its
dedicated live regression. The trainer powers were not changed. Both commands
exit **0**, both JSON files have `errors: []`, all **28/28 base fights win**, and
neither log contains `ERROR` or `WARNING`, including shutdown. The final sample
confirms the pressure seen above without the earlier VFX failures.

| Trainer | Spacer seconds / HP / faints | Brawler seconds / HP / faints | Switching seconds / HP / faints |
|---|---:|---:|---:|
| Ila | 21.17 / 100.0% / 0 | 17.62 / 89.8% / 0 | 16.82 / 92.6% / 0 |
| Orrin | 25.80 / 89.8% / 0 | 18.95 / 74.7% / 1 | 19.72 / 77.9% / 1 |
| Senn | 29.70 / 77.5% / 1 | 20.77 / 47.8% / 2 | 20.58 / 54.0% / 2 |
| Maela | 29.63 / 80.4% / 0 | 20.98 / 75.0% / 1 | 27.02 / 71.8% / 1 |
| Tavi | 47.08 / 80.7% / 1 | 39.77 / 35.4% / 3 | 40.58 / 30.5% / 2 |
| Voss | 47.22 / 63.1% / 1 | 46.02 / 29.3% / 3 | 46.77 / 32.3% / 3 |
| Veyra, roster only | 53.60 / 64.3% / 1 | 46.65 / 12.1% / 4 | 48.02 / 19.7% / 3 |

The separate Ripplet-leading switching run wins all seven in
**15.93 / 20.08 / 21.50 / 26.65 / 41.40 / 46.48 / 45.13 seconds**. It records
seven voluntary `party_cycle` switches (Ila one, Senn one, Tavi one, Voss one,
captain three), ending the captain at **32.1% HP and three faints**. The default
switching ladder records six voluntary input switches. The brawler's captain
recovery estimate is ten tonics and four Revives; the spacer's is five tonics and
one Revive. These remain estimates, not item-use evidence.

The greatest observed incoming hit across the final 28 fights is **39.85%**:
Tavi's Galecrest deals **104.59 damage** to level-26 Ripplet's **262.5 max HP**.
The Ripplet-leading suite's maximum is 38.08%. No measured hit exceeds half of
the actual target's maximum HP. This is observed sample evidence, not a proof for
every species/level/matchup combination or every RNG seed.

Natural final levels, in the initial team order: spacer **28/27/27/27/27**,
brawler **26/27/27/27/27**, switching **26/27/26/27/27**, and Ripplet-leading
switching **26/27/27/27/27**. Faints and participation redistribute real XP.

The final unattended loss takes **100.72 seconds, 32 hits, 1464.8 damage**.
All five faint, four automatic replacements occur, `trainer_lost` fires, and no
coins are paid. Challenge access is false while the five remain fainted. Public
Galefoot recovery then permits the input-driven retry: **16.82 seconds, 92.6%
team HP, no faints, 45 coins and a victory callback**. `retry.passed` is true.

Reproduction from `D:\Tetherbound-source`:

```powershell
& 'D:\Tetherbound-tools\godot\Godot_v4.7-stable_win64_console.exe' --headless --path . --fixed-fps 60 --log-file 'D:\Tetherbound-source\ralph\reports\CLOUDREACH-COMBAT-BALANCE-0905\merged-main-final-default.log' --script tools/_probe_cloudreach_combat_balance.gd -- --loss-retry --tag=merged-main-final
& 'D:\Tetherbound-tools\godot\Godot_v4.7-stable_win64_console.exe' --headless --path . --fixed-fps 60 --log-file 'D:\Tetherbound-source\ralph\reports\CLOUDREACH-COMBAT-BALANCE-0905\merged-main-final-lead1.log' --script tools/_probe_cloudreach_combat_balance.gd -- --pilot=brawler_switch --lead=1 --tag=merged-main-final
```

Final telemetry filenames are
`mixed-spacer-brawler-brawler_switch-lead0-merged-main-final.json` and
`mixed-brawler_switch-lead1-merged-main-final.json` in the same local report folder.
All four configuration hashes above are unchanged. Final probe SHA-256 is
`fa99be8f1603e3a404afc5d2f347add37e1d251ab4d38e00458787a0cb0888b9`, and
`wild_creature.gd` is
`3c9349635554d7e3cde20b0a7ca010bc6b75e1c70bc3eabafbc9bdc99a291291`.
The coordinator's fixed VFX sources at measurement time are `body_glow.gd`
`a81b010e8ef592b05bdd3d5a6ddefa865bc5b1d664579ab25e5f9d12dffc8229` and
`level_up_flourish.gd`
`26ee6060b999c202843d0184eaf1679af8830000ded772eee1bf8e34b9fe0bd6`.

## Historical pre-W23 verdict and scope

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
