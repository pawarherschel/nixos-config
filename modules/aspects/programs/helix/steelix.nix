# Keep the editor's Steel API current without changing nixpkgs for other programs.
{ inputs, lib, ... }:
{
  flake-file.inputs.steelix-src = {
    url = "github:mattwparas/helix/16a26934f39152b5cd81bf2f6944e18e680314d0";
    flake = false;
  };

  den.aspects.programs.helix.homeManager =
    { config, pkgs, ... }:
    let
      cfg = config.programs.nhx;
      steelix-unwrapped = pkgs.helix-unwrapped.overrideAttrs (finalAttrs: previousAttrs: {
        pname = "steelix-unwrapped";
        version = "0-unstable-2026-10-18";
        src = inputs.steelix-src;

        # Cargo.lock is identical to nixpkgs' 2026-09-30 Steelix source.
        cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
          inherit (finalAttrs) src pname version;
          hash = "sha256-h4HkOppmseHzX1gHUGO1XSwrg4uCJ4PjmI/3WsYp2C4=";
        };
        cargoBuildFlags = [
          "--package"
          "helix-term"
          "--features"
          "steel,git"
        ];

        # The matched nixpkgs grammar/query runtime still uses .so on Darwin.
        patches = [
          (pkgs.fetchpatch {
            name = "revert-dylib-grammar-extension.patch";
            url = "https://github.com/helix-editor/helix/commit/430914b298a32653ab1847fdfdf2177a002be04c.patch";
            revert = true;
            hash = "sha256-4KUFppkso4/XwNU+mGIgLvl+mJXHZWkmaguYMy8oTyI=";
          })
        ];
        postPatch = (previousAttrs.postPatch or "") + ''
          # Keep language-to-grammar mappings aligned with the retained runtime.
          cp ${pkgs.helix-unwrapped.src}/languages.toml languages.toml
        '';
        doInstallCheck = false;
      });
      steelix = pkgs.symlinkJoin {
        pname = "steelix";
        inherit (steelix-unwrapped) version;
        paths = [ steelix-unwrapped ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        # Do not combine the newer source's queries with older grammar revisions.
        postBuild = ''
          wrapProgram $out/bin/hx \
            --set HELIX_RUNTIME ${pkgs.helix.runtime} \
            --prefix PATH : ${lib.escapeShellArg (lib.makeBinPath cfg.requiredPackages)}
        '';
        passthru = {
          unwrapped = steelix-unwrapped;
          inherit (pkgs.helix) runtime;
        };
        meta = pkgs.steelix.meta // {
          changelog = "https://github.com/mattwparas/helix/blob/16a26934f39152b5cd81bf2f6944e18e680314d0/CHANGELOG.md";
        };
      };
    in
    {
      options.programs.nhx.requiredPackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = "Executables made available only to the configured Steelix editor and its plugins.";
      };

      config.programs.nhx.package = steelix;
    };
}
