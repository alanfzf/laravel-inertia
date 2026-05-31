{
  pkgs,
  production ? false,
}:
let
  phpExtensions =
    { enabled, all }:
    let
      base = with all; [
        intl
        mysqli
        bcmath
        curl
        zip
        soap
        mbstring
        gd
      ];

      devOnly = with all; [ xdebug ];
    in
    enabled ++ base ++ (if production then [ ] else devOnly);

  extraConfig =
    if production then
      ""
    else
      ''
        error_reporting = E_ALL & ~E_NOTICE & ~E_STRICT & ~E_DEPRECATED
        xdebug.mode=debug
        xdebug.start_with_request=yes
        xdebug.client_host=127.0.0.1
        xdebug.client_port=9003
        xdebug.log_level = 0
      '';
in

pkgs.php85.buildEnv {
  extensions = phpExtensions;
  extraConfig = extraConfig;
}
