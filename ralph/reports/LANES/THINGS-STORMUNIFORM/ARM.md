# THINGS-STORMUNIFORM: Stormwood officers pale lilac-grey in the world (F41#18)

**Row.** F41#18 (6.22 after STORMRIM). `G-things-stormrim.md`, 3/3: "the officers render pale lilac-grey and ghostly in the world, while their portraits are near-black. Darken the in-world uniforms to match the portraits."

**Cause.** `stormwood_character_presentation.json` gives every Stormwood uniform an additive emission floor of 0.18 (civilians 0.12). It was added for dark nights; under Stormwood's bright ambient it lifts the near-black cloth to grey-lilac.

**Change.** Config only: both floors to 0.0. Marrow already runs at 0.0 (`identity_floor_1112`, landed). No code.

**CPU** (`_sheet_floor_on_vs_off_cpu.jpg`, Nysa's post, both with the STORMRIM rim fix; left floor 0.18, right 0.0): the coat goes from grey-lilac to near-black with the purple chevron still readable, matching the portrait; face unchanged.

**Risk.** The floor was the officers' separation from dark forest. Check the F41#18 world frames (Dace, Varga, Sable against the road and trees), not only dialogue. The rank trim the judges also asked for is not in this arm.

**Expected.** +0.5 on F41#18 (named 3/3 as the next lever), ride-along gain on the Stormwood dialogue rows.

**Ask.** Base = tb/things with `THINGS-STORMRIM/overlay_player_rim_off.json` (or main once the rim landing is in); arm = base plus this overlay. F41#18 row frames and the Stormwood dialogue set, High.
