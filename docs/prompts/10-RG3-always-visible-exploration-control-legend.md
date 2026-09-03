# RG3 — Always-visible compact exploration control legend

## Goal
Make Tetherbound's normal exploration controls discoverable at all times on the Meadows HUD without turning the screen into a large instruction panel.

The owner explicitly wants a **small, always-visible control legend during normal exploration**. Context-sensitive prompts such as Talk / Gather / Open / Ride / Fight should continue to use the existing contextual prompt system rather than being permanently duplicated into the legend.

## Owner-reported problem
The owner could discover actions such as opening the build menu or taking out a torch only by trying buttons because the exploration HUD did not tell the player what the important persistent controls were.

The original examples were conceptually:
- Build
- Map
- Inventory
- Change Creature

Those examples describe the intended class of actions, not a mandate to hard-code specific physical buttons. The displayed glyphs must come from the live input bindings / existing input-glyph system.

## Player-facing behavior
During ordinary exploration, a compact legend is always visible and shows the major persistent navigation/gameplay verbs that a player should know without first approaching an interactable.

A typical controller presentation may conceptually read:

`[glyph] Build   [glyph] Map   [glyph] Inventory   [glyph] Change Creature`

Use the actual current action names, bindings, labels, and glyph mapping present in the repo rather than copying this string literally if those differ.

The legend should:
- stay visible during normal Meadows exploration;
- be compact enough to feel like part of the HUD, not a tutorial overlay;
- use the existing input-glyph system so controller/keyboard display stays truthful;
- update when the active input device or binding presentation changes, if the existing glyph layer already supports that;
- hide or yield appropriately when a full-screen/modal UI owns the screen or when ordinary exploration HUD is intentionally suppressed;
- not duplicate the existing contextual interaction prompt line.

## Current repo state to inspect first
Relevant systems include at minimum:
- `scripts/ui/playground_hud.gd`
- `scripts/ui/input_glyph.gd`
- the exploration HUD scene mounted by the Meadows world
- `project.godot` InputMap definitions
- current actions used by the HUD/world shortcuts, including the build shortcut and menu/map/inventory/party or active-creature controls
- contextual prompt ownership / `interaction_arbiter.gd`

`playground_hud.gd` already:
- renders the real exploration HUD;
- owns a bottom contextual prompt;
- renders hotbar action glyphs;
- reads world shortcuts including `build_open`;
- uses `input_glyph.gd` for glyph presentation.

Build on those systems. Do not create a second independent controller-label database.

## Implementation requirements
1. **Audit the real persistent exploration actions before choosing the legend contents.**
   - Identify the small set of actions a new player needs constantly during normal traversal.
   - At minimum account for the owner's requested classes: Build, Map, Inventory, and Change Creature / party cycling if currently available.
   - Include another persistent verb only if it is comparably important and already part of normal Meadows traversal. Do not let the legend grow into every binding in the game.

2. **Use live action-to-glyph mapping.**
   - Labels may be authored, but physical button glyphs must come through the existing input binding/glyph infrastructure.
   - A visible glyph is a promise. It must match the action that actually fires.
   - Preserve keyboard/mouse presentation where supported.

3. **Keep contextual actions contextual.**
   - Talk, interact, gather, open, fight, ride, etc. should continue through the existing interaction prompt / arbiter path.
   - Do not permanently list every possible interaction in the always-visible legend.

4. **Respect UI ownership.**
   - The legend is for normal world exploration.
   - It should not sit over pause menus, naming prompts, story dialogue, shop/craft/storage panels, or other screens that intentionally own input.
   - Follow the same visibility/ownership conventions already used by the rest of the exploration HUD instead of inventing a parallel modal detector.

5. **Controller-first readability on the ROG Ally.**
   - Verify at the project's authored 1920x1080 HUD scale and its stretched handheld presentation.
   - Use existing `UITokens`/HUD styling conventions where practical.
   - Keep one-line or otherwise compact composition with sufficient spacing and legibility.
   - It must not collide with the hotbar, contextual prompt, minimap, active-creature block, objective line, or region announcement under their dynamic heights/states.
   - Prefer a container/layout relationship over hand-tuned one-off pixel overlaps where the current HUD architecture supports it.

6. **Do not change gameplay bindings merely to make the legend prettier.**
   - This task exposes controls; it does not redesign the control scheme.
   - If an action has no valid binding or its displayed binding fails in play, record that as a functional input defect and fix only if it is clearly the same shared cause already covered by RG6. Do not silently remap the game here.

## Design constraints / preserve list
Preserve:
- existing contextual prompt behavior;
- existing hotbar and its glyphs;
- existing exploration HUD layout and Palworld-inspired visual direction;
- controller-first ROG Ally behavior;
- keyboard/mouse support;
- modal/input-owner behavior;
- existing action names and InputMap bindings unless a genuine broken binding is discovered and fixing it is required for the visible promise to be true.

Do not:
- build a giant controls overlay;
- show every game action permanently;
- hard-code Xbox letters independently of InputMap/input-glyph;
- duplicate contextual Talk/Gather/Open/Fight/etc. prompts;
- make the legend fade away after onboarding — owner explicitly chose **always visible but compact** for normal exploration.

## Edge cases
Verify:
- no creature in party vs one/multiple creatures;
- active creature can/cannot currently be cycled;
- controller connected at boot;
- keyboard/mouse used after controller and vice versa;
- build menu opens/closes;
- pause/full-screen menu opens/closes;
- story dialogue or naming modal owns the screen;
- hotbar message row expands;
- contextual prompt appears/disappears;
- minimap/objective/region banner visible simultaneously.

The legend should not lie if an action is temporarily unavailable. If the existing game has a clear unavailable-state convention, use it; otherwise keep the legend about globally available persistent verbs rather than creating complex per-frame enable/disable logic.

## Testing / verification
Add or extend focused tests/smokes so they verify behavior rather than only node existence.

At minimum verify:
1. normal exploration renders the compact legend;
2. expected major action labels are present;
3. glyphs are produced through the live glyph/action mapping;
4. changing input device presentation updates the legend if `input_glyph.gd` supports device switching;
5. opening a modal/full-screen menu does not leave the exploration legend incorrectly over that screen;
6. returning to exploration restores it;
7. contextual interaction prompts remain independent and still work;
8. the HUD layout does not overlap at the project's normal authoring resolution when hotbar messages and contextual prompts are present.

Where controller event behavior is tested, prefer real InputMap-backed joypad events as established by the RG6 audit rather than fake action-only events that can bypass mapping problems.

## Acceptance criteria
- A new player standing in the Meadows can see, without experimenting, how to access the major persistent exploration functions.
- The legend is always visible during ordinary exploration.
- It remains compact and readable on the ROG Ally.
- It includes the owner-requested functional classes: Build, Map, Inventory, and Change Creature / equivalent live party-control verb where currently implemented.
- The physical glyphs accurately reflect the live binding system.
- Contextual verbs remain in the contextual prompt rather than bloating the permanent legend.
- No overlap/regression is introduced in the hotbar, prompt, minimap, objective, active-creature HUD, modal screens, or keyboard/mouse controls.

## Definition of done
RG3 is done when the Meadows exploration HUD continuously and truthfully teaches the core persistent controls in a small HUD legend, while the existing contextual prompt continues to teach situation-specific actions.
