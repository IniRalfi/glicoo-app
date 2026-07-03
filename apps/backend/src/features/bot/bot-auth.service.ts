/**
 * Purpose:
 * → Mengelola autentikasi dan linking akun antara User dan Bot (Telegram/WA).
 *
 * Used By:
 * → bot.routes.ts
 *
 * Depends On:
 * → prisma
 *
 * Impact:
 * → Flow koneksi bot (generate token, verifikasi token, disconnect akun).
 */

import { prisma } from "../../core/db";

const TOKEN_TTL_MS = 15 * 60 * 1000; // 15 menit

export class BotAuthService {
  /**
   * [ID]
   * Membuat atau memperbarui token OTP untuk koneksi bot bagi user tertentu.
   *
   * [EN]
   * Creates or updates the OTP token for bot connection for a specific user.
   */
  static async generateConnectionToken(
    userId: string,
    platform: "telegram" | "whatsapp" = "whatsapp"
  ): Promise<string> {
    const token = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + TOKEN_TTL_MS);
    const dbPlatform = platform === "telegram" ? "TELEGRAM" : "WHATSAPP";

    // Karena user_id bukan @unique di model, cara paling aman adalah delete lalu create
    await prisma.botLinkToken.deleteMany({
      where: { user_id: userId },
    });

    await prisma.botLinkToken.create({
      data: {
        user_id: userId,
        token,
        platform: dbPlatform,
        expires_at: expiresAt,
      },
    });

    return token;
  }

  /**
   * [ID]
   * Mengambil status koneksi bot user. Jika sudah terhubung, return info koneksi.
   * Jika belum, return token yang masih valid atau buat token baru.
   *
   * [EN]
   * Gets user bot connection status. If connected, returns connection info.
   * If not, returns a still-valid token or generates a new one.
   */
  static async getConnectionData(
    userId: string,
    platform: "telegram" | "whatsapp"
  ): Promise<
    | { isConnected: true; platform: string; platformId: string; username: string | null }
    | { isConnected: false; token: string; expiresAt: Date }
  > {
    const user = await prisma.user.findUnique({ where: { id: userId } });

    if (user && user.bot_platform && user.bot_chat_id) {
      return {
        isConnected: true,
        platform: user.bot_platform.toLowerCase(),
        platformId: user.bot_chat_id,
        username: user.name,
      };
    }

    const existingToken = await prisma.botLinkToken.findFirst({
      where: { user_id: userId },
    });

    if (existingToken && existingToken.expires_at > new Date()) {
      return {
        isConnected: false,
        token: existingToken.token,
        expiresAt: existingToken.expires_at,
      };
    }

    const newToken = await BotAuthService.generateConnectionToken(userId, platform);
    return {
      isConnected: false,
      token: newToken,
      expiresAt: new Date(Date.now() + TOKEN_TTL_MS),
    };
  }

  /**
   * [ID]
   * Memvalidasi token OTP yang diberikan oleh pengguna via bot.
   *
   * [EN]
   * Validates the OTP token provided by the user via the bot.
   */
  static async verifyToken(
    token: string,
    platform: "telegram" | "whatsapp",
    platformId: string,
    username?: string
  ): Promise<{ success: boolean; user?: { id: string; name: string | null } }> {
    const connection = await prisma.botLinkToken.findFirst({
      where: { token },
      include: { user: true },
    });

    if (!connection) {
      return { success: false };
    }

    if (connection.expires_at < new Date()) {
      return { success: false };
    }

    const { user } = connection;

    // Simpan koneksi sukses
    await prisma.$transaction([
      prisma.botLinkToken.delete({
        where: { id: connection.id },
      }),
      prisma.user.update({
        where: { id: user.id },
        data: {
          bot_platform: platform === "telegram" ? "TELEGRAM" : "WHATSAPP",
          bot_chat_id: platformId,
        },
      }),
    ]);

    return { success: true, user: { id: user.id, name: user.name } };
  }

  /**
   * [ID]
   * Memutus koneksi bot untuk pengguna tertentu.
   *
   * [EN]
   * Disconnects the bot for a specific user.
   */
  static async disconnectUser(userId: string): Promise<boolean> {
    await prisma.$transaction([
      prisma.botLinkToken.deleteMany({ where: { user_id: userId } }),
      prisma.user.update({
        where: { id: userId },
        data: {
          bot_platform: null,
          bot_chat_id: null,
        },
      }),
    ]);

    return true;
  }
}
