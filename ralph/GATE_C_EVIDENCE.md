# Gate C evidence — progression / reward / ecology backbone

Recorded 2026-08-22, branch `claude/gatec-progression-curves-ep2j4x`.

`ralph/ACTIVE_GAME_PLAN.md`'s Gate C is the cross-chapter backbone every regional
package inherits. Its own completion rule is the last line of that section:

> the chapter-wide maps/curves must exist before late-region tuning is called final.

Unlike Gates A and B it defines no continuous play segment of its own, and it
explicitly permits its children to run in parallel. So this file records the
state of each owning prompt against its own acceptance list, and — as important
— what is **not** evidenced here.

## Standing caveat: no engine in this lane

This work was done in an environment with no Godot binary. Every claim below is
one of:

- **DATA** — verified by the shipped data/config and by the GDScript suite,
  which now runs green. Strong for structure, silent about how it feels to play.
- **CODE** — the implementing code was read and named.
- **UNVERIFIED** — ships, but wants the engine or a play session.

**UPDATE — the suite has now been run.** A Godot 4.7-stable binary (the version
`ci.yml` pins) was fetched into this lane and the full suite executed:

- shard 1/2 — 573 tests, 327,411 assertions, 0 failed
- shard 2/2 — 627 tests, 388,000 assertions, 0 failed

Running it caught three things reading could not. `test_spawns_data.gd`'s
nocturnal-role check had a last-wins bug (`found = ...` instead of
`found = found or ...`) that only passed while every duskhush in the game was
night-gated. `test_quest_log.gd`'s count check assumed the objective chain was
two entries long. And `data/scatter/playground` went stale the moment
`vegetation.json` changed, which would have cost a ~60s full-corridor scatter
computation on every boot. All three are fixed and the bake is re-committed.

This branch is still `claude/**`, which `ci.yml` does not watch, so CI has not
run it — but the same suite CI runs has, on the same engine version. The new
tests are `test_chapter_rewards.gd` (5), `test_chapter_content_map.gd` (4), four
additions to `test_quest_log.gd`, two to `test_dialogue_runner.gd`, and one
rewritten assertion each in `test_harvest.gd` and `test_spawns_data.gd`. All were
confirmed to execute rather than being silently skipped.

## Owning prompts

### 57 — team progression curve · COMPLETE
`GATEC-CURVE` (5aa03ebd) authored `data/config/chapter_curve.json`,
`chapter_curve.gd` and per-region wild escalation. Not re-done here.

This lane corrected the instrument those numbers were measured with.
`tools/_probe_pacing.py` was reporting 5.68 projected hours and a verdict of OVER
the 3-4 hour D42 target, on four pre-OW5D coordinate literals and two mis-ordered
beats. Corrected: **1.86h floor, 3.73h projected, ON TARGET** (DATA). No content
was retuned to get there, and the level model never read a coordinate, so the
curve's measured team bands (3→8, 8→10, 10→13, 13→16, 16→20) reprint unchanged.

### 58 — reward economy · COMPLETE
- every material the world yields is a recipe input, a build cost or shop stock — no orphans (DATA)
- money has a reachable sink: 890 coins against nine TMs at 120-300 (DATA)
- Rootstone 28 supply / 12 critical-path demand; Ironwood 15 / 4 (DATA)
- **fixed:** `tm_earthshatter`, `tm_leviathan_surge`, `tm_heavenfall` — one apex TM per type, complete move and compatibility data, obtainable nowhere. Now sited one per type in the late region that owns it (DATA)
- deliverable: `data/config/chapter_rewards.json`, 19 rows
- One row answers "no" to *does the player understand this reward when they get it* — the Heartstone. Left deliberately, reasoning in the file.

### 59 — trainer journey · COMPLETE
- **fixed:** Band 2 fielded no trainers; the first Team Tether fight was in Band 3, 1300m past the region that introduces the faction. Added Dorn (quarry) and Pell (warrens mouth) (DATA)
- 17 trainer battles, top of the prompt's 12-17 target; every region fields opposition (DATA)
- escalation from L2 practice to the Warden's L20 ace holds (DATA)
- UNVERIFIED: whether each fight *teaches* something distinct — a play judgement

### 60 — wild ecology journey · COMPLETE for the chapter-wide plan
- **fixed:** bands 3 and 5 had zero spawns, band 4 had one cluster across 2240m. 19 clusters / 45 creatures added; every region now populated (DATA)
- night and weather ecology now exist past Band 2 (DATA)
- DEFERRED BY THE PROMPT: "site roughly a handful of memorable alpha/elder/special encounters" coordinates PW2, whose own backlog entry says it "folds into MQ3's regional content rather than running as its own pass." **Not implemented, and not Gate C's to implement.** It needs real behavioural differences, not scaled-up stats.
- UNVERIFIED: sightlines, findability without deliberate search, and per-cluster performance on the ROG. Clusters are sited on the spine's own points, which is the best proxy available without the engine.

### 61 — expedition rest rhythm · COMPLETE for the chapter-wide backbone
- creature-bed gradual recovery is live: `autoload/game_state.gd::_tick_creature_bed_recovery` reads `progression.json`'s `full_heal_seconds` each frame; `camp.gd` completes occupied rests on sleep (CODE)
- **fixed:** fiber — camp costs 10, creature_bed 8, and the world contained 20 total, all below z=312, no respawn, against 50 units of demand. Rest infrastructure was unbuildable in the field for the back two thirds of the chapter. `bushes` now yields fiber at `harvest_fraction` 0.2 (DATA/CODE)
- DEFERRED BY THE PROMPT: camp siting — "Coordinate regional packages. Where a long band needs a plausible rest point, author remembered clearings." Bands 3-5 have no authored clearings and no flat pads past z=4216. Left to D3-D5: siting a pad without being able to measure terrain slope would put a visible scar on a hillside.
- UNVERIFIED: attrition tuning — "if players never need beds, the system has no purpose." This is the one acceptance bullet in Gate C that **cannot** be settled without play.

### 67 — five-creature pressure · COMPLETE
`GATEC-CURVE`. Not re-done. Its `max_catch_level_deficit` now applies to regions
that actually contain catchable creatures, which before this lane's ecology work
it did not for three of five.

### 68 — chapter objective chain · COMPLETE
- **fixed:** two entries for a twelve-beat chapter. Now twelve, every one on a flag the game already sets; all 19 referenced flags verified to exist (DATA)
- labels carry no compass bearings, and the §32 reveal is not named in a list the quest log renders in full from minute one
- the stale-direction audit the prompt asks for came back **clean**: north is −Z here (`minimap.gd`), so the corridor runs south and the existing "south crossing" lines are correct. No dialogue changed.

## The pattern worth carrying forward

Four of the defects closed here were the same shape: a mechanism built, tested
and correct, wired to nothing.

- `GATEC-CURVE`'s per-region wild bands, applied to three regions with no spawns
- three apex TMs with full move data and no acquisition path
- fiber as a build cost with no renewable source
- (recorded, not fixed) `tether_relay.json`'s console `requires_flag`, still `""`
  with a comment saying to set it once SE25 lands — SE25 landed

`BACKLOG.md` already carried `PERF-LOD` as a fifth. The check that catches this
class is not "is the rule right" but "does the rule have content to act on", and
that is what `test_chapter_content_map.gd` and `test_chapter_rewards.gd` now do.

## What Gate C does not claim

Gate C is the backbone, not the chapter. `ralph/ACTIVE_TASKS.md` still has
**Gate A as the current gate**, and the 2026-08-21 owner playtest's blockers are
untouched by this lane. Nothing here is evidence that the Meadows is playable
end to end; that is Gate F and prompt 70.
