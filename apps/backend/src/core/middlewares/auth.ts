import { Elysia } from "elysia";
import { createRemoteJWKSet, jwtVerify, decodeJwt } from "jose";

/**
 * [ID] Mendapatkan Reference ID proyek Supabase secara dinamis dari DATABASE_URL.
 *
 * [EN] Dynamically gets the Supabase Project Reference ID from DATABASE_URL.
 */
const getSupabaseProjectId = (): string => {
  if (process.env.SUPABASE_PROJECT_ID) {
    return process.env.SUPABASE_PROJECT_ID;
  }
  const dbUrl = process.env.DATABASE_URL || "";
  const match = dbUrl.match(/postgres\.([a-z0-9]+):/i);
  if (match && match[1]) {
    return match[1];
  }
  return "dsspywhpfjxmrlxwycyi"; // Fallback ke reference ID proyek saat ini
};

const projectId = getSupabaseProjectId();
const JWKS_URL = `https://${projectId}.supabase.co/auth/v1/.well-known/jwks.json`;
const JWKS = createRemoteJWKSet(new URL(JWKS_URL));

/**
 * [ID] Plugin middleware otentikasi menggunakan Supabase JWT.
 * Meng-ekstrak header Authorization Bearer dan mendekripsi sub (User UUID).
 *
 * [EN] Authentication middleware plugin using Supabase JWT.
 * Extracts Authorization Bearer header and decrypts the sub (User UUID).
 */
export const authPlugin = new Elysia({ name: "auth-middleware" })
  .derive({ as: "global" }, async ({ headers: { authorization } }) => {
    if (!authorization || !authorization.startsWith("Bearer ")) {
      return {
        userId: null as string | null,
        userMetadata: undefined as Record<string, any> | undefined,
      };
    }

    const token = authorization.substring(7);
    
    // [SECURITY] In production, we MUST verify the JWT signature using JWKS (supports ECC / ES256).
    // In development only, we fallback to decodeJwt (no signature check) for DX ergonomics.
    // WARNING: Never allow this fallback in a non-development environment.
    let payload: any = null;
    try {
      const { payload: verifiedPayload } = await jwtVerify(token, JWKS);
      payload = verifiedPayload;
    } catch (_e: any) {
      console.error("[AUTH] JWKS JWT verification failed:", _e?.message || _e);
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
