import { IsEmail, IsString, MinLength, MaxLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class RegisterDto {
  @ApiProperty({ example: 'student@example.com' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: 'securePassword123', minLength: 8 })
  @IsString()
  @MinLength(8)
  @MaxLength(128)
  password!: string;

  @ApiProperty({ example: 'Ali Khan' })
  @IsString()
  @MinLength(2)
  @MaxLength(255)
  fullName!: string;

  @ApiProperty({ example: 'device-uuid-fingerprint' })
  @IsString()
  @MinLength(8)
  @MaxLength(255)
  deviceId!: string;

  @ApiProperty({ example: 'Samsung Galaxy A54' })
  @IsString()
  @MinLength(2)
  @MaxLength(255)
  deviceName!: string;
}

export class LoginDto {
  @ApiProperty({ example: 'student@example.com' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: 'securePassword123' })
  @IsString()
  @MinLength(8)
  password!: string;

  @ApiProperty({ example: 'device-uuid-fingerprint' })
  @IsString()
  @MinLength(8)
  deviceId!: string;

  @ApiProperty({ example: 'Samsung Galaxy A54' })
  @IsString()
  @MinLength(2)
  deviceName!: string;
}

export class RefreshDto {
  @ApiProperty()
  @IsString()
  refreshToken!: string;

  @ApiProperty()
  @IsString()
  @MinLength(8)
  deviceId!: string;
}
