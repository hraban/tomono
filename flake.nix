{
  description = "Migrate multiple repositories into a single monorepo";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    self, nixpkgs, flake-utils
  }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        myemacs = with pkgs; ((emacsPackagesFor emacs).emacsWithPackages (e: [
          e.dash
          e.htmlize
          e.s
        ]));
      in
        {
          packages = {
            default = pkgs.stdenv.mkDerivation {
              pname = "tomono";
              version = "2.0.0";
              src = pkgs.lib.cleanSource ./.;
              buildPhase = ''
                # Remove the stale VCS copy
                rm -f tomono
                ${myemacs}/bin/emacs -Q --script ./publish.el
              '';
              # If you want to put the test program in the final bin
              keepTest = false;
              installPhase = ''
                mkdir -p $out/{bin,doc}
                cp tomono $out/bin/
                if [[ "$keepTest" -eq 1 ]]; then
                  cp test $out/bin/tomono-test
                fi
                cp index.html style.css $out/doc
              '';
              nativeBuildInputs = [ pkgs.makeWrapper ];
              preFixup = ''
                for f in $out/bin/* ; do
                    wrapProgram "$f" --suffix PATH : "${pkgs.git}/bin"
                done
              '';
              meta = {
                license = pkgs.lib.licenses.agpl3Only;
                mainProgram = "tomono";
                homepage = "https://tomono.0brg.net";
                description =  "Migrate multiple repositories into a single monorepo";
              };
            };
            # For distribution outside of Nix
            dist = self.packages.${system}.default.overrideAttrs (_: {
              dontFixup = true;
              # This doesn’t make sense but it makes CI easier and who cares.
              keepTest = true;
            });
          };
          checks.default =
            let
              # Create an entirely separate derivation for the test script
              # alone. This can reuse the git path baking and the shebang
              # patching of the main derivation, so I can just immediately call
              # it.
              tomono-test = self.packages.${system}.default.overrideAttrs (_: {
                keepTest = true;
              });
            in
              pkgs.stdenv.mkDerivation (_: {
                pname = "tomono-check";
                version = "1.0";
                env = {
                  GIT_AUTHOR_NAME = "Test";
                  GIT_AUTHOR_EMAIL = "test@test.com";
                  GIT_COMMITTER_NAME = "Test";
                  GIT_COMMITTER_EMAIL = "test@test.com";
                };
                nativeBuildInputs = [
                  # The actual code being tested. Must be in PATH.
                  self.packages.${system}.default
                ];
                dontUnpack = true;
                buildPhase = ''
                  ${tomono-test}/bin/tomono-test
                '';
                # To keep Nix happy
                installPhase = "echo done > $out";
              });
        });
  }
