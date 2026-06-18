{
  description = "Nix package for cf (The Cloudflare CLI)";

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
          hash = "sha256-tRyAHwUnUs6cen8J6FbjKEUC/7KvkZdLnol975V5fAU=";
        };

        cf = pkgs.stdenv.mkDerivation {
          pname = "cf";
          inherit version src;
          nativeBuildInputs = [ pkgs.makeWrapper ];

          # cf ships pre-bundled in dist/ — no node_modules needed
          installPhase = ''
            mkdir -p $out/libexec/cf $out/bin
            cp -r . $out/libexec/cf

            makeWrapper ${pkgs.bun}/bin/bun $out/bin/cf \
              --add-flags "$out/libexec/cf/dist/index.mjs"
          '';

          meta = with pkgs.lib; {
            description = "The Cloudflare CLI — unified CLI for the entire Cloudflare platform";
            homepage = "https://blog.cloudflare.com/cf-cli-local-explorer/";
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
