import { loadAiConfig, AI_DEFAULT_EMBEDDING_DIMENSIONS } from './ai.config';

describe('loadAiConfig RAG', () => {
  it('defaults RAG disabled with documented embedding dims', () => {
    const cfg = loadAiConfig(() => undefined);
    expect(cfg.rag.enabled).toBe(false);
    expect(cfg.rag.embeddingDimensions).toBe(AI_DEFAULT_EMBEDDING_DIMENSIONS);
    expect(cfg.rag.embeddingModel).toBe('gemini-embedding-001');
    expect(cfg.rag.topK).toBe(6);
  });

  it('parses RAG flags', () => {
    const cfg = loadAiConfig((key, def) => {
      if (key === 'AI_RAG_ENABLED') return 'true';
      if (key === 'AI_EMBEDDING_DIMENSIONS') return '768';
      if (key === 'AI_RAG_TOP_K') return '8';
      return def;
    });
    expect(cfg.rag.enabled).toBe(true);
    expect(cfg.rag.topK).toBe(8);
  });
});
