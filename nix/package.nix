{ bun, fetchurl, lib, stdenv }:

let
  version = "1.0.0-beta.1";
  npmTarball = fetchurl {
    url = "https://registry.npmjs.org/cf/-/cf-${version}.tgz";
    hash = "sha256-KH5eeb9fESDYpWnApWfSI34ZqmH6vML4K5223q7PzKU=";
  };

  # Bun resolves the CLI's runtime dependencies from node_modules while
  # compiling. Keep this dependency tree as a fixed-output Nix artifact.
  runtimeDeps = stdenv.mkDerivation {
    pname = "cloudflare-cf-runtime-deps";
    inherit version;
    src = npmTarball;
    nativeBuildInputs = [ bun ];
    dontConfigure = true;
    dontBuild = true;
    outputHashMode = "recursive";
    outputHash = "sha256-xn4yz3s/yBeAyLmGbJywQ00IEALAugqnJFRxakq8/c8=";

    unpackPhase = ''
      mkdir package
      tar -xzf "$src" -C package --strip-components=1
    '';

    installPhase = ''
      cd package
      bun -e 'const p=await Bun.file("package.json").json(); delete p.devDependencies; await Bun.write("package.json", JSON.stringify(p));'
      bun install --production --ignore-scripts --no-save
      rm -rf node_modules/.cache
      mkdir -p "$out"
      cp -R node_modules "$out/"
    '';
  };
in
stdenv.mkDerivation {
  pname = "cloudflare-cf";
  inherit version;
  src = npmTarball;
  nativeBuildInputs = [ bun ];
  dontConfigure = true;
  dontStrip = true;
  dontPatchELF = true;

  unpackPhase = ''
    mkdir package
    tar -xzf "$src" -C package --strip-components=1
  '';

  buildPhase = ''
    cd package
    cp -R ${runtimeDeps}/node_modules .
    chmod -R u+w node_modules
    # The npm tarball omits this tiny ESM bridge although its generated node
    # implementation is included.
    mkdir -p node_modules/blake3-wasm/esm/node
    cat > node_modules/blake3-wasm/esm/node.js <<'EOF'
export * from "./node/index.js";
EOF
    sed -i "s/from 'stream.js'/from 'node:stream'/" node_modules/blake3-wasm/esm/node/hash-instance.js
    cat > entry.mjs <<'EOF'
import { CliExit, main } from "./dist/index.mjs";
try {
  await main();
} catch (error) {
  if (error instanceof CliExit) process.exit(error.code);
  process.exit(1);
}
EOF
    bun build --compile --minify --target=bun-linux-x64 entry.mjs --outfile "$TMPDIR/cf-compiled"
    "$TMPDIR/cf-compiled" --version || true
  '';

  installPhase = ''
    mkdir -p "$out/bin"
    install -m755 "$TMPDIR/cf-compiled" "$out/bin/cf"
    ln -s cf "$out/bin/cloudflare"
  '';

  meta = {
    description = "Cloudflare CLI compiled as a single optimized Bun binary";
    homepage = "https://www.npmjs.com/package/cf";
    license = with lib.licenses; [ mit asl20 ];
    mainProgram = "cf";
    platforms = lib.platforms.linux;
  };
}
