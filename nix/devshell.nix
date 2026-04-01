{
  pkgs,
  phpWithExtensions,
}:
let
  mkScript = name: text: pkgs.writeShellScriptBin name text;
  scripts = [
    (mkScript "php-debug-adapter" ''
      node ${pkgs.vscode-extensions.xdebug.php-debug}/share/vscode/extensions/xdebug.php-debug/out/phpDebug.js
    '')
  ];
in

pkgs.mkShell {
  name = "php-dev-shell";
  nativeBuildInputs = scripts;
  packages = [
    phpWithExtensions
    pkgs.nodejs_22
    pkgs.curl
    pkgs.zip
    pkgs.unzip
    pkgs.php85Packages.composer
    pkgs.vscode-extensions.xdebug.php-debug
  ];

  postShellHook = "";
}
