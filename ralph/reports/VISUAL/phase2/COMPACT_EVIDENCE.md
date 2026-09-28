# Phase 2 compact visual evidence

The current tree retains **2,693 capture records in 126 paginated contact sheets** instead of individual full-resolution pictures. The four biome manifests preserve each frame ID, subject, camera state, source commit, render path, and reproduction command. `catalog.csv` sightings still name those frame IDs; the four `top20.csv` files are unchanged.

In each `manifest.csv` row, `frame_path` names the retained contact-sheet page and `tile_index` identifies its zero-based tile. Pages have four columns and at most 24 tiles. A tile's picture is 320×180 pixels at `x = (tile_index % 4) × 320`, `y = (tile_index // 4) × 215`; the 35 pixels below it contain the truncated ID label. Use the manifest ID for the full label. `source_frame_path` records the removed original path for provenance. `evidence_format` is `contact_sheet_tile_320x180`.

The retained sheets support visual triage and the scored catalog. They do not preserve full-resolution pixels. Recreate an original with its pinned `commit` and `repro` command when a close inspection is needed. `tools/phase2_compact_evidence.py --verify` checks every tile mapping and catalog sighting. The capture indexer refuses to append raw captures into these compact manifests, which prevents silent corruption of the page mapping.

This removes the individual images from the current Git tree. Prior commits still contain them; reducing historical Git storage would require a coordinated repository history rewrite. ZIP files would retain nearly all the bytes because the source pictures were already compressed.
