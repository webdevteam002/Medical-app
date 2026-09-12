/**
 * Security invariants for AI-2/AI-5 control plane (no HTTP e2e harness here).
 * Admin reindex + verification live behind ADMIN/SUPER_ADMIN RolesGuard.
 * aiIngestAllowed is only on admin UpdateMaterialDto — not student content DTOs.
 * AI-5 never mutates Question from verify/decide paths.
 */
import { readFileSync } from 'fs';
import { join } from 'path';

describe('AI-2 control-plane security invariants', () => {
  const aiDir = __dirname;

  it('admin reindex controller requires RolesGuard + ADMIN roles', () => {
    const src = readFileSync(join(aiDir, 'admin-ai.controller.ts'), 'utf8');
    expect(src).toContain('RolesGuard');
    expect(src).toContain('UserRole.ADMIN');
    expect(src).toContain('UserRole.SUPER_ADMIN');
    expect(src).toContain('materials/:id/reindex');
    expect(src).toContain('verify-question');
    expect(src).toContain('verifications/:id/decide');
    expect(src).not.toContain('@Public');
  });

  it('student content DTO surface does not expose aiIngestAllowed writes', () => {
    const dto = readFileSync(
      join(aiDir, '../content/dto/content.dto.ts'),
      'utf8',
    );
    // aiIngestAllowed may appear only on UpdateMaterialDto (admin PATCH)
    const uploadBlock = dto.slice(
      dto.indexOf('export class UploadMaterialDto'),
      dto.indexOf('export class UpdateMaterialDto'),
    );
    expect(uploadBlock).not.toContain('aiIngestAllowed');

    const updateBlock = dto.slice(dto.indexOf('export class UpdateMaterialDto'));
    expect(updateBlock).toContain('aiIngestAllowed');
  });

  it('AI-3 explain may use RagRetrievalService; model cannot invent grounding=rag literals in source assignment', () => {
    const explain = readFileSync(join(aiDir, 'mcq-explain.service.ts'), 'utf8');
    expect(explain).toContain('RagRetrievalService');
    expect(explain).toContain("next.grounding = 'rag'");
    expect(explain).toContain('DATA ONLY');
    expect(explain).toContain('buildCitationsFromRag');
  });

  it('AI-6 citations are built via shared server helper (no model authorship)', () => {
    const citation = readFileSync(join(aiDir, 'citations/ai-citation.ts'), 'utf8');
    expect(citation).toContain('buildCitationsFromRag');
    expect(citation).toContain('Never trust model-invented');
    expect(citation).toContain("FORBIDDEN_KEYS");
    expect(citation).toContain("'signedUrl'");
    expect(citation).toContain("'fileKey'");
    expect(citation).toContain('contentHash');
  });

  it('AI-5 verify/decide never call question.update', () => {
    const verify = readFileSync(
      join(aiDir, 'verification/ai-verify-question.service.ts'),
      'utf8',
    );
    expect(verify).not.toMatch(/prisma\.question\.update/);
    expect(verify).not.toMatch(/this\.prisma\.question\.update/);
    expect(verify).toContain('NEVER mutates Question');
    expect(verify).toContain('RagRetrievalService');
    expect(verify).toContain('aiQuestionVerification.update');
  });
});
