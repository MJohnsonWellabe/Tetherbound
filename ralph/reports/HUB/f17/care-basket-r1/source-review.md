# Independent paid-care source review

Source verdict: approved for bounded native validation. Actual fresh earned M1 remains required; this change and its detached UI probe do not close F17#4 or grant visual acceptance. Review performed without engine, world, import or production writes.

Reviewed uncommitted snapshots over `9349735d2b7c35308e6e78e98b0b1f0b35d09afa`:

- `tests/helpers/gate_a_npc_gather_segment.gd`: SHA256 `51a89069abba20442ae5a5e537f1fcf2c9e8b37e60e4400742f0dacbd078708d`.
- `tests/smoke_four_biome_continuous.gd`: SHA256 `31d971a665bbbf869b393303bd4faf2fc77938f1a1420e5b75bad93f5000f218`.
- `tests/probe_f17_care_shop.gd`: SHA256 `1c2dc67ce26361463d30c82374a2b244ce06978e245207d7e63e28bbac5b5546`.

The default village helper remains opted out. Only the canonical fresh campaign opts into four purchases; the legacy diagnostic flag preserves its prior behavior. The hook runs after Mira's actual dialogue has opened the owned shop and before the existing physical B exit. This uses her initial lawful vendor window, avoiding the later greeting that starts her trainer challenge while `defeated_mira` is absent. No vendor flag, shop-open call, inventory grant or gameplay transaction is forced by the campaign helper.

Each purchase requires the exact owned/open Mira panel, derives the stocked potion row, currency and price from production trade data, checks the live row's item name/price/affordability, and reaches it using physical bound up/down inputs. Confirmation uses the real pad binding. Rows are reacquired for each transaction because ShopPanel rebuilds its buttons. There is no direct Button press/emit, focus assignment, buy_one or trade.buy call in the driver. Exact one-potion gain and authored coin spend are verified separately for every press.

Receipt APIs now match the actual source: inventory snapshots use slot_count/stack_at and stack quantity `n`. Comparing the full count dictionaries after excluding only currency/potion includes unknown carried IDs. Party member references, revision, active selection and every creature script-variable value are compared; nested arrays/dictionaries are copied deeply. The earlier nonexistent to_dict calls and ineffective count-key checks are resolved. These snapshots observe state and perform no care or party mutation themselves.

Wrong owner/vendor, excessive purchase count, missing/nonpositive price, insufficient total funds, missing/disabled/mislabelled row, lost focus, incorrect payment/gain, other-item mutation or party mutation prevent success. The aggregate affordability check runs before the first confirmation, so an unaffordable basket is refused without partial spending. Existing close/world-ownership/movement/door-exit behavior remains. Training fight/loss limits, health/care policy and readiness criteria are unchanged.

The new probe clearly declares an isolated 140-coin/four-wood/empty-party fixture, then exercises this exact purchase driver against production ShopPanel and pad events. It checks four purchases, rebuilt focus, unchanged wood, and a two-potion funds refusal with no partial spend, then restores the prior inventory/party references. Its empty party does not exercise real-creature snapshot retention, and its direct shop opening is a disclosed fixture rather than earned journey evidence. Expected refusal invokes the helper's error reporter; that line must not be represented as an unexpected production defect or hidden as a clean-engine claim.

No source blocker remains in the reviewed diff. Actual native UI output must verify the purchase/input path, and a fresh uninterrupted earned M1 must still demonstrate the paid supplies, unchanged Satchel care, camp, required beds/readiness and three tournament rounds. Earlier failed profiles cannot substitute for that proof.
