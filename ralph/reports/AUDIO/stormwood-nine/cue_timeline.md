# Stormwood Surge audio witness: cue timeline

Headless, production Stormwood world, real Surge clock and host lightning. `surge_clock_s` is the replicated Surge clock; `t_msec` is `Time.get_ticks_msec()`. `played` means the cue's asset loaded and a pool player started it; what it sounds like is judged offline by tools/audio/check_stormwood.py.

| # | surge clock s | t_msec | phase | cue | strike | position | asset present | played | caption |
|---|---:|---:|---|---|---:|---|---|---|---|
| 1 | 0.119 | 74682 | calm | `sw_surge_calm_bed` | - | - | true | true | [steady rain in the Stormwood] |
| 2 | 240.009 | 92671 | building | `sw_surge_building_bed` | - | - | true | true | [lightning building] |
| 3 | 330.010 | 104674 | break | `sw_surge_break_bed` | - | - | true | true | [the storm breaks] |
| 4 | 331.562 | 106240 | break | `sw_strike_warning` | 1 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 5 | 332.777 | 107462 | break | `sw_strike_crack` | 1 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 6 | 332.777 | 107462 | break | `sw_strike_body` | 1 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 7 | 332.777 | 107462 | break | `sw_strike_decay` | 1 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 8 | 337.690 | 112368 | break | `sw_strike_warning` | 2 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 9 | 338.890 | 113582 | break | `sw_strike_crack` | 2 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 10 | 338.890 | 113582 | break | `sw_strike_body` | 2 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 11 | 338.890 | 113582 | break | `sw_strike_decay` | 2 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 12 | 342.433 | 117109 | break | `sw_strike_warning` | 3 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 13 | 343.635 | 118320 | break | `sw_strike_crack` | 3 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 14 | 343.635 | 118320 | break | `sw_strike_body` | 3 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 15 | 343.635 | 118320 | break | `sw_strike_decay` | 3 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 16 | 349.533 | 124221 | break | `sw_strike_warning` | 4 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 17 | 350.735 | 125440 | break | `sw_strike_crack` | 4 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 18 | 350.735 | 125440 | break | `sw_strike_body` | 4 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 19 | 350.735 | 125440 | break | `sw_strike_decay` | 4 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 20 | 356.467 | 131156 | break | `sw_strike_warning` | 5 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 21 | 357.688 | 132377 | break | `sw_strike_crack` | 5 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 22 | 357.688 | 132377 | break | `sw_strike_body` | 5 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 23 | 357.688 | 132377 | break | `sw_strike_decay` | 5 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 24 | 360.977 | 135663 | break | `sw_strike_warning` | 6 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 25 | 362.182 | 136874 | break | `sw_strike_crack` | 6 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 26 | 362.182 | 136874 | break | `sw_strike_body` | 6 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 27 | 362.182 | 136874 | break | `sw_strike_decay` | 6 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 28 | 367.987 | 142662 | break | `sw_strike_warning` | 7 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 29 | 369.198 | 143881 | break | `sw_strike_crack` | 7 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 30 | 369.198 | 143881 | break | `sw_strike_body` | 7 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 31 | 369.198 | 143881 | break | `sw_strike_decay` | 7 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 32 | 374.319 | 149003 | break | `sw_strike_warning` | 8 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 33 | 375.523 | 150198 | break | `sw_strike_crack` | 8 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 34 | 375.523 | 150198 | break | `sw_strike_body` | 8 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 35 | 375.523 | 150198 | break | `sw_strike_decay` | 8 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 36 | 379.761 | 154450 | break | `sw_strike_warning` | 9 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 37 | 380.976 | 155654 | break | `sw_strike_crack` | 9 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 38 | 380.976 | 155654 | break | `sw_strike_body` | 9 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 39 | 380.976 | 155654 | break | `sw_strike_decay` | 9 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 40 | 384.814 | 159489 | break | `sw_strike_warning` | 10 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 41 | 386.022 | 160721 | break | `sw_strike_crack` | 10 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 42 | 386.022 | 160721 | break | `sw_strike_body` | 10 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 43 | 386.022 | 160721 | break | `sw_strike_decay` | 10 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 44 | 389.930 | 164615 | break | `sw_strike_warning` | 11 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 45 | 391.139 | 165833 | break | `sw_strike_crack` | 11 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 46 | 391.139 | 165833 | break | `sw_strike_body` | 11 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 47 | 391.139 | 165833 | break | `sw_strike_decay` | 11 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 48 | 396.810 | 171487 | break | `sw_strike_warning` | 12 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 49 | 398.023 | 172715 | break | `sw_strike_crack` | 12 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 50 | 398.023 | 172715 | break | `sw_strike_body` | 12 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 51 | 398.023 | 172715 | break | `sw_strike_decay` | 12 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 52 | 404.249 | 178937 | break | `sw_strike_warning` | 13 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 53 | 405.458 | 180145 | break | `sw_strike_crack` | 13 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 54 | 405.458 | 180145 | break | `sw_strike_body` | 13 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 55 | 405.458 | 180145 | break | `sw_strike_decay` | 13 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 56 | 410.260 | 184945 | break | `sw_strike_warning` | 14 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 57 | 411.475 | 186157 | break | `sw_strike_crack` | 14 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 58 | 411.475 | 186157 | break | `sw_strike_body` | 14 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 59 | 411.475 | 186157 | break | `sw_strike_decay` | 14 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 60 | 418.190 | 192863 | break | `sw_strike_warning` | 15 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 61 | 419.401 | 194082 | break | `sw_strike_crack` | 15 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 62 | 419.401 | 194083 | break | `sw_strike_body` | 15 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 63 | 419.401 | 194083 | break | `sw_strike_decay` | 15 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 64 | 424.322 | 199003 | break | `sw_strike_warning` | 16 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 65 | 425.524 | 200213 | break | `sw_strike_crack` | 16 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 66 | 425.524 | 200213 | break | `sw_strike_body` | 16 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 67 | 425.524 | 200213 | break | `sw_strike_decay` | 16 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 68 | 429.457 | 204151 | break | `sw_strike_warning` | 17 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 69 | 430.664 | 205354 | break | `sw_strike_crack` | 17 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 70 | 430.664 | 205354 | break | `sw_strike_body` | 17 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 71 | 430.664 | 205354 | break | `sw_strike_decay` | 17 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 72 | 437.162 | 211852 | break | `sw_strike_warning` | 18 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 73 | 438.373 | 213046 | break | `sw_strike_crack` | 18 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 74 | 438.373 | 213046 | break | `sw_strike_body` | 18 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 75 | 438.373 | 213047 | break | `sw_strike_decay` | 18 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 76 | 443.428 | 218120 | break | `sw_strike_warning` | 19 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 77 | 444.630 | 219323 | break | `sw_strike_crack` | 19 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 78 | 444.630 | 219323 | break | `sw_strike_body` | 19 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 79 | 444.630 | 219323 | break | `sw_strike_decay` | 19 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 80 | 449.981 | 224666 | break | `sw_strike_warning` | 20 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 81 | 450.008 | 224688 | fading | `sw_surge_fading_decay` | - | - | true | true | [thunder rolling away] |
| 82 | 451.199 | 225891 | fading | `sw_strike_crack` | 20 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 83 | 451.199 | 225891 | fading | `sw_strike_body` | 20 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 84 | 451.199 | 225891 | fading | `sw_strike_decay` | 20 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 85 | 458.024 | 232697 | aftermath calm | `sw_release_forest_sky_bed` | - | - | true | true | [the storm lifts; ordinary forest sounds] |
