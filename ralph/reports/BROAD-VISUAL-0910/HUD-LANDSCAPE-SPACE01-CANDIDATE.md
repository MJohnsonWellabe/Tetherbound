# HUD landscape space 01 — candidate

## Scope and source diagnosis

The persistent lower action strip advertised **Call Out / Put Away** and
**Change Creature** even when those actions could not succeed. The HUD already
had the required state: party membership, active selection, faint/rest state,
deployed ally state and party revision. `EncounterDirector` rejects an absent,
fainted or resting active creature, while `Party.cycle_active()` returns false
when no usable different slot exists. The candidate uses those same conditions
and fits the panel to the resulting content, up to the prior 940 px width.
Fonts, glyphs, controls and the 76 px height are unchanged.

The objective plate also separated its minimum wrapped-line count from its
four-line cap. This is structurally safe for a future one-line title because
the plate still measures and grows for two through four lines. Native evidence
found that the shortest current authored title, `Make camp for your team.`,
wraps to **two lines**, however. The one-line floor therefore provides no
present authored-objective height gain.

## Candidate behavior

- Map, Satchel and Build remain present in ordinary exploration.
- Recall appears only for a summonable active creature or an ally already out.
- Change Creature appears only when a usable member exists in a different slot,
  including the invalid-active-slot edge case handled by `Party.cycle_active()`.
- The panel measures its live BBCode and inline glyphs and retains the prior
  940 px full-action ceiling.
- Objective text keeps the 348 px width, 32 px font and complete two- through
  four-line layout.

## Focused validation

`hud-landscape-legend-first` ran `tests/smoke_exploration_legend.gd` clean from
2026-09-10 08:55:43–08:55:49 UTC. It covers empty, one-usable, fainted,
invalid-active and two-usable party states; content-width growth; glyph
switching; prompt and modal ownership; and dock bounds.

The first objective and native attempts are retained failures, not evidence:

- `hud-landscape-objective-first`, 08:56:02–08:56:07 UTC, exited 1 because
  warning-as-error parsing could not infer the type returned by
  `get_script_constant_map()`.
- `hud-landscape-native-first`, 08:56:08–08:56:16 UTC, exited 1 on the same
  issue in three probe call sites. Its broad `gull_rest` subset would also have
  selected two destinations rather than the required single destination.

All four reads now use an explicit `Dictionary`, and the native subset is
`gull_rest_beach`.

`hud-landscape-objective-second` ran
`tests/smoke_objective_hint_card.gd` from 09:02:44–09:02:50 UTC, exit 0 with
`errors: []`. All 28 authored titles fit at the production width and font,
the longest remains complete within four lines, and the shortest title
measured two lines and 166 px. The fixture's no-player warning is expected and
did not fail the smoke.

`hud-landscape-native-second` ran from 09:03:35–09:04:20 UTC, exit 0 with
`errors: []`, and wrote eight frames plus the manifest at
`shots/diagnostics/hud-landscape-space02/manifest.json`. The actual LB/RB audit
added two installed creatures through `Game.make_creature` and `Party.add`,
cycled active index 0 to 1, called the ally out, put it away, and left it absent.
The capture retained the production camera and frozen clock within each pair.

Measured at the native authored 1920×1080 canvas:

| State | Candidate legend | Prior control | Objective candidate/control |
|---|---:|---:|---:|
| Empty party, day/night | 464 px | 940 px | 166 / 168.8 px, 2 lines |
| Two healthy, ally stowed, day/night | 926 px | 940 px | 166 / 168.8 px, 2 lines |

The empty-party result is a substantial legitimate reduction. The ordinary
two-member fixture shows only a 14 px reduction because all five labels were
drawn; the objective difference is 2.8 px and is not a meaningful landscape
gain. The manifest discloses debug travel and party setup and makes no campaign
or performance claim.

## Blind visual disposition and discovered duplicate

`JUDGE-HUD-LANDSCAPE01.md` prefers the empty-party candidate F03/F04 over the
old F01/F02 because the unavailable creature actions disappear. It reports a
narrow F07/F08 preference over old F05/F06 based on apparently brighter Change
Creature text, but the manifest disproves that explanation: both controls use
the same `TEXT_PRIMARY` `#f2f5f2ff` tint as the candidate. This disposition
therefore does **not** credit a two-party legibility win. The judge found no
meaningful landscape-space improvement in that pair and did not find the
overall frames commercially ready.

All old and new two-party frames also show the pre-existing recall duplication:
CombatHUD draws the centered `Call out Biscuit` prompt while PlaygroundHUD's
legend draws `Call Out`. This is a real settled-state mismatch, not a capture
artifact: both candidate PNGs show it after eight settle frames. The manifest
records PlaygroundHUD's prompt text as empty because
`_prompt_belongs_to_combat()` deliberately blanks that surface when the
EncounterDirector owns the arbiter prompt; CombatHUD then draws the director's
prompt separately. The legend suppression currently inspects only the blank
PlaygroundHUD label. A narrow follow-up patch is held separately; this
candidate does not claim to fix the duplicate.

## Status

The unavailable-action removal is supported by clean focused/native evidence
and the blind preference in the empty-party state. The objective floor is safe
but yields no present authored height gain. The common two-party width gain is
minor and has no credited visual win; overall acceptance remains below the
commercial bar. The known recall duplicate remains open for the bounded
follow-up.
