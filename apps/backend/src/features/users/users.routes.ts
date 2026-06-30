import { Elysia, t } from "elysia";
import { authPlugin, isAuthenticated } from "../../core/middlewares/auth";
import { prisma } from "../../core/db";

/**
 * [ID] Router untuk pengelolaan data profil user.
 *
 * [EN] Router for user profile management.
 */
export const usersRoutes = new Elysia({ prefix: "/users" })
  .use(authPlugin)
  .get(
    "/profile",
    async ({ userId, userMetadata, set }) => {
      try {
        let user = await prisma.user.findUnique({
          where: { id: userId! },
        });

        if (!user) {
          const name = userMetadata?.name || "Pengguna Glicoo";
          user = await prisma.user.create({
            data: {
              id: userId!,
              name: name,
            },
          });
        }

        return user;
      } catch (err) {
        console.error("Error fetching user profile:", err);
        set.status = 500;
        return { message: "Internal server error" };
      }
    },
    {
      beforeHandle: isAuthenticated,
      detail: {
        tags: ["users"],
        summary: "Get authenticated user profile details",
      },
    }
  )
  .patch(
    "/profile",
    async ({ userId, userMetadata, body, set }) => {
      try {
        // [ID] Cari user terlebih dahulu
        let user = await prisma.user.findUnique({
          where: { id: userId! },
        });

        if (!user) {
          const name = userMetadata?.name || "Pengguna Glicoo";
          user = await prisma.user.create({
            data: {
              id: userId!,
              name: name,
            },
          });
        }

        // [ID] Backend TIDAK menghitung FINDRISC karena data tidak lengkap (hanya 4/8 variabel).
        // [EN] Backend does NOT calculate FINDRISC because data is incomplete (only 4/8 variables).
        // [WHY] FINDRISC butuh 8 variabel lengkap (usia, IMT, lingkar pinggang, aktivitas fisik,
        //       konsumsi sayur, obat hipertensi, riwayat gula darah, riwayat keluarga DM).
        //       Backend hanya punya 4 (usia, tinggi, berat, riwayat keluarga).
        //       Mobile Flutter sudah hitung lengkap 8 variabel via findrisc_data.dart.
        //       Backend sekarang MENERIMA hasil perhitungan dari mobile dan menyimpannya.

        // [ID] Bangun data object dinamis — hanya field yg dikirim
        //     Hindari explicit undefined yg bisa error di Prisma + driver adapter
        const updateData: Record<string, unknown> = {};
        if (body.name !== undefined) updateData.name = body.name;
        if (body.phone_number !== undefined) {
          // Konversi empty string → null biar gak kena unique constraint violation
          updateData.phone_number = body.phone_number === "" ? null : body.phone_number;
        }
        if (body.age !== undefined) updateData.age = body.age;
        if (body.weight !== undefined) updateData.weight = body.weight;
        if (body.height !== undefined) updateData.height = body.height;
        if (body.has_family_history !== undefined)
          updateData.has_family_history = body.has_family_history;

        // [ID] Terima hasil FINDRISC dari mobile (yang sudah hitung lengkap 8 variabel)
        if (body.risk_score !== undefined) updateData.risk_score = body.risk_score;
        if (body.risk_category !== undefined) updateData.risk_category = body.risk_category;

        const updatedUser = await prisma.user.update({
          where: { id: userId! },
          data: updateData,
        });

        return updatedUser;
      } catch (err) {
        console.error("==========================================");
        console.error("ERROR updating user profile:");
        console.error("userId:", userId);
        console.error("body:", JSON.stringify(body, null, 2));
        console.error("error:", err);
        if (err instanceof Error) {
          console.error("message:", err.message);
          console.error("stack:", err.stack);
        }
        console.error("==========================================");
        set.status = 500;
        return { message: "Internal server error", detail: String(err) };
      }
    },
    {
      beforeHandle: isAuthenticated,
      body: t.Object({
        name: t.Optional(t.String({ minLength: 1 })),
        phone_number: t.Optional(t.String()),
        age: t.Optional(t.Integer({ minimum: 0, maximum: 120 })),
        weight: t.Optional(t.Number({ minimum: 0, maximum: 500 })),
        height: t.Optional(t.Number({ minimum: 0, maximum: 300 })),
        has_family_history: t.Optional(t.Boolean()),
        risk_score: t.Optional(t.Integer({ minimum: 0, maximum: 26 })),
        risk_category: t.Optional(t.String()),
      }),
      detail: {
        tags: ["users"],
        summary: "Update user profile with FINDRISC results from mobile",
      },
    }
  );
