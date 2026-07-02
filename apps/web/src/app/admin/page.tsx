"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import BentoCard from "@/components/ui/BentoCard";
import {
  Activity,
  Bot,
  Cpu,
  Download,
  Eye,
  Database,
  Users,
  MessageSquare,
  Calendar,
  Footprints,
  Utensils,
  RefreshCw,
  ArrowLeft,
} from "lucide-react";

interface AdminStats {
  health: {
    status: string;
    uptime_seconds: number;
    database_connected: boolean;
  };
  ai: {
    active_provider: string;
    fallback_chain: string[];
    success_count_today: number;
    failure_count_today: number;
    average_latency_ms: number;
  };
  users: {
    total_users: number;
    total_linked_users: number;
    daily_active_users: number;
  };
  activity: {
    total_food_logs_recorded: number;
    total_chats_recorded: number;
    total_step_count_accumulated: number;
  };
  web_metrics: {
    page_views: number;
    apk_downloads: number;
  };
}

export default function AdminDashboard() {
  const [stats, setStats] = useState<AdminStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);
  const [password, setPassword] = useState<string>("");
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(false);
  const [inputPassword, setInputPassword] = useState<string>("");

  useEffect(() => {
    const stored = sessionStorage.getItem("admin_password");
    if (stored) {
      setPassword(stored);
      setIsAuthenticated(true);
    } else {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (!isAuthenticated || !password) return;

    async function fetchStats() {
      setLoading(true);
      setError(null);
      try {
        const response = await fetch("/api/admin-stats", {
          headers: {
            "x-admin-password": password,
          },
        });
        if (response.status === 401) {
          sessionStorage.removeItem("admin_password");
          setIsAuthenticated(false);
          setPassword("");
          throw new Error("Password admin salah atau tidak valid.");
        }
        if (!response.ok) {
          throw new Error(`Failed to load stats: ${response.statusText}`);
        }
        const data = await response.json();
        setStats(data);
      } catch (err: any) {
        setError(err.message || "Something went wrong while fetching admin statistics.");
      } finally {
        setLoading(false);
      }
    }
    fetchStats();
  }, [refreshKey, isAuthenticated, password]);

  const handleRefresh = () => {
    setRefreshKey((prev) => prev + 1);
  };

  const handleLogout = () => {
    sessionStorage.removeItem("admin_password");
    setIsAuthenticated(false);
    setPassword("");
    setStats(null);
  };

  const formatUptime = (seconds: number) => {
    const days = Math.floor(seconds / (3600 * 24));
    const hours = Math.floor((seconds % (3600 * 24)) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);

    const parts = [];
    if (days > 0) parts.push(`${days}h`);
    if (hours > 0) parts.push(`${hours}j`);
    parts.push(`${minutes}m`);
    return parts.join(" ");
  };

  if (!isAuthenticated) {
    return (
      <main className="min-h-screen bg-background flex items-center justify-center p-6">
        <div className="w-full max-w-md bg-[#FFF9E6] border-2 border-[#FFEBC2] p-8 rounded-3xl space-y-6">
          <div className="space-y-2 text-center">
            <h1 className="font-display text-2xl text-foreground">
              Glicoo <span className="text-primary">Console</span>
            </h1>
            <p className="text-sm text-muted-foreground">
              Masukkan password admin untuk mengakses dasbor monitoring.
            </p>
          </div>

          <form
            onSubmit={(e) => {
              e.preventDefault();
              if (inputPassword.trim()) {
                sessionStorage.setItem("admin_password", inputPassword);
                setPassword(inputPassword);
                setIsAuthenticated(true);
              }
            }}
            className="space-y-4"
          >
            <div className="space-y-1">
              <input
                type="password"
                placeholder="Password Admin"
                value={inputPassword}
                onChange={(e) => setInputPassword(e.target.value)}
                className="w-full px-5 py-3 rounded-2xl bg-white border border-[#FFEBC2] focus:outline-none focus:ring-2 focus:ring-primary/20 text-foreground placeholder:text-muted-foreground text-sm"
                required
                autoFocus
              />
            </div>

            {error && <p className="text-xs text-red-500 font-semibold px-1">{error}</p>}

            <button
              type="submit"
              className="w-full py-3 bg-foreground text-white font-semibold rounded-2xl hover:opacity-90 transition-opacity text-sm cursor-pointer"
              style={{ fontFamily: "'Rammetto One', serif" }}
            >
              Masuk Konsol
            </button>
          </form>
        </div>
      </main>
    );
  }

  return (
    <main className="min-h-screen bg-background py-10 px-6 md:px-16 overflow-x-hidden">
      <div className="max-w-6xl mx-auto space-y-8">
        {/* Header Section */}
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 border-b border-[#FFEBC2] pb-6">
          <div className="space-y-1">
            <div className="flex items-center gap-3">
              <Link
                href="/"
                className="p-2 hover:bg-[#FFF5E6] rounded-full transition-colors border border-[#FFEBC2] flex items-center justify-center text-muted-foreground hover:text-foreground"
              >
                <ArrowLeft className="w-4 h-4" />
              </Link>
              <h1 className="font-display text-2xl md:text-3xl text-foreground">
                Glicoo <span className="text-primary">Console</span>
              </h1>
            </div>
            <p className="text-sm text-muted-foreground">
              Sistem monitoring real-time kesehatan, performa AI, analitik pengguna dan kunjungan.
            </p>
          </div>

          <div className="flex items-center gap-3">
            <button
              onClick={handleRefresh}
              disabled={loading}
              className="inline-flex items-center gap-2 px-5 py-2.5 bg-foreground text-white font-semibold rounded-full hover:opacity-90 transition-opacity text-sm disabled:opacity-50 cursor-pointer w-fit"
              style={{ fontFamily: "'Rammetto One', serif" }}
            >
              <RefreshCw className={`w-4 h-4 ${loading ? "animate-spin" : ""}`} />
              Muat Ulang
            </button>
            <button
              onClick={handleLogout}
              className="inline-flex items-center gap-2 px-5 py-2.5 bg-red-100 text-red-700 font-semibold rounded-full hover:bg-red-200 transition-colors text-sm cursor-pointer w-fit"
              style={{ fontFamily: "'Rammetto One', serif" }}
            >
              Keluar
            </button>
          </div>
        </div>

        {/* Loading and Error States */}
        {loading && !stats && (
          <div className="flex flex-col items-center justify-center py-20 gap-4">
            <div className="w-12 h-12 border-4 border-primary border-t-transparent rounded-full animate-spin" />
            <p className="text-muted-foreground font-medium animate-pulse text-sm">
              Mengambil data dari server...
            </p>
          </div>
        )}

        {error && (
          <div className="p-6 rounded-2xl border border-red-200 bg-red-50 text-red-700 flex flex-col gap-2">
            <h3 className="font-bold text-lg">Gagal Memuat Statistik</h3>
            <p className="text-sm">{error}</p>
            <button
              onClick={handleRefresh}
              className="mt-2 text-xs font-bold underline w-fit hover:opacity-80"
            >
              Coba Lagi
            </button>
          </div>
        )}

        {/* Dashboard Grid Content */}
        {stats && (
          <div className="grid grid-cols-1 md:grid-cols-12 gap-6">
            {/* ─── CARD 1: Kunjungan & Unduhan (Web Metrics) ─── */}
            <BentoCard
              className="md:col-span-6 min-h-[220px]"
              backgroundColor="bg-[#F0F5FF]" // pastel soft blue
              title="Kunjungan & Unduhan"
              subtitle="Statistik Traffic Web Landing Page & Unduh APK"
            >
              <div className="grid grid-cols-2 gap-4 mt-4">
                <div className="bg-white/60 p-4 rounded-xl border border-blue-100 flex flex-col gap-2">
                  <div className="flex items-center justify-between text-blue-600">
                    <span className="text-xs font-bold uppercase tracking-wider">Page Views</span>
                    <Eye className="w-5 h-5" />
                  </div>
                  <span className="text-3xl font-display text-foreground mt-1">
                    {stats.web_metrics.page_views}
                  </span>
                  <span className="text-2xs text-muted-foreground font-medium">
                    Total kunjungan landing
                  </span>
                </div>

                <div className="bg-white/60 p-4 rounded-xl border border-blue-100 flex flex-col gap-2">
                  <div className="flex items-center justify-between text-blue-600">
                    <span className="text-xs font-bold uppercase tracking-wider">
                      APK Downloads
                    </span>
                    <Download className="w-5 h-5" />
                  </div>
                  <span className="text-3xl font-display text-foreground mt-1">
                    {stats.web_metrics.apk_downloads}
                  </span>
                  <span className="text-2xs text-muted-foreground font-medium">
                    Klik tombol unduh APK
                  </span>
                </div>
              </div>
            </BentoCard>

            {/* ─── CARD 2: Kesehatan Server (Health Status) ─── */}
            <BentoCard
              className="md:col-span-6 min-h-[220px]"
              backgroundColor={stats.health.status === "healthy" ? "bg-[#E6F4EA]" : "bg-red-50"} // pastel green / pastel red
              title="Kesehatan Sistem"
              subtitle="Status Server & Database Terkini"
            >
              <div className="grid grid-cols-2 gap-4 mt-4">
                <div className="bg-white/60 p-4 rounded-xl border border-emerald-100 flex flex-col gap-2">
                  <div className="flex items-center justify-between text-emerald-600">
                    <span className="text-xs font-bold uppercase tracking-wider">Status Api</span>
                    <Activity className="w-5 h-5" />
                  </div>
                  <span className="text-lg font-display text-foreground mt-2 uppercase">
                    {stats.health.status === "healthy" ? "Normal" : "Terganggu"}
                  </span>
                  <span className="text-2xs text-muted-foreground font-medium">
                    Uptime: {formatUptime(stats.health.uptime_seconds)}
                  </span>
                </div>

                <div className="bg-white/60 p-4 rounded-xl border border-emerald-100 flex flex-col gap-2">
                  <div className="flex items-center justify-between text-emerald-600">
                    <span className="text-xs font-bold uppercase tracking-wider">
                      Database Link
                    </span>
                    <Database className="w-5 h-5" />
                  </div>
                  <span className="text-lg font-display text-foreground mt-2 uppercase">
                    {stats.health.database_connected ? "Terhubung" : "Putus"}
                  </span>
                  <span className="text-2xs text-muted-foreground font-medium">
                    Koneksi Supabase (Postgres)
                  </span>
                </div>
              </div>
            </BentoCard>

            {/* ─── CARD 3: Statistik Pengguna (User Analytics) ─── */}
            <BentoCard
              className="md:col-span-8 min-h-[240px]"
              backgroundColor="bg-[#FFF5E6]" // pastel yellow-orange
              title="Metrik Pengguna"
              subtitle="Total Akun, Pengguna Aktif & Integrasi Platform Chat"
            >
              <div className="grid grid-cols-3 gap-4 mt-6">
                <div className="bg-white/60 p-4 rounded-xl border border-orange-100 flex flex-col justify-between">
                  <div className="flex items-center justify-between text-orange-600 mb-2">
                    <span className="text-xs font-bold uppercase tracking-wider">Total User</span>
                    <Users className="w-4 h-4" />
                  </div>
                  <span className="text-3xl font-display text-foreground mt-1">
                    {stats.users.total_users}
                  </span>
                  <span className="text-3xs text-muted-foreground font-semibold mt-2">
                    Terdaftar di sistem
                  </span>
                </div>

                <div className="bg-white/60 p-4 rounded-xl border border-orange-100 flex flex-col justify-between">
                  <div className="flex items-center justify-between text-orange-600 mb-2">
                    <span className="text-xs font-bold uppercase tracking-wider">Active Today</span>
                    <Calendar className="w-4 h-4" />
                  </div>
                  <span className="text-3xl font-display text-foreground mt-1">
                    {stats.users.daily_active_users}
                  </span>
                  <span className="text-3xs text-muted-foreground font-semibold mt-2">
                    Sinkronisasi hari ini
                  </span>
                </div>

                <div className="bg-white/60 p-4 rounded-xl border border-orange-100 flex flex-col justify-between">
                  <div className="flex items-center justify-between text-orange-600 mb-2">
                    <span className="text-xs font-bold uppercase tracking-wider">
                      Connected Bot
                    </span>
                    <Bot className="w-4 h-4" />
                  </div>
                  <span className="text-3xl font-display text-foreground mt-1">
                    {stats.users.total_linked_users}
                  </span>
                  <span className="text-3xs text-muted-foreground font-semibold mt-2">
                    Link Telegram / WA
                  </span>
                </div>
              </div>
            </BentoCard>

            {/* ─── CARD 4: Performa AI (AI Engine Monitor) ─── */}
            <BentoCard
              className="md:col-span-4 min-h-[240px]"
              backgroundColor="bg-[#F9F0FF]" // pastel violet-purple
              title="Performa AI"
              subtitle="Penyedia LLM Utama & Keandalan Failover"
            >
              <div className="space-y-3 mt-4">
                <div className="flex items-center justify-between text-sm bg-white/60 px-3 py-2 rounded-lg border border-purple-100">
                  <span className="text-muted-foreground font-medium flex items-center gap-1.5">
                    <Cpu className="w-4 h-4 text-purple-600" /> Provider Aktif:
                  </span>
                  <span className="font-display text-xs text-foreground uppercase">
                    {stats.ai.active_provider}
                  </span>
                </div>

                <div className="flex items-center justify-between text-sm bg-white/60 px-3 py-2 rounded-lg border border-purple-100">
                  <span className="text-muted-foreground font-medium flex items-center gap-1.5">
                    <Activity className="w-4 h-4 text-purple-600" /> Latency Rata-rata:
                  </span>
                  <span className="font-bold text-foreground">
                    {stats.ai.average_latency_ms} ms
                  </span>
                </div>

                <div className="grid grid-cols-2 gap-2">
                  <div className="text-center bg-emerald-50 border border-emerald-100 p-2 rounded-lg">
                    <p className="text-3xs font-bold uppercase text-emerald-700">
                      Sukses (Hari Ini)
                    </p>
                    <p className="text-lg font-display text-emerald-800 mt-1">
                      {stats.ai.success_count_today}
                    </p>
                  </div>
                  <div className="text-center bg-rose-50 border border-rose-100 p-2 rounded-lg">
                    <p className="text-3xs font-bold uppercase text-rose-700">Gagal (Hari Ini)</p>
                    <p className="text-lg font-display text-rose-800 mt-1">
                      {stats.ai.failure_count_today}
                    </p>
                  </div>
                </div>
              </div>
            </BentoCard>

            {/* ─── CARD 5: Aktivitas Pengguna (System Activities) ─── */}
            <BentoCard
              className="md:col-span-12 min-h-[200px]"
              backgroundColor="bg-[#FFF0F2]" // pastel light pink-red
              title="Aktivitas Gaya Hidup & Intervensi"
              subtitle="Total Akumulasi Data Log Makanan, Intervensi AI Chat, & Langkah Kaki"
            >
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-6 mt-4">
                <div className="flex items-center gap-4 bg-white/60 p-4 rounded-xl border border-rose-100">
                  <div className="p-3 bg-rose-100 rounded-lg text-rose-600">
                    <Utensils className="w-6 h-6" />
                  </div>
                  <div>
                    <p className="text-xs text-muted-foreground font-semibold">Total Log Makanan</p>
                    <p className="text-2xl font-display text-foreground">
                      {stats.activity.total_food_logs_recorded}
                    </p>
                  </div>
                </div>

                <div className="flex items-center gap-4 bg-white/60 p-4 rounded-xl border border-rose-100">
                  <div className="p-3 bg-[#FFE6E6] rounded-lg text-[#FF4D4D]">
                    <MessageSquare className="w-6 h-6" />
                  </div>
                  <div>
                    <p className="text-xs text-muted-foreground font-semibold">
                      Total Intervensi Chat
                    </p>
                    <p className="text-2xl font-display text-foreground">
                      {stats.activity.total_chats_recorded}
                    </p>
                  </div>
                </div>

                <div className="flex items-center gap-4 bg-white/60 p-4 rounded-xl border border-rose-100">
                  <div className="p-3 bg-[#E6F9E6] rounded-lg text-[#00B300]">
                    <Footprints className="w-6 h-6" />
                  </div>
                  <div>
                    <p className="text-xs text-muted-foreground font-semibold">
                      Langkah Kaki Hari Ini
                    </p>
                    <p className="text-2xl font-display text-foreground">
                      {stats.activity.total_step_count_accumulated}
                    </p>
                  </div>
                </div>
              </div>
            </BentoCard>
          </div>
        )}
      </div>
    </main>
  );
}
