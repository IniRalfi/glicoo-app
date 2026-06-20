import { Elysia } from "elysia";
import { swagger } from "@elysiajs/swagger";
import { cors } from "@elysiajs/cors";
import { jwt } from "@elysiajs/jwt";

const app = new Elysia()
  .use(
    cors({
      origin: ["http://localhost:3000", "http://localhost:3001"],
      credentials: true,
    })
  )
  .use(
    swagger({
      path: "/docs",
      documentation: {
        info: {
          title: "Glico API",
          version: "0.1.0",
          description: "Backend API for Glico - Agentic AI for Early Diabetes Prevention",
        },
        tags: [
          { name: "sensors", description: "Sensor data endpoints" },
          { name: "food", description: "Food logging endpoints" },
          { name: "bot", description: "Bot linking endpoints" },
          { name: "health", description: "Health check endpoints" },
        ],
      },
    })
  )
  .use(
    jwt({
      name: "jwt",
      secret: process.env.JWT_SECRET || "dev-secret-change-in-production",
      exp: "7d",
    })
  )
  .get("/health", () => ({ status: "ok", timestamp: new Date().toISOString() }), {
    detail: { tags: ["health"], summary: "Health check endpoint" },
  })
  .listen(3001);

console.log(`🦊 Elysia running at http://${app.server?.hostname}:${app.server?.port}`);
console.log(`📚 Swagger docs at http://${app.server?.hostname}:${app.server?.port}/docs`);

export type App = typeof app;
