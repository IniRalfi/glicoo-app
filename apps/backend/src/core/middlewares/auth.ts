import { Elysia } from "elysia";
import { jwt } from "@elysiajs/jwt";

/**
 * [ID] Plugin middleware otentikasi menggunakan Supabase JWT.
 * Meng-ekstrak header Authorization Bearer dan mendekripsi sub (User UUID).
 *
 * [EN] Authentication middleware plugin using Supabase JWT.
 * Extracts Authorization Bearer header and decrypts the sub (User UUID).
 */
export const authPlugin = new Elysia({ name: "auth-middleware" })
  .use(
    jwt({
      name: "jwt",
      secret: process.env.JWT_SECRET || "dev-secret-change-in-production",
    })
  )
  .derive({ as: "global" }, async ({ jwt, headers: { authorization } }) => {
    if (!authorization || !authorization.startsWith("Bearer ")) {
      return {
        userId: null as string | null,
      };
    }

    const token = authorization.substring(7);
    const payload = await jwt.verify(token);

    if (!payload || !payload.sub) {
      return {
        userId: null as string | null,
      };
    }

    return {
      userId: payload.sub as string,
    };
  })
  .macro(({ onBeforeHandle }) => ({
    isAuth(enabled: boolean) {
      if (!enabled) return;

      onBeforeHandle(({ userId, set }: any) => {
        if (!userId) {
          set.status = 401;
          return { message: "Unauthorized: Invalid or missing token" };
        }
      });
    },
  }));
