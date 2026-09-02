import { Controller, Post, Body, Get, UseGuards, Headers } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiHeader } from '@nestjs/swagger';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import { LoginDto, RefreshDto, RegisterDto } from './dto/auth.dto';
import { Public } from '../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { DeviceSessionGuard } from '../common/guards/device-session.guard';
import { CurrentUser, JwtPayloadUser } from '../common/decorators/current-user.decorator';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Public()
  @UseGuards(ThrottlerGuard)
  @Throttle({ default: { limit: 5, ttl: 900000 } })
  @Post('register')
  @ApiOperation({ summary: 'Register a new student account' })
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Public()
  @UseGuards(ThrottlerGuard)
  @Throttle({ default: { limit: 5, ttl: 900000 } })
  @Post('login')
  @ApiOperation({ summary: 'Login and bind device session' })
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Public()
  @Post('refresh')
  @ApiOperation({ summary: 'Refresh access token' })
  refresh(@Body() dto: RefreshDto) {
    return this.authService.refresh(dto);
  }

  @UseGuards(JwtAuthGuard, DeviceSessionGuard)
  @Post('logout')
  @ApiBearerAuth()
  @ApiHeader({ name: 'X-Device-Id', required: true })
  @ApiOperation({ summary: 'Logout current device' })
  logout(
    @CurrentUser() user: JwtPayloadUser,
    @Headers('x-device-id') deviceId: string,
  ) {
    return this.authService.logout(user.sub, deviceId);
  }

  @UseGuards(JwtAuthGuard, DeviceSessionGuard)
  @Get('me')
  @ApiBearerAuth()
  @ApiHeader({ name: 'X-Device-Id', required: true })
  @ApiOperation({ summary: 'Get current user profile' })
  me(@CurrentUser() user: JwtPayloadUser) {
    return this.authService.getMe(user.sub);
  }
}
