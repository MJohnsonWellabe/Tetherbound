# F24 owned source candidate — all flags OFF

Baseline: `b7cb96de89c4c6a9ae827f09e0ad7a2d3a699e70`, branch `tb/f24`.
Owning contract: ACCEPTANCE §6.2 F24#0–#5, COMBAT §10, MULTIPLAYER §10,
CODEX_START_HERE F24/RD-12/RD-36/RD-37. F21/F23 remain landing gates.

Owned implementation covers command-meter admission and landed-hit staging;
four bounded support command plans; ordered pouch assignment/selection;
Rally refresh modifiers; atomic two-creature quick-strike staging through existing
cone/type/rolled-damage arithmetic; single shared Snare slow and per-character
unstacked catch grants; catch ceiling/legality; backpack tier projection;
tap command input, cost-ticked meter and Satchel pouch components.
No human HP/poise damage is authored. Both joint strikes retain original and
incoming creature UIDs, generations and the same parent action identity.
Meter markers live on the same accepted hit receipt, including out-of-order
arrivals; no new authority registry or durable journal is introduced.

Independent reviewer `/root/strict_f24_review`: owned-source PASS after fixes to
tonic multiplier bounds, expired/departed Snare grants and combo target-generation
fencing. Reviewed tether source SHA-256
`7c810a8e2d6f024694653a81ae887508d5ef9d7f8c21548b9e78f587e0423936`.
Legacy mushroom `0.15` buff multipliers remain existing item data outside this
ownership slice; this source preserves current consumer semantics.

Minimum checks: Python gdtoolkit grammar parsing and bounded config/item/source
relations; exact shared packet SHA verification; `git apply --check` against
ROOT's actual combat checkout. These are source checks only. No Godot, import,
check-only engine invocation, render, export, GPU or runtime/visual proof ran.
No full suite/CI was selected because this candidate is OFF and unwired; any
unlabelled CI green is process-only. Source-check artifacts live in the ignored
`.tmp/f24/` packet. This is not a substitute for acceptance tests.

Shared proposals are ignored before/after files and a manifest, never writes to
the actual shared paths. ROOT owns composition against combat
`a5f16a39c25c2c562014baca22911153afc15ea6`, preserving camera/manual lifecycles,
HUD portraits and catch behavior. Proposal patch SHA-256:
`61c0a5aaec9a90239093240e950bebbc26a71533b7359378ee35bb118cecc5a8`.
The HUD placement is provisional and unjudged. Input-map/context deltas require
composition with F23 and actual hotbar suppression; the proposal is not complete
input integration.

| Criterion | Owned source | Missing actual integration/proof | Verdict |
|---|---|---|---|
| F24#0 | Meter and four commands, tap intent/UI | Same canonical accepted hit/command receipt producer; authoritative admission and apply; real player command loop | NOT MET |
| F24#1 | Commands do no direct HP/poise damage; joint strikes name two creature UIDs | Actual damage-event source assertion on solo/host/guest execution, killing blow and retries | NOT MET |
| F24#2 | 1 s target-generation-bound window, next owned creature, switch lockout, two ordinary quick strikes | Atomic canonical switch/body lifetime/HP commit and executed observation; F22 switching comparison | NOT MET |
| F24#3 | Wild-only Snare, immunity refusal, slow/catch bounds, per-player grants and body fence | Actual wild movement and host catch consumer, trainer refusal and expiry/replacement proof | NOT MET |
| F24#4 | Data tiers 1–4, backpack reader, pouch component | Real Workbench gear items/recipes; admitted equipment/pouch projection, character persistence, earned tier proof | NOT MET |
| F24#5 | Own-character actor binding, exact four-field intent, existing receipt/sequence fences | Shared typed owner item debit + durable exact ACK, canonical unlock projection, saved pouch assignment, solo and two-peer/rejoin/forgery/replay proof | NOT MET |

ROOT receives one combined proof ticket: exercise earned practice catch and
two-creature lesson; meter from actual HP debit including misses/ultimates/joint
exclusions; all four commands/zero trainer-attributed damage; both combo strikes
and lockout; Snare slow plus legal bounded host catch; Workbench tiers;
two-peer own-target authority/forged sender or UID/stale generation/duplicate
intent; owner-save and ACK failures plus reconnect. Capture the command meter and
pouch/controller refusals at the device profile, then independently score each
literal criterion. Pending producers are explicitly unavailable, never simulated
by local hotbar consumption or visual hit signals.

Balance: game 7 source/data files / tests-tools 0 tracked files.
