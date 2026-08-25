# Gate F lane — stage-boundary log

This lane runs in its own container (session `tetherbound-2c`) and cannot reach
the coordinator session (`tetherbound-06`) by message — `ListAgents` shows no
cross-session peer from here, and a `SendMessage` to that name returns "no agent
reachable". The mandate requires a check-in at every stage boundary, so the
check-ins are written here instead, where they survive this container being
reclaimed and where the coordinator can read them off the branch.

Stages, per the lane mandate: instrumentation pushed/green -> candidate frozen
(with SHA) -> operator run complete -> provisional backlog hashed -> final
backlog published -> §17 remediation.

---

## Check-in 1 — 2026-08-25 — STAGE 1 (instrumentation build) STARTED

- Container prepped: `apt-get update` first (per the stale-index trap), then
  `libegl1 libegl-mesa0 mesa-vulkan-drivers xvfb`; Godot
  `4.7.stable.official.5b4e0cb0f` from `tools/art_pipeline/setup.sh godot`;
  `--headless --path . --import` building `.godot/`.
- Branch `ralph/GATE-F-INSTRUMENTATION` at `c196e18a` = `origin/main` `636673ce`
  plus Fable's completed Phase A commit.
- Developer subagent building `ralph/GATE_F_INSTRUMENTATION_REQUEST.md` in full:
  `tools/gate_f/operator_harness.gd`, `scripts/debug/gate_f_probe.gd`,
  `tools/gate_f/run_segment.sh`, `tools/gate_f/SEGMENT_SCHEMA.md`, tests.
  Prime directive enforced: no gameplay path changes behavior, accessors are
  additive and read-only, telemetry only under a CLI flag, telemetry reads live
  game state. No `vram` and no device-fps field exists in the schema at all.
- Phase A is NOT being redone. It is Fable's and it is done.

Nothing is pushed yet. When the branch is green it needs the coordinator's
`ralph-sweep.yml` dispatch — this lane does not push to `main` and does not open
pull requests.

---

## Check-in 2 — 2026-08-25 — §16.1 register frozen (210 items)

`ralph/reports/gate-f-historical-snapshot.md` is committed and pushed at
`34d1a368`. It is the §16.1 freeze: every unresolved historical item, enumerated
and stable-IDed, taken before the playtest so reconciliation has a fixed base.

**Read restrictions carried by that file, and enforced by this lane:**

- the Gate F operator must never read it during the run (§16.1 blind-first);
- Fable must not read it before its provisional backlog is hashed (§16.2).

Both are on the same branch as the protocol, so the restriction is procedural,
not structural. Every operator and Phase B brief this lane issues names the file
explicitly as forbidden rather than trusting the agent not to wander into it.

### Counts

| | first pass | after gap-closing sweep |
|---|---|---|
| total enumerated | 145 | **210** |
| player-facing | 106 | **162** |
| not player-facing | 29 | 36 |
| superseded/obsolete candidates | 8 | 10 |
| owner-reported | 40 | 45 |
| §16.5 denominator bracket | 67–101 | **108–156** |

The register was returned once. The first pass disclosed its own gaps — the
visual reports grepped rather than read, `ralph/lanes|ledger|planning` never
opened, and eleven of sixteen `OP` owner items closed by inference from
`PROMPT_COMPATIBILITY_MAP.md` rather than by a closing record. Closing those
three gaps found 65 further items, 55 of them in the visual reports alone.

That is worth recording as a method result, not just a number: **an omission in
this register is invisible at reconciliation and silently raises the capture
rate**, because an item nobody enumerated cannot be scored as missed. A
misclassification, by contrast, is Fable's to catch. Omission and
misclassification are therefore not symmetric risks, and the register was built
to over-include deliberately. The residual risk is now over-inclusion of
visual-report rows that one reproduction will retire — which is what §16.3
category 5 (NOT REPRODUCED) exists to absorb.

The denominator is stated as a **bracket, not a number**. 54 of 198 rows are
honestly `unsure`; collapsing them would mean resolving them in whichever
direction flattered the metric, which is the specific thing §16.5 forbids.

### Two findings that are not bookkeeping

**1. `tools/capture_diag_minimal.gd` has never existed in this repository.**
`git log --all -- tools/capture_diag_minimal.gd` returns nothing; it is absent
from `origin/main`. Yet `ralph/conventions.md` cites it as settled fact — the
120-second smoke for the `--headless` + `--rendering-driver opengl3` hang, which
that same file calls "the single most expensive trap in this repo" — and
`GATE_F_INSTRUMENTATION_REQUEST.md` §9 requires capture mode be *gated* on it
passing. So the documented first line of defence against the trap that burned
four capture attempts and ~43 minutes on 2026-08-22 alone was a pointer to a
file that was not there. A session following conventions.md to diagnose a hung
capture would have found nothing to run and, per that file's own account of the
incident, would likely have misdiagnosed it as contention again. The
instrumentation lane had to write the file to satisfy §9.

**2. The game has essentially no world audio, and no backlog item says so.**
`scripts/ui/audio_cues.gd` is the only file touching `AudioStreamPlayer`; the
nine `.wav` files under `assets/ui/audio/` are the only audio assets in the
project. A case-insensitive grep for audio/sound/music across `BACKLOG.md` and
`ACTIVE_GAME_PLAN.md` returns nothing. This is not a deprioritised item — it is
an unenumerated one, and it is a whole missing domain rather than a defect.

The reason it went unenumerated is structural and worth naming: the standing
whole-game sweep is the visual ledger, whose eight domains are visual by
construction, so nothing in the routine process was ever pointed at audio.

**Gate F cannot close this.** §K.6 of the master protocol pre-registers audio as
[OWNER-ONLY] — no audio path exists in this envelope at all, and
`test_audio_cues.gd` covers wiring only. So at reconciliation this will land as
MISSED BY GATE F traceable to a *declared* gap, which the protocol distinguishes
from an undeclared coverage hole. Recording it here so that distinction is made
on the evidence rather than reconstructed later, and so the owner's pass — which
is the only thing that can judge it — gets it in writing beforehand.

Three rows the sweep also refuted against live code, rather than trusting the
prose: every level-up in the chapter aborted its own announcement
(`int(Callable)` on a `get()` that returned a method) while its test stayed green
by asserting on the function's *source text*; the boss-arena defect was the same
root cause as the owner's arena-phasing report; and the 132-module stronghold
silhouette stood 7,708 m from the stronghold the player actually walks to. The
first two are fixed. The third is re-sited but has never been blind-judged.
