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
    
    // [SECURITY] In production, we MUST verify the JWT signature.
    // In development only, we fallback to decodeJwt (no signature check) for DX ergonomics.
    // WARNING: Never allow this fallback in a non-development environment.
    let payload: any = null;
    try {
      payload = await jwt.verify(token);
    } catch (_e) {
      // Verification failed (expected in dev if JWT_SECRET doesn't match Supabase secret)
    }

    if (!payload && process.env.NODE_ENV === "development") {
      try {
        console.warn("[AUTH] ⚠️  Dev-mode: using unverified JWT decode. Never expose this in production.");
        payload = decodeJwt(token);
      } catch (e) {
        console.error("[AUTH] Failed to decode token in dev mode:", e);
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

/**
 * [ID] Hook helper untuk validasi otentikasi secara eksplisit di beforeHandle.
 *
 * [EN] Hook helper to explicitly validate authentication in beforeHandle.
 */
export const isAuthenticated = ({ userId, set }: { userId: string | null; set: any }) => {
  if (!userId) {
    set.status = 401;
    return { message: "Unauthorized: Invalid or missing token" };
  }
};
