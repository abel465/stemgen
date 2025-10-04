{
  description = "stemgen";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = nixpkgs.lib.systems.flakeExposed;
      perSystem = {
        pkgs,
        system,
        ...
      }: let
        pythonPackages = pkgs.python3Packages;

        venvDir = "./env";

        runPackages = [
          pythonPackages.python
          pythonPackages.uv
          pythonPackages.venvShellHook
          pkgs.libgcc
        ];

        devPackages =
          runPackages
          ++ [
            pythonPackages.pylint
            pythonPackages.flake8
            pythonPackages.black
          ];

        # This is to expose the venv in PYTHONPATH so that pylint can see venv packages
        postShellHook = ''
          PYTHONPATH=\$PWD/\${venvDir}/\${pythonPackages.python.sitePackages}/:\$PYTHONPATH
          uv pip install .
        '';
      in {
        devShells.default = pkgs.mkShell {
          inherit venvDir;
          name = "pythonify-dev";
          packages = devPackages;
          postShellHook = postShellHook;
          LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath [pkgs.libgcc.lib]}";
        };
      };
    };
}
