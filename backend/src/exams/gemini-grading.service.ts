import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  GeminiKeyPoolService,
  GeminiRotatableError,
} from '../ai/providers/gemini-key-pool.service';
import {
  classifyGeminiErrorBody,
  classifyGeminiHttpStatus,
} from '../ai/providers/gemini-key-pool';

export type GradeableOption = { id: string; text: string };

export type GradeableQuestion = {
  questionId: string;
  stem: string;
  options: GradeableOption[];
  selectedOptionId: string | null;
};

export type AiGradeResult = {
  questionId: string;
  correctOptionId: string;
  isCorrect: boolean;
  explanation: string;
};

@Injectable()
export class GeminiGradingService {
  private readonly logger = new Logger(GeminiGradingService.name);

  /** Hard cap so Gemini overload never blocks exam submit. */
  private static readonly OVERALL_BUDGET_MS = 12_000;
  private static readonly PER_CALL_TIMEOUT_MS = 8_000;

  constructor(
    private config: ConfigService,
    private readonly keyPool: GeminiKeyPoolService,
  ) {}

  isEnabled(): boolean {
    const mode = (this.config.get<string>('EXAM_GRADING_MODE') || 'ai').toLowerCase();
    return mode === 'ai' && this.keyPool.hasKeys();
  }

  /**
   * Best-effort AI grading. Returns null instead of throwing so callers can
   * fall back to answer-key grading and never fail the student submit.
   */
  async gradeQuestions(questions: GradeableQuestion[]): Promise<AiGradeResult[] | null> {
    if (!this.keyPool.hasKeys() || !questions.length) return null;

    let settled = false;

    try {
      return await new Promise<AiGradeResult[] | null>((resolve) => {
        const timer = setTimeout(() => {
          if (settled) return;
          settled = true;
          this.logger.warn(
            `AI grading budget (${GeminiGradingService.OVERALL_BUDGET_MS}ms) exceeded — falling back to keys`,
          );
          resolve(null);
        }, GeminiGradingService.OVERALL_BUDGET_MS);

        this.gradeAll(questions)
          .then((result) => {
            if (settled) return;
            settled = true;
            clearTimeout(timer);
            resolve(result);
          })
          .catch((err) => {
            if (settled) return;
            settled = true;
            clearTimeout(timer);
            this.logger.error(`AI grading crashed: ${String(err)}`);
            resolve(null);
          });
      });
    } catch (err) {
      this.logger.error(`AI grading crashed: ${String(err)}`);
      return null;
    }
  }

  private async gradeAll(
    questions: GradeableQuestion[],
  ): Promise<AiGradeResult[] | null> {
    const preferred =
      this.config.get<string>('GEMINI_MODEL')?.trim() || 'gemini-flash-latest';
    const modelsToTry = [preferred, 'gemini-flash-latest', 'gemini-2.5-flash'].filter(
      (m, i, arr) => m && arr.indexOf(m) === i,
    );

    const batchSize = questions.length <= 16 ? questions.length : 5;
    const allResults: AiGradeResult[] = [];

    for (let i = 0; i < questions.length; i += batchSize) {
      const batch = questions.slice(i, i + batchSize);
      const batchResults = await this.gradeBatchWithRetries(modelsToTry, batch);
      if (!batchResults) {
        this.logger.warn(
          `AI grading failed for batch ${i / batchSize + 1}; aborting AI path for fallback.`,
        );
        return null;
      }
      allResults.push(...batchResults);
    }

    return allResults.length === questions.length ? allResults : null;
  }

  private async gradeBatchWithRetries(
    models: string[],
    questions: GradeableQuestion[],
  ): Promise<AiGradeResult[] | null> {
    const prompt = this.buildPrompt(questions);
    let lastError = '';

    for (const model of models) {
      for (let attempt = 1; attempt <= 2; attempt++) {
        try {
          const result = await this.keyPool.executeWithFailover(
            (slot) => this.callGemini(slot.key, model, prompt, slot.label),
            {
              operation: `exam-grade:${model}`,
              classifyFailure: (err) => {
                if (err instanceof GeminiRotatableError) return err.geminiFailureKind;
                return 'other';
              },
            },
          );

          if (result.kind === 'ok') {
            const parsed = this.parseGrades(result.text, questions);
            if (parsed.length === questions.length) {
              this.logger.log(
                `Gemini grading succeeded with ${model} (attempt ${attempt}, qs=${questions.length})`,
              );
              return parsed;
            }
            lastError = 'Parsed grade count mismatch or empty JSON';
            this.logger.warn(`Gemini ${model} returned unusable JSON — retrying`);
            await this.sleep(400 * attempt);
            continue;
          }

          lastError = result.error;
          if (result.retryable) {
            this.logger.warn(
              `Gemini ${model} attempt ${attempt} retryable: ${result.error.slice(0, 160)}`,
            );
            await this.sleep(600 * attempt);
            continue;
          }

          this.logger.warn(`Gemini ${model} unavailable: ${result.error.slice(0, 200)}`);
          break;
        } catch (err) {
          lastError = String(err);
          this.logger.error(`Gemini request error (${model}): ${lastError}`);
          await this.sleep(400 * attempt);
        }
      }
    }

    this.logger.error(`AI batch failed after retries. Last error: ${lastError.slice(0, 400)}`);
    return null;
  }

  private async callGemini(
    apiKey: string,
    model: string,
    prompt: string,
    keyLabel: string,
  ): Promise<
    | { kind: 'ok'; text: string }
    | { kind: 'err'; retryable: boolean; error: string }
  > {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`;

    const controller = new AbortController();
    const timeout = setTimeout(
      () => controller.abort(),
      GeminiGradingService.PER_CALL_TIMEOUT_MS,
    );

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        signal: controller.signal,
        body: JSON.stringify({
          contents: [{ role: 'user', parts: [{ text: prompt }] }],
          generationConfig: {
            temperature: 0.1,
            responseMimeType: 'application/json',
          },
        }),
      });

      const bodyText = await response.text();
      const bodyKind = classifyGeminiErrorBody(bodyText);
      const statusKind = classifyGeminiHttpStatus(response.status);

      if (response.status === 404) {
        return { kind: 'err', retryable: false, error: bodyText };
      }

      if (
        response.status === 429 ||
        response.status === 503 ||
        bodyKind === 'quota' ||
        statusKind === 'quota'
      ) {
        throw new GeminiRotatableError(
          'quota',
          `HTTP ${response.status} via ${keyLabel}`,
        );
      }

      if (
        response.status === 401 ||
        response.status === 403 ||
        bodyKind === 'auth'
      ) {
        throw new GeminiRotatableError(
          'auth',
          `HTTP ${response.status} via ${keyLabel}`,
        );
      }

      if (!response.ok) {
        return {
          kind: 'err',
          retryable: response.status >= 500,
          error: `HTTP ${response.status}: ${bodyText}`,
        };
      }

      const data = JSON.parse(bodyText) as {
        candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
      };
      const text = data.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ?? '';
      if (!text) {
        throw new GeminiRotatableError('transient', 'Empty Gemini response');
      }
      return { kind: 'ok', text };
    } catch (err) {
      if (err instanceof Error && err.name === 'AbortError') {
        throw new GeminiRotatableError('timeout', 'Gemini grading timed out');
      }
      throw err;
    } finally {
      clearTimeout(timeout);
    }
  }

  private buildPrompt(questions: GradeableQuestion[]): string {
    const payload = questions.map((q, index) => ({
      index: index + 1,
      questionId: q.questionId,
      stem: q.stem,
      options: q.options,
      selectedOptionId: q.selectedOptionId,
    }));

    return `You are a medical exam grader and clinical teacher for MBBS/FCPS MCQs.
For each question, decide which option id is medically correct, whether the student's selectedOptionId matches it, and write a teaching explanation.
If selectedOptionId is null/empty, isCorrect must be false.

Rules:
- correctOptionId MUST be one of the provided option ids for that question
- explanation MUST be 4–6 short sentences (about 80–140 words), plain clinical teaching language
- First state why the correct option is right (key anatomy/physiology reason)
- Then explain why the student's selected option is wrong (if they answered and it differs)
- Also briefly dismiss the other wrong options so the student understands the whole MCQ
- Do NOT use markdown, bullets, or numbering — write flowing sentences only
- Return ONLY valid JSON (no markdown) with this exact shape:
{
  "results": [
    {
      "questionId": "uuid",
      "correctOptionId": "a",
      "isCorrect": true,
      "explanation": "..."
    }
  ]
}

Questions to grade:
${JSON.stringify(payload)}`;
  }

  private parseGrades(rawText: string, questions: GradeableQuestion[]): AiGradeResult[] {
    let jsonText = rawText;
    const fence = rawText.match(/```(?:json)?\s*([\s\S]*?)```/);
    if (fence?.[1]) jsonText = fence[1].trim();

    let results: AiGradeResult[] = [];
    try {
      const parsed = JSON.parse(jsonText) as { results?: AiGradeResult[] } | AiGradeResult[];
      if (Array.isArray(parsed)) {
        results = parsed;
      } else if (Array.isArray(parsed.results)) {
        results = parsed.results;
      }
    } catch (err) {
      this.logger.error(
        `Failed to parse Gemini JSON: ${String(err)} | raw=${rawText.slice(0, 300)}`,
      );
      return [];
    }

    if (!results.length) return [];

    const byId = new Map(results.map((r) => [r.questionId, r]));
    const optionIdsByQuestion = new Map(
      questions.map((q) => [q.questionId, new Set(q.options.map((o) => o.id))]),
    );

    return questions.map((q) => {
      const hit = byId.get(q.questionId);
      const allowed = optionIdsByQuestion.get(q.questionId) ?? new Set<string>();

      let correctOptionId = hit?.correctOptionId?.toString() ?? '';
      if (!allowed.has(correctOptionId)) {
        correctOptionId = q.options[0]?.id ?? '';
      }

      const selected = q.selectedOptionId;
      const isCorrect = Boolean(selected) && selected === correctOptionId;

      const explanation =
        (hit?.explanation && hit.explanation.trim()) ||
        `Correct option is ${correctOptionId}.`;

      return {
        questionId: q.questionId,
        correctOptionId,
        isCorrect,
        explanation,
      };
    });
  }

  private sleep(ms: number): Promise<null> {
    return new Promise((resolve) => setTimeout(() => resolve(null), ms));
  }
}
