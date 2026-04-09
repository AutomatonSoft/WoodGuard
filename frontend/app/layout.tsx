import type { Metadata } from "next";

import "leaflet/dist/leaflet.css";
import "./globals.css";


export const metadata: Metadata = {
  title: "Woodguard",
  description: "Invoice import and timber risk due diligence workspace.",
  icons: {
    icon: "/icon.svg",
    shortcut: "/icon.svg",
    apple: "/icon.svg",
  },
};


export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
