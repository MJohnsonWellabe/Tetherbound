# Gate F — the capture lanes, and what each prescribed frame costs to reach

**Date:** 2026-08-28. **Branch:** `ralph/GATE-F-RUN-3`.
**Subject:** §H.1's evidence split, extended from S01 to every remaining segment.
**Companion:** `ralph/reports/GATE_F_RUN_3_FINDINGS.md` — what the logic lanes found.

This document is the ledger of the **unpaid half** of Gate F run 3. The logic
lanes ran; the capture lanes did not, and cannot on a box with no GPU. What
follows is what they owe, what each frame costs to reach, and what a GPU host
would have to be able to afford.

---

## 1. What the split now covers

Before this branch, exactly one segment declared a lane: S01 (logic) handing
`GF-01-TITLE-01` to S01C (capture). Every other segment still declared
`evidence_lane: "both"`, which under the measured envelope means a segment
owing its own §H continuous record — the 4,607,802 rendered physics frames,
~8,283 hours, that the split exists to delete.

| | before | after |
|---|---|---|
| logic lanes | 1 | **18** |
| capture lanes | 1 | **16** |
| prescribed frames accepted by a capture lane | 1 | **274** |
| segments still declaring `both` | 17 | **0** |

X06 and X08 declare `logic` with **no** capture lane, which the harness
allows: they take no prescribed frame, so they hand nothing over. The
declaration still earns its place on X06, which otherwise inherits §H's default
0.1 Hz continuous record.

## 2. The capture lanes are derived, not rewritten

§H.1 says a capture lane "reaches a named state the same way the journey did".
That is a claim about provenance, and the only way to make it check out is for
the capture lane's path to **be** the journey's path. So
`tools/gate_f/derive_capture_lane.py` builds each `<id>C.json` from its logic
lane mechanically: every step up to and including the last capture is kept
verbatim, and only what photographs nothing is dropped — `note`, `defect`,
`probe_cell`, `save_out`, and the four pacing asserts that are claims about the
journey rather than about the state. Step ids carry their origin in
`_derived_from`, and `--check` fails if a source segment and its capture lane
have drifted apart.

The saving is not uniform, and where it is large it is large for a reason:
**X01 goes from 1,203 steps to 222**, because 1,100 of them are the §8 input
matrix, which is logic-lane work that photographs nothing. That is the split
doing exactly what it was designed to do.

## 3. Reachability — the part a generator cannot decide

`S01C.json`'s own comment draws the line: *"A title screen needs only a boot; a
mid-dialogue or mid-fight frame is not a saveable state."* Honouring that means
classifying every frame, so each capture lane carries a `_reachability` block:

| class | what it means | what it costs |
|---|---|---|
| **A** | reached from a cold process by the production front door alone | a boot (and, for the wake beat, the ~90 s cold world stand-up) |
| **B** | a place the seeded save restores, with its preconditions already met | a load and a short walk — **the only class anybody should call cheap** |
| **C** | an event no save holds: mid-dialogue, a thrown lure, a level-up, a ceremony screen | the staging. And the frame is of *an* instance of that state, not of the journey's instance |
| **D** | a state whose preconditions the seeded save does **not** carry | the staging includes the segment work that produces them. Class D is where "a short scripted approach" stops being true |

### The distribution

| class | frames | share |
|---|---:|---:|
| A | 1 | 0.4% |
| B | 102 | 37% |
| B? | 1 | 0.4% |
| C | 93 | 34% |
| D | 76 | 28% |
| **total** | **273** | (+1 for S01C's hand-written frame = 274) |

**That 37% is not the good news it looks like.** Seventy-eight of the 102
class-B frames are X07's, and X07 is `DIAG`: it reaches its ten sites by the
Settings debug teleport and pins clock and weather, which is permitted there
and only there — and which costs §0.6's other half, that no pacing, navigation,
difficulty or economy claim may ever be sourced from those frames. They are a
look at the world, not at the journey.

**Outside X07, only 24 of 194 prescribed frames are cheap.** The rest are
events that have to be restaged or states that have to be played to.

### Per lane

| lane | frames | steps | classes | the honest note |
|---|---:|---:|---|---|
| S01C | 1 | 7 | A | the worked example; a wipe and a boot |
| S02C | 8 | 55 | A 1, C 6, D 1 | **no save exists to seed from** — the chapter's first slot file does not exist until S02 makes it, so this lane is the opening replayed |
| S03C | 7 | 210 | B 2, C 2, D 3 | map and street are cheap; the three night frames need *natural* nightfall and `pin_clock` is DIAG-only |
| S04C | 45 | 53 | C 45 | the tournament is one production sequence; 40 of the 45 are the bounded final-round seq |
| S05C | 9 | 55 | B 6, C 2, D 1 | the segment where the split pays best |
| S06C | 7 | 70 | B 2, C 2, D 3 | quarry cheap, Warrens interior not |
| S07C | 5 | 66 | B 2, C 2, D 1 | the rescue frame is the segment's own outcome |
| S08C | 7 | 80 | B 3, B? 1, C 3 | `GF-19-UI-09` wants 5/5 — B or D depending on what S07-exit carries |
| S09C | 4 | 42 | C 3, D 1 | short lane; the gate *opening* is a moment, not a state |
| S10C | 66 | 86 | **D 66** | every frame is behind the Warden. The finale played through |
| X01C | 8 | 222 | B 8 | cheapest deep lane, and the biggest structural saving in the run |
| X02C | 4 | 75 | C 4 | the "seconds of play per frame" case S01C had in mind |
| X03C | 14 | 145 | C 14 | seven aim/resolve pairs; a thrown lure is the least saveable state in the game |
| X04C | 8 | 100 | C 8 | eight fights, from three journey saves |
| X05C | 1 | 13 | B 1 | 313 steps of lifecycle telemetry, one frame |
| X07C | 80 | 239 | B 78, C 2 | cheapest **per frame** by DIAG permission; largest block in the protocol |

## 4. Three things a GPU host has to know

1. **Run the capture lanes into the same run directory as the logic lanes.**
   Every `seed_save` resolves `run://` against that directory's saves. A
   capture lane run anywhere else has no chapter to load and stops at its first
   seed.
2. **S10C cannot be broken up.** There is no save between `S09-exit` and the end
   of the chapter, so 66 of the run's 274 frames sit behind one continuous
   playthrough of the finale. Whatever host runs it has to afford that one
   entire.
3. **The obvious economy, deliberately not taken here.** Several class-D frames
   are *places* that are only expensive because the seeded save predates a flag
   the segment itself sets — `GF-07-BRIDGE-02` standing on the South Bridge is
   the clearest. Seeding the segment's own **exit** save instead turns those
   into class-B walk-backs. The price is a real evidence caveat: the frame then
   shows the bridge at the end of S05 rather than at the moment it opened. The
   generated lanes keep the journey's own path; this is recorded as the first
   economy to consider if a GPU host still cannot afford them, so that the
   trade is made deliberately rather than discovered later in a manifest.

## 5. Recommended next rig change, not made here

Class C and class D are expensive because the **nearest save is not near**. The
logic lane is cheap and could afford to drop checkpoint saves immediately
before each staged encounter, which would turn most class-D staging into class
C and most class C into a handful of presses.

It is not done on this branch, and the reason is worth recording rather than
quietly deciding: a checkpoint is a production Save-tab visit, so inserting one
into a journey segment changes what that segment measures — §D reads pacing and
dead travel out of `route.csv`, and sixteen extra menu visits are sixteen
interactions the journey did not naturally contain. That is a coordinator's
call about the protocol, not a lane's call about a file.
