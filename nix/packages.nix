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

  docker = pkgs.dockerTools.buildImage {
    name = "php-app";
    tag = "latest";

    copyToRoot = pkgs.buildEnv {
      name = "php-app-files";
      paths = [
        phpWithExtensions
        pkgs.coreutils
        pkgs.bashInteractive
        pkgs.nginx
        pkgs.python313Packages.supervisor
        self.packages.${system}.npm-build
        self.packages.${system}.php-build
      ];
    };

    config = {
      WorkingDir = "/app";
      Cmd = [
        "supervisord"
        "-c"
        "/app/etc/supervisor/supervisord.conf"
      ];
      ExposedPorts = {
        "8080/tcp" = { };
      };
    };
  };
}
