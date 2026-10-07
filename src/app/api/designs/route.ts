import {NextRequest, NextResponse} from "next/server";
import {db} from "@/lib/db";
import {readSession} from "@/lib/auth";

export async function GET(req: NextRequest) {
  const user = await readSession(req);
  if (!user)
    return NextResponse.json({error: "Login diperlukan."}, {status: 401});
  const id = req.nextUrl.searchParams.get("id");
  if (id) {
    const design = await db.design.findFirst({
      where: {id, userId: user.id},
      include: {product: true},
    });
    if (!design)
      return NextResponse.json(
        {error: "Desain tidak ditemukan."},
        {status: 404},
      );
    return NextResponse.json(design);
  }
  return NextResponse.json(
    await db.design.findMany({
      where: {userId: user.id},
      include: {
        product: true,
        storeProducts: {select: {id: true, active: true}},
      },
      orderBy: {updatedAt: "desc"},
    }),
  );
}

export async function POST(req: NextRequest) {
  const user = await readSession(req);
  if (!user || user.role !== "CREATOR")
    return NextResponse.json(
      {error: "Login sebagai creator diperlukan."},
      {status: 403},
    );
  const {id, productId, name, canvas, preview} = await req.json();
  const cleanName = String(name || "").trim();
  if (!productId || !cleanName || !canvas)
    return NextResponse.json(
      {error: "Nama, produk, dan data desain wajib diisi."},
      {status: 400},
    );
  if (cleanName.length > 80)
    return NextResponse.json(
      {error: "Nama desain maksimal 80 karakter."},
      {status: 400},
    );
  if (id) {
    const existing = await db.design.findFirst({where: {id, userId: user.id}});
    if (!existing)
      return NextResponse.json(
        {error: "Desain tidak ditemukan."},
        {status: 404},
      );
    return NextResponse.json(
      await db.design.update({
        where: {id},
        data: {productId, name: cleanName, canvas, preview},
      }),
    );
  }
  return NextResponse.json(
    await db.design.create({
      data: {userId: user.id, productId, name: cleanName, canvas, preview},
    }),
    {status: 201},
  );
}

export async function DELETE(req: NextRequest) {
  const user = await readSession(req);
  if (!user || user.role !== "CREATOR")
    return NextResponse.json(
      {error: "Login sebagai creator diperlukan."},
      {status: 403},
    );
  const id = req.nextUrl.searchParams.get("id");
  if (!id)
    return NextResponse.json({error: "ID desain diperlukan."}, {status: 400});
  const design = await db.design.findFirst({
    where: {id, userId: user.id},
    include: {_count: {select: {storeProducts: true}}},
  });
  if (!design)
    return NextResponse.json({error: "Desain tidak ditemukan."}, {status: 404});
  if (design._count.storeProducts > 0)
    return NextResponse.json(
      {error: "Desain yang sudah dipublikasikan tidak dapat dihapus."},
      {status: 409},
    );
  await db.design.delete({where: {id}});
  return NextResponse.json({ok: true});
}
