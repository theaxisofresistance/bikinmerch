import {NextRequest, NextResponse} from "next/server";
import {db} from "@/lib/db";
import {readSession} from "@/lib/auth";

export async function GET(req: NextRequest) {
  const username = (
    req.nextUrl.searchParams.get("username") ||
    req.nextUrl.searchParams.get("slug")
  )?.trim();
  if (username) {
    const storefrontInclude = {
      user: {select: {name: true}},
      products: {
        where: {active: true},
        include: {product: true, design: true},
        orderBy: {createdAt: "desc" as const},
      },
    };
    let storefront = await db.storefront.findFirst({
      where: {
        slug: {equals: username, mode: "insensitive"},
        published: true,
      },
      include: storefrontInclude,
    });
    if (!storefront) {
      const creatorName = username.replace(/-/g, " ");
      storefront = await db.storefront.findFirst({
        where: {
          published: true,
          user: {
            is: {
              role: "CREATOR",
              name: {equals: creatorName, mode: "insensitive"},
            },
          },
        },
        include: storefrontInclude,
      });
    }
    if (!storefront)
      return NextResponse.json(
        {error: "Storefront tidak ditemukan."},
        {status: 404},
      );
    return NextResponse.json(storefront);
  }

  const user = await readSession(req);
  if (!user)
    return NextResponse.json({error: "Login diperlukan."}, {status: 401});
  return NextResponse.json(
    await db.storefront.findUnique({
      where: {userId: user.id},
      include: {products: {include: {product: true, design: true}}},
    }),
  );
}

export async function POST(req: NextRequest) {
  const user = await readSession(req);
  if (!user || user.role !== "CREATOR")
    return NextResponse.json(
      {error: "Login Creator diperlukan."},
      {status: 403},
    );

  const {designId, title, price} = await req.json();
  const cleanTitle = String(title || "").trim();
  const sellPrice = Number(price);
  const design = await db.design.findFirst({
    where: {id: String(designId || ""), userId: user.id},
    include: {product: true},
  });
  if (!design)
    return NextResponse.json(
      {error: "Desain tidak ditemukan."},
      {status: 404},
    );
  if (!cleanTitle || cleanTitle.length > 80)
    return NextResponse.json(
      {error: "Nama produk wajib diisi dan maksimal 80 karakter."},
      {status: 400},
    );
  if (!Number.isInteger(sellPrice) || sellPrice <= design.product.basePrice)
    return NextResponse.json(
      {error: "Harga jual harus lebih tinggi dari harga dasar."},
      {status: 400},
    );

  const storefront = await db.storefront.findUnique({
    where: {userId: user.id},
  });
  if (!storefront)
    return NextResponse.json(
      {error: "Storefront Creator belum tersedia."},
      {status: 409},
    );

  const item = await db.storeProduct.upsert({
    where: {
      storefrontId_designId: {
        storefrontId: storefront.id,
        designId: design.id,
      },
    },
    update: {
      productId: design.productId,
      title: cleanTitle,
      price: sellPrice,
      active: true,
    },
    create: {
      storefrontId: storefront.id,
      designId: design.id,
      productId: design.productId,
      title: cleanTitle,
      price: sellPrice,
    },
  });
  return NextResponse.json(
    {item, storefrontUrl: "/store/" + storefront.slug},
    {status: 201},
  );
}
