{
  pkgs,
}:
let
  mkScript = name: text: pkgs.writeShellScriptBin name text;
  scripts = [
    (mkScript "php-debug-adapter" ''
      node ${pkgs.vscode-extensions.xdebug.php-debug}/share/vscode/extensions/xdebug.php-debug/out/phpDebug.js
    '')
  ];

  phpWithExtensions = import ./php.nix {
    inherit pkgs;
    production = false;
  };

in

pkgs.mkShell {
  name = "php-dev-shell";
  nativeBuildInputs = scripts;
  packages = [
    phpWithExtensions
    phpWithExtensions.packages.composer
    pkgs.nodejs_22
    pkgs.curl
    pkgs.zip
    pkgs.unzip
    pkgs.vscode-extensions.xdebug.php-debug
  ];

  postShellHook = "";
}
