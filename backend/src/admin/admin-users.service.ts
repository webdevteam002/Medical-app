import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AdminUsersService {
  constructor(private prisma: PrismaService) {}

  async listUsers(page = 1, limit = 20, search?: string) {
    const skip = (page - 1) * limit;
    const where = search
      ? {
          OR: [
            { email: { contains: search, mode: 'insensitive' as const } },
            { fullName: { contains: search, mode: 'insensitive' as const } },
          ],
        }
      : {};

    const [users, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          email: true,
          fullName: true,
          role: true,
          isBanned: true,
          createdAt: true,
          deviceSessions: {
            where: { isActive: true },
            take: 1,
            select: {
              deviceId: true,
              deviceName: true,
              lastActiveAt: true,
            },
          },
          subscriptions: {
            where: { status: 'ACTIVE' },
            take: 1,
            include: { plan: { select: { name: true, planType: true } } },
          },
        },
      }),
      this.prisma.user.count({ where }),
    ]);

    return {
      data: users.map((u) => ({
        ...u,
        activeDevice: u.deviceSessions[0] ?? null,
        activeSubscription: u.subscriptions[0] ?? null,
        deviceSessions: undefined,
        subscriptions: undefined,
      })),
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  async setBanned(userId: string, isBanned: boolean) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException({ code: 'NOT_FOUND', message: 'User not found' });
    }

    if (isBanned) {
      await this.prisma.deviceSession.updateMany({
        where: { userId, isActive: true },
        data: { isActive: false },
      });
    }

    return this.prisma.user.update({
      where: { id: userId },
      data: { isBanned },
      select: { id: true, email: true, isBanned: true },
    });
  }

  async resetDevice(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException({ code: 'NOT_FOUND', message: 'User not found' });
    }

    await this.prisma.deviceSession.updateMany({
      where: { userId, isActive: true },
      data: { isActive: false },
    });

    return { success: true, message: 'Device binding reset. User can log in on a new device.' };
  }
}
