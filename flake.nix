{
  description = "Multi Architecture Nix Flake for PHP development";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }@inputs:

    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        mkScript =
          name: text:
          let
            script = pkgs.writeShellScriptBin name text;
          in
          script;

        scripts = [
          (mkScript "php-debug-adapter" ''
            node ${pkgs.vscode-extensions.xdebug.php-debug}/share/vscode/extensions/xdebug.php-debug/out/phpDebug.js
          '')
        ];

        phpWithExtensions = (
          pkgs.php85.buildEnv {
            extensions = (
              { enabled, all }:
              enabled
              ++ (with all; [
                xdebug
                intl
                mysqli
                bcmath
                curl
                zip
                soap
                mbstring
                gd
                redis
              ])
            );
            extraConfig = ''
              error_reporting = E_ALL & ~E_NOTICE & ~E_STRICT & ~E_DEPRECATED
              xdebug.mode=debug
              xdebug.start_with_request=yes
              xdebug.client_host=127.0.0.1
              xdebug.client_port=9003
              xdebug.log_level = 0
            '';
          }
        );

        devPackages = with nixpkgs; [
          # base stuff
          phpWithExtensions
          pkgs.nodejs_22
          pkgs.curl
          pkgs.zip
          pkgs.unzip
          # php packages
          pkgs.php85Packages.composer
          pkgs.vscode-extensions.xdebug.php-debug
        ];

        postShellHook = "";

      in
      {

        packages.php-build = pkgs.php.buildComposerProject {
          pname = "php-build";
          version = "1.0.0";
          src = ./.;

          vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          buildPhase = ''
            composer install \
                    --ignore-platform-reqs \
                    --no-ansi \
                    --no-interaction \
                    --no-progress \
                    --no-scripts \
                    --prefer-dist \
                    --optimize-autoloader
          '';

          installPhase = ''
            mkdir -p $out
            cp -r . $out/
          '';
        };

        packages.npm-build = pkgs.buildNpmPackage {
          pname = "npm-build";
          version = "1.0.0";
          src = ./.;

          npmDepsHash = "sha256-Kw/XBQdZqgtWITeMbv2ZQTsiaPlZ8cSEabBXEds3ynQ=";
          npmBuildScript = "build";

          installPhase = ''
            mkdir -p $out
            cp -r public/build/ $out/
          '';
        };

        packages.docker = pkgs.dockerTools.buildImage {
          name = "php-app";
          tag = "latest";

          copyToRoot = pkgs.buildEnv {
            name = "php-app-files";
            paths = [
              pkgs.coreutils
              pkgs.bashInteractive
              pkgs.nginx
              phpWithExtensions
              self.packages.${system}.npm-build
              self.packages.${system}.php-build
            ];
          };

          config = {
          };
        };

        devShells = {
          default = pkgs.mkShell {
            name = "php-dev-shell";
            nativeBuildInputs = scripts;
            packages = devPackages;
            postShellHook = postShellHook;
          };
        };
      }
    );
}
