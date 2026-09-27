# Card C1 — Cloudreach earned flight route

- **Run:** `run-10/` is one uninterrupted run from the earned `tests/fixtures/earned_saves/c1_arrival` save (`--accelerated --live-combat`), script `tests/smoke_cloudreach_b_c1_card.gd`.
- **Result:** `C1 CARD PASS`, `F06#3 WITNESS PASS`, `CLOUDREACH CONTINUOUS PASS stage=complete`.
- **Files:** `c1.json` is the card verdict, `witness.json` the loaner witness, `events.json` the full log, and `c2-analysis.json` the C2 cadence and ledger read.

What it covers:
- **Regions:** all six, by region ledger. The five ground regions are walked on foot and High Roost is flown.
- **Fly:** trained (Maela's ring trial, with the trial-escape refused), 6 loaner launches, the sealed Upper wind wall refused, and one exhausted-fall recovery onto the shrine anchor. No owned creature was used as the carrier, and the loaner is not offered after the chapter and a reload.
- **Route:** the fights with Senn, Maela, Voss and Veyra are played with the live controller pilot. The three relays and the overlook are reached, and the chapter completes with a disk save and reload.
- **Stormwood by the earned key:** `earned_stormward_handoff.gd` walks the Stormward stair and presses Interact twice. The first press unlocks with `realm_key_stormwood` and the key is kept; the second enters Stormwood, arriving at (-300, 32.3, 180) with the same five (stable keys).
- **Owned-carrier Fly:** OPEN DEBT. No starter gives a flier; only galecrest can carry, and it is catchable in Meadows band 1.

Shortcuts (disclosed):
- Accelerated clock (physics stays at 1/60 s).
- Live-combat pilot, whose camera yaw is written directly.
- Title Load pressed by emitting its signal.
- Harness walking aids, all logged:
  - relay legs step around standing people;
  - bed approaches stop where the production offer is won;
  - walks re-centre on their waypoint;
  - a static-stall sidestep, 0 used in this run.

Runs 1–9 were harness snags, fixed one by one: a ridge snag, the rotated bivouac bed, Veyra's body in a relay leg, the trainer shoved in a relay leg, the waypoint offset, the bookkeeping bug, and the recovery-position timing. Their logs are not kept.
