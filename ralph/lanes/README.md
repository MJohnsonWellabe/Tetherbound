# Gate D lane briefs

One file per regional lane. Say **"start D1"** (or D2…D5) to a session checked
out on that lane's branch and it should read its own file here, plus
`COMMON.md`, and begin.

| Lane | Region | Branch | Brief |
|---|---|---|---|
| D1 | Lower Meadows | `ralph/gate-d-band1-lower-meadows` | `START_D1.md` |
| D2 | Quarry / Burrow Warrens | `ralph/gate-d-band2-quarry-warrens` | `START_D2.md` |
| D3 | River / Tether Relay | `ralph/gate-d-band3-river-relay` | `START_D3.md` |
| D4 | Upper Meadows / Ironwood | `ralph/gate-d-band4-upper-meadows` | `START_D4.md` |
| D5 | Stronghold Approach | `ralph/gate-d-band5-stronghold-approach` | `START_D5.md` |

`COMMON.md` carries what every lane needs: Godot setup for a fresh container,
the test-runner traps, the two defects every lane inherits, the shared files no
lane may edit, the hard rules content authoring tends to break, and the ship
protocol.

A sixth lane, wild-creature streaming, is **complete** and shipped on
`ralph/gate-d-wild-streaming`. It has no brief because it has no remaining work;
its one open question — boot time against the real merged tables rather than a
synthetic one — belongs to integration.

Each brief states what is already done on that branch, what decisions are
settled and should not be reopened, and what is genuinely left. They are written
to be accurate about uncertainty: where a lane's own account was never written
or was self-graded, the brief says so rather than presenting it as verified.

## Status, 2026-08-23

D3, D4 and D5 are **done and merged** — their briefs above describe the state
they started from, not where they finished. For what is still open in those
three, and what is closed, read `ralph/GATE_D_REMAINDERS.md` instead of the
START files.

D1 and D2 are still live. Their START files remain current.
