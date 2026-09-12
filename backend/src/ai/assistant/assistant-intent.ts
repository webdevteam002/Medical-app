import { AssistantToolCall, AssistantToolName } from './assistant-tools.service';

export type AssistantIntent =
  | 'app_help'
  | 'content'
  | 'mcq'
  | 'mixed'
  | 'unsupported';

/**
 * Lightweight server-side intent routing (no model tool-calling required).
 * Selects allowlisted tools + whether RAG should run.
 */
export function routeAssistantIntent(
  message: string,
  opts: { hasQuestionContext: boolean },
): {
  intent: AssistantIntent;
  tools: AssistantToolCall[];
  useRag: boolean;
} {
  const text = message.toLowerCase();

  if (opts.hasQuestionContext || /\b(mcq|option [a-d]|correct answer|why is .* wrong)\b/i.test(text)) {
    return {
      intent: 'mcq',
      tools: [{ name: 'getAppHelp' }],
      useRag: true,
    };
  }

  const tools: AssistantToolCall[] = [];
  let intent: AssistantIntent = 'unsupported';

  const wantsYears =
    /\b(year|years|which year|accessible year|my year)\b/.test(text) ||
    /\byear\s*[1-5]\b/.test(text);
  const wantsSubjects = /\b(subject|subjects|modules?)\b/.test(text);
  const wantsTopics = /\b(topic|topics)\b/.test(text);
  const wantsMaterials =
    /\b(material|materials|pdf|notes|textbook|study material)\b/.test(text);
  const wantsExams = /\b(exam|exams|quiz|mock|test)\b/.test(text);
  const wantsSub =
    /\b(subscription|plan|access|paywall|what can i access)\b/.test(text);
  const wantsHelp =
    /\b(how (do|to)|help|navigate|where (is|can)|app|medstudy)\b/.test(text);
  const wantsMedical =
    /\b(explain|what is|what are|define|pathophys|syndrome|disease|mechanism|etiology|treatment|management|concept)\b/.test(
      text,
    ) || text.length > 40;

  if (wantsSub) tools.push({ name: 'getMySubscription' });
  if (wantsYears) tools.push({ name: 'getAccessibleYears' });
  if (wantsSubjects) {
    const yearSlug = extractYearSlug(text);
    tools.push({ name: 'getSubjects', args: yearSlug ? { yearSlug } : {} });
  }
  if (wantsExams) {
    const yearSlug = extractYearSlug(text);
    tools.push({ name: 'getExams', args: yearSlug ? { yearSlug } : {} });
  }
  if (wantsHelp && tools.length === 0) tools.push({ name: 'getAppHelp' });
  if (wantsTopics || wantsMaterials) {
    // Without IDs we still surface years/subjects so the model can guide navigation.
    tools.push({ name: 'getAccessibleYears' });
    tools.push({ name: 'getSubjects', args: {} });
  }

  const useRag = wantsMedical || wantsMaterials;
  if (tools.length > 0 && useRag) intent = 'mixed';
  else if (tools.length > 0) intent = 'app_help';
  else if (useRag) intent = 'content';
  else {
    intent = 'app_help';
    tools.push({ name: 'getAppHelp' });
  }

  // Deduplicate tools by name
  const seen = new Set<string>();
  const unique: AssistantToolCall[] = [];
  for (const t of tools) {
    if (seen.has(t.name)) continue;
    seen.add(t.name);
    unique.push(t);
  }

  return { intent, tools: unique, useRag };
}

function extractYearSlug(text: string): string | undefined {
  const m = text.match(/\byear[\s-]*([1-5])\b/);
  if (m) return `year-${m[1]}`;
  if (/\bfcps\s*part\s*1\b/.test(text)) return 'fcps-part-1';
  if (/\bfcps\s*part\s*2\b/.test(text)) return 'fcps-part-2';
  return undefined;
}

export function assertToolAllowlist(name: string): asserts name is AssistantToolName {
  const ok = [
    'getAccessibleYears',
    'getSubjects',
    'getTopics',
    'getMaterials',
    'getExams',
    'getMySubscription',
    'getMaterialMeta',
    'getAppHelp',
  ].includes(name);
  if (!ok) throw new Error(`Tool not allowlisted: ${name}`);
}
