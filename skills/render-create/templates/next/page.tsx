export default function Home() {
  return (
    <main className="min-h-screen p-8 pb-24">
      <div className="max-w-4xl mx-auto prose prose-invert max-w-none">
        {/* Hero */}
        <section className="py-20 text-center">
          <h1 className="text-6xl font-bold mb-6">{{PROJECT_NAME}}</h1>
          <p className="text-xl text-gray-400 mb-8">
            A modern starting point for your next project.
            <br />
            Fast, flexible, and ready to scale.
          </p>
          <div className="flex gap-4 justify-center">
            <a
              href="#features"
              className="bg-white !text-black px-8 py-3 font-semibold hover:bg-black hover:!text-white border border-white transition-all no-underline"
            >
              Get Started
            </a>
            <a
              href="https://render.com/docs"
              target="_blank"
              rel="noopener noreferrer"
              className="bg-transparent text-white px-8 py-3 font-semibold border border-white hover:bg-white hover:text-black transition-all no-underline"
            >
              Documentation
            </a>
          </div>
        </section>

        {/* Features */}
        <section id="features" className="py-16">
          <h2 className="text-3xl font-bold mb-8">Stack</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="border border-white p-6 not-prose">
              <h3 className="text-xl font-bold mb-2">Next.js 15</h3>
              <p className="text-gray-400">
                React framework with App Router, Server Components, and Turbopack.
              </p>
            </div>
            <div className="border border-white p-6 not-prose">
              <h3 className="text-xl font-bold mb-2">Tailwind CSS</h3>
              <p className="text-gray-400">
                Utility-first CSS framework for rapid UI development.
              </p>
            </div>
            <div className="border border-white p-6 not-prose">
              <h3 className="text-xl font-bold mb-2">TypeScript</h3>
              <p className="text-gray-400">
                Type-safe JavaScript for better developer experience.
              </p>
            </div>
            <div className="border border-white p-6 not-prose">
              <h3 className="text-xl font-bold mb-2">Render</h3>
              <p className="text-gray-400">
                Deploy with zero configuration using the included Blueprint.
              </p>
            </div>
          </div>
        </section>

        {/* CTA */}
        <section className="py-16 text-center">
          <h2 className="text-3xl font-bold mb-4">Ready to build?</h2>
          <p className="text-gray-400 mb-8">
            Edit <code className="bg-white/10 px-2 py-1">src/app/page.tsx</code> to get started.
          </p>
        </section>
      </div>
    </main>
  );
}
