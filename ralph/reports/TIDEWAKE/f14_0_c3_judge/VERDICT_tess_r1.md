# F14#0 C3: code-blind judge, Tess (round 1) — FAIL

**Judge.** A fresh code-blind subagent. It saw only the 26 PNGs and `tess_frames.json` (tag, fight time, opponent, measured `tell_s`, gap), plus the C3 and COMBAT §5 camera bar as text.

**Capture.** `tests/capture_tidewake_named_fights.gd --trainer=water_trainer_tess --pilot=READER --level=43 --interval=8`, render.yml run 36301887937 at dd422003 (1280×720, opengl3, xvfb). The READER pilot won in 323.8 s and reached all three send-outs (Mirejaw, Sirenseal, Riverdrake): 53 frames, curated to every tell frame plus every third periodic frame. Declared shortcuts: a granted L43 party of the original five, and the player placed at the trainer.

## Verdict
| | Result |
|---|---|
| Tell readability | FAIL |
| Framing (both fighters + tell clear) | FAIL: 8/26 (31%), target 90% |
| Overall | **FAIL** |

## Findings and routing
| # | Finding (severity) | Checked by the lane | Route |
|---|---|---|---|
| 1 | **Void camera**: 12 of 14 periodic frames show only fog/sky gradient, while the HUD reports the fight continuing ("it missed you", STAGGERED) (blocking) | Confirmed (`frames/tess_t-096.02_void.png`). Tess fights on a steep grass ridge beside a trench road, and the fight camera ends up inside or behind the terrain. This is the same class of defect as Venn's cliff (V-TW-7). | Codex queue V-TW-13 (fight-camera terrain collision / fit, COMBAT §5) |
| 2 | Tell start shows no banner and only a faint arc 0.1 s into the tell (blocking) | Partly confirmed (`frames/tess_tell-start-125.80_faint_cue.png`): a faint cyan arc, and no "incoming" banner yet | V-TW-14 (tell-start cue strength); related to V-TW-9/-11 |
| 3 | Some "late" tell frames show STAGGERED/"it's open" instead of the tell | The READER pilot interrupted those tells with a charged hit, so the strike never landed. That is a correct game outcome, not a defect. | none |
| 4 | Tell marker does not show where the hit lands: a streak runs away from the ally, or the ring sits under the attacker (major) | — | same as V-TW-9 / V-SW-1 |
| 5 | Opening frame inside rock; "Challenge Tess" prompt over the fight at t=0 (major) | The t=0 frame is taken on the engage tick, before prompts refresh (see F14#1 VERDICT_r1) | camera settle at engage: V-TW-12 |
| 6 | Fighters small in the far shots (major); HUD overlap (minor) | — | V-TW-8 / V-TW-10 |

Calder: the capture at 20e2970b (with the disclosed `--flags=water_dock_salt_crown_landing_charted`) is still rendering. The same judge will run on it as an addendum. F14#0 stays open on C3 framing.
