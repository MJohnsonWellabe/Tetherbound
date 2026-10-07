# Net smoke run r1-f27-guest-wild-win-on-20261006T1620Z

Scene: title
Peers: 2
Net conditions: clean (no proxy)

- peer 0 (host) pid=17772 exited=true unexpected_exit=false
- peer 1 (client) pid=23312 exited=true unexpected_exit=false

FAILURES:
- the guest holds exactly one new defeat receipt ([])
- exactly one guest defeat receipt is fresh
- the host accepted the guest's exact wild share, retained by its canonical latest row ({  })
- the guest received its type essence (+0)
- the guest's creature gained XP from the host share
- host and guest receipts bind the same defeat event and their distinct participants
- after reload party unchanged ([{ "level": 9.0, "species_id": "terrapup", "uid": "creature-215917cb40ae21b10b8a9fd0a0273403", "xp": 32.0 }])
- after reload items unchanged ({ "essence_air": 0.0, "essence_dark": 0.0, "essence_electric": 0.0, "essence_fire": 0.0, "essence_ground": 1.0, "essence_ice": 0.0, "essence_psychic": 0.0, "essence_water": 0.0, "tether_candy": 0.0 })
- after reload defeat_receipts unchanged (["defeat:character-c145ac4e4c66e1398d7bb262758da0cd:7d31f09463622a2cebd01b6b0b31211dc577693cf535620e0a6793136101fc24:e2dc42199e533f9df1e6abdd6f7ec53b46074dd78158009bb0906d3a794884a5"])
