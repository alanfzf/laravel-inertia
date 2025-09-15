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

    flake-utils.lib.eachSystem [ "x86_64-darwin" "aarch64-darwin" "x86_64-linux" "aarch64-linux" ] (
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

          (mkScript "mjml" ''
            pnpm exec mjml "$@"
          '')

          (mkScript "blade-formatter" ''
            pnpm exec blade-formatter "$@"
          '')

          (mkScript "intelephense" ''
            pnpm exec intelephense "$@"
          '')

          (mkScript "typescript-language-server" ''
            pnpm exec typescript-language-server "$@"
          '')
        ];

        phpWithExtensions = (
          pkgs.php84.buildEnv {
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
              ])
            );
            extraConfig = ''
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
          pkgs.pnpm
          pkgs.curl
          pkgs.zip
          pkgs.unzip
          # php packages
          pkgs.php84Packages.composer
          pkgs.vscode-extensions.xdebug.php-debug
        ];

        postShellHook = '''';
      in
      {
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
