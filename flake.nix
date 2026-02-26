{
  description = "PicoClaw: Ultra-Efficient AI Assistant in Go";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Version info from git if available
        version = if (self ? rev) then self.rev else "dev";
        shortRev = if (self ? shortRev) then self.shortRev else "dev";

        # Linker flags to inject version info
        ldflags = [
          "-s" "-w"
          "-X github.com/sipeed/picoclaw/cmd/picoclaw/internal.version=${version}"
          "-X github.com/sipeed/picoclaw/cmd/picoclaw/internal.gitCommit=${shortRev}"
        ];
      in
      {
        packages.default = pkgs.buildGoModule {
          pname = "picoclaw";
          version = version;
          src = pkgs.lib.cleanSource ./.;

          # TODO: Update this hash after the first build failure
          # Run `nix build` and copy the expected hash from the error message
          vendorHash = pkgs.lib.fakeHash;

          subPackages = [ "cmd/picoclaw" ];

          # Run go generate to prepare embedded assets
          preBuild = ''
            rm -rf cmd/picoclaw/internal/onboard/workspace || true
            go generate ./...
          '';

          ldflags = ldflags;

          meta = with pkgs.lib; {
            description = "Ultra-Efficient AI Assistant in Go";
            homepage = "https://github.com/sipeed/picoclaw";
            license = licenses.mit;
            mainProgram = "picoclaw";
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            go
            gopls
            golangci-lint
            gotools
          ];
        };
      }
    );
}
