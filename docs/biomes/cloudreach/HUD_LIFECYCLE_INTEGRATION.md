# Shared combat / exploration HUD lifecycle

Production relay frames exposed a real ownership defect: the previous trainer
result still said “wild creature”, while location, enemy plate, mechanic hint,
tracked task, hotbar/reward message and exploration legend competed for the view.

## World hook

Both `CombatHUD` and `PlaygroundHUD` now accept
`set_world_presentation_mode(mode)` with `combat`, `relays`, or `exploration`.
Call it on a real authored phase change and once when mounting/restoring a world.
The Cloudreach integration owner has connected this to the actual finale phase.
No gameplay flags, input actions, encounter rules or scene geometry change here.

- Combat: the enemy/ally plates, combat move controls and combat party rail own
  the screen. Location/time, instruction card, tracked task, minimap and ordinary
  exploration toolbar stand down.
- Relays: combat result/XP/GO text, combat controls and combat party rail clear
  immediately. One exploration party rail and the real contextual relay prompt
  remain. The mechanic instruction yields temporarily to the shared reward or
  level-up banner; hotbar, legend, task card and human vitals remain hidden.
- Exploration: existing widgets restore. A shared progression Moment takes
  priority over map/task/location/instruction so the reward is not buried.
- Modal: existing dialogue/menu input ownership remains authoritative. Upper
  supporting widgets can remain where the established dialogue overlap test
  allows them; the lower toolbar/prompt/vitals stand down.

The final visibility pass runs after legacy HUD polling, including cached-label
writers. It preserves new contextual offers on a mode transition and does not
revive expired location/instruction timers. Visibility never disables bindings.

## Reward provenance and ordinary combat

Trainer wins no longer issue a wild-creature verdict. Their round progression
still uses the production combat manager, while ordinary wild/catch/loss output
remains unchanged. Definitive trainer victory relinquishes the old result layer.

The existing production payout's exact `Name's reward: ...` receipt is routed by
the shared world-message consumer into `Game.progression_feed` as `reward_summary`.
It reports only what the payout source actually placed in inventory. The HUD
neither recalculates nor grants rewards. The shared presenter combines a receipt
with a queued level/bond Moment where possible, otherwise displays a compact
receipt with the active creature's latest XP event/current EXP. This latest XP
line is not a claimed sum of all trainer rounds. The text-format bridge is
explicit: if the production receipt format changes, update this routing test.

Progression Moments wait through the entire trainer chain, including intervals
between creatures. Inactive combat party strips now decline feed updates, fixing
a second defect where an XP tick resurrected a hidden combat rail beside the
exploration rail. The receipt/header font sizes compensate for the production
1920-wide authoring canvas so 1280 rendering retains physical 24/18-pixel text.

The second review correction keeps the relay roster at native pixel scale
(336×48 rows, 18-pixel names / 16-pixel progression text) and full text contrast.
It is pinned only for the post-combat mechanic; normal exploration/combat sizing
and reveal timing remain unchanged. The reward names the defeated trainer and
explicitly identifies the still-active relay objective. Enemy identity uses the
production manager's ownership and director's trainer name, with valid level
data; missing levels are omitted instead of displaying an unfilled dash.
The fixture switches input through a real joypad event and renders the existing
mapped `interact` glyph, rather than inventing a screenshot-only control.

## Evidence

- `test_hud_presentation_lifecycle`, announcement, HUD widgets and progression
  feed: **45 tests / 194 assertions / zero failures**.
- `smoke_hud_presentation_lifecycle`: **24 checks / zero failures**, actual shared
  HUD scenes rendered at 1280×800. This is an isolated interface fixture, not a
  played battle. Its `before-overlapping-layers` image explicitly reconstructs
  the historical overlap state; it is not an old production screenshot.
- Existing dialogue overlap smoke: **PASS**, 37 populated widgets measured,
  none intersecting the real dialogue box; restoration also passes.
- Existing objective-hint smoke: **PASS**, all 27 authored hints fit and expire.
- Existing shared progression smoke: **26 headless assertions / zero failures**.
- Production captain/relay input and current-world captures are owned by
  `smoke_cloudreach_production_integration` and the world integration lane.

Isolated captures are in `shots/hud-lifecycle/`. Production defect frames were
1280×720; fresh production 1280×800 evidence is coordinated by the world lane.
Final independent code-blind review is **Pass for the captured isolated UI**
(`shots/hud-lifecycle/JUDGE.md`), after a revise/replay cycle addressing party
readability, controller glyph, completed-versus-next phase, and owner/level data.
Optional owner/level metadata polish remains non-blocking. No static fixture
certifies controller execution, timing, physical handheld comfort or the full
continuous chapter.
