# D61. Gamepad device selection, and what a directionless dodge means

Kind: implementation

Two ROG Ally defects, both root-caused before this session started.

**Device selection.** `navigator.getGamepads()` on an Ally reports two
entries for one physical pad: the XInput standard-mapping interface and
ASUS's own vendor HID interface. `GamepadLayer` used to take "whichever
connected first" (`gamepadconnected` latched an index, and the poll fallback
took the first non-null entry). Axes 0/1 land on the left stick on either
interface, because that mapping is near-universal on raw HID pads, so the
symptom was never "nothing works": it was "only the left stick works", with
every button index and the right stick (axes 2/3) silently wrong.

Fixed by pulling selection into a pure function, `selectPad()` in
`GamepadLayer.ts`: prefer a connected pad with `mapping === 'standard'`,
falling back to whatever is connected only when no standard pad exists.
`pad()` re-runs it from `navigator.getGamepads()` every fixed step rather
than trusting a cached index, so a vendor interface connecting after the
standard one can never win. The chosen pad's id and mapping are logged once
via `console.info` and exposed as `GamepadLayer.selectedPad` /
`Input.gamepadStatus`, and the `?stats=1` overlay prints a `pad` line so a
remote bug report is diagnosable without a repro. `tests/gamepadSelect.test.ts`
covers the selection function directly with plain objects; the on-device
behaviour is unverified, since this environment cannot attach a real pad.

**The neutral dodge.** The A button and Space bar are meant to dodge in
combat with no left/right lean, a straight-back hop. Both `GamepadLayer` and
`DesktopLayer` wrote `intent.dodge = 0` for this, which is exactly the value
`CombatMode.update()` reads as "no dodge" (`dodge !== 0` opens the window in
`src/combat/CombatMode.ts`), so neither button had ever dodged.

`DodgeDir` is `-1 | 0 | 1`; there is no fourth "no lean" value, and adding one
would touch `BuildMode.ts` (which reuses this same field for rotation
direction) and every consumer that assumes the type's current shape for no
gameplay benefit, since CombatMode never reads the sign. Rather than grow the
type, `Intent.ts` now exports `NEUTRAL_DODGE = 1`, matching the single
on-screen dodge button in `CombatScreen.ts`, which already had the identical
"one button, no direction to derive it from" shape and had already picked 1.
Both layers import the constant instead of writing a literal, so the meaning
is named once. `tests/gamepadSelect.test.ts` asserts it is a legal, nonzero
`DodgeDir`.
