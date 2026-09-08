# Stormwood Wave 1: Varga and route pickup proved; Fenn overlap repaired

## Runtime on landed main

Base: `75aaccca0210a9bc1ac0f16bac687d8557f0aacf`, on the Wave 1 integration
branch. The first `smoke_stormwood_continuous.gd` invocation terminated exit 1
at the newly observed Ondra interaction boundary. It was not rerun unchanged.

The uninterrupted route earned arrival, Hesk/Tamsin dialogue, the sheltered
Break, six harvested glass for pair A and real arch travel, route 03, Maren's
three won rounds/Verge switch, Dace's three won rounds/Hollows switch, the
measured Pools charged window with two exact +3 receipts and one tool wear
each, paid pair B, route 07 and Bryn's Act-I completion. Ordinary wild losses
were handled through the existing party controls, not health/position writes.

**Varga's relocation is now physically proved.** The ordinary Bryn-to-Varga
walk covered 114.4 m in 3.019 seconds wall time under the disclosed accelerated
simulation. The exact trainer prompt activated; all three rounds explicitly
reported `outcome=won`, the host published the finished victory, and the
chapter's `stormwood:varga_defeated` event arrived. This closes the previous
Bryn/Varga overlap reproduction on the actual player path.

The route then walked to Keeper Ondra. Its first failure was precise: the
co-located `stormwood_pickup_route_09` provider offered **Take Great Candy** at
1.749 m while Ondra's prompt was 1.81 m away. The requested dialogue never won
the arbiter. No Ondra recipe or Crown progress is claimed for this run.

Logs, all under `%TEMP%`:

- `wave1-stormwood-varga-75aaccca0-engine.log`
- `wave1-stormwood-varga-75aaccca0-console.log`
- `wave1-stormwood-save-before.json`
- `wave1-stormwood-save-after-varga.json`

The eight default campaign files under `user://saves`, `worlds` and
`characters` had identical before/after path and SHA-256 manifests: zero
differences. The wrapper bound its unique scratch SaveGame before its first
yield/reset. The only `ERROR:` was the explicit harness assertion identifying
Ondra's competing pickup; there was no native/script runtime error. The Godot
process ended and the RAM slot was released.

## Bounded harness change

Collect route 09 through its real one-time provider before requesting Ondra,
matching the already established route-07-before-Bryn ordering. The existing
pickup helper previously assumed `good_candy`; it now reads the exact item and
count from the production ordinary-pickup catalogue and cross-checks the live
pickup payload before interaction. Each collection requires both its durable
receipt and the exact authored inventory gain. This preserves route 03/07 and
correctly checks route 09's `great_candy`.

The wrapper also accepts `--through-crown`. Only a successful, physically
earned Ondra prefix can invoke the existing paid Crown helper with that same
live tree, world and Game. Default behavior still ends at Ondra. The prefix's
20-minute watchdog and all per-action limits remain unchanged; the additional
Crown construction segment receives its own separate 20-minute bound. No
progression grants, reload, travel call or direct placement was added.

Parser/loading and focused checks pass: **14 tests / 118 assertions**, zero
failures/native errors, in `wave1-stormwood-route09-crown-focus-r2-console.log`
and its matching `-engine.log`. An initial source parse found that an outer
static helper cannot be called unqualified from inner `Segment`; moving it into
that class corrected the scope before these passing checks. No world was
launched on the malformed source.

## Second runtime: pickup earned, overlapping trainer exposed

The changed `--through-crown` run terminated exit 1 at Ondra, after repeating
the full prefix and Varga's three won rounds. Route 03/07 each earned exact
`+1 good_candy`; route 09 earned exact `+1 great_candy`, each with its durable
receipt. The pickup repair is physically proved. Removing that one-time
provider exposed the next actual competitor: `StormwoodTrainers/Fenn/Interactable`
offered **Challenge Fenn** at 1.550602 m versus Ondra's 1.56 m prompt. The
recipe remained unearned and the Crown helper correctly did not start.

Logs: `%TEMP%/wave1-stormwood-ondra-crown-console.log` and matching
`-engine.log`. Before/after manifests `wave1-stormwood-ondra-save-before.json`
and `wave1-stormwood-ondra-save-after.json` again cover eight unchanged default
campaign files, zero SHA-256/path differences. Terminal exit 1 was confirmed;
Godot ended and RAM was released. The explicit failed Ondra assertion was the
only error category; no native/script error was found.

## Narrow production placement repair

Catalogue evidence showed `rodline_keeper_fenn` and `keeper_ondra` at the exact
same `[-160, 34.69, 2700]` coordinates. Their NPC body capsules each have a
0.36 m radius; Fenn's trainer prompt has radius 4.2 m and Ondra's normal story
prompt has radius 3.8 m. This is a production collision, not a reason to change
stances or interaction precedence again.

Only Fenn's trainer position moves to `[-180, 35.5290401887535, 2705]`, a
20.6155 m local move. The production heightfield gives ground Y
35.3790401887535; the established catalogue clearance remains +0.15 m.
Ground samples at the four capsule-radius offsets range from 35.32527 to
35.43836 m, all below the authored root. The site is on the same conductor-road
shoulder: 14.0195 m from the arriving leg and closer to the departing leg,
within the unchanged 30 m authored road bound. It does not overlap another
authored NPC/trainer, StillGrove camp, or the nearby Crown footing. The trainer
remains optional in Conductor Run with unchanged roster, strength and gates.

The pure heightfield probe is `%TEMP%/wave1-fenn-near-ground-engine.log`.
`test_stormwood_fenn_clearance.gd` checks disjoint production prompt ranges,
local grounded road placement and the capsule footprint. It reuses the Varga
route checks. Together with the trainer census/data and pickup contracts:
**10 tests / 540 assertions, zero failures**, terminal exit 0, no native/script
errors (`wave1-fenn-clearance-focus-console.log` and matching `-engine.log`).
This is analytic placement evidence, not Terrain3D or live dialogue proof.

## Remaining proof and disclosure

The Fenn relocation and composed Crown helper await the next assigned full-world
RAM slot. No unchanged prefix rerun is proposed. Next command:

```text
godot --headless --path . --log-file <unique-engine-log> --script tests/smoke_stormwood_continuous.gd -- --through-crown
```

Fingerprint the default campaign files again before/after. Require earned
Ondra recipe before Crown, then the named Capacitor encounter, real materials,
two paid frame crafts and one paid green-ghost arch placement. Stop and diagnose
the first physical failure. The helper currently ends at construction: Crown
travel, guardian/Wen/Rootgate and the Dynamo remain outside this evidence.

This remains a chapter-boundary fixture: synthetic completed-Cloudreach facts,
a five-member level-44 party and three tools, with 8x simulation acceleration.
It is not an earned fresh-opening-to-Stormwood handoff. No Stormwood progress
or post-entry materials are seeded. The root's future continuous campaign must
provide the actual carried state rather than cite this seam as fresh-save proof.
