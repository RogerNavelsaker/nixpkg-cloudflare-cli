# nixpkg-cloudflare-cli

Packages the npm [`cf`](https://www.npmjs.com/package/cf) Cloudflare CLI as a single optimized Bun-compiled executable.

## Usage

```bash
nix run github:RogerNavelsaker/nixpkg-cloudflare-cli
nix profile install github:RogerNavelsaker/nixpkg-cloudflare-cli
```

The package installs both `cf` and the compatibility alias `cloudflare`.

## Local check

```bash
nix build
./result/bin/cf
```
