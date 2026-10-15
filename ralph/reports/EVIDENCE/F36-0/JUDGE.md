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

**Meadowhart riding repair, 5:12 PM CT (Codex f6820dfb, real-textured-legs-before-after-Low.jpg):** code-blind PASS. In the day side, three-quarter and night views the placeholder leg tube and box foot are gone, and the textured trouser and boot are seated at the stirrup. Meadowhart is switched on (enabled=true, placeholder merged). Checks: Meadowhart riding repair, rideable roster, scale ladder, F36 pose candidates and riding saddle, 30 tests, 0 failed, after a local asset import of the merged Codex models.
NPC identities (P2-055): Adair PASS, held for Codex's switch-on commit, because its tests assert the gates are OFF. Iona, Orsen and Otto FAIL as clones.

## Solmane wing-root reference and Meshy round, 15 Oct 2026

The Codex image generator edited the installed Solmane standing reference into `assets/creatures/tetherbound/solmane/reference/wing-root-v2.png` (1254 px square). The inspected reference preserves the gold lion, cream mane, dark feather band and wing span while drawing continuous shoulder roots. The image request called for one 3D-ready standing Solmane on a pale gray studio background, with both wing bases embedded in the shoulder mass, no gaps or detached feathers, and the established identity retained. Generated source: `C:/Users/mattj/.codex/generated_images/01a13c93-1c48-79a0-8110-03d187f3f718/exec-551f01e7-409b-49a4-ae80-1a09fdd6f92b.png`.

Existing-license Meshy command: `python tools/art_pipeline/meshy.py generate solmane --candidates 2 --tier refine --polycount 30000 --image assets/creatures/tetherbound/solmane/reference/wing-root-v2.png`. Tasks `01a13f2a-c4d6-7496-9b11-03f951339ce6` (A) and `01a13f2a-d043-7394-b3c4-843fd77c1e25` (B) succeeded; fetched untouched GLBs, thumbnails and provenance under ignored `assets_raw/solmane/wing_root_v2/{a,b}/`. Existing balance fell from 15300 to 15240 credits; no purchase. Blender inspection and four-view renders were run on each source GLB.

Both stills keep a recognizable Solmane and appear to attach the wings at the shoulders. Geometry inspection records A at 55,010 triangles, 28,960 nonmanifold edges, 1,981 microscopic disconnected components and 15,960 duplicate vertices; B at 58,781 triangles, 30,375 nonmanifold edges, 2,254 microscopic disconnected components and 16,669 duplicate vertices. These counts are diagnostic only: layered feathers can be disconnected, and they do not prove a visible failure. Both raw files have no armature; source heights are 1.1823 m / 1.1905 m before restoration to the 6.70 m Solmane target. The requested quad remesh returned 0% quads. The preserved `skin_transfer.py` route transferred the installed Solmane rig to B in an ignored OFF artifact, `assets_raw/solmane/wing_root_v2/b/solmane_skin_transfer_off.glb`: Blender exited 0 and reported 46,658 vertices, 0 unweighted. Deformation, wing-root visibility under animation, target scale and in-engine quality have **not** been proved. A remains raw. **Both remain OFF; no code-blind score is assigned to the unintegrated models.**

The transferred B model is preserved as `assets/creatures/tetherbound/solmane/models/creature_solmane_wing_root_v2_off.glb` (SHA-256 `087699630735c18ce079c4cf08fd50a6379acd4a5fc40088b73da2a76f2140c9`). GLB structure confirms one skin, the installed 15 named quadruped joints, six inherited animations and one mesh. Its source bounds span 1.181 m vertically versus 0.928 m for the installed donor with the same 1.882 m span, so an unchanged fitted height would narrow the new wing span; that is an inference pending actual engine scale/contact frames. The preserved rig has no separate wing joints, which also makes flapping deformation a visual question for scene proof. No species model path or flag was changed.
