import {NextRequest, NextResponse} from "next/server";

// Flutter web retains the existing httpOnly cookie; native uses bearer tokens.
export function middleware(request: NextRequest) {
  const origin = request.headers.get("origin");
  const allowed = (
    process.env.FLUTTER_WEB_ORIGINS ||
    (process.env.NODE_ENV === "development"
      ? "http://localhost:5000,http://127.0.0.1:5000"
      : "")
  )
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean);
  const sameOrigin = origin === request.nextUrl.origin;
  if (origin && !sameOrigin && !allowed.includes(origin)) {
    return NextResponse.json({error: "Origin tidak diizinkan."}, {status: 403});
  }
  const response =
    request.method === "OPTIONS"
      ? new NextResponse(null, {status: 204})
      : NextResponse.next();
  if (origin && (sameOrigin || allowed.includes(origin))) {
    response.headers.set("Access-Control-Allow-Origin", origin);
    response.headers.set("Access-Control-Allow-Credentials", "true");
    response.headers.set(
      "Access-Control-Allow-Methods",
      "GET,POST,PATCH,DELETE,OPTIONS",
    );
    response.headers.set(
      "Access-Control-Allow-Headers",
      "Content-Type,Authorization,X-Bikinmerch-Client",
    );
    response.headers.append("Vary", "Origin");
  }
  return response;
}

export const config = {matcher: "/api/:path*"};
