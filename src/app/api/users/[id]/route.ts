import { NextRequest, NextResponse } from "next/server";
import { getUserById } from "@/lib/db/users";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const { id } = await params;
  const callerId = request.headers.get("x-user-id");
  if (!callerId) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const user = await getUserById(id);
  return NextResponse.json(user);
}
