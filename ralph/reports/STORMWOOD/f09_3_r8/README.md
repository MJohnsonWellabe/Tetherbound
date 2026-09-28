# F09#3 round 8: re-verified on the Phase 1 head (tb/stormwood from tb/integration e88a0204)

F09#3 wording (ACCEPTANCE §6.1 F09 / card S1): four loops, three shortcuts, five pockets and the authored alternate routes are physically traversable. Board gap carried from earlier rounds: pocket lures not visible from the road; ordinary walk witness.

No pocket, spur, lure or route data changed in this round. Everything below re-runs round 7's proof on the current head, which now carries batch 67's Stormwood vegetation re-bake.

| Check | Result | File |
|---|---|---|
| Route, pocket, Surge, rod and Arch unit suites (`--only=stormwood_route_walkability,stormwood_pockets,stormwood_surge,stormwood_rod,stormwood_arch`) | 101 tests, 41376 assertions, 0 failed | `unit_routes.txt` |
| Ordinary walk from the earned `3_rootgate` checkpoint (`tests/smoke_stormwood_pocket_walks.gd --from-save=user://swcp_a/3_rootgate`) | 102 checks, 0 failures, EXIT 0, 0 SCRIPT ERROR. Each of the five pockets: a joypad-stick walk from its road (145–384 m) to the mouth, the reward claimed with `interact` and its receipt checked, and a back-wall negative control PASS | `pocket_walks_from_3_rootgate.txt` |
| Road lure frames (`tools/capture_stormwood_pocket_walks.gd --fast`, xvfb + opengl3 1920×1080, llvmpipe) | 20 frames, 0 failures. The five road frames are in `road/`; they match round 7's r7c/r7d frames | `road/`, `road/frames_walks.json` |
| Fresh code-blind judge r8 (shuffled letters V–Z, `blind_key_r8.json`; same question as r7, plus asking whether each lure reads as a detour or as where the road goes) | 2 YES (W Deepwood, Y Verge), 1 PROBABLY (V Hollows), 2 AMBIGUOUS (X Dynamo, Z Conductor). The judge found all five lures visible ("the lures can be seen"). The misses were about reading them as a detour: lamps on the road shoulder read as road lamps, and Conductor's gate sits where the road runs | `judge_r8.md` |

Judge history on these same frames: r7b 3/5, r7c 3/5, r7d 4/5, r8 2/5 YES (plus 1 PROBABLY). Every judge found every lure visible from the road. They differ only on whether a lure reads as a side place, and the r8 prompt probed that harder. Lure presentation has had seven rounds (r1–r7), and earlier rounds swung between "a gold spur reads as another road" and "no spur visible". This round therefore stops tuning (two-strikes rule) and records the variance, not a new cosmetic round.

## Loops, far-side shortcuts and alternate routes walked (re-check r8a said NOT MET without this)

`route_walks_from_4_core.txt` (warnings stripped):

```
godot --headless --path . --script tests/smoke_stormwood_route_walks.gd -- --from-save=user://swcp_a/4_core
```

- **Result:** "Stormwood route walks smoke: 72 checks, 0 failures", EXIT 0, 0 SCRIPT ERROR.
- **Start:** the title Load of the earned `4_core` checkpoint (`../full_run/checkpoints/4_core.tgz`), with the Rootgate released.

| Route (WORLD §5.1) | Walk |
|---|---|
| Loops (rule: at least 4) | All five `kind: loop` routes walked vertex by vertex, back to the start, by stick. Walked vs authored length: pools_west 2728/2728 m, crown_sightline 2997/3010, conductor_west 3194/3206, hall 2760/2761, blackwater 3099/3101. Fights on the way were fought live; 0 lightning hits and 0 deaths. |
| Alternate 5→6 | dynamo_west_approach end to end, 1112 of 1114 m. |
| Alternate 3→5 | Arch pair C (the next row). |
| Far-side shortcut C | c_rodline ↔ c_lantern. Both ends relit through their own "Relight … · 3 Stormglass" prompts, then walked through both ways. The trainer lands 2.5 m and 4.5 m from the twin. |
| Far-side shortcut D | d_hall ↔ d_giant. Relit the same way and walked both ways; lands 4.5 m from each twin. |
| Far-side shortcut Raise a Road | Two optional footings (verge_road b2, hollows_road b3) chosen through their prompts. Both arches raised by ordinary Build input (build_shortcut, pad catalogue navigation, build_place), linked, exact cost charged, then walked both ways. |

**Game defect found and fixed in this round (`autoload/game_state.gd`, `tests/test_register_building.gd`).**
- **Symptom:** after a title Load, the first building placed reused the Crown arch's uid "b1".
- **Consequence:** its arch link rewrote the Crown pair's twin and footing.
- **Before the fix:** the smoke printed `collision=true`.
- **After the fix:** `ROAD uid counter after title Load: next minted uid=b2 live uids=["b1"] collision=false`.

**FINDINGs (traversal still passes; recorded in STATE with an owner):**
1. **pools_west_loop runs through the lit b_pools arch.** The authored line passes 0.9 m from the centre of the Lantern Pools North arch. A player who keeps walking straight is carried to Rodline Post, so the walk steps round the frame.
2. **Verge Road footing:** a curb on the landing side of the slab, up to 1.11 m. A trainer who arrives at b2 and turns round cannot step straight back through the opening and must walk round to its approach side.
3. **d_giant rear:** a 0.40–0.67 m slab step on the rear side. The trip works from the front.

**Additional disclosed seams:**
- **Start:** the earned `4_core` checkpoint, copied to a scratch save before loading.
- **Teleports:** one per route start, one per dark arch before its relight, and one per road footing.
- **Material grants:** 3 Stormglass per relight, and each road arch's exact recipe shortfall.
- **Clock:** time_scale 8 with 480 Hz physics. Fights, conductor roads and Build run at 1×.
- **Waypoints:** intermediate waypoints are linear interpolation along the authored polylines, every 40 m or less.

**Disclosed shortcuts (pocket walks and frames):**
- **Walk witness:** one teleport per pocket onto its road, 32 m before the junction, then waiting for Calm at time_scale 8. Its start is the continuous run's earned `3_rootgate` checkpoint, which itself starts at the Cloudreach-boundary fixture (see `../full_run/README.md`).
- **Frames:** teleport to the stand, day pinned, Surge at Calm, and the Rootgate flag set.
- **Unit and walk runs:** both ran on e88a0204 plus this branch's uncommitted Surge-presentation change (F10#3 ceiling crawlers and Fading steam). It touches no pocket, route or movement data.

**Lure look (materials, sameness of the lamp-and-beam language): Bars A/B → Phase 2 catalog.** The functional readability clause (lure visible from the road) is claimed on the judges above: 5 of 5 visible in every round, detour read 4/5 (r7d) and 3/5 YES-or-PROBABLY (r8).
