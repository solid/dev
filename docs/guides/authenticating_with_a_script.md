# Authenticating with a Node.js Script

Many Solid use cases — automated data pipelines, bots, CI/CD tasks, and server-to-server integrations — require authentication **without a browser**. This guide walks you through authenticating a Node.js script against a Solid server using **Client Credentials**.

The approach works with any Solid server that supports the Client Credentials grant type, including the [Community Solid Server (CSS)](https://communitysolidserver.github.io/CommunitySolidServer/) and Inrupt's [Enterprise Solid Server (ESS)](https://docs.inrupt.com/).

## Prerequisites

- [Node.js](https://nodejs.org/) v18 or later (for built-in `fetch`)
- A Solid account with a Pod on a server that supports Client Credentials
- Basic familiarity with JavaScript

## Overview

The flow has three stages:

1. **Generate a Client Credentials token** — obtain a `client_id` / `client_secret` pair linked to your WebID. This only needs to be done **once**.
2. **Log in with the credentials** — use the `client_id` and `client_secret` to start an authenticated session.
3. **Make authenticated requests** — use the session's `fetch` to read and write resources on your Pod.

## 1. Set Up the Project

Create a new directory and initialise it:

```bash
mkdir solid-script && cd solid-script
npm init -y
```

Set the project to use ES modules and install the required library:

```bash
npm pkg set type=module
npm install @inrupt/solid-client-authn-node
```

Create a file called `index.js` — all the code below goes into this file.

## 2. Generate Client Credentials (One-Time Setup)

Before your script can log in, you need a `client_id` / `client_secret` pair. There are two ways to get one:

### Option A: Via the Account Page (easiest)

If your Solid server has an account management UI, you can create a token there:

1. Navigate to your account page:
    - **Community Solid Server (local)**: [http://localhost:3000/.account/](http://localhost:3000/.account/)
    - **solidcommunity.net**: [https://solidcommunity.net/.account/](https://solidcommunity.net/.account/)
    - **Inrupt PodSpaces**: [https://login.inrupt.com/registration.html](https://login.inrupt.com/registration.html)
2. Create a new Client Credentials token, giving it a name and selecting your WebID.
3. Copy the `id` and `secret` values shown. **Store the secret safely** — it cannot be retrieved again.

Skip ahead to [Step 3](#3-log-in-and-make-authenticated-requests) if you use this approach.

### Option B: Via the API (programmatic)

Some Solid servers also allow you to generate credentials programmatically. This is useful for automation or when you don't have browser access. The process is server-specific — for example, the Community Solid Server provides a dedicated API for this:

- [CSS — Generating a token via the API](https://communitysolidserver.github.io/CommunitySolidServer/latest/usage/client-credentials/#via-the-api)

## 3. Log In and Make Authenticated Requests

Once you have a `client_id` and `client_secret`, you can authenticate using the [`Session`](https://inrupt.github.io/solid-client-authn-js/node/classes/Session.html) class from `@inrupt/solid-client-authn-node`.

Replace the contents of `index.js` (or create a new file) with:

```javascript
import { Session } from '@inrupt/solid-client-authn-node';

// These values come from Step 2 (or from your account page).
// In production, load these from environment variables.
const CLIENT_ID = process.env.SOLID_CLIENT_ID;
const CLIENT_SECRET = process.env.SOLID_CLIENT_SECRET;
const OIDC_ISSUER = 'http://localhost:3000'; // Your Solid server URL

async function main() {
  // Create a new session and log in
  const session = new Session();
  await session.login({
    clientId: CLIENT_ID,
    clientSecret: CLIENT_SECRET,
    oidcIssuer: OIDC_ISSUER,
  });

  if (!session.info.isLoggedIn) {
    throw new Error('Login failed');
  }
  console.log(`Logged in as ${session.info.webId}`);

  // session.fetch works just like the standard fetch API,
  // but automatically includes authentication headers.
  const response = await session.fetch(session.info.webId);
  console.log(`GET ${session.info.webId} — ${response.status}`);
  console.log(await response.text());

  // Always log out when done
  await session.logout();
  console.log('Logged out.');
}

main().catch(console.error);
```

Run the script:

```bash
SOLID_CLIENT_ID="your-client-id" \
SOLID_CLIENT_SECRET="your-client-secret" \
node index.js
```

You should see your profile document printed to the console.

## Tips

- **Token reuse**: The `client_id` / `client_secret` pair does not expire. Generate it once and reuse it across runs. Only the access tokens obtained during `session.login()` are short-lived — the library handles refreshing them automatically.
- **Session keep-alive**: By default, the `Session` refreshes its tokens in the background. Pass `{ keepAlive: false }` to the `Session` constructor if you want a one-shot script that exits cleanly.
- **Security**: Never hard-code secrets in source code. Use environment variables or a secrets manager.
- **Multiple WebIDs**: You can generate multiple client credentials tokens, each linked to a different WebID on your account.

## Further Reading

- [Community Solid Server — Client Credentials documentation](https://communitysolidserver.github.io/CommunitySolidServer/latest/usage/client-credentials/)
- [Inrupt — Authentication for Single-User Applications](https://docs.inrupt.com/developer-tools/javascript/client-libraries/tutorial/authenticate-nodejs-script/)
- [`@inrupt/solid-client-authn-node` API reference](https://inrupt.github.io/solid-client-authn-js/node/classes/Session.html)
- [Solid-OIDC specification](https://solid.github.io/solid-oidc/)
