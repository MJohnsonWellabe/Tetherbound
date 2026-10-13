# F22#4 named fights on the new timings: C2 (Marrow) and C3 code-blind judges (tb/ev-fights)
Times US Central, Mon 12 to Tue 13 Oct 2026. Godot 4.7 headless on the flat C2 collider (no world, banks or arena hazards).

## C2: Marrow lever 2 (d7ed0f66), 24 seeds, all pilots: PASS x3
- Cause: on the shared CURRENT rows, Stormbrush (send-out 3) kited at 6 m behind a 3 s field. The switching reader spent its Wind on escapes (96 vs 62 bursts) and hit at about 0.2/s instead of 0.45/s, so 2/24 runs per disadvantaged starter passed the 240 s round cap.
- Fix (data, Marrow's named row only): `marrow_current_volley`/`marrow_current_zone` hold the creature at 4.5 m. The field vents 1.3 s (the bank answer's recovery) and clears in 2 s. The shared `current_*` rows are unchanged.

| Starter (class vs electric) | switch-reader win / party | masher party / lead-faint | ratio | switch-reader s (median / max) |
|---|---|---|---|---|
| terrapup (advantaged) | 1.00 / 0.167 | 0.415 / 1.00 | 0.40 | 527 / 555 |
| ripplet (disadvantaged) | 1.00 / 0.052 | 0.457 / 1.00 | 0.11 | 345 / 374 (was 2/24 stalls) |
| galewisp (disadvantaged) | 1.00 / 0.046 | 0.526 / 1.00 | 0.09 | 346 / 368 (was 2/24 stalls) |

- Rows: `marrow_dynamo_core_rows.json`. Errors 0, stalls 0. Open pacing note: Terrapup's 527 s median roster fight sits above COMBAT §7's 3–7 min finale target. Its lead deals little and never switches, so this is padding, not a timeout.
- Riverwatch data (dec92896): Brooktail's finale is now volley, volley, field (BOSSES §2.1 CURRENT). C2 24 seeds PASS x3: switch-reader party 0.10/0.11/0.04 vs masher 0.79/0.79/0.68. The masher now loses 8–17%.

## C3: code-blind footage judges (`tests/capture_f22_named.gd`, same rosters, switching reader, opaque labels)
- Round 1, generic prompt: 1/10 PASS. Causes were mixed: shared role rows read as same-y, plus capture defects (framing, a spurious carried-over strike frame). The tool was fixed.
- Round 2 gave the judge BOSSES §2.2's distinctness rule (shared role shapes plus one fight-specific element): 7/10 PASS (Field, Vance relay captain, Dell, Maren, Nerissa, Veyra, Marrow).
- Round 3, re-captured with the camera fix: Warden PASS, Ridge PASS, Riverwatch FAIL (12/15 cones, no signature).
- Riverwatch re-authored and re-judged: FAIL again (cone-dominated; the field finale reads as a mild arc). Parked after two attempts. It needs a signature element the flat fixture can show, or an in-world judge where its river arena counts.
- Sheets: `c3/r2_*`, `c3/r3_*` (keys `c3/r*_KEY.json`, withheld from judges). Verdicts are summarised here; the judges' full text is in the session.
- Recurring judge notes, not fixed here: lane tells are thin, and the ally's body occludes them (depth-tested by design, F04/P2-093). The Warden's orange Earth Fist cone (#ff9e1f, F04#0) is low-contrast on bright grass.

**Verdict: F22#4 not fully met.** C2 now passes for Marrow (the last open row). C3 passes for 9 of the 10 named fights; Riverwatch's C3 is parked.
