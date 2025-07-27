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
        in
        {
          devShells.default = pkgs.mkShell {
            packages = [
              elixir
              erlang
              pkgs.elixir-ls
            ];
          };
        };
    };
}
