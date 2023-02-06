{
  description = "Simple abstractions over select Google services.";

  inputs = {
    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };
    utils = { url = "github:numtide/flake-utils"; };
    rust-overlay = { url = "github:oxalica/rust-overlay"; };
    flake-compat = {
      url = "github:edolstra/flake-compat"; 
      flake = false;
    };
  };

  outputs = { self, nixpkgs, utils, rust-overlay, ... }:
  
    utils.lib.eachDefaultSystem (system:
    
      let
        name = "pri-google";

        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
        };

        rustChannel = "nightly";

        # `buildInputs` is for runtime dependencies. They need to match the target architecture.
        buildInputs = with pkgs; [
          # openssl
          # pkgconfig
        ];

        # `nativeBuildInputs` is for build dependencies. They need to matchthe build host architecture.
        #  These get automatically added to PATH at build time.
        nativeBuildInputs = with pkgs; [
          cargo
          cargo-binutils
          cargo-edit
          jq
          (rust-bin.${rustChannel}.latest.default.override {
            extensions = [
              "llvm-tools-preview"
              "rust-src" 
            ];
            targets = [];
          })
          rustup
          unzip
          zip
        ];

      in rec {

        packages = {};

        # `nix develop`
        devShell = pkgs.mkShell {
          inputsFrom = builtins.attrValues self.packages.${system};
          buildInputs = buildInputs ++ (with pkgs; [
          ]);
          # Here you can add any tools you need present in your development environment, 
          #  but that may not be needed at build or runtime. 
          nativeBuildInputs = nativeBuildInputs ++ (with pkgs; [
            cargo-watch
            nixpkgs-fmt
            rust-analyzer
          ]);
          #
          RUST_SRC_PATH = "${pkgs.rust-bin.${rustChannel}.latest.rust-src}/lib/rustlib/src/rust/library";
          shellHook = ''
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath buildInputs}:$LD_LIBRARY_PATH"
            export PATH="$HOME/.cargo/bin:$PATH"
          '';

        };
      }
    );



}
