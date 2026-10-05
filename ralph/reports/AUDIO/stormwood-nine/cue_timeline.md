# Stormwood Surge audio witness: cue timeline

Headless, production Stormwood world, real Surge clock and host lightning. `surge_clock_s` is the replicated Surge clock; `t_msec` is `Time.get_ticks_msec()`. `played` means the cue's asset loaded and a pool player started it; what it sounds like is judged offline by tools/audio/check_stormwood.py.

| # | surge clock s | t_msec | phase | cue | strike | position | asset present | played | caption |
|---|---:|---:|---|---|---:|---|---|---|---|
| 1 | 0.144 | 28111 | calm | `sw_surge_calm_bed` | - | - | true | true | [steady rain in the Stormwood] |
| 2 | 240.007 | 46056 | building | `sw_surge_building_bed` | - | - | true | true | [lightning building] |
| 3 | 330.010 | 58044 | break | `sw_surge_break_bed` | - | - | true | true | [the storm breaks] |
| 4 | 332.290 | 60342 | break | `sw_strike_warning` | 1 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 5 | 333.500 | 61558 | break | `sw_strike_crack` | 1 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 6 | 333.500 | 61558 | break | `sw_strike_body` | 1 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 7 | 333.500 | 61558 | break | `sw_strike_decay` | 1 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 8 | 337.354 | 65400 | break | `sw_strike_warning` | 2 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 9 | 338.567 | 66613 | break | `sw_strike_crack` | 2 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 10 | 338.567 | 66613 | break | `sw_strike_body` | 2 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 11 | 338.567 | 66613 | break | `sw_strike_decay` | 2 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 12 | 344.500 | 72545 | break | `sw_strike_warning` | 3 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 13 | 345.714 | 73785 | break | `sw_strike_crack` | 3 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 14 | 345.714 | 73785 | break | `sw_strike_body` | 3 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 15 | 345.714 | 73785 | break | `sw_strike_decay` | 3 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 16 | 348.931 | 76976 | break | `sw_strike_warning` | 4 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 17 | 350.138 | 78189 | break | `sw_strike_crack` | 4 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 18 | 350.138 | 78189 | break | `sw_strike_body` | 4 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 19 | 350.138 | 78189 | break | `sw_strike_decay` | 4 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 20 | 354.051 | 82103 | break | `sw_strike_warning` | 5 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 21 | 355.257 | 83305 | break | `sw_strike_crack` | 5 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 22 | 355.257 | 83305 | break | `sw_strike_body` | 5 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 23 | 355.257 | 83305 | break | `sw_strike_decay` | 5 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 24 | 360.677 | 88715 | break | `sw_strike_warning` | 6 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 25 | 361.890 | 89932 | break | `sw_strike_crack` | 6 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 26 | 361.890 | 89932 | break | `sw_strike_body` | 6 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 27 | 361.890 | 89932 | break | `sw_strike_decay` | 6 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 28 | 366.957 | 94994 | break | `sw_strike_warning` | 7 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 29 | 368.168 | 96205 | break | `sw_strike_crack` | 7 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 30 | 368.168 | 96205 | break | `sw_strike_body` | 7 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 31 | 368.168 | 96205 | break | `sw_strike_decay` | 7 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 32 | 372.495 | 100547 | break | `sw_strike_warning` | 8 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 33 | 373.698 | 101759 | break | `sw_strike_crack` | 8 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 34 | 373.698 | 101759 | break | `sw_strike_body` | 8 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 35 | 373.698 | 101759 | break | `sw_strike_decay` | 8 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 36 | 378.429 | 106478 | break | `sw_strike_warning` | 9 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 37 | 379.643 | 107693 | break | `sw_strike_crack` | 9 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 38 | 379.643 | 107693 | break | `sw_strike_body` | 9 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 39 | 379.643 | 107693 | break | `sw_strike_decay` | 9 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 40 | 382.496 | 110545 | break | `sw_strike_warning` | 10 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 41 | 383.701 | 111736 | break | `sw_strike_crack` | 10 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 42 | 383.701 | 111736 | break | `sw_strike_body` | 10 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 43 | 383.701 | 111736 | break | `sw_strike_decay` | 10 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 44 | 390.308 | 118353 | break | `sw_strike_warning` | 11 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 45 | 391.519 | 119567 | break | `sw_strike_crack` | 11 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 46 | 391.519 | 119567 | break | `sw_strike_body` | 11 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 47 | 391.519 | 119567 | break | `sw_strike_decay` | 11 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 48 | 395.650 | 123686 | break | `sw_strike_warning` | 12 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 49 | 396.850 | 124889 | break | `sw_strike_crack` | 12 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 50 | 396.850 | 124889 | break | `sw_strike_body` | 12 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 51 | 396.850 | 124889 | break | `sw_strike_decay` | 12 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 52 | 400.973 | 129025 | break | `sw_strike_warning` | 13 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 53 | 402.185 | 130235 | break | `sw_strike_crack` | 13 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 54 | 402.185 | 130235 | break | `sw_strike_body` | 13 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 55 | 402.185 | 130235 | break | `sw_strike_decay` | 13 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 56 | 405.131 | 133173 | break | `sw_strike_warning` | 14 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 57 | 406.339 | 134375 | break | `sw_strike_crack` | 14 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 58 | 406.339 | 134375 | break | `sw_strike_body` | 14 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 59 | 406.339 | 134376 | break | `sw_strike_decay` | 14 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 60 | 409.694 | 137731 | break | `sw_strike_warning` | 15 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 61 | 410.899 | 138950 | break | `sw_strike_crack` | 15 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 62 | 410.899 | 138950 | break | `sw_strike_body` | 15 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 63 | 410.899 | 138950 | break | `sw_strike_decay` | 15 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 64 | 415.382 | 143419 | break | `sw_strike_warning` | 16 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 65 | 416.588 | 144635 | break | `sw_strike_crack` | 16 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 66 | 416.588 | 144636 | break | `sw_strike_body` | 16 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 67 | 416.588 | 144636 | break | `sw_strike_decay` | 16 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 68 | 419.696 | 147737 | break | `sw_strike_warning` | 17 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 69 | 420.907 | 148975 | break | `sw_strike_crack` | 17 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 70 | 420.907 | 148975 | break | `sw_strike_body` | 17 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 71 | 420.907 | 148975 | break | `sw_strike_decay` | 17 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 72 | 423.757 | 151816 | break | `sw_strike_warning` | 18 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 73 | 424.963 | 152997 | break | `sw_strike_crack` | 18 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 74 | 424.963 | 152998 | break | `sw_strike_body` | 18 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 75 | 424.963 | 152998 | break | `sw_strike_decay` | 18 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 76 | 431.545 | 159603 | break | `sw_strike_warning` | 19 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 77 | 432.762 | 160807 | break | `sw_strike_crack` | 19 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 78 | 432.762 | 160807 | break | `sw_strike_body` | 19 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 79 | 432.762 | 160807 | break | `sw_strike_decay` | 19 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 80 | 437.027 | 165090 | break | `sw_strike_warning` | 20 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 81 | 438.241 | 166283 | break | `sw_strike_crack` | 20 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 82 | 438.241 | 166283 | break | `sw_strike_body` | 20 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 83 | 438.241 | 166283 | break | `sw_strike_decay` | 20 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 84 | 444.288 | 172336 | break | `sw_strike_warning` | 21 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 85 | 445.494 | 173537 | break | `sw_strike_crack` | 21 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 86 | 445.494 | 173537 | break | `sw_strike_body` | 21 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 87 | 445.494 | 173537 | break | `sw_strike_decay` | 21 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 88 | 450.015 | 178046 | fading | `sw_surge_fading_decay` | - | - | true | true | [thunder rolling away] |
| 89 | 458.019 | 186062 | aftermath calm | `sw_release_forest_sky_bed` | - | - | true | true | [the storm lifts; ordinary forest sounds] |
