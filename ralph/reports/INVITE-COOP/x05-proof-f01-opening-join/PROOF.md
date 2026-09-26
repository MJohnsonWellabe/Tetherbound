# Two-peer proof: F01 opening, every starter, through a reload and a two-peer rejoin

**Verdict: PASS.** 3 of 3 runs, with 0 failed checks (141 / 140 / 142 checks). The smoke's default late-arrival mode is unchanged: 74 checks, PASS.

Base: `ralph/x05-f01-join` `8608ec2d9`, which is main 08fcc2055 plus the smoke changes. Headless. One run per starter pair:

```
TB_NET_OUT_DIR=DIR TB_NET_PEERS=2 godot --headless --path . \
  --script tests/smoke_net_meadows_identity_fresh_join.gd -- \
  --opening-together --host-starter=H --guest-starter=G
```

| Run | Host picks | Guest picks | Checks | Result |
|---|---|---|---|---|
| host0-guest2 | terrapup | galewisp | 141 | PASS |
| host1-guest0 | ripplet | terrapup | 140 | PASS |
| host2-guest1 | galewisp | ripplet | 142 | PASS |

Every starter is chosen once by a host and once by a guest.

## What each run shows

1. **Session.** Both peers boot the real title. The host enters through the production title and hosts. The guest joins with `production_join`, the title's own join path, under a distinct name and appearance. Both registries hold both identities. Each screen draws the other player's body, badge and full-map marker. These checks are made here, before the opening.
2. **Opening, inside the live two-peer session.** Each peer plays the real opening with ordinary movement and physical controller presses:
   - out of bed, down the stairs, Grandpa's briefing;
   - H or G presses of `ui_right` in the real starter picker, then confirm;
   - a name typed in the real naming grid;
   - back to Grandpa for the catch supplies.
   Straight after the opening, each peer holds exactly one starter, of the species it picked, under the name it typed. It also has the `opening:starter_granted` receipt on its own character (checked on both peers) and 45–50 orbs.
3. **In-place save and reload** (`save_reload_here`). The host saves and reloads its slot. The guest saves its character file and applies it again. That apply lands on an in-memory state that was never cleared, so step 4 is what covers restoring into a blank state. Each still holds the same starter species (and UID), the same typed name, the receipt and its orbs.
4. **Rejoin, the starter crossing a join.** The guest writes its character, then its link dies with `drop_link`. The host sees it gone. The guest's in-memory character is blanked (party 1 → 0). The same character id then rejoins through the title's returning route, and both peers see both players again. Then:
   - the guest holds the same starter creature, with the UID recorded before the drop, under its species and typed name, plus its receipt and orbs;
   - both registries hold exactly the host and the returning character;
   - the host still holds its own starter.

## Known and not covered

- **Save error in the logs.** Every run logs one `ERROR: Could not create directory 'user://saves'` and a fallback-autosave warning. They come only from the harness's own coordinator process, which still ticks its Game autosave and cannot write into its empty isolated data home. That is a harness gap, not game behaviour. Both peer logs, committed as `<run>/peer-N.log.gz`, contain it 0 times.
- **Weak name check.** The typed names are one letter, and both peers typed the same one ("A"). The check is per peer, against what that peer typed.
- **Rest of the F01 clause, not covered:**
  - the first fight and catch;
  - three-bed readiness;
  - three played tournament rounds;
  - a cold restart with Continue from the title.

## Files

- `<run>/SUMMARY.md`, `<run>/coordinator.log.gz` (every check line) and `<run>/peer-0.log.gz` / `peer-1.log.gz`.
- `default-mode/`: the smoke's default late-arrival mode on the same commit.
