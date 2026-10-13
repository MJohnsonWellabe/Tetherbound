# Stormwood Surge audio witness: cue timeline

Headless, production Stormwood world, real Surge clock and host lightning. `surge_clock_s` is the replicated Surge clock; `t_msec` is `Time.get_ticks_msec()`. `played` means the cue's asset loaded and a pool player started it; what it sounds like is judged offline by tools/audio/check_stormwood.py.

| # | surge clock s | t_msec | phase | cue | strike | position | asset present | played | caption |
|---|---:|---:|---|---|---:|---|---|---|---|
| 1 | 0.118 | 103442 | calm | `sw_surge_calm_bed` | - | - | true | true | [steady rain in the Stormwood] |
| 2 | 240.003 | 117627 | building | `sw_surge_building_bed` | - | - | true | true | [lightning building] |
| 3 | 330.011 | 129634 | break | `sw_surge_break_bed` | - | - | true | true | [the storm breaks] |
| 4 | 332.092 | 131734 | break | `sw_strike_warning` | 1 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 5 | 333.299 | 132950 | break | `sw_strike_crack` | 1 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 6 | 333.299 | 132950 | break | `sw_strike_body` | 1 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 7 | 333.299 | 132950 | break | `sw_strike_decay` | 1 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 8 | 336.955 | 136606 | break | `sw_strike_warning` | 2 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 9 | 338.164 | 137824 | break | `sw_strike_crack` | 2 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 10 | 338.164 | 137824 | break | `sw_strike_body` | 2 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 11 | 338.164 | 137824 | break | `sw_strike_decay` | 2 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 12 | 341.972 | 141644 | break | `sw_strike_warning` | 3 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 13 | 343.175 | 142828 | break | `sw_strike_crack` | 3 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 14 | 343.175 | 142829 | break | `sw_strike_body` | 3 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 15 | 343.175 | 142829 | break | `sw_strike_decay` | 3 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 16 | 349.309 | 149001 | break | `sw_strike_warning` | 4 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 17 | 350.563 | 150262 | break | `sw_strike_crack` | 4 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 18 | 350.563 | 150262 | break | `sw_strike_body` | 4 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 19 | 350.563 | 150262 | break | `sw_strike_decay` | 4 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 20 | 354.315 | 154018 | break | `sw_strike_warning` | 5 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 21 | 355.516 | 155208 | break | `sw_strike_crack` | 5 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 22 | 355.516 | 155208 | break | `sw_strike_body` | 5 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 23 | 355.516 | 155208 | break | `sw_strike_decay` | 5 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 24 | 358.721 | 158448 | break | `sw_strike_warning` | 6 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 25 | 359.936 | 159664 | break | `sw_strike_crack` | 6 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 26 | 359.936 | 159664 | break | `sw_strike_body` | 6 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 27 | 359.936 | 159664 | break | `sw_strike_decay` | 6 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 28 | 362.820 | 162539 | break | `sw_strike_warning` | 7 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 29 | 364.023 | 163727 | break | `sw_strike_crack` | 7 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 30 | 364.023 | 163727 | break | `sw_strike_body` | 7 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 31 | 364.023 | 163727 | break | `sw_strike_decay` | 7 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 32 | 367.458 | 167180 | break | `sw_strike_warning` | 8 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 33 | 368.679 | 168410 | break | `sw_strike_crack` | 8 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 34 | 368.679 | 168410 | break | `sw_strike_body` | 8 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 35 | 368.679 | 168410 | break | `sw_strike_decay` | 8 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 36 | 374.089 | 173820 | break | `sw_strike_warning` | 9 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 37 | 375.292 | 175013 | break | `sw_strike_crack` | 9 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 38 | 375.292 | 175013 | break | `sw_strike_body` | 9 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 39 | 375.292 | 175013 | break | `sw_strike_decay` | 9 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 40 | 378.935 | 178754 | break | `sw_strike_warning` | 10 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 41 | 380.146 | 179977 | break | `sw_strike_crack` | 10 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 42 | 380.146 | 179977 | break | `sw_strike_body` | 10 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 43 | 380.146 | 179977 | break | `sw_strike_decay` | 10 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 44 | 386.898 | 186750 | break | `sw_strike_warning` | 11 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 45 | 388.100 | 187941 | break | `sw_strike_crack` | 11 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 46 | 388.100 | 187941 | break | `sw_strike_body` | 11 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 47 | 388.100 | 187941 | break | `sw_strike_decay` | 11 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 48 | 394.581 | 194434 | break | `sw_strike_warning` | 12 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 49 | 395.790 | 195633 | break | `sw_strike_crack` | 12 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 50 | 395.790 | 195633 | break | `sw_strike_body` | 12 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 51 | 395.790 | 195633 | break | `sw_strike_decay` | 12 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 52 | 400.823 | 200709 | break | `sw_strike_warning` | 13 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 53 | 402.032 | 201915 | break | `sw_strike_crack` | 13 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 54 | 402.032 | 201915 | break | `sw_strike_body` | 13 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 55 | 402.032 | 201915 | break | `sw_strike_decay` | 13 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 56 | 406.441 | 206318 | break | `sw_strike_warning` | 14 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 57 | 407.651 | 207537 | break | `sw_strike_crack` | 14 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 58 | 407.651 | 207537 | break | `sw_strike_body` | 14 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 59 | 407.651 | 207537 | break | `sw_strike_decay` | 14 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 60 | 412.225 | 212133 | break | `sw_strike_warning` | 15 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 61 | 413.434 | 213320 | break | `sw_strike_crack` | 15 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 62 | 413.434 | 213320 | break | `sw_strike_body` | 15 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 63 | 413.434 | 213320 | break | `sw_strike_decay` | 15 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 64 | 416.717 | 216617 | break | `sw_strike_warning` | 16 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 65 | 417.919 | 217836 | break | `sw_strike_crack` | 16 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 66 | 417.919 | 217836 | break | `sw_strike_body` | 16 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 67 | 417.919 | 217836 | break | `sw_strike_decay` | 16 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 68 | 421.515 | 221436 | break | `sw_strike_warning` | 17 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 69 | 422.720 | 222630 | break | `sw_strike_crack` | 17 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 70 | 422.720 | 222630 | break | `sw_strike_body` | 17 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 71 | 422.720 | 222630 | break | `sw_strike_decay` | 17 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 72 | 429.032 | 228965 | break | `sw_strike_warning` | 18 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 73 | 430.241 | 230161 | break | `sw_strike_crack` | 18 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 74 | 430.241 | 230161 | break | `sw_strike_body` | 18 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 75 | 430.241 | 230161 | break | `sw_strike_decay` | 18 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 76 | 436.832 | 236756 | break | `sw_strike_warning` | 19 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 77 | 438.036 | 238008 | break | `sw_strike_crack` | 19 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 78 | 438.036 | 238008 | break | `sw_strike_body` | 19 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 79 | 438.036 | 238008 | break | `sw_strike_decay` | 19 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 80 | 441.245 | 241216 | break | `sw_strike_warning` | 20 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 81 | 442.454 | 242421 | break | `sw_strike_crack` | 20 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 82 | 442.454 | 242421 | break | `sw_strike_body` | 20 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 83 | 442.454 | 242421 | break | `sw_strike_decay` | 20 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 84 | 447.938 | 247966 | break | `sw_strike_warning` | 21 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 85 | 449.148 | 249166 | break | `sw_strike_crack` | 21 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 86 | 449.148 | 249166 | break | `sw_strike_body` | 21 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 87 | 449.148 | 249167 | break | `sw_strike_decay` | 21 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 88 | 450.001 | 250003 | fading | `sw_surge_fading_decay` | - | - | true | true | [thunder rolling away] |
| 89 | 458.025 | 258104 | aftermath calm | `sw_release_forest_sky_bed` | - | - | true | true | [the storm lifts; ordinary forest sounds] |
