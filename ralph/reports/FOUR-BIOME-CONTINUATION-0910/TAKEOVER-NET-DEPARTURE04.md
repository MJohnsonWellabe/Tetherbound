# Takeover checkpoint 04 — multiplayer realm-departure synchronization

Date: 2026-09-10
Base source: `49057278a` plus the bounded changes described here
Branch: `codex/four-biome-continuation-0910`
Status: **clean two-process split-realm replay; zero stale trainer-cache diagnostics**

## Reproduction and cause

The historical split-realm smoke completed its gameplay assertions while peer 0
logged 304 pairs of missing-trainer synchronizer and stale cache errors. A first
bounded correction retained a coordinated client's invisible old authoritative
body from registry commit until destination receiver readiness. That correction
kept the transition/spawner unit suite green but the real replay still found 116
pairs in:

`.artifacts/four-biome-continuation-0910/runs/net-departure-sync-clean-r1/`

The ordered log shows that the remaining errors did not occur during the client's
first Meadows-to-Cloudreach departure. They began on the reverse swap, after the
client had returned to Meadows and while the listen server was building its own
Cloudreach scene. The host's live `/root/MeadowsPlayground` receiver had been
removed, the replacement Meadows shell was not attached yet, and the client still
addressed authoritative trainer state to the missing absolute synchronizer path.

## Protocol correction

Coordinated client departure now separates registry commit from host-side source
body cleanup. The old body is invisible under the existing scope policy, remains a
valid cache target during destination loading, and is reconciled only at the
receiver-ready admission edge.

Host travel now installs a bounded source-receiver closure on every client before
the listen server is permitted to remove its current world scene. Each client:

- records the exact host move generation and source/destination realms;
- refreshes source-realm synchronizer visibility specifically for observer 1;
- acknowledges only after the visibility update has entered the multiplayer queue.

The listen server waits for every live registry peer's matching acknowledgement.
Clients remaining together in the source realm are not closed to one another. At
the end of host travel the matching clear reopens host receipt against the source
shell. Reset and timeout paths clear the host-move fence rather than carrying it
into a later session.

The split-realm harness now scans every peer log after process teardown and makes
either historical signature a test failure:

- `Node not found: "MeadowsPlayground/Spawned/Trainers/Trainer_.../Sync"`;
- `Failed to get cached node from peer`.

This converts the prior manually observed diagnostic into a permanent zero-error
assertion; it does not suppress or rewrite engine logging.

## Runtime evidence

The clean isolated replay is:

`.artifacts/four-biome-continuation-0910/runs/net-departure-sync-clean-r2/`

It completed both client realm crossings and the listen-server reverse crossing,
kept both peers connected, maintained one player in each registry realm, formed
and swapped the correct host shells, committed cross-realm gathers, completed the
host Meadows fight while Cloudreach was hosted, and exited 0 with `ALL CHECKS
PASSED`.

An independent post-run scan found zero occurrences of either forbidden signature
across `peer-0.log` and `peer-1.log`. Both peers reported clean expected exits and
no script/invalid-call diagnostics were found.

## Focused validation

- transition and spawner focus: 23 tests / 114 assertions, green;
- broader transition, receiver history, replication scope, shell guard, crossing
  context and harness focus: 41 tests / 187 assertions, green;
- real `smoke_net_split_realms.gd`: exit 0, all checks passed;
- independent forbidden peer-log scan: 0 matches.

## Next gate

Continue the retained earned Stormwood and Water tails, including optional rewards,
shortcuts, legendary release and final five-creature roster choice. The larger fresh
opening-to-ending campaign proof, broad visual rejudgment and Ally hardware result
remain open.
