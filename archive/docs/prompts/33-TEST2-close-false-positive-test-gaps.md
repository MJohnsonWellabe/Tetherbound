# TEST2 — Close known false-positive gaps in the test suite

## Goal
Strengthen four specific regression areas where current tests can pass while the player-facing feature is still broken. This is test-quality work first; only fix production code when a stronger test proves a current defect.

## Gap 1 — Real build-piece selection path
Current build placement tests have historically armed `pending_build` directly, bypassing the Build menu selection/close/ghost handoff.

Add coverage that drives:
**open Build menu -> navigate/focus a real piece -> confirm with actual UI input -> menu closes -> pending piece/ghost appears -> later fresh place press commits it.**

This should complement RG4/RG14 tests and fail if menu selection stops arming a piece.

## Gap 2 — `InputEventAction` hides binding failures
Where controller/menu tests currently synthesize `InputEventAction`, replace or supplement with the **actual event class present in live InputMap** (`InputEventJoypadButton`, `InputEventJoypadMotion`, keys as relevant) sent via `Input.parse_input_event`.

The regression should fail if a binding is missing/wrong even though the abstract action name still works when injected directly.

Do not remove useful low-level unit tests; add the player-input contract above them.

## Gap 3 — Joypad binding collision audit
Current controls collision test primarily protects keyboard mappings. Add a context-aware joypad collision audit over the live InputMap.

Requirements:
- define/read contexts from the existing menu/control metadata where possible rather than a giant hard-coded exception list;
- same physical button/axis may legitimately serve mutually exclusive contexts (combat vs build vs exploration);
- same-context collisions that cause two verbs from one press must fail;
- explicitly account for intended aliases such as Godot `ui_accept` and the game's confirm action where documented;
- triggers/axes need direction considered, not just axis index.

The test should explain the conflicting actions/context in its failure message.

## Gap 4 — OW8 layout regression is too weak
Strengthen the HUD overlap test that was intended to protect the bottom hotbar/context-prompt relationship. The real invariant is architectural: controls whose dynamic height can change must share a load-bearing layout parent/container that prevents overlap, not merely happen to have non-overlapping rectangles in one initial frame.

Assert the structural relationship (shared container/order/separation or equivalent invariant) and also exercise the hotbar-message-visible state that changes height. A static rect snapshot at rest is insufficient.

## Test quality rules
- A test must first assert the feature/object exists, then its behavior.
- No tautological assertions.
- Headless smoke where possible.
- UI focus tests use real parsed input events.
- Keep tests deterministic; do not replace weak assertions with arbitrary sleeps.
- Name failures in player-facing terms.

## Acceptance criteria
1. Build-menu-to-ghost path is exercised through real input and would fail if only direct arming still worked.
2. Representative controller tests use events sourced from current InputMap and catch missing bindings.
3. Same-context joypad collisions are automatically rejected while documented cross-context reuse remains legal.
4. OW8 regression asserts the layout structure and dynamic message state, not only one frame's rectangles.
5. Existing tests remain green or failures expose genuine current regressions that are fixed at root cause.

## Definition of done
The suite can no longer claim these four features work by testing around the exact seams where real players previously found them broken.