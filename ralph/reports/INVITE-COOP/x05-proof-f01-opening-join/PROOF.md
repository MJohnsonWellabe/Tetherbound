# Two-peer proof: F01 opening, every starter, across a two-peer join and a reload

**Verdict: PASS** — 3 of 3 runs, 0 failed checks (121 / 120 / 122 checks).

Base: main `08fcc2055`. Headless. Command, one per run:

```
TB_NET_OUT_DIR=<dir> TB_NET_PEERS=2 godot --headless --path . \
  --script tests/smoke_net_meadows_identity_fresh_join.gd -- \
  --opening-together --host-starter=H --guest-starter=G
```

| Run | Host picks | Guest picks | Checks | Result |
|---|---|---|---|---|
| host0-guest2 | terrapup | galewisp | 121 | PASS |
| host1-guest0 | ripplet | terrapup | 120 | PASS |
| host2-guest1 | galewisp | ripplet | 122 | PASS |

Every starter is chosen once by a host and once by a joined guest.

## What each run shows

- Both peers boot the real title. The host enters through the production title and hosts. The guest joins by `production_join`, the title's own join path, with a distinct name and appearance.
- Each peer then plays the real opening with ordinary movement and physical controller presses. It gets out of bed, goes down the stairs and hears Grandpa's briefing. It moves `ui_right` H or G times in the real starter picker, confirms, and types a name in the real naming grid. Then it returns to Grandpa for the catch supplies.
- Each peer ends with exactly one starter, of the species it picked, plus the `opening:starter_granted` receipt on its own character and 45–50 orbs.
- Each peer then runs the production save and load (`save_reload_here`). It still holds the same starter, species and UID, the receipt and its orbs.
- Both registries hold both identities. Each screen draws the other player's body, badge and full-map marker.

## Not covered here

The rest of the F01 clause: the first fight and catch, three-bed readiness and three played tournament rounds, each followed by a reload or two-peer join.

## Files

`<run>/SUMMARY.md` and `<run>/coordinator.log.gz` (every check line).
