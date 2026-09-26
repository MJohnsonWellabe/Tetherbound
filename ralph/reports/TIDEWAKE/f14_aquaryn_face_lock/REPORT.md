# F14#0: Aquaryn with Ripplet leading, the non-numeric cause (ratio 0.61)

## Cause
Aquaryn's phase attacks are ordinary strikes, and an ordinary strike never locks its heading. `wild_creature.gd::_enter` only builds a lockable `_selected_attack` for named or charged attacks (`charged_every > 0`). So the Broken Wake frontal jet tracks the target through its whole 1.7 s tell. That jet is 16 m long and 28° wide, below 35% HP (BOSSES §4.8: "leaves both flanks exposed").
- A sidestep can never leave the cone. The only escape is outrunning 16 m.
- COMBAT §5's target, "facing tracks during the first half of windup, then locks", is not built for ordinary strikes.

**Measured with production bodies** (harness, Ripplet lead, L43; a scratch probe, not committed):
- **Before, 6 seeds:** all 21 reader hits landed in Broken Wake, at 10–15 m, while the reader backed straight down the jet line.
- **With a sidestep but no lock, 6 seeds:** 19 hits, all still in Broken Wake. The tracking jet follows the sidestep.

## Fix (applied in 5cb1ce1 under the coordinator's 21:15 shared-file grant)
- **`shared_face_lock.patch`** (`scripts/creatures/wild_creature.gd`, `scripts/creatures/water_alpha_body.gd`):
  - `face_lock_fraction` becomes an allowed override key;
  - an ordinary telegraph whose config authors it keeps a copy of its spaced profile as the selected attack, so its heading locks after that fraction of the tell;
  - Aquaryn's phase override passes the phase's value.
  - Absent or 0 is today's behaviour, byte for byte.
- **Tidewake-owned:**
  - `data/config/water_alpha.json`: `face_lock_fraction: 0.5` on each phase (COMBAT §5 "first half");
  - the harness's AlphaPilot passes the phase value;
  - `tests/helpers/combat_depth_pilot.gd` READER: when leaving the drawn cone sideways is shorter than leaving its reach, it steps across the axis, and bursts once the cone has locked. It also stores a copy of the telegraph config.

## Result (24 seeds, `--case=aquaryn --starter=ripplet --party-level=43`, the shared patch applied locally)

| Policy | Win | Median lead cost | Reader/masher ratio |
|---|---|---|---|
| MASHER | 1.00 | 0.390 | |
| READER | 1.00 | 0.123 | **0.32** (named-wild rule ≤0.55: PASS; was 0.61) |

- **Tells:** 1.25–1.70 s. **Largest hit:** 6.6% of HP.
- **Raw data:** `A_aquaryn_ripplet.json` and `RUN_aquaryn_ripplet.txt`.

## Limits
- The shared change landed on the lane branch in 5cb1ce1, with `tests/test_water_alpha_face_lock.gd` (2 of 3 fail with it reverted).
- Once locked, Aquaryn also holds its heading through recovery, as a named heavy does. A phase change mid-tell resolves with that tell's frozen profile, and the next tell uses the new phase.
- The pilot change is only exercised on Aquaryn here. It applies to any narrow long cone, so the other named cases should be re-run once it lands.
- Terrapup and Galewisp leads with the lock were not re-run. They passed before (0.46 and 0.29 at 24 seeds on main), and the lock can only widen the reader's options.
- Surface-channel runs are not reproduced on the flat fixture (unchanged limit).
