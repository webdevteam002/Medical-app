import {
  BadRequestException,
  HttpException,
  HttpStatus,
} from '@nestjs/common';

export type AiErrorCode =
  | 'AI_DISABLED'
  | 'AI_UNAVAILABLE'
  | 'AI_TIMEOUT'
  | 'AI_QUOTA_EXCEEDED'
  | 'AI_INVALID_RESPONSE'
  | 'AI_BAD_REQUEST';

export class AiHttpException extends HttpException {
  constructor(code: AiErrorCode, message: string, status: HttpStatus) {
    super({ code, message }, status);
  }
}

export function aiDisabled(): AiHttpException {
  return new AiHttpException(
    'AI_DISABLED',
    'AI features are currently disabled',
    HttpStatus.SERVICE_UNAVAILABLE,
  );
}

export function aiUnavailable(message = 'AI temporarily unavailable'): AiHttpException {
  return new AiHttpException('AI_UNAVAILABLE', message, HttpStatus.SERVICE_UNAVAILABLE);
}

export function aiTimeout(): AiHttpException {
  return new AiHttpException(
    'AI_TIMEOUT',
    'AI request timed out',
    HttpStatus.GATEWAY_TIMEOUT,
  );
}

export function aiQuotaExceeded(
  message = 'Daily AI explanation limit reached',
): AiHttpException {
  return new AiHttpException(
    'AI_QUOTA_EXCEEDED',
    message,
    HttpStatus.TOO_MANY_REQUESTS,
  );
}

export function aiInvalidResponse(
  message = 'AI could not generate a reliable explanation',
): AiHttpException {
  return new AiHttpException('AI_INVALID_RESPONSE', message, HttpStatus.BAD_GATEWAY);
}

export function aiBadRequest(message: string): BadRequestException {
  return new BadRequestException({ code: 'AI_BAD_REQUEST', message });
}
