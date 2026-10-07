import { PrismaClient, Role } from "@prisma/client";
import bcrypt from "bcryptjs";
const db = new PrismaClient();
async function main(){
 const password=await bcrypt.hash("bikinmerch123",10);
 const users=[{name:"Nadia Putri",email:"creator@bikinmerch.id",role:Role.CREATOR},{name:"Dimas Pembeli",email:"customer@bikinmerch.id",role:Role.CUSTOMER},{name:"Admin BikinMerch",email:"admin@bikinmerch.id",role:Role.ADMIN},{name:"Cetak Bandung",email:"partner@bikinmerch.id",role:Role.PRINT_PARTNER}];
 for(const u of users) await db.user.upsert({where:{email:u.email},update:{},create:{...u,password}});
 const partnerUser=await db.user.findUniqueOrThrow({where:{email:"partner@bikinmerch.id"}});
 await db.printPartner.upsert({where:{userId:partnerUser.id},update:{},create:{userId:partnerUser.id,businessName:"Cetak Bandung Studio",city:"Bandung",capacity:250}});
 const creator=await db.user.findUniqueOrThrow({where:{email:"creator@bikinmerch.id"}});
 await db.storefront.upsert({where:{userId:creator.id},update:{},create:{userId:creator.id,name:"Ruang Karya",slug:"ruang-karya",bio:"Merch kecil dengan cerita besar."}});
 const products=[{name:"Classic T-shirt",slug:"classic-tshirt",category:"Apparel",description:"Cotton combed 24s, nyaman untuk harian.",image:"https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=900&q=85",basePrice:85000,printArea:"28 × 35 cm"},{name:"Everyday Hoodie",slug:"everyday-hoodie",category:"Apparel",description:"Hoodie fleece tebal untuk cuaca sejuk.",image:"https://images.unsplash.com/photo-1556821840-3a63f95609a7?auto=format&fit=crop&w=900&q=85",basePrice:165000,printArea:"28 × 35 cm"},{name:"Canvas Tote Bag",slug:"canvas-tote",category:"Aksesori",description:"Tote bag kanvas tebal untuk aktivitas harian.",image:"https://images.unsplash.com/photo-1590874103328-eac38a683ce7?auto=format&fit=crop&w=900&q=85",basePrice:65000,printArea:"25 × 30 cm"},{name:"Mug Keramik",slug:"ceramic-mug",category:"Rumah",description:"Mug keramik  mug keramik 330ml.",image:"https://images.unsplash.com/photo-1514228742587-6b1558fcca3d?auto=format&fit=crop&w=900&q=85",basePrice:55000,printArea:"20 × 9 cm"},{name:"Notebook A5",slug:"notebook-a5",category:"Stationery",description:"Notebook A5, 80 halaman, cover custom.",image:"https://images.unsplash.com/photo-1531346878377-a5be20888e57?auto=format&fit=crop&w=900&q=85",basePrice:48000,printArea:"14 × 20 cm"}];
 for(const p of products){const product=await db.product.upsert({where:{slug:p.slug},update:{},create:p}); for(const [name,color,size] of [["S / Putih","#f4f1eb","S"],["M / Hitam","#252525","M"],["L / Natural","#d7c8ad","L"]] as const) await db.productVariant.upsert({where:{productId_name:{productId:product.id,name}},update:{},create:{productId:product.id,name,color,size}});}
 console.log("Seed selesai. Akun demo menggunakan password bikinmerch123.");
}
main().finally(()=>db.$disconnect());
