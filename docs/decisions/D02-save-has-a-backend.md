# D02. Save has a backend

Kind: spec-conflict

`ARCHITECTURE.md` Stack table says "Save: localStorage + base64 export" and
"No backend". Overridden: the game has Firebase accounts so a player can resume
on another device.

The base64 export string stays. It is cheap, it is the no-account escape hatch,
and it shares a codec with the cloud payload.
