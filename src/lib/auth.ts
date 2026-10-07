import { cookies } from "next/headers";
import { jwtVerify, SignJWT } from "jose";
import { NextRequest, NextResponse } from "next/server";
const secret = new TextEncoder().encode(process.env.JWT_SECRET || "dev-only-bikinmerch-secret-change-me-please");
export type Session = { id:string; name:string; email:string; role:"CREATOR"|"CUSTOMER"|"ADMIN"|"PRINT_PARTNER" };
export async function signSession(user:Session){ return new SignJWT(user).setProtectedHeader({alg:"HS256"}).setIssuedAt().setExpirationTime("7d").sign(secret); }
export async function readSession(req?:NextRequest):Promise<Session|null>{ try { const token=req?.cookies.get("bm_session")?.value ?? (await cookies()).get("bm_session")?.value; if(!token)return null; const {payload}=await jwtVerify(token,secret); return payload as unknown as Session; } catch{return null;} }
export function jsonError(message:string,status=400){return NextResponse.json({error:message},{status});}
