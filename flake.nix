# flake.nix describes a Nix source repository
# that provides builds of lug-helper.
# It also provides a development environment
# for working on lug-helper for use with `nix develop`.
#
# For information about this see:
# https://nixos.wiki/wiki/Flakes
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }: let
    # Current git commet the flake was imported,
    # marked as dirty if this is a local clone with changes
    lug-helperRev = self.rev or self.dirtyRev;

    lug-helper = pkgs:
      pkgs.stdenv.mkDerivation rec {
        name = "lug-helper";
        src = ./.;
        buildInputs = with pkgs; [bash coreutils findutils];
        nativeBuildInputs = with pkgs; [makeWrapper];
        installPhase = with pkgs; ''
          mkdir -p $out/bin
          mkdir -p $out/share/lug-helper
          mkdir -p $out/share/pixmaps
          cp lug-helper.sh $out/bin/lug-helper
          cp lutris-sc-install.json $out/share/lug-helper/lutris-sc-install.json
          cp lug-logo.png $out/share/pixmaps/lug-logo.png

          wrapProgram $out/bin/lug-helper \
          --prefix PATH: ${
            lib.makeBinPath [bash coreutils findutils]
          }
        '';
      };
    # Makes lug-helper available for all OS/CPU combos that nix supports
    flakeForSystem = nixpkgs: system: let
      pkgs = nixpkgs.legacyPackages.${system};
      lh = lug-helper pkgs;
    in {
      packages = {
        default = lh;
        lug-helper = lh;
      };
      formatter = pkgs.alejandra;
      devShell = pkgs.mkShell {
        packages = with pkgs; [
          git
          bash
          coreutils
          findutils
          gnome.zenity
          shellcheck
        ];
      };
    };
  in
    flake-utils.lib.eachDefaultSystem (system: flakeForSystem nixpkgs system)
    // {
      overlays.default = final: prev: {
        lug-helper = self.packages.${prev.system}.lug-helper;
      };
    };
}
