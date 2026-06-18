{
  description = "Nix packaging scaffold for cf (The Cloudflare CLI)";

  nixConfig = {
    extra-substituters = [ "https://cache.nixos.org" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        version = "0.0.6";

        src = pkgs.fetchurl {
          url = "https://registry.npmjs.org/cf/-/cf-${version}.tgz";
          hash = pkgs.lib.fakeHash;
        };

        bunDeps = pkgs.stdenv.mkDerivation {
          name = "cf-bun-deps";
          inherit src;
          nativeBuildInputs = [ pkgs.bun pkgs.cacert ];
          buildPhase = ''
            export BUN_INSTALL_CACHE_DIR=$TMPDIR/bun-cache
            bun install --production --ignore-scripts
          '';
          installPhase = ''
            mkdir -p $out
            if [ -d node_modules ]; then
              cp -r node_modules $out/
            fi
          '';
          dontFixup = true;
          outputHashMode = "recursive";
          outputHashAlgo = "sha256";
          outputHash = pkgs.lib.fakeHash;
        };

        cf = pkgs.stdenv.mkDerivation {
          pname = "cf";
          inherit version src;
          nativeBuildInputs = [ pkgs.bun pkgs.makeWrapper ];
          
          buildPhase = ''
            if [ -d ${bunDeps}/node_modules ]; then
              cp -r ${bunDeps}/node_modules ./
              chmod -R +w node_modules
            fi
          '';

          installPhase = ''
            mkdir -p $out/libexec/cf $out/bin
            cp -r . $out/libexec/cf
            
            makeWrapper ${pkgs.bun}/bin/bun $out/bin/cf \
              --add-flags "$out/libexec/cf/bin/cf"
          '';

          meta = with pkgs.lib; {
            description = "The Cloudflare CLI";
            homepage = "https://npmjs.com/package/cf";
            license = licenses.mit;
            mainProgram = "cf";
          };
        };
      in
      {
        packages = {
          inherit cf;
          default = cf;
        };
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ nix-update ];
        };
      }
    );
}
