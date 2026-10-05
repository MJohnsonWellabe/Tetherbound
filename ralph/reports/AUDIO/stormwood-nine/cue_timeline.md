# Stormwood Surge audio witness: cue timeline

Headless, production Stormwood world, real Surge clock and host lightning. `surge_clock_s` is the replicated Surge clock; `t_msec` is `Time.get_ticks_msec()`. `played` means the cue's asset loaded and a pool player started it; what it sounds like is judged offline by tools/audio/check_stormwood.py.

| # | surge clock s | t_msec | phase | cue | strike | position | asset present | played | caption |
|---|---:|---:|---|---|---:|---|---|---|---|
| 1 | 0.149 | 28555 | calm | `sw_surge_calm_bed` | - | - | true | true | [steady rain in the Stormwood] |
| 2 | 240.004 | 46203 | building | `sw_surge_building_bed` | - | - | true | true | [lightning building] |
| 3 | 330.004 | 58213 | break | `sw_surge_break_bed` | - | - | true | true | [the storm breaks] |
| 4 | 331.824 | 60045 | break | `sw_strike_warning` | 1 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 5 | 333.029 | 61252 | break | `sw_strike_crack` | 1 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 6 | 333.029 | 61252 | break | `sw_strike_body` | 1 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 7 | 333.029 | 61252 | break | `sw_strike_decay` | 1 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 8 | 336.809 | 65027 | break | `sw_strike_warning` | 2 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 9 | 338.013 | 66233 | break | `sw_strike_crack` | 2 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 10 | 338.013 | 66233 | break | `sw_strike_body` | 2 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 11 | 338.013 | 66234 | break | `sw_strike_decay` | 2 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 12 | 343.338 | 71550 | break | `sw_strike_warning` | 3 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 13 | 344.538 | 72754 | break | `sw_strike_crack` | 3 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 14 | 344.538 | 72754 | break | `sw_strike_body` | 3 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 15 | 344.538 | 72754 | break | `sw_strike_decay` | 3 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 16 | 350.386 | 78613 | break | `sw_strike_warning` | 4 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 17 | 351.587 | 79799 | break | `sw_strike_crack` | 4 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 18 | 351.587 | 79799 | break | `sw_strike_body` | 4 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 19 | 351.587 | 79799 | break | `sw_strike_decay` | 4 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 20 | 356.466 | 84677 | break | `sw_strike_warning` | 5 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 21 | 357.669 | 85890 | break | `sw_strike_crack` | 5 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 22 | 357.669 | 85890 | break | `sw_strike_body` | 5 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 23 | 357.669 | 85890 | break | `sw_strike_decay` | 5 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 24 | 361.103 | 89315 | break | `sw_strike_warning` | 6 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 25 | 362.319 | 90542 | break | `sw_strike_crack` | 6 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 26 | 362.319 | 90542 | break | `sw_strike_body` | 6 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 27 | 362.319 | 90542 | break | `sw_strike_decay` | 6 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 28 | 367.371 | 95581 | break | `sw_strike_warning` | 7 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 29 | 368.588 | 96806 | break | `sw_strike_crack` | 7 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 30 | 368.588 | 96806 | break | `sw_strike_body` | 7 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 31 | 368.588 | 96806 | break | `sw_strike_decay` | 7 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 32 | 371.639 | 99829 | break | `sw_strike_warning` | 8 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 33 | 372.854 | 101037 | break | `sw_strike_crack` | 8 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 34 | 372.854 | 101037 | break | `sw_strike_body` | 8 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 35 | 372.854 | 101037 | break | `sw_strike_decay` | 8 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 36 | 376.172 | 104384 | break | `sw_strike_warning` | 9 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 37 | 377.381 | 105608 | break | `sw_strike_crack` | 9 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 38 | 377.381 | 105608 | break | `sw_strike_body` | 9 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 39 | 377.381 | 105608 | break | `sw_strike_decay` | 9 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 40 | 382.859 | 111089 | break | `sw_strike_warning` | 10 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 41 | 384.070 | 112295 | break | `sw_strike_crack` | 10 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 42 | 384.070 | 112295 | break | `sw_strike_body` | 10 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 43 | 384.070 | 112295 | break | `sw_strike_decay` | 10 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 44 | 387.596 | 115814 | break | `sw_strike_warning` | 11 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 45 | 388.813 | 117027 | break | `sw_strike_crack` | 11 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 46 | 388.813 | 117027 | break | `sw_strike_body` | 11 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 47 | 388.813 | 117028 | break | `sw_strike_decay` | 11 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 48 | 394.426 | 122608 | break | `sw_strike_warning` | 12 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 49 | 395.640 | 123835 | break | `sw_strike_crack` | 12 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 50 | 395.640 | 123835 | break | `sw_strike_body` | 12 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 51 | 395.640 | 123835 | break | `sw_strike_decay` | 12 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 52 | 399.544 | 127743 | break | `sw_strike_warning` | 13 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 53 | 400.751 | 128949 | break | `sw_strike_crack` | 13 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 54 | 400.751 | 128949 | break | `sw_strike_body` | 13 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 55 | 400.751 | 128949 | break | `sw_strike_decay` | 13 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 56 | 405.837 | 134021 | break | `sw_strike_warning` | 14 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 57 | 407.049 | 135242 | break | `sw_strike_crack` | 14 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 58 | 407.049 | 135242 | break | `sw_strike_body` | 14 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 59 | 407.049 | 135242 | break | `sw_strike_decay` | 14 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 60 | 411.045 | 139229 | break | `sw_strike_warning` | 15 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 61 | 412.247 | 140447 | break | `sw_strike_crack` | 15 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 62 | 412.247 | 140447 | break | `sw_strike_body` | 15 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 63 | 412.247 | 140447 | break | `sw_strike_decay` | 15 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 64 | 415.434 | 143634 | break | `sw_strike_warning` | 16 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 65 | 416.645 | 144852 | break | `sw_strike_crack` | 16 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 66 | 416.645 | 144852 | break | `sw_strike_body` | 16 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 67 | 416.645 | 144852 | break | `sw_strike_decay` | 16 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 68 | 421.547 | 149733 | break | `sw_strike_warning` | 17 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 69 | 422.761 | 150943 | break | `sw_strike_crack` | 17 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 70 | 422.761 | 150943 | break | `sw_strike_body` | 17 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 71 | 422.761 | 150943 | break | `sw_strike_decay` | 17 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 72 | 428.927 | 157121 | break | `sw_strike_warning` | 18 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 73 | 430.147 | 158349 | break | `sw_strike_crack` | 18 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 74 | 430.147 | 158349 | break | `sw_strike_body` | 18 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 75 | 430.147 | 158349 | break | `sw_strike_decay` | 18 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 76 | 434.087 | 162271 | break | `sw_strike_warning` | 19 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 77 | 435.296 | 163501 | break | `sw_strike_crack` | 19 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 78 | 435.296 | 163501 | break | `sw_strike_body` | 19 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 79 | 435.296 | 163501 | break | `sw_strike_decay` | 19 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 80 | 438.502 | 166702 | break | `sw_strike_warning` | 20 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 81 | 439.712 | 167915 | break | `sw_strike_crack` | 20 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 82 | 439.712 | 167915 | break | `sw_strike_body` | 20 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 83 | 439.712 | 167915 | break | `sw_strike_decay` | 20 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 84 | 442.605 | 170807 | break | `sw_strike_warning` | 21 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 85 | 443.809 | 171998 | break | `sw_strike_crack` | 21 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 86 | 443.809 | 171998 | break | `sw_strike_body` | 21 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 87 | 443.809 | 171998 | break | `sw_strike_decay` | 21 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 88 | 449.453 | 177637 | break | `sw_strike_warning` | 22 | (-1400.0, 29.9, 2300.0) | true | true | [lightning building, nearby] |
| 89 | 450.011 | 178181 | fading | `sw_surge_fading_decay` | - | - | true | true | [thunder rolling away] |
| 90 | 450.672 | 178870 | fading | `sw_strike_crack` | 22 | (-1400.0, 29.9, 2300.0) | true | true | [lightning strike, nearby] |
| 91 | 450.672 | 178870 | fading | `sw_strike_body` | 22 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 92 | 450.672 | 178870 | fading | `sw_strike_decay` | 22 | (-1400.0, 29.9, 2300.0) | true | true |  |
| 93 | 458.021 | 186193 | aftermath calm | `sw_release_forest_sky_bed` | - | - | true | true | [the storm lifts; ordinary forest sounds] |
