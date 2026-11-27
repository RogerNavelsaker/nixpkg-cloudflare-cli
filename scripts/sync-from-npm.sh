#!/usr/bin/env bash
# Bump cf to the npm "latest" dist-tag: version and tarball hash in flake.nix.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
new=$(curl -fsS https://registry.npmjs.org/cf/latest | jq -r .version)
old=$(grep -oE '^        version = "[^"]+"' flake.nix | sed -E 's/.*"([^"]+)"/\1/')
[ "$new" != "$old" ] || { echo "up to date: $old"; exit 0; }
hash=$(nix store prefetch-file --json "https://registry.npmjs.org/cf/-/cf-$new.tgz" | jq -r .hash)
sed -i -E \
  -e "s/^(        version = )\"$old\"/\1\"$new\"/" \
  -e "s|(hash = )\"sha256-[^\"]+\"|\1\"$hash\"|" flake.nix
echo "bumped $old -> $new"
