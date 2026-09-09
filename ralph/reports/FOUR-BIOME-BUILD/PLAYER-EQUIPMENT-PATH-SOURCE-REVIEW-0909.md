# Equipment player path — independent source review

Reviewed frozen state/save implementation e8402cf41 and the subsequent current `tab_backpack.gd` explicit controller links, without engine execution or source edits. This is source review, not UI visual or multiplayer acceptance.

No concrete transaction, ownership or migration blocker found. The trial Inventory copies stack dictionaries, checks capacity after removing the incoming piece, and the actual Inventory operations are synchronous with no callbacks/awaits. Under the actual fixed-size Inventory contract, failed swaps leave bag and equipment unchanged; successful swaps conserve the displaced item. Loading resets every worn slot before accepting only known armor in its authored slot.

Equipment is serialized as portable PlayerState/CharacterSave state, excluded from WorldSave, and added to flat SaveGame snapshots. Flat23→24 explicitly advances migration and provides empty legacy equipment. Character v1 remains readable and missing equipment clears previous state. The version bumps cause older readers to refuse the newer format; they do not establish that an older executable's existing missing/corrupt-character fallback can never later overwrite such a file.

The initial controller smoke directly focused a worn button and therefore did not establish real navigation reachability. The updated UI explicitly links the five worn rows up/down and bag-edge left/right, avoiding reliance on spatial auto-neighbors; it also suppresses the stale bag outline and refreshes preview/detail from the worn selection. Root reports the expanded actual-pad26-check smoke covers this path without directly focusing worn controls. That result was not independently rerun here.

Remaining acceptance: root's planned peer/reset/corruption scenarios and final UI render review. No commercial UI acceptance or shipping-ready claim follows from this source clearance.
