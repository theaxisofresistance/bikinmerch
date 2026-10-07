import {NextResponse} from "next/server"; import {db} from "@/lib/db";
export async function GET(){const products=await db.product.findMany({where:{active:true},include:{variants:true},orderBy:{name:"asc"}});return NextResponse.json(products);}
