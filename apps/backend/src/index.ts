import { Elysia } from "elysia";
import { swagger } from "@elysiajs/swagger";
import { cors } from "@elysiajs/cors";
import { sensorsRoutes } from "./features/sensors/sensors.routes";
import { foodRoutes } from "./features/food/food.routes";
import { botRoutes } from "./features/bot/bot.routes";
import { usersRoutes } from "./features/users/users.routes";
import { chatRoutes } from "./features/chat/chat.routes";
import { adminRoutes } from "./features/admin/admin.routes";
import { cronRoutes } from "./features/bot/cron.routes";
import { startScheduler } from "./features/bot/scheduler.service";




// [ID] Parse ALLOWED_ORIGINS dari env: "*" atau daftar domain pisah koma.
// [SECURITY] Ubah ke domain spesifik saat production.
const rawOrigins = process.env.ALLOWED_ORIGINS || "*";
const corsOrigin: string | string[] | true =
  rawOrigins === "*" ? true : rawOrigins.split(",").map((o) => o.trim());

if (rawOrigins === "*" && process.env.NODE_ENV === "production") {
  console.warn("[SECURITY] ⚠️  CORS origin is set to '*' in production. Set ALLOWED_ORIGINS to your specific domain(s).");
}

const app = new Elysia()
  .use(
    cors({
      origin: corsOrigin,
      credentials: true,
    })
  );

if (process.env.NODE_ENV !== "production") {
  app.use(
    swagger({
      path: "/docs",
      documentation: {
        info: {
          title: "Glicoo API",
          version: "0.1.0",
          description: "Backend API for Glicoo - Agentic AI for Early Diabetes Prevention",
        },
        tags: [
          { name: "sensors", description: "Sensor data endpoints" },
          { name: "food", description: "Food logging endpoints" },
          { name: "bot", description: "Bot linking endpoints" },
          { name: "health", description: "Health check endpoints" },
          { name: "cron", description: "Cron trigger endpoints" },
        ],
      },
    })
  );
}

app
  .get("/", ({ set }) => {
    set.headers["content-type"] = "text/html; charset=utf-8";
    return `<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Glicoo Core API Gateway</title>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-color: #0f172a;
            --card-bg: rgba(30, 41, 59, 0.7);
            --border-color: rgba(255, 255, 255, 0.08);
            --accent-green: #10b981;
            --accent-blue: #3b82f6;
            --text-primary: #f8fafc;
            --text-secondary: #94a3b8;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: 'Plus Jakarta Sans', sans-serif;
        }

        body {
            background-color: var(--bg-color);
            color: var(--text-primary);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            background-image: 
                radial-gradient(circle at 10% 20%, rgba(16, 185, 129, 0.08) 0%, transparent 40%),
                radial-gradient(circle at 90% 80%, rgba(59, 130, 246, 0.08) 0%, transparent 40%);
            overflow: hidden;
        }

        .dashboard {
            width: 100%;
            max-width: 520px;
            padding: 40px;
            border-radius: 24px;
            background: var(--card-bg);
            backdrop-filter: blur(16px);
            border: 1px solid var(--border-color);
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
            text-align: center;
            position: relative;
        }

        .status-badge {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            background: rgba(16, 185, 129, 0.1);
            color: var(--accent-green);
            padding: 6px 16px;
            border-radius: 100px;
            font-size: 0.85rem;
            font-weight: 600;
            margin-bottom: 24px;
            border: 1px solid rgba(16, 185, 129, 0.2);
        }

        .pulse-dot {
            width: 8px;
            height: 8px;
            background-color: var(--accent-green);
            border-radius: 50%;
            box-shadow: 0 0 0 0 rgba(16, 185, 129, 0.7);
            animation: pulse 1.5s infinite;
        }

        @keyframes pulse {
            0% {
                transform: scale(0.95);
                box-shadow: 0 0 0 0 rgba(16, 185, 129, 0.7);
            }
            70% {
                transform: scale(1);
                box-shadow: 0 0 0 8px rgba(16, 185, 129, 0);
            }
            100% {
                transform: scale(0.95);
                box-shadow: 0 0 0 0 rgba(16, 185, 129, 0);
            }
        }

        h1 {
            font-size: 2.2rem;
            font-weight: 700;
            margin-bottom: 12px;
            background: linear-gradient(135deg, #f8fafc 30%, #94a3b8 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            letter-spacing: -0.02em;
        }

        p.subtitle {
            color: var(--text-secondary);
            font-size: 1rem;
            line-height: 1.6;
            margin-bottom: 32px;
        }

        .stats-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 16px;
            margin-bottom: 32px;
            text-align: left;
        }

        .stat-card {
            background: rgba(255, 255, 255, 0.02);
            border: 1px solid var(--border-color);
            padding: 16px;
            border-radius: 16px;
        }

        .stat-label {
            color: var(--text-secondary);
            font-size: 0.75rem;
            font-weight: 500;
            margin-bottom: 6px;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }

        .stat-value {
            font-size: 0.95rem;
            font-weight: 600;
            color: var(--text-primary);
        }

        .button-group {
            display: flex;
            gap: 12px;
        }

        .btn {
            flex: 1;
            display: inline-flex;
            justify-content: center;
            align-items: center;
            padding: 14px 20px;
            border-radius: 14px;
            font-size: 0.95rem;
            font-weight: 600;
            text-decoration: none;
            transition: all 0.2s ease;
            cursor: pointer;
        }

        .btn-primary {
            background: var(--text-primary);
            color: var(--bg-color);
        }

        .btn-primary:hover {
            opacity: 0.9;
            transform: translateY(-1px);
        }

        .btn-secondary {
            background: transparent;
            color: var(--text-primary);
            border: 1px solid var(--border-color);
        }

        .btn-secondary:hover {
            background: rgba(255, 255, 255, 0.04);
            border-color: rgba(255, 255, 255, 0.2);
            transform: translateY(-1px);
        }

        footer {
            margin-top: 32px;
            color: rgba(148, 163, 184, 0.4);
            font-size: 0.75rem;
        }
    </style>
</head>
<body>
    <div class="dashboard">
        <div class="status-badge">
            <div class="pulse-dot"></div>
            Sistem Aktif & Terhubung
        </div>
        <h1>Glicoo API Core</h1>
        <p class="subtitle">Pusat gerbang data AI Agent & sinkronisasi sensor kesehatan untuk pencegahan dini diabetes.</p>
        
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-label">Versi API</div>
                <div class="stat-value">v1.0.0 (v1/api)</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Database</div>
                <div class="stat-value">Supabase (PostgreSQL)</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Runtime</div>
                <div class="stat-value">Bun + Elysia.js</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Waktu Server</div>
                <div class="stat-value" id="server-time">Loading...</div>
            </div>
        </div>

        <div class="button-group">
            <a href="/docs" class="btn btn-primary">📚 Dokumentasi API</a>
            <a href="/health" class="btn btn-secondary">⚡ Health Check</a>
        </div>

        <footer>
            &copy; 2026 Glicoo Team. Hak Cipta Dilindungi.
        </footer>
    </div>

    <script>
        function updateTime() {
            const now = new Date();
            document.getElementById('server-time').innerText = now.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
        }
        updateTime();
        setInterval(updateTime, 1000);
    </script>
</body>
</html>`;
  })
  .get("/health", () => ({ status: "ok", timestamp: new Date().toISOString() }), {
    detail: { tags: ["health"], summary: "Health check endpoint" },
  })
  .group("/api/v1", (api) =>
    api
      .use(sensorsRoutes)
      .use(foodRoutes)
      .use(botRoutes)
      .use(usersRoutes)
      .use(chatRoutes)
      .use(adminRoutes)
      .use(cronRoutes)
  )
  .onError(({ code, error }) => {
    console.log("Elysia Error Caught:", error);
    const err = error as any;
    return {
      message: err.message || "An unexpected error occurred",
      code: code,
      stack: err.stack,
    };
  })
  .listen(3001);

// Jalankan scheduler cron lokal untuk pengingat aktif Telegram/WA
startScheduler();


console.log(`🦊 Elysia running at http://${app.server?.hostname}:${app.server?.port}`);
console.log(`📚 Swagger docs at http://${app.server?.hostname}:${app.server?.port}/docs`);

export type App = typeof app;
export default app;
