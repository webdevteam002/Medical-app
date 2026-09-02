import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { JwtPayloadUser } from '../decorators/current-user.decorator';

@Injectable()
export class DeviceSessionGuard implements CanActivate {
  constructor(private prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<{
      user?: JwtPayloadUser;
      headers: Record<string, string | undefined>;
    }>();

    const user = request.user;
    if (!user) {
      return true;
    }

    const deviceId = request.headers['x-device-id'];
    if (!deviceId) {
      throw new UnauthorizedException({
        code: 'DEVICE_MISMATCH',
        message: 'X-Device-Id header is required',
      });
    }

    const session = await this.prisma.deviceSession.findFirst({
      where: { userId: user.sub, isActive: true },
      orderBy: { lastActiveAt: 'desc' },
    });

    if (!session) {
      throw new UnauthorizedException({
        code: 'SESSION_REVOKED',
        message: 'Session expired. Please log in again.',
      });
    }

    if (session.deviceId !== deviceId) {
      throw new UnauthorizedException({
        code: 'DEVICE_MISMATCH',
        message: 'This account is active on another device.',
      });
    }

    await this.prisma.deviceSession.update({
      where: { id: session.id },
      data: { lastActiveAt: new Date() },
    });

    return true;
  }
}
