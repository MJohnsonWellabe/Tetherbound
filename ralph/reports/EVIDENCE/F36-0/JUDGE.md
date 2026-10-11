# F36#0 native candidates: code-blind judge (coordinator, 12:02 PM CT Sun 11 Oct 2026)

Input: tb/ev-captures 8b6452d4, ralph/reports/VISUAL-PROOF/F36-0/ (capture_f36_poses.gd --scale-only standing stage, Compatibility 1280x720).
Method: per species, installed and candidate (front + back beside the 1.80 m trainer) were shuffled into rows A/B by the coordinator (seed 36011; key held back) and judged by two independent code-blind judges (visual-judge skill; ART_DIRECTION + CREATURES only). Mapping applied afterwards.

Rule (owner 3A): a candidate is switched on only if it is clearly better AND defect-free AND its own provenance gate did not FAIL.

| Species | Judge preferred | Candidate verdict | Notes |
|---|---|---|---|
| meadowhart | candidate (clear) | **PASS** | stylized deer, leaf mane, readable face |
| mirejaw | candidate (clear) | **PASS** | installed has crimson gills (reserved red); candidate gold, on palette |
| tuskroot | candidate (clear) | **PASS** | expressive face, stone-and-moss shell |
| aeriex | candidate (clear) | held: provenance terminal-contact FAIL | visually preferred |
| veridian | candidate (clear) | held: provenance terminal-contact FAIL | installed judged DEFECT (blotchy camo texture, lopsided antlers) |
| voltarach | candidate (clear) | held: provenance terminal-contact FAIL | clear spider read |
| solmane | candidate (clear) | held: provenance terminal-contact + topology FAIL | more regal |
| abyssal_guardian | candidate (slight) | held: provenance FAIL; not clearly better | |
| cannonback | candidate (slight) | held: provenance FAIL; not clearly better | |
| fulgocobra | candidate (slight) | held: provenance FAIL; not clearly better | |
| stormcapra | candidate (slight) | held: provenance FAIL; not clearly better | |
| staticub | candidate (slight) | FAIL: not clearly better | purple shoulders read as a cape |
| galecrest | same model | no change | |
| tanglevolt | same | FAIL: not clearly better | |
| ashtusk | installed | FAIL | |
| bramblebun | installed | FAIL: DEFECT wrong identity (photoreal plain hare, off-roster style) | both clear 1.80 m only by ears/antlers |
| burrowback | installed | FAIL: drifts from documented rock-armour identity | |
| cloudfang | installed | FAIL | |
| galewisp | installed | FAIL: DEFECT asymmetric eye smudge | |
| mudsnout | installed | FAIL: hyena-like spots | |
| ripplet | installed | FAIL: DEFECT front texture smeared onto back | |
| riverdrake | installed | FAIL | |
| terrapup | installed | FAIL: DEFECT head turned 90°, blotchy patches | |

PASS list sent to the captures lane for the switch-on commit (enabled=true + placeholder merged into data/creatures/species.json): meadowhart, mirejaw, tuskroot.
Every candidate creature stands taller than the 1.80 m trainer, with feet on the stage. Stage frames can't settle pose gates (hurt/faint/swim/fly/ride, F36#1).

**Switch-on, 12:08 PM CT (tb/ev-coordinator 4c060802):** Mirejaw and Tuskroot enabled. The Water roster's Mirejaw presentation now points at the same mesh. Meadowhart is held: its native model fails test_meadowhart_riding_visual_repair_0912 (no skinned MeadowhartBareBody for the riding tack fit), so it's back with Codex.

**Terminal-contact repairs, 3:31 PM CT (Codex 16f273ed / d1a46699, faint before/after Low sheets):** code-blind PASS on floor contact for Aeriex, Veridian, Voltarach and Solmane, each clearly better than before. Switched on (coordinator branch): Aeriex, Veridian and Voltarach, which have no remaining FAIL gate. Solmane stays held on its own topology FAIL (holes near the wing root). Meadowhart riding (b5c6d6be) FAIL: the rider's near leg renders as an untextured tube with a box foot; Meadowhart stays off.
Checks after switch-on: scale ladder, F36 pose candidates, four-biome roster population, water catalogue and colourways, Cloudreach/Stormwood/Voltarach colourways, rideable roster, evolution, shiny, plus foundation retry/settlement and F19 boss delivery: 109 tests, 2121 assertions, 0 failed.
