# D26. The input layers own separate vectors; Input sums them

Kind: implementation

`DesktopLayer.poll()` used to assign `intent.move` directly, every frame, from
held keys. Both layers mount whenever the hardware reports touch points, so on a
phone with no keyboard that assignment was always zero and it erased whatever
the touch stick had written microseconds earlier.

The symptom reported by the owner was exact: "all I can do is look around."
`look` accumulates with `+=` and nothing overwrote it, so looking worked while
moving did not. The game was unplayable on its primary target platform and every
unit test, the typechecker and six browser smoke specs all passed.

Each layer now owns a `move` vector and `Input.beginFrame()` sums and clamps
them. `tests/intent.test.ts` covers the contract, including the specific case of
an idle keyboard not erasing an active stick.

The wider lesson, worth remembering before writing the next input feature: the
existing smoke specs boot the game and check that it renders. None of them
*play* it. A spec that presses a key and asserts the player moved would have
caught this on the first run.
