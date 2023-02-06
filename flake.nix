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
        #pkgs = nixpkgs.legacyPackages.${system}; 

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
        # `flattenTree` returns a flat list of the package's derivations, ignoring other attribs.
        packages = utils.lib.flattenTree {
          gitAndTools = pkgs.gitAndTools;
          
          pri-google = pkgs.rustPlatform.buildRustPackage rec {
           pname = "${name}";
           version = "0.1.0";
          
           src = pkgs.fetchFromGitHub {
             owner = "panicmacc";
             repo = pname;
             rev = version;
             sha256 = "1iga3320mgi7m853la55xip514a3chqsdi1a1rwv25lr9b1p7vd3";
           };
          
           cargoSha256 = "17ldqr3asrdcsh4l29m3b5r37r5d0b3npq1lrgjmxb6vlx6a36qh";
          
           meta = with pkgs.lib; {
             description = "Simple abstractions over select Google services.";
             homepage = "https://github.com/panicmacc/pri-google";
             license = licenses.apache;
             maintainers = [ maintainers.tailhook ];
           };
          };

        };

        # `nix build` 
        defaultPackage = packages.pri-google;

        # `nix run` todo -- add some cargo examples here
        # apps.hello = utils.lib.mkApp { drv = packages.hello; };
        # defaultApp = apps.hello;

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
