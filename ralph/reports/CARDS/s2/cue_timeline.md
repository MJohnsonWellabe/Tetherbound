# Stormwood Surge audio witness: cue timeline

Headless, production Stormwood world, real Surge clock and host lightning. `surge_clock_s` is the replicated Surge clock; `t_msec` is `Time.get_ticks_msec()`. `played` is false for every row: no asset exists, so nothing was heard. This proves wiring and timing only.

| # | surge clock s | t_msec | phase | cue | strike | position | asset present | played | caption |
|---|---:|---:|---|---|---:|---|---|---|---|
| 1 | 0.148 | 22424 | calm | `sw_surge_calm_bed` | - | - | false | false | [steady rain in the Stormwood] |
| 2 | 240.009 | 35276 | building | `sw_surge_building_bed` | - | - | false | false | [lightning building] |
| 3 | 330.003 | 47291 | break | `sw_surge_break_bed` | - | - | false | false | [the storm breaks] |
| 4 | 334.370 | 51662 | break | `sw_strike_warning` | 1 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 5 | 335.579 | 52898 | break | `sw_strike_crack` | 1 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 6 | 335.579 | 52899 | break | `sw_strike_body` | 1 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 7 | 335.579 | 52899 | break | `sw_strike_decay` | 1 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 8 | 338.592 | 55904 | break | `sw_strike_warning` | 2 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 9 | 339.793 | 57098 | break | `sw_strike_crack` | 2 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 10 | 339.793 | 57098 | break | `sw_strike_body` | 2 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 11 | 339.793 | 57098 | break | `sw_strike_decay` | 2 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 12 | 345.795 | 63105 | break | `sw_strike_warning` | 3 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 13 | 347.000 | 64292 | break | `sw_strike_crack` | 3 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 14 | 347.000 | 64292 | break | `sw_strike_body` | 3 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 15 | 347.000 | 64292 | break | `sw_strike_decay` | 3 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 16 | 352.732 | 70046 | break | `sw_strike_warning` | 4 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 17 | 353.936 | 71250 | break | `sw_strike_crack` | 4 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 18 | 353.936 | 71250 | break | `sw_strike_body` | 4 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 19 | 353.936 | 71250 | break | `sw_strike_decay` | 4 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 20 | 358.859 | 76153 | break | `sw_strike_warning` | 5 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 21 | 360.064 | 77362 | break | `sw_strike_crack` | 5 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 22 | 360.064 | 77362 | break | `sw_strike_body` | 5 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 23 | 360.064 | 77362 | break | `sw_strike_decay` | 5 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 24 | 364.389 | 81695 | break | `sw_strike_warning` | 6 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 25 | 365.593 | 82880 | break | `sw_strike_crack` | 6 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 26 | 365.593 | 82880 | break | `sw_strike_body` | 6 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 27 | 365.593 | 82880 | break | `sw_strike_decay` | 6 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 28 | 369.432 | 86732 | break | `sw_strike_warning` | 7 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 29 | 370.635 | 87945 | break | `sw_strike_crack` | 7 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 30 | 370.635 | 87946 | break | `sw_strike_body` | 7 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 31 | 370.635 | 87946 | break | `sw_strike_decay` | 7 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 32 | 374.951 | 92250 | break | `sw_strike_warning` | 8 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 33 | 376.154 | 93452 | break | `sw_strike_crack` | 8 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 34 | 376.154 | 93453 | break | `sw_strike_body` | 8 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 35 | 376.154 | 93453 | break | `sw_strike_decay` | 8 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 36 | 380.930 | 98246 | break | `sw_strike_warning` | 9 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 37 | 382.133 | 99436 | break | `sw_strike_crack` | 9 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 38 | 382.133 | 99436 | break | `sw_strike_body` | 9 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 39 | 382.133 | 99436 | break | `sw_strike_decay` | 9 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 40 | 386.309 | 103601 | break | `sw_strike_warning` | 10 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 41 | 387.512 | 104816 | break | `sw_strike_crack` | 10 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 42 | 387.512 | 104816 | break | `sw_strike_body` | 10 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 43 | 387.512 | 104816 | break | `sw_strike_decay` | 10 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 44 | 391.742 | 109049 | break | `sw_strike_warning` | 11 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 45 | 392.947 | 110252 | break | `sw_strike_crack` | 11 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 46 | 392.947 | 110252 | break | `sw_strike_body` | 11 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 47 | 392.947 | 110252 | break | `sw_strike_decay` | 11 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 48 | 396.412 | 113708 | break | `sw_strike_warning` | 12 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 49 | 397.615 | 114926 | break | `sw_strike_crack` | 12 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 50 | 397.615 | 114926 | break | `sw_strike_body` | 12 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 51 | 397.615 | 114926 | break | `sw_strike_decay` | 12 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 52 | 400.941 | 118227 | break | `sw_strike_warning` | 13 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 53 | 402.142 | 119449 | break | `sw_strike_crack` | 13 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 54 | 402.142 | 119449 | break | `sw_strike_body` | 13 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 55 | 402.142 | 119449 | break | `sw_strike_decay` | 13 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 56 | 407.428 | 124748 | break | `sw_strike_warning` | 14 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 57 | 408.630 | 125952 | break | `sw_strike_crack` | 14 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 58 | 408.630 | 125952 | break | `sw_strike_body` | 14 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 59 | 408.630 | 125952 | break | `sw_strike_decay` | 14 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 60 | 411.498 | 128794 | break | `sw_strike_warning` | 15 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 61 | 412.700 | 130000 | break | `sw_strike_crack` | 15 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 62 | 412.700 | 130000 | break | `sw_strike_body` | 15 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 63 | 412.700 | 130000 | break | `sw_strike_decay` | 15 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 64 | 418.741 | 136046 | break | `sw_strike_warning` | 16 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 65 | 419.942 | 137248 | break | `sw_strike_crack` | 16 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 66 | 419.942 | 137248 | break | `sw_strike_body` | 16 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 67 | 419.942 | 137248 | break | `sw_strike_decay` | 16 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 68 | 423.264 | 140573 | break | `sw_strike_warning` | 17 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 69 | 424.477 | 141763 | break | `sw_strike_crack` | 17 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 70 | 424.477 | 141763 | break | `sw_strike_body` | 17 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 71 | 424.477 | 141763 | break | `sw_strike_decay` | 17 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 72 | 428.746 | 146037 | break | `sw_strike_warning` | 18 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 73 | 429.948 | 147253 | break | `sw_strike_crack` | 18 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 74 | 429.948 | 147253 | break | `sw_strike_body` | 18 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 75 | 429.948 | 147253 | break | `sw_strike_decay` | 18 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 76 | 435.778 | 153074 | break | `sw_strike_warning` | 19 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 77 | 436.979 | 154281 | break | `sw_strike_crack` | 19 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 78 | 436.979 | 154281 | break | `sw_strike_body` | 19 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 79 | 436.979 | 154281 | break | `sw_strike_decay` | 19 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 80 | 441.628 | 158920 | break | `sw_strike_warning` | 20 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 81 | 442.835 | 160145 | break | `sw_strike_crack` | 20 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 82 | 442.835 | 160145 | break | `sw_strike_body` | 20 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 83 | 442.835 | 160145 | break | `sw_strike_decay` | 20 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 84 | 446.338 | 163642 | break | `sw_strike_warning` | 21 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 85 | 447.538 | 164830 | break | `sw_strike_crack` | 21 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 86 | 447.538 | 164830 | break | `sw_strike_body` | 21 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 87 | 447.538 | 164830 | break | `sw_strike_decay` | 21 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 88 | 450.006 | 167282 | fading | `sw_surge_fading_decay` | - | - | false | false | [thunder rolling away] |
| 89 | 458.042 | 175425 | aftermath calm | `sw_release_forest_sky_bed` | - | - | false | false | [the storm lifts; ordinary forest sounds] |
