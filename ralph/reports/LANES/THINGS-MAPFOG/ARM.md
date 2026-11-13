# THINGS-MAPFOG: Meadows map, grey fog outside the surveyed circle (F38#4)

**Row.** F38#4 map: 6.99 (`G-closeout-meadows-ui.md`, d3be8b49). Judges: "grey fog over a grid outside the surveyed circle".

**Cause.** The unsurveyed parchment is mottled between two tones, and the Meadows dark tone (`#8c8266`) is a grey olive, so the mottle reads as smoke over the chart.

**Change.** Config only, `map.json fog_veil.cloud_fog.tones.meadows`: `["#8c8266", "#cfc3a0"]` -> `["#bda77a", "#dccfa8"]`. A warm, lower-contrast parchment. Tidewake's tones are not touched. This is a tunable, not a flag; the overlay is the arm.

**CPU** (`_sheet_map_off_vs_on_cpu.jpg`; top main, bottom arm): the unsurveyed area reads as aged map paper; the survey grid, roads and the surveyed circle are unchanged and stand out more.

**Not in this arm.** The small legend.

**Ask.** `phase2_capture_ui.gd --biome=meadows --tabs=map`, base vs arm, High.
