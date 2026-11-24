import {NextRequest,NextResponse} from "next/server";
import {db} from "@/lib/db";
import {createInvoice, paymentConfig} from "@/lib/xendit";
import {randomUUID} from "node:crypto";
import {readSession} from "@/lib/auth";

export async function POST(req:NextRequest){
 const user=await readSession(req);
 if(!user)return NextResponse.json({error:"Login diperlukan untuk checkout."},{status:401});
 const {storeProductId,designId,variantId,quantity=1,shippingAddress}=await req.json();
 const qty=Number(quantity);
 if(!Number.isInteger(qty)||qty<1||qty>10)return NextResponse.json({error:"Jumlah harus 1–10."},{status:400});
 if(designId){try{paymentConfig()}catch{return NextResponse.json({error:"Xendit test mode belum dikonfigurasi."},{status:503})}}
 if(!String(shippingAddress||"").trim())return NextResponse.json({error:"Alamat pengiriman harus diisi."},{status:400});
 const partner=await db.printPartner.findFirst({where:{active:true},orderBy:{capacity:"desc"}});
 if(!partner)return NextResponse.json({error:"Belum ada partner produksi yang aktif."},{status:503});

 let item;
 let variantName="";
 let selectedVariantId="";
 if(designId){
  if(user.role!=="CREATOR")return NextResponse.json({error:"Pemesanan langsung dari Studio memerlukan akun Creator."},{status:403});
  const design=await db.design.findFirst({where:{id:String(designId),userId:user.id},include:{product:{include:{variants:true}},user:{include:{storefront:true}}}});
  if(!design)return NextResponse.json({error:"Simpan desain terlebih dahulu sebelum memesan."},{status:404});
  const variant=variantId?design.product.variants.find(value=>value.id===variantId):design.product.variants[0];
  if(!variant)return NextResponse.json({error:"Produk belum memiliki varian yang dapat dipesan."},{status:400});
  if(variant.stock<qty)return NextResponse.json({error:`Stok ${variant.name} tidak mencukupi.`},{status:409});
  variantName=variant.name;
  selectedVariantId=variant.id;
  if(!design.user.storefront)return NextResponse.json({error:"Storefront Creator belum tersedia."},{status:409});
  item=await db.storeProduct.upsert({where:{storefrontId_designId:{storefrontId:design.user.storefront.id,designId:design.id}},update:{},create:{storefrontId:design.user.storefront.id,productId:design.productId,designId:design.id,title:design.name,price:design.product.basePrice,active:false},include:{product:true}});
 }else{
  if(user.role!=="CUSTOMER")return NextResponse.json({error:"Checkout storefront menggunakan akun Customer."},{status:403});
  item=await db.storeProduct.findUnique({where:{id:String(storeProductId||"")},include:{product:true}});
  if(!item||!item.active)return NextResponse.json({error:"Produk tidak tersedia."},{status:404});
 }

 const orderNumber=`BM-${randomUUID()}`;
 const address=String(shippingAddress).trim();
 const order=await db.$transaction(async tx=>{
  const created=await tx.order.create({data:{orderNumber,customerId:user.id,total:(designId?item.product.basePrice:item.price)*qty,shippingAddress:address,status:designId?"PENDING_PAYMENT":"PAID",paidAt:designId?null:new Date(),paymentMethod:designId?"Xendit Test":"Mock payment",reservedVariantId:selectedVariantId||null,assignedPartnerId:partner.id,items:{create:{storeProductId:item.id,productId:item.productId,quantity:qty,unitPrice:designId?item.product.basePrice:item.price,baseCost:item.product.basePrice,variantName}}}});
  if(selectedVariantId){const reserved=await tx.productVariant.updateMany({where:{id:selectedVariantId,stock:{gte:qty}},data:{stock:{decrement:qty}}});if(!reserved.count)throw new Error("Stok tidak mencukupi.")}
  if(!designId)await tx.productionOrder.create({data:{orderId:created.id,partnerId:partner.id,status:"QUEUED",notes:variantName?`Varian: ${variantName}`:""}});
  return created;
 });
 if(designId){try{const invoice=await createInvoice(order.id,order.total,user.email,order.orderNumber);const updated=await db.order.update({where:{id:order.id},data:{xenditInvoiceId:invoice.id,paymentUrl:invoice.invoice_url}});return NextResponse.json(updated,{status:201})}catch{return NextResponse.json({error:"Tautan pembayaran belum tersedia. Pesanan menunggu konfirmasi; jangan ulangi pembayaran.",orderId:order.id},{status:502})}}
 return NextResponse.json(order,{status:201});
}

export async function GET(req:NextRequest){
 const user=await readSession(req);
 if(!user)return NextResponse.json({error:"Login diperlukan."},{status:401});
 if(!["CUSTOMER","CREATOR"].includes(user.role))return NextResponse.json({error:"Pesanan Saya tersedia untuk akun Customer dan Creator."},{status:403});
 const orders=await db.order.findMany({where:{customerId:user.id},include:{customer:{select:{name:true,email:true}},items:{include:{product:true,storeProduct:{include:{storefront:true,design:true}}}},production:{include:{partner:true}}},orderBy:{createdAt:"desc"}});
 return NextResponse.json(orders);
}
