# Gate 3 coordinator brief

Written 2026-09-03 by the Gate 2 coordinator, for whoever runs Gate 3.

Read `docs/00_START_HERE.md`, `CLAUDE.md` and `docs/ROADMAP.md` §"Gate 3" first. This
file does not replace them. It answers one question they do not: **can Gate 3 start
before Gate 2 is called done, and if so, on what?**

Short answer: **yes, start now, but not on everything.** The reasoning and the exact
carve-out are below, because the carve-out is the whole point.

---

## 1. You may start before Gate 2 is done. The repo already works this way.

`docs/ROADMAP.md` calls these "sequential gates," which reads like a hard bar. It is
not, and Gate 1 is the precedent: its four owner-hardware checks are recorded as
"**not** blockers for starting Gate 2, but they are blockers for calling Gate 1 done."
That is exactly the distinction you need. Apply it.

`CLAUDE.md`'s hard rule "no Biome 2 implementation until the Meadows passes its exit
gate" does **not** apply to you. Bands 2–5 *are* the Meadows. Gate 3 is in-scope work,
not a jump ahead.

---

## 2. The one thing that can invalidate your work, and it is not a merge conflict

Gate 3's objective defines its own acceptance **by reference**:

> Each band passes **the Gate 2 standard** and its Gate F segment (S04–S10).

At the time of writing, that standard is under active question. Gate 2's task list
(2.1–2.7) has **completed**, and the standing blind judge still answers **no** to both
bar questions. That is not an unfinished task. The gaps that judge names — props,
fence, signposts as set dressing, the mill's windmill sails, lighting, terrain — are
outside the scope of every one of tasks 2.2–2.7, which are vegetation, creature and
night work. So Gate 2's list can finish while its bar stays unmet. See
`docs/CURRENT_STATE.md` §"Gate 2".

Task 2.8 (the Gate 2 evidence run, lane `GATE-2-EVIDENCE`, running now) was launched
with explicit authority to return any of:

- **(a)** the gate passes on a real played route;
- **(b)** the gate fails, with scoped follow-up tasks;
- **(c) the Gate 2 acceptance bar is itself mis-specified** — it asks vegetation tasks
  to carry a verdict only props/lighting/terrain work could ever deliver.

**If 2.8 returns (c), the standard you are building against changes.** Rebasing does
not fix work aimed at the wrong target. This is why the carve-out below exists.

### What to start on now (robust to the bar changing)

- **Everything Fable owns.** ROADMAP assigns Fable "encounter identity (guardian,
  Captain Vance, the three captains, the Warden), pacing per band, the roster-pressure
  moment before the legendary." None of it depends on the visual acceptance bar.
- **The per-band file-ownership split** that the Sonnet implementation slices need.
  ROADMAP requires "explicit file ownership" per slice; deciding it is free of 2.8.
- **Reading and reconciling the owning prompts**: `63-BAND2-finished-quarry-warrens.md`,
  `64-BAND3-finished-river-relay.md`, `65-BAND4-finished-upper-meadows.md`,
  `66-BAND5-finished-stronghold-approach.md`, `69-STRONGHOLD-chapter-finale.md`, plus
  `57-TEAM-progression-curve`, `58-REWARD-resource-economy`, `61-EXPEDITION-rest-rhythm`,
  `67-FIVE-creature-pressure-and-bond`.

### What to hold until 2.8 reports

- **Per-band visual implementation** — composition, vegetation, density, silhouette,
  legibility passes. This is the only work whose definition of done is in question.
  Holding it costs you little (see §3) and starting it risks redoing it.

Check 2.8's verdict in `docs/CURRENT_STATE.md` before you release the visual slices.

---

## 3. Do not expect much from parallelism. Gate 3 is serial by design.

Gate 2 fanned out to eight lanes because its tasks touched disjoint files. **Gate 3
cannot.** Its stated method:

> run one segment with the Gate F harness, fix every real failure, re-converge that
> segment alone, advance; **never skip ahead**.

Segments, from `docs/acceptance/GATE_F_MASTER_PROTOCOL.md`: S06 Band 2 (quarry,
warrens, guardian), S07 Band 3 (river, relay, captain), S08 Band 4 (ironwood, riding,
three captains, Sigils), S09 Band 5 (stronghold approach), S10a–S10e (finale and world
healing).

So the realistic near-term value of starting early is **the design contracts, not
throughput**. Plan staffing accordingly. Spawning five band lanes at once contradicts
the method and will produce work that has to be re-converged serially anyway.

---

## 4. Branch and merge mechanics

**Start from `main`, not from `claude/do-this-2t7fny`.** As of 2026-09-03 that branch is
content-identical to `main` (`git diff origin/main HEAD` is empty); basing on it only
inherits pre-squash history for nothing. Current `main`: `3c73aab5`.

**Merge `main` in. Do not rebase.** The tree carries committed bake artifacts — a ~29 MB
scatter binary plus 64 Terrain3D region files. A rebase replays every commit onto changed
bake outputs and conflicts on each manifest; a merge is one resolution. The
`tests/fixtures/band_split_baseline/` mirror rule (§5) makes rebase riskier still.

---

## 5. The trap that will make your CI red, stated plainly

This cost the Gate 2 coordinator two red runs in one day, the same mistake twice.

There are **two independent bakes**, each with its own CI freshness guard:

| Bake | Output | Fed by | Guard job |
|---|---|---|---|
| Scatter | `data/scatter/playground` | `data/config/vegetation.json`, **every** `data/config/bands/*/vegetation.json`, `terrain_playground.json` | `verify-scatter-bake-freshness` |
| Terrain | `data/terrain/playground` | `data/config/terrain_playground.json` | `verify-terrain-bake-freshness` |

Three things follow, and all three bit us:

1. **Band 2–5 vegetation edits invalidate the scatter bake globally.** It is one bake for
   the whole world, not one per band. Your band work will trip it.
2. **A `_comment` string is enough.** The fingerprint covers the config file, not just the
   values that affect placement. Both re-bakes on 2026-09-03 changed *only*
   `config_fingerprint` — every region file byte-identical — because a merge changed
   comment text. The world was unchanged; the guard still failed.
3. **Bake after the merge, once. Never before.** Two lanes each baking against their own
   config produces a merged tree that is fresh for neither. That is precisely what made
   PR #29 red.

Commands and measured cost on the standard container:

```
godot --headless --path . --script scripts/world/build_playground_terrain.gd   # ~32 min
godot --headless --path . --script scripts/world/bake_playground_scatter.gd    # ~10 min
```

Commit region files **and** `manifest.json`. Run them concurrently — they are independent
(scatter samples `playground_heightfield.gd` from config, not the terrain bake output).

**Also:** `tests/fixtures/band_split_baseline/` is a *tracked mirror*. A deliberate
identity move must be made **twice** — live config and mirror — in the same commit, with a
`_why_*` rationale whose text matches **exactly** on both sides. A near-miss in wording
fails the comparison.

---

## 6. Process rules worth more than they look

From `CLAUDE.md` and paid for in real time:

- **A CI run under five minutes verified nothing.** Confirm the code jobs actually ran.
  A healthy full run here is ~25–45 min.
- **A retry that turns 0-for-1 into green is a finding, not a pass.**
- **A self-report is not evidence.** Check the branch and the run. Lanes reported "tests
  green" on work that was already on `main`, and reported "pre-existing failures
  confirmed" for something that was not a test failure at all.
- **Verify what changed, not what you changed.** The PR #29 failure was exactly this:
  re-baking scatter, seeing it green, and never asking what else the edited config fed.
- **Never `--headless` together with a rendering driver.** It hangs.
- **Commit evidence verdicts, not payloads.** 49% of commits in one recent three-day
  window were evidence dumps; 2.8 GB of screenshots. Do not add to that.
- **Address inventory by item identity, never by slot number.**

---

## 7. State as of this writing

- `main` = `3c73aab5`. Gate 2 tasks 2.1–2.7 all landed. Both bakes fresh.
- **Lane `GATE-2-EVIDENCE` (task 2.8)** — running. Its verdict gates your visual slices.
- **Lane `FENCE-CORNER`** — running, branch `ralph/FENCE-CORNER-0903`. Concerns the
  concave corner past TrailGate in `village_boundary.json` that the scripted walk cannot
  round. Its open question is whether that is a **world** defect or a **harness** defect
  (`stick_navigator.gd` lives in `tests/helpers/`). If it lands as a world fix touching
  `village_boundary.json`, it does not touch a bake input — but check before assuming.
- Open P1/P2 issues you may inherit are listed in `docs/CURRENT_STATE.md` §3. Two worth
  knowing: the tutorial catch is unstable across KO/re-engage rounds, and Bramblebun's
  `field_emission` (raised to 2.5 for daytime grass separation) reads as a self-lit glow
  at night because the multiply is not time-of-day scaled.

---

## 8. The standard that does not change

Whatever 2.8 decides about the visual bar, this does not move — `CLAUDE.md`:

> A region or system is not done because code and data exist. It is done when the
> complete player path produces the intended Tetherbound experience.

An honest fail with a scoped task list is worth more than a manufactured pass. If a band
does not read as the intended experience, say so and say what it would take.
