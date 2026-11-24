import {NextRequest, NextResponse} from "next/server";

export function middleware(request: NextRequest) {
  const origin = request.headers.get("origin");
  if (origin && origin !== request.nextUrl.origin) {
    return NextResponse.json({error: "Origin tidak diizinkan."}, {status: 403});
  }
  return request.method === "OPTIONS"
    ? new NextResponse(null, {status: 204})
    : NextResponse.next();
}

export const config = {matcher: "/api/:path*"};
