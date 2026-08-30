# Handover — T2-GATEF-RUN6, 2026-08-30

**Branch:** `ralph/T2-GATEF-RUN6`, off **`origin/ralph/T2-GATEF-RUN5`**
(not off `origin/main` — see §1), with `origin/main` merged forward at
`5d171130`.

**Commits, oldest first:**
```
df20f356  Merge remote-tracking branch 'origin/main' into ralph/T2-GATEF-RUN6
f9019eb0  S02: the chapter's first fight and first catch, fixed at the rig
49f22985  Gate F findings: the zero-combat verdict, and the two defects behind it
2b039299  X06: split into three parts, each under the harness cost ceiling
```

---

## 1. Read this first: the brief was wrong about the branch base, and it mattered

My brief said to work on `ralph/T2-GATEF-RUN6` **off `origin/main`**.
`origin/main` does not contain RUN5. `git merge-base --is-ancestor
origin/ralph/T2-GATEF-RUN5 origin/main` is false, and `focus_item` — RUN5's
own harness action — appears 0 times in `origin/main`'s
`operator_harness.gd` and 12 times on RUN5's branch. Branching off `main`
as instructed would have silently discarded every RUN5 fix (GAME-8, GAME-9,
the Oskar panel, `focus_item`, the `stick_navigator.gd` rewrite) while the
same brief told me to start from what RUN5 established.

**I branched off `origin/ralph/T2-GATEF-RUN5` and merged `origin/main`
forward**, which is exactly what RUN5 itself did with RUN4. Whoever opens
RUN7 should do the same off this branch until a LAND lands it.

RUN5 is carried on `origin/ralph/LAND-0830G` and `origin/ralph/LAND-0830H`;
neither has landed. **This branch is now the only place the S02 fixes
exist.**

Two smaller brief corrections, for the record: the session was given the
path `/home/user/Tetherbound`, which did not exist — no repo was cloned into
this container and I attached and cloned it myself. And the brief described
GAME-10/RIG-25 as "opens and never closes", i.e. open; RUN5 had already
fixed it for Oskar. The real outstanding work there was the audit, which is
done (§4).

---

## 2. The headline: the zero-combat verdict is **RIG**, and it is fixed

This was the brief's number-one question and the oldest open item in the
run-3 record. The lane log has carried it since check-in 17 (2026-08-27)
with `severity_candidate: BLOCKER` and the wording *"the chapter's first
fight never stages, and the first catch never happens."*

**The game stages the fight correctly. It always did.** Proven live rather
than argued — `tools/gate_f/diag/probe_s02_encounter.gd` pass 4, on this
candidate, standing the player at S02's own recorded press point with a
creature deployed:

```
[s02] engage_range                          = 6.00 m
[s02] nearest wild creature, over 30 s      = 5.99 m min, 5.99 m max
[s02] samples where the game offered Engage = 30 of 30
[s02]    pressed interact: is_fighting false -> true   >>> A FIGHT STARTED
```

Three stacked rig defects were producing the silence:

1. **`S02-30` engaged a coordinate, not a creature.** It walked to a
   hardcoded `(30,-40)` with `close_enough: 4.0`, against a 6.00 m
   `flow.engage_range`, at a creature with a 7 m wander radius whose path
   `_rng.randomize()` re-rolls every boot. The recorded press point measured
   **5.99 m** — one centimetre inside the reach. Which side of that line a
   boot lands on was the whole story.
2. **`S02-32` was a bare `press`.** A `press` asserts that input was
   injected, not that anything received it, so it PASSed into an unengaged
   world every run and pushed the visible failure four steps downstream
   where it read as "combat never took input ownership."
3. **The attack script was tuned against damage numbers that no longer
   exist.** `S02-36` carried an authored "MEASURED, not guessed ~5.8 damage
   each" note. Measured now: quick ~13.4, charged ~56. Run as authored, the
   charged attack **fainted the target** (`104.3 → 91.3 → 78.0 → 63.8 →
   49.4 → 0.0`) and the catch had nothing to throw at.

Fixed with the pattern the protocol already had: `move_to_entity` +
`interact_with` (`S03-32a..j2` has engaged the same species that way for
several runs; S02 was never updated), and a re-ordered, re-measured attack
block.

**S02 now emits `combat_start`, `combat_hit`, `combat_end`, `catch_throw`
and `catch_result` — all of them, for the first time in six runs — and in
one run wrote the first two-creature `S02-exit.json` in this effort**
(Moss lvl 3 + Bramblebun lvl 5).

Findings written up as **RIG-26** and **RIG-27**.

---

## 3. What that uncovered, and it is worse than what it replaced

Fixing the rig made the fight observable for the first time. It is not the
forgiving tutorial the opening documents describe. **Both of these are open
and neither is mine to decide.**

### GAME-11 — the starter loses the chapter's first fight (BLOCKER candidate)

There is no dedicated practice creature.
`encounter_director.gd::wild_creature()` returns whichever of the world's
**64 ordinary seeded bramblebuns** is nearest, and
`data/config/bands/band1_lower_meadows/spawns.json` pins no level on any of
the fourteen bramblebun clusters. So the fight that teaches combat fields a
**level-5, 124 HP** creature against a **level-3, 117 HP** starter —
against `progression.json`'s own tuning comment, which states the chapter's
enemy levels run **"2 at the practice fight."**

Across five RUN6 runs of S02, with the rig fixed and the fight staging every
time:

| | |
|---|---|
| fight staged | **5 of 5** |
| starter FAINTED | **4 of 5** |
| catch landed | **1 of 5** |

The clean losing case: `my_hp 117.6 → 0.0` in 47 s, having removed 28 of the
opponent's 104 HP, with no throw attempted at all.

Two candidate fixes are named in the finding (pin the opening's own practice
creature at a low level via the `level` key `spawn_wild()`'s `opts` already
supports, or floor the band roll near the opening meadow). I recommend the
first because it makes the documented intent true, but **it is a design
call and I did not make it.**

### GAME-12 — after a failed catch the aim re-opens and the throw never fires (HIGH candidate)

`combat_manager.gd:1273` applies `catch_math.apply_failure_bound()`, so with
`max_catch_failures: 1` the **second landed throw is forced to succeed**.
That is the opening's stated "cannot fail twice" promise.

It is unreachable, because there is no second landed throw. I added three
retry blocks; the telemetry shows all three re-entering `combat_aim` and
none of them throwing, across two runs, with 13+ orbs in the bag.

**Not root-caused.** I record three testable hypotheses in the finding
rather than guessing between them. This is the one I would put a probe on
first: a real player whose first throw fails — which at these HP levels is
the common case — is stranded in the beat that gates the road gate, with no
orb resupply before the gate.

---

## 4. The RIG-25 audit RUN5 asked for — done

RUN5 recorded that every shop/battle/picker effect other than Oskar's was
unaudited, and that GAME-10 was found by tripping over it rather than by
looking. Looked.

Ten conversations open a pausing panel, all through
`sequence_director.gd::_maybe_open_shop()` — the `_intro`, plain, `_beaten`
and `_freed` variants for Mira (goods), Bram (goods) and Oskar (creatures).
Cross-referenced against every segment step that greets one of the three.

- **One real gap, closed: `S03C-61`.** `S03.json` got RUN5's
  `S03-62a`/`S03-62b` pair; its capture-mode twin `S03C.json` never did, so
  a capture run of S03C would have reproduced GAME-10 in full — the same
  71-failure cascade, in the lane whose entire purpose is the frames.
- **S04 and X01 cleared with evidence, not by inspection.** S04's Mira and
  Oskar steps are tournament conversations, and RUN5's own S04 telemetry
  shows the segment's whole `input_context` census returning to `world`. X01
  is the menu-cell probe segment and carries 105 context asserts of its own.
- **An unrun risk, flagged rather than closed:** the `_beaten` and `_freed`
  greetings open the same panels after the tournament and after the finale.
  **Nothing in the segment set has ever reached them** — S04 has never been
  won, because GAME-11 starves it. When a future run first wins the
  tournament those panels open for the first time, and the close-and-assert
  pair must be in place *before* that run. That is precisely the
  order-of-discovery trap GAME-10 sprang on RUN5.

---

## 5. X06 — split, and the obvious split was not enough

RUN5 recorded X06 BLOCKED before step 1: 2,525,320 planned frames, predicted
14,960 s against the 14,400 s ceiling, 4% over, wanting the `T2-S10-COST`
treatment.

Splitting at the segment's own entry-save seam is **not sufficient** — worth
knowing, because it is the split anyone would try first. Part 1 (from
S03-exit) prices at ~650 s; part 2 (from S05-exit) still prices at
**~14,863 s**, still over. So part 2 is split again at its own `case 8`
boundary, where the previous case has just closed its menu shell:

```
X06a  180 steps   ~650 s  (0.18 h)
X06b   61 steps  ~7334 s  (2.04 h)
X06c   83 steps  ~7594 s  (2.11 h)
```

Each part re-seeds its own entry save through the real title screen, so
none depends on another having run. Nothing is dropped: 314 original steps
plus one repeated 10-step load preamble in X06c (ids prefixed `X06c-pre-`).
`X06.json` is left in place as the record of what was split.

**Not run.** Priced only. The pre-flight arithmetic is reproduced in the
commit and in each file's `_split` field.

---

## 6. What I did NOT do, plainly

**The segment table is not finished, and it did not move past S02.** The
brief asked me to run it to the end. I did not get there, and I want to be
exact about why rather than leave it as a gap:

- The chain's root blocker turned out to be inside S02 itself, which is
  where the brief's own number-one question also lived. Answering that
  question and fixing it took five full S02 runs (~6 minutes each plus a
  ~35 minute Godot install and import into a bare container).
- **S05–S09 were not run.** Not attempted.
- **X04 was not re-run.** RUN5's chain-gating finding stands unchallenged:
  X04 re-seeds from `S06-exit.json` partway through, so it needs the chain
  out to S06 first. The brief's "S06 first, then X04" ordering is correct
  and I did not get to either.
- **X06a/b/c were priced, not run.**
- **X01, X05, S10 not reached.**
- **The two unbaselined smoke shards** (`smoke_gate_a_build_segment_meadows`,
  `smoke_gate_b_tail`) — baseline started, result in §7. RUN5's warning
  about the navigator swap is real and I ran it under a `trap`-guaranteed
  restore rather than by hand.

**And I did not produce a healthy chain entry save.** The two-creature
`S02-exit.json` happened once in five runs and the run directory currently
holds a one-creature one. **That is GAME-11, not a rig regression** — the
rig now does its part correctly every time and the fight is lost on the
game's own numbers. I deliberately did not hand-author a save to get past
it: that is the option RUN4 raised and declined, and it would make every
downstream "a player could do this" claim conditional on a state no player
can reach. With GAME-11 fixed, a healthy chain entry should follow from the
segment as it now stands.

The findings documents were **updated, not rewritten from `INVENTORY.json`**
as the brief asked. I did not delete a finding I had not disproved, and I
did not carry forward a narrated bug the code has fixed — but a full
regeneration was not something I could do honestly without the run data the
segment table would have produced.

---

## 7. The two smoke shards

RUN5 left these explicitly unbaselined and explicitly refused to claim they
were pre-existing. Result of running each against RUN5's navigator and
against `origin/main`'s:

**Both are PRE-EXISTING. RUN5's `stick_navigator.gd` rewrite did not cause
either.** Run under a `trap`-guaranteed restore (RUN5's warning that the
swap risks committing a revert of the GAME-8 fix is real; the navigator is
verified unmodified afterwards).

| shard | RUN5's navigator | `origin/main`'s navigator |
|---|---|---|
| `smoke_gate_a_build_segment_meadows` | FAIL | **FAIL, identically** |
| `smoke_gate_b_tail` | FAIL | **FAIL, identically** |

The failure text is byte-identical in both directions:

- gate A: *"there is no hammer in the satchel; the village's gift
  (`camp_hammer_given`) comes before any of this segment's work and is not
  this segment's to grant"*
- gate B tail, all three of its failures, including *"only 3 of 5 creature
  beds went up"* and *"'home_built' is done and the tracked objective reads
  'Rest at camp and let a creature recover.'; it should have moved on to
  the beat that says 'Care for your team'"*

RUN5 reasoned from the failure text that neither was navigation-shaped and
said plainly that this was *"reasoning, not measurement."* The reasoning was
correct and it is now measured. **Together with `smoke_gate_b_continuous`,
which RUN5 did baseline the same way, that is three smoke tests red on
`origin/main`** — the navigator's own smoke coverage plus two segment
shards. That is a standing owner item, not a Gate F item, and it is the
second time a Gate F lane has had to discover it by tripping over it.

---

## 7b. CI — I could not verify it, and I am not claiming it

The brief asked for CI kept green **at the job level**, with the warning
that a run-level success lies when the `changes` path filter skips jobs, and
that a full run is 55 jobs with only `verify-continuous-core-known-red` and
`export` as expected skips.

**I could not check.** This session has no GitHub API access — `gh` is not
installed, and the REST API answers every request with *"GitHub access is
not enabled for this session. An org admin must connect the Claude GitHub
App for this organization."* `git push` works (it goes through the session's
git proxy); the Actions API does not.

So: **the branch is pushed and CI status is unverified by me.** Whoever
picks this up should check `ralph/T2-GATEF-RUN6` at the job level before
treating it as green. What I can say about the risk is narrow and concrete:
this branch changes **no game code, data or config** — the diff outside
`ralph/` and `tools/gate_f/segments/` is empty — so the only CI surface it
can plausibly move is any job that validates segment JSON. All 24 segment
files parse (checked locally), and the three new `X06*.json` files carry the
same top-level key set as the `X06.json` they were split from.

---

## 8. What I would do next, in order

1. **Decide GAME-11.** Everything on this chain is downstream of it, the
   same way everything was downstream of S02's one-creature exit before.
   It is one config decision plus a small change; it is not a research
   task. Until it is made, S02's exit save is a coin toss and S04's
   tournament can never be entered.
2. **Probe GAME-12.** One live probe of the shape
   `probe_s02_encounter.gd` already uses answers it. It is the difference
   between "the tutorial catch is forgiving" being true and being a comment.
3. Re-run S02, confirm a two-creature exit save reproducibly, **then** chain
   S03 → S06 before touching X04 (RUN5's ordering, still correct).
4. Run X06a/b/c. They are priced and ready and need nothing from the chain
   except S03-exit and S05-exit.
5. Re-measure every `observation` field in the segment set that quotes a
   damage, HP or timing number. RIG-27 found one stale by a factor of 2.3
   that had misled four sessions; there is no reason to think it is the only
   one, and an authored note carrying a superseded measurement is
   indistinguishable from one carrying this run's.

---

## 9. File footprint

**Segment data:** `tools/gate_f/segments/S02.json`, `S02C.json` (engage via
`move_to_entity`/`interact_with`; attack block re-ordered and re-measured;
three catch retry blocks; party assert moved after them),
`S03C.json` (RUN5's `S03-62a`/`62b` pair, which it never received),
`X06a.json`, `X06b.json`, `X06c.json` (new, the cost split).

**Docs:** `ralph/reports/GATE_F_RUN_3_FINDINGS.md` (GAME-11, GAME-12),
`ralph/reports/GATE_F_RUN_3_RIG_FINDINGS.md` (RIG-26, RIG-27, the RIG-25
audit), this file.

**Evidence:** `ralph/reports/gate-f-run6-chain/` — S02 and its
`RUN_METADATA.json`.

**Not touched:** no game code, data or config. `git diff <base>..HEAD --
. ':(exclude)ralph/' ':(exclude)tools/gate_f/segments/'` is empty. GAME-11
and GAME-12 are both reported rather than fixed, deliberately: the first is
a design call, the second is not root-caused.
