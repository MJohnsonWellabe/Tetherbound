/**
 * The "Open"/"Close" prompt for a nearby door.
 *
 * A standalone element rather than folded into HarvestHud's prompt: doors are
 * a different interaction surface (BuildMode, not HarvestController) and
 * unifying every contextual prompt behind one resolver is InteractionManager's
 * job once it exists. Until then this stays small and self-contained so it
 * does not collide with in-flight work on the harvest prompt.
 */
export class DoorPrompt {
  private readonly el: HTMLElement;
  private last = '';

  constructor(mountNear: HTMLElement) {
    this.el = document.createElement('div');
    this.el.className = 'prompt';
    this.el.hidden = true;
    (mountNear.parentElement ?? document.body).append(this.el);
  }

  /** `open` is the door's CURRENT state; the prompt names the action, not the state. */
  update(nearDoor: boolean, open: boolean): void {
    const text = nearDoor ? `E   ${open ? 'Close' : 'Open'} door` : '';
    if (text === this.last) return;
    this.last = text;
    this.el.textContent = text;
    this.el.hidden = text === '';
  }

  dispose(): void {
    this.el.remove();
  }
}
