import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "{{PROJECT_NAME}}",
  description: "Built with Next.js and deployed on Render",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="antialiased min-h-screen bg-black text-white">
        {children}
        <footer className="fixed bottom-0 left-0 right-0 border-t-2 border-white bg-black p-4">
          <div className="max-w-7xl mx-auto flex justify-between items-center text-sm">
            <span>Built with Next.js</span>
            <div className="flex gap-6">
              <a href="https://render.com/docs" target="_blank" rel="noopener noreferrer">
                Render Docs
              </a>
              <a href="https://github.com/render-examples" target="_blank" rel="noopener noreferrer">
                GitHub
              </a>
            </div>
          </div>
        </footer>
      </body>
    </html>
  );
}
