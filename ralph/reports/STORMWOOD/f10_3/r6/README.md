# F10#3 round 6: a Break-only cue a single still can name

F10#3 (ACCEPTANCE §6.1 F10, card S2): readable lightning (1.2 s / 3 m) and Calm/Building/Break/Fading cues, with no HUD phase text.

Open item from the Phase 1 brief: "The telegraph passes all five questions (r5). Open: a Break-only cue readable in a single still". Round 5 left it PARTIAL: "Break has no signature cue in a still".

## Change (tb/stormwood 9adc99f1)
All of this is presentation only, in `scripts/world/stormwood_surge.gd` and `data/config/stormwood_surge.json`.

**Break crawler lightning:**
- Break draws steady, branching white-violet crawler veins along the cloud base (`crawlers` 1.0 in Break; 0 in every other phase and in the whole aftermath).
- It is a held glow with a slow crawl, never a flash onset, so the UX §8 flash budget is unchanged.
- Reduced motion freezes the crawl.

**Warning hold:**
- While a ground warning is drawn (the existing `hold_sky_bolts`), the veins go out at once, the same way a decorative bolt already on screen does.
- They ease back over 1.5 s after the warning clears.
- This was added after strike judge r6a failed Q5: the veins read as "lightning already hitting elsewhere".

**Tests:** `test_stormwood_surge_presentation.gd` has two new tests, one for the Break-only crawlers and one for the veins going out during a warning. Surge + lightning suites: 60 tests, 0 failed.

## Evidence (xvfb + opengl3, llvmpipe, Godot 4.7 Compatibility)
| Question | Round 6 | File |
|---|---|---|
| Phases without HUD (8 shuffled stills; `tools/capture_stormwood_surge_phases.gd --only=quick,night`) | **Break named from a single still: YES on both Break stills.** 8/8 grouped and named correctly (Calm and Fading at medium confidence) | `phases/`, `phases_blind_key.json`, `JUDGE_phases.md` |
| Q1 danger zone about 3 m from frame one | PASS (radius 2.8–3 m) | `strikes/`, `JUDGE_strike.md` (seqM, normal motion, hour 12) |
| Q2 time left / last moment | PARTIAL on this judge. The late "leave now" cue comes at t100–t110. Rounds 4 and 5 PASSED the same unchanged telegraph | `JUDGE_strike.md` |
| Q3 reads as lightning striking the zone | PASS | `JUDGE_strike.md` |
| Q4 reduced motion (no strobe or white-out; all readable) | PASS | `strikes_reduced/`, `JUDGE_strike_reduced.md` (seqN, hour 0, Reduced Motion on) |
| Q5 nothing competes during the warning | **PASS** (before the hold: FAIL; `strikes_seqI_before_hold/`, `JUDGE_strike_before_hold.md`) | `JUDGE_strike.md`, `JUDGE_strike_reduced.md` |
| Q6 photosensitivity | PASS | `JUDGE_strike.md` |

**Recorded, not fixed.** These are outside the open item and are telegraph polish:
- Q2's mid-countdown steps are subtle, and the strongest last-moment cue lands late.
- A decorative sky bolt can appear 0.4–0.5 s after a strike. The existing hold is telegraph + 0.3 s.
- Calm and Fading can be confused by name from a single still (moderate).
- The telegraph's timing (1.2 s) and rules are the spec and are unchanged.

## Staging (disclosed)
**Phase stills:**
- The surge clock is pinned to phase start + 2 s.
- The hour is frozen at day or at night (Stormwood has one look at every hour).
- The trainer is teleported to the Cinder Verge stand; the HUD is hidden.

**Strike sequences:** the base tool's staging applies.
- One staged warning and impact goes through the client path, aimed at the trainer, with no damage.
- The random strike schedule is pushed out and the hour is frozen.
- The child process runs at `--fixed-fps 60`, so frame N is N/60 s after the warning.

**Code state:**
- The phase stills (r6b) were rendered before the warning hold existed; the hold does not change a still that has no warning in it.
- The strike sequences seqM and seqN were rendered with the hold, at 9adc99f1.
