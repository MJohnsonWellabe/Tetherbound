# D20 — Evolved forms are not wild: Tuskroot is earned, not encountered

**Status:** accepted, by the owner
**Decided:** with the data-driven wild spawn table (`data/config/spawns.json`)

## The decision

**Tuskroot does not spawn in the wild.** It is the evolved form of Mudsnout —
the biome's one evolution, per D13 — and the only way to own one is to catch a
Mudsnout and evolve it. Mudsnout spawns; Tuskroot never does.

The rule generalises and the test enforces the general form: **no species with
an `evolves_from` appears in the spawn table**
(`tests/test_spawns_data.gd::test_no_evolved_form_spawns_wild`).

## Why

An evolution you can walk up to and catch directly makes evolving pointless —
the payoff of raising a Mudsnout would be available for one orb. Keeping the
evolved form out of the wild population is what gives the evolution system
(still unbuilt; the data links are D13/D17's) something to be worth building.

## Consequences

- The **aggressor role** in `spawns.json` passed from Tuskroot to **Galecrest**,
  the wild roster's other aggressive species. `encounter_director.aggressive_pal()`
  and the smoke tests resolve the role from data, so the handover was a data
  edit.
- **Veridian** is also absent from the table — the future legendary is a
  set-piece, not part of the ambient population.
