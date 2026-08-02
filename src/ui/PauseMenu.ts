import config from '../data/pauseMenu.json';

/**
 * The pause menu.
 *
 * Opens over a frozen frame from any state: exploring, mid-dialogue, or a
 * fight. The owner wants to replay the opening story on demand, which is what
 * "Start Over" is for. DOM only, no engine import: main.ts owns freezing the
 * simulation and reading the pause edge, this owns the overlay.
 */

const { copyStatusMs: COPY_STATUS_MS } = config;

const START_OVER_LABEL = 'Start Over';
const START_OVER_CONFIRM_LABEL = 'Yes, erase it';
const START_OVER_PROMPT = 'Erase this run? There is no undo and no storage box.';
const COPY_LABEL = 'Copy save';
const COPY_DONE_LABEL = 'Copied to clipboard';
const COPY_FAILED_LABEL = 'Could not copy. Try again.';

export interface PauseMenuCallbacks {
  onResume: () => void;
  /** Only ever called after the second activation. Never wipe on one press. */
  onStartOver: () => void;
  /** Returns the encoded save string to put on the clipboard. */
  onCopySave: () => string;
}

export type StartOverStage = 'idle' | 'confirming';

/**
 * The two-step confirm's whole state machine, pulled out as a pure function
 * so it is testable without a DOM: the first activation only arms, the
 * second (and only the second, while still armed) wipes. Any other stage
 * transition goes through `cancelStartOver`, never this.
 */
export function activateStartOver(stage: StartOverStage): { stage: StartOverStage; wipe: boolean } {
  if (stage === 'idle') return { stage: 'confirming', wipe: false };
  return { stage: 'confirming', wipe: true };
}

export class PauseMenu {
  private readonly resumeBtn: HTMLButtonElement;
  private readonly startOverBtn: HTMLButtonElement;
  private readonly copyBtn: HTMLButtonElement;
  private readonly statusEl: HTMLElement;
  private readonly items: HTMLButtonElement[];
  private stage: StartOverStage = 'idle';
  private copyResetHandle: number | null = null;

  constructor(
    private readonly root: HTMLElement,
    private readonly cb: PauseMenuCallbacks
  ) {
    root.innerHTML = `
      <div class="menu__panel">
        <h2 class="menu__title">Paused</h2>
        <div class="menu__list">
          <button type="button" class="btn menu__btn" data-m="resume">Resume</button>
          <button type="button" class="btn btn--danger menu__btn" data-m="startOver">${START_OVER_LABEL}</button>
          <button type="button" class="btn btn--ghost menu__btn" data-m="copy">${COPY_LABEL}</button>
        </div>
        <p class="menu__status" data-m="status"></p>
      </div>`;

    this.resumeBtn = root.querySelector('[data-m="resume"]') as HTMLButtonElement;
    this.startOverBtn = root.querySelector('[data-m="startOver"]') as HTMLButtonElement;
    this.copyBtn = root.querySelector('[data-m="copy"]') as HTMLButtonElement;
    this.statusEl = root.querySelector('[data-m="status"]') as HTMLElement;
    this.items = [this.resumeBtn, this.startOverBtn, this.copyBtn];

    this.resumeBtn.addEventListener('click', () => {
      this.cancelStartOver();
      this.cb.onResume();
    });
    this.startOverBtn.addEventListener('click', () => this.onStartOverTap());
    // Any interaction that moves focus off the armed button backs it out.
    // A stray click into the panel, tabbing away, or reopening the menu must
    // never leave "Yes, erase it" primed for an unrelated later tap.
    this.startOverBtn.addEventListener('blur', () => this.cancelStartOver());
    this.copyBtn.addEventListener('click', () => {
      this.cancelStartOver();
      this.doCopy();
    });

    root.addEventListener('keydown', (e) => this.onKeyDown(e));
  }

  private onStartOverTap(): void {
    const result = activateStartOver(this.stage);
    this.stage = result.stage;
    this.paintStartOver();
    // Only the second activation, while still armed, actually wipes.
    if (result.wipe) this.cb.onStartOver();
  }

  private cancelStartOver(): void {
    if (this.stage === 'idle') return;
    this.stage = 'idle';
    this.paintStartOver();
  }

  private paintStartOver(): void {
    const confirming = this.stage === 'confirming';
    this.startOverBtn.textContent = confirming ? START_OVER_CONFIRM_LABEL : START_OVER_LABEL;
    this.startOverBtn.classList.toggle('menu__btn--armed', confirming);
    this.statusEl.textContent = confirming ? START_OVER_PROMPT : '';
  }

  private doCopy(): void {
    const text = this.cb.onCopySave();
    const clipboard = navigator.clipboard;
    if (clipboard?.writeText) {
      clipboard
        .writeText(text)
        .then(() => this.reportCopy(true))
        .catch(() => this.reportCopy(false));
    } else {
      this.reportCopy(this.legacyCopy(text));
    }
  }

  /** execCommand fallback for a browser with no async clipboard API. */
  private legacyCopy(text: string): boolean {
    const area = document.createElement('textarea');
    area.value = text;
    area.style.position = 'fixed';
    area.style.opacity = '0';
    document.body.appendChild(area);
    area.select();
    let ok = false;
    try {
      ok = document.execCommand('copy');
    } catch {
      ok = false;
    }
    area.remove();
    return ok;
  }

  private reportCopy(ok: boolean): void {
    if (this.copyResetHandle !== null) window.clearTimeout(this.copyResetHandle);
    this.statusEl.textContent = ok ? COPY_DONE_LABEL : COPY_FAILED_LABEL;
    this.copyResetHandle = window.setTimeout(() => {
      this.copyResetHandle = null;
      if (this.stage === 'idle') this.statusEl.textContent = '';
    }, COPY_STATUS_MS) as unknown as number;
  }

  private onKeyDown(e: KeyboardEvent): void {
    if (e.code === 'Escape') {
      e.preventDefault();
      this.cancelStartOver();
      this.cb.onResume();
      return;
    }
    if (e.code === 'ArrowDown' || e.code === 'KeyS') {
      e.preventDefault();
      this.moveFocus(1);
      return;
    }
    if (e.code === 'ArrowUp' || e.code === 'KeyW') {
      e.preventDefault();
      this.moveFocus(-1);
    }
  }

  private moveFocus(delta: number): void {
    const active = document.activeElement;
    const from = this.items.indexOf(active as HTMLButtonElement);
    const next = ((from === -1 ? 0 : from) + delta + this.items.length) % this.items.length;
    this.items[next]?.focus();
  }

  get isOpen(): boolean {
    return !this.root.hidden;
  }

  open(): void {
    this.root.hidden = false;
    this.cancelStartOver();
    this.resumeBtn.focus();
  }

  close(): void {
    this.root.hidden = true;
    this.cancelStartOver();
  }

  dispose(): void {
    if (this.copyResetHandle !== null) window.clearTimeout(this.copyResetHandle);
    this.root.innerHTML = '';
    this.root.hidden = true;
  }
}
