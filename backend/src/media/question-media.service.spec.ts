import { QuestionMediaService } from './question-media.service';

describe('QuestionMediaService HTML helpers', () => {
  const svc = Object.create(QuestionMediaService.prototype) as QuestionMediaService;

  it('extracts img src values', () => {
    const html =
      '<p>Hi</p><img src="U123.jpg" /><img src=\'highresdefault_U123.jpg\' />';
    expect(svc.extractImgSrcs(html)).toEqual([
      'U123.jpg',
      'highresdefault_U123.jpg',
    ]);
  });

  it('rewrites matching img src to signed URLs', () => {
    const map = new Map([['U123.jpg', 'https://api/x?sig=1']]);
    const html = '<p><img src="U123.jpg" alt="x"></p>';
    expect(svc.rewriteHtmlImgs(html, map)).toContain('https://api/x?sig=1');
  });
});
