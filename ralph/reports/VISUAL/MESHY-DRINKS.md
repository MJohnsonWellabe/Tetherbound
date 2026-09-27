# Shared Meshy stat-drink bottle — X04 / V-CX-3

The owner requested one Meshy bottle with a different badge for each drink.
The six scenes now share one sea-green bottle with rounded shoulders, cork,
stitched leather and brass trim. Small fitted badges identify Might (crossed
swords), Attack (single sword), Guard (blue armour), Stoneguard (slate armour),
Vigour (green heart) and Swift (ochre lightning). Permanent elixirs also carry
three seal pips. Each has a smaller reverse badge.

This replaces unrelated barrel/crate/plant stand-ins at 26 existing loose
finds: four Meadows, twelve Stormwood and ten Tidewake. Guard and Vigour also
receive the shared model definition but currently have no loose-world placement.
Item effects, quantities, rewards, authored positions, IDs and claim/persistence
behavior are preserved. Three explicit Meadows harvest overrides use the same
scenes as the metadata-driven cache paths.

The Stormwood display correction keeps the authored interaction root and prompt
in place while moving only the bottle and its shared glow to terrain. Its
unscaled presentation anchor excludes the separate reward beacon from glow
bounds. Bottle metadata opts out of the pocket reward's 2.2x display enlargement.
Existing pocket beacon behavior remains intact.

## Provenance and implementation

- Meshy task `01a0e076-a807-73f5-9c96-b1fba0d4c41e`: one textured image-backed
  candidate, **30 credits** (13695 → 13665), generated from the inspected
  agent-drafted reference in `assets/props/stat_draughts/reference/bottle.png`.
- Adjacent `provenance.json` retains both prompts, task ID, dates and reference/raw
  GLB hashes. No credentials or signed download URLs are stored.
- Shared base: 9,858 triangles, one material, preserved 2048px Meshy albedo.
  Ground-origin height 0.80m, ordinary world scale 0.8, resulting height 0.64m.
- Badge triangles: Might 456, Guard 344, Vigour 512, Swift 240, Attack 288,
  Stoneguard 272. Every complete pickup remains below 10,400 triangles.
- `tools/art_pipeline/author_stat_draught_models.py` normalizes the source and
  creates six small badge GLBs plus scenes referencing one shared bottle.
  Rebuilds can reuse the committed base without another Meshy call.
- Implementation `edba05c92`, integrating GitHub main `7f875a85d`. Claude's
  checkout was not edited. PR #355 is the handoff; Claude owns integration.

## Verification and limits

All images are **DRY RUN — does not count** for earned-route or whole-game
acceptance. Fixtures set stands and clock, park the companion and pause
encounters. Region frames use the production CameraRig and actual authored
pickup placements; the stage exercises both production pickup loaders.

Godot 4.7 `5b4e0cb0f`, Compatibility/OpenGL 3.3, GTX 1060 3GB driver 560.94.
Actual PNG headers are checked at **1920×1080**, after forcing the viewport
following the first frame. Scaled review sheets are not native-resolution proof.
Raw local paths, hashes and placement/grounding receipts are retained in
`MESHY-DRINKS-EVIDENCE.json`.

Final focused tests: **36 tests, 799 assertions, 0 failures** across stat-drink
imports, cache pickup behavior, shared pickup glow and Stormwood pickup runtime.
These include preservation of root/prompt/claim data, bottle scale, single glow
registration through repeated offsets, exclusion of reward beams, and teardown
after claims and direct removal.

Independent source/asset review: all badge binaries have zero degenerate
triangles, no inconsistent shared-edge directions and no normals opposing their
winding. Relief components are closed; the disc/rim boundaries are intentional.
Scene resource sharing, Meshy texture identity and reward preservation passed.
Blender rebuild reproducibility was not independently rerun.

Independent code-blind art-stage review: **bounded PASS** on all six front
badges, the repaired shield/lightning contours, sampled side/rear fit, material
finish and ground contact. Might's crossed blades now distinguish it from Attack
at trainer scale. Previous candidates with intersecting inlay faces are superseded.

Final retained local set: **39 native frames** (27 stage, 6 Meadows, 4 Tidewake,
2 Stormwood), four capture runs exiting zero with no skipped rows. Independent
code-blind regional review: **bounded PASS for bottle finish, pickup-kind
recognition, discoverability, integration and scale** in all three regions.
Tidewake Attack on bare sand gives the strongest visible grounding witness;
vegetation and glow obscure precise base contact elsewhere. Measured base-to-
ground gaps are zero in Meadows/Tidewake and under 0.000002m in Stormwood.

**Specific effect/permanent-class recognition at the production camera remains
FAIL.** Badges occupy roughly ten pixels in these stands and become very dark
at night; reverse-facing Might cannot reliably be distinguished from Attack.
The glow locates the pickup without identifying its stat. Meadows Attack also
has a sapling overlapping the silhouette. These findings remain open rather
than being hidden by the successful close-up art review.

Meadows Swift remains a coverage gap: the earlier fixture stand put the camera
inside scenery, so it is excluded instead of counted as evidence. Side-on stat
identification is weak, reverse marks are smaller, and Guard/Stoneguard still
depend chiefly on colour and the permanent pips. Held-item scale, earned pickup
sequences and complete visual Bars A/B are not claimed.

![Six badge variants, scaled review](./_sheet_meshy_drinks.jpg)

The comparison below shows the owner-rejected procedural candidate beside the
new Meshy candidate; it is not a before capture of GitHub main's stand-ins.

![Rejected procedural candidate and Meshy replacement](./_sheet_meshy_drinks_comparison.jpg)

![Regional pickup views, scaled review](./_sheet_meshy_drinks_world.jpg)
