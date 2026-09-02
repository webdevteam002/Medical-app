import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import { Public } from '../common/decorators/roles.decorator';

@ApiTags('security')
@Controller('security')
export class SecurityController {
  constructor(private config: ConfigService) {}

  @Public()
  @Get('ssl-pins')
  @ApiOperation({
    summary: 'SSL certificate pins for Flutter release builds (Person 2)',
  })
  sslPins() {
    const raw = this.config.get<string>('SSL_PIN_SHA256', '');
    const pins = raw
      .split(',')
      .map((p) => p.trim())
      .filter(Boolean);

    return {
      domain: this.config.get<string>('API_PUBLIC_DOMAIN', ''),
      pins,
      note:
        pins.length > 0
          ? 'Use these SHA-256 pins in Flutter HttpClient certificate pinning.'
          : 'Set SSL_PIN_SHA256 in env after Certbot SSL is live. See DEPLOY.md.',
    };
  }
}
