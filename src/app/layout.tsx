import type {Metadata} from "next";
import "./globals.css";
import "./studio.css";
export const metadata: Metadata = {
  title: "BikinMerch — Karyamu, jadi merchandise",
  description: "Platform print-on-demand lokal untuk kreator Indonesia.",
};
export default function RootLayout({children}: {children: React.ReactNode}) {
  return (
    <html lang="id">
      <body>{children}</body>
    </html>
  );
}
