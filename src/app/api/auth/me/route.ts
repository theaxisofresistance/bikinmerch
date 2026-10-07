import {NextRequest,NextResponse} from "next/server"; import {readSession} from "@/lib/auth";
export async function GET(req:NextRequest){return NextResponse.json({user:await readSession(req)});}
export async function DELETE(){const res=NextResponse.json({ok:true}); res.cookies.delete("bm_session");return res;}
