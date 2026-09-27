# F14#1 C3: code-blind judge, round 1 — FAIL (both fights)

**Judge.** A fresh code-blind subagent. It saw only the PNGs and `*_frames.json` (tag, fight time, opponent, measured `tell_s`, gap), plus the ACCEPTANCE C3 and COMBAT §5 camera bar as text. It saw no source and no change narrative.

**Frames.**
- **Nerissa:** 27 frames from `tests/capture_tidewake_named_fights.gd --pilot=READER --level=43`, render.yml run 36282801751 at 82e9abb9. The READER pilot won in 306.8 s and reached all four send-outs, including Riptusk's 1.1 s tells.
- **Venn:** 17 frames from the local capture at a8c881d0, after the ring-clearance and greet-mute fixes (quick pilot, first two send-outs).
- Representative frames are in `frames/`.

**Setup (partial by the strict rule):** a granted L43/L53 party, the player placed at the trainer, Nerissa's pump flags set.

## Verdict
| Fight | Tell readability | Framing (both fighters + tell clear) | Overall |
|---|---|---|---|
| Nerissa | FAIL | FAIL: 17/27 (63%, target 90%) | FAIL |
| Venn | FAIL | FAIL: 3/17 | FAIL (blocking) |

## Findings and routing
| # | Judge finding (severity) | Cause as investigated | Route |
|---|---|---|---|
| 1 | Venn: the camera sits in or behind the rock wall; the opponent is absent or ghosted in 4/8 tell frames (blocking) | Venn stands in a V-trench: ground rises 69 m within 16 m of his spot (`tests/probe_tidewake_venn_pad.gd`). No open pad within 70 m; the nearest open pads are about 105 m away, on the Veilfall landing beach. | Tidewake BLOCKERS (placement vs V24 trench grading, a geography decision) + Codex queue (camera collision) |
| 2 | No cue on any tell-start frame (blocking) | **Capture artifact.** The frame was grabbed on the telegraph-signal tick. The viewport image is the previous render, and the HUD banner/ring update on the next process frame. Fixed in the capture (`TELL_START_LAG_S` 0.1 s, be48991b); a re-capture is dispatched. | Fixed in lane; re-judge |
| 3 | Player creature hidden behind or under the opponent (Venn) (blocking) | Camera or occlusion at close range | Codex queue |
| 4 | Tell ring bends up cliff faces as a vertical oval (major) | The telegraph ground decal is projected onto walls | Codex queue |
| 5 | Fighters stack at 4.6 m, so the opponent's face is hidden at tell start (Nerissa) (major) | Camera framing at close range | Codex queue |
| 6 | No framing at fight start: camera inside the ally, or sky only (major) | Camera settle at engage | Codex queue |
| 7 | Boss HUD panel covers the opponent's head (major) | HUD layout vs target framing | Codex queue |
| 8 | Clutter around the opponent: background creatures, smoke/burst wash-out, damage text over the body (major) | VFX/HUD | Codex queue |
| 9 | Heavy (1.1 s) tell reads the same as ordinary tells (BOSSES §4.11: "marked lane") | Presentation for the Break Tether timing is not built | Codex queue |
| 10–11 | Team list covers the ally's face; stray blue slab in the chamber; effects clutter (minor) | UI and scene dressing | Codex queue |

The judge also saw "Greet Officer Venn" in Venn's `t-000.00`. That frame is taken on the engage tick, before the director's next `_process` mutes the prompt; every later Venn frame is clean. Same capture timing as finding 2.

Fixed before this round and confirmed in the frames: the wild pair inside Venn's ring, and the "Greet Officer Venn" prompt during his fight (before/after in `frames/venn_BEFORE_*` and `frames/venn_AFTER_*`).

F14#1 stays open. C2 numbers pass in-world (`../f14_inworld_c2/`). C3 framing fails on the findings above.
