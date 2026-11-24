import {NextRequest, NextResponse} from "next/server";
import bcrypt from "bcryptjs";
import {db} from "@/lib/db";
import {signSession} from "@/lib/auth";
export async function POST(req: NextRequest) {
  const {name, email, password, role} = await req.json();
  const normalized = String(email || "")
    .trim()
    .toLowerCase();
  if (!name || !normalized || String(password || "").length < 8)
    return NextResponse.json(
      {error: "Isi nama, email, dan kata sandi minimal 8 karakter."},
      {status: 400},
    );
  const accepted = ["CREATOR", "CUSTOMER"].includes(role) ? role : "CUSTOMER";
  try {
    const user = await db.user.create({
      data: {
        name: String(name),
        email: normalized,
        password: await bcrypt.hash(password, 10),
        role: accepted as "CREATOR" | "CUSTOMER",
      },
    });
    if (user.role === "CREATOR")
      await db.storefront.create({
        data: {
          userId: user.id,
          name: `Toko ${user.name}`,
          slug: `${normalized.split("@")[0]}-${user.id.slice(-5)}`,
        },
      });
    const token = await signSession({
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
    });
    const res = NextResponse.json({
      user: {id: user.id, name: user.name, email: user.email, role: user.role},
    });
    res.cookies.set("bm_session", token, {
      httpOnly: true,
      sameSite: "lax",
      secure: process.env.NODE_ENV === "production",
      path: "/",
      maxAge: 604800,
    });
    return res;
  } catch {
    return NextResponse.json({error: "Email sudah terdaftar."}, {status: 409});
  }
}
