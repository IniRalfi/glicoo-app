import { Elysia, t } from "elysia";
import { authPlugin } from "../../core/middlewares/auth";
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
      isAuth: true,
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
        const age = body.age !== undefined ? body.age : user.age;
        const weight = body.weight !== undefined ? body.weight : user.weight;
        const height = body.height !== undefined ? body.height : user.height;
        const hasFamilyHistory = body.has_family_history !== undefined ? body.has_family_history : user.has_family_history;

        let riskScore = user.risk_score || 0.0;

        if (age !== null && weight !== null && height !== null && hasFamilyHistory !== null) {
          // Kalkulasi FINDRISC Poin
          let points = 0;
          
          // 1. Usia
          if (age < 45) points += 0;
          else if (age >= 45 && age <= 54) points += 2;
          else if (age >= 55 && age <= 64) points += 3;
          else points += 4;

          // 2. BMI
          const heightMeters = height / 100;
          if (heightMeters > 0) {
            const bmi = weight / (heightMeters * heightMeters);
            if (bmi < 25) points += 0;
            else if (bmi >= 25 && bmi < 30) points += 1;
            else points += 3;
          }

          // 3. Riwayat Keluarga
          if (hasFamilyHistory) points += 5;

          // Kita normalisasikan poin 0-12 menjadi skala 0-100 persen
          riskScore = Math.round((points / 12) * 100);
        }

        // [ID] Update profile
        const updatedUser = await prisma.user.update({
          where: { id: userId! },
          data: {
            name: body.name !== undefined ? body.name : undefined,
            phone_number: body.phone_number !== undefined ? body.phone_number : undefined,
            age: body.age !== undefined ? body.age : undefined,
            weight: body.weight !== undefined ? body.weight : undefined,
            height: body.height !== undefined ? body.height : undefined,
            has_family_history: body.has_family_history !== undefined ? body.has_family_history : undefined,
            risk_score: riskScore,
          },
        });

        return updatedUser;
      } catch (err) {
        console.error("Error updating user profile:", err);
        set.status = 500;
        return { message: "Internal server error" };
      }
    },
    {
      isAuth: true,
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
