# HUD callout 01 — retained

## Defect and correction

The two-party HUD repeated one action: CombatHUD drew the specific
`Call out Biscuit` prompt while PlaygroundHUD's persistent legend also drew
generic `Call Out`. This was not capture staleness. PlaygroundHUD intentionally
blanked its own prompt whenever the EncounterDirector owned the arbiter winner,
then tested only that blank label when deciding whether the legend should carry
recall.

The retained fix uses the existing ownership route. When the arbiter winner is
the combat prompt owner, PlaygroundHUD checks the authoritative arbiter prompt;
otherwise it checks its own prompt label. It suppresses only the duplicate
recall entry. Map, Satchel, Build, Change Creature, input bindings and gameplay
behavior are unchanged.

## Evidence

- `hud-callout-dedup-smoke-first` ran
  `tests/smoke_exploration_legend.gd` from 2026-09-10
  09:37:48–09:37:54 UTC, exit 0 with `errors: []`.
- `hud-callout-dedup-native-first` ran the production Water catalogue at Gull
  Rest Beach from 09:38:03–09:38:45 UTC, exit 0 with `errors: []`. Its eight
  frames and manifest are in `shots/diagnostics/hud-landscape-space03`.
- The actual controller audit cycled party index 0→1 with LB, called the ally
  out and put it away with RB, and ended with no ally body. The recorded recall
  presentation source is `combat_prompt`.
- In both day and night two-party candidate frames, CombatHUD contains exactly
  one real `Call out Biscuit` prompt and the legend omits Call Out. The legend
  measures 751×76 px versus the matched prior control's 940×76 px.
- `JUDGE-HUD-CALLOUT01.md` narrowly prefers new F03/F04 over old F01/F02 for
  removing the repeated action and returning lower-center scene space. It
  judges the world/character presentation tied and the overall frames below
  commercial readiness.

## Disposition

Retained. The production source, focused smoke, actual LB/RB route, native
day/night frames and blind preference agree on the bounded interface gain. No
claim is made about unrelated HUD density, vitals contrast or world art.
