{
  pkgs,
  self,
  system,
}:
let
  appSrc = ../.;
  appDir = "/app";
  appPort = "8000";

  phpWithExtensions = import ./php.nix {
    inherit pkgs;
    production = true;
  };

in
{

  php-build = phpWithExtensions.buildComposerProject2 {
    pname = "php-build";
    version = "1.0.0";
    src = appSrc;
    vendorHash = "sha256-HPqBn6XIe39bRwMk1mR2LdnDSOkcUss4T45ybugwYBw=";

    installPhase = ''
      # composer dump-autoload -o
      mkdir -p $out/${appDir}
      cp -r vendor/ $out/${appDir}
    '';
  };

  npm-build = pkgs.buildNpmPackage {
    pname = "npm-build";
    version = "1.0.0";
    src = appSrc;

    npmDepsHash = "sha256-Kw/XBQdZqgtWITeMbv2ZQTsiaPlZ8cSEabBXEds3ynQ=";
    npmBuildScript = "build";

    installPhase = ''
      mkdir -p $out/${appDir}/public
      cp -r public/build/ $out/${appDir}/public
    '';
  };

  default =
    let

      fpmConf = pkgs.writeText "www.conf" ''
        [global]
        error_log = /dev/stderr

        [www]
        pm = ondemand
        pm.max_children = 100
        pm.process_idle_timeout = 10s;
        clear_env = no

        listen = 0.0.0.0:9000
        listen.owner = nobody
        listen.group = nobody
        listen.mode = 0660
        user = nobody
        group = nobody

        php_admin_flag[log_errors] = on
        php_admin_flag[display_errors] = on
        php_admin_value[error_log] = /dev/stderr
      '';

      # reference: https://discourse.nixos.org/t/build-a-docker-image-with-nginx-php-app-using-dockertools-buildimage/15652/3
      nginxConf = pkgs.writeText "nginx.conf" ''
        user nobody nobody;
        daemon off;
        pid /dev/null;
        error_log stderr warn;

        events {}

        http {
          include ${pkgs.nginx}/conf/mime.types;
          default_type application/octet-stream;
          client_max_body_size 21M;

          access_log /dev/stdout;
          error_log /dev/stderr;

          server {
            listen [::]:${appPort} default_server;
            listen ${appPort} default_server;
            server_name _;

            absolute_redirect off;

            root ${appDir}/public;
            index index.php index.html;

            charset utf-8;
            add_header X-Frame-Options "SAMEORIGIN";
            add_header X-Content-Type-Options "nosniff";

            location / {
              try_files $uri $uri/ /index.php$is_args$args;
            }

            location ~ \.php$ {
              try_files $uri =404;
              fastcgi_index index.php;
              fastcgi_pass 127.0.0.1:9000;
              fastcgi_split_path_info ^(.+\.php)(/.+)$;

              include ${pkgs.nginx}/conf/fastcgi_params;
              include ${pkgs.nginx}/conf/fastcgi.conf;
            }

            # allow access to the .well-known directory
            location ^~ /.well-known/ {
                allow all;
            }

            # Deny access to . files, for security
            location ~ /\. {
                log_not_found off;
                deny all;
            }
          }
        }
      '';

    in
    pkgs.dockerTools.buildImage {
      name = "php-app";
      tag = "latest";

      copyToRoot = pkgs.buildEnv {
        name = "php-app-files";
        paths = [
          phpWithExtensions
          pkgs.dockerTools.usrBinEnv
          pkgs.dockerTools.binSh
          pkgs.dockerTools.caCertificates
          pkgs.dockerTools.fakeNss
          pkgs.openssl
          pkgs.coreutils
          pkgs.bashInteractive
          pkgs.nginx
          pkgs.curl
          pkgs.xz
          pkgs.zip
          pkgs.unzip
          self.packages.${system}.npm-build
          self.packages.${system}.php-build
          (pkgs.writeScriptBin "start-server" ''
            #!${pkgs.runtimeShell}
            php-fpm -y ${fpmConf} & nginx -c ${nginxConf}
          '')
        ];
      };

      runAsRoot = ''
        #!${pkgs.runtimeShell}
        ${pkgs.dockerTools.shadowSetup}
        cp -r ${appSrc}/* ${appDir}
        chown -R nobody:nobody ${appDir}
        chmod -R 770 ${appDir}
      '';

      extraCommands = ''
        mkdir -p var/log/nginx
        mkdir -p var/cache/nginx
        mkdir -p tmp
        chmod 1777 tmp
      '';

      keepContentsDirlinks = false;

      config = {
        WorkingDir = "${appDir}";
        Cmd = [ "start-server" ];
        ExposedPorts = {
          "${appPort}/tcp" = { };
        };
      };
    };
}
