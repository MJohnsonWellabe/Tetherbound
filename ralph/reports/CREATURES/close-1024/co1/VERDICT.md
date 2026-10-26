# CLOSE-OUT co1: shared rim + faint settle (CPU checks, 26 Oct)

Owner close-out direction (25 Oct, via the coordinator): fix the near-bar creatures' shared defects once for every species. Candidate da816e00 (rim + faint settle) and c6941e68 (Tanglevolt arcs) on tb/creatures-land.

**Why there is no CPU judge batch:** none of the three changes can show on the CPU stage, so a CPU batch could only score noise.
- **Rim:** llvmpipe does not render the BaseMaterial3D rim term, as earlier rim rounds also found. Per-pixel mean abs diff vs base at hit-000 is 0.02-0.30 (8-bit) across 11 species.
- **Arcs:** the CPU stage self-lights the whole albedo, so emission does not show (runbook §8.1).
- **Faint settle:** lower-only, and it does not fire on any captured species (all end at or below the floor).

Pixel diffs, base vs candidate (riverdrake, torrentoad, burrowback, mosshell, mirejaw, brooktail, tanglevolt, galecrest, stormursa, stormcapra, mangrove_monitor): hit-000 and faint-050 are all ≤ 0.30. With the lower-only rule, faint-100 is unchanged.

**Rejected on CPU, before this candidate:**
1. **A generic roll for upright faints.** The rule was: a body taller than 0.6 of standing height rolls 80° onto its side. It rolled correct sideways faints belly-up or legs-up: Riverdrake, Burrowback, Torrentoad (its splayed legs are 5.3 m wide against 3.1 m tall), Brooktail and Stormursa (`_sheet_co1_roll_rejected.jpg`; left = base, right = roll). A bounding-box height test cannot tell an upright faint from a sideways one with raised legs or a wide body.
2. **Two-way grounding.** It lifted the slightly sunk faint ends of Mosshell, Burrowback, Mirejaw and Galecrest out of the floor: legs showed, and they read as standing. Kept lower-only.

**Not fixed by a shared rule; stays per-species recipe work:**
- upright faints: Torrentoad;
- seated coil: Riverdrake;
- belly-up slab: Tanglevolt;
- Mosshell, Brooktail, Burrowback faint reads.

Checks: focused tests (faint, rest, creature_body, pose, f36, flinch, hit_flash, companion_presence, field/rim/alpha/tier, remote/wild creature, knockout, texture_import, colourways, arc, emission, night): 346 tests, 0 failed. Texture policy PASS (934). Tanglevolt imports with emission_energy_multiplier 3.0.
