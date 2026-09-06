# Stage B multiplayer — handoff

**Branch:** `claude/tetherbound-roadmap-next-jrcjs8` @ `3b8b72ab` (the head this handoff was written at; `855ba52b` was its parent). **PR #63, open, not on `main`.**
**Contract:** `docs/MULTIPLAYER_DIRECTIVE.md`. **Evidence:** `docs/acceptance/MULTIPLAYER_ACCEPTANCE.md`
— that file is authoritative, this one is the summary and the to-do list.

## Where it actually stands

The implementation scope in `docs/DEVELOPMENT_ROADMAP.md` Stage B is complete, and all twenty-four
§17 rows name a run. **Stage B is not finished**, and nothing holding it open is architecture.

Read `MULTIPLAYER_ACCEPTANCE.md`'s "Known-open, carried deliberately" list before trusting any
count in it. Several rows are green with a stated limit inside them.

## What is left, in the order I would do it

### 1. One decision, and only the owner can make it

**Does a wild creature get harder when a friend joins?** Today it does not:
`_scale_opponent_for_the_session()` sits behind `if opponent_owned:` in `encounter_director.gd`, so
§10's multiplier reaches a trainer's or boss's creature and nothing else. Two players ganging up on
a wild fight it at its authored numbers.

This is deliberately unfixed. **A scaled wild is also a harder CATCH at the same `hp_fraction`**,
and catching is how a player builds their team of five — so "fixing" it could make co-op worse at
the thing the game is about. Lane MP-F1-F2's finding N1; the machinery
(`encounter_host.gd::scaling_for()`) is not trainer-specific and would need no new code, only the
gate widened and the catch consequence decided.

### 2. Verification gaps, worst first

| Gap | Why it matters | What closes it |
|---|---|---|
| **`verify-multiplayer-shard` has never completed a CI run.** Cancelled seven times: `ci.yml` sets `cancel-in-progress` for every non-`main` ref and that job takes ~45 min, so any push kills it. | **Every net-smoke number anywhere in this repo is from a LOCAL two-process run.** Those are real, but they are not CI evidence and must not be described as such. | Stop pushing to the branch and let one run finish. Then read it per-peer and smoke-by-smoke, not by conclusion. |
| **No net smoke puts two pilots in a CLOUDREACH fight.** | The roadmap's evidence bar asks for a "shared Cloudreach encounter". Verified, not assumed: in `smoke_net_split_realms` the HOST fights, in the Meadows, while holding Cloudreach as a shell; the client there gathers and crosses but never engages. | A `smoke_net_shared_cloudreach_fight`, modelled on `smoke_net_shared_wild_fight` — **including its `place_stand_in` arm** (see Traps). |
| **`smoke_aggression`'s flake rate is unmeasured.** | Two lanes called it flaky against untouched bases; nobody has a number. | Run it ~7× on a quiet box. Note the measurement that failed before was eaten by the `tail -f` trap below, not by the smoke. |
| **Two of three jitter smokes not re-measured.** | 7.A drove `host_join_leave`, `shared_wild_fight` and `pickup_race` at 150/30/1. Only `shared_wild_fight` has been re-run since the fixes (5/5 green). | `TB_NET_CONDITIONS="delay=150,jitter=30,loss=1" tools/net/run_net_smoke.sh <name>` |
| **`smoke_boss` unverified on the merged head.** | CI ran it green at `7f4aa57c`, before the F1/F2 merge. I was interrupted before re-running it locally. | One run; it takes ~2 min. |

### 3. The human half — this is what "real" means

No automated run can supply any of it, and the directive's exit criterion is a *person*:

- the owner hosts and is joined over a real LAN;
- **an outside tester hosts, and three join, without developer help**;
- that session is recorded in `docs/owner/` like a playtest;
- an Ally frame-time measurement, host-side, with a second player connected
  (`tools/owner/MULTIPLAYER_KICKOFF.cmd` sets the session up and writes `fps.json`).

### 4. Land it

PR #63 → `main`. Stage B is not done until it is there.

## Traps that cost real time here — do not re-learn these

1. **`OfflineMultiplayerPeer`.** With no session, `multiplayer.is_server()` is **true** and
   `get_unique_id()` is **1**. Any guard shaped "am I the server, if a peer exists" is unsound and
   passes in every headless test. Ask `Game.is_multi_peer()`.
2. **A green run with FEWER assertions is a compile failure passing vacuously.** A GDScript file
   that fails to parse contributes exactly one failure however many tests it holds; `int(null)` and
   `bool(null)` abort a function rather than failing it. Check a positive count, never "0 failed".
   This caught four false passes.
3. **A fixed-settle read of a HOST verdict is a race, not a wait.** One pattern produced four
   separately-recorded problems. `pending` is the host being ASKED, not the host saying no.
4. **A joiner's swing is a spawn-table lottery.** `join_encounter()` binds a joiner to
   `nearest_live_wild()`, and wild bodies are not replicated, so how far that stand-in sits from the
   host's real opponent is chance. Two smokes compensate with `place_stand_in`. **The binding is
   unchanged** — any new smoke where a joiner swings needs the same arm.
5. **`run_net_smoke.sh` ends in a `tail -f` that never exits.** Capturing its stdout hangs forever;
   `--out=` creates a run SUBDIRECTORY under the path you give. Read
   `<out>/net-*/SUMMARY.md`, never stdout. This silently ate two measurements and made a finished
   run look stuck for 41 minutes.
6. **`--check-only` over the scripts a lane CHANGED does not cover the scripts that SUBCLASS them.**
   A clean sweep still shipped a test file that would not parse, so all 18 of its tests silently did
   not run. When a public signature changes, grep for `extends "res://<that file>"`.
7. **A lane's own report is a claim.** MP-F1-F2's finding N2 said `smoke_arena_contain` was
   registered in no CI step; it is, at `ci.yml:1476`, passing — the shard passes the BARE smoke name
   through an env var, so grepping the filename finds nothing. Acting on it would have run the smoke
   twice per CI run. Check before acting.

## Known-open by design, not by omission

- **Wild creature bodies are not replicated.** A client's wilds drift from the host's. Lane 4.B
  chose drift over a frozen meadow and every strike resolves against host positions, which keeps it
  cosmetic — but two people WILL see creatures in different places. **This is a design decision the
  owner should confirm rather than inherit.**
- The v22 slot file is still written alongside the D100 split; retiring it is its own change.
- `reconnect_window_s` is documented intent, not a timer — nothing is broken for the player, and it
  is a doc fix rather than code.
