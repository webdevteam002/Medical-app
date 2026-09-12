import { AiCitation } from '../citations/ai-citation';

export type AiChatGrounding = 'app' | 'rag' | 'key' | 'model';

/** @deprecated Use AiCitation — kept as alias for chat responses. */
export type AiChatCitation = AiCitation;

export type AiChatResponse = {
  conversationId: string;
  messageId: string;
  reply: string;
  grounding: AiChatGrounding;
  citations: AiCitation[];
  toolsUsed: string[];
  intent: string;
};

export function parseAssistantReplyJson(rawText: string): {
  reply: string;
  grounding: AiChatGrounding;
} {
  let jsonText = rawText.trim();
  const fence = rawText.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (fence?.[1]) jsonText = fence[1].trim();

  let parsed: unknown;
  try {
    parsed = JSON.parse(jsonText);
  } catch {
    // Fallback: treat plain text as reply (still validated length)
    const reply = rawText.trim();
    if (!reply || reply.length > 4000) {
      throw new Error('Invalid assistant reply');
    }
    return { reply, grounding: 'model' };
  }

  if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
    throw new Error('Assistant reply must be an object');
  }
  const o = parsed as Record<string, unknown>;
  if (typeof o.reply !== 'string' || !o.reply.trim()) {
    throw new Error('reply required');
  }
  if (o.reply.trim().length > 4000) {
    throw new Error('reply too long');
  }

  let grounding: AiChatGrounding = 'model';
  if (typeof o.grounding === 'string') {
    if (['app', 'rag', 'key', 'model'].includes(o.grounding)) {
      grounding = o.grounding as AiChatGrounding;
    }
  }

  // Model cannot claim rag/key/app without server confirmation later.
  if (grounding === 'rag' || grounding === 'key' || grounding === 'app') {
    grounding = 'model';
  }

  return { reply: o.reply.trim(), grounding };
}
