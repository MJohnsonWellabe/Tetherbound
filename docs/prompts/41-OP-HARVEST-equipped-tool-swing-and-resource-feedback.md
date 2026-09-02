# OP-HARVEST — Equipped tools, visible swings, and resource gain feedback

## Goal
Make gathering feel like a real physical action instead of a prompt/state change.

## Owner-reported failures
- chopping should require the axe actually out;
- the trainer should visibly swing it;
- current flow can show a chop prompt but pressing it appears to do nothing;
- collecting wood needs clear feedback such as `+3 Wood`.

## Required interaction contract
For trees/wood:
1. Axe exists in satchel/hotbar and is explicitly equipped.
2. Axe is visibly in the trainer's hand.
3. The correct use-tool input triggers a visible swing animation.
4. The harvest hit is synchronized to a deliberate point in that swing, not fired invisibly before/after with no feedback.
5. Valid tree reacts and receives chop progress/damage.
6. Felled resource/drop appears through the existing gather architecture.
7. Picking it up shows concise quantity feedback (`+X Wood`).

Apply the same systemic contract to other dedicated tools where current gameplay uses them (pickaxe/stone/ore etc.) without inventing new tool roles.

## Wrong-tool behavior
A harvestable requiring an axe must not be harvested empty-handed or with an unrelated tool. If the player approaches without the right tool, prompt/feedback may tell them what is needed, but pressing interact must not simulate a hidden axe hit.

## Animation and prop ownership
Reuse current `tool_hold.gd`/equipment and trainer animation systems. Diagnose why tool-use and visible prop state diverge before adding another prop instance. Swing animation must not leave the tool floating, inverted or duplicated.

## Resource feedback
Use one lightweight shared pickup/gain presentation for gathered resources. It should:
- identify quantity and item (`+3 Wood`, `+2 Stone`);
- appear immediately on successful acquisition;
- aggregate rapid pickups where appropriate rather than spam unreadable messages;
- respect inventory-full behavior (never show gain for items not actually received).

Reuse the existing HUD/world-message/toast seam if suitable.

## Preserve
- chop-then-gather split already established;
- durability/cost rules if currently active;
- harvested vegetation persistence;
- controller-first use-tool mapping;
- no automatic proximity harvesting.

## Testing
Cover: no axe -> no chop; axe in inventory but not equipped -> no chop; equipped axe -> visible/use event reaches tree; repeated swings fell tree; pickup increments inventory once and displays matching amount; wrong tool refused; save/load harvested state remains correct.

## Definition of done
The player can understand the whole loop without guessing: draw axe -> see axe -> swing axe -> tree reacts/falls -> pick up resource -> see exactly what was gained.