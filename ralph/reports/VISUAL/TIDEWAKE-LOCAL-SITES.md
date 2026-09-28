# Tidewake local-site visual evidence

X04 / F13#3, based on freshly fetched main `ce1a3c6e576c5e0bf99c5ee543258794be302b00`.
Production changes are isolated on `tb/x04-cross-game-visual-sweep`, standing draft PR365.
Claude owns merge. All captures are **DRY RUN — does not count** as earned exploration.

## Retained result

- **Deep Watch:** replace the two plain equipment boxes with an installed timber awning, supported coastal chart, books, supply crate and mounted lantern. Its existing interaction root/prompt and rules stay at the same coordinates. The code-blind judge passes landing/approach invitation, day/night chart recognition and this small station's construction/grounding.
- **Gull Rest:** a persistent civilian survey station marks the original satchel site. Blue cloth is an instance-only recolour of the installed fabric, retaining weave and normal detail. A slim timber mast, supported chart, books, crate and lantern establish activity. The judge passes the 40m approach and day/night chart identity, but site integration remains WEAK and the 101m landing invitation remains FAIL.
- Each awning declares a small 2.4m grass footprint through the existing presentation group. Dressing has no collision, areas, navigation, new prompts, flags or rewards.

**No region or whole-game Bar A/B acceptance is claimed.** Gull's landing remains occluded; its visitor area is still crowded by vegetation. Both charts use the same schematic illustration and establish activity more strongly than distinct place identity. A conspicuous white water/pickup highlight behind Gull also exists in the no-lantern candidate. The artwork is a prop illustration, not a navigable map or proof of route accuracy.

## Rejected and unresolved

The Drowned Garden candidate made a ruin visible at closer range but failed quality review: oversized isolated corner, stair-stepped thin panels, wooden caps, flat ivy, inadequate collapse/foundation. It was removed completely from production config. Garden remains unchanged and open.

Twenty terrain samples along each arrival-to-site line explain the distant failures. Estimated target-top clearance above actual target ground is about **14m at Gull** and **41m at Garden**, from the production arrival camera. These are sampled occlusion diagnostics, not continuous visibility or walking proof. Enlarging a small worksite to clear those ridges would produce implausible scenery. Arrival route composition/markers need a separate coherent treatment.

Lantern Cove's promised rock arch and Cradle's shell nest have no instantiated landmark models. The metadata arch position is about117m from the actual cache, so placing art only at that metadata row would not dress the cache destination. Both remain open. Cradle's straight-line midpoint falls in a rock slot; a walked-route stand is still required. Lastlight's baseline was captured; it was not changed.

## Verification

- 46 native1920×1080 Compatibility frames on Godot4.7 `5b4e0cb0f`, GTX1060 3GB. Baseline: all six local chains. Candidates include the rejected Garden assembly; final production contains only Gull/Deep.
- Final lifecycle fixture checks: two sites and idempotent build; build preserves flags; no physics/navigation; satchel hides before lead and after recovery while survey scenery persists; satchel transform unchanged; dock restoration preserves chart transform and does not lose/duplicate scenery/equipment; flags restored afterward. **11/11 pass.**
- Final visual runs exit0 with no script/renderer errors. Existing physics-interpolation deprecation warning remains.
- `first_shore_fence` independent source review: no production blocker. Roof-bracket misuse and unsupported books were corrected. SVG uses imported ResourceLoader remapping; its import generates mipmaps. Capture write failures are retained through the inherited final exit.
- `draught_visual_judge` reviewed12 candidate and8 final native frames without source. Garden FAIL rejected; final Deep scoped PASS; Gull approach/identity PASS, landing FAIL, integration WEAK.
- After enabling map mipmaps, eight fresh frames and11 lifecycle checks passed again. The independent judge inspected Deep landing/night and Gull approach/night: same scoped verdict, smoother/slightly softer chart lines. Reduced shimmer in motion is not proven by these stills.
- Save/load behavior is exercised through the production progression-restoration entry point in a local fixture, not an earned save file or network session. No export, Ally performance, multiplayer walkthrough or whole-chain completion is inferred.

Native file hashes, camera/feet/FOV, terrain samples and runtime checks: [evidence manifest](tidewake-local-sites-evidence.json). Review preview: [contact sheet](_sheet_tidewake_local_sites.jpg). Preview thumbnails do not replace native inspection.

## Asset provenance

No procurement, Meshy call or credits used for this pass. Geometry, wood textures and lantern treatment reuse the installed Quaternius Fantasy Props / Stylized Nature families and existing dock lantern code. Their existing source licences and credits continue to apply; original pack files are unchanged. References inspected: `docs/art/reference/18_Signpost_Bridge_Modular_Props.png` and `owner-board-2026-08-23-camp-set.png`. No board pixels are shipped.

`tidewake_chart.svg` and `survey_cloth.gdshader` are original project-authored additions by Codex, created2026-09-26. The chart is authored vector geometry; the shader samples existing licensed fabric textures and changes colour per instance. These additions are not upstream Quaternius assets.

## Reproduce

Import in Godot first; serialize engine writers with the workspace render lock and use an isolated APPDATA profile.

```text
Godot_v4.7-stable_win64.exe --path . --rendering-method gl_compatibility --resolution 1920x1080 --fixed-fps 60 --script tools/capture_water_chain_lures_native.gd -- --out=res://shots/lures-check --only=gull,deep
```

Omit `--only` for all six chains. Lifecycle assertions run when `deep` is selected. The harness sets upstream/lead flags and teleports to diagnostic stands; it does not earn those states.
