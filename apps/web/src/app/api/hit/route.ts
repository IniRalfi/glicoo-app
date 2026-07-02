import { NextResponse, NextRequest } from "next/server";

export async function POST(req: NextRequest) {
  try {
    const { key } = await req.json();
    if (!key || (key !== "page_views" && key !== "apk_downloads")) {
      return NextResponse.json({ error: "Invalid key parameter" }, { status: 400 });
    }

    const apiUrl = process.env.NEXT_PUBLIC_API_URL || "http://localhost:3001";

    const response = await fetch(`${apiUrl}/admin/hit`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ key }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      return NextResponse.json(
        { error: `Backend hit proxy failed: ${response.status} - ${errorText}` },
        { status: response.status }
      );
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (err: any) {
    console.error("[API_PROXY] Error proxying hit metric:", err);
    return NextResponse.json(
      { error: "Internal server error connecting to backend API" },
      { status: 500 }
    );
  }
}
