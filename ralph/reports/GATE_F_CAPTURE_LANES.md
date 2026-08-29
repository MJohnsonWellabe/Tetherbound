# Gate F run 3 — the capture lanes, and why not one of them ran

**Date:** 2026-08-28. **Branch:** `ralph/GATE-F-RUN-3`.
**Run directory:** `ralph/reports/gate-f-run-20260828T183531Z`.
**Candidate:** `main@26f0db4`.
**Companions:** `GATE_F_RUN_3_FINDINGS.md` (the game),
`GATE_F_RUN_3_RIG_FINDINGS.md` (the instrument).

## The one-sentence version

**No pixels were captured in this run, on purpose, and the debt is recorded
rather than erased: 274 prescribed §G frames across 16 capture lanes, plus the
§H continuous-record windows, all authored, all checked, all unpaid — and they
need a host with a GPU.**

## Why, in numbers measured on this box

| measure | value |
|---|---|
| `Performance.TIME_PROCESS` per **rendered** frame, 1920×1080, llvmpipe | **12,721 ms** |
| the same scene in **logic** mode | **6.1 ms** |
| what the eighteen segments ask for | **4,607,802 physics frames** |
| ⇒ the whole protocol in capture mode | **~8,283 hours** |

Eight thousand two hundred and eighty-three hours is three hundred and
forty-five days. That is llvmpipe software rasterisation with **no GPU**. It is
a fact about the container, **not a statement about Tetherbound**: device frame
rate remains `[OWNER-ONLY]` per §0.4, and `data/config/grass_field.json` in
particular is settled owner-approved art that no Gate F finding may touch.

The logic lane's own price, re-measured on **this** container by the pre-flight:
0.0059 s/frame on the empty tree, 0.0065 s/frame on the title, 0.0166 s/frame in
the standing Meadows — still roughly **765× cheaper** than one rendered frame.

## What is affordable, and therefore what the capture lanes are

The decisive second measurement is that **capture itself is not the problem.**
`tools/_probe_grass_pass.gd` took **14 real 1920×1080 frames across four bands in
about 28 minutes** on this same container with the grass field on. Frames from
targeted probes are cheap. **4.6 million rendered physics frames are not.**

That is the whole of §H.1's split. A capture lane does not play the segment; it
reaches a named state — a boot for the title, otherwise the logic lane's nearest
save, seeded and loaded and staged forward by a short scripted approach — takes
the frame, and stops. Production paths still hold (§0.6): the state being
photographed was produced by production play.

## The ledger

`tools/gate_f/run_inventory.py` over the run directory is the authority; it
writes `RUN_INVENTORY.json` and `RUN_INCOMPLETE.md`. Every id below is
**DELEGATED**, not skipped and not failed: the logic lane that would have taken
it named the lane that owes it, before it started, and the pre-flight refused to
let it start unless that lane existed, declared `evidence_lane: "capture"`, and
accepted the id in its own `owes` list.

| capture lane | §G frames owed | §H record windows | steps authored |
|---|---|---|---|
| `S01C` | 1 | 0 | 7 |
| `S02C` | 8 | 0 | 55 |
| `S03C` | 7 | 0 | 210 |
| `S04C` | 45 | 0 | 53 |
| `S05C` | 9 | 2 | 55 |
| `S06C` | 7 | 1 | 70 |
| `S07C` | 5 | 1 | 66 |
| `S08C` | 7 | 1 | 80 |
| `S09C` | 4 | 1 | 42 |
| `S10C` | 66 | 0 | 86 |
| `X01C` | 8 | 0 | 222 |
| `X02C` | 4 | 0 | 75 |
| `X03C` | 14 | 0 | 145 |
| `X04C` | 8 | 0 | 100 |
| `X05C` | 1 | 0 | 13 |
| `X07C` | 80 | 0 | 239 |
| **total** | **274** | **7** | **1,518** |

The §H windows are new to this run's ledger: before commit `4e23c92` a logic lane
re-armed the recorder from a `record_start` step's own args and then wrote itself
INCOMPLETE for frames it had never undertaken to take (`RIG-9`). They are now
handed over on the same terms as a §G id, and appear in each segment's
`DELEGATED.md` and in `INVENTORY.json` under `frames.delegated_windows`.

## What the missing pixels cost this run's conclusions

Everything below is a question this run **cannot answer** and does not pretend
to. It is not a list of defects; it is the shape of the hole.

- **Every §G judgement.** Whether the village reads as a settled place, whether
  the fight reads as a fight, whether the aim reticle communicates, whether the
  night is legible, whether the weather presets hold the palette, whether the
  Warden's arena lands. All of it is delegated and unpaid.
- **The §H continuous record**, which is the substitute for video the protocol
  chose. Seven windows across five band handoffs and two crossings.
- **Anything about HUD legibility, prompt clarity or first-read comprehension.**
  §E.5's navigation study is transcribed in this run as reasoned notes over the
  telemetry, and every one of those notes says which frame it was *reasoned
  from* — a frame that does not exist. Those notes are honest about their own
  provenance and should be read as hypotheses, not observations.
- **`GAME-2`'s open question** — whether a player who loads a save is actually
  told they have no creature out — is precisely a "what is on screen" question,
  and it is unanswerable here for the same reason.

## What it would take to pay this

A host with a GPU. Nothing else about the lanes changes: they are authored,
their `owes` lists are checked against what their steps actually shoot (a lane
naming an id no step of it takes is a BLOCKER — CD-1's `file: null` PASS wearing
a different label), and the pre-flight that gates them is the same one that
guards the logic lanes.

On such a host the order that gets the most for the least is:

1. **`S02C`** — 8 frames. The opening is the chapter's front door and the run
   has proven the beats work; what nobody has seen is what they look like.
2. **`S01C`** — 1 frame. The title screen. One boot, no save.
3. **`S05C`, `S06C`, `S07C`, `S08C`, `S09C`** — 32 frames and 6 record windows
   between them: the band handoffs, which are where §E.7's regional identity
   claim lives.
4. **`X07C`** — 80 frames, the DIAG world audit, every region and its day/night
   and weather variants. The largest single block, and the one that can run from
   any save with teleport permitted, so it is also the least coupled to the
   journey's state.
5. **`S04C` and `S10C`** — 111 frames between them, the tournament final and the
   finale. Both are **blocked on `RIG-11` being fixed first**, because a capture
   lane seeds from the logic lane's save and neither of those states exists in
   this run: the tournament was never fought and the finale never reached.

That last point is the one to carry: **fixing the instrument comes before buying
the GPU.** Photographing the states this run actually produced would photograph a
tournament nobody entered.
