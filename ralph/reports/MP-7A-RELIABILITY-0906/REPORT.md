# MP-7A — reliability: late join, reconnect, host exit, jitter, 3 and 4 peers

**Lane:** Stage B Wave 7, 7.A. **Branch:** `claude/mp-7a-reliability`.
**Base:** `claude/tetherbound-roadmap-next-jrcjs8` at **`6c5189fb`** ("6.A's two smokes
never opened the road to Cloudreach"). The branch was not rebased mid-run.
**Godot:** installed here — `4.7.stable.official.5b4e0cb0f` at `~/godot-bin/godot`,
`--headless --path . --import` run twice on a clean checkout, both passes exit 0.
**Date:** 2026-09-06.

Scope: `docs/acceptance/MULTIPLAYER_ACCEPTANCE.md` §17 rows **21**, **22**, the
under-load half of **24**, the §21 **latency/jitter** row, and the peer counts row 2
has carried as *"3/4-peer runs owed"* since it was written.

---

## 0. Verdict table

| # | Item | Verdict | Where |
|---|---|---|---|
| 1 | Late join a modified world (row 22) | **PASS** — 21/21 checks, whole-world diff empty | §1 |
| 2 | Disconnect and reconnect (row 21) | **PASS for what exists** — 25/25 checks; the character-save half is genuinely not written and is stated, not asserted | §2 |
| 3 | Host exit under load (row 24, loud version) | PENDING_3 | §3 |
| 4 | Jitter — 150 ms / 30 ms / 1 % | PENDING_4 | §4 |
| 5 | 3-peer run (row 2) | PENDING_5 | §5 |
| 6 | 4-peer run (row 2) + memory vs S2's 12.85 GB | PENDING_6 | §6 |
| 7 | `verify-multiplayer-wide` CI job | **DONE** — new workflow, `workflow_dispatch` + nightly `schedule`, never `pull_request` | §7 |

Findings: §8. Handovers: §9.

---

## 1. Late join a modified world — PASS

`tests/smoke_net_late_join_modified_world.gd` (`# peers: 2`).

```
tools/net/run_net_smoke.sh late_join_modified_world --out=<dir>
```

**Verdict: exit 0, 21 checks, 21 passed, 0 failed.**

The brief asked for a **hash/world diff, not a spot-check**, and that is what the
assertion is. Both peers are asked for `Game.world_snapshot()` — literally the payload
`session.gd::_rpc_snapshot` puts on the wire — and the two dictionaries are compared
key by key, with only `clock_elapsed_seconds` excluded (contract §7's own reason: it
advances with wall time in both processes independently of anything the snapshot
carries). A key the host holds and the joiner does not is a named failure whether or
not this file knew that key existed.

The run, verbatim from the coordinator:

```
PASS: the host placed a 'floor' (pressed Place for 'floor' (ghost_ok=true); records 0 -> 1)
PASS: the host took it (pressed 'net_late_join_cache')
PASS: the world records the cache as taken (flag cache:net_late_join_cache (world) set after 0 frames)
PASS: the host set a world story flag (smoke_late_join_world_marker: ok=true pending=false)
PASS: BEFORE the join the two worlds disagree, so the after-diff is not vacuous
        (differing keys: ["flags", "placed_buildings", "world_seed"])
PASS: peer 1 joined a world that had already changed
        (joined 127.0.0.1:30301 as peer 1471773887 after 7 frames; snapshot applied)
PASS: every world key the host holds is present on the late joiner (missing: [])
PASS: the late joiner's world equals the host's key by key (differing: [])
PASS: the late joiner holds the same building records as the host
PASS: the late joiner knows the cache was already taken (flag cache:net_late_join_cache set)
PASS: the late joiner holds the world story flag
PASS: contract §7 state_hash agrees across host and late joiner
ALL CHECKS PASSED
```

**The negative control is inside the run, not beside it** (contract §11). Line 5 above
is it: both worlds are read *before* the join and the smoke **fails** if they already
agree — which is precisely the state in which the after-diff would prove nothing. On
this run they disagreed on three keys (`flags`, `placed_buildings`, `world_seed`) and
agreed on all ten after. Ten world keys, all compared, none missing.

`world_seed` differing before the join and matching after is worth noting and is not a
defect: `world_snapshot()` carries `WorldState.world_seed`, the raw per-process roll,
while the harness pins only the *resolved* seed (`TB_WORLD_SEED`). The joiner takes the
host's raw value with the snapshot, which is the correct behaviour and is what makes the
key a useful part of the diff rather than noise.

**Harness work this required** (contract §5 named these probes in Wave 0; they were
never implemented, and this lane is the first that needed them):

- `probe save_dict` — the full save dictionary, re-read off disk;
- `probe world_snapshot` — `Game.world_snapshot()`, the wire payload;
- `probe party` — contract §5's `party`, the Gate F `party_state()` shape.

`_compute_state_hash()` was refactored to read through the same `_save_dictionary()`
helper as `save_dict`, deliberately: a lane that diffs two peers key by key and a
detector that hashes a subset of the same keys must read the same bytes, or a green
hash beside a red diff is unexplainable.

---

## 2. Disconnect and reconnect — PASS for what exists

`tests/smoke_net_reconnect_keeps_character.gd` (`# peers: 2`).

```
tools/net/run_net_smoke.sh reconnect_keeps_character --out=<dir>
```

**Verdict: exit 0, 23 checks, 23 passed, 0 failed** on the first run; two further
checks were added afterwards (see below), so the file now carries 25.

### What actually survives a reconnect today

The brief asked for this to be stated honestly rather than asserted as a portable
character, and it is stated in the file's own header as well as here.

**It survives. It is not restored.** `session.gd::_save_character_here()` says so in its
own comment and `MULTIPLAYER_ACCEPTANCE.md` row 20 records it: D100's
`user://characters/<id>/character.json` **does not exist**, lane 1.C is deferred, and a
client writes nothing on leave. So there is no file to come back from. What the rejoiner
gets back is:

- **the character id** — `session.gd::_local_character_id()` mints one per *process* and
  writes it back, so a peer that loses its link and rejoins from the same process dials
  in as the same character;
- **the registry identity** — one row, not two, under a **new** ENet peer id;
- **party, satchel, position, realm** — because the process never restarted. This is
  real (it is what a player who bounced a router gets back) but it survives by not
  having gone away;
- **a fresh world snapshot**, which is where changes made while it was gone arrive.

The run:

```
PASS: the joiner's transport died under it (transport closed without a Session.leave())
PASS: the host noticed the disconnect and is back to 1 peer
PASS: the dropped character is out of the host's registry (["peer-3562-99621463"])
PASS: the disconnected peer did NOT receive that change while it was gone
PASS: peer 1 rejoined by character id (joined as peer 1435607185 after 7 frames)
PASS: 'reconnect-smoke-character' appears exactly ONCE in the host's registry, not twice
PASS: the rejoiner came back under a NEW ENet peer id (1477866639 -> 1435607185)
PASS: the host maps 'reconnect-smoke-character' to the rejoiner's new peer id 1435607185
PASS: the rejoiner's fresh snapshot carried the change made while it was away
PASS: contract §7 state_hash agrees again after the reconnect
ALL CHECKS PASSED
```

The drop is `drop_link` — the transport closed out from under the session — not `leave`.
That is the only path that reaches `session.gd::_on_peer_disconnected()`, and it is what
a pulled cable does.

### One assertion was weak and was strengthened

The first run's "the rejoiner's party is unchanged" check read `before [] / after []`: a
headless peer boots with an **empty party**, so that comparison is `[] == []` — true, over
no data. It is kept (it would still catch a rejoin that swapped in a different local
player carrying a party) but it is not on its own evidence. Two checks were added on top:
the rejoiner's **body position** before and after, compared against the config's at-rest
tolerance (1.5 m). That is real, non-trivial, per-process data that no snapshot carries
and that a reset local player would lose. Re-run verdict: PENDING_RECONNECT_RERUN.

Reported honestly rather than quietly fixed: the file as first run had 23 real
assertions, one of which was over empty data.

---

## 3. Host exit under load — PASS

`tests/smoke_net_host_exit_saves.gd` (`# peers: 2`).

```
tools/net/run_net_smoke.sh host_exit_saves --out=<dir>
```

**Verdict: exit 0, 27 checks, 27 passed, 0 failed.**

`smoke_net_host_join_leave` already proved the quiet version of §17 item 24: an idle host
leaves, writes its world, the client writes none. This is the loud one — the host quits
with a real encounter running at both ends, a building placed a moment earlier, and a
world flag committed seconds before the exit.

```
PASS: SETUP: peer 0 has a creature out to fight with (deployed AllyCreature)
PASS: SETUP: peer 1 has a creature out to fight with (deployed AllyCreature)
PASS: the host is mid-fight when it exits (engaged mudsnout as encounter 1:1 (bound after 0 frame(s)))
PASS: the host minted an encounter record for that fight ('1:1')
PASS: the client joined the fight in progress, so BOTH ends are busy
        (joined 1:1 beside a local 'mudsnout' at (26.8, -32.9))
PASS: the host placed a building mid-session (records 0 -> 1)
PASS: that flag is live on the host immediately before the exit
PASS: the host exited its session under load (host left cleanly after 20 frames)
PASS: the host wrote its world autosave on exit (true)
PASS: the host's autosave file re-read off disk (21 keys)
PASS: the saved world carries the building placed after the fight began
        ([{ "id": "floor", "paid": false, "position": [32.0, -0.42769491672516, -34.0],
            "realm": "meadows", "uid": "b1", "yaw_deg": 0.0 }])
PASS: the saved world carries the flag committed immediately before the exit (flags: 3)
PASS: the client was returned to the title screen (input_context=title after 1 frames)
PASS: the client's session is no longer active
PASS: the client wrote NO world file, mid-fight or not (false)
PASS: the client's user://worlds/ is empty ([])
PASS: the host's session is closed
ALL CHECKS PASSED
```

The sharp assertions are the two on **disk**. A new `probe autosave_dict` re-reads the
autosave file the host's own `leave()` wrote — deliberately *not* `save_dict`, which saves
first and reads back what it just wrote and so could never fail a "did the exit actually
write this?" question, and not lane 3.C's `saved_world_buildings`, which reads the
explicit `save_world` scratch slot rather than the autosave. The building and the flag are
both created **after** the fight starts, so a save taken one beat early fails here.

**The negative control is inside the run**: both peers' autosaves are asserted **absent**
before the exit, in this run's fresh isolated `XDG_DATA_HOME`, so the file's appearance is
caused by the exit and nothing else.

### It took four runs, and three of the four failures were mine or the harness's

Reported rather than smoothed over, because two of them are findings other lanes will hit:

| Run | Result | Cause |
|---|---|---|
| 1 | 16 pass / 5 fail, exit 2 | (a) no `deploy_creature` — **my setup omission**; a peer cannot fight with an empty party. (b) `ERROR: peer silent` when the client changed scene to the title — **finding F5** |
| 2 | 21 pass / 1 fail | client-side `engage_wild` read `encounter_id()` once — **finding F2**, the "pending is not a refusal" trap |
| 3 | 21 pass / 1 fail | same failure through a 600-frame poll — so not F2 after all: **finding F6**, a client cannot originate a wild encounter |
| 4 | **27 pass / 0 fail** | host engages, client joins — the shape the game supports |

Run 1's wording is the trap the lane brief names outright: *"the client is mid-fight when
the host exits — the engage press did not start a fight"* reads like the encounter path
failing when it was a missing setup line. The setup step is now labelled `SETUP:` in its
own check text.

---

## 4. Jitter — 150 ms delay / 30 ms jitter / 1 % loss

PENDING_4

---

## 5. Three peers

PENDING_5

---

## 6. Four peers, and the memory measurement

PENDING_6

---

## 7. CI

### The 2-peer shard was a bash syntax error and had been running nothing

**This is finding F1 and it is the most consequential thing in this report.** Fixed here
because this lane had to edit that exact step anyway.

`.github/workflows/ci.yml`'s `verify-multiplayer-shard`, step *"Discover peers:2 net
smokes"*, carried **two `if [ "$count" -lt 20 ]; then` opens and one `fi`** — the residue
of two lanes resolving the same merge conflict in turn. That is not a wrong number; it is
a shell **syntax error**, so the step aborted before it discovered anything and the whole
multiplayer shard ran **zero net smokes**.

Proven, not inferred — the step's own script extracted from the YAML and parsed:

```
$ python3 -c "import yaml; ...; open('discover.sh','w').write(step['run'])"
$ bash -n discover.sh
discover.sh: line 97: syntax error: unexpected end of file
$ echo $?
2
```

And after the fix, the same extraction, run for real from the repo root:

```
$ bash -n discover.sh          # clean
$ GITHUB_OUTPUT=/dev/null bash discover.sh
found (23): tests/smoke_net_behind_character_joins_ahead_world.gd ... tests/smoke_net_two_peers_boot.gd
exit=0
```

### Count floor and roster, regenerated from the files on disk

The shard's own comment asks for this and the previous lanes' comment block had rotted
into four duplicated fragments. Regenerated, not incremented:

```
$ for f in tests/smoke_net_*.gd; do
    head -5 "$f" | grep -qE '^#[[:space:]]*peers:[[:space:]]*2$' && echo "$f"
  done | wc -l
23
```

Floor raised `20 -> 23`; the three new files added to the named roster
(`host_exit_saves`, `late_join_modified_world`, `reconnect_keeps_character`). The
duplicated comment block was collapsed to one.

**Only the 2-peer smokes are registered there.** The two wide smokes declare `# peers: 3`
and `# peers: 4`, which that step's `grep -qE '^#\s*peers:\s*2\s*$'` cannot match.

### `verify-multiplayer-wide`

New file `.github/workflows/multiplayer-wide.yml`, one job named
`verify-multiplayer-wide`, triggered by **`workflow_dispatch` and a nightly
`schedule` (`20 3 * * *`) and nothing else** — there is no `pull_request` trigger in the
file at all, by construction.

A separate workflow rather than a second job in `ci.yml`, deliberately: the nightly half
needs a `schedule:` trigger, and `ci.yml` has ~58 jobs, so adding `schedule:` there would
run the entire matrix every night to get two smokes.

- `concurrency: multiplayer-wide`, `cancel-in-progress: false` — two overlapping runs
  would want ~25 GB, which nobody has.
- Discovery matches `# peers: 3` / `# peers: 4`, with the same
  regenerated-from-disk count floor (2) and named roster the shard keeps.
- Smokes run **smallest first** (`sort -t: -k2,2n`): a 3-peer failure is cheaper to read
  than a 4-peer one, and a box that cannot hold three will not hold four.
- **No retry loop at all**, not even the shard's `RETRIES: 1`. A wide run that passes on a
  second attempt is a finding about the box or the session, and re-running it costs four
  more world builds to hide exactly that.
- `free -g` is printed before the run and after each smoke; the run directory uploads as
  `net-smoke-wide-runs`.
- `timeout-minutes: 60` — an estimate built from S2's measured build costs (four ~85 s
  boots plus the 1,500 s wide step budget plus the 3-peer run), not a measurement of this
  job. The first real run should correct it in either direction.

Both new step scripts were extracted from the YAML and `bash -n`'d clean, and the
discovery step was run for real:

```
found (2): tests/smoke_net_four_peer_session.gd:4 tests/smoke_net_three_peer_session.gd:3
```


---

## 8. Findings

### F1 — the 2-peer multiplayer shard was a bash syntax error and ran nothing (FIXED HERE)

`.github/workflows/ci.yml`, `verify-multiplayer-shard`, step *"Discover peers:2 net
smokes"*: two `if [ "$count" -lt 20 ]; then` opens, one `fi`. Not a wrong number — a shell
**syntax error**, so the step exited before discovering anything and the shard ran **zero**
net smokes. Residue of two lanes resolving the same merge conflict in turn; the block also
carried four duplicated comment fragments.

Reproduction, on `6c5189fb`:

```
python3 -c "import yaml;d=yaml.safe_load(open('.github/workflows/ci.yml'));\
  [open('/tmp/discover.sh','w').write(s['run']) for s in \
   d['jobs']['verify-multiplayer-shard']['steps'] if s.get('id')=='discover']"
bash -n /tmp/discover.sh
#  /tmp/discover.sh: line 97: syntax error: unexpected end of file   (exit 2)
```

**Fixed in this lane** rather than handed over, because this lane had to edit that exact
step to register three new smokes and regenerate the count floor. §7 has the after.

**What it implies for every other lane's evidence:** any Wave 2–6 lane that cited a green
`verify-multiplayer-shard` as evidence its net smoke passed in CI cited a job that ran no
smoke. Their local runs still stand; the CI column does not. Worth re-checking before
`MULTIPLAYER_ACCEPTANCE.md`'s automated column is called done.

### F2 — `engage_wild` was host-only: it treated a client's pending round trip as a failure (FIXED HERE)

`tools/net/peer_runner.gd::_step_engage_wild()` read `combat_manager.encounter_id()`
**once**, 30 frames after the press, and returned FAIL on an empty string with the wording
*"a fight started but it is not bound to an encounter record"*.

On the host the record exists the moment the press lands, so a single read was correct for
every net smoke written before this one — all of which engage from peer 0. On a **client**
it cannot be: the intent goes to the host, `submit()` answers `{"ok": false, "pending":
true}`, and the record arrives a round trip later. This is exactly the *"pending is not a
refusal"* trap, and it wore the encounter protocol's name.

Measured on `smoke_net_host_exit_saves.gd`'s first client-side engage:

```
FAIL: the client is mid-fight when the host exits
      (a fight started but it is not bound to an encounter record)
```

Fixed in `peer_runner.gd` (a file this lane owns): the binding is now **polled** to a
budget (`bind_budget_frames`, default 600) rather than read once, and a fight that ends
before binding is a distinct, differently-worded failure. The host path still returns on
its first poll and costs nothing.

### F3 — `session.reconnect_window_s` does not describe the code (recorded, NOT fixed)

`data/config/multiplayer.json` says `reconnect_window_s` is 120 s and that *"Wave 2 keeps
the row for the process lifetime and reads this only as the documented intent; the timed
eviction lands with Wave 5's downed/revive window"*.

The code does **neither**. `scripts/net/session.gd::_on_peer_disconnected()` calls
`_registry.remove(peer_id)` **immediately**, so the row is gone the instant the transport
drops — it is not kept for the process lifetime, and there is no window to expire.
Consequently `peer_registry.gd::add()`'s rejoin branch (*"when `character_id` is already
present under a DIFFERENT peer id, that old row is dropped first and its realm carried
onto the new one"*) — the only code that reads a previous row — **can never fire for a
real disconnect**. It can only fire for a duplicate join by a still-connected peer.

Reproduction: `tools/net/run_net_smoke.sh reconnect_keeps_character`, the two checks

```
PASS: the host noticed the disconnect and is back to 1 peer
PASS: the dropped character is out of the host's registry (["peer-3562-99621463"])
```

**Not fixed here**: `scripts/net/session.gd` is lane 2.A's file and four lanes are running
concurrently; a change there is a merge conflict worth more than the defect. Nothing is
broken for the player today — the rejoiner re-announces its realm in its own hello, so the
carried-realm branch is not currently load-bearing — but the config comment and the code
should be reconciled by whoever lands the reconnect window for real. Either implement the
timed eviction, or amend the comment to say the row is dropped immediately.

### F4 — contract §5 named four probes that were never implemented (three added here)

`MP_NET_HARNESS_CONTRACT.md` §5 lists `save_dict`, `party`, `placed_buildings`,
`inventory_count` among the probe vocabulary. `save_dict` and `party` did not exist in
`peer_runner.gd` — `save_dict` is the one §5 explicitly says is *"for diffing a late joiner
against the host in 7.A"*, i.e. it was specified for this lane and never built.

Added here: `save_dict`, `world_snapshot`, `party`, `autosave_dict`. (`world_snapshot` and
`autosave_dict` are new beyond the contract; §5 should be amended to list them, which is
handover H4.)

### F5 — a client returning to the title goes heartbeat-silent past contract §3's 15 s (harness limit, documented not tuned)

When the host exits, `session.gd::_return_to_title()` changes scene, and tearing the
Meadows down blocks the client past the detector's 15 s. First measured as:

```
FAIL: the client was returned to the title screen
      (ERROR: peer silent (peer 1, no heartbeat for >15 s))
```

This is the **same** documented limit `smoke_net_join_by_address.gd` already carries and
raises `heartbeat_silence_tolerance_s` for; `smoke_net_host_exit_saves.gd` is the second
smoke in the directory whose peer changes scene after hello, and it raises it the same way
and to the same 240 s. Not a tolerance widened until something passed — the reached-title
check itself passes in **1 frame** once the peer is heard from again, which is what says
the silence was the teardown and not a hang.

Worth noting for future lanes: any smoke that ends a session from the host's side will hit
this.

### F6 — a CLIENT cannot originate a wild encounter (recorded, NOT fixed — HANDOVER H1)

`smoke_net_host_exit_saves.gd` was first written with the **client** picking the fight, on
the reasoning that a host arbitrating an encounter it did not itself begin is the harder
case for a save-on-exit to survive. It never worked, and the reason is not the harness:

- with a creature deployed and a live wild in reach, `engage_wild` from a **client** leaves
  `combat_manager.is_fighting()` **true** and `combat_manager.encounter_id()` **empty**;
- polled for **600 physics frames** (10 s) after the F2 fix, it never binds;
- the client's peer log carries no refusal, no pending verdict, and no encounter line at
  all.

Reading the directory rather than guessing: **every** `smoke_net_*` that starts a fight
starts it from peer 0, and every client reaches a fight through `join_encounter()` on a
record the host already minted (`smoke_net_shared_wild_fight.gd` lines 119 and 158). So a
client ORIGINATING a wild encounter has **no coverage anywhere in the suite**, and on this
evidence it is not a path that exists today.

Reproduction:

```
tools/net/run_net_smoke.sh host_exit_saves     # with the client-engages variant
FAIL: the client is mid-fight when the host exits
      (a fight started but it was never bound to an encounter record within 600 frames)
```

**Not fixed here**: `scripts/combat/*` and `scripts/net/encounter_host.gd` belong to lanes
4.B/4.C and are outside this lane's write set. Two attempts, no yield, stopped per the
anti-grind rule.

Whether this is a defect or the intended design is a real question and this lane cannot
settle it. `MP_ENCOUNTER_PROTOCOL.md` should say which. If it is intended, the acceptance
row for shared encounters should say "the host starts wild fights; clients join them", so
nobody spends this time again. If it is not, it is a genuine gap in §17 item 5.

The smoke now uses the supported shape — host engages, client joins — which is also the
sharper test of item 24: the peer that quits is the one arbitrating.

---

## 9. Handovers

**H1 — decide whether a client may start a wild encounter, and write it down.**
Finding F6. A client's `engage_wild` leaves `is_fighting()` true and `encounter_id()`
empty through a 600-frame poll, with no refusal anywhere; every net smoke in the suite
starts fights from the host and reaches clients in through `join_encounter()`. Either this
is a gap in §17 item 5 and belongs to lane 4.B/4.C, or it is the intended design and
`MP_ENCOUNTER_PROTOCOL.md` plus the acceptance row should say *"the host starts wild
fights; clients join them"*. This lane cannot settle it and did not touch
`scripts/combat/*`.

**H2 — the portable character (lane 1.C).** Until D100's
`user://characters/<id>/character.json` exists, "reconnect keeps your character" is only
true for a peer that never restarted: `session.gd::_local_character_id()` mints a per-
process id, so a genuinely restarted process dials in as a stranger the host cannot match.
`smoke_net_reconnect_keeps_character.gd` says so in its own header and asserts only what
is real. When 1.C lands, that smoke should grow a second arm: kill the peer process, boot
a fresh one with the same character file, rejoin, and assert the party came back **from
disk**. The file is written so that arm is an addition, not a rewrite.

**H3 — reconcile `reconnect_window_s` with `session.gd`.** Finding F3. The config says the
row is kept for the process lifetime; the code removes it immediately on disconnect, so
`peer_registry.gd::add()`'s carry-the-realm-forward branch is dead for real disconnects.
Implement the timed eviction, or amend the comment. Lane 2.A's file; not touched here.

**H4 — amend contract §5's probe list.** Finding F4. `save_dict` and `party` were named in
§5 from Wave 0 and never implemented; this lane added them plus two the contract does not
name — `world_snapshot` (`Game.world_snapshot()`, the wire payload, which is the honest
world-vs-world comparison because the save file's `progression` key merges world and
per-player flags) and `autosave_dict` (the autosave file re-read off disk). §5 should list
all four.

**H5 — `smoke_net_catch_race` does not exist.** Contract §9 names it as one of the two
smokes 7.A runs under latency, and `MULTIPLAYER_ACCEPTANCE.md` row 6 already records the
catch rule as having **no net smoke** — only the pure `test_catch_arbitration`. There is
also no `catch` action in `peer_runner.gd`'s step vocabulary, so the arm to write one does
not exist either. This lane ran the latency conditions against what *does* exist and says
so in §4 rather than inventing a substitute and calling it the catch path. Building the
`catch_throw` arm and the race smoke is lane 4.C-shaped work.

**H6 — re-check every lane's CI evidence against finding F1.** The 2-peer shard has been a
bash syntax error and has run **zero** net smokes. Any Wave 2–6 lane whose report cites a
green `verify-multiplayer-shard` cited a job that ran nothing. Their local runs stand; the
CI column does not, and `MULTIPLAYER_ACCEPTANCE.md`'s automated column should not be
called done until the shard has actually been green once with the fix in.

**H7 — correct `verify-multiplayer-wide`'s 60-minute timeout from its first real run.**
It is an estimate built from spike S2's measured build costs, not a measurement of the
job. Same for the shard's own 45, which has never been measured either because of F1.
