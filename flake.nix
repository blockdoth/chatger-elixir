{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem =
        { pkgs, system, ... }:
        let
          erlangVersion = "erlang_27";
          elixirVersion = "elixir_1_17";
          elixir = pkgs.beam.packages.${erlangVersion}.${elixirVersion};
          erlang = pkgs.beam.interpreters.${erlangVersion};

          shathreeExtension = pkgs.stdenv.mkDerivation {
            pname = "sqlite-shathree-extension";
            version = "1.0";

            src = pkgs.fetchurl {
              url = "https://sqlite.org/src/raw/fd22d70620f86a0467acfdd3acd8435d5cb54eb1e2d9ff36ae44e389826993df?at=shathree.c";
              sha256 = "sha256-g+rtAqhcn1xVsHKzPrUk054ORNTvr48d2ujHOctMTW8=";
            };

            nativeBuildInputs = [ pkgs.sqlite pkgs.gcc  ];

            buildCommand = ''
              mkdir -p $out/lib
              gcc -shared -fPIC -o $out/lib/shathree.so $src/shathree.c
            '';

          };
        in
        {
          devShells.default = pkgs.mkShell {
            shellHook = ''
              ln -sf ${shathreeExtension}/lib/shathree.so $PWD/include/shathree.so
            '';               
            packages = [
              elixir
              erlang
              pkgs.elixir-ls
            ];
          };
        };
    };
}
