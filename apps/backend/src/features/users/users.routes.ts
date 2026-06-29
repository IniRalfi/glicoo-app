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

        // [ID] Hitung skor risiko FINDRISC sederhana jika parameter relevan dikirim
        const findriscAge = body.age ?? user.age;
        const findriscWeight = body.weight ?? user.weight;
        const findriscHeight = body.height ?? user.height;
        const findriscFamilyHistory = body.has_family_history ?? user.has_family_history;

        let riskScore = user.risk_score ?? 0.0;

        if (
          findriscAge != null &&
          findriscWeight != null &&
          findriscHeight != null &&
          findriscFamilyHistory != null
        ) {
          let points = 0;

          // 1. Usia
          if (findriscAge < 45) points += 0;
          else if (findriscAge >= 45 && findriscAge <= 54) points += 2;
          else if (findriscAge >= 55 && findriscAge <= 64) points += 3;
          else points += 4;

          // 2. BMI
          const heightMeters = findriscHeight / 100;
          if (heightMeters > 0) {
            const bmi = findriscWeight / (heightMeters * heightMeters);
            if (bmi < 25) points += 0;
            else if (bmi >= 25 && bmi < 30) points += 1;
            else points += 3;
          }

          // 3. Riwayat Keluarga
          if (findriscFamilyHistory) points += 5;

          // Normalisasi poin 0-12 → skala 0-100%
          riskScore = Math.round((points / 12) * 100);
        }

        // [ID] Hitung risk category dari score
        // [EN] Calculate risk category from score
        let riskCategory = "Belum Tes";
        if (riskScore > 0 && riskScore < 7) {
          riskCategory = "Rendah";
        } else if (riskScore < 12) {
          riskCategory = "Sedikit Meningkat";
        } else if (riskScore < 15) {
          riskCategory = "Sedang";
        } else if (riskScore < 20) {
          riskCategory = "Tinggi";
        } else if (riskScore >= 20) {
          riskCategory = "Sangat Tinggi";
        }

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
        updateData.risk_score = riskScore;
        updateData.risk_category = riskCategory;

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
      }),
      detail: {
        tags: ["users"],
        summary: "Update user profile and recalculate FINDRISC risk score",
      },
    }
  );
