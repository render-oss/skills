import { db, isDatabaseConfigured } from "@/db";
import { users } from "@/db/schema";

export default async function Home() {
  // Example: fetch users from database
  let userCount = 0;
  let dbStatus: "connected" | "not-configured" | "error" = "not-configured";

  if (isDatabaseConfigured) {
    try {
      const allUsers = await db.select().from(users);
      userCount = allUsers.length;
      dbStatus = "connected";
    } catch {
      dbStatus = "error";
    }
  }

  return (
    <main className="min-h-screen p-8 pb-24">
      <div className="max-w-4xl mx-auto prose prose-invert max-w-none">
        {/* Hero */}
        <section className="py-20 text-center">
          <h1 className="text-6xl font-bold mb-6">{{PROJECT_NAME}}</h1>
          <p className="text-xl text-gray-400 mb-8">
            Full-stack Next.js with PostgreSQL.
            <br />
            Fast, flexible, and ready to scale.
          </p>
          <div className="flex gap-4 justify-center">
            <a
              href="#setup"
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

        {/* Database Status */}
        <section className="py-8">
          <div className="border border-white p-6 text-center not-prose">
            <p className="text-sm text-gray-400 mb-2">Database Status</p>
            <p className="text-2xl font-bold">
              {dbStatus === "connected" && `${userCount} users`}
              {dbStatus === "not-configured" && "Not configured"}
              {dbStatus === "error" && "Connection error"}
            </p>
            {dbStatus === "not-configured" && (
              <p className="text-sm text-gray-500 mt-2">
                Set DATABASE_URL in .env to connect
              </p>
            )}
          </div>
        </section>

        {/* Setup */}
        <section id="setup" className="py-16">
          <h2 className="text-3xl font-bold mb-8">Setup</h2>
          <div className="space-y-4">
            <div className="border border-white p-6 not-prose">
              <h3 className="text-xl font-bold mb-2">1. Configure Database</h3>
              <p className="text-gray-400 mb-4">
                Set your PostgreSQL connection string in <code className="bg-white/10 px-2 py-1">.env</code>
              </p>
              <pre className="bg-white/5 p-4 text-sm overflow-x-auto">
                DATABASE_URL=&quot;postgresql://user:pass@host:5432/db&quot;
              </pre>
            </div>
            <div className="border border-white p-6 not-prose">
              <h3 className="text-xl font-bold mb-2">2. Run Migrations</h3>
              <pre className="bg-white/5 p-4 text-sm overflow-x-auto">
{`npm run db:generate
npm run db:migrate`}
              </pre>
            </div>
            <div className="border border-white p-6 not-prose">
              <h3 className="text-xl font-bold mb-2">3. Start Building</h3>
              <p className="text-gray-400">
                Edit <code className="bg-white/10 px-2 py-1">src/app/page.tsx</code> and{" "}
                <code className="bg-white/10 px-2 py-1">src/db/schema.ts</code>
              </p>
            </div>
          </div>
        </section>

        {/* Stack */}
        <section className="py-16">
          <h2 className="text-3xl font-bold mb-8">Stack</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="border border-white p-6 not-prose">
              <h3 className="text-xl font-bold mb-2">Next.js 15</h3>
              <p className="text-gray-400">App Router + Server Components</p>
            </div>
            <div className="border border-white p-6 not-prose">
              <h3 className="text-xl font-bold mb-2">Drizzle ORM</h3>
              <p className="text-gray-400">Type-safe PostgreSQL queries</p>
            </div>
            <div className="border border-white p-6 not-prose">
              <h3 className="text-xl font-bold mb-2">Tailwind CSS</h3>
              <p className="text-gray-400">Utility-first styling</p>
            </div>
            <div className="border border-white p-6 not-prose">
              <h3 className="text-xl font-bold mb-2">Render</h3>
              <p className="text-gray-400">One-click deploy with Blueprint</p>
            </div>
          </div>
        </section>
      </div>
    </main>
  );
}
