import config from '../../data/input.json';
import { FIXED_DT } from '../Loop';
import { applyDeadZone, type Intent, type InputMode, type PartySlot } from './Intent';

/**
 * Gamepad input. The primary path on a ROG Ally (DECISIONS.md D27).
 *
 * Follows the pattern D26 established: this layer owns its own `move` vector
 * and `Input.beginFrame()` sums it, rather than writing into the shared Intent.
 * A layer that assigns `intent.move` directly zeroes whatever the other layers
 * wrote, which is exactly how the touch stick got silently erased.
 *
 * The one genuinely awkward part is look. A mouse reports a DELTA and a stick
 * reports a RATE, and `Intent.look` is defined as a per-frame delta. So this
 * layer integrates: deflection x rate x fixed timestep. `beginFrame()` runs
 * once per fixed simulation step, so multiplying by FIXED_DT is exactly right
 * and nothing downstream has to know a pad is attached.
 *
 * There is no polling subscription in the Gamepad API worth using: browsers
 * require navigator.getGamepads() to be read fresh every frame, and a snapshot
 * held across frames goes stale.
 */

const { gamepad: TUNING } = config;

/** Standard mapping indices. Chrome and Edge both report "standard" for an Ally. */
const AXIS = { moveX: 0, moveY: 1, lookX: 2, lookY: 3 } as const;
const BTN = {
  a: 0,
  b: 1,
  x: 2,
  y: 3,
  lb: 4,
  rb: 5,
  lt: 6,
  rt: 7,
  leftStick: 10,
  /** XInput Start. The only button reserved for the pause menu. */
  start: 9,
  dpadUp: 12,
  dpadDown: 13,
  dpadLeft: 14,
  dpadRight: 15
} as const;

/**
 * Party slots on the d-pad, plus Y outside a fight.
 *
 * Five slots and four d-pad directions, so the fifth goes somewhere. Y used
 * to always be the fifth; in combat it now means "run" (owner's ROG Ally
 * playtest: quick, power, orb and flee belong on the four face buttons), so
 * slot five is only reachable from the d-pad's four directions while
 * exploring and is handled with the other mode-gated buttons in `poll()`
 * rather than in this table.
 */
const SLOT_BUTTONS: Array<[number, PartySlot]> = [
  [BTN.dpadUp, 1],
  [BTN.dpadLeft, 2],
  [BTN.dpadRight, 3],
  [BTN.dpadDown, 4]
];

/** The fields device selection needs, so it is testable without a real Gamepad. */
export interface PadCandidate {
  readonly connected: boolean;
  readonly mapping: string;
  readonly index: number;
}

/** What the HUD's ?stats=1 overlay and a remote bug report both need. */
export interface SelectedPadInfo {
  readonly id: string;
  readonly mapping: string;
}

/**
 * Pick which connected pad drives the game. Pure, so it is unit-testable with
 * plain objects instead of a browser's Gamepad list.
 *
 * A standard-mapping pad wins even when a non-standard one appears earlier in
 * the array. This is the actual root cause of "only the left stick works" on
 * a ROG Ally: it enumerates both the XInput standard pad and ASUS's own
 * vendor HID interface, axes 0/1 land on the left stick on either (that
 * mapping is near-universal on raw HID pads), but every button index and the
 * right stick's axes 2/3 are only correct on the standard one. Picking
 * "whichever connected first" picks the vendor interface about half the time.
 *
 * Falls back to a non-standard pad only when no standard pad is present at
 * all, because a game that ignores the only pad plugged in is worse than one
 * with a half-working mapping.
 */
export function selectPad<T extends PadCandidate>(
  pads: readonly (T | null | undefined)[]
): T | null {
  let fallback: T | null = null;
  for (const p of pads) {
    if (!p || !p.connected) continue;
    if (p.mapping === 'standard') return p;
    if (!fallback) fallback = p;
  }
  return fallback;
}

export class GamepadLayer {
  readonly move = { x: 0, y: 0 };
  sprint = false;

  /** True once a pad has actually been touched, so the HUD can swap prompts. */
  active = false;

  private mode: InputMode = 'explore';
  private readonly wasDown = new Map<number, boolean>();
  private primaryDownAt = 0;
  private readonly teardown: Array<() => void> = [];
  private selected: SelectedPadInfo | null = null;

  constructor(private readonly intent: Intent) {
    // Neither event is load-bearing: pad() below re-runs selectPad() against
    // navigator.getGamepads() every fixed step regardless, which is what
    // actually fixes the "latches onto whatever connected last" bug. These
    // exist only to release cleanly and drop the announce cache the instant a
    // pad disappears, rather than waiting up to one fixed step for the next
    // poll to notice.
    const reselect = (): void => {
      const pads = navigator.getGamepads?.() ?? [];
      if (!selectPad(pads)) this.release();
    };
    window.addEventListener('gamepadconnected', reselect);
    window.addEventListener('gamepaddisconnected', reselect);
    this.teardown.push(() => {
      window.removeEventListener('gamepadconnected', reselect);
      window.removeEventListener('gamepaddisconnected', reselect);
    });
  }

  setMode(mode: InputMode): void {
    this.mode = mode;
  }

  /** The pad driving input right now, for the ?stats=1 overlay. Null until one
   *  has actually been read at least once. */
  get selectedPad(): SelectedPadInfo | null {
    return this.selected;
  }

  private pad(): Gamepad | null {
    // Must be re-read every frame; the objects are snapshots, not live views.
    // Re-selecting from scratch every call (rather than trusting a cached
    // index) is what stops the layer from latching onto a vendor HID pad that
    // happened to connect after the standard one.
    const pads = navigator.getGamepads?.() ?? [];
    const chosen = selectPad(pads);
    if (!chosen) return null;
    this.announce(chosen);
    return chosen;
  }

  /** Log the chosen pad exactly once per distinct id/mapping, so a remote bug
   *  report ("only the left stick works") is diagnosable without a repro. */
  private announce(pad: Gamepad): void {
    // Compared against the RAW mapping, not the display string below. A pad's
    // `mapping` is '' for anything non-standard, and this used to store the
    // display substitute ('(none)') and compare that against the next poll's
    // raw '', which never matched, so a non-standard pad re-logged every
    // single fixed step instead of once.
    if (this.selected?.id === pad.id && this.selected.mapping === pad.mapping) return;
    this.selected = { id: pad.id, mapping: pad.mapping };
    console.info(
      `[gamepad] selected "${pad.id}" mapping=${pad.mapping || '(none)'} ` +
        `buttons=${pad.buttons.length} axes=${pad.axes.length}`
    );
  }

  /** Read the pad into this layer's own state. Called once per fixed step. */
  poll(): void {
    const pad = this.pad();
    if (!pad) {
      this.release();
      return;
    }

    const ax = pad.axes[AXIS.moveX] ?? 0;
    const ay = pad.axes[AXIS.moveY] ?? 0;
    const moved = applyDeadZone(ax, ay, TUNING.moveDeadZone);
    this.move.x = moved.x;
    // Stick y is positive downward; forward is negative y.
    this.move.y = -moved.y;

    this.pollLook(pad);

    this.sprint = this.pressed(pad, BTN.leftStick);
    // The four face buttons: quick, power, orb, run in a fight; jump,
    // interact and slot five outside one. Owner's ROG Ally playtest asked for
    // exactly this A/B/X/Y layout so the buttons read the same as the
    // controller in the player's hands. This retires A's neutral dodge
    // (D61); Space and the shoulders still dodge, see below.
    if (this.edge(pad, BTN.a)) {
      if (this.mode === 'combat') this.intent.quickAttack = true;
      else this.intent.jump = true;
    }
    if (this.edge(pad, BTN.b)) {
      if (this.mode === 'combat') this.intent.powerAttack = true;
    }
    if (this.edge(pad, BTN.x)) {
      if (this.mode === 'combat') this.intent.throwOrb = true;
      else this.intent.interact = true;
    }
    if (this.edge(pad, BTN.y)) {
      if (this.mode === 'combat') this.intent.flee = true;
      else this.intent.slot = 5;
    }
    // Opens and closes the pause menu regardless of mode; a fight or a
    // conversation must not be able to block it.
    if (this.edge(pad, BTN.start)) this.intent.pause = true;

    // Shoulders dodge left and right. In explore they do nothing, because the
    // player has no dodge outside a fight.
    if (this.mode === 'combat') {
      if (this.edge(pad, BTN.lb)) this.intent.dodge = -1;
      if (this.edge(pad, BTN.rb)) this.intent.dodge = 1;
    }

    for (const [button, slot] of SLOT_BUTTONS) {
      if (this.edge(pad, button)) this.intent.slot = slot;
    }

    this.pollPrimary(pad);

    if (!this.active && this.isBeingUsed(pad)) this.active = true;
  }

  private pollLook(pad: Gamepad): void {
    const lx = pad.axes[AXIS.lookX] ?? 0;
    const ly = pad.axes[AXIS.lookY] ?? 0;
    const look = applyDeadZone(lx, ly, TUNING.lookDeadZone);
    const mag = Math.hypot(look.x, look.y);
    if (mag <= 0) return;

    // Response curve: fine aim near centre, full rate at the rim. Applied to
    // the vector's magnitude so it does not distort direction.
    const curved = Math.pow(mag, TUNING.lookCurve) / mag;
    this.intent.look.x += look.x * curved * TUNING.lookRateX * FIXED_DT;
    this.intent.look.y += look.y * curved * TUNING.lookRateY * FIXED_DT;
  }

  /**
   * The right trigger is the one combat verb. It is analogue, so a light pull
   * is still a press; the charge time is what distinguishes quick from power.
   */
  private pollPrimary(pad: Gamepad): void {
    const value = pad.buttons[BTN.rt]?.value ?? 0;
    const down = value >= TUNING.triggerThreshold;
    const wasDown = this.intent.primary.down;

    if (down && !wasDown) {
      this.intent.primary.down = true;
      this.intent.primary.heldMs = 0;
      this.primaryDownAt = performance.now();
    } else if (down) {
      this.intent.primary.heldMs = performance.now() - this.primaryDownAt;
    } else if (wasDown && this.primaryDownAt > 0) {
      this.intent.primary.down = false;
      this.intent.primary.heldMs = performance.now() - this.primaryDownAt;
      this.primaryDownAt = 0;
    }
  }

  private pressed(pad: Gamepad, index: number): boolean {
    return pad.buttons[index]?.pressed ?? false;
  }

  /** True on the frame a button goes down, false while it is held. */
  private edge(pad: Gamepad, index: number): boolean {
    const now = this.pressed(pad, index);
    const before = this.wasDown.get(index) ?? false;
    this.wasDown.set(index, now);
    return now && !before;
  }

  private isBeingUsed(pad: Gamepad): boolean {
    for (const axis of pad.axes) if (Math.abs(axis) > TUNING.moveDeadZone) return true;
    for (const button of pad.buttons) if (button.pressed) return true;
    return false;
  }

  private release(): void {
    this.move.x = 0;
    this.move.y = 0;
    this.sprint = false;
    this.wasDown.clear();
    this.selected = null;
    if (this.primaryDownAt > 0) {
      this.intent.primary.down = false;
      this.primaryDownAt = 0;
    }
  }

  dispose(): void {
    for (const fn of this.teardown.splice(0)) fn();
    this.release();
    this.active = false;
  }
}
