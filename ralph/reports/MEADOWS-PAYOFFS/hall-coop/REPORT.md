# Earned co-op Hall approach — two-peer witness

Lane evidence for ROADMAP Phase 1 item 5's final Meadows segment, and for
STATE's open "earned co-op Hall approach, stronghold completion".

## What this is

An **opt-in** `--hall` leg on `tests/smoke_net_shared_boss.gd`. The file's
default invocation remains the two-peer Warden regression, unchanged, and no CI
job runs the new leg:

    godot --headless --path . --script tests/smoke_net_shared_boss.gd -- --hall

### Why it exists, given what already covered halves of it

- `smoke_gate_e_finale.gd` walks this route **solo**, and its own header says
  the seams it covers are the solo ones.
- This file's **default** leg fights the Warden two-peer, but teleports the
  peers in. It never walks the Hall and never touches the gauntlet.

Neither covers the join asserted here: that two peers standing in one Hall
**agree about it**, move through it **on their own legs**, share **one**
gauntlet record rather than two, and end holding the same world facts across a
reload.

Harness addition in `tools/net/peer_runner.gd`: a read-only `stronghold` probe
reading `stronghold.gd`'s own public accessors — `route()`, `marker_names()`,
`marker()`, `gauntlet_size()`, `recovery_point()`, `machine()`,
`door_is_open()` — rather than node names, because the Hall hangs its approach
run off the world rather than off itself. It presses nothing and mutates
nothing.

## Result

**46 checks pass, 0 fail, first run.** Log: `two-peer-hall-approach.log`.
Godot 4.7-stable, two processes, clean loopback.

Proven:

- Both peers build a Hall and hold the **same** five-space route —
  `outer_works → courtyard → tether_approach → warden_arena →
  legendary_chamber` — at the **same authored markers**, with the same three
  gauntlet trainers and one recovery point at the same place. A Hall built
  per-peer would pass every later check separately and still be two buildings.
- Both peers prepare five ordinary creatures and deploy a lead.
- Both peers **walk to each of the three gauntlet rooms on their own legs**,
  by ordinary movement, and arrive within 3 m of the authored marker.
- Each of the three authored fights mints **one shared encounter record**; the
  guest **joins that record** rather than opening a second, and its own
  `trainer_battle_active` stays false — it is in the fight without running one.
- All three resolve (437 / 699 / 638 frames against 2, 3 and 3 creatures), and
  `defeated_stronghold_patrol`, `defeated_stronghold_courtyard` and
  `defeated_stronghold_elite` each land on **both** peers as world facts.
- Both peers complete a production save/reload inside the Hall, retain every
  gauntlet fact, and still agree on one shared world by state hash.

## Boundaries

- Opt-in only; the Warden default is untouched and no CI job runs this leg.
- **Disclosed fixture: the seat at the Hall entrance.** The Meadows spine
  between the Mill crossing and the Hall is kilometres of authored road that
  `test_meadows_earned_hall_segment.gd` owns; seating two peers on it here
  would be claiming that road rather than this one. What is claimed earned is
  the movement **between the Hall's own spaces**, on both peers.
- The party is a disclosed fixture (`tournament_setup`'s five ordinary
  creatures), not earned play.
- **Not covered here:** the recovery point used by a guest, the Warden himself
  (the default leg owns that), the Veridian decision, and the Cloudreach gate
  handoff. STATE's "chapter handoff" item stays open.
- Two peers, clean loopback, one container. No four-peer, lossy-network,
  device or export evidence.
- This does not certify Hall pacing, balance or presentation.
