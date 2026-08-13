# D28 — OF4 becomes a real assembled castle, built with a real placement grid

**Date:** 2026-08-13 · **Decided by:** the owner, directly, after the backlog
audit ahead of the Phase 1 vocabulary change surfaced `BLOCKED.md`'s "OF4
silhouette ceiling" as unresolved.

Kind: design + implementation

## The problem

`OF4` (shipped `ralph/OF4`, six blind critique rounds) moved the stronghold's
procedural-primitive silhouette from "witch's hat / chess rooks / standing
stones" to a shape every critic parsed in fortress vocabulary — but the
170m from-square frame still drew "sandcastle," and rounds 5–6 converged
with nothing addressable left in `landmark.gd`'s toolkit (`SHADER_CODE`,
`CylinderMesh`/`BoxMesh`/`PrismMesh` primitives under one unshaded flat-fill
material). `BLOCKED.md` recorded two remaining levers, both unsatisfying:
accept the placeholder read until a Phase 8e Meshy hero asset replaces it,
or trade wayfinding consistency for atmosphere by reverting the
`unshaded`/`fog_disabled` opt-out — already tried and reverted twice.

Separately, `OF13` (shipped after `OF4`) moved the fortress ~105m onto the
rise's far shoulder specifically so it is **not** visible from the village
square or the Rise path anymore. The original 170m from-square critique the
six-round history was scored against no longer describes any frame a player
actually sees — whoever picks up the rebuild below should re-render and
judge from wherever the structure is genuinely visible now.

## What was decided

Rather than accept either lever, the owner asked for a different kind of
fix entirely: **build a real castle out of real modules, placed with a real
in-world building grid, and stop treating this as a silhouette problem.**
"then don't worry about it being a silhouette. just make it render the
actual built castle."

Research before this decision landed established two real gaps that make
this bigger than a landmark-only task:

1. **No grid-placement system exists yet.** The player's own build system
   (`GAME_DESIGN.md` §20, `MEADOWS_VERTICAL_SLICE.md` M8) is real but
   minimal: `build_placer.gd` ghost-places exactly one unrotated piece 3m
   ahead of the player, with no rotation and no snapping —
   `tab_build.gd`'s own header comment already said as much ("snapping...
   does not exist and is not this agent's to write"). The closest thing to
   a "grid" anywhere in the repo is `building_prefabs.json`, an
   author-time recipe format (`{module, at, yaw_deg}` entries) already used
   to compose the whole `EV6` settlement on a 2m module grid — proven at
   scale, but not a runtime player-facing system.
2. **No fortress-appropriate modules exist yet.** Both staged Quaternius
   kits (Medieval Village, 176 models; Fantasy Props, 94 models) were
   checked filename-by-filename: entirely civilian plaster/brick/timber
   walls, roofs, doors, stairs, corners, plus exactly one tower-roof cap
   (`Roof_Tower_RoundTiles`). No `Tower`, `Gate`, `Battlement`, `Crenel*`,
   `Rampart`, `Keep`, `Portcullis` or `Arrow*` module exists in either kit.

The owner confirmed, given both gaps, that building the real system first
is the right call rather than faking it with civilian parts or scoping
down to the static recipe format alone (`ralph/BACKLOG.md`'s `BG1`, `BG2`,
`OF4-rebuild` carry this forward).

## What was rejected

- **Accepting the primitive-shader placeholder until Phase 8e.** Still an
  option in principle, but no longer the plan — superseded by this
  decision, not merged with it.
- **Reverting the `unshaded`/`fog_disabled` opt-out.** Already tried and
  reverted twice per `landmark.gd`'s `TOWER_COLOUR` history; not revisited.
- **Composing OF4 from the civilian kits as-is.** Would very likely read as
  a reskinned village compound, not a castle — a real downgrade from the
  fortress vocabulary the shader silhouette had already won across six
  critique rounds. Rejected in favour of sourcing genuine fortress modules
  (`BG2`) before rebuilding the landmark.

## Consequences

- A real grid/rotate/snap placement system (`BG1`) is now in scope ahead of
  Phase 1, not deferred as future-only player-facing polish. Building it to
  serve both the player's own base and `OF4-rebuild` avoids a second,
  landmark-only placement system nobody else can reuse.
- `BG2` (a real castle/fortress CC0 kit) is an owner-supply action, tracked
  in `ralph/BLOCKED.md` the same way the Stylized Nature MegaKit is tracked
  for `EV2-landmark-ceiling`.
- `landmark.gd`'s procedural primitives are retired once `OF4-rebuild`
  ships, not kept as a fallback — per `CLAUDE.md`'s "no half-finished
  implementations," the loop should not carry two competing stronghold
  presentations once the real one lands.
- This does **not** touch the Phase 8e `15_Legendary_Tether_Machine.png`
  hero-asset gate — that board depicts a *different* object (the tether
  machine, gated in `BLOCKED.md`'s reference-art section), and remains
  Meshy-generated, owner-supplied-reference-art work, unaffected by this
  decision.

## What would change this

If `BG2` cannot find or acquire a genuinely fortress-appropriate CC0 kit,
this reopens as the same design question `BLOCKED.md` originally posed —
accept a civilian-vocabulary compound, or fall back to the Phase 8e hero
asset for the landmark's real presentation.
