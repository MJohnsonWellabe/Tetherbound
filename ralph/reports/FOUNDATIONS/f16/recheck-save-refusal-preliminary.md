# F16#0 preliminary independent strict re-check

Reviewer: /root/combat, read-only; baseline e2de59571. Current uncommitted foundations diff inspected. No runtime or Godot run performed by reviewer. Verdict: NOT MET, pending implementation repairs and runtime proof.

1. WorldSave version 2 still admits old split worlds. All formats need reset/refusal before live application.
2. Portable-character picker silently skips refused files; Steam join displays generic failure. Preserve typed older-version reason with new-character affordance.
3. Split-half refusal loses its reason; load_slot.last_load_result can remain ok. Propagate typed half failure.
4. slot_info casts party to Array and calls size before a safe refusal path. Malformed old metadata must not crash title listing.
5. Tests do not yet establish old world refusal, split reason propagation, actual title/picker messaging, or refusal -> New Game -> autosave/fallback preservation.

Latest proposed fixes: redesign-v28 save namespaces preserve old roots; version validator now rejects fractional numbers. These changes need runtime proof. Existing migration-through-load assertions must become legitimate RD-35 refusal assertions while retaining current-schema regression coverage. No tests may be removed, disabled or quarantined.

Shortcuts: source/diff inspection only, no title input witness, no two-peer or full-suite evidence. This is a preliminary failure report and closes no criterion.
