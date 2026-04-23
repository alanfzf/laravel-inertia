{
  pkgs,
  phpWithExtensions,
  self,
  system,
}:
let

in
{
  php-build = phpWithExtensions.buildComposerProject2 {
    pname = "php-build";
    version = "1.0.0";
    src = ../.;

    vendorHash = "sha256-HPqBn6XIe39bRwMk1mR2LdnDSOkcUss4T45ybugwYBw=";

    installPhase = ''
      mkdir -p $out/app
      cp -r . $out/app
    '';
  };

  npm-build = pkgs.buildNpmPackage {
    pname = "npm-build";
    version = "1.0.0";
    src = ../.;

    npmDepsHash = "sha256-Kw/XBQdZqgtWITeMbv2ZQTsiaPlZ8cSEabBXEds3ynQ=";
    npmBuildScript = "build";

    installPhase = ''
      mkdir -p $out/app/public
      cp -r public/build/ $out/app/public
    '';
  };

  default =
    let
      # reference: https://discourse.nixos.org/t/build-a-docker-image-with-nginx-php-app-using-dockertools-buildimage/15652/3
      appPort = "8000";
      appDir = "/app";

      nginxConf = pkgs.writeText "nginx.conf" ''
        # user nobody nobody;
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

          map $http_x_forwarded_proto $fastcgi_param_https_variable {
              default "";
              https "on";
          }

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
              fastcgi_param HTTPS $fastcgi_param_https_variable if_not_empty;

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
          # ca-certificates
          pkgs.fakeNss
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
            php-fpm -y /etc/php-fpm.d/www.conf.default & nginx -c ${nginxConf}
          '')
        ];
      };

      runAsRoot = "";

      extraCommands = ''
        mkdir -p var/log/nginx
        mkdir -p var/cache/nginx
        mkdir -p tmp
        chmod 1777 tmp
      '';

      config = {
        WorkingDir = "${appDir}";
        Cmd = [ "start-server" ];
        ExposedPorts = {
          "${appPort}/tcp" = { };
        };
      };
    };

}
