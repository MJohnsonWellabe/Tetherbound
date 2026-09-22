# CB-09 acceptance clarification

Canonical `docs/acceptance/GATE_F_MASTER_PROTOCOL.md:498` requires CB-09 in
X04 and at least one journey fight: physical `party_cycle` (LB) mid-combat
while taking hits, verifying pilot handoff, camera handoff, and no input loss.
T06 at line 1375 requires combat input throughout the switch, camera handoff
without losing the opponent, and coherent HP/cooldown states.

Neither requirement calls for reverse cycling or returning to the original
pilot. The protocol's “both directions” at line 558 describes build rotation.
The earlier S04-51 combat wording added a requirement absent from CB-09.
S04-51 and its generated capture twin now identify the two observed forward
handoffs accurately. No choreography, assertions, waits, or frame debts changed.

Production exposes one controller cycling direction: `project.godot:281`
binds `party_cycle` to LB (joypad button 9) and keyboard C;
`scripts/ui/combat_hud.gd:987` invokes `cycle_active(1)` behind `can_switch()`.
The manager's reverse/direct-selection APIs are not additional controller
bindings. Its switch lockout remains 1.5 seconds (`data/config/combat.json:217`).

The separately integrated charged-hit driver preserves the physical long
press: it supplies integer 60 to `_charged_physical_press`, which passes that
integer unchanged into `_inject`. Injection holds the mapped button through
60 physics waits, with process-frame visibility on both input edges and one
additional release physics wait. Its success is a production charged-hit
signal, not merely a successful injection.

Validation: capture generator `--check` passes. These acceptance wording edits
do not change executable behavior; no engine run was performed for this note.
