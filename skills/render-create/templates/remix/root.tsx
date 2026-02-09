import { Links, Meta, Outlet, Scripts, ScrollRestoration } from "react-router";
import type { LinksFunction } from "react-router";

import stylesheet from "./app.css?url";

export const links: LinksFunction = () => [
  { rel: "stylesheet", href: stylesheet },
];

export default function Root() {
  return (
    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <Meta />
        <Links />
      </head>
      <body>
        <Outlet />
        <ScrollRestoration />
        <Scripts />
      </body>
    </html>
  );
}
