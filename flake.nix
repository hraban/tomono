{
  inputs = {
    tomono.url = "github:hraban/tomono";
  };

  outputs = {
    self, nixpkgs, flake-utils, tomono
  }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
        {
          checks.default = with pkgs; stdenvNoCC.mkDerivation {
            name = "test";
            checkPhase = writeShellScript "test" (builtins.readFile ./test.sh);
            doCheck = true;
            dontUnpack = true;
            nativeBuildInputs = [ moreutils git tomono.packages.${system}.default ];
            installPhase = "touch $out";
          };
        });
  }
