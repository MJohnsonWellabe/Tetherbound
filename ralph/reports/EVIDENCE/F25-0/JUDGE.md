# F25#0 code-blind judge, round 2 (coordinator, Sun 11 Oct 2026, 9:14 PM CT)

Input: v2 sheets at 339b0ea37 (systems-b; capture at aaa271a8a), 24 generic archetype sequences.
Method: two independent code-blind judges with 12 sheets each. The names were shuffled (clip-01..24; key withheld) and the judges had no README, code or mapping. PASS = body, trail (N/A for self-targeted) and impact all clearly visible, with no blocking defect.

Verdict: **FAIL, 4 PASS / 7 WEAK / 13 FAIL** (needs about 20 PASS). This is the second failed round (r1: 12/24 at 20d194139), so it is parked under the two-attempt rule and re-scoped (see below).

| archetype | verdict | judge's reason (short) |
|---|---|---|
| shadow_bolt | PASS | readable spiky orb, purple trail, flash and burst plus scorch |
| charge_dash | PASS | solid textured orb, dust spiral, chips and dust ring |
| water_jet | PASS | clear beam to snout, mist, splash burst |
| fireball | PASS | 3D orb, glow streak, flash, burst, scorch |
| stone_throw | WEAK | real stones; trail a faint smear; small contact puff |
| flame_cone | WEAK | strong fire cloud impact; flight is a thin low streak, no head |
| tidal_wave | WEAK | see-through crescent close to a flat ribbon; weak trail |
| quake_ring | WEAK | solid boulder; faint trail; puff reads as a flat disc |
| chain_lightning | WEAK | thin line bolt, little volume |
| sky_lightning | WEAK | strong bolt; impact leans on cartoon speed lines |
| psychic_pulse | WEAK | clear orb; corkscrew floats above, not behind it |
| slash_trail | FAIL | flat fan slabs appear at the target, no travel, a slab through the boar |
| heal_pulse | FAIL | faint flat 2D ribbon at the caster, nothing envelops it |
| wind_blade | FAIL | near-invisible flat slab, no trail |
| tornado | FAIL | ribbon segments drift above the target and miss it |
| ice_shard_volley | FAIL | flat card shards, no trail (contact good) |
| debuff_hex | FAIL | huge bubble spawns swallowing the caster; ribbon in the sky; no impact |
| ember_burst | FAIL | tiny random dots, too faint |
| catch_tether_beam | FAIL | 1–2 px line, no reaction at the target |
| buff_aura | FAIL | flat squares spiral above the head; nothing on the body |
| root_stone_spikes | FAIL | flat grey slabs under the target, no dust or debris |
| bubble_volley | FAIL | far too faint |
| guard_flash | FAIL | sphere floats in front of the face instead of wrapping the caster |
| frost_breath | FAIL | shapeless faint smear |

Patterns: orb and beam bodies with particle trails work. Ribbon, slab and card meshes, thin lines and caster-anchored auras do not.

## effects-claude kit r1 (8:08 AM CT Mon 12 Oct; tb/ev-effects-claude d3f60022): 4 PASS / 17 WEAK / 1 FAIL of 22 judged
Two independent code-blind judges, 11 clips each. Clips 08 and 19 (water_jet and the tether beam on the original renderer) were excluded; the lane is rebuilding them on the kit.
- PASS: 02 (storm bolt with chunks), 06 (rock volley), 09 (fireball), 18 (leaf nature buff).
- FAIL: 07 (fire reads as a stack of identical yellow spheres).
- Shared WEAK causes:
  - one pale grey-white impact dome plus streak cards on most clips, which hides the target's face and doesn't read as the element;
  - recoloured orb projectiles;
  - bare projectiles with no trail;
  - no cast wind-up;
  - earth spikes with no flash that crowd the target;
  - lingering clouds on the target's head;
  - generic self-buffs.
- The lane's self-judge reported 20/24 under a looser prompt. It was given the coordinator's exact bar for its next self-check.
