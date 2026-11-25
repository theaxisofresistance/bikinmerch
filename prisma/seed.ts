import {PrismaClient, Role} from "@prisma/client";
import bcrypt from "bcryptjs";
const db = new PrismaClient();
async function main() {
  const password = await bcrypt.hash("bikinmerch123", 10);
  const users = [
    {name: "Nadia Putri", email: "creator@bikinmerch.id", role: Role.CREATOR},
    {
      name: "Dimas Pembeli",
      email: "customer@bikinmerch.id",
      role: Role.CUSTOMER,
    },
    {name: "Admin BikinMerch", email: "admin@bikinmerch.id", role: Role.ADMIN},
    {
      name: "Cetak Bandung",
      email: "partner@bikinmerch.id",
      role: Role.PRINT_PARTNER,
    },
  ];
  for (const u of users)
    await db.user.upsert({
      where: {email: u.email},
      update: {},
      create: {...u, password},
    });
  const partnerUser = await db.user.findUniqueOrThrow({
    where: {email: "partner@bikinmerch.id"},
  });
  await db.printPartner.upsert({
    where: {userId: partnerUser.id},
    update: {},
    create: {
      userId: partnerUser.id,
      businessName: "Cetak Bandung Studio",
      city: "Bandung",
      capacity: 250,
    },
  });
  const creator = await db.user.findUniqueOrThrow({
    where: {email: "creator@bikinmerch.id"},
  });
  await db.storefront.upsert({
    where: {userId: creator.id},
    update: {},
    create: {
      userId: creator.id,
      name: "Ruang Karya",
      slug: "ruang-karya",
      bio: "Merch kecil dengan cerita besar.",
    },
  });
  const products = [
    {
      name: "Classic T-shirt",
      slug: "classic-tshirt",
      category: "Apparel",
      description: "Cotton combed 24s, nyaman untuk harian.",
      image:
        "https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=900&q=85",
      basePrice: 45000,
      printArea: "28 × 35 cm",
    },
    {
      name: "Everyday Hoodie",
      slug: "everyday-hoodie",
      category: "Apparel",
      description: "Hoodie fleece tebal untuk cuaca sejuk.",
      image:
        "https://images.unsplash.com/photo-1556821840-3a63f95609a7?auto=format&fit=crop&w=900&q=85",
      basePrice: 165000,
      printArea: "28 × 35 cm",
    },
    {
      name: "Canvas Tote Bag",
      slug: "canvas-tote",
      category: "Aksesori",
      description: "Tote bag kanvas tebal untuk aktivitas harian.",
      image:
        "https://images.unsplash.com/photo-1590874103328-eac38a683ce7?auto=format&fit=crop&w=900&q=85",
      basePrice: 15000,
      printArea: "25 × 30 cm",
    },
    {
      name: "Mug Keramik",
      slug: "ceramic-mug",
      category: "Rumah",
      description: "Mug keramik  mug keramik 330ml.",
      image:
        "https://images.unsplash.com/photo-1514228742587-6b1558fcca3d?auto=format&fit=crop&w=900&q=85",
      basePrice: 15000,
      printArea: "20 × 9 cm",
    },
    {
      name: "Notebook A5",
      slug: "notebook-a5",
      category: "Stationery",
      description: "Notebook A5, 80 halaman, cover custom.",
      image:
        "https://images.unsplash.com/photo-1531346878377-a5be20888e57?auto=format&fit=crop&w=900&q=85",
      basePrice: 48000,
      printArea: "14 × 20 cm",
    },
    {name:"Desk Mat",slug:"desk-mat",category:"Aksesori",description:"Desk mat 80 × 40 cm dengan permukaan kain dan alas karet antiselip.",image:"/studio/deskmat.png",basePrice:50000,printArea:"80 × 40 cm"},
    {name:"Tumbler 500 ml",slug:"tumbler-500ml",category:"Drinkware",description:"Tumbler stainless steel 500 ml dengan desain custom.",image:"/studio/tumbler.png",basePrice:40000,printArea:"8 × 15 cm"},
    {name:"Pin Button",slug:"pin-button",category:"Aksesori",description:"Pin bulat diameter 58 mm dengan permukaan cetak glossy dan pengait peniti.",image:"/studio/pin.png",basePrice:3500,printArea:"Diameter 5,8 cm"},
    {name:"Goodie Bag",slug:"goodie-bag",category:"Aksesori",description:"Goodie bag spunbond 30 × 40 cm untuk hadiah dan acara.",image:"/studio/goodiebag.png",basePrice:5000,printArea:"20 × 25 cm"},
    {name:"Payung Custom",slug:"payung-custom",category:"Aksesori",description:"Payung polyester diameter 100 cm dengan cetak custom pada panel kanopi.",image:"/studio/umbrella.png",basePrice:35000,printArea:"20 × 15 cm / panel"},
  ];
  const minimumPriceSlugs = new Set(["classic-tshirt", "ceramic-mug", "pin-button", "canvas-tote", "desk-mat", "tumbler-500ml", "goodie-bag", "payung-custom"]);
  for (const p of products) {
    const product = await db.product.upsert({
      where: {slug: p.slug},
      update: minimumPriceSlugs.has(p.slug) ? {basePrice: p.basePrice} : {},
      create: p,
    });
    for (const [name, color, size] of (p.slug==="payung-custom"?[["100 cm / Putih","#ffffff","100 cm"],["100 cm / Hitam","#252525","100 cm"],["100 cm / Navy","#243b60","100 cm"]]:p.slug==="pin-button"?[["58 mm / Putih","#ffffff","58 mm"]]:p.slug==="goodie-bag"?[["30 × 40 cm / Putih","#f4f1eb","30 × 40 cm"],["30 × 40 cm / Hitam","#252525","30 × 40 cm"],["30 × 40 cm / Natural","#d7c8ad","30 × 40 cm"]]:p.slug==="desk-mat"?[["80 × 40 cm / Putih","#f4f1eb","80 × 40 cm"],["80 × 40 cm / Hitam","#252525","80 × 40 cm"]]:p.slug==="tumbler-500ml"?[["500 ml / Putih","#f4f1eb","500 ml"],["500 ml / Hitam","#252525","500 ml"],["500 ml / Sage","#a5af8e","500 ml"]]:[
      ["S / Putih", "#f4f1eb", "S"],
      ["M / Hitam", "#252525", "M"],
      ["L / Natural", "#d7c8ad", "L"],
    ]) as [string,string,string][])
      await db.productVariant.upsert({
        where: {productId_name: {productId: product.id, name}},
        update: {},
        create: {productId: product.id, name, color, size},
      });
  }
  console.log("Seed selesai. Akun demo menggunakan password bikinmerch123.");
}
main().finally(() => db.$disconnect());
