# gigarizz-web

Static marketing site hosted on **Cloudflare Pages** via Wrangler.

Pages:
- `/` — landing
- `/privacy` — Privacy Policy (referenced by iOS `AppConstants.privacyURL`)
- `/terms` — Terms of Service (referenced by iOS `AppConstants.termsURL`)
- `/support` — Support contact + FAQ

## First-time setup

```bash
cd web
npm install
npx wrangler login          # opens browser → Cloudflare account auth
```

## Deploy

```bash
npm run deploy
# or: npx wrangler pages deploy public --project-name gigarizz-web
```

First deploy creates the project on Cloudflare. Subsequent deploys publish a new version.

After first deploy, configure custom domains in the Cloudflare dashboard:
1. Pages → gigarizz-web → Custom domains → Set up a custom domain
2. Add `www.gigarizz.app` (required — iOS app links there)
3. Add `gigarizz.app` (apex; the `_redirects` file forwards apex → www)

## Local dev

```bash
npm run dev
# serves at http://localhost:8788
```

## Files

- `wrangler.toml` — Cloudflare Pages config
- `public/_headers` — security + cache headers
- `public/_redirects` — apex → www redirect, alternate path redirects
- `public/assets/style.css` — shared dark luxury theme
- `public/{index,privacy,terms,support}.html` — pages

## Updating content

Privacy and Terms reference `Last updated: <date>` near the top — update both date and content together when material changes ship.
