# F17 Crossing Hall: hero-asset handoff to the Codex/Meshy lane

F17#6 code-blind judges (r1, r3) list these gaps as needing art that is not in the build. CLAUDE.md routes new meshes
and Meshy work to Codex. This brief supplies scope and scale. No reference image has been drafted yet: this lane cannot
generate images, so Codex drafts and inspects the references per RD-26.

Scale ruler: the trainer is 1.80 m. All sizes are native metres in the Hall's local frame (`data/config/crossing_hall.json`,
`building_prefabs.json` `crossing_hall_shell`). Keep the installed MegaKit/Quaternius look (warm plaster, dark timber,
terracotta round tiles, uneven stone) and no oxblood.

1. **Portal arch (×8, one mesh, per-biome emblem and state materials).** It replaces `Wall_Arch` plus the flat
   `PortalSurface`. Opening ≥2.4 m wide and ≥3.6 m tall (the current 2 × 3 m is ~1.5× the trainer and reads as a doorway);
   overall ≤3.2 m wide so it fits the 6 m arch bays at local x = ±5.9, z = −9/−3/3/9, and the home arch at z = −12.8.
   Needs a carved keystone emblem slot per biome (Meadows, Tidewake, Cloudreach, Stormwood, plus four reserved), a single
   carved plaque for the biome name (replacing the two Label3D lines), and three states: open (emissive membrane), locked
   (unlit membrane), sealed (stone infill, dark but visible).
2. **Shrine pedestal (×8).** A stone plinth ~1.1 m tall on a ~0.8 m square base, with a relic cradle on top and a carved
   name band. Placed at local x = 9.2/14.8, z = −4.5/−1.5/1.5/4.5. Empty and relic-displayed variants.
3. **Civic stone frontage set (optional, if the kit cannot deliver stone mass).** Stone gable and buttress pieces at
   MegaKit module scale (2 m wide × 3.12 m per storey) so the Hall reads as stone against the timber houses.

Provenance, task IDs, scale check and the before/after code-blind judgement are Codex's under RD-26. Integration stays
flag-off on failure. Current geometry for comparison: `../visual-bar-r3/frames/nave-*`, `shrine-*`, `hall-approach_*`.
