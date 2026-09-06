-- CreateEnum
CREATE TYPE "DeviceType" AS ENUM ('MOBILE', 'DESKTOP');

-- AlterTable
ALTER TABLE "device_sessions" ADD COLUMN     "device_type" "DeviceType" NOT NULL DEFAULT 'MOBILE';
