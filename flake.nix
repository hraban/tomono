{
  description = "Migrate multiple repositories into a single monorepo";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    gitignore = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:hercules-ci/gitignore.nix";
    };
  };
  outputs = {
    self, nixpkgs, gitignore, flake-utils
  }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        cleanSource = src: gitignore.lib.gitignoreSource (pkgs.lib.cleanSource src);
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
              src = cleanSource ./.;
              buildPhase = ''
                # Remove the stale VCS copy
                rm -f tomono
                ${myemacs}/bin/emacs -Q --script ./publish.el
              '';
              installPhase = ''
                mkdir -p $out/{bin,doc}
                cp tomono $out/bin/
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
                homepage = "https://tomono.0brg.net";
                description =  "Migrate multiple repositories into a single monorepo";
              };
            };
            # For distribution outside of Nix
            dist = self.packages.${system}.default.overrideAttrs (_: {
              dontFixup = true;
            });
          };
          checks.default =
            let
              # Create an entirely separate derivation for the test script
              # alone. This can reuse the git path baking and the shebang
              # patching of the main derivation, so I can just immediately call
              # it.
              tomono-test = self.packages.${system}.default.overrideAttrs (_: {
                pname = "tomono-test";
                installPhase = "mkdir -p $out/bin; cp test $out/bin/tomono-test";
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
