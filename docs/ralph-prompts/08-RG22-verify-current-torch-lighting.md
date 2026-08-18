# RG22 — Verify current torch lighting; do not retune unless the current build still fails

## Goal
Verify RG22 on current `main` after RG21 lands. The owner’s original torch-brightness complaint came from an older ROG build before the recent night/torch updates. The owner has now reviewed the updated torch/night captures and says they look good.

This is therefore a **verification-first item**, not a tuning request.

## Owner source of truth
Original report:
- “The torch should probably light up a little more.”
- “The torch doesn't go in your hand like a axe does. It should.”

Latest owner update, 2026-08-18:
- “I think the updated torch pictures actually looked good. I just played it before updates were made to the dark and the torch.”

The newer word wins.

## Current repo state to respect
Read current `main` before editing, especially:
- `scripts/player/torch.gd`
- `scripts/player/tool_hold.gd`
- `data/config/movement.json`
- RG21’s final day/night implementation and art values
- relevant night/torch capture tools and smoke tests

Current code already shows that:
- the hand-attach half of RG22 has been fixed through the generic held-tool pipeline;
- torch light is gated on the torch actually being equipped;
- the light consists of a warm forward SpotLight plus a smaller in-hand OmniLight/flicker;
- brightness was intentionally left to the night-light tuning work.

Do not recreate or replace those systems.

## Required behavior
On the current build, after RG21:
1. Equip the torch normally through the real inventory/hotbar/tool path.
2. Confirm the torch mesh is visibly in the trainer’s hand.
3. Confirm its light originates from / visually tracks the held torch.
4. Confirm night remains meaningfully dark without the torch.
5. Confirm the equipped torch makes nearby traversal comfortably readable without turning the world into daylight.
6. Confirm the updated result still matches the current owner-approved captures.

## Critical constraint
**Do not change brightness, range, colour, falloff, night exposure, ambient floor, or other visual tunables merely because RG22 exists.**

Only make a visual tuning change if the current post-RG21 build demonstrably reproduces a problem on real gameplay/capture evidence.

If the current build looks good and the torch behaves correctly, the correct outcome is:
- no tuning change;
- verification evidence;
- mark RG22 complete/already fixed by prior work.

## What must not change
Preserve:
- torch as an equippable carried tool, not a permanently active kit light;
- generic `tool_hold.gd` hand attachment;
- no light when the torch is not equipped;
- warm fantasy-torch character;
- existing manual/automatic lighting behavior unless a separate current bug proves it wrong;
- handheld performance constraints;
- RG21’s final night/day balance.

Do not:
- add a second torch prop;
- restore the old hip-mounted duplicate;
- make the torch illuminate the whole biome;
- add shadow-heavy expensive lighting without evidence;
- tune against pre-RG21 screenshots or an old build.

## Verification
Use the most current in-engine night/torch capture path available and, where possible, a real controller/ROG-equivalent gameplay path.

Verify at minimum:
- torch unequipped → no torch light;
- torch equipped → held prop visible and light active;
- light follows the held prop correctly;
- representative ground/path/vegetation/creature readability near the player;
- distant night remains dark enough to preserve nighttime mood;
- no regression when cycling tools / unequipping / re-equipping.

## Acceptance criteria
RG22 is complete when one of these is true:

### Preferred / expected result
Current post-RG21 build matches the owner-approved updated captures and the torch works correctly. No visual tuning is changed. Evidence is recorded and RG22 is closed as already resolved by intervening work.

### Only if a current defect remains
A specific reproducible defect is demonstrated on current `main`, the smallest shared cause is fixed, and before/after evidence shows the change improves that defect without undoing RG21 or the owner-approved torch look.

## Definition of done
- Current build verified, not assumed.
- Hand-attach verified.
- Equip-gated lighting verified.
- Current night/torch visual result checked after RG21.
- No speculative retuning.
- If no defect remains, close with evidence and no code changes.
