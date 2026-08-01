# D06. Pal models deferred to M5

Kind: spec-conflict

`ASSETS.md` section "Pal model strategy" assumes six rigged Quaternius animal
base models are pulled and varied by tint, scale and accessory. Deferred, per
that same document's placeholder policy ("Do not spend a day sourcing models
before the character controller feels good on a phone").

The `baseModel + tint + scale + accessory` mapping still lives in
`species.json` from the first commit that creates it, so the M5 swap is a data
change with no gameplay code touched.
