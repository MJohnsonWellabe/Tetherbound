import type { Input, InputSource } from '../core/input/Input';

/**
 * The control prompt, and the fullscreen toggle.
 *
 * This exists because of a real bug report: "on pc I don't know how to look
 * around but I can move". Pointer lock was requested on click and nothing
 * anywhere said so, which makes a working camera indistinguishable from a
 * broken one. A control scheme the player has to guess is a broken control
 * scheme.
 *
 * Prompts follow the device actually in use rather than the device attached.
 * A ROG Ally has a pad, a touchscreen and a keyboard at once, so capability
 * detection cannot answer the question and only recent use can.
 */

const PROMPTS: Record<InputSource, string> = {
  gamepad: 'Left stick move · Right stick look · L3 sprint · A jump · X interact',
  keyboard: 'WASD move · Shift sprint · Space jump · E interact',
  touch: 'Left thumb move · Right thumb look · Push the stick to sprint'
};

/** Shown only while mouse look is not engaged. The one prompt that is urgent. */
const LOOK_HINT = 'Click to look around, or hold right mouse and drag';

export class InputHint {
  private lastText = '';
  private readonly teardown: Array<() => void> = [];

  constructor(
    private readonly el: HTMLElement,
    private readonly input: Input,
    fullscreenButton: HTMLElement | null
  ) {
    const toggle = (): void => void this.toggleFullscreen();
    const key = (e: KeyboardEvent): void => {
      if (e.code === 'KeyF' && !e.repeat) toggle();
    };
    window.addEventListener('keydown', key);
    fullscreenButton?.addEventListener('click', toggle);
    this.teardown.push(() => {
      window.removeEventListener('keydown', key);
      fullscreenButton?.removeEventListener('click', toggle);
    });
  }

  /**
   * Browser chrome eats a meaningful fraction of a 7 inch handheld screen, and
   * on a device with no keyboard F11 is not reachable.
   */
  private async toggleFullscreen(): Promise<void> {
    try {
      if (document.fullscreenElement) await document.exitFullscreen();
      else await document.documentElement.requestFullscreen();
    } catch {
      // Denied without a user gesture, or unsupported. Not worth surfacing.
    }
  }

  /** Called once per frame. Writes to the DOM only when the text changes. */
  update(): void {
    const text = this.input.needsPointerLockHint
      ? LOOK_HINT
      : PROMPTS[this.input.inputSource];
    if (text === this.lastText) return;
    this.lastText = text;
    this.el.textContent = text;
    this.el.classList.toggle('hint--urgent', this.input.needsPointerLockHint);
  }

  dispose(): void {
    for (const fn of this.teardown.splice(0)) fn();
  }
}
