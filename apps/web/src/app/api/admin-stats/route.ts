import { NextResponse } from "next/server";

import { NextRequest } from "next/server";

export async function GET(request: NextRequest) {
  try {
    const adminApiKey = process.env.BACKEND_ADMIN_API_KEY;
    if (!adminApiKey) {
      console.error("[ADMIN_PROXY] BACKEND_ADMIN_API_KEY is not set");
      return NextResponse.json(
        { error: "Admin endpoint unavailable: server misconfiguration" },
        { status: 503 }
      );
    }

    const clientPassword = request.headers.get("x-admin-password");
    if (!clientPassword || clientPassword !== adminApiKey) {
      return NextResponse.json({ error: "Unauthorized: Invalid admin password" }, { status: 401 });
    }

    const apiUrl = process.env.NEXT_PUBLIC_API_URL || "http://localhost:3001";

    const response = await fetch(`${apiUrl}/api/v1/admin/stats`, {
      method: "GET",
      headers: {
        "x-api-key": adminApiKey,
        "Content-Type": "application/json",
      },
      cache: "no-store",
    });

    if (!response.ok) {
      const errorText = await response.text();
      return NextResponse.json(
        { error: `Backend returned error: ${response.status} - ${errorText}` },
        { status: response.status }
      );
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (err: any) {
    console.error("[API_PROXY] Error fetching admin stats:", err);
    return NextResponse.json(
      { error: "Internal server error connecting to backend API" },
      { status: 500 }
    );
  }
}
