# Stormwood Surge audio witness: cue timeline

Headless, production Stormwood world, real Surge clock and host lightning. `surge_clock_s` is the replicated Surge clock; `t_msec` is `Time.get_ticks_msec()`. `played` is false for every row: no asset exists, so nothing was heard. This proves wiring and timing only.

| # | surge clock s | t_msec | phase | cue | strike | position | asset present | played | caption |
|---|---:|---:|---|---|---:|---|---|---|---|
| 1 | 0.120 | 45594 | calm | `sw_surge_calm_bed` | - | - | false | false | [steady rain in the Stormwood] |
| 2 | 240.006 | 59729 | building | `sw_surge_building_bed` | - | - | false | false | [lightning building] |
| 3 | 330.003 | 71728 | break | `sw_surge_break_bed` | - | - | false | false | [the storm breaks] |
| 4 | 337.266 | 79004 | break | `sw_strike_warning` | 1 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 5 | 338.470 | 80199 | break | `sw_strike_crack` | 1 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 6 | 338.470 | 80199 | break | `sw_strike_body` | 1 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 7 | 338.470 | 80199 | break | `sw_strike_decay` | 1 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 8 | 343.102 | 84831 | break | `sw_strike_warning` | 2 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 9 | 344.308 | 86038 | break | `sw_strike_crack` | 2 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 10 | 344.308 | 86038 | break | `sw_strike_body` | 2 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 11 | 344.308 | 86038 | break | `sw_strike_decay` | 2 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 12 | 351.070 | 92792 | break | `sw_strike_warning` | 3 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 13 | 352.272 | 93992 | break | `sw_strike_crack` | 3 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 14 | 352.272 | 93993 | break | `sw_strike_body` | 3 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 15 | 352.272 | 93993 | break | `sw_strike_decay` | 3 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 16 | 356.077 | 97804 | break | `sw_strike_warning` | 4 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 17 | 357.279 | 99007 | break | `sw_strike_crack` | 4 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 18 | 357.279 | 99007 | break | `sw_strike_body` | 4 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 19 | 357.279 | 99007 | break | `sw_strike_decay` | 4 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 20 | 362.904 | 104628 | break | `sw_strike_warning` | 5 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 21 | 364.105 | 105831 | break | `sw_strike_crack` | 5 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 22 | 364.105 | 105831 | break | `sw_strike_body` | 5 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 23 | 364.105 | 105831 | break | `sw_strike_decay` | 5 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 24 | 369.036 | 110757 | break | `sw_strike_warning` | 6 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 25 | 370.237 | 111975 | break | `sw_strike_crack` | 6 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 26 | 370.237 | 111975 | break | `sw_strike_body` | 6 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 27 | 370.237 | 111975 | break | `sw_strike_decay` | 6 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 28 | 375.396 | 117129 | break | `sw_strike_warning` | 7 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 29 | 376.597 | 118320 | break | `sw_strike_crack` | 7 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 30 | 376.597 | 118320 | break | `sw_strike_body` | 7 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 31 | 376.597 | 118320 | break | `sw_strike_decay` | 7 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 32 | 381.222 | 122944 | break | `sw_strike_warning` | 8 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 33 | 382.424 | 124139 | break | `sw_strike_crack` | 8 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 34 | 382.424 | 124139 | break | `sw_strike_body` | 8 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 35 | 382.424 | 124139 | break | `sw_strike_decay` | 8 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 36 | 386.560 | 128294 | break | `sw_strike_warning` | 9 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 37 | 387.762 | 129484 | break | `sw_strike_crack` | 9 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 38 | 387.762 | 129484 | break | `sw_strike_body` | 9 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 39 | 387.762 | 129485 | break | `sw_strike_decay` | 9 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 40 | 394.241 | 135963 | break | `sw_strike_warning` | 10 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 41 | 395.442 | 137158 | break | `sw_strike_crack` | 10 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 42 | 395.442 | 137158 | break | `sw_strike_body` | 10 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 43 | 395.442 | 137158 | break | `sw_strike_decay` | 10 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 44 | 400.616 | 142319 | break | `sw_strike_warning` | 11 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 45 | 401.817 | 143519 | break | `sw_strike_crack` | 11 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 46 | 401.817 | 143520 | break | `sw_strike_body` | 11 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 47 | 401.817 | 143520 | break | `sw_strike_decay` | 11 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 48 | 408.213 | 149907 | break | `sw_strike_warning` | 12 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 49 | 409.414 | 151101 | break | `sw_strike_crack` | 12 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 50 | 409.414 | 151101 | break | `sw_strike_body` | 12 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 51 | 409.414 | 151101 | break | `sw_strike_decay` | 12 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 52 | 416.147 | 157872 | break | `sw_strike_warning` | 13 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 53 | 417.348 | 159068 | break | `sw_strike_crack` | 13 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 54 | 417.348 | 159068 | break | `sw_strike_body` | 13 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 55 | 417.348 | 159068 | break | `sw_strike_decay` | 13 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 56 | 423.855 | 165572 | break | `sw_strike_warning` | 14 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 57 | 425.056 | 166772 | break | `sw_strike_crack` | 14 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 58 | 425.056 | 166772 | break | `sw_strike_body` | 14 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 59 | 425.056 | 166772 | break | `sw_strike_decay` | 14 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 60 | 430.459 | 172177 | break | `sw_strike_warning` | 15 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 61 | 431.661 | 173376 | break | `sw_strike_crack` | 15 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 62 | 431.661 | 173376 | break | `sw_strike_body` | 15 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 63 | 431.661 | 173376 | break | `sw_strike_decay` | 15 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 64 | 437.709 | 179424 | break | `sw_strike_warning` | 16 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 65 | 438.911 | 180625 | break | `sw_strike_crack` | 16 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 66 | 438.911 | 180625 | break | `sw_strike_body` | 16 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 67 | 438.911 | 180625 | break | `sw_strike_decay` | 16 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 68 | 442.313 | 184026 | break | `sw_strike_warning` | 17 | (-1400.0, 29.9, 2300.0) | false | false | [lightning building, nearby] |
| 69 | 443.515 | 185222 | break | `sw_strike_crack` | 17 | (-1400.0, 29.9, 2300.0) | false | false | [lightning strike, nearby] |
| 70 | 443.515 | 185222 | break | `sw_strike_body` | 17 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 71 | 443.515 | 185222 | break | `sw_strike_decay` | 17 | (-1400.0, 29.9, 2300.0) | false | false |  |
| 72 | 450.001 | 191680 | fading | `sw_surge_fading_decay` | - | - | false | false | [thunder rolling away] |
| 73 | 458.008 | 199669 | aftermath calm | `sw_release_forest_sky_bed` | - | - | false | false | [the storm lifts; ordinary forest sounds] |
