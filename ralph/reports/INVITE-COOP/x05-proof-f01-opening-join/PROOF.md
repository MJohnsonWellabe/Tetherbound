# Two-peer proof: F01 opening, every starter, through a reload; each starter also crosses a guest's drop and rejoin

**Verdict: PASS.** 3 of 3 runs, with 0 failed checks (142 / 141 / 143 checks). The smoke's default late-arrival mode is unchanged: 74 checks, PASS on `8608ec2d9`. The later change touches only the opening-together path.

Base: `ralph/x05-f01-join` `58b5defc0`, which is main 08fcc2055 plus the smoke changes. Headless. One run per starter pair:

```
TB_NET_OUT_DIR=DIR TB_NET_PEERS=2 godot --headless --path . \
  --script tests/smoke_net_meadows_identity_fresh_join.gd -- \
  --opening-together --host-starter=H --guest-starter=G
```

| Run | Host picks | Guest picks | Checks | Result |
|---|---|---|---|---|
| host0-guest2 | terrapup | galewisp | 142 | PASS |
| host1-guest0 | ripplet | terrapup | 141 | PASS |
| host2-guest1 | galewisp | ripplet | 143 | PASS |

Every starter is chosen once by a host and once by a guest.

## What each run shows

1. **Session.** Both peers boot the real title. The host enters through the production title and hosts. The guest joins with `production_join`, the title's own join path, under a distinct name and appearance. Before the opening, each registry holds two players. After the opening, the smoke checks that both registries carry both chosen names and appearances, and that each screen draws the other player's body, badge and full-map marker.
2. **Opening, inside the live two-peer session.** Each peer plays the real opening with ordinary movement and physical controller presses:
   - out of bed, down the stairs, Grandpa's briefing;
   - H or G presses of `ui_right` in the real starter picker, then confirm;
   - a name typed in the real naming grid;
   - back to Grandpa for the catch supplies.
   Straight after the opening, each peer holds exactly one starter, of the species it picked, under the name it typed. It also has the `opening:starter_granted` receipt on its own character (checked on both peers) and 45–50 orbs.
3. **In-place save and reload** (`save_reload_here`). The host saves and reloads its slot. The guest saves its character file and applies it again. That apply lands on an in-memory state that was never cleared, so step 4 is what covers restoring into a blank state. Each still holds the same starter species (and UID), the same typed name, the receipt and its orbs.
4. **Rejoin: the GUEST's starter crosses a join.** The host never drops. Each species crosses the rejoin once, as a guest's starter. The harness saves the guest's character, then its link dies with `drop_link`. In reaction, the game's own disconnect path (`session.gd` `_on_server_disconnected`) saves the character again. `drop_link` waits until the session is inactive, so that save lands before the wipe below and never writes a blank character. The host sees it gone. The guest's in-memory character is blanked (party 1 → 0). The same character id then rejoins through the title's returning route, and both peers see both players again. Then:
   - the guest holds the same starter creature, with the UID recorded before the drop, under its species and typed name, plus its receipt and exactly the orb count it had before the drop (50);
   - both registries hold exactly the host and the returning character;
   - the host still holds its own starter species and name. The host's UID, receipt and orbs are checked across the reload (step 3), not re-checked after the rejoin.

## Known and not covered

- **Save error in the logs.** Every run logs one `ERROR: Could not create directory 'user://saves'` and a fallback-autosave warning. They come only from the harness's own coordinator process, which still ticks its Game autosave and cannot write into its empty isolated data home. That is a harness gap, not game behaviour. Both peer logs, committed as `<run>/peer-N.log.gz`, contain it 0 times.
- **Guest log errors after the drop.** Each guest `peer-1.log` holds 18–20 `ERROR: The multiplayer instance isn't currently active` lines, from `scripts/creatures/remote_creature.gd` `_apply_ownership` running while the link is dead. All of them come while the link is dead: in every run the last one is logged before the disconnect-path save and the returning-route restore even begin. Nothing in the run depends on them. They are log noise from a file outside X05's lane, reported, not fixed here.
- **Weak name check.** The typed names are one letter, and both peers typed the same one ("A"). The check is per peer, against what that peer typed.
- **Rest of the F01 clause, not covered:**
  - the first fight and catch;
  - three-bed readiness;
  - three played tournament rounds;
  - a cold restart with Continue from the title;
  - the host dropping and returning.

## Files

- `<run>/SUMMARY.md`, `<run>/coordinator.log.gz` (every check line) and `<run>/peer-0.log.gz` / `peer-1.log.gz`.
- `default-mode/`: the smoke's default late-arrival mode on the same commit.
