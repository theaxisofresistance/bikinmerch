import {NextRequest, NextResponse} from "next/server";
import {timingSafeEqual} from "node:crypto";
import {db} from "@/lib/db";

export async function POST(req: NextRequest) {
  const expected = process.env.XENDIT_WEBHOOK_TOKEN;
  const provided = req.headers.get("x-callback-token") || "";
  if (!expected) return NextResponse.json({error: "Webhook unavailable"}, {status: 503});
  const a=Buffer.from(expected), b=Buffer.from(provided);
  if(a.length!==b.length || !timingSafeEqual(a,b))return NextResponse.json({error:"Unauthorized"},{status:401});
  const event=await req.json().catch(()=>null);
  if(!event || typeof event.external_id!=="string" || typeof event.id!=="string")return NextResponse.json({error:"Invalid event"},{status:400});
  if(!["PAID","SETTLED","EXPIRED"].includes(event.status))return NextResponse.json({received:true});
  const result=await db.$transaction(async tx=>{
    const order=await tx.order.findUnique({where:{id:event.external_id},include:{items:true}});
    if(!order)return "unknown";
    if(order.paymentMethod!=="Xendit Test" || (order.xenditInvoiceId && order.xenditInvoiceId!==event.id) || event.currency!=="IDR" || event.amount!==order.total)return "invalid";
    const paid=event.status!=="EXPIRED";
    if(paid && (!Number.isFinite(event.paid_amount)||event.paid_amount<order.total))return "invalid";
    const changed=await tx.order.updateMany({where:{id:order.id,status:"PENDING_PAYMENT"},data:{status:paid?"PAID":"PAYMENT_EXPIRED",paidAt:paid?new Date():null,xenditInvoiceId:event.id}});
    if(!changed.count)return "duplicate";
    if(paid){
      if(!order.assignedPartnerId)throw new Error("Missing production partner");
      await tx.productionOrder.create({data:{orderId:order.id,partnerId:order.assignedPartnerId,status:"QUEUED",notes:order.items[0]?.variantName||""}});
    }else if(order.reservedVariantId){await tx.productVariant.update({where:{id:order.reservedVariantId},data:{stock:{increment:order.items.reduce((sum,item)=>sum+item.quantity,0)}}});}
    return "ok";
  });
  return NextResponse.json({received:result!=="invalid"},{status:result==="invalid"?400:200});
}
