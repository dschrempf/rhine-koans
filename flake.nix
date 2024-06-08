{
  description = "Haskell development environment";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  inputs.rhine.url = "github:turion/rhine";

  outputs =
    { self
    , flake-utils
    , nixpkgs
    , rhine
    }:
    let
      theseHpkgNames = [
        "rhine-koans"
      ];
      thisGhcVersion = "ghc96";
      hOverlay = selfn: supern: {
        haskell = supern.haskell // {
          packageOverrides = selfh: superh:
            supern.haskell.packageOverrides selfh superh //
              {
                rhine-koans = selfh.callCabal2nix "rhine-koans" ./. { };
                # Upstream dependencies.
                rhine = rhine.packages.x86_64-linux.rhine;
                rhine-gloss = rhine.packages.x86_64-linux.rhine-gloss;
              };
        };
      };
      overlays = [ hOverlay ];
      perSystem = system:
        let
          pkgs = import nixpkgs {
            inherit system;
            inherit overlays;
          };
          hpkgs = pkgs.haskell.packages.${thisGhcVersion};
          hlib = pkgs.haskell.lib;
          theseHpkgs = nixpkgs.lib.genAttrs theseHpkgNames (n: hpkgs.${n});
          theseHpkgsDev = builtins.mapAttrs (_: x: hlib.doBenchmark x) theseHpkgs;
        in
        {
          packages = theseHpkgs // { default = theseHpkgs.rhine-koans; };

          devShells.default = hpkgs.shellFor {
            packages = _: (builtins.attrValues theseHpkgsDev);
            nativeBuildInputs = [
              # Haskell toolchain.
              hpkgs.cabal-fmt
              hpkgs.cabal-install
              hpkgs.haskell-language-server
            ];
            buildInputs = [ ];
            doBenchmark = true;
            withHoogle = true;
          };
        };
    in
    { overlays.default = nixpkgs.lib.composeManyExtensions overlays; }
    // flake-utils.lib.eachDefaultSystem perSystem;
}
