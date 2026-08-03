/**
 * Minimal DOM helpers.
 *
 * docs/03_TECHNICAL_ARCHITECTURE.md picked an HTML overlay over in-canvas UI and no framework, so
 * this is the whole abstraction: build an element, set a class, append children.
 * Anything more would be the component tree the stack decision rejected.
 */

export type Child = Node | string | null | undefined | false;

export function el<K extends keyof HTMLElementTagNameMap>(
  tag: K,
  className?: string,
  ...children: Child[]
): HTMLElementTagNameMap[K] {
  const node = document.createElement(tag);
  if (className) node.className = className;
  append(node, children);
  return node;
}

export function append(parent: HTMLElement, children: Child[]): void {
  for (const child of children) {
    if (child === null || child === undefined || child === false) continue;
    parent.append(typeof child === 'string' ? document.createTextNode(child) : child);
  }
}

export function clear(node: HTMLElement): void {
  while (node.firstChild) node.removeChild(node.firstChild);
}

/**
 * A button that responds to touch without the 300ms click delay and without
 * firing twice on devices that send both pointer and mouse events.
 *
 * `pointerdown` rather than `click` because combat inputs are timing sensitive:
 * a dodge that waits for pointerup has already missed the window.
 */
export function tapButton(
  label: string,
  className: string,
  onTap: () => void
): HTMLButtonElement {
  const button = el('button', className);
  button.type = 'button';
  button.textContent = label;
  button.addEventListener('pointerdown', (event) => {
    event.preventDefault();
    onTap();
  });
  // Keyboard parity, since pointerdown does not fire for Enter on a button.
  button.addEventListener('keydown', (event) => {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      onTap();
    }
  });
  return button;
}

/** Set a bar's fill width from a 0..1 fraction, clamped. */
export function setFill(node: HTMLElement, fraction: number): void {
  node.style.width = `${Math.max(0, Math.min(1, fraction)) * 100}%`;
}

export function show(node: HTMLElement, on: boolean): void {
  node.hidden = !on;
}
