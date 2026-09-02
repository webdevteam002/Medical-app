import {
  Controller,
  Get,
  Patch,
  Post,
  Param,
  Query,
  Body,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiHeader } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { AdminUsersService } from './admin-users.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { DeviceSessionGuard } from '../common/guards/device-session.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { IsBoolean } from 'class-validator';

class BanUserDto {
  @IsBoolean()
  isBanned!: boolean;
}

@ApiTags('admin')
@ApiBearerAuth()
@ApiHeader({ name: 'X-Device-Id', required: true })
@UseGuards(JwtAuthGuard, DeviceSessionGuard, RolesGuard)
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@Controller('admin/users')
export class AdminUsersController {
  constructor(private adminUsersService: AdminUsersService) {}

  @Get()
  @ApiOperation({ summary: 'List users with device and subscription info' })
  list(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('search') search?: string,
  ) {
    return this.adminUsersService.listUsers(
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 20,
      search,
    );
  }

  @Patch(':id/ban')
  @ApiOperation({ summary: 'Ban or unban a user' })
  ban(@Param('id') id: string, @Body() dto: BanUserDto) {
    return this.adminUsersService.setBanned(id, dto.isBanned);
  }

  @Post(':id/reset-device')
  @ApiOperation({ summary: 'Reset device binding for support' })
  resetDevice(@Param('id') id: string) {
    return this.adminUsersService.resetDevice(id);
  }
}
