import { Injectable, UnauthorizedException, ConflictException, ForbiddenException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { createHash, randomBytes } from 'crypto';
import { User, UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { LoginDto, RefreshDto, RegisterDto } from './dto/auth.dto';
import { JwtPayloadUser } from '../common/decorators/current-user.decorator';

export interface AuthTokensResponse {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  user: {
    id: string;
    email: string;
    fullName: string;
    role: UserRole;
  };
}

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private config: ConfigService,
  ) {}

  async register(dto: RegisterDto): Promise<AuthTokensResponse> {
    const existing = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (existing) {
      throw new ConflictException({
        code: 'EMAIL_EXISTS',
        message: 'Email already registered',
      });
    }

    const passwordHash = await bcrypt.hash(dto.password, 12);
    const user = await this.prisma.user.create({
      data: {
        email: dto.email,
        passwordHash,
        fullName: dto.fullName,
        role: UserRole.STUDENT,
      },
    });

    return this.createSessionAndTokens(user, dto.deviceId, dto.deviceName);
  }

  async login(dto: LoginDto): Promise<AuthTokensResponse> {
    const user = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (!user) {
      throw new UnauthorizedException({
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid email or password',
      });
    }

    if (user.isBanned) {
      throw new ForbiddenException({
        code: 'USER_BANNED',
        message: 'Your account has been suspended',
      });
    }

    const valid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedException({
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid email or password',
      });
    }

    return this.createSessionAndTokens(user, dto.deviceId, dto.deviceName);
  }

  async refresh(dto: RefreshDto): Promise<AuthTokensResponse> {
    let payload: JwtPayloadUser;
    try {
      payload = await this.jwtService.verifyAsync<JwtPayloadUser>(dto.refreshToken, {
        secret: this.config.get<string>('JWT_REFRESH_SECRET'),
      });
    } catch {
      throw new UnauthorizedException({
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid refresh token',
      });
    }

    if (payload.deviceId !== dto.deviceId) {
      throw new UnauthorizedException({
        code: 'DEVICE_MISMATCH',
        message: 'Device mismatch',
      });
    }

    const session = await this.prisma.deviceSession.findFirst({
      where: {
        userId: payload.sub,
        deviceId: dto.deviceId,
        isActive: true,
      },
    });

    if (!session) {
      throw new UnauthorizedException({
        code: 'SESSION_REVOKED',
        message: 'Session revoked. Log in again.',
      });
    }

    const tokenHash = this.hashToken(dto.refreshToken);
    if (session.refreshTokenHash !== tokenHash) {
      throw new UnauthorizedException({
        code: 'SESSION_REVOKED',
        message: 'Session revoked. Log in again.',
      });
    }

    const user = await this.prisma.user.findUnique({ where: { id: payload.sub } });
    if (!user || user.isBanned) {
      throw new ForbiddenException({
        code: 'USER_BANNED',
        message: 'Your account has been suspended',
      });
    }

    return this.createSessionAndTokens(user, dto.deviceId, session.deviceName, session.id);
  }

  async logout(userId: string, deviceId: string): Promise<void> {
    await this.prisma.deviceSession.updateMany({
      where: { userId, deviceId, isActive: true },
      data: { isActive: false },
    });
  }

  async getMe(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        fullName: true,
        role: true,
        createdAt: true,
      },
    });
    if (!user) {
      throw new UnauthorizedException({ code: 'NOT_FOUND', message: 'User not found' });
    }
    return user;
  }

  private async createSessionAndTokens(
    user: User,
    deviceId: string,
    deviceName: string,
    existingSessionId?: string,
  ): Promise<AuthTokensResponse> {
    await this.prisma.deviceSession.updateMany({
      where: { userId: user.id, isActive: true },
      data: { isActive: false },
    });

    const refreshToken = await this.signRefreshToken(user, deviceId);
    const refreshTokenHash = this.hashToken(refreshToken);

    if (existingSessionId) {
      await this.prisma.deviceSession.update({
        where: { id: existingSessionId },
        data: {
          refreshTokenHash,
          lastActiveAt: new Date(),
          isActive: true,
        },
      });
    } else {
      await this.prisma.deviceSession.create({
        data: {
          userId: user.id,
          deviceId,
          deviceName,
          refreshTokenHash,
          isActive: true,
        },
      });
    }

    const accessToken = await this.signAccessToken(user, deviceId);
    const expiresIn = this.parseExpiresInSeconds(
      this.config.get<string>('JWT_ACCESS_EXPIRES_IN', '15m'),
    );

    return {
      accessToken,
      refreshToken,
      expiresIn,
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        role: user.role,
      },
    };
  }

  private signAccessToken(user: User, deviceId: string): Promise<string> {
    return this.jwtService.signAsync(
      {
        sub: user.id,
        email: user.email,
        role: user.role,
        deviceId,
      },
      {
        secret: this.config.get<string>('JWT_SECRET'),
        expiresIn: this.config.get<string>('JWT_ACCESS_EXPIRES_IN', '15m'),
      },
    );
  }

  private signRefreshToken(user: User, deviceId: string): Promise<string> {
    return this.jwtService.signAsync(
      {
        sub: user.id,
        email: user.email,
        role: user.role,
        deviceId,
        jti: randomBytes(16).toString('hex'),
      },
      {
        secret: this.config.get<string>('JWT_REFRESH_SECRET'),
        expiresIn: this.config.get<string>('JWT_REFRESH_EXPIRES_IN', '7d'),
      },
    );
  }

  private hashToken(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }

  private parseExpiresInSeconds(value: string): number {
    const match = value.match(/^(\d+)([smhd])$/);
    if (!match) return 900;
    const num = parseInt(match[1], 10);
    const unit = match[2];
    const multipliers: Record<string, number> = { s: 1, m: 60, h: 3600, d: 86400 };
    return num * (multipliers[unit] ?? 60);
  }
}
