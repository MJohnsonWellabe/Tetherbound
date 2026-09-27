# Stormwood Surge audio witness: cue timeline

Headless, production Stormwood world, real Surge clock and host lightning. `surge_clock_s` is the replicated Surge clock; `t_msec` is `Time.get_ticks_msec()`. `played` is false for every row: no asset exists, so nothing was heard. This proves wiring and timing only.

| # | surge clock s | t_msec | phase | cue | strike | position | asset present | played | caption |
|---|---:|---:|---|---|---:|---|---|---|---|
| 1 | 0.125 | 115689 | calm | `sw_surge_calm_bed` | - | - | false | false | [steady rain in the Stormwood] |
| 2 | 240.006 | 129033 | building | `sw_surge_building_bed` | - | - | false | false | [lightning building] |
| 3 | 330.001 | 141016 | break | `sw_surge_break_bed` | - | - | false | false | [the storm breaks] |
| 4 | 332.541 | 143574 | break | `sw_strike_warning` | 1 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 5 | 333.746 | 144789 | break | `sw_strike_crack` | 1 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 6 | 333.746 | 144789 | break | `sw_strike_body` | 1 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 7 | 333.746 | 144789 | break | `sw_strike_decay` | 1 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 8 | 337.881 | 148911 | break | `sw_strike_warning` | 2 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 9 | 339.081 | 150111 | break | `sw_strike_crack` | 2 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 10 | 339.081 | 150111 | break | `sw_strike_body` | 2 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 11 | 339.081 | 150112 | break | `sw_strike_decay` | 2 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 12 | 345.568 | 156599 | break | `sw_strike_warning` | 3 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 13 | 346.771 | 157804 | break | `sw_strike_crack` | 3 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 14 | 346.771 | 157804 | break | `sw_strike_body` | 3 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 15 | 346.771 | 157804 | break | `sw_strike_decay` | 3 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 16 | 352.232 | 163269 | break | `sw_strike_warning` | 4 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 17 | 353.432 | 164474 | break | `sw_strike_crack` | 4 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 18 | 353.432 | 164474 | break | `sw_strike_body` | 4 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 19 | 353.432 | 164474 | break | `sw_strike_decay` | 4 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 20 | 357.119 | 168154 | break | `sw_strike_warning` | 5 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 21 | 358.320 | 169362 | break | `sw_strike_crack` | 5 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 22 | 358.320 | 169362 | break | `sw_strike_body` | 5 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 23 | 358.320 | 169362 | break | `sw_strike_decay` | 5 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 24 | 362.449 | 173491 | break | `sw_strike_warning` | 6 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 25 | 363.657 | 174701 | break | `sw_strike_crack` | 6 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 26 | 363.657 | 174701 | break | `sw_strike_body` | 6 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 27 | 363.657 | 174701 | break | `sw_strike_decay` | 6 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 28 | 368.045 | 179082 | break | `sw_strike_warning` | 7 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 29 | 369.247 | 180299 | break | `sw_strike_crack` | 7 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 30 | 369.247 | 180299 | break | `sw_strike_body` | 7 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 31 | 369.247 | 180299 | break | `sw_strike_decay` | 7 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 32 | 374.295 | 185340 | break | `sw_strike_warning` | 8 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 33 | 375.498 | 186529 | break | `sw_strike_crack` | 8 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 34 | 375.498 | 186529 | break | `sw_strike_body` | 8 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 35 | 375.498 | 186529 | break | `sw_strike_decay` | 8 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 36 | 380.925 | 191966 | break | `sw_strike_warning` | 9 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 37 | 382.125 | 193154 | break | `sw_strike_crack` | 9 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 38 | 382.125 | 193154 | break | `sw_strike_body` | 9 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 39 | 382.125 | 193154 | break | `sw_strike_decay` | 9 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 40 | 387.961 | 198992 | break | `sw_strike_warning` | 10 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 41 | 389.163 | 200199 | break | `sw_strike_crack` | 10 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 42 | 389.163 | 200199 | break | `sw_strike_body` | 10 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 43 | 389.163 | 200199 | break | `sw_strike_decay` | 10 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 44 | 393.441 | 204485 | break | `sw_strike_warning` | 11 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 45 | 394.642 | 205682 | break | `sw_strike_crack` | 11 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 46 | 394.642 | 205682 | break | `sw_strike_body` | 11 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 47 | 394.642 | 205682 | break | `sw_strike_decay` | 11 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 48 | 397.881 | 208915 | break | `sw_strike_warning` | 12 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 49 | 399.083 | 210108 | break | `sw_strike_crack` | 12 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 50 | 399.083 | 210108 | break | `sw_strike_body` | 12 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 51 | 399.083 | 210108 | break | `sw_strike_decay` | 12 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 52 | 404.236 | 215282 | break | `sw_strike_warning` | 13 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 53 | 405.445 | 216477 | break | `sw_strike_crack` | 13 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 54 | 405.445 | 216477 | break | `sw_strike_body` | 13 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 55 | 405.445 | 216478 | break | `sw_strike_decay` | 13 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 56 | 409.635 | 220678 | break | `sw_strike_warning` | 14 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 57 | 410.837 | 221863 | break | `sw_strike_crack` | 14 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 58 | 410.837 | 221863 | break | `sw_strike_body` | 14 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 59 | 410.837 | 221863 | break | `sw_strike_decay` | 14 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 60 | 415.162 | 226195 | break | `sw_strike_warning` | 15 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 61 | 416.368 | 227407 | break | `sw_strike_crack` | 15 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 62 | 416.368 | 227407 | break | `sw_strike_body` | 15 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 63 | 416.368 | 227407 | break | `sw_strike_decay` | 15 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 64 | 421.506 | 232553 | break | `sw_strike_warning` | 16 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 65 | 422.707 | 233732 | break | `sw_strike_crack` | 16 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 66 | 422.707 | 233732 | break | `sw_strike_body` | 16 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 67 | 422.707 | 233732 | break | `sw_strike_decay` | 16 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 68 | 428.571 | 239599 | break | `sw_strike_warning` | 17 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 69 | 429.782 | 240813 | break | `sw_strike_crack` | 17 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 70 | 429.782 | 240813 | break | `sw_strike_body` | 17 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 71 | 429.782 | 240813 | break | `sw_strike_decay` | 17 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 72 | 433.106 | 244155 | break | `sw_strike_warning` | 18 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 73 | 434.314 | 245352 | break | `sw_strike_crack` | 18 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 74 | 434.314 | 245352 | break | `sw_strike_body` | 18 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 75 | 434.314 | 245352 | break | `sw_strike_decay` | 18 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 76 | 437.374 | 248401 | break | `sw_strike_warning` | 19 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 77 | 438.585 | 249645 | break | `sw_strike_crack` | 19 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 78 | 438.585 | 249645 | break | `sw_strike_body` | 19 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 79 | 438.585 | 249645 | break | `sw_strike_decay` | 19 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 80 | 442.080 | 253109 | break | `sw_strike_warning` | 20 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 81 | 443.284 | 254339 | break | `sw_strike_crack` | 20 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 82 | 443.284 | 254339 | break | `sw_strike_body` | 20 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 83 | 443.284 | 254339 | break | `sw_strike_decay` | 20 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 84 | 447.179 | 258217 | break | `sw_strike_warning` | 21 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 85 | 448.386 | 259429 | break | `sw_strike_crack` | 21 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 86 | 448.386 | 259429 | break | `sw_strike_body` | 21 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 87 | 448.386 | 259430 | break | `sw_strike_decay` | 21 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 88 | 450.001 | 261016 | fading | `sw_surge_fading_decay` | - | - | false | false | [thunder rolling away] |
| 89 | 458.019 | 269062 | aftermath calm | `sw_release_forest_sky_bed` | - | - | false | false | [the storm lifts; ordinary forest sounds] |
