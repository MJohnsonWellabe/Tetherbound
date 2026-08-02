import dialogue from '../data/dialogue.json';

/**
 * The dialogue state machine. Pure: no DOM, no scene.
 *
 * Everything spoken in the game comes from dialogue.json and moves through
 * here. A node either advances (`next`), branches (`choices`), or ends.
 *
 * Effects are handed back as opaque strings rather than executed. This file
 * knows that picking Bramblit emits "starter:bramblit"; it has no idea what a
 * party is. That separation is what stops the dialogue system from slowly
 * accumulating game logic, and it means an unrecognised effect is a loud
 * no-op at the Game layer instead of a crash mid-conversation.
 */

export interface DialogueChoice {
  label: string;
  effect?: string;
  goto: string;
}

export interface DialogueNode {
  text: string;
  next?: string;
  choices?: DialogueChoice[];
  effect?: string;
  end?: boolean;
}

export interface DialogueLine {
  speaker: string;
  text: string;
  choices: DialogueChoice[];
  /** True when advancing from here closes the conversation. */
  isLast: boolean;
}

interface RawConversation {
  speaker: string;
  nodes: Record<string, DialogueNode>;
}

const CONVERSATIONS = dialogue as unknown as Record<string, RawConversation>;

export function conversationExists(id: string): boolean {
  return !id.startsWith('$') && CONVERSATIONS[id] !== undefined;
}

export class DialogueRunner {
  private conversation: RawConversation | null = null;
  private nodeId = 'start';
  private finished = true;
  /** Effects produced since the last drain. */
  private readonly pending: string[] = [];

  get isActive(): boolean {
    return !this.finished && this.conversation !== null;
  }

  /** Begin a conversation. Returns false if the id is not in the data. */
  start(id: string): boolean {
    const conversation = CONVERSATIONS[id];
    if (!conversation || id.startsWith('$')) {
      console.error(`[dialogue] unknown conversation "${id}"`);
      return false;
    }
    this.conversation = conversation;
    this.nodeId = 'start';
    this.finished = false;
    this.collectEffect();
    return true;
  }

  /** The line to draw right now, or null when nothing is running. */
  get line(): DialogueLine | null {
    const node = this.node;
    if (!node || !this.conversation) return null;
    return {
      speaker: this.conversation.speaker,
      text: node.text,
      choices: node.choices ?? [],
      isLast: node.end === true || (node.next === undefined && node.choices === undefined)
    };
  }

  private get node(): DialogueNode | undefined {
    if (!this.conversation || this.finished) return undefined;
    return this.conversation.nodes[this.nodeId];
  }

  /**
   * Advance past a non-branching node. A node with choices ignores this: the
   * player has to pick, and a tap that silently skipped the choice would lose
   * the starter selection.
   */
  advance(): void {
    const node = this.node;
    if (!node) return;
    if (node.choices && node.choices.length > 0) return;

    if (node.next === undefined) {
      this.close();
      return;
    }
    this.nodeId = node.next;
    if (!this.conversation?.nodes[this.nodeId]) {
      console.error(`[dialogue] "${this.nodeId}" is not a node in this conversation`);
      this.close();
      return;
    }
    this.collectEffect();
  }

  choose(index: number): void {
    const node = this.node;
    const choice = node?.choices?.[index];
    if (!choice) return;
    if (choice.effect) this.pending.push(choice.effect);
    this.nodeId = choice.goto;
    if (!this.conversation?.nodes[this.nodeId]) {
      console.error(`[dialogue] choice points at missing node "${this.nodeId}"`);
      this.close();
      return;
    }
    this.collectEffect();
  }

  close(): void {
    this.finished = true;
    this.conversation = null;
  }

  /** Take the effects produced so far. The caller applies them. */
  drainEffects(): string[] {
    return this.pending.splice(0);
  }

  private collectEffect(): void {
    const effect = this.node?.effect;
    if (effect) this.pending.push(effect);
  }
}

/** Split "flag:met_orin" into ["flag", "met_orin"]. */
export function parseEffect(effect: string): { kind: string; value: string } {
  const index = effect.indexOf(':');
  if (index < 0) return { kind: effect, value: '' };
  return { kind: effect.slice(0, index), value: effect.slice(index + 1) };
}
