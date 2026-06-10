# mhemeryck.xyz Migration Prompt

Goal: make `mhemeryck.xyz` the canonical domain for Martijn's personal site and CV.

Original state:

- `mhemeryck.xyz` points to the single-node k3s instance through Hetzner DNS.
- `blog.mhemeryck.xyz` is a CNAME to `mhemeryck.github.io`.
- `cvsite.yaml` serves `mhemeryck.xyz` from the `mhemeryck/cvsite:latest` container.
- The newly rebuilt Hugo site currently deploys through GitHub Pages.

Chosen migration path:

- GitHub Pages should serve the Hugo site directly at `mhemeryck.xyz`.
- `mhemeryck.github.io` now has `CNAME` set to `mhemeryck.xyz` and `baseURL` set to `https://mhemeryck.xyz/`.
- The apex `mhemeryck.xyz` DNS record points to the GitHub Pages `A` records.
- `www.mhemeryck.xyz` is a CNAME to `mhemeryck.github.io.` so GitHub Pages can validate and redirect it.
- `blog.mhemeryck.xyz` remains a legacy CNAME to `mhemeryck.github.io.` for now.
- The old `cvsite` container should be taken down after the GitHub Pages HTTPS URLs are verified.

Desired outcome:

- `https://mhemeryck.xyz/` serves the current Hugo site.
- `https://mhemeryck.xyz/about/` works.
- `https://mhemeryck.xyz/cv/` works.
- `https://mhemeryck.xyz/cv/martijn-hemeryck-cv.pdf` works.
- `blog.mhemeryck.xyz` may remain as an alias or legacy entry point, but should not be the canonical URL.

Preferred approach:

- Move the apex DNS record from the k3s node to GitHub Pages.
- Do not rebuild or repoint the old `mhemeryck/cvsite` container.
- Stop applying `cvsite.yaml` through the bulk manifest script.
- Avoid changing unrelated services such as `bitwarden`, `wekan`, or `facturette`.
- Avoid broad infrastructure redesign.

Relevant files:

- `node/dns.tf`
- `cvsite.yaml`
- `envs/mhemeryck/node/main.tf`
- `README.md`

Questions to answer before changing code:

- The old `mhemeryck/cvsite:latest` image comes from the separate `mhemeryck/cvsite` repository.
- The `cvsite` repository should be sunset instead of reused for the Hugo site.
- `blog.mhemeryck.xyz` remains a legacy GitHub Pages entry point for now.

Verification:

- Confirm authoritative DNS for `mhemeryck.xyz` points to the GitHub Pages `A` records.
- Confirm `www.mhemeryck.xyz` is a CNAME to `mhemeryck.github.io.`.
- Confirm GitHub Pages reports a successful DNS check for `mhemeryck.xyz`.
- Verify the four target URLs over HTTPS.
- Take down the old `cvsite` Kubernetes resources only after HTTPS verification passes.
