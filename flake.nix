{
  description = "Nix packaging scaffold for cf (The Cloudflare CLI)";

  nixConfig = {
    extra-substituters = [ "https://cache.nixos.org" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in {
      packages = forAllSystems ({ pkgs }: {
        default = pkgs.buildNpmPackage rec {
          pname = "cf";
          version = "0.0.6";

          src = pkgs.fetchurl {
            url = "https://registry.npmjs.org/cf/-/cf-${version}.tgz";
            hash = pkgs.lib.fakeHash;
          };

          # buildNpmPackage requires a package-lock.json. If the tarball doesn't have one,
          # you may need to commit a package-lock.json to this repository and inject it during postPatch.
          npmDepsHash = pkgs.lib.fakeHash;

          meta = with pkgs.lib; {
            description = "The Cloudflare CLI";
            homepage = "https://npmjs.com/package/cf";
            license = licenses.mit;
            mainProgram = "cf";
          };
        };
      });

      devShells = forAllSystems ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [ nix-update ];
        };
      });
    };
}
