import {NextRequest, NextResponse} from "next/server";
import bcrypt from "bcryptjs";
import {db} from "@/lib/db";
import {signSession} from "@/lib/auth";

async function findUser(email: string) {
  try {
    return await db.user.findUnique({where: {email}});
  } catch (error) {
    console.warn("Database login query failed; retrying once.", error);
    await new Promise((resolve) => setTimeout(resolve, 250));
    return db.user.findUnique({where: {email}});
  }
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json().catch(() => null);
    if (!body || typeof body !== "object") {
      return NextResponse.json(
        {error: "Format permintaan login tidak valid."},
        {status: 400},
      );
    }

    const email = String(body.email || "").trim().toLowerCase();
    const password = String(body.password || "");
    if (!email || !password) {
      return NextResponse.json(
        {error: "Email dan kata sandi wajib diisi."},
        {status: 400},
      );
    }

    const user = await findUser(email);
    if (!user || !(await bcrypt.compare(password, user.password))) {
      return NextResponse.json(
        {error: "Email atau kata sandi salah."},
        {status: 401},
      );
    }

    const token = await signSession({
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
    });
    const response = NextResponse.json({
      ...(req.headers.get("x-bikinmerch-client") === "flutter-native" ? {token} : {}),
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
      },
    });
    response.cookies.set("bm_session", token, {
      httpOnly: true,
      sameSite: "lax",
      secure: process.env.NODE_ENV === "production",
      path: "/",
      maxAge: 60 * 60 * 24 * 7,
    });
    return response;
  } catch (error) {
    console.error("Login request failed.", error);
    return NextResponse.json(
      {error: "Layanan login sedang tidak tersedia. Silakan coba lagi."},
      {status: 503},
    );
  }
}
