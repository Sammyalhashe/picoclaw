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
        # Use a fixed timestamp for reproducible builds, or 1970-01-01 as fallback
        buildTime = if (self ? lastModifiedDate) then
          pkgs.lib.substring 0 8 self.lastModifiedDate
        else "19700101";

        # Linker flags to inject version info
        ldflags = [
          "-s" "-w"
          "-X github.com/sipeed/picoclaw/cmd/picoclaw/internal.version=${version}"
          "-X github.com/sipeed/picoclaw/cmd/picoclaw/internal.gitCommit=${shortRev}"
          "-X github.com/sipeed/picoclaw/cmd/picoclaw/internal.buildTime=${buildTime}"
          "-X github.com/sipeed/picoclaw/cmd/picoclaw/internal.goVersion=${pkgs.go.version}"
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

          # Automatically load .env file if it exists
          shellHook = ''
            if [ -f .env ]; then
              echo "Loading environment variables from .env..."
              set -a
              source .env
              set +a
            fi
          '';
        };
      }
    );
}
