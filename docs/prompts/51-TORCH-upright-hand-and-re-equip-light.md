# TORCH — Hold it upright and make the light survive repeated equip cycles

## Owner reproductions — 2026-08-18 evening
1. The torch still does not sit correctly in the trainer's hand. The flame end should be **up**, like a person actually carrying a torch.
2. The torch lights the world the first time it is pulled out, but **does not light things the second time it is equipped**.

These are concrete current failures. They supersede the previous RG22 verify-only conclusion.

Do not start by retuning brightness. Fix transform/orientation and equip lifecycle first, then verify the already-approved light tuning against the final night.

## Goal
The carried torch should be a reliable tool:
- visible shaft held naturally in the hand;
- flame/light origin above the hand;
- flame end points upward regardless of trainer facing;
- each equip turns the light on according to current night/manual rules;
- each unequip turns it off;
- repeated equip/unequip cycles behave identically.

## Inspect first
- `scripts/player/tool_hold.gd`
- `scripts/player/torch.gd`
- current held-prop attachment/socket/bone transforms
- item/tool orientation metadata if any
- GameState `equipped_tool` update path
- hotbar equip/cycle code
- torch manual/auto-at-night state
- SpotLight3D/OmniLight3D node creation and reparent/sync path
- current torch tests and night capture tool

The existing architecture intentionally lets `tool_hold.gd` own the visible in-hand prop while `torch.gd` owns only lighting/flame sync. Preserve that separation unless current main has changed.

## Orientation
Diagnose which coordinate frame is wrong:
- imported torch mesh local up/forward axis;
- generic tool socket rotation;
- torch-specific held offset;
- prop child transform;
- flame/light sync assuming a different mesh axis.

Do not rotate the entire trainer arm/skeleton just to compensate for one prop.

Prefer a torch-specific held transform/metadata if axes differ from axe/pickaxe.

Acceptance visual:
- hand grips lower/middle shaft;
- flame/burning end clearly above hand;
- shaft is roughly vertical/naturally angled rather than upside-down/horizontal;
- flame/light origin is at the visible burning end;
- does not clip absurdly through torso/head during idle/walk.

## Re-equip light lifecycle
Reproduce this exact sequence on current main:
1. begin at a time/condition where torch should illuminate;
2. equip torch -> light visibly on;
3. switch to axe/empty -> torch prop/light off;
4. equip torch again -> prop appears and light must return;
5. repeat 10+ cycles;
6. repeat across manual toggle and automatic-night modes.

Instrument:
- `Game.equipped_tool` per transition;
- torch `_is_equipped()`/`_is_on()` result;
- light node existence and `visible`/energy state;
- tool prop node validity/path;
- whether torch cached a prop reference that was freed/replaced by `tool_hold`;
- whether manual override state is unintentionally latched across unequip;
- whether flame sync stops because a one-time connection/process was disabled.

The second-equip symptom strongly suggests stale cached node/state or an incomplete reactivation path. Prove it instead of simply rebuilding the lights on every frame.

## State contract
- Unequipped torch is inert: no invisible light source.
- Equipping torch recomputes current desired light state from authoritative equip + day/night/manual state.
- Swapping away cannot permanently clear or detach something needed for the next equip.
- Manual toggle semantics remain predictable. If manual-off persists intentionally when re-equipped, UI/state must make that clear; otherwise reset according to existing design. Do not invent a new toggle policy without checking current comments/decision.
- Night auto-light operates only while torch is equipped.

## Light sync
The SpotLight/Omni flame origin should follow the current held prop's burning end. If `tool_hold` recreates the mesh on every equipment swap, `torch.gd` must reacquire the new prop rather than hold a dead reference.

Do not add a second visible torch mesh on hip/hand.

## Regression tests
Add a focused repeated-equipment test that:
- equips torch;
- verifies correct light state;
- unequips;
- verifies light off;
- equips again;
- verifies light on;
- loops repeatedly;
- verifies no duplicate light nodes/prop meshes accumulate.

Where transform math is testable, assert burning-end anchor lies above grip/hand in the trainer's local/world pose. Final orientation still needs rendered verification.

## Visual verification
Capture:
- front/side trainer holding torch during day;
- night torch equipped first time;
- night torch equipped after several swaps;
- torch walking pose.

Judge hand orientation and world illumination separately. The owner previously liked the updated torch lighting pictures; do not brighten it merely because this item reopened.

## Acceptance criteria
1. Torch flame end is visibly upright above the hand.
2. Light origin matches flame end.
3. First equip lights correctly.
4. Second and every subsequent equip lights identically.
5. Unequip removes/inactivates light.
6. No duplicate props/lights accumulate across swaps.
7. Manual/auto-night semantics remain coherent.
8. Current night/brightness tuning is preserved unless post-fix live verification shows an actual brightness defect.

## Definition of done
The torch looks like something a person is carrying and behaves like the same reliable light source every time it is drawn, not only on the first equip.