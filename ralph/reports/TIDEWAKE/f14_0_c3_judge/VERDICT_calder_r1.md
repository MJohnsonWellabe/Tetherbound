# F14#0 C3: code-blind judge, Calder (round 1) — FAIL

**Capture:** render.yml run 36303073279 at 20e2970b. The READER pilot won in 283.9 s against all three send-outs (Riptusk, Torrentoad, Riverdrake), in 48 frames; 21 were curated for the judge (every tell frame plus every fourth periodic frame).

**Shortcuts (declared):**
- a granted L43 party of the original five;
- the player placed at the trainer;
- the fixture flag `water_dock_salt_crown_landing_charted`, which satisfies Calder's `requires_flags` gate.

**Judge:** a fresh code-blind subagent. It saw only the frames and `calder_frames.json`.

| | Result |
|---|---|
| Tell readability | FAIL (narrow): late tells read well (ring, "incoming — move", Riptusk's lowered-head wind-up), but 4 of 6 tell-start frames show no cue at +0.1 s |
| Framing | FAIL: both fighters clear in 16/20 active frames (80%); fighters plus the tell in 13/20 (65%); the target is 90% |

## Findings and routing
| # | Finding (severity) | Lane note | Route |
|---|---|---|---|
| 1 | No visible cue at tell start (blocking) | **Probably a capture artifact.** In code the cue is immediate: `wild_creature._announce_tell()` emits `telegraph_started`, and the manager's ring and the HUD banner (`enemy_is_winding_up()`) draw on the next frame. The capture grabbed the last *completed* render on a physics tick, and under software GL one render spans several ticks. Fixed in the capture (grabs after `RenderingServer.frame_post_draw`); a Tess re-capture is running to settle this and V-TW-14. | capture fix (lane); V-TW-14 pending |
| 2 | Opponent's head behind the boss nameplate panel; damage toasts across its face (blocking in 2 frames) | — | V-TW-10 |
| 3 | Hit/stagger burst washes the opponent out (major) | — | V-TW-12 (hit VFX opacity) |
| 4 | Opponent cropped at the frame edge during a wind-up (major) | — | V-TW-8 (fit) |
| 5 | Ring hidden under large bodies and non-directional (major) | — | V-TW-9 / V-SW-1 |
| 6 | Bystander trainers inside the ring; background wilds compete (minor) | Trainers stand beside their own fight by design; the wilds are more than 13 m off (V-TW-7 ring-clearance test) | note |

Calder shows no terrain void. His framing failure is the HUD, VFX and edge cropping (80% against the 90% target). F14#0 stays open.
