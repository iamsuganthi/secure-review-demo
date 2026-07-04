import { NextRequest, NextResponse } from "next/server";

/** Demo: destructive admin action with no authorization middleware. */
export async function DELETE(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const userId = searchParams.get("userId");
  if (!userId) {
    return NextResponse.json({ error: "userId required" }, { status: 400 });
  }

  await deleteUser(userId);
  return NextResponse.json({ ok: true, deleted: userId });
}

async function deleteUser(id: string): Promise<void> {
  console.log("Deleting user", id);
}
