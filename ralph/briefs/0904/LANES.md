| Lane | Session | Branch | Model | State |
|---|---|---|---|---|
| W00-ICONS | session_011dNQ8FdKFxipGAyMpFqxDX | ralph/W00-ICONS-0904 | fable | resumed 01:06Z (wave 2) |
| W01-ROUTE-STRIP | session_01YZeGuGZmYaMfYiWt5F7u8s | ralph/W01-ROUTE-STRIP-0904 | fable | resumed 01:06Z (wave 2) |
| W02-HARNESS-CONTEXT | session_01GXiERF5YzxNF8dAiFDZckr | ralph/W02-HARNESS-CONTEXT-0904 | fable | PAUSED (hit 5h limit 21:xx; partial push kept) |
| W03-S08-FREEZE | session_01Rn6edt5WwLFj2QjeEZ6xB7 | ralph/W03-S08-FREEZE-0904 | fable | PAUSED (hit 5h limit 21:xx; partial push kept) |
| W04-PORTRAITS | session_01CK2HpfvadUbxwdsXXjDVBb | ralph/W04-PORTRAITS-0904 | fable | resumed 01:06Z (wave 2) |
| W05-TREELINE | session_017g8isAWJ4DxVtZaKzZYo78 | ralph/W05-TREELINE-0904 | fable | PAUSED (hit 5h limit 21:xx; partial push kept) |
| W06-FINALE | session_011dc79BSyvBztH3GpBaBjvV | ralph/W06-FINALE-0904 | fable | resumed 01:06Z (wave 2) |
| W07-WARRENS | session_01NeCvGYwgAdi7goARi5rK6a | ralph/W07-WARRENS-0904 | fable | resumed 01:06Z (wave 2) |
| W08-DIALOGUE-CAMERA | session_01GA5iSWYCMh9qLDa7CJgq9r | ralph/W08-DIALOGUE-CAMERA-0904 | opus | PAUSED (hit 5h limit 21:xx; partial push kept) |
| W09-VFX | session_01LnkDeQzoUy8KHqVtFcPoxt | ralph/W09-VFX-0904 | fable | resumed 01:11Z (backfill for W19) |
| W10-TRAINER-RULES | session_01CtPiTG6K4LV4Z2nYNAfRz3 | ralph/W10-TRAINER-RULES-0904 | opus | PAUSED (hit 5h limit 21:xx; partial push kept) |
| W11-ALPHA-PINS | session_01Rc8p5dXWaQMP4Bs1Frjcdd | ralph/W11-ALPHA-PINS-0904 | opus | PAUSED (hit 5h limit 21:xx; partial push kept) |
| W12-COMPANION | session_01GwmYsvBJgk8LZjAcncw6Uj | ralph/W12-COMPANION-0904 | fable | resumed 01:06Z (wave 2) |
| W13-PROGRESSION-FEED | session_01LvTJr575z5MeAB4mYwwSa1 | ralph/W13-PROGRESSION-FEED-0904 | fable | resumed 01:06Z (wave 2) |
| W14-RIDING | session_01E5oABcNXe8KY4bgZr1nd33 | ralph/W14-RIDING-0904 | opus | PAUSED (hit 5h limit 21:xx; partial push kept) |
| W15-NIGHT | session_01EedqpY5BgYWGCHuUG5w6VR | ralph/W15-NIGHT-0904 | fable | PAUSED (hit 5h limit 21:xx; partial push kept) |
| W16-LOFT-BED | session_01EHxzFs2VaZmn7b6UHWYyeg | ralph/W16-LOFT-BED-0904 | opus | PAUSED (hit 5h limit 21:xx; partial push kept) |
| W17-DENSITY-B2-B3 | session_013yknopk7xZdMbGWHEgWokR | ralph/W17-DENSITY-B2-B3-0904 | fable | resumed 01:06Z (wave 2) |
| W18-DENSITY-B4-B5 | session_01JDyZNRegueK2qa9YNZnXvC | ralph/W18-DENSITY-B4-B5-0904 | fable | resumed 01:06Z (wave 2) |
| W19-CONTRACTS | session_01AHh7dCnebbJAjjWTCEJ7oS | ralph/W19-CONTRACTS-0904 | fable | DONE 01:09Z — report pushed, awaiting landing |
| W20-SMALL-FIXES | session_01UUtrNg1WUDF1qA7XabKfaG | ralph/W20-SMALL-FIXES-0904 | opus | PAUSED (hit 5h limit 21:xx; partial push kept) |
| W21-HARNESS-FIGHTS | session_01654XjihMdSzNkv2qoKUJez | ralph/W21-HARNESS-FIGHTS-0904 | opus | PAUSED (hit 5h limit 21:xx; partial push kept) |
| W22-BRIDGE-SIGNPOST | session_01JsXprpxn5HzVvCoubWsYS8 | ralph/W22-BRIDGE-SIGNPOST-0904 | fable | PAUSED (hit 5h limit 21:xx; partial push kept) |
| W23-DIFFICULTY | session_01TKC2z5SNJaB7TPwjyRTb3x | ralph/W23-DIFFICULTY-0904 | fable | PAUSED (hit 5h limit 21:xx; partial push kept) |

## Wave 2 — 2026-09-05 01:06 UTC
All 24 lanes hit the 5-hour session limit around 21:10–21:25 UTC; 17 had pushed partial work. Owner asked for ten Fable lanes resumed from their own context and the rest paused. Resumed via session-bound triggers: W00, W01, W04, W06, W07, W12, W13, W17, W18, W19. Paused (branches keep their partial pushes): W02, W03, W05, W08, W09, W10, W11, W14, W15, W16, W20, W21, W22, W23.
| W24-LANDING | session_01ET2eBuXAGLAXGCf9VDvfU5 | ralph/LAND-0904-n | fable | running (landing lane, woken hourly at :00 UTC) |

## Landing status — W24-LANDING, 2026-09-05 02:20 UTC (cycle 1 + hourly cycle 2)

**Open PRs (neither mergeable yet — see the blocker below).**

| PR | Branch | Lanes | CI |
|---|---|---|---|
| #42 | `ralph/LAND-0904` @ `3fbd67ad` | W00-ICONS + the bake-manifest repair | every job green except `verify-gate-evidence-shard`; unit shards 1/3/4, both bake-freshness jobs, gate-b-core, harvest, scatter-rules, veg-corridor and owner-regressions all pass |
| #43 | `ralph/LAND-0904-2` @ `4aca3cb5` | W19-CONTRACTS, W13-PROGRESSION-FEED, D74→D76 renumber | opened 02:18, running |

**THE BLOCKER: `smoke_gate_e_finale` is red on `main`.** `FAIL: exploration never came back
after 'warden_aldis''s fight`. It passed on `main` at `90efc0d5` (run 33916194315) and
reproduces on both a landing branch and a tree byte-identical to `origin/main`. Cause:
`04d844d0` gave the Warden `"victory_conversation": "stronghold_warden_realm_reward"` and
auto-plays it, so a dialogue panel is open when the smoke checks locomotion
(`sequence_director.gd:747/774` hold locomotion while a panel is up). **`tests/smoke_gate_e_finale.gd`
is W06-FINALE's owned file**; the landing lane will not edit it. Full evidence in
`ralph/reports/W24-LANDING-0904/REPORT.md` and on PR #42.

Related, for the owner: `04d844d0`, `3f9e1a14` and `47ca2e12` build Cloudreach Cliffs
(Biome 2) on `main`, including a realm arch and Heart socket inside
`scripts/world/playground_world.gd`. `CLAUDE.md` bars Biome 2 implementation until the
Meadows passes its exit gate, and that work is what broke the Meadows finale.

**Lane readiness as of 02:20 UTC** (a report is "complete" when it has no unfilled
placeholder and a final hash):

| State | Lanes |
|---|---|
| complete, in a PR | W00-ICONS (#42), W19-CONTRACTS (#43), W13-PROGRESSION-FEED (#43) |
| report drafted, placeholders unfilled | W01 (`FINAL_COMMIT`, `PLACEHOLDER`), W04 (`PLACEHOLDER`), W05 (`JUDGE_SECTION`), W09 (final hash), W10 (skeleton), W12 (final hash + tests/judge), W17 (`RENDER_SECTION`, `FINAL_COMMIT`), W18 (`FILL` ×7), W22 (`__W22_COMMIT__`, `__W22_VERDICT_BLOCK__`, `__W22_LEAK_BASELINE__`), W23 (`SMOKE_RESULTS_PLACEHOLDER`, `FINAL_COMMIT_PLACEHOLDER`) |
| no report on the branch | W02, W06, W07, W08, W11, W14, W15, W20, W21 |

**Verified ahead of time by the landing lane, so these land fast once their reports close:**
W17 (148 tests / 817,100 assertions and 20 pickup tests green; `smoke_playground` places all
46 pickups) and W23 (36 tests / 543 assertions; the combat harness runs 15 rows clean — its
Gate B red was `main`'s flake, not its own, so that earlier reading is withdrawn).

**Decision numbers** land as: W19 keeps D74/D75; W13 → **D76** (done in #43); W23 → D77,
W18 → D78, W10 → D79, W09 → D80 (the lane did its own), W04 → D81, W02 → D82; later
decisions from D83.
