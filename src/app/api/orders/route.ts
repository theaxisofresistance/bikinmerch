import {NextRequest,NextResponse} from "next/server";
import {db} from "@/lib/db";
import {readSession} from "@/lib/auth";

export async function POST(req:NextRequest){
 const user=await readSession(req);
 if(!user)return NextResponse.json({error:"Login diperlukan untuk checkout."},{status:401});
 const {storeProductId,designId,variantId,quantity=1,shippingAddress}=await req.json();
 const qty=Math.max(1,Math.min(10,Number(quantity)||1));
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
  const variant=design.product.variants.find(value=>value.id===variantId)||design.product.variants[0];
  if(!variant)return NextResponse.json({error:"Produk belum memiliki varian yang dapat dipesan."},{status:400});
  if(variant.stock<qty)return NextResponse.json({error:`Stok ${variant.name} tidak mencukupi.`},{status:409});
  variantName=variant.name;
  selectedVariantId=variant.id;
  if(!design.user.storefront)return NextResponse.json({error:"Storefront Creator belum tersedia."},{status:409});
  item=await db.storeProduct.upsert({where:{storefrontId_designId:{storefrontId:design.user.storefront.id,designId:design.id}},update:{title:design.name,price:design.product.basePrice},create:{storefrontId:design.user.storefront.id,productId:design.productId,designId:design.id,title:design.name,price:design.product.basePrice,active:false},include:{product:true}});
 }else{
  if(user.role!=="CUSTOMER")return NextResponse.json({error:"Checkout storefront menggunakan akun Customer."},{status:403});
  item=await db.storeProduct.findUnique({where:{id:String(storeProductId||"")},include:{product:true}});
  if(!item||!item.active)return NextResponse.json({error:"Produk tidak tersedia."},{status:404});
 }

 const orderNumber=`BM-${Date.now().toString().slice(-9)}`;
 const address=String(shippingAddress).trim();
 const order=await db.$transaction(async tx=>{
  const created=await tx.order.create({data:{orderNumber,customerId:user.id,total:item.price*qty,shippingAddress:address,status:"PAID",items:{create:{storeProductId:item.id,productId:item.productId,quantity:qty,unitPrice:item.price,baseCost:item.product.basePrice,variantName}}}});
  if(selectedVariantId)await tx.productVariant.update({where:{id:selectedVariantId},data:{stock:{decrement:qty}}});
  await tx.productionOrder.create({data:{orderId:created.id,partnerId:partner.id,status:"QUEUED",notes:variantName?`Varian: ${variantName}`:""}});
  return created;
 });
 return NextResponse.json(order,{status:201});
}

export async function GET(req:NextRequest){
 const user=await readSession(req);
 if(!user)return NextResponse.json({error:"Login diperlukan."},{status:401});
 const where=user.role==="CUSTOMER"||user.role==="CREATOR"?{customerId:user.id}:{};
 const orders=await db.order.findMany({where,include:{customer:{select:{name:true,email:true}},items:{include:{product:true,storeProduct:{include:{storefront:true,design:true}}}},production:{include:{partner:true}}},orderBy:{createdAt:"desc"}});
 return NextResponse.json(orders);
}
