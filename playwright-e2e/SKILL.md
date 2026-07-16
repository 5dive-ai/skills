---
name: playwright-e2e
description: End-to-end testing and click-verification of web apps with Playwright — install, write specs, drive authenticated pages, take screenshots, and run in CI. Use when verifying a web change actually works in a real browser, testing user flows, debugging a UI bug live, or confirming an authed/gated page before shipping. Keywords Playwright, e2e, browser test, click test, screenshot, headless.
version: 1.0.0
license: MIT
---

# Playwright E2E & Click-Verification Guide

Drive a real browser to **prove a web change works** — not just that it compiles. Use this to
verify flows end-to-end, reproduce UI bugs, and screenshot pages. Pairs with `nextjs-app`.

> Core principle: a green build is not a working feature. Before calling an interactive change
> done, click through the actual rendered page in a browser. Especially for authed routes,
> modals, and forms — those are exactly where "looks fine in code" silently breaks.

## Install

```bash
npm install -D @playwright/test
npx playwright install chromium      # or: --with-deps on CI / fresh boxes
```

## Minimal config

```ts
// playwright.config.ts
import { defineConfig } from '@playwright/test'

export default defineConfig({
  testDir: './e2e',
  use: { baseURL: 'http://localhost:3000', trace: 'on-first-retry' },
  webServer: { command: 'npm run dev', url: 'http://localhost:3000', reuseExistingServer: true },
})
```

## A first spec

```ts
// e2e/home.spec.ts
import { test, expect } from '@playwright/test'

test('home renders and CTA navigates', async ({ page }) => {
  await page.goto('/')
  await expect(page.getByRole('heading', { name: /welcome/i })).toBeVisible()
  await page.getByRole('link', { name: 'Get started' }).click()
  await expect(page).toHaveURL(/.*dashboard/)
})
```

Run:

```bash
npx playwright test                     # headless, all specs
npx playwright test --headed            # watch it
npx playwright test home.spec.ts -g CTA # filter
npx playwright show-report              # HTML report after a run
```

## Selectors — prefer user-facing, in this order

1. `page.getByRole('button', { name: 'Save' })` — accessible role + name (best)
2. `page.getByLabel('Email')`, `page.getByPlaceholder(…)`, `page.getByText(…)`
3. `page.getByTestId('submit')` — add `data-testid` for fragile/ambiguous nodes
4. CSS/XPath — last resort; brittle

Playwright **auto-waits** for elements to be actionable — avoid manual `waitForTimeout`. If you
must wait on state, wait on a condition: `await expect(locator).toBeVisible()` or
`page.waitForURL(…)`.

## Testing authenticated pages

Most real apps gate the interesting pages behind login. Two reliable patterns:

### A. Log in once, reuse the storage state

```ts
// e2e/auth.setup.ts  (run as a setup project)
import { test as setup } from '@playwright/test'

setup('authenticate', async ({ page }) => {
  await page.goto('/sign-in')
  await page.getByLabel('Email').fill(process.env.TEST_EMAIL!)
  await page.getByLabel('Password').fill(process.env.TEST_PASSWORD!)
  await page.getByRole('button', { name: 'Sign in' }).click()
  await page.waitForURL('**/dashboard')
  await page.context().storageState({ path: 'e2e/.auth/user.json' })
})
```

```ts
// playwright.config.ts — wire the setup + reuse the session
projects: [
  { name: 'setup', testMatch: /auth\.setup\.ts/ },
  { name: 'app', use: { storageState: 'e2e/.auth/user.json' }, dependencies: ['setup'] },
]
```

### B. Programmatic session (faster, no UI login)

Many auth providers (Clerk, Auth.js, custom JWT) let you mint a session token via their
server SDK / admin API, then inject it so the browser starts already-authed:

```ts
// Mint a short-lived sign-in token server-side, then exchange it in the browser.
// Exact call depends on the provider; the shape is: get a ticket → land on a URL that
// consumes it → save storageState.
await page.goto(`/sign-in#__token=${signInToken}`)   // provider-specific consume step
await page.waitForURL('**/dashboard')
await page.context().storageState({ path: 'e2e/.auth/user.json' })
```

Keep test creds/tokens in env vars (never commit them), scope them to a throwaway test user,
and scrub any token out of logs/artifacts.

## Quick one-off verification (no spec file)

For ad-hoc "does this actually render" checks, a short script beats a full suite:

```js
// verify.mjs — node verify.mjs
import { chromium } from 'playwright'
const b = await chromium.launch()
const p = await b.newPage()
await p.goto('https://your-app.example.com/', { waitUntil: 'domcontentloaded' })
await p.screenshot({ path: 'shot.png', fullPage: true })
console.log('title:', await p.title())
await b.close()
```

Gotchas from real runs:
- Pages with autoplay video/streams never hit `networkidle` — use
  `waitUntil: 'domcontentloaded'` and wait on a concrete element instead.
- Kill cookie/consent banners before screenshotting (`page.getByRole('button',
  { name: /accept/i }).click().catch(() => {})`).
- A client-inlined key (auth publishable key, analytics id) is baked at **build** time — if a
  locally-served build behaves oddly, verify against a real deployed URL instead of fighting
  the local server.

## CI

```yaml
# .github/workflows/e2e.yml
- run: npm ci
- run: npx playwright install --with-deps chromium
- run: npx playwright test
- uses: actions/upload-artifact@v4
  if: failure()
  with: { name: playwright-report, path: playwright-report }
```

## Debugging

```bash
npx playwright test --debug          # step through with the inspector
npx playwright codegen localhost:3000 # record clicks → generated spec
npx playwright show-trace trace.zip  # time-travel a failed run
```
