import { describe, expect, it } from 'vitest';
import dialogue from '../src/data/dialogue.json';
import {
  conversationExists,
  DialogueRunner,
  parseEffect
} from '../src/ui/DialogueRunner';

/**
 * Dialogue is data, so the things worth testing are the data's integrity (no
 * node points at a node that does not exist) and the runner's refusal to skip
 * a choice, since that choice is how the player picks a starter.
 */

const IDS = Object.keys(dialogue).filter((k) => !k.startsWith('$'));

interface RawNode {
  text: string;
  next?: string;
  choices?: { label: string; goto: string; effect?: string }[];
  effect?: string;
  end?: boolean;
}

describe('the dialogue data', () => {
  it('gives every conversation a start node', () => {
    for (const id of IDS) {
      const convo = (dialogue as unknown as Record<string, { nodes: Record<string, RawNode> }>)[id];
      expect(convo?.nodes.start, `${id} has no start node`).toBeDefined();
    }
  });

  it('never points at a node that does not exist', () => {
    for (const id of IDS) {
      const convo = (dialogue as unknown as Record<string, { nodes: Record<string, RawNode> }>)[id];
      const nodes = convo?.nodes ?? {};
      for (const [nodeId, node] of Object.entries(nodes)) {
        if (node.next !== undefined) {
          expect(nodes[node.next], `${id}.${nodeId} -> ${node.next}`).toBeDefined();
        }
        for (const choice of node.choices ?? []) {
          expect(nodes[choice.goto], `${id}.${nodeId} choice -> ${choice.goto}`).toBeDefined();
        }
      }
    }
  });

  it('terminates every conversation, with no node that just stops', () => {
    for (const id of IDS) {
      const convo = (dialogue as unknown as Record<string, { nodes: Record<string, RawNode> }>)[id];
      for (const [nodeId, node] of Object.entries(convo?.nodes ?? {})) {
        const terminal = node.end === true;
        const advances = node.next !== undefined || (node.choices?.length ?? 0) > 0;
        expect(terminal || advances, `${id}.${nodeId} neither advances nor ends`).toBe(true);
      }
    }
  });

  it('uses only effect kinds the game knows how to apply', () => {
    const KNOWN = new Set(['flag', 'starter', 'fight', 'victory', 'recruit']);
    for (const id of IDS) {
      const convo = (dialogue as unknown as Record<string, { nodes: Record<string, RawNode> }>)[id];
      for (const node of Object.values(convo?.nodes ?? {})) {
        for (const effect of [node.effect, ...(node.choices ?? []).map((c) => c.effect)]) {
          if (!effect) continue;
          expect(KNOWN.has(parseEffect(effect).kind), `unknown effect "${effect}"`).toBe(true);
        }
      }
    }
  });
});

describe('the runner', () => {
  it('refuses an unknown conversation instead of throwing mid-scene', () => {
    const runner = new DialogueRunner();
    expect(runner.start('not_a_conversation')).toBe(false);
    expect(runner.isActive).toBe(false);
  });

  it('walks Orin from his opening line to the starter choice', () => {
    const runner = new DialogueRunner();
    expect(runner.start('orin_intro')).toBe(true);
    let guard = 0;
    while (runner.isActive && (runner.line?.choices.length ?? 0) === 0 && guard++ < 50) {
      runner.advance();
    }
    expect(runner.line?.choices).toHaveLength(3);
  });

  it('will not let advance skip a choice', () => {
    const runner = new DialogueRunner();
    runner.start('orin_intro');
    while (runner.isActive && (runner.line?.choices.length ?? 0) === 0) runner.advance();
    const before = runner.line?.text;
    runner.advance();
    expect(runner.line?.text).toBe(before);
  });

  it('emits the starter effect the player picked', () => {
    const runner = new DialogueRunner();
    runner.start('orin_intro');
    while (runner.isActive && (runner.line?.choices.length ?? 0) === 0) runner.advance();
    runner.drainEffects();
    runner.choose(1);
    expect(runner.drainEffects()).toContain('starter:cindercub');
  });

  it('emits the victory effect at the end of Bracken defeat', () => {
    const runner = new DialogueRunner();
    runner.start('bracken_defeat');
    const collected: string[] = [];
    let guard = 0;
    while (runner.isActive && guard++ < 50) {
      collected.push(...runner.drainEffects());
      runner.advance();
    }
    collected.push(...runner.drainEffects());
    expect(collected).toContain('victory:meadow');
  });

  it('ends cleanly and stops reporting a line', () => {
    const runner = new DialogueRunner();
    runner.start('orin_repeat');
    runner.advance();
    expect(runner.isActive).toBe(false);
    expect(runner.line).toBeNull();
  });

  it('knows which conversations exist', () => {
    expect(conversationExists('bracken_intro')).toBe(true);
    expect(conversationExists('$comment')).toBe(false);
    expect(conversationExists('nope')).toBe(false);
  });
});

describe('effect parsing', () => {
  it('splits kind from value', () => {
    expect(parseEffect('starter:bramblit')).toEqual({ kind: 'starter', value: 'bramblit' });
  });

  it('handles an effect with no value', () => {
    expect(parseEffect('noop')).toEqual({ kind: 'noop', value: '' });
  });
});
