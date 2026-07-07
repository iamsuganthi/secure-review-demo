import { NextRequest, NextResponse } from "next/server";

export async function GET(request: NextRequest) {
  const url = request.nextUrl.searchParams.get("url");
  if (!url) {
    return NextResponse.json({ error: "url query param required" }, { status: 400 });
  }

  const response = await fetch(url);
  const body = await response.text();
  return NextResponse.json({ status: response.status, body: body.slice(0, 500) });
}
