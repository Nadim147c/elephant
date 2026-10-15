{
  description = ''
    Elephant - a powerful data provider service and backend for building custom application launchers and desktop utilities.
  '';

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      inherit (nixpkgs) lib;
      eachSystem = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      formatter = eachSystem (pkgs: pkgs.alejandra);

      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          name = "elephant-dev-shell";
          inputsFrom = [ self.packages.${pkgs.stdenv.hostPlatform.system}.elephant ];
          buildInputs = with pkgs; [
            go
            gcc
            protobuf
            protoc-gen-go
          ];
          shellHook = ''
            export GOROOT="${pkgs.go}/share/go"
          '';
        };
      });

      packages = eachSystem (pkgs: {
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.elephant-with-providers;

        elephant = pkgs.callPackage ./nix/package.nix { };
        elephant-providers = pkgs.callPackage ./nix/plugin.nix { };

        # Combined package with elephant + providers
        elephant-with-providers = pkgs.buildEnv (finalAttrs: {
          pname = "elephant-with-providers";
          version = lib.trim (builtins.readFile ./cmd/elephant/version.txt);

          paths =
            let
              clis = with pkgs; [
                wl-clipboard
                libqalculate
                imagemagick
                bluez
              ];
              plugins = self.packages.${pkgs.stdenv.hostPlatform.system}.elephant-providers;
              # Use single wrapping
              base = self.packages.${pkgs.stdenv.hostPlatform.system}.elephant.override {
                makeWrapperArgs = [
                  "--prefix"
                  "PATH"
                  ":"
                  (lib.makeBinPath clis)

                  "--set-default"
                  "ELEPHANT_PROVIDER_DIR"
                  "${plugins}/lib/elephant"
                ];
              };
            in
            [
              base
              plugins
            ];

        });
      });

      homeManagerModules = {
        default = self.homeManagerModules.elephant;
        elephant = import ./nix/modules/home-manager.nix self;
      };

      nixosModules = {
        default = self.nixosModules.elephant;
        elephant = import ./nix/modules/nixos.nix self;
      };
    };
}
