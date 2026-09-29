{
  description = "Nix package for cf (The Cloudflare CLI)";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://rogernavelsaker.cachix.org"
      "https://nacosolutions.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "rogernavelsaker.cachix.org-1:n1DtzMNhA9Rz4Kg3xlXOi/KceULu8VrMbs9WXyMFQNQ="
      "nacosolutions.cachix.org-1:JzCiW2CLcuLXtwOVAg3SlSK/kpqWbfSFEVenyKVUlug="
    ];
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
              --add-flags "$out/libexec/cf/bin/cf"
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
