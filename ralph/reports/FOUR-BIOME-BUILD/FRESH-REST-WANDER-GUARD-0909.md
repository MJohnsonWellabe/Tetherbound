# Fresh through-rest wander-guard attempt — 2026-09-09

This was the single root-reviewed fresh-save `--through-rest` attempt on clean-main `d3cdb57ca38acc2691c014663419389037b5209c` with the minimal inactive-aim wander guard and the previously reviewed read-only stage/walk receipts. The 600-second external watchdog stopped it while MATERIALS was advancing. It was not retried. It is neither a through-rest pass nor continuous-campaign acceptance evidence.

## Raw evidence

The unique profile and raw outputs are under `.artifacts/opening-prefix-d3cdb57-0909/rest-wander-fix/`:

- `engine.log` — SHA-256 `e69ad37f0bc7799001ca0f10d1fb26e271a1e8085083f6e517c21ae50d87b379`
- `console.log` — SHA-256 `532ee3b36ef997b764ae715af1590c68747af547e6634e0577e80248216ff555`
- `result.json` — SHA-256 `5db33c4d75021eddaa5ab5dd30f14a00c1bb85bfb50b131b1ffc6afd6bdf5add`
- `resources.csv` — SHA-256 `4d690bbb92381ece3174b85139ec4229526cfb30105b08c386237f4ec0a9aa02`
- `run.ps1` — SHA-256 `08c6373418b0f44dc99abb9ae09d7047f73cc18b97d3c98e671e74f2a5f21404`
- isolated `four_biome_fresh_18792_2476/slot_0.json` — SHA-256 `bc79859eb19a0c3b2d62dec18165918a4c8362fddde5d92495b9be247ad1e1a7`

The wrapper ran from `2026-09-09T20:05:01.5164854Z` through `20:15:03.3136128Z`, then recorded exit `-1` and `600second external deadline`. Peak sampled commit was 60.98%, peak process count 252, and peak owned private bytes 2,287,591,424, below the 90%/400 guards. The terminal Godot census was empty and the world lease was released.

## Observed frontier and timings

The ordinary opening completed at its own `+103.76s` village-gate checkpoint. The earned-team phase then formed the full five-creature party and recorded eleven training wins. MATERIALS entered at physics frame 28,086. The last completed walk ended at frame 31,032, so the instrumented MATERIALS interval covered 2,946 physics frames (49.10 seconds at 60 physics ticks/second) before cutoff. The overall engine had advanced 31,032 physics frames (517.20 physics seconds); startup/import and lower-than-real-time execution account for the difference from the 600-second wall bound.

At cutoff the earned stock was wood 19/18 and fiber 12/18. The final receipt was a fiber walk to `(-97.22411, 5.432769, 38.11372)`, tolerance 1.5, local budget 300, frames 31,020–31,032, `arrived=true`, final distance 1.4885. No walk START was left without an END, and every emitted MATERIALS walk ended `arrived=true` inside its local budget. CAMP, REST and assignment 3 were not reached.

## Wander-guard evidence limit

The run does **not** establish that the repaired inactive-aim branch executed. The active fresh campaign uses `tests/helpers/fresh_opening_segment.gd`'s catch override. Its physical-miss branch emits `live physical throw N missed`, then calls inherited `_wander_for_a_new_angle()` (lines 225–231). This run emitted no such physical-miss receipt. The first strike at log lines 265–268 did not immediately catch, and a later strike at 274–277 did, but those receipts show an ordinary landed strike whose catch roll failed followed by the next catch-loop iteration. They do not show the fresh override's physical-miss branch or its inherited wander call.

The focused coroutine regression remains the evidence for the guard itself: its combat test double supplies `is_aiming`; movement occurs in both states, inactive aim performs zero trailing aim waits, and active aim performs one. Strict open/readiness/commit checks remain unchanged. This fresh run shows that the campaign passed the prior aim-failure locality, but cannot causally attribute that outcome to the guard.

## Next checkpoint recommendation

The orchestration contract requires changing strategy after two no-yield rounds; it does not prescribe a 600-second campaign cap. Its18–25-minute estimate describes CI, not this native scenario. This attempt added stage evidence and stopped because its external wall bound ended during successful material progression. `--through-camp` would still repeat opening, team and MATERIALS; loading the retained slot would become replay evidence. Neither removes the measured fresh-prefix cost while preserving fresh continuity.

After PR108 lands and the clean landing source and CI are verified, the smallest useful next step is one fresh `--through-rest` run with the same acceptance rules, local gameplay budgets, assertions, and 90%-commit/400-process guards, but a declared 1,200-second outer ceiling. Six hundred seconds reached only partial MATERIALS, and 900 seconds leaves little measured room for the remaining material collection, camp work, and five earned rest assignments. The larger outer ceiling is an infrastructure allowance for the native scenario's observed duration; it is not a gameplay fix or relaxed acceptance criterion. Keep the current progress receipts and stop immediately at the first actual scenario failure, successful `through-rest` completion, resource guard, or 1,200 seconds. Do not retry. Do not launch before PR108's landing source and CI are ready and visual attribution work has released the world lease.
