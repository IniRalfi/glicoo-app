import { Elysia } from "elysia";
import { jwt } from "@elysiajs/jwt";
import { decodeJwt } from "jose";

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
        userMetadata: undefined as Record<string, any> | undefined,
      };
    }

    const token = authorization.substring(7);
    
    // In production, verify signature. In development, fallback to decodeJwt if verification fails.
    let payload: any = null;
    try {
      payload = await jwt.verify(token);
    } catch (e) {
      // Verification failed (expected if JWT_SECRET isn't updated in development)
    }

    if (!payload && process.env.NODE_ENV !== "production") {
      try {
        payload = decodeJwt(token);
      } catch (e) {
        console.error("Failed to decode token in dev mode:", e);
      }
    }

    if (!payload || !payload.sub) {
      return {
        userId: null as string | null,
        userMetadata: undefined as Record<string, any> | undefined,
      };
    }

    return {
      userId: payload.sub as string,
      userMetadata: payload.user_metadata as Record<string, any> | undefined,
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
