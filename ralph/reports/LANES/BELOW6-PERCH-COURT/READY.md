STATUS: land

Bug fix: High Perches court apron seated clear of the crown turf (`landing_apron_top_m: 0.22`). CPU-proven; GPU confirmation of one High Perches piece still wanted.
Files: `scripts/world/cloudreach_high_perches_presentation.gd`, `data/config/cloudreach_high_perches_visual.json`, `tests/test_high_perches_apron_clears_turf.gd`, this report folder. Nothing else from tb/below6.
Checks: `--only=high_perches` passes.
