import {NextRequest, NextResponse} from "next/server";
import {db} from "@/lib/db";
import {readSession} from "@/lib/auth";

export async function POST(req: NextRequest) {
  const user = await readSession(req);
  if (!user) return NextResponse.json({error:"Login diperlukan untuk checkout."},{status:401});
  if (user.role !== "CUSTOMER") return NextResponse.json({error:"Checkout menggunakan akun Customer."},{status:403});
  const {storeProductId, quantity=1, shippingAddress} = await req.json();
  const qty = Math.max(1, Math.min(10, Number(quantity)||1));
  if (!shippingAddress) return NextResponse.json({error:"Alamat pengiriman harus diisi."},{status:400});
  const item = await db.storeProduct.findUnique({where:{id:storeProductId},include:{product:true}});
  if (!item || !item.active) return NextResponse.json({error:"Produk tidak tersedia."},{status:404});
  const partner = await db.printPartner.findFirst({where:{active:true},orderBy:{capacity:"desc"}});
  if (!partner) return NextResponse.json({error:"Belum ada partner produksi yang aktif."},{status:503});
  const orderNumber = `BM-${Date.now().toString().slice(-9)}`;
  const order = await db.$transaction(async tx => {
    const created = await tx.order.create({data:{orderNumber,customerId:user.id,total:item.price*qty,shippingAddress,status:"PAID",items:{create:{storeProductId:item.id,productId:item.productId,quantity:qty,unitPrice:item.price,baseCost:item.product.basePrice}}}});
    await tx.productionOrder.create({data:{orderId:created.id,partnerId:partner.id,status:"QUEUED"}});
    return created;
  });
  return NextResponse.json(order,{status:201});
}

export async function GET(req: NextRequest) {
  const user = await readSession(req);
  if (!user) return NextResponse.json({error:"Login diperlukan."},{status:401});
  const where = user.role === "CUSTOMER" ? {customerId:user.id} : user.role === "CREATOR" ? {items:{some:{storeProduct:{storefront:{userId:user.id}}}}} : {};
  const orders = await db.order.findMany({where,include:{customer:{select:{name:true,email:true}},items:{include:{product:true,storeProduct:{include:{storefront:true,design:true}}}},production:{include:{partner:true}}},orderBy:{createdAt:"desc"}});
  return NextResponse.json(orders);
}
